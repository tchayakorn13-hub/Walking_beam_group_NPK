function R = analyze_F3(cfg)
%% analyze_F3  ส่วนวิเคราะห์ (ไม่มีการ plot)
% อ่านข้อมูลของ Link 8 จุด F3 จาก workspace แล้วคำนวณ
%   - ข้อมูล x, v, a เทียบกับมุม Link 2 (deg) ในช่วง 0..cfg.thRange
%   - จุดที่ v = 0
%   - ช่วงจาก v = 0 ถึง v = 0 ถัดไป:
%       delta_x = x(θ_end) - x(θ_start)
%       v_avg   = (1/θ_span) * ∫ v dθ
%       a_avg   = (1/θ_span) * ∫ a dθ
%
% R = analyze_F3(cfg)   cfg ดูได้จาก plot_F3_vs_theta2.m
%
% ผลลัพธ์ R:
%   R.th, R.x, R.v, R.a        ข้อมูลที่พร้อม plot (θ ในช่วง 0..thRange)
%   R.thZ, R.xZ, R.aZ          จุดที่ v = 0 (มุม, x และ a ณ จุดนั้น)
%   R.seg                      table ของแต่ละช่วง v=0 -> v=0 (ว่างถ้ามีจุด v=0 น้อยกว่า 2 จุด)
%   R.cfg                      ค่าตั้งที่ใช้

src = pickSource({cfg.nameTheta, cfg.nameX, cfg.nameV, cfg.nameA});

[tTh, th] = getSig(src, cfg.nameTheta);
[tX,  xd] = getSig(src, cfg.nameX);
[tV,  vd] = getSig(src, cfg.nameV);
[tA,  ad] = getSig(src, cfg.nameA);

% ทำให้ทุกสัญญาณอยู่บนแกนเวลาเดียวกับ theta2
xd = alignTo(tX, xd, tTh);
vd = alignTo(tV, vd, tTh);
ad = alignTo(tA, ad, tTh);

th = th - cfg.theta0;

%% เลือกช่วงข้อมูล
thRange = cfg.thRange;
if cfg.lastRevOnly
    if abs(th(end) - th(1)) < thRange
        warning('ข้อมูลหมุนไปแค่ %.1f deg ไม่ถึง %g deg -> เพิ่ม Stop time', ...
                abs(th(end)-th(1)), thRange);
        idx = true(size(th));
    elseif th(end) >= th(1)
        idx = th >= th(end) - thRange;   % หมุนทิศบวก
    else
        idx = th <= th(end) + thRange;   % หมุนทิศลบ
    end
else
    idx = true(size(th));
end

thW = mod(th(idx), thRange);        % บีบให้อยู่ใน 0-thRange deg (มุม 0 ตรงกับ 360·k ของมุมจริง)
xs = xd(idx); vs = vd(idx); as = ad(idx);

if cfg.lastRevOnly
    % เรียงตามมุมเพื่อไม่ให้มีเส้นกระโดดตรงรอยต่อ thRange -> 0
    [thW, k] = sort(thW);
    xs = xs(k); vs = vs(k); as = as(k);
else
    % หลายรอบ: แทรก NaN ตรงรอยต่อ ให้เส้นขาดแทนที่จะลากข้าม
    jump = [false; abs(diff(thW)) > thRange/2];
    xs(jump) = NaN; vs(jump) = NaN; as(jump) = NaN;
end

%% จุดที่ v = 0
thZ = findZeroV(thW, vs);
xZ = interp1(thW, xs, thZ);
aZ = interp1(thW, as, thZ);

%% ช่วง v = 0 -> v = 0 ถัดไป
nSeg = numel(thZ) - 1;
if nSeg >= 1
    seg      = (1:nSeg)';
    th_start = thZ(1:end-1);
    th_end   = thZ(2:end);
    th_span  = th_end - th_start;
    delta_x  = zeros(nSeg,1); v_avg = zeros(nSeg,1); a_avg = zeros(nSeg,1);
    for i = 1:nSeg
        in = thW > th_start(i) & thW < th_end(i) & ~isnan(vs);
        tt = [th_start(i); thW(in); th_end(i)];   % ปลายช่วงใช้ค่าที่ interpolate
        vv = [0;           vs(in);  0];            % ปลายช่วง v = 0 พอดี
        aa = [aZ(i);       as(in);  aZ(i+1)];
        delta_x(i) = xZ(i+1) - xZ(i);
        v_avg(i)   = trapz(tt, vv) / th_span(i);
        a_avg(i)   = trapz(tt, aa) / th_span(i);
    end
    segTable = table(seg, th_start, th_end, th_span, delta_x, v_avg, a_avg);
else
    segTable = table();
end

%% ผลลัพธ์
R.th  = thW;  R.x = xs;  R.v = vs;  R.a = as;
R.thZ = thZ;  R.xZ = xZ; R.aZ = aZ;
R.seg = segTable;
R.cfg = cfg;
end

