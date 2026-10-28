%% S2L_QUOTED_VALUE
% enable_backlash에 따옴표 포함 문자열("'on'")로 설정 시도.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2l_quoted_value

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

gb = [mdl '/Gearbox'];

fprintf('===== S2l: 따옴표 포함 값으로 재시도 =====\n\n');

try
    set_param(gb, 'enable_backlash', '''on''');
    fprintf('[OK] enable_backlash 설정 (따옴표 포함)\n');
    fprintf('     저장된 값: %s\n', get_param(gb, 'enable_backlash'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

set_param(mdl, 'StopTime', '3');
set_param([mdl '/Motor Torque Command'], 'Value', '0');

fprintf('--- Test A 시도 ---\n');
try
    sim(mdl);
    fprintf('[OK] 성공!\n');
catch ME
    fprintf('[실패] 에러 전체:\n');
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S2l 끝 =====\n');
