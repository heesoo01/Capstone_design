%% S5_MULTI_ANGLE
% 목표각을 0 -> 30 -> 60 -> 90도로 2초 간격으로 계단식 변화시킨다.
% Step 블록 3개(이미 검증됨)를 더해서 계단 신호를 만든다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s5_multi_angle

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S5: 다중 각도(0/30/60/90도) 배선 =====\n\n');

%% 1. 기존 단일 Angle Reference 제거
ref = [mdl '/Angle Reference'];
hRef = get_param(ref, 'PortHandles');
lineOut = get_param(hRef.Outport(1), 'Line');
if lineOut ~= -1
    delete_line(lineOut);
    fprintf('[OK] 기존 Angle Reference 출력선 제거\n');
end
try
    delete_block(ref);
    fprintf('[OK] 기존 Angle Reference(단일 Step) 삭제\n');
catch ME
    fprintf('[정보] %s\n', ME.message);
end

%% 2. Step 3개 + Sum
try
    add_block('simulink/Sources/Step', [mdl '/Step1'], ...
        'Position', [20 360 60 390], 'Time', '0.5', 'Before', '0', 'After', '30');
    add_block('simulink/Sources/Step', [mdl '/Step2'], ...
        'Position', [20 400 60 430], 'Time', '2.5', 'Before', '0', 'After', '30');
    add_block('simulink/Sources/Step', [mdl '/Step3'], ...
        'Position', [20 440 60 470], 'Time', '4.5', 'Before', '0', 'After', '30');
    fprintf('[OK] Step1(t=0.5,+30), Step2(t=2.5,+30), Step3(t=4.5,+30) 배치\n');
catch ME
    fprintf('[실패] Step 블록: %s\n', ME.message);
end

try
    add_block('simulink/Math Operations/Sum', [mdl '/Angle Reference Sum'], ...
        'Position', [100 390 130 440], 'Inputs', '+++');
    fprintf('[OK] Angle Reference Sum(3입력 합) 배치\n');
catch ME
    fprintf('[실패] Sum: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 3. 연결
fprintf('--- 연결 ---\n');
hStep1 = get_param([mdl '/Step1'], 'PortHandles');
hStep2 = get_param([mdl '/Step2'], 'PortHandles');
hStep3 = get_param([mdl '/Step3'], 'PortHandles');
hSum   = get_param([mdl '/Angle Reference Sum'], 'PortHandles');
hErr   = get_param([mdl '/Angle Error'], 'PortHandles');

try
    add_line(mdl, hStep1.Outport(1), hSum.Inport(1), 'autorouting', 'on');
    add_line(mdl, hStep2.Outport(1), hSum.Inport(2), 'autorouting', 'on');
    add_line(mdl, hStep3.Outport(1), hSum.Inport(3), 'autorouting', 'on');
    fprintf('  [OK] Step1,2,3 -> Sum\n');
catch ME
    fprintf('  [실패] Step->Sum: %s\n', ME.message);
end

try
    add_line(mdl, hSum.Outport(1), hErr.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] Sum -> Angle Error(+)\n');
catch ME
    fprintf('  [실패] Sum->Error: %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '8');

fprintf('\n--- 시뮬레이션 ---\n');
try
    sim(mdl);
    fprintf('[OK] 성공!\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n===== S5 끝. 성공하면 Scope 스크린샷(자동축맞춤) 보내달라. =====\n');
