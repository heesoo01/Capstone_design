%% S2C_WIRE_GEAR_CHAIN
% S2b 조회 결과를 바탕으로 정확한 포트 인덱스로 연결한다.
%
% 해석 (포트 위치 좌표 기반):
%   RotIfc: LConn(1)/RConn(1) 같은 높이(y=215) = 회전 기계망 R/C
%           LConn(2)/RConn(2) 같은 높이(y=240) = 신호 w(입력, 왼쪽)/t(출력, 오른쪽)
%   MotorTorqueSource: LConn(1)(위, y=196) = 신호 입력 S
%                       RConn(1),RConn(2)(아래, y=254) = 회전 기계망 R/C
%   MotorRef, InterfaceRef: 포트 1개 (LConn(1))
%   Gearbox, JointFriction: 2포트 (LConn(1)=B/입력쪽, RConn(1)=F/출력쪽)
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2c_wire_gear_chain

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2c: 기어 체인 연결 =====\n\n');

function try_connect(mdl, srcH, dstH, label)
    try
        lS = get_param(srcH, 'Line');
        lD = get_param(dstH, 'Line');
        if lS ~= -1 && lD ~= -1
            fprintf('  [건너뜀] %s (둘 다 이미 연결됨)\n', label);
            return;
        end
        add_line(mdl, srcH, dstH, 'autorouting', 'on');
        fprintf('  [OK] %s\n', label);
    catch ME
        fprintf('  [실패] %s : %s\n', label, ME.message);
    end
end

hIfc    = get_param([mdl '/RotIfc'], 'PortHandles');
hTS     = get_param([mdl '/MotorTorqueSource'], 'PortHandles');
hMRef   = get_param([mdl '/MotorRef'], 'PortHandles');
hIRef   = get_param([mdl '/InterfaceRef'], 'PortHandles');
hGear   = get_param([mdl '/Gearbox'], 'PortHandles');
hFric   = get_param([mdl '/JointFriction'], 'PortHandles');
hRJ     = get_param([mdl '/RevoluteJoint'], 'PortHandles');

fprintf('--- 회전 기계망 체인 ---\n');
try_connect(mdl, hMRef.LConn(1), hTS.RConn(1), 'MotorRef -- TorqueSource(C)');
try_connect(mdl, hTS.RConn(2), hGear.LConn(1), 'TorqueSource(R) -- Gearbox(B)');
try_connect(mdl, hGear.RConn(1), hFric.LConn(1), 'Gearbox(F) -- Friction');
try_connect(mdl, hFric.RConn(1), hIfc.LConn(1), 'Friction -- Interface(network)');
try_connect(mdl, hIfc.RConn(1), hIRef.LConn(1), 'Interface(network 반대쪽) -- InterfaceRef');

fprintf('\n--- 조인트 <-> 인터페이스 신호 ---\n');
try_connect(mdl, hRJ.RConn(3), hIfc.LConn(2), 'RevoluteJoint 속도센싱 -- Interface.w');
try_connect(mdl, hIfc.RConn(2), hRJ.LConn(2), 'Interface.t -- RevoluteJoint 토크입력');

fprintf('\n--- 토크 커맨드 신호 ---\n');
try
    hConst = get_param([mdl '/Motor Torque Command'], 'PortHandles');
    hS2PS  = get_param([mdl '/Motor Torque S2PS'], 'PortHandles');
    try_connect(mdl, hConst.Outport(1), hS2PS.Inport(1), 'Constant -- S2PS');
    try_connect(mdl, hS2PS.RConn(1), hTS.LConn(1), 'S2PS -- TorqueSource.S');
catch ME
    fprintf('  [실패] 토크 커맨드 신호: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 기어/마찰 파라미터 이름 (설정은 다음 스크립트에서)
fprintf('--- Simple Gear 파라미터 목록 ---\n');
try
    dpG = get_param([mdl '/Gearbox'], 'DialogParameters');
    disp(fieldnames(dpG));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- Rotational Friction 파라미터 목록 ---\n');
try
    dpF = get_param([mdl '/JointFriction'], 'DialogParameters');
    disp(fieldnames(dpF));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n===== S2c 끝. 출력 전체 + 모델 창 스크린샷 보내달라. =====\n');
