%% S1D_WIRE_AND_TEST
% S1 마무리: 토크 입력 + 위치/속도 출력 신호를 잇고, 두 가지 조건으로 돌려본다.
%   Test A: 토크 = 0  -> 중력으로 처지는지 확인
%   Test B: 토크 = 중력을 버틸 만큼 큰 값 -> 반대 방향으로 움직이는지 확인
%
% *** 아직 실행 전 ***
%
% 새로 생긴 포트(LConn(2)=토크 입력 추정, RConn(2)/RConn(3)=위치/속도 출력 추정)를
% 연결한다. "추정"이라고 쓴 건, 정확히 어느 쪽이 위치고 어느 쪽이 속도인지는
% 이름으로 확정을 못 해서다 (get_param으로 시도는 하되, 실패하면 시뮬레이션
% 결과(단위/그래프 모양)로 구분해서 알려달라고 할 것).
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s1d_wire_and_test

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

rj = [mdl '/RevoluteJoint'];
fprintf('===== S1d: 신호 배선 + 테스트 =====\n\n');

%% 0. 포트 핸들 다시 조회 + 이름 정보 시도
h = get_param(rj, 'PortHandles');
fprintf('LConn 개수: %d, RConn 개수: %d\n', numel(h.LConn), numel(h.RConn));
for i = 1:numel(h.LConn)
    try
        nm = get_param(h.LConn(i), 'Name');
    catch
        nm = '(이름 조회 불가)';
    end
    fprintf('  LConn(%d) 이름: %s\n', i, nm);
end
for i = 1:numel(h.RConn)
    try
        nm = get_param(h.RConn(i), 'Name');
    catch
        nm = '(이름 조회 불가)';
    end
    fprintf('  RConn(%d) 이름: %s\n', i, nm);
end
fprintf('\n');

% LConn(1), RConn(1)은 기존 프레임 연결(이미 연결됨)이라고 가정.
% 새로 생긴 것: LConn(2) = 토크 입력, RConn(2), RConn(3) = 위치/속도 출력 (추정)
torque_in_handle = h.LConn(2);
sense_out_1 = h.RConn(2);
sense_out_2 = h.RConn(3);

%% 1. 블록 추가: 토크 커맨드 체인
try
    add_block('simulink/Sources/Constant', [mdl '/Torque Command'], ...
        'Position', [280 150 340 180], 'Value', '0');
    fprintf('[OK] Constant(토크 커맨드) 배치, 초기값 0\n');
catch ME
    fprintf('[실패] Constant: %s\n', ME.message);
end

try
    add_block('nesl_utility/Simulink-PS Converter', [mdl '/Torque S2PS'], ...
        'Position', [380 150 440 180]);
    fprintf('[OK] Simulink-PS Converter(토크용) 배치\n');
catch ME
    fprintf('[실패] Simulink-PS Converter: %s\n', ME.message);
end

%% 2. 블록 추가: 센싱 체인 (PS-Simulink Converter x2 + Scope)
try
    add_block('nesl_utility/PS-Simulink Converter', [mdl '/Sense1 PS2S'], ...
        'Position', [560 20 620 50]);
    fprintf('[OK] PS-Simulink Converter #1 배치\n');
catch ME
    fprintf('[실패] Sense1 PS2S: %s\n', ME.message);
end

try
    add_block('nesl_utility/PS-Simulink Converter', [mdl '/Sense2 PS2S'], ...
        'Position', [560 90 620 120]);
    fprintf('[OK] PS-Simulink Converter #2 배치\n');
catch ME
    fprintf('[실패] Sense2 PS2S: %s\n', ME.message);
end

try
    add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
        'Position', [700 40 740 100]);
    set_param([mdl '/Scope'], 'NumInputPorts', '2');
    fprintf('[OK] Scope 배치 (입력 2개)\n');
catch ME
    fprintf('[실패] Scope: %s\n', ME.message);
end

fprintf('\n');

%% 3. 연결
fprintf('--- 신호 연결 ---\n');
try
    hConst = get_param([mdl '/Torque Command'], 'PortHandles');
    hS2PS  = get_param([mdl '/Torque S2PS'], 'PortHandles');
    add_line(mdl, hConst.Outport(1), hS2PS.Inport(1), 'autorouting', 'on');
    add_line(mdl, hS2PS.RConn(1), torque_in_handle, 'autorouting', 'on');
    fprintf('[OK] Torque Command -> S2PS -> RevoluteJoint 토크 입력\n');
catch ME
    fprintf('[실패] 토크 체인 연결: %s\n', ME.message);
end

try
    hP1 = get_param([mdl '/Sense1 PS2S'], 'PortHandles');
    add_line(mdl, sense_out_1, hP1.LConn(1), 'autorouting', 'on');
    hScope = get_param([mdl '/Scope'], 'PortHandles');
    add_line(mdl, hP1.Outport(1), hScope.Inport(1), 'autorouting', 'on');
    fprintf('[OK] RevoluteJoint 출력1 -> PS2S #1 -> Scope 입력1\n');
catch ME
    fprintf('[실패] 센싱1 연결: %s\n', ME.message);
end

try
    hP2 = get_param([mdl '/Sense2 PS2S'], 'PortHandles');
    add_line(mdl, sense_out_2, hP2.LConn(1), 'autorouting', 'on');
    hScope = get_param([mdl '/Scope'], 'PortHandles');
    add_line(mdl, hP2.Outport(1), hScope.Inport(2), 'autorouting', 'on');
    fprintf('[OK] RevoluteJoint 출력2 -> PS2S #2 -> Scope 입력2\n');
catch ME
    fprintf('[실패] 센싱2 연결: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 4. 시뮬레이션 준비
if ~exist(fullfile(pwd, '..', 'results'), 'dir')
    mkdir(fullfile(pwd, '..', 'results'));
end
set_param(mdl, 'StopTime', '3');

%% Test A: 토크 = 0
fprintf('--- Test A: 토크 0 (중력으로 처지는지) ---\n');
try
    set_param([mdl '/Torque Command'], 'Value', '0');
    simOutA = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    fprintf('[OK] Test A 시뮬레이션 완료 (에러 없이 끝남)\n');
catch ME
    fprintf('[실패] Test A 시뮬레이션: %s\n', ME.message);
    fprintf('      (에러 메시지 그대로 알려주면 원인 확인 가능)\n');
end

%% Test B: 토크 = 중력을 버틸 만한 큰 값 (placeholder, 5 N*m)
fprintf('\n--- Test B: 토크 5 N*m (반대로 움직이는지) ---\n');
try
    set_param([mdl '/Torque Command'], 'Value', '5');
    simOutB = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    fprintf('[OK] Test B 시뮬레이션 완료 (에러 없이 끝남)\n');
catch ME
    fprintf('[실패] Test B 시뮬레이션: %s\n', ME.message);
end

fprintf('\n===== S1d 끝. =====\n');
fprintf('- 위 [실패] 있으면 에러 메시지 그대로 붙여넣어 달라.\n');
fprintf('- 성공했으면 Scope 창을 더블클릭해서 연 화면 스크린샷을 보내달라\n');
fprintf('  (Test A, Test B 각각 한 번씩 -- 두 번 실행해서 스코프가 최신 결과로 갱신됨).\n');
fprintf('- 두 출력 중 뭐가 위치고 뭐가 속도인지는, 스코프에서 값의 단위/모양\n');
fprintf('  (위치는 계속 누적/포화, 속도는 0에서 시작해 변화)으로 같이 확인해보자.\n');
