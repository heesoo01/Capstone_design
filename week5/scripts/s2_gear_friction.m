%% S2_GEAR_FRICTION
% S1의 "신호로 토크 직접 주입" 방식을 걷어내고,
% 조인트 <-> Rotational Multibody Interface <-> (임시 토크원)-기어(백래시)-마찰
% 구조로 바꾼다. 기어비/백래시/마찰계수 등은 아직 안 정하고 "파라미터 이름"만 조회한다.
%
% *** 아직 실행 전 ***
%
% 임시 토크원(Ideal Torque Source)은 S3에서 PMSM+인버터로 교체될 자리다.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2_gear_friction

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2: 인터페이스 + 기어 + 마찰 구조로 재배선 =====\n\n');

%% 1. 기존 "직접 토크 주입" 배선 제거
rj = [mdl '/RevoluteJoint'];
hRJ = get_param(rj, 'PortHandles');
torque_in = hRJ.LConn(2);  % S1c에서 새로 생긴 토크 입력 포트

lineIn = get_param(torque_in, 'Line');
if lineIn ~= -1
    try
        delete_line(lineIn);
        fprintf('[OK] 기존 토크 입력 배선 제거\n');
    catch ME
        fprintf('[실패] 기존 배선 제거: %s\n', ME.message);
    end
end

% Torque Command, Torque S2PS 블록은 이제 안 쓰므로 삭제 (있으면)
for bname = {'Torque Command', 'Torque S2PS'}
    bp = [mdl '/' bname{1}];
    try
        delete_block(bp);
        fprintf('[OK] 안 쓰는 블록 삭제: %s\n', bname{1});
    catch
        fprintf('[정보] %s 이미 없음\n', bname{1});
    end
end
fprintf('\n');

%% 2. 새 블록 배치
newblocks = struct( ...
    'RotIfc',   'fl_lib/Mechanical/Multibody Interfaces/Rotational Multibody Interface', ...
    'Gearbox',  'sdl_lib/Gears/Simple Gear', ...
    'JointFriction', 'fl_lib/Mechanical/Rotational Elements/Rotational Friction', ...
    'MotorTorqueSource', 'fl_lib/Mechanical/Mechanical Sources/Ideal Torque Source', ...
    'MotorRef', 'fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference', ...
    'InterfaceRef', 'fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference' ...
);
nb = fieldnames(newblocks);
y = 200;
placed2 = struct();
for i = 1:numel(nb)
    key = nb{i};
    src = newblocks.(key);
    dst = [mdl '/' key];
    try
        add_block(src, dst, 'Position', [150+120*(i-1), y, 150+120*(i-1)+70, y+50]);
        fprintf('[OK] 배치: %s (%s)\n', key, src);
        placed2.(key) = dst;
    catch ME
        fprintf('[실패] 배치: %s -> %s\n', src, ME.message);
        placed2.(key) = '';
    end
end
fprintf('\n');

%% 3. 토크 커맨드용 Constant + Simulink-PS Converter (모터 임시 입력)
try
    add_block('simulink/Sources/Constant', [mdl '/Motor Torque Command'], ...
        'Position', [150 300 210 330], 'Value', '0');
    add_block('nesl_utility/Simulink-PS Converter', [mdl '/Motor Torque S2PS'], ...
        'Position', [250 300 310 330]);
    fprintf('[OK] Motor Torque Command + S2PS 배치\n');
