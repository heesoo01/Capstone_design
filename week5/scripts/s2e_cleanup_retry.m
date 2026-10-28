%% S2E_CLEANUP_RETRY
% RotIfc 포트에 남아있을 수 있는 유령/끊어진 연결을 확인하고 지운 뒤 재시도.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2e_cleanup_retry

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2e: RotIfc 포트 상태 확인 + 정리 =====\n\n');

hIfc = get_param([mdl '/RotIfc'], 'PortHandles');
allPorts = [hIfc.LConn, hIfc.RConn];
labels = {'LConn1(C)', 'LConn2(t)', 'RConn1(R)', 'RConn2(w)'};

for i = 1:numel(allPorts)
    ph = allPorts(i);
    lineH = get_param(ph, 'Line');
    fprintf('%s : Line=%.0f\n', labels{i}, lineH);
    if lineH ~= -1
        try
            delete_line(lineH);
            fprintf('  -> 삭제함\n');
        catch ME
            fprintf('  -> 삭제 실패: %s\n', ME.message);
        end
    end
end

save_system(mdl);
fprintf('\n--- 정리 후 재연결 시도 ---\n');

function try_connect(mdl, srcH, dstH, label)
    try
        add_line(mdl, srcH, dstH, 'autorouting', 'on');
        fprintf('  [OK] %s\n', label);
    catch ME
        fprintf('  [실패] %s : %s\n', label, ME.message);
    end
end

hIfc  = get_param([mdl '/RotIfc'], 'PortHandles');
hRJ   = get_param([mdl '/RevoluteJoint'], 'PortHandles');
hFric = get_param([mdl '/JointFriction'], 'PortHandles');
hIRef = get_param([mdl '/InterfaceRef'], 'PortHandles');

try_connect(mdl, hRJ.RConn(3), hIfc.RConn(2), 'RevoluteJoint.w -> RotIfc.w');
try_connect(mdl, hIfc.LConn(2), hRJ.LConn(2), 'RotIfc.t -> RevoluteJoint.t');
try_connect(mdl, hFric.RConn(1), hIfc.LConn(1), 'Friction.C -> RotIfc.C');
try_connect(mdl, hIfc.RConn(1), hIRef.LConn(1), 'RotIfc.R -> InterfaceRef');

save_system(mdl);
fprintf('\n===== S2e 끝 =====\n');
