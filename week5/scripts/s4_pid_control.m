%% S4_PID_CONTROL
% S3(PMSM/인버터)는 나중으로 미루고, 지금 있는 MotorTorqueSource(이상적
% 토크원)를 "임시 모터"로 그대로 쓴 채 PID 위치제어를 얹는다.
%
% 구조: 목표각(Step) -> 오차(Sum) <- 현재각(RevoluteJoint.q 센싱)
%       오차 -> PID Controller -> (기존 Motor Torque S2PS) -> MotorTorqueSource
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s4_pid_control

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

fprintf('===== S4: PID 위치제어 배선 (임시 모터 사용) =====\n\n');

%% 1. 기존 Motor Torque Command(상수)를 끊고 PID로 교체
mtc = [mdl '/Motor Torque Command'];
hMTC = get_param(mtc, 'PortHandles');
lineOut = get_param(hMTC.Outport(1), 'Line');
if lineOut ~= -1
    try
        delete_line(lineOut);
        fprintf('[OK] 기존 Motor Torque Command 출력선 제거\n');
    catch ME
        fprintf('[실패] 기존 선 제거: %s\n', ME.message);
    end
end
try
    delete_block(mtc);
    fprintf('[OK] Motor Torque Command(상수) 블록 삭제\n');
catch ME
    fprintf('[정보] 이미 없음: %s\n', ME.message);
end

%% 2. 새 블록: 목표각, Sum, PID Controller
try
    add_block('simulink/Sources/Step', [mdl '/Angle Reference'], ...
        'Position', [20 400 80 430], 'Time', '0.5', 'Before', '0', 'After', '30');
    fprintf('[OK] Angle Reference(Step, 0->30deg at t=0.5s) 배치\n');
catch ME
    fprintf('[실패] Angle Reference: %s\n', ME.message);
end

try
    add_block('simulink/Math Operations/Sum', [mdl '/Angle Error'], ...
        'Position', [150 400 180 430], 'Inputs', '+-');
    fprintf('[OK] Angle Error(Sum) 배치\n');
catch ME
    fprintf('[실패] Angle Error: %s\n', ME.message);
end

try
    add_block('simulink/Continuous/PID Controller', [mdl '/PID Controller'], ...
        'Position', [220 390 310 440], 'P', num2str(p.ctrl.Kp), 'I', num2str(p.ctrl.Ki), ...
        'D', num2str(p.ctrl.Kd));
    fprintf('[OK] PID Controller 배치 (Kp=%g, Ki=%g, Kd=%g)\n', p.ctrl.Kp, p.ctrl.Ki, p.ctrl.Kd);
catch ME
    fprintf('[실패] PID Controller: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 3. 연결
fprintf('--- 연결 ---\n');
hRef = get_param([mdl '/Angle Reference'], 'PortHandles');
hErr = get_param([mdl '/Angle Error'], 'PortHandles');
hPID = get_param([mdl '/PID Controller'], 'PortHandles');
hS2PS = get_param([mdl '/Motor Torque S2PS'], 'PortHandles');

% 현재각 센싱(Sense1 PS2S 출력)을 가져와서 branch
hSense1 = get_param([mdl '/Sense1 PS2S'], 'PortHandles');

try
    add_line(mdl, hRef.Outport(1), hErr.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] Angle Reference -> Angle Error(+)\n');
catch ME
    fprintf('  [실패] Reference->Error: %s\n', ME.message);
end

try
    add_line(mdl, hSense1.Outport(1), hErr.Inport(2), 'autorouting', 'on');
    fprintf('  [OK] Sense1(현재각) -> Angle Error(-)\n');
catch ME
    fprintf('  [실패] Sense->Error: %s\n', ME.message);
end

try
    add_line(mdl, hErr.Outport(1), hPID.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] Angle Error -> PID\n');
catch ME
    fprintf('  [실패] Error->PID: %s\n', ME.message);
end

try
    add_line(mdl, hPID.Outport(1), hS2PS.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] PID -> Motor Torque S2PS\n');
catch ME
    fprintf('  [실패] PID->S2PS: %s\n', ME.message);
end

save_system(mdl);

%% 4. 단위 확인 (Sense1이 rad인지 deg인지 -- Step 레퍼런스 단위랑 맞춰야 함)
fprintf('\n--- 단위 확인 ---\n');
try
    senseUnit = get_param([mdl '/RevoluteJoint'], 'PositionTargetValueUnits');
    fprintf('참고용 PositionTargetValueUnits: %s (실제 센싱 출력 단위와 다를 수 있음, 아래 q_unit 확인)\n', senseUnit);
catch
end
try
    qUnit = get_param([mdl '/RevoluteJoint'], 'q_unit');
    fprintf('q(위치 센싱) 단위: %s\n', qUnit);
catch ME
    fprintf('q_unit 조회 실패(파라미터 이름 다를 수 있음): %s\n', ME.message);
end

fprintf('\n===== S4 배선 끝. [실패] 있으면 알려주고, 단위 확인 후 다음 스크립트에서 시뮬레이션. =====\n');
