function R = plot_F3_vs_theta2(userCfg)
%PLOT_F3_VS_THETA2  Kinematic analysis of Link 8 point F3 versus the Link 2 crank angle.
%
%   วิเคราะห์และพล็อตตำแหน่ง (x), ความเร็ว (v_x) และความเร่ง (a_x) ของ Link 8 จุด F3
%   เทียบกับมุม Link 2 (theta2, deg) จากผล simulation ของ walking_beam
%
%   การใช้งาน
%     plot_F3_vs_theta2                 ใช้ค่าตั้งมาตรฐาน (defaultConfig)
%     plot_F3_vs_theta2(cfg)            override บางค่า เช่น cfg.thRange = 360
%     R = plot_F3_vs_theta2(___)        คืนผลการวิเคราะห์เป็น struct
%
%   ขั้นตอนการทำงาน
%     1. Configuration   ค่าตั้ง: ชื่อสัญญาณ, หน่วย, ช่วงมุม
%     2. Data loading    อ่านสัญญาณจาก base workspace (หรือ out) แล้วจัดให้อยู่บนแกนเวลาเดียวกัน
%     3. Preprocessing   เลือกช่วงมุมที่วิเคราะห์ และพับมุมให้อยู่ในช่วง 0..thRange
%     4. Analysis        หาจุด v = 0 และคำนวณค่าของแต่ละช่วง v = 0 -> v = 0
%                          delta_x = x(theta_end) - x(theta_start)
%                          v_avg   = (1/theta_span) * integral(v dtheta)
%     5. Reporting       ส่งผลไป base workspace และพิมพ์สรุปใน Command Window
%     6. Visualization   วาดกราฟ x, v, a พร้อมเส้น v = 0 และค่าเฉลี่ยของแต่ละช่วง
%
%   ผลลัพธ์ R
%     R.th, R.x, R.v, R.a   ข้อมูลที่ใช้ plot (theta ในช่วง 0..thRange)
%     R.thZ, R.xZ, R.aZ     จุดที่ v = 0 (มุม, x และ a ณ จุดนั้น)
%     R.seg                 table ของแต่ละช่วง v = 0 -> v = 0
%     R.cfg                 ค่าตั้งที่ใช้
%
%   ตัวแปรที่ส่งออกไป base workspace
%     F3_result, F3_seg, delta_x, v_avg
%
%   ให้รันอัตโนมัติหลัง simulation จบ
%     1) Model Settings (Ctrl+E) > Data Import/Export > เอาติ๊ก "Single simulation output" ออก
%     2) Model Properties > Callbacks > StopFcn ใส่:  plot_F3_vs_theta2
%     3) ไฟล์นี้ต้องอยู่โฟลเดอร์เดียวกับโมเดล (หรืออยู่ใน MATLAB path)

if nargin < 1, userCfg = struct(); end

cfg  = mergeConfig(defaultConfig(), userCfg);   % 1. Configuration
data = loadSignals(cfg);                         % 2. Data loading
win  = selectAngleWindow(data, cfg);             % 3. Preprocessing
res  = analyzeMotion(win, cfg);                  % 4. Analysis
exportToWorkspace(res);                          % 5. Reporting
printReport(res);
plotResults(res);                                % 6. Visualization

if nargout > 0, R = res; end
end


%% =====================================================================
%% 1. Configuration
%% =====================================================================
function cfg = defaultConfig()
% ค่าตั้งมาตรฐาน: ชื่อสัญญาณต้องตรงกับ Variable name ใน To Workspace
%                 หน่วยต้องตรงกับ Output signal unit ของ PS-Simulink Converter
cfg.nameTheta   = 'theta2';   % มุม Link 2 (deg)
cfg.nameX       = 'x';        % ตำแหน่ง x ของ F3
cfg.nameV       = 'v_x';      % ความเร็ว x ของ F3
cfg.nameA       = 'a_x';      % ความเร่ง x ของ F3

cfg.unitX       = 'mm';
cfg.unitV       = 'mm/s';
cfg.unitA       = 'mm/s^2';

