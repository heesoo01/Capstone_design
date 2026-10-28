%% S9P_HARD_RESET
% 모델을 메모리에서 완전히 내렸다가 다시 불러와서 Explorer 캐시를 강제 초기화.
%
% *** 아직 실행 전 ***
% 지금 뜬 Multibody Explorer/Simulink 창을 먼저 손으로 닫아주세요 (X 버튼),
% 그 다음 이 스크립트를 실행합니다.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9p_hard_reset

clear; clc;
mdl = 's1_mechanical';

fprintf('===== S9p: 완전 초기화 =====\n\n');

if bdIsLoaded(mdl)
    close_system(mdl, 0);
    fprintf('[OK] 모델 메모리에서 완전히 내림\n');
else
    fprintf('[정보] 모델이 이미 메모리에 없음\n');
end

pause(1);

open_system(fullfile(pwd, [mdl '.slx']));
fprintf('[OK] 모델 새로 불러옴\n');

set_param(mdl, 'StopTime', '8');
fprintf('[OK] StopTime = 8\n');

fprintf('\n--- 시뮬레이션 (새 Explorer가 떠야 함) ---\n');
sim(mdl);
fprintf('[OK] 완료\n');

fprintf('\n===== S9p 끝. 새로 뜬 Explorer 창에서 타임라인 확인해달라. =====\n');
