%% S7J_RUN_PICK_PLACE
% 전체 4-Phase 픽앤플레이스 통합 시뮬레이션 실행.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7j_run_pick_place

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S7j: 픽앤플레이스 통합 시뮬레이션 =====\n\n');

set_param(mdl, 'StopTime', '8');

try
    sim(mdl);
    fprintf('[OK] 성공! 전체 4-Phase 한 번에 돌아갔습니다.\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S7j 끝. Scope 스크린샷(자동축맞춤) 보내달라. =====\n');