%% ===================== ฟังก์ชันช่วย =====================
function src = pickSource(names)
% ใช้ตัวแปรตรงๆ ใน base workspace ถ้ามีครบ (ข้อมูลล่าสุด ใช้ได้ตอน StopFcn)
% ไม่อย่างนั้นใช้ out (กรณีเปิด Single simulation output แล้วรันเองหลัง sim จบ)
    hasAll = all(cellfun(@(n) evalin('base', sprintf('exist(''%s'',''var'')', n)) == 1, names));
    if hasAll
        src = struct();
        for n = [names, {'tout'}]
            if evalin('base', sprintf('exist(''%s'',''var'')', n{1})) == 1
                src.(n{1}) = evalin('base', n{1});
            end
        end
    elseif evalin('base', 'exist(''out'',''var'')') == 1
        src = evalin('base', 'out');
    else
        error('%s', sprintf(['ไม่พบข้อมูลใน workspace -> รันโมเดลก่อน\n' ...
               '(ถ้าเรียกจาก StopFcn ต้องเอาติ๊ก "Single simulation output" ออก)']));
    end
end

function [t, d] = getSig(src, name)
% ดึงสัญญาณไม่ว่าจะบันทึกแบบไหน คืนค่าเวลา t และข้อมูล d เป็นคอลัมน์
    t = []; d = [];
    if isstruct(src)
        vars = fieldnames(src);
        getv = @(n) src.(n);
    else                                   % Simulink.SimulationOutput
        vars = src.who;
        getv = @(n) src.get(n);
    end
    if any(strcmp(vars, name))
        s = getv(name);
        if isa(s, 'timeseries')                       % Save format: Timeseries
            t = s.Time; d = s.Data;
        elseif isstruct(s) && isfield(s, 'signals')   % Structure with time
            t = s.time; d = s.signals.values;
        elseif isa(s, 'Simulink.SimulationData.Dataset')
            el = s{1}; t = el.Values.Time; d = el.Values.Data;
        elseif isnumeric(s)                           % Save format: Array
            d = s;
            if any(strcmp(vars, 'tout'))
                tt = getv('tout');
                if numel(tt) == size(s, 1), t = tt; end
            end
        end
    elseif any(strcmp(vars, 'logsout'))               % Signal Logging
        el = getv('logsout').get(name);
        if ~isempty(el)
            t = el.Values.Time; d = el.Values.Data;
        end
    end
    if isempty(d)
        error('หา "%s" ไม่เจอ -> แก้ชื่อในส่วนตั้งค่า (ตัวแปรที่มี: %s)', ...
              name, strjoin(reshape(vars,1,[]), ', '));
    end
    d = squeeze(d); d = d(:);
    t = t(:);
end

function thZ = findZeroV(th, v)
% หามุมที่ v ตัดศูนย์ (เปลี่ยนเครื่องหมาย) แล้ว interpolate หามุมที่ v = 0 พอดี
% ถ้าไม่มีจุดตัดศูนย์เลย ใช้จุดที่ |v| ใกล้ 0 ที่สุดแทน
    th = th(:); v = v(:);
    ok = ~isnan(v(1:end-1)) & ~isnan(v(2:end)) & abs(diff(th)) < 90;  % ข้ามรอยต่อ/NaN
    s  = sign(v);
    i  = find(ok & s(1:end-1) .* s(2:end) < 0);        % เปลี่ยนเครื่องหมายระหว่าง i กับ i+1
    iz = find(v == 0);                                  % ตรงศูนย์พอดี
    thZ = th(i) - v(i) .* (th(i+1) - th(i)) ./ (v(i+1) - v(i));
    thZ = sort([thZ; th(iz)]);
    if isempty(thZ)
        [~, k] = min(abs(v)); thZ = th(k);
        warning('Vx ไม่ตัดศูนย์ -> ใช้จุดที่ใกล้ 0 ที่สุด (Vx = %.4g ที่ %.2f deg)', v(k), th(k));
    end
    % ตัดจุดที่ซ้ำกัน (ห่างกันไม่ถึง 0.5 deg)
    thZ = thZ([true; diff(thZ) > 0.5]);
end

function y = alignTo(t, d, tRef)
% ถ้าเวลาไม่ตรงกับ theta2 ให้ interpolate ไปที่เวลาของ theta2
    if isempty(t) || isempty(tRef)
        if numel(d) ~= numel(tRef) && ~isempty(tRef)
            error('ความยาวข้อมูลไม่เท่ากัน -> ตั้ง Sample time ของ To Workspace ให้เท่ากันทุกตัว');
        end
        y = d; return
    end
    if numel(t) == numel(tRef) && all(abs(t - tRef) < 1e-12)
        y = d;
    else
        [t, iu] = unique(t);
        y = interp1(t, d(iu), tRef, 'linear', 'extrap');
    end
end
