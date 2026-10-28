%% S9J_CHECK_SIMLOG_V2
% 변수 이름을 'simlog'로 맞춰서 재확인.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9j_check_simlog_v2

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9j: simlog 변수로 재확인 =====\n\n');

set_param(mdl, 'StopTime', '8');

try
    sim(mdl);
    fprintf('[OK] 시뮬레이션 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
    return;
end

try
    sl = evalin('base', 'simlog');
    fprintf('[OK] simlog 변수 찾음 (base workspace)\n');
    fprintf('클래스: %s\n', class(sl));
catch ME
    fprintf('[실패] simlog 못 찾음: %s\n', ME.message);
    fprintf('\nbase workspace 전체 변수 목록:\n');
    disp(evalin('base', 'who'));
    sl = [];
end

if ~isempty(sl)
    try
        children = sl.children;
        fprintf('\nsimlog 하위 노드들:\n');
        for i = 1:numel(children)
            fprintf('  %s\n', children{i}.id);
        end
    catch ME
        fprintf('children 조회 실패: %s\n', ME.message);
    end

    try
        q = sl.RevoluteJoint.Rz.q;
        t = q.series.time;
        v = q.series.values;
        fprintf('\nRevoluteJoint.Rz.q : %d개 데이터 포인트, t=[%.2f,%.2f], q=[%.2f,%.2f] %s\n', ...
            numel(t), t(1), t(end), min(v), max(v), q.series.units);
    catch ME
        fprintf('RevoluteJoint.Rz.q 조회 실패: %s\n', ME.message);
    end
end

fprintf('\n===== S9j 끝 =====\n');
