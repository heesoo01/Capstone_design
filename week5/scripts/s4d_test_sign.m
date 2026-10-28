%% S4D_TEST_SIGN
% PID 출력 부호를 뒤집어서(-1 게인 삽입) 피드백 부호가 반대였는지 테스트.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s4d_test_sign

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S4d: 피드백 부호 테스트 =====\n\n');

% Gearbox rotation_direction 참고로 출력
try
    fprintf('Gearbox.rotation_direction = %s\n\n', get_param([mdl '/Gearbox'], 'rotation_direction'));
catch
end

pid = [mdl '/PID Controller'];
s2ps = [mdl '/Motor Torque S2PS'];

hPID = get_param(pid, 'PortHandles');
hS2PS = get_param(s2ps, 'PortHandles');

% 기존 PID->S2PS 선 제거
lineH = get_param(hPID.Outport(1), 'Line');
if lineH ~= -1
    delete_line(lineH);
    fprintf('[OK] 기존 PID->S2PS 선 제거\n');
end

% -1 게인 블록 삽입
try
    add_block('simulink/Math Operations/Gain', [mdl '/Sign Flip'], ...
        'Position', [330 400 360 430], 'Gain', '-1');
    fprintf('[OK] Sign Flip(-1) 배치\n');
catch ME
    fprintf('[정보] 이미 있음: %s\n', ME.message);
end

hFlip = get_param([mdl '/Sign Flip'], 'PortHandles');

add_line(mdl, hPID.Outport(1), hFlip.Inport(1), 'autorouting', 'on');
add_line(mdl, hFlip.Outport(1), hS2PS.Inport(1), 'autorouting', 'on');
fprintf('[OK] PID -> Sign Flip -> S2PS 재연결\n');

save_system(mdl);
set_param(mdl, 'StopTime', '3');

fprintf('\n--- 시뮬레이션 ---\n');
try
    sim(mdl);
    fprintf('[OK] 성공! (부호 반대였던 게 맞음)\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
    fprintf('(부호 문제가 아니었을 수 있음 -- 다른 원인 찾아야 함)\n');
end

fprintf('\n===== S4d 끝 =====\n');
