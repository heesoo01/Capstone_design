%% S2B_INSPECT_PORTS
% S2에서 추가한 블록들의 포트 구성을 정확히 확인한다 (연결은 안 함).
% Interface/TorqueSource/Reference 블록들의 LConn/RConn 각 항목이 실제로
% 뭔지(위치, 개수) 알아야 다음 연결 스크립트에서 인덱스를 안전하게 쓸 수 있다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2b_inspect_ports

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2b: 포트 구성 상세 확인 =====\n\n');

blocks_to_check = {'RotIfc', 'MotorTorqueSource', 'MotorRef', 'InterfaceRef', 'Gearbox', 'JointFriction'};

for i = 1:numel(blocks_to_check)
    key = blocks_to_check{i};
    bp = [mdl '/' key];
    fprintf('--- %s ---\n', key);
    try
        h = get_param(bp, 'PortHandles');
        fn = fieldnames(h);
        for j = 1:numel(fn)
            arr = h.(fn{j});
            if isempty(arr); continue; end
            for k = 1:numel(arr)
                try
                    pos = get_param(arr(k), 'Position');
                catch
                    pos = [NaN NaN];
                end
                fprintf('  %s(%d): handle=%.0f, Position=[%.0f, %.0f]\n', fn{j}, k, arr(k), pos(1), pos(2));
            end
        end
    catch ME
        fprintf('  [실패] %s\n', ME.message);
    end

    % PortConnectivity로 좀 더 자세한 정보 (Type, Position)
    try
        pc = get_param(bp, 'PortConnectivity');
        for k = 1:numel(pc)
            fprintf('  PortConnectivity(%d): Type=''%s'', Position=[%.0f, %.0f]\n', ...
                k, pc(k).Type, pc(k).Position(1), pc(k).Position(2));
        end
    catch ME
        fprintf('  [PortConnectivity 실패] %s\n', ME.message);
    end
    fprintf('\n');
end

fprintf('===== 끝. 이 출력을 보고 다음 연결 스크립트를 정확히 짤 것. =====\n');
