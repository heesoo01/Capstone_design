%% S9O_TEST_FINAL_POSE
% StopTime을 아주 짧게(0.3초, 거의 0도)와 길게(8초, 90도)로 각각 돌려서
% Explorer가 "최종 자세"는 다르게 보여주는지 비교 (재생/스크러빙 문제와
% 별개로 최종 상태 렌더링 자체는 되는지 확인).
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9o_test_final_pose
%         (1단계 끝나면 스크린샷, 스크립트에서 다시 엔터 눌러 2단계 진행 -- 아니라
%          그냥 한번에 돌고 두 번 비교 캡처하도록 안내 메시지만 띄움)

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9o: 1단계 -- 짧게(0.3초, 약 0도 근처) =====\n\n');

set_param(mdl, 'StopTime', '0.3');
sim(mdl);
fprintf('[OK] 0.3초 시뮬레이션 완료.\n');
fprintf('지금 Multibody Explorer 스크린샷 하나 찍어주세요 (막대가 거의 수평이어야 정상).\n');
fprintf('찍은 뒤, 다음 스크립트(s9p)를 돌려서 8초짜리와 비교합니다.\n');
