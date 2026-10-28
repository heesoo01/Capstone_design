%% S2H_CHECK_CONNECTIONS
% 수동으로 연결한 4개 선이 실제로 다 이어졌는지 확인만 한다 (연결 시도 안 함).
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2h_check_connections

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2h: 연결 상태 확인 =====\n\n');

hIfc  = get_param([mdl '/RotIfc'], 'PortHandles');
hRJ   = get_param([mdl '/RevoluteJoint'], 'PortHandles');
hFric = get_param([mdl '/JointFriction'], 'PortHandles');
hIRef = get_param([mdl '/InterfaceRef'], 'PortHandles');

checks = { ...
    hRJ.RConn(3),  'RevoluteJoint.w'; ...
    hIfc.RConn(2), 'RotIfc.w'; ...
    hIfc.LConn(2), 'RotIfc.t'; ...
    hRJ.LConn(2),  'RevoluteJoint.t'; ...
    hFric.RConn(1),'JointFriction.C'; ...
    hIfc.LConn(1), 'RotIfc.C'; ...
    hIfc.RConn(1), 'RotIfc.R'; ...
    hIRef.LConn(1),'InterfaceRef' ...
};

for i = 1:size(checks,1)
    ph = checks{i,1};
    name = checks{i,2};
    lineH = get_param(ph, 'Line');
    status = '연결 안 됨';
    if lineH ~= -1
        status = '연결됨';
    end
    fprintf('  %-20s : %s\n', name, status);
end

fprintf('\n===== 끝 =====\n');
fprintf('4쌍이 둘 다 "연결됨"이어야 완성:\n');
fprintf('  (RevoluteJoint.w, RotIfc.w) / (RotIfc.t, RevoluteJoint.t) /\n');
fprintf('  (JointFriction.C, RotIfc.C) / (RotIfc.R, InterfaceRef)\n');
