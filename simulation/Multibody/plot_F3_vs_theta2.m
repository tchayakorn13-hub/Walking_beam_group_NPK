function plot_F3_vs_theta2()
%% plot_F3_vs_theta2  ไฟล์หลัก: ตั้งค่า -> วิเคราะห์ -> ส่งออก workspace -> plot
% วิเคราะห์และพล็อตตำแหน่ง (x), ความเร็ว (v_x), ความเร่ง (a_x) ของ Link 8 จุด F3
% เทียบกับมุมของ Link 2 (deg)
%
% แยกไฟล์:
%   plot_F3_vs_theta2.m  <- ไฟล์นี้: ค่าตั้ง + เรียกใช้ + ส่งผลไป workspace
%   analyze_F3.m         <- ส่วนวิเคราะห์ (อ่านข้อมูล, หาจุด v=0, Δx, v_avg, a_avg)
%   plot_F3.m            <- ส่วน plot
%
% ให้รันเองอัตโนมัติหลัง simulation จบ:
%   1) Model Settings (Ctrl+E) -> Data Import/Export
%        -> เอาติ๊ก "Single simulation output" ออก
%        (ถ้าติ๊กไว้ ข้อมูลจะยังไม่อยู่ใน workspace ตอน StopFcn ทำงาน)
%   2) Modeling -> Model Settings -> Model Properties -> Callbacks -> StopFcn
%        ใส่:  plot_F3_vs_theta2
%   3) ทั้ง 3 ไฟล์ต้องอยู่โฟลเดอร์เดียวกับโมเดล (หรืออยู่ใน MATLAB path)
%
% เรียกเองก็ได้: พิมพ์ plot_F3_vs_theta2 ใน Command Window
% หรือเรียกแยก:  R = analyze_F3(cfg);  plot_F3(R);

%% ===================== ตั้งค่า =====================
cfg.nameTheta = 'theta2';   % มุม link 2 (deg)  <- จาก PS-Simulink 'theta2_deg'
cfg.nameX     = 'x';        % ตำแหน่ง x ของ F3
cfg.nameV     = 'v_x';      % ความเร็ว x ของ F3
cfg.nameA     = 'a_x';      % ความเร่ง x ของ F3

% หน่วย ต้องตรงกับ Output signal unit ของ PS-Simulink Converter แต่ละตัว
cfg.unitX = 'mm';  cfg.unitV = 'mm/s';  cfg.unitA = 'mm/s^2';

cfg.thRange     = 720;      % ช่วงแกน x (deg): 360 = 1 รอบ, 720 = 2 รอบ
cfg.lastRevOnly = true;     % true = ใช้เฉพาะ thRange องศาสุดท้าย (ตัด transient), false = ทุกรอบซ้อนกัน
cfg.theta0      = 0;        % offset มุม (deg) ถ้าต้องการให้ 0° ตรงกับแบบ
%% ===================================================

%% วิเคราะห์
R = analyze_F3(cfg);

%% ส่งออกไป base workspace
assignin('base', 'F3_result', R);
if height(R.seg) > 0
    assignin('base', 'F3_seg',  R.seg);
    assignin('base', 'delta_x', R.seg.delta_x);
    assignin('base', 'v_avg',   R.seg.v_avg);
    assignin('base', 'a_avg',   R.seg.a_avg);
end

%% แสดงผลใน Command Window
fprintf('\nจุดที่ Vx = 0:\n');
for i = 1:numel(R.thZ)
    fprintf('  theta2 = %7.2f deg   x = %8.3f %s   ax = %9.3f %s\n', ...
            R.thZ(i), R.xZ(i), cfg.unitX, R.aZ(i), cfg.unitA);
end
if height(R.seg) > 0
    fprintf('\nช่วง V=0 -> V=0   [delta_x: %s, v_avg: %s, a_avg: %s, theta: deg]\n', ...
            cfg.unitX, cfg.unitV, cfg.unitA);
    fprintf('(ส่งออกไป workspace: F3_result, F3_seg, delta_x, v_avg, a_avg)\n');
    disp(R.seg);
end
fprintf('x  : min %.4g  max %.4g  %s\n', min(R.x), max(R.x), cfg.unitX);
fprintf('Vx : min %.4g  max %.4g  %s\n', min(R.v), max(R.v), cfg.unitV);
fprintf('ax : min %.4g  max %.4g  %s\n', min(R.a), max(R.a), cfg.unitA);

%% plot
plot_F3(R);
end
