%% S2S_RELAX_AND_RETRY
% ConsistencyTolSource를 LOCAL로 바꾸고 허용오차를 완화해서 재시도.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2s_relax_and_retry

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

sc = [mdl '/SolverConfiguration'];

fprintf('===== S2s: 허용오차 완화 =====\n\n');

try
    set_param(sc, 'ConsistencyTolSource', 'LOCAL');
    set_param(sc, 'ConsistencyAbsTol', '0.05');
    set_param(sc, 'ConsistencyRelTol', '0.05');
    set_param(sc, 'ConsistencyTolFactor', '0.05');
    fprintf('[OK] ConsistencyTolSource=LOCAL, AbsTol/RelTol/TolFactor=0.05로 완화\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

try
    set_param(sc, 'MaxNonlinIter', '200');
    fprintf('[OK] MaxNonlinIter = 200 (기본보다 늘림)\n');
catch ME
    fprintf('[실패] MaxNonlinIter: %s\n', ME.message);
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

fprintf('\n===== S2s 끝. 성공했으면 Scope 스크린샷(A/B) 보내달라. =====\n');
