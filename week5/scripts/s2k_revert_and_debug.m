%% S2K_REVERT_AND_DEBUG
% enable_backlash를 'on'으로 되돌리고, 컴파일 에러의 전체 내용을 출력한다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2k_revert_and_debug

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

gb = [mdl '/Gearbox'];

fprintf('===== S2k: enable_backlash 복구 + 에러 상세 =====\n\n');

try
    set_param(gb, 'enable_backlash', 'on');
    fprintf('[OK] enable_backlash = on (복구)\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('현재 설정값들:\n');
fprintf('  ratio = %s\n', get_param(gb, 'ratio'));
fprintf('  enable_backlash = %s\n', get_param(gb, 'enable_backlash'));
fprintf('  backlash_distance = %s %s\n', get_param(gb, 'backlash_distance'), get_param(gb, 'backlash_distance_unit'));

save_system(mdl);
fprintf('\n');

set_param(mdl, 'StopTime', '3');
set_param([mdl '/Motor Torque Command'], 'Value', '0');

fprintf('--- Test A 시도, 에러 전체 출력 ---\n');
try
    sim(mdl);
    fprintf('[OK] 성공\n');
catch ME
    fprintf('[실패] 에러 전체 내용:\n');
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S2k 끝 =====\n');