cfg.thRange     = 720;        % ช่วงแกนมุม (deg): 360 = 1 รอบ, 720 = 2 รอบ
cfg.lastRevOnly = true;       % true = ใช้เฉพาะ thRange องศาสุดท้าย (ตัด transient)
cfg.theta0      = 0;          % offset มุม (deg) ให้ 0° ตรงกับแบบ
end

function cfg = mergeConfig(cfg, userCfg)
% เขียนทับค่ามาตรฐานด้วยค่าที่ผู้ใช้ส่งเข้ามา
fields = fieldnames(userCfg);
for k = 1:numel(fields)
    if ~isfield(cfg, fields{k})
        warning('plot_F3_vs_theta2:unknownField', 'ไม่รู้จักค่าตั้ง "%s" -> ข้าม', fields{k});
        continue
    end
    cfg.(fields{k}) = userCfg.(fields{k});
end
end


%% =====================================================================
%% 2. Data loading
%% =====================================================================
function data = loadSignals(cfg)
% อ่านสัญญาณทั้ง 4 ตัว แล้ว interpolate x, v, a ไปที่เวลาของ theta2
names = {cfg.nameTheta, cfg.nameX, cfg.nameV, cfg.nameA};
src   = pickSource(names);

[tTh, data.th] = getSignal(src, cfg.nameTheta);
[tX,  x]       = getSignal(src, cfg.nameX);
[tV,  v]       = getSignal(src, cfg.nameV);
[tA,  a]       = getSignal(src, cfg.nameA);

data.x = alignToTime(tX, x, tTh);
data.v = alignToTime(tV, v, tTh);
data.a = alignToTime(tA, a, tTh);
end

function src = pickSource(names)
% ใช้ตัวแปรใน base workspace ถ้ามีครบ (ข้อมูลล่าสุด ใช้ได้ตอน StopFcn)
% ไม่อย่างนั้นใช้ out (กรณีเปิด Single simulation output แล้วเรียกเองหลัง simulation จบ)
inBase = @(n) evalin('base', sprintf('exist(''%s'', ''var'')', n)) == 1;
if all(cellfun(inBase, names))
    src = struct();
    for n = [names, {'tout'}]
        if inBase(n{1}), src.(n{1}) = evalin('base', n{1}); end
    end
elseif inBase('out')
    src = evalin('base', 'out');
else
    error('plot_F3_vs_theta2:noData', ['ไม่พบข้อมูลใน workspace -> รันโมเดลก่อน\n' ...
          '(ถ้าเรียกจาก StopFcn ต้องเอาติ๊ก "Single simulation output" ออก)']);
end
end

function [t, d] = getSignal(src, name)
% ดึงสัญญาณได้ทุกรูปแบบการบันทึก คืนค่าเวลา t และข้อมูล d เป็นเวกเตอร์คอลัมน์
t = []; d = [];
if isstruct(src)
    vars = fieldnames(src);
    getv = @(n) src.(n);
else                                                  % Simulink.SimulationOutput
    vars = src.who;
    getv = @(n) src.get(n);
end

if any(strcmp(vars, name))
    s = getv(name);
    if isa(s, 'timeseries')                           % Save format: Timeseries
        t = s.Time;  d = s.Data;
    elseif isstruct(s) && isfield(s, 'signals')       % Save format: Structure with time
        t = s.time;  d = s.signals.values;
    elseif isa(s, 'Simulink.SimulationData.Dataset')  % Record / Dataset
        el = s{1};  t = el.Values.Time;  d = el.Values.Data;
    elseif isnumeric(s)                               % Save format: Array
        d = s;
        if any(strcmp(vars, 'tout'))
            tt = getv('tout');
            if numel(tt) == size(s, 1), t = tt; end
        end
    end
elseif any(strcmp(vars, 'logsout'))                   % Signal Logging
    el = getv('logsout').get(name);
    if ~isempty(el), t = el.Values.Time;  d = el.Values.Data; end
end

if isempty(d)
    error('plot_F3_vs_theta2:signalNotFound', ...
          'หา "%s" ไม่เจอ -> แก้ชื่อใน defaultConfig (ตัวแปรที่มี: %s)', ...
          name, strjoin(reshape(vars, 1, []), ', '));
