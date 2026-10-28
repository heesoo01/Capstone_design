%% S2M_LOGICAL_VALUE
% enable_backlash에 logical 타입 값(true 또는 1)으로 설정 시도.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2m_logical_value

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

gb = [mdl '/Gearbox'];

fprintf('===== S2m: logical 값으로 재시도 =====\n\n');

fprintf('--- 시도 1: true ---\n');
try
    set_param(gb, 'enable_backlash', 'true');
    fprintf('[OK] 설정됨, 저장된 값: %s\n', get_param(gb, 'enable_backlash'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '3');
set_param([mdl '/Motor Torque Command'], 'Value', '0');

try
    sim(mdl);
    fprintf('[OK] 시뮬레이션 성공! (enable_backlash=true)\n');
catch ME
    fprintf('[실패] 시뮬레이션: %s\n', ME.message);

    fprintf('\n--- 시도 2: 1 (숫자) ---\n');
    try
        set_param(gb, 'enable_backlash', '1');
        fprintf('[OK] 설정됨, 저장된 값: %s\n', get_param(gb, 'enable_backlash'));
    catch ME2
        fprintf('[실패] %s\n', ME2.message);
    end

    save_system(mdl);
    try
        sim(mdl);
        fprintf('[OK] 시뮬레이션 성공! (enable_backlash=1)\n');
    catch ME3
        fprintf('[실패] 시뮬레이션: \n');
        disp(getReport(ME3, 'extended', 'hyperlinks', 'off'));
    end
end

fprintf('\n===== S2m 끝 =====\n');