catch ME
    fprintf('[실패] Motor Torque Command 체인: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 4. 연결 (실패해도 계속 진행, 결과 보고 고치기)
fprintf('--- 연결 ---\n');

function try_connect(mdl, srcH, dstH, label)
    try
        if get_param(srcH, 'Line') == -1 && get_param(dstH, 'Line') == -1
            add_line(mdl, srcH, dstH, 'autorouting', 'on');
            fprintf('  [OK] %s\n', label);
        else
            fprintf('  [건너뜀] %s (이미 연결된 것 같음)\n', label);
        end
    catch ME
        fprintf('  [실패] %s : %s\n', label, ME.message);
    end
end

% 조인트 각속도 센싱(RConn(3), S1g에서 확인) -> Interface.w
hRJ = get_param(rj, 'PortHandles');
hIfc = get_param(placed2.RotIfc, 'PortHandles');

% w, t는 물리신호 포트라 Inport/Outport 쪽에 잡힐 수도 있어 둘 다 확인
fprintf('Interface 포트 구성: ');
disp(hIfc);

% 속도센싱 -> Interface (branch, 이미 Scope에도 연결돼 있어야 하므로 굳이 끊지 않음)
try
    add_line(mdl, hRJ.RConn(3), hIfc.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] RevoluteJoint 속도센싱 -> Interface.w\n');
catch ME
    fprintf('  [실패] 속도센싱 -> Interface.w : %s (Interface 포트 구성 위 출력 참고해서 수동 확인 필요)\n', ME.message);
end

% Interface.t -> 조인트 토크 입력
try
    add_line(mdl, hIfc.Outport(1), torque_in, 'autorouting', 'on');
    fprintf('  [OK] Interface.t -> RevoluteJoint 토크입력\n');
catch ME
    fprintf('  [실패] Interface.t -> 토크입력 : %s\n', ME.message);
end

% 회전 기계망 체인: MotorRef -- MotorTorqueSource -- Gearbox -- JointFriction -- Interface(R) , Interface(C) -- InterfaceRef
hMotorRef = get_param(placed2.MotorRef, 'PortHandles');
hTS       = get_param(placed2.MotorTorqueSource, 'PortHandles');
hGear     = get_param(placed2.Gearbox, 'PortHandles');
hFric     = get_param(placed2.JointFriction, 'PortHandles');
hIfcRef   = get_param(placed2.InterfaceRef, 'PortHandles');

try_connect(mdl, hMotorRef.RConn(1), hTS.LConn(1), 'MotorRef -> TorqueSource(C)');
try_connect(mdl, hTS.RConn(1), hGear.LConn(1), 'TorqueSource(R) -> Gearbox(B)');
try_connect(mdl, hGear.RConn(1), hFric.LConn(1), 'Gearbox(F) -> Friction');
try_connect(mdl, hFric.RConn(1), hIfc.LConn(1), 'Friction -> Interface(R)');
try_connect(mdl, hIfc.RConn(1), hIfcRef.RConn(1), 'Interface(C) -> InterfaceRef');

% 토크 커맨드 신호 -> Simulink-PS Converter -> TorqueSource 신호입력
try
    hConst = get_param([mdl '/Motor Torque Command'], 'PortHandles');
    hS2PS  = get_param([mdl '/Motor Torque S2PS'], 'PortHandles');
    add_line(mdl, hConst.Outport(1), hS2PS.Inport(1), 'autorouting', 'on');
    add_line(mdl, hS2PS.RConn(1), hTS.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] Motor Torque Command -> S2PS -> TorqueSource 신호입력\n');
catch ME
    fprintf('  [실패] 토크 커맨드 신호 연결: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 5. 기어/마찰 파라미터 이름 조회 (아직 설정 안 함)
fprintf('--- Simple Gear 파라미터 목록 ---\n');
try
    dpG = get_param(placed2.Gearbox, 'DialogParameters');
    disp(fieldnames(dpG));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- Rotational Friction 파라미터 목록 ---\n');
try
    dpF = get_param(placed2.JointFriction, 'DialogParameters');
    disp(fieldnames(dpF));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n===== S2 배선 끝 =====\n');
fprintf('[실패]가 있으면 그대로 붙여넣어 달라 (특히 Interface 연결 부분).\n');
fprintf('성공한 부분이 많으면 모델 창 스크린샷도 보내달라.\n');
fprintf('이번엔 시뮬레이션은 아직 안 돌렸다 -- 기어비/마찰계수부터 정해야 하기 때문.\n');
