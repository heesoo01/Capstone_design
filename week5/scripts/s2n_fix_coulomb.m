%% S2N_FIX_COULOMB
% JointFriction의 Col_trq(쿨롱 마찰 토크)를 0이 아닌 작은 placeholder로.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2n_fix_coulomb

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fr = [mdl '/JointFriction'];

fprintf('===== S2n: 쿨롱 마찰 토크 수정 =====\n\n');

try
    set_param(fr, 'Col_trq', '0.001');
    set_param(fr, 'brkwy_trq', '0.001');
    fprintf('[OK] Col_trq = brkwy_trq = 0.001 N*m (placeholder, 0 불가라서 최소값)\n');
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

fprintf('\n===== S2n 끝. 성공했으면 Scope 스크린샷(A/B) 보내달라. =====\n');