end
d = squeeze(d);  d = d(:);
t = t(:);
end

function y = alignToTime(t, d, tRef)
% ถ้าเวลาไม่ตรงกับ tRef ให้ interpolate ไปที่ tRef
if isempty(t) || isempty(tRef)
    if ~isempty(tRef) && numel(d) ~= numel(tRef)
        error('plot_F3_vs_theta2:lengthMismatch', ...
              'ความยาวข้อมูลไม่เท่ากัน -> ตั้ง Sample time ของ To Workspace ให้เท่ากันทุกตัว');
    end
    y = d;
    return
end
if numel(t) == numel(tRef) && all(abs(t - tRef) < 1e-12)
    y = d;
else
    [t, iu] = unique(t);
    y = interp1(t, d(iu), tRef, 'linear', 'extrap');
end
end


%% =====================================================================
%% 3. Preprocessing
%% =====================================================================
function win = selectAngleWindow(data, cfg)
% เลือกช่วงมุมที่วิเคราะห์ และพับมุมให้อยู่ในช่วง 0..thRange
th      = data.th - cfg.theta0;
thRange = cfg.thRange;
span    = abs(th(end) - th(1));

if ~cfg.lastRevOnly
    idx = true(size(th));
elseif span < thRange
    warning('plot_F3_vs_theta2:shortRun', ...
            'ข้อมูลหมุนไปแค่ %.1f deg ไม่ถึง %g deg -> เพิ่ม Stop time', span, thRange);
    idx = true(size(th));
elseif th(end) >= th(1)
    idx = th >= th(end) - thRange;                    % หมุนทิศบวก
else
    idx = th <= th(end) + thRange;                    % หมุนทิศลบ
end

win.th = mod(th(idx), thRange);                       % มุม 0 ตรงกับ 360*k ของมุมจริง
win.x  = data.x(idx);
win.v  = data.v(idx);
win.a  = data.a(idx);

if cfg.lastRevOnly
    % เรียงตามมุม เพื่อไม่ให้มีเส้นกระโดดตรงรอยต่อ thRange -> 0
    [win.th, k] = sort(win.th);
    win.x = win.x(k);  win.v = win.v(k);  win.a = win.a(k);
else
    % หลายรอบ: แทรก NaN ตรงรอยต่อ ให้เส้นขาดแทนที่จะลากข้าม
    jump = [false; abs(diff(win.th)) > thRange/2];
    win.x(jump) = NaN;  win.v(jump) = NaN;  win.a(jump) = NaN;
end
end


%% =====================================================================
%% 4. Analysis
%% =====================================================================
function R = analyzeMotion(win, cfg)
% หาจุด v = 0 แล้วคำนวณ delta_x, v_avg ของแต่ละช่วง
R.th = win.th;  R.x = win.x;  R.v = win.v;  R.a = win.a;

R.thZ = findZeroCrossings(win.th, win.v);
R.xZ  = interp1(win.th, win.x, R.thZ);
R.aZ  = interp1(win.th, win.a, R.thZ);

R.seg = computeSegments(win, R.thZ, R.xZ);
R.cfg = cfg;
end

function thZ = findZeroCrossings(th, v)
% หามุมที่ v เปลี่ยนเครื่องหมาย แล้ว interpolate หามุมที่ v = 0 พอดี
% ถ้า v ไม่ตัดศูนย์เลย ใช้จุดที่ |v| ใกล้ 0 ที่สุดแทน
th = th(:);  v = v(:);
valid = ~isnan(v(1:end-1)) & ~isnan(v(2:end)) & abs(diff(th)) < 90;   % ข้ามรอยต่อ / NaN
s     = sign(v);
i     = find(valid & s(1:end-1) .* s(2:end) < 0);
iz    = find(v == 0);

thZ = th(i) - v(i) .* (th(i+1) - th(i)) ./ (v(i+1) - v(i));
thZ = sort([thZ; th(iz)]);

if isempty(thZ)
    [~, k] = min(abs(v));
    thZ = th(k);
    warning('plot_F3_vs_theta2:noZeroCrossing', ...
            'Vx ไม่ตัดศูนย์ -> ใช้จุดที่ใกล้ 0 ที่สุด (Vx = %.4g ที่ %.2f deg)', v(k), th(k));
