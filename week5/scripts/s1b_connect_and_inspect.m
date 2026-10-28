%% S1B_CONNECT_AND_INSPECT
% s1_mechanical 모델(S1 스크립트로 만든 것)을 열어서:
%   1) 물리 포트를 "숫자 핸들"로 다시 연결한다 (문자열 이름 방식은 실패했었음)
%   2) TorqueActuationMode / MotionActuationMode / SensePosition / SenseVelocity
%      (Revolute Joint) 와 UniformGravity / GravityVector (Mechanism Configuration)
%      의 실제 허용값(Enum)과 현재값을 출력한다 (set_param은 아직 안 함)
%
% *** 아직 실행 전 ***
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s1b_connect_and_inspect

clear; clc;
mdl = 's1_mechanical';

if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S1b: 포트 연결(핸들 방식) + 파라미터 상세 조회 =====\n\n');

names = {'SolverConfiguration','MechanismConfiguration','WorldFrame', ...
         'RevoluteJoint','RigidTransformLink','LinkInertia'};
blk = struct();
for i = 1:numel(names)
    blk.(names{i}) = [mdl '/' names{i}];
end

%% 1. 기존 연결선 제거(있으면) 후 핸들 기반으로 재연결
fprintf('--- 연결 (PortHandles 사용) ---\n');
chain = {'WorldFrame','RevoluteJoint','RigidTransformLink','LinkInertia'};

for i = 1:numel(chain)-1
    aName = chain{i};
    bName = chain{i+1};
    try
        hA = get_param(blk.(aName), 'PortHandles');
        hB = get_param(blk.(bName), 'PortHandles');

        % RConn(오른쪽 포트) -> LConn(왼쪽 포트) 우선 시도, 없으면 RConn끼리
        if isfield(hA,'RConn') && ~isempty(hA.RConn) && isfield(hB,'LConn') && ~isempty(hB.LConn)
            srcH = hA.RConn(1);
            dstH = hB.LConn(1);
        elseif isfield(hA,'RConn') && ~isempty(hA.RConn) && isfield(hB,'RConn') && ~isempty(hB.RConn)
            srcH = hA.RConn(1);
            dstH = hB.RConn(1);
        else
            fprintf('  [건너뜀] %s -> %s : 사용 가능한 포트 조합을 못 찾음 (수동 연결 필요)\n', aName, bName);
            continue;
        end

        % 이미 연결돼 있으면 스킵 (핸들의 Line 속성이 -1이 아니면 연결된 것)
        alreadyA = get_param(srcH, 'Line');
        alreadyB = get_param(dstH, 'Line');
        if alreadyA ~= -1 || alreadyB ~= -1
            fprintf('  [건너뜀] %s -> %s : 이미 연결돼 있는 것 같음\n', aName, bName);
            continue;
        end

        add_line(mdl, srcH, dstH, 'autorouting', 'on');
        fprintf('  [OK] %s -> %s (핸들 연결)\n', aName, bName);
    catch ME
        fprintf('  [실패] %s -> %s : %s\n', aName, bName, ME.message);
    end
end

fprintf('\n');

%% 2. Revolute Joint 파라미터 상세
fprintf('--- Revolute Joint: TorqueActuationMode ---\n');
try
    dp = get_param(blk.RevoluteJoint, 'DialogParameters');
    disp(dp.TorqueActuationMode);
    fprintf('현재값: %s\n', get_param(blk.RevoluteJoint, 'TorqueActuationMode'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- Revolute Joint: MotionActuationMode ---\n');
try
    disp(dp.MotionActuationMode);
    fprintf('현재값: %s\n', get_param(blk.RevoluteJoint, 'MotionActuationMode'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- Revolute Joint: SensePosition ---\n');
try
    disp(dp.SensePosition);
    fprintf('현재값: %s\n', get_param(blk.RevoluteJoint, 'SensePosition'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- Revolute Joint: SenseVelocity ---\n');
try
    disp(dp.SenseVelocity);
    fprintf('현재값: %s\n', get_param(blk.RevoluteJoint, 'SenseVelocity'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

%% 3. Mechanism Configuration 파라미터 상세
fprintf('\n--- Mechanism Configuration: UniformGravity ---\n');
try
    dp2 = get_param(blk.MechanismConfiguration, 'DialogParameters');
    disp(dp2.UniformGravity);
    fprintf('현재값: %s\n', get_param(blk.MechanismConfiguration, 'UniformGravity'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- Mechanism Configuration: GravityVector ---\n');
try
    disp(dp2.GravityVector);
    fprintf('현재값: %s\n', get_param(blk.MechanismConfiguration, 'GravityVector'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
fprintf('\n===== 저장 완료. 위 출력 전체를 붙여넣어 달라. =====\n');
