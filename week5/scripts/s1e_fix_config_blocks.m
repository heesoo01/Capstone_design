%% S1E_FIX_CONFIG_BLOCKS
% SolverConfiguration, MechanismConfiguration을 물리 네트워크에 연결한다.
% 이미 연결돼 있는 WorldFrame 포트에서 가지치기(branch)로 잇는다.
%
% *** 아직 실행 전 ***
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s1e_fix_config_blocks

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S1e: Solver/Mechanism Configuration 연결 =====\n\n');

hWorld  = get_param([mdl '/WorldFrame'], 'PortHandles');
hSolver = get_param([mdl '/SolverConfiguration'], 'PortHandles');
hMech   = get_param([mdl '/MechanismConfiguration'], 'PortHandles');

worldPort = hWorld.RConn(1);

try
    if get_param(hSolver.RConn(1), 'Line') == -1
        add_line(mdl, worldPort, hSolver.RConn(1), 'autorouting', 'on');
        fprintf('[OK] SolverConfiguration -> WorldFrame 노드에 연결\n');
    else
        fprintf('[건너뜀] SolverConfiguration 이미 연결됨\n');
    end
catch ME
    fprintf('[실패] SolverConfiguration 연결: %s\n', ME.message);
end

try
    if get_param(hMech.RConn(1), 'Line') == -1
        add_line(mdl, worldPort, hMech.RConn(1), 'autorouting', 'on');
        fprintf('[OK] MechanismConfiguration -> WorldFrame 노드에 연결\n');
    else
        fprintf('[건너뜀] MechanismConfiguration 이미 연결됨\n');
    end
catch ME
    fprintf('[실패] MechanismConfiguration 연결: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 다시 테스트
set_param(mdl, 'StopTime', '3');

fprintf('--- Test A: 토크 0 ---\n');
try
    set_param([mdl '/Torque Command'], 'Value', '0');
    sim(mdl);
    fprintf('[OK] Test A 시뮬레이션 완료\n');
catch ME
    fprintf('[실패] Test A: %s\n', ME.message);
end

fprintf('\n--- Test B: 토크 5 N*m ---\n');
try
    set_param([mdl '/Torque Command'], 'Value', '5');
    sim(mdl);
    fprintf('[OK] Test B 시뮬레이션 완료\n');
catch ME
    fprintf('[실패] Test B: %s\n', ME.message);
end

fprintf('\n===== S1e 끝. 에러 있으면 그대로, 성공했으면 Scope 스크린샷 2개(A/B) 보내달라. =====\n');