end
thZ = thZ([true; diff(thZ) > 0.5]);                   % ตัดจุดซ้ำ (ห่างกันไม่ถึง 0.5 deg)
end

function seg = computeSegments(win, thZ, xZ)
% ค่าของแต่ละช่วง v = 0 -> v = 0 ถัดไป (ใช้ trapz อินทิเกรตเทียบกับมุม)
% หมายเหตุ: ไม่คำนวณความเร่งเฉลี่ย เพราะช่วงเริ่มและจบที่ v = 0
%           จึงได้ a_avg = (v_end - v_start)/dt = 0 เสมอ
nSeg = numel(thZ) - 1;
if nSeg < 1
    seg = table();
    return
end

seg_no   = (1:nSeg)';
th_start = thZ(1:end-1);
th_end   = thZ(2:end);
th_span  = th_end - th_start;
delta_x  = zeros(nSeg, 1);
v_avg    = zeros(nSeg, 1);

for i = 1:nSeg
    in = win.th > th_start(i) & win.th < th_end(i) & ~isnan(win.v);
    tt = [th_start(i); win.th(in); th_end(i)];        % ปลายช่วงใช้ค่าที่ interpolate
    vv = [0;           win.v(in);  0];                % ปลายช่วง v = 0 พอดี
    delta_x(i) = xZ(i+1) - xZ(i);
    v_avg(i)   = trapz(tt, vv) / th_span(i);
end

seg = table(seg_no, th_start, th_end, th_span, delta_x, v_avg, ...
            'VariableNames', {'seg', 'th_start', 'th_end', 'th_span', 'delta_x', 'v_avg'});
end


%% =====================================================================
%% 5. Reporting
%% =====================================================================
function exportToWorkspace(R)
% ส่งผลการวิเคราะห์ไป base workspace
assignin('base', 'F3_result', R);
if height(R.seg) > 0
    assignin('base', 'F3_seg',  R.seg);
    assignin('base', 'delta_x', R.seg.delta_x);
    assignin('base', 'v_avg',   R.seg.v_avg);
end
end

function printReport(R)
% พิมพ์สรุปผลใน Command Window
cfg = R.cfg;

fprintf('\nจุดที่ Vx = 0:\n');
for i = 1:numel(R.thZ)
    fprintf('  theta2 = %7.2f deg   x = %8.3f %s   ax = %9.3f %s\n', ...
            R.thZ(i), R.xZ(i), cfg.unitX, R.aZ(i), cfg.unitA);
end

if height(R.seg) > 0
    fprintf('\nช่วง V=0 -> V=0   [delta_x: %s, v_avg: %s, theta: deg]\n', ...
            cfg.unitX, cfg.unitV);
    fprintf('(ส่งออกไป workspace: F3_result, F3_seg, delta_x, v_avg)\n');
    disp(R.seg);
end

fprintf('x  : min %.4g  max %.4g  %s\n', min(R.x), max(R.x), cfg.unitX);
fprintf('Vx : min %.4g  max %.4g  %s\n', min(R.v), max(R.v), cfg.unitV);
fprintf('ax : min %.4g  max %.4g  %s\n', min(R.a), max(R.a), cfg.unitA);
end


%% =====================================================================
%% 6. Plots
%% =====================================================================
function fig = plotResults(R)
% วาดกราฟ x, v, a เทียบกับ theta2 พร้อมจุด v = 0 และค่าของแต่ละช่วง
cfg   = R.cfg;
style = plotStyle();
fig   = prepareFigure();

tl  = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');
axs = gobjects(1, 3);

axs(1) = nexttile(tl);  plot(axs(1), R.th, R.x, 'LineWidth', style.lineWidth);
ylabel(axs(1), ['x_{F3} (' cfg.unitX ')']);
title(axs(1), 'Link 8 @ F3 เทียบกับมุม Link 2');

axs(2) = nexttile(tl);  plot(axs(2), R.th, R.v, 'LineWidth', style.lineWidth);
ylabel(axs(2), ['V_{x,F3} (' cfg.unitV ')']);

