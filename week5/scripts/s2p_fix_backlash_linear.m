%% S2P_FIX_BACKLASH_LINEAR
% backlash_distance를 원래 단위(mm, 선형)로 되돌리고, r_base를 이용해
% 0.5도에 해당하는 선형 변위 값으로 환산해서 설정.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2p_fix_backlash_linear

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

gb = [mdl '/Gearbox'];

fprintf('===== S2p: 백래시 선형 단위로 재설정 =====\n\n');

% r_base 읽기 (m 단위, 아까 0.1m로 확인됨)
r_base_val = str2double(get_param(gb, 'r_base'));
r_base_unit = get_param(gb, 'r_base_unit');
fprintf('현재 r_base = %g %s\n', r_base_val, r_base_unit);

backlash_rad = deg2rad(p.gear.backlash_deg);
backlash_linear_m = r_base_val * backlash_rad;
backlash_linear_mm = backlash_linear_m * 1000;
fprintf('0.5deg -> 선형 환산 = %g mm (r_base=%g m 기준)\n\n', backlash_linear_mm, r_base_val);

try
    set_param(gb, 'backlash_distance_unit', 'mm');
    set_param(gb, 'backlash_distance', num2str(backlash_linear_mm));
    fprintf('[OK] backlash_distance = %g mm\n', backlash_linear_mm);
catch ME
    fprintf('[실패] %s\n', ME.message);
end

try
    set_param(gb, 'transition_unit', 'mm');
    fprintf('[OK] transition_unit = mm (원래대로)\n');
catch ME
    fprintf('[실패] transition_unit: %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '3');

fprintf('\n--- Test A: 토크 0 ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '0');
    sim(mdl);
    fprintf('[OK] Test A 성공!\n');
catch ME
    fprintf('[실패]:\n');
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n--- Test B: 토크 5 N*m ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '5');
    sim(mdl);
    fprintf('[OK] Test B 성공!\n');
catch ME
    fprintf('[실패]:\n');
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S2p 끝. 성공했으면 Scope 스크린샷(A/B) 보내달라. =====\n');
