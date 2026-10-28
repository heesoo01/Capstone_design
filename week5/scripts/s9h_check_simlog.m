%% S9H_CHECK_SIMLOG
% simlog(Simscape 로깅 데이터) 자체가 생성되는지, 시간에 따라 값이 바뀌는지
% 직접 확인. Explorer UI를 거치지 않고 데이터 레벨에서 검증.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9h_check_simlog

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9h: simlog 데이터 직접 확인 =====\n\n');

set_param(mdl, 'StopTime', '8');

try
    simOut = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    fprintf('[OK] 시뮬레이션 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
    return;
end

% simlog 찾기 (출력 구조체 안에 있거나, 모델 콜백 변수로 base workspace에 있을 수 있음)
try
    sl = simOut.get('simlog_s1_mechanical');
    fprintf('[OK] simlog_s1_mechanical 찾음 (simOut 안에)\n');
catch
    try
        sl = evalin('base', 'simlog_s1_mechanical');
        fprintf('[OK] simlog_s1_mechanical 찾음 (base workspace)\n');
    catch ME
        fprintf('[실패] simlog를 못 찾음: %s\n', ME.message);
        sl = [];
    end
end

if ~isempty(sl)
    try
        q = sl.RevoluteJoint.Rz.q;
        t = q.series.time;
        v = q.series.values;
        fprintf('\nRevoluteJoint.Rz.q 데이터 포인트 개수: %d\n', numel(t));
        fprintf('시간 범위: %.3f ~ %.3f\n', t(1), t(end));
        fprintf('값 범위: %.3f ~ %.3f (%s)\n', min(v), max(v), q.series.units);
        fprintf('\n샘플 (처음 5개, 중간 5개, 끝 5개):\n');
        n = numel(t);
        idxs = unique([1:min(5,n), max(1,round(n/2)-2):min(n,round(n/2)+2), max(1,n-4):n]);
        for i = idxs
            fprintf('  t=%.3f  q=%.4f\n', t(i), v(i));
        end
    catch ME
        fprintf('[실패] RevoluteJoint.Rz.q 조회 실패: %s\n', ME.message);
        fprintf('simlog 구조 확인:\n');
        disp(sl)
    end
end

fprintf('\n===== S9h 끝 =====\n');