axs(3) = nexttile(tl);  plot(axs(3), R.th, R.a, 'LineWidth', style.lineWidth);
ylabel(axs(3), ['a_{x,F3} (' cfg.unitA ')']);
xlabel(axs(3), '\theta_2 (deg)');

styleAxes(axs, cfg.thRange, style);
drawZeroCrossings(axs, R, style);
drawSegments(axs, R.seg, cfg, style);

for ax = axs, hold(ax, 'off'); end
end

function style = plotStyle()
% สีและขนาดเส้นที่ใช้ร่วมกันทุกกราฟ
style.lineWidth = 1.5;
style.zeroColor = [0.85 0.10 0.10];    % แดง: จุด v = 0
style.segColor  = [0.00 0.45 0.20];    % เขียว: ค่าของแต่ละช่วง
style.revColor  = [0.40 0.40 0.40];    % เทา: เส้นแบ่งรอบ
style.gridColor = [0.60 0.60 0.60];
end

function fig = prepareFigure()
% ใช้หน้าต่างเดิมซ้ำทุกครั้งที่รัน และบังคับธีมสว่าง (R2025a+)
tag = 'plot_F3_vs_theta2';
fig = findobj(groot, 'Type', 'figure', 'Tag', tag);
if isempty(fig)
    fig = figure('Name', 'Link 8 @ F3 vs theta2', 'Tag', tag);
else
    fig = fig(1);  clf(fig);  figure(fig);
end
if exist('theme', 'file'), theme(fig, 'light'); end
fig.Color = 'w';
end

function styleAxes(axs, thRange, style)
% ตัวหนังสือ/แกนสีดำ พื้นขาว, grid, ช่วงแกนมุม และเส้นแบ่งรอบ
revLines = 360:360:thRange-1;
for ax = axs
    grid(ax, 'on');
    xlim(ax, [0 thRange]);
    xticks(ax, 0:max(45, thRange/8):thRange);
    if ~isempty(revLines), xline(ax, revLines, '--', 'Color', style.revColor); end
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', style.gridColor);
    ax.XLabel.Color = 'k';  ax.YLabel.Color = 'k';  ax.Title.Color = 'k';
    hold(ax, 'on');
end
end

function drawZeroCrossings(axs, R, style)
% เส้นแนวดิ่งตรงจุด v = 0 ทั้ง 3 กราฟ พร้อมจุดบนเส้นกราฟและป้ายมุม
if isempty(R.thZ), return; end
c = style.zeroColor;
for ax = axs
    xline(ax, R.thZ, '-', 'Color', c, 'LineWidth', 1.2);
end
plot(axs(1), R.thZ, R.xZ,               'o', 'Color', c, 'MarkerFaceColor', c);
plot(axs(2), R.thZ, zeros(size(R.thZ)), 'o', 'Color', c, 'MarkerFaceColor', c);
plot(axs(3), R.thZ, R.aZ,               'o', 'Color', c, 'MarkerFaceColor', c);
for i = 1:numel(R.thZ)
    text(axs(2), R.thZ(i), 0, sprintf('%.1f°', R.thZ(i)), 'Color', c, ...
         'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
         'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1);
end
end

function drawSegments(axs, S, cfg, style)
% Δx บนกราฟ x และเส้นประ v_avg บนกราฟ v ของแต่ละช่วง
c = style.segColor;
lbl = {'Color', c, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1, ...
       'HorizontalAlignment', 'center'};
for i = 1:height(S)
    th1 = S.th_start(i);  th2 = S.th_end(i);  thm = (th1 + th2) / 2;

    text(axs(1), thm, mean(axs(1).YLim), ...
         sprintf('\\Deltax = %.2f %s', S.delta_x(i), cfg.unitX), lbl{:});

    plot(axs(2), [th1 th2], S.v_avg(i) * [1 1], '--', 'Color', c, 'LineWidth', 1.5);
    text(axs(2), thm, S.v_avg(i), sprintf('v_{avg} = %.2f', S.v_avg(i)), ...
         lbl{:}, 'VerticalAlignment', 'bottom');
end
end
