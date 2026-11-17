function fig = plot_F3(R)
%% plot_F3  ส่วน plot (ไม่มีการคำนวณ)
% วาดกราฟ x, v, a ของ Link 8 จุด F3 เทียบกับมุม Link 2 จากผลของ analyze_F3
%   - เส้นแนวดิ่งสีแดง + จุด ตรงที่ v = 0
%   - Δx, v_avg, a_avg ของแต่ละช่วง v=0 -> v=0 (สีเขียว)
%
% fig = plot_F3(R)    R มาจาก analyze_F3

cfg = R.cfg;
thRange = cfg.thRange;
zc = [0.85 0.1 0.1];      % สีแดง: จุด v = 0
sc = [0 0.45 0.2];        % สีเขียว: ค่าของแต่ละช่วง

%% หน้าต่าง (ใช้หน้าต่างเดิมซ้ำทุกครั้งที่รัน ไม่เปิดหน้าต่างใหม่เพิ่ม)
fig = findobj(groot, 'Type', 'figure', 'Tag', 'plot_F3_vs_theta2');
if isempty(fig)
    fig = figure('Name', 'Link 8 @ F3 vs theta2', 'Tag', 'plot_F3_vs_theta2');
else
    fig = fig(1); clf(fig); figure(fig);
end
if exist('theme', 'file')            % R2025a+ : บังคับธีมสว่าง ไม่ให้ตามธีมมืดของ MATLAB
    theme(fig, 'light');
end
fig.Color = 'w';
tl = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact');

%% เส้นกราฟหลัก
ax1 = nexttile(tl); plot(ax1, R.th, R.x, 'LineWidth', 1.5);
ylabel(ax1, ['x_{F3} (' cfg.unitX ')']);
title(ax1, 'Link 8 @ F3 เทียบกับมุม Link 2');

ax2 = nexttile(tl); plot(ax2, R.th, R.v, 'LineWidth', 1.5);
ylabel(ax2, ['V_{x,F3} (' cfg.unitV ')']);

ax3 = nexttile(tl); plot(ax3, R.th, R.a, 'LineWidth', 1.5);
ylabel(ax3, ['a_{x,F3} (' cfg.unitA ')']);
xlabel(ax3, '\theta_2 (deg)');

axs = [ax1 ax2 ax3];
for axh = axs                         % ตัวหนังสือ/แกน/ป้าย สีดำ พื้นขาว
    grid(axh, 'on'); xlim(axh, [0 thRange]); xticks(axh, 0:max(45, thRange/8):thRange);
    revLines = 360:360:thRange-1;                                   % เส้นแบ่งรอบ
    if ~isempty(revLines), xline(axh, revLines, '--', 'Color', [0.4 0.4 0.4]); end
    set(axh, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridColor', [0.6 0.6 0.6]);
    axh.XLabel.Color = 'k'; axh.YLabel.Color = 'k'; axh.Title.Color = 'k';
    hold(axh, 'on');
end

%% จุด v = 0 (เส้นแนวดิ่งทั้ง 3 กราฟ)
if ~isempty(R.thZ)
    for axh = axs
        xline(axh, R.thZ, '-', 'Color', zc, 'LineWidth', 1.2);
    end
    plot(ax1, R.thZ, R.xZ,                'o', 'Color', zc, 'MarkerFaceColor', zc);
    plot(ax2, R.thZ, zeros(size(R.thZ)),  'o', 'Color', zc, 'MarkerFaceColor', zc);
    plot(ax3, R.thZ, R.aZ,                'o', 'Color', zc, 'MarkerFaceColor', zc);
    for i = 1:numel(R.thZ)            % ป้ายมุมบนกราฟ V (ใต้เส้นศูนย์)
        text(ax2, R.thZ(i), 0, sprintf('%.1f°', R.thZ(i)), 'Color', zc, ...
             'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
             'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1);
    end
end

%% ค่าของแต่ละช่วง v = 0 -> v = 0
S = R.seg;
for i = 1:height(S)
    th1 = S.th_start(i); th2 = S.th_end(i); thm = (th1 + th2) / 2;
    text(ax1, thm, mean(ax1.YLim), sprintf('\\Deltax = %.2f %s', S.delta_x(i), cfg.unitX), ...
         'Color', sc, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', ...
         'BackgroundColor', 'w', 'Margin', 1);
    plot(ax2, [th1 th2], S.v_avg(i)*[1 1], '--', 'Color', sc, 'LineWidth', 1.5);
    text(ax2, thm, S.v_avg(i), sprintf('v_{avg} = %.2f', S.v_avg(i)), 'Color', sc, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1);
    plot(ax3, [th1 th2], S.a_avg(i)*[1 1], '--', 'Color', sc, 'LineWidth', 1.5);
    text(ax3, thm, S.a_avg(i), sprintf('a_{avg} = %.1f', S.a_avg(i)), 'Color', sc, ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
         'FontWeight', 'bold', 'BackgroundColor', 'w', 'Margin', 1);
end

for axh = axs, hold(axh, 'off'); end
end
