%% S2T_DISABLE_BACKLASH_TEST
% enable_backlash=0으로 끄고, 나머지 체인(기어비+마찰+인터페이스+모터)이
% 정상 동작하는지 확인. 문제가 백래시 때문인지 isolate하는 테스트.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2t_disable_backlash_test

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

gb = [mdl '/Gearbox'];

fprintf('===== S2t: 백래시 끄고 테스트 =====\n\n');

try
    set_param(gb, 'enable_backlash', '0');
    fprintf('[OK] enable_backlash = 0 (끔)\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '3');

fprintf('\n--- Test A: 토크 0 ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '0');
    sim(mdl);
    fprintf('[OK] Test A 성공!\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n--- Test B: 토크 5 N*m ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '5');
    sim(mdl);
    fprintf('[OK] Test B 성공!\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n===== S2t 끝. 결과 알려달라. 성공하면 Scope 스크린샷도. =====\n');
