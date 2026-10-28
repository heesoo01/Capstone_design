%% S1_CREATE_MECHANICAL
% S1: 회전 관절 + 링크(관성) + 중력, 골격 모델을 만든다.
%
% *** 아직 실행 전 — 이 스크립트는 MATLAB에서 한 번도 돌려보지 않았다. ***
%
% 이 스크립트가 하는 일:
%   1) S0에서 확인한 블록들(World Frame, Solver Configuration,
%      Mechanism Configuration, Revolute Joint, Rigid Transform, Inertia)을
%      새 모델에 배치한다.
%   2) 포트를 "이름을 추측해서" 잇지 않는다. 대신 각 블록에
%      get_param(...,'PortConnectivity')로 실제 포트 이름을 먼저 물어보고,
%      그 이름으로 연결을 시도한다. 실패하면 실패했다고만 출력하고 멈추지 않는다.
%   3) 아직 설정 안 한 것 (일부러 안 건드림):
%        - Revolute Joint의 "토크를 입력으로 받기" 옵션
%        - Mechanism Configuration의 중력 설정 확인
%      -> 이 두 블록의 실제 파라미터 이름 목록을 출력만 한다.
%         정확한 이름을 모르고 set_param을 쓰면 틀릴 수 있기 때문.
%         목록을 보고 다음 스크립트에서 정확히 설정한다.
%
% 실행법:
%   cd D:\Capstone_design\week5\scripts
%   s1_create_mechanical
%   -> 뜨는 모델 창 스크린샷 + 명령창 출력 전체를 붙여넣어 달라.

clear; clc;
mdl = 's1_mechanical';

if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
new_system(mdl);
open_system(mdl);

fprintf('===== S1: 모델 골격 생성 =====\n\n');

%% 1. 블록 배치
blocks = struct( ...
    'SolverConfiguration', 'nesl_utility/Solver Configuration', ...
    'MechanismConfiguration', 'sm_lib/Utilities/Mechanism Configuration', ...
    'WorldFrame', 'sm_lib/Frames and Transforms/World Frame', ...
    'RevoluteJoint', 'sm_lib/Joints/Revolute Joint', ...
    'RigidTransformLink', 'sm_lib/Frames and Transforms/Rigid Transform', ...
    'LinkInertia', 'sm_lib/Body Elements/Inertia' ...
);

names = fieldnames(blocks);
pos_x = 30;
placed = struct();

for i = 1:numel(names)
    key = names{i};
    src = blocks.(key);
    dst = [mdl '/' strrep(key, '_', ' ')];
    try
        add_block(src, dst, 'Position', [pos_x, 40, pos_x+70, 90]);
        fprintf('[OK] 배치: %s  (%s)\n', dst, src);
        placed.(key) = dst;
    catch ME
        fprintf('[실패] 배치: %s -> %s\n', src, ME.message);
        placed.(key) = '';
    end
    pos_x = pos_x + 120;
end
fprintf('\n');

%% 2. 각 블록의 실제 포트 이름 출력 (추측 금지, 조회만)
fprintf('--- 포트 이름 조회 ---\n');
port_names = struct();
for i = 1:numel(names)
    key = names{i};
    if isempty(placed.(key)); continue; end
    try
        pc = get_param(placed.(key), 'PortConnectivity');
        types = {pc.Type};
        port_names.(key) = types;
        fprintf('  %-24s : %s\n', key, strjoin(types, ', '));
    catch ME
        fprintf('  %-24s : [조회 실패] %s\n', key, ME.message);
        port_names.(key) = {};
    end
end
fprintf('\n');

%% 3. 체인으로 연결 시도: World Frame -> Revolute Joint -> Rigid Transform -> Inertia
% 각 블록의 "첫 번째 포트"를 이전 블록의 "마지막 포트"에 잇는 단순한 방식.
% 물리 포트는 방향이 없는 경우가 많아 이 방식이 대체로 통하지만,
% 실패하면 GUI에서 직접 드래그해서 연결하면 된다 (이 스크립트가 필수는 아님).
chain = {'WorldFrame', 'RevoluteJoint', 'RigidTransformLink', 'LinkInertia'};

fprintf('--- 연결 시도 ---\n');
for i = 1:numel(chain)-1
    a_key = chain{i};
    b_key = chain{i+1};
    if isempty(placed.(a_key)) || isempty(placed.(b_key))
        fprintf('  [건너뜀] %s -> %s (블록이 없음)\n', a_key, b_key);
        continue;
    end
    a_ports = port_names.(a_key);
    b_ports = port_names.(b_key);
    if isempty(a_ports) || isempty(b_ports)
        fprintf('  [건너뜀] %s -> %s (포트 정보 없음, GUI에서 수동 연결)\n', a_key, b_key);
        continue;
    end
    a_port = [placed.(a_key) '/' a_ports{end}];
    b_port = [placed.(b_key) '/' b_ports{1}];
    try
        add_line(mdl, a_port, b_port, 'autorouting', 'on');
        fprintf('  [OK] %s -> %s\n', a_port, b_port);
    catch ME
        fprintf('  [실패] %s -> %s : %s\n', a_port, b_port, ME.message);
    end
end
fprintf('\n');

%% 4. 파라미터 이름 확인용 출력 (set_param은 아직 하지 않음)
fprintf('--- Revolute Joint 파라미터 목록 (토크 입력 옵션 찾기용) ---\n');
if ~isempty(placed.RevoluteJoint)
    try
        dp = get_param(placed.RevoluteJoint, 'DialogParameters');
        disp(dp);
    catch ME
        fprintf('[실패] %s\n', ME.message);
    end
end

fprintf('\n--- Mechanism Configuration 파라미터 목록 (중력 설정 확인용) ---\n');
if ~isempty(placed.MechanismConfiguration)
    try
        dp2 = get_param(placed.MechanismConfiguration, 'DialogParameters');
        disp(dp2);
    catch ME
        fprintf('[실패] %s\n', ME.message);
    end
end

save_system(mdl);
fprintf('\n===== 저장 완료: %s.slx (week5/scripts 폴더 안) =====\n', mdl);
fprintf('1) 모델 창에서 블록/선이 이상하게 연결돼 있으면 스크린샷으로 알려달라.\n');
fprintf('2) 위 파라미터 목록 출력을 전부 복사해서 붙여넣어 달라.\n');
