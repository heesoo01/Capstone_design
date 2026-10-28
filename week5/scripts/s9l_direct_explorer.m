%% S9L_DIRECT_EXPLORER
% simlog 데이터를 확인하고(오타 수정), 이 데이터를 직접 Mechanics Explorer에 넘긴다.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9l_direct_explorer

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9l: 데이터 확인 + Explorer 직접 열기 =====\n\n');

set_param(mdl, 'StopTime', '8');
simOut = sim(mdl);
sl = simOut.get('simlog');

q = sl.RevoluteJoint.Rz.q;
t = q.series.time;
v = q.series.values;
fprintf('RevoluteJoint.Rz.q : %d개 포인트\n', numel(t));
fprintf('t 처음 5개: %s\n', mat2str(t(1:5)', 4));
fprintf('q 처음 5개: %s\n', mat2str(v(1:5)', 4));
fprintf('t 끝 5개: %s\n', mat2str(t(end-4:end)', 4));
fprintf('q 끝 5개: %s\n', mat2str(v(end-4:end)', 4));

fprintf('\n--- Mechanics Explorer를 이 simlog로 직접 열기 ---\n');
try
    mechanicsExplorer(sl);
    fprintf('[OK] 명령 실행됨 -- 창이 떴는지 확인해달라\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n===== S9l 끝 =====\n');
