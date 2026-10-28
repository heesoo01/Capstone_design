%% S1G_FIX_JOINT_AXIS_AND_MASS
% 문제 1: RevoluteJoint 회전축이 WorldFrame Z축(=중력 방향)과 평행해서
%         중력 토크가 구조적으로 0이 됨. -> 축을 눕히는 Rigid Transform 추가.
% 문제 2: RigidTransformLink의 TranslationMethod가 'None'이라 오프셋이 적용 안 됨.
% 문제 3: LinkInertia 질량을 config/params.m 값으로 맞춤.
%
% Enum 문자열은 하드코딩하지 않고, 실제 후보 리스트에서 'Standard'가 포함된
% 항목을 코드가 찾아서 쓴다 (추측 아님, 실행 중 실제 값을 조회해서 사용).
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s1g_fix_joint_axis_and_mass

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

fprintf('===== S1g: 관절 축 방향 + 링크 오프셋/질량 수정 =====\n\n');

%% 1. WorldFrame에서 나가는 기존 연결선 정리 (RevoluteJoint로 가는 것만 지우고 싶지만,
%     물리망은 공유 노드라 안전하게 WorldFrame 쪽 선을 전부 지우고 다시 잇는다)
hWorld = get_param([mdl '/WorldFrame'], 'PortHandles');
lineH = get_param(hWorld.RConn(1), 'Line');
if lineH ~= -1
    try
        delete_line(lineH);
        fprintf('[OK] WorldFrame 기존 연결선 삭제\n');
    catch ME
        fprintf('[실패] 기존 연결선 삭제: %s (그냥 진행, 연결이 겹칠 수 있음)\n', ME.message);
    end
else
    fprintf('[정보] WorldFrame에 기존 연결선 없음\n');
end

%% 2. 축을 눕히는 Rigid Transform 추가
try
    add_block('sm_lib/Frames and Transforms/Rigid Transform', [mdl '/RigidTransformJointAxis'], ...
        'Position', [150 130 210 160]);
    fprintf('[OK] RigidTransformJointAxis 배치\n');
catch ME
    fprintf('[정보] RigidTransformJointAxis: %s (이미 있으면 무시)\n', ME.message);
end

rtAxis = [mdl '/RigidTransformJointAxis'];
dpAxis = get_param(rtAxis, 'DialogParameters');
rotMethodOptions = dpAxis.RotationMethod.Enum;
rotStdIdx = find(contains(rotMethodOptions, 'Standard', 'IgnoreCase', true), 1);
if isempty(rotStdIdx)
    fprintf('[실패] RotationMethod에 "Standard"가 포함된 옵션을 못 찾음. 후보: %s\n', strjoin(rotMethodOptions, ' / '));
else
    rotMethodValue = rotMethodOptions{rotStdIdx};
    try
        set_param(rtAxis, 'RotationMethod', rotMethodValue);
        set_param(rtAxis, 'RotationStandardAxis', '+X');
        set_param(rtAxis, 'RotationAngle', '90');
        fprintf('[OK] RigidTransformJointAxis: RotationMethod=%s, Axis=+X, Angle=90deg\n', rotMethodValue);
    catch ME
        fprintf('[실패] RigidTransformJointAxis 회전 설정: %s\n', ME.message);
    end
end

%% 3. 다시 연결: WorldFrame -> RigidTransformJointAxis -> RevoluteJoint
hWorld = get_param([mdl '/WorldFrame'], 'PortHandles');
hAxis  = get_param(rtAxis, 'PortHandles');
hRJ    = get_param([mdl '/RevoluteJoint'], 'PortHandles');
hSolver = get_param([mdl '/SolverConfiguration'], 'PortHandles');
hMech   = get_param([mdl '/MechanismConfiguration'], 'PortHandles');

try
    add_line(mdl, hWorld.RConn(1), hAxis.LConn(1), 'autorouting', 'on');
    fprintf('[OK] WorldFrame -> RigidTransformJointAxis\n');
catch ME
    fprintf('[실패] WorldFrame -> RigidTransformJointAxis : %s\n', ME.message);
end

try
    add_line(mdl, hAxis.RConn(1), hRJ.LConn(1), 'autorouting', 'on');
    fprintf('[OK] RigidTransformJointAxis -> RevoluteJoint\n');
catch ME
    fprintf('[실패] RigidTransformJointAxis -> RevoluteJoint : %s\n', ME.message);
end

% Solver/Mechanism Configuration 다시 브랜치 (기존 선을 지웠으므로 재연결)
try
    if get_param(hSolver.RConn(1), 'Line') == -1
        add_line(mdl, hWorld.RConn(1), hSolver.RConn(1), 'autorouting', 'on');
        fprintf('[OK] SolverConfiguration 재연결\n');
    end
catch ME
    fprintf('[실패] SolverConfiguration 재연결: %s\n', ME.message);
end

try
    if get_param(hMech.RConn(1), 'Line') == -1
        add_line(mdl, hWorld.RConn(1), hMech.RConn(1), 'autorouting', 'on');
        fprintf('[OK] MechanismConfiguration 재연결\n');
    end
catch ME
    fprintf('[실패] MechanismConfiguration 재연결: %s\n', ME.message);
end

fprintf('\n');

%% 4. RigidTransformLink 오프셋 설정 (링크 길이만큼, +X 방향)
rt = [mdl '/RigidTransformLink'];
dpRT = get_param(rt, 'DialogParameters');
transMethodOptions = dpRT.TranslationMethod.Enum;
transStdIdx = find(contains(transMethodOptions, 'Standard', 'IgnoreCase', true), 1);
if isempty(transStdIdx)
    fprintf('[실패] TranslationMethod에 "Standard"가 포함된 옵션을 못 찾음. 후보: %s\n', strjoin(transMethodOptions, ' / '));
else
    transMethodValue = transMethodOptions{transStdIdx};
    try
        set_param(rt, 'TranslationMethod', transMethodValue);
        set_param(rt, 'TranslationStandardAxis', '+X');
        set_param(rt, 'TranslationStandardOffset', num2str(p.mech.link_len));
        fprintf('[OK] RigidTransformLink: TranslationMethod=%s, Axis=+X, Offset=%.3f m\n', ...
            transMethodValue, p.mech.link_len);
    catch ME
        fprintf('[실패] RigidTransformLink 오프셋 설정: %s\n', ME.message);
    end
end

%% 5. LinkInertia 질량 설정
li = [mdl '/LinkInertia'];
try
    set_param(li, 'Mass', num2str(p.mech.link_mass));
    fprintf('[OK] LinkInertia Mass = %.3f kg\n', p.mech.link_mass);
catch ME
    fprintf('[실패] LinkInertia Mass 설정: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 6. 다시 테스트
set_param(mdl, 'StopTime', '3');

fprintf('--- Test A: 토크 0 (수평에서 시작, 중력으로 처지는지) ---\n');
try
    set_param([mdl '/Torque Command'], 'Value', '0');
    sim(mdl);
    fprintf('[OK] Test A 완료\n');
catch ME
    fprintf('[실패] Test A: %s\n', ME.message);
end

fprintf('\n--- Test B: 토크 5 N*m ---\n');
try
    set_param([mdl '/Torque Command'], 'Value', '5');
    sim(mdl);
    fprintf('[OK] Test B 완료\n');
catch ME
    fprintf('[실패] Test B: %s\n', ME.message);
end

fprintf('\n===== S1g 끝 =====\n');
fprintf('에러 있으면 그대로 붙여넣고, 성공했으면 Scope 스크린샷(Test A / Test B 각 1장)을 보내달라.\n');
