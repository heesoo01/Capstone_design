%% S2D_FINAL_WIRE
% 스크린샷으로 확인된 정확한 포트 방향으로 재연결.
%   RotIfc: LConn(1)=C(회전망), LConn(2)=t(출력, 조인트로 나감)
%           RConn(1)=R(회전망), RConn(2)=w(입력, 조인트에서 들어옴)
%   RevoluteJoint: RConn(3)=w(속도, 출력) -> RotIfc.w(RConn(2))로
%                  RotIfc.t(LConn(2)) -> RevoluteJoint의 t(LConn(2), 입력)로
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2d_final_wire

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2d: 최종 배선 수정 =====\n\n');

function try_connect(mdl, srcH, dstH, label)
    try
        lS = get_param(srcH, 'Line');
        lD = get_param(dstH, 'Line');
        if lS ~= -1 && lD ~= -1
            fprintf('  [건너뜀] %s (이미 연결됨)\n', label);
            return;
        end
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
hMRef = get_param([mdl '/MotorRef'], 'PortHandles');
hTS   = get_param([mdl '/MotorTorqueSource'], 'PortHandles');
hS2PS = get_param([mdl '/Motor Torque S2PS'], 'PortHandles');

fprintf('--- 신호 (w/t 방향 수정) ---\n');
try_connect(mdl, hRJ.RConn(3), hIfc.RConn(2), 'RevoluteJoint.w(속도) -> RotIfc.w');
try_connect(mdl, hIfc.LConn(2), hRJ.LConn(2), 'RotIfc.t -> RevoluteJoint.t(토크입력)');

fprintf('\n--- 회전 기계망 (Friction -- Interface -- InterfaceRef) ---\n');
try_connect(mdl, hFric.RConn(1), hIfc.LConn(1), 'Friction.C -> RotIfc.C(LConn1)');
try_connect(mdl, hIfc.RConn(1), hIRef.LConn(1), 'RotIfc.R(RConn1) -> InterfaceRef');

fprintf('\n--- 회전 기계망 (MotorRef -- TorqueSource) ---\n');
try_connect(mdl, hMRef.LConn(1), hTS.LConn(1), 'MotorRef -> TorqueSource.LConn(1)');

fprintf('\n--- 토크 커맨드 신호 -> TorqueSource ---\n');
try_connect(mdl, hS2PS.RConn(1), hTS.RConn(1), 'S2PS -> TorqueSource.RConn(1)');

save_system(mdl);
fprintf('\n===== S2d 끝. 아직 [실패] 있으면 그대로 붙여넣어 달라. =====\n');
