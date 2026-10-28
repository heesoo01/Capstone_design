%% S9K_CAPTURE_OUTPUT
% sim() 출력을 simOut으로 제대로 받아서 그 안에서 simlog를 꺼낸다.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9k_capture_output

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9k: simOut에서 simlog 꺼내기 =====\n\n');

set_param(mdl, 'StopTime', '8');

simOut = sim(mdl);
fprintf('[OK] 시뮬레이션 완료, simOut 클래스: %s\n', class(simOut));

try
    fprintf('\nsimOut 안의 변수 목록:\n');
    disp(simOut.who);
catch ME
    fprintf('who 조회 실패: %s\n', ME.message);
end

try
    sl = simOut.get('simlog');
    fprintf('\n[OK] simlog 찾음!\n');

    q = sl.RevoluteJoint.Rz.q;
    t = q.series.time;
    v = q.series.values;
    fprintf('RevoluteJoint.Rz.q : %d개 포인트, t=[%.2f,%.2f], q=[%.2f,%.2f] %s\n', ...
        numel(t), t(1), t(end), min(v), max(v), q.series.units);

    % base workspace에도 저장해서 나중에 쓸 수 있게
    assignin('base', 'simlog', sl);
    fprintf('\n(base workspace에도 simlog로 저장함)\n');
catch ME
    fprintf('\n[실패] simlog 조회: %s\n', ME.message);
end

fprintf('\n===== S9k 끝 =====\n');
