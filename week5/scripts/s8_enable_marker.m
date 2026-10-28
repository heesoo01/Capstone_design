%% S8_ENABLE_MARKER
% LinkVarMass에 마커(점/구슬) 표시를 켜서 Mechanics Explorer에서 보이게 한다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s8_enable_marker

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

vm = [mdl '/LinkVarMass'];

fprintf('===== S8: 마커 표시 켜기 =====\n\n');

dp = get_param(vm, 'DialogParameters');
fprintf('--- GraphicType ---\n');
disp(dp.GraphicType);
fprintf('현재값: %s\n\n', get_param(vm, 'GraphicType'));

fprintf('--- MarkerShape ---\n');
disp(dp.MarkerShape);
fprintf('현재값: %s\n\n', get_param(vm, 'MarkerShape'));

% GraphicType을 마커 표시 쪽으로 (enum에서 'marker' 비슷한 거 찾기)
gtOptions = dp.GraphicType.Enum;
markerIdx = find(contains(gtOptions, 'marker', 'IgnoreCase', true), 1);
if ~isempty(markerIdx)
    try
        set_param(vm, 'GraphicType', gtOptions{markerIdx});
        fprintf('[OK] GraphicType = %s\n', gtOptions{markerIdx});
    catch ME
        fprintf('[실패] %s\n', ME.message);
    end
else
    fprintf('[정보] marker 옵션 못 찾음. 전체 옵션: %s\n', strjoin(gtOptions, ' / '));
end

% MarkerShape, MarkerSize도 확인되는 값으로 설정 시도
msOptions = dp.MarkerShape.Enum;
sphereIdx = find(contains(msOptions, 'sphere', 'IgnoreCase', true), 1);
if ~isempty(sphereIdx)
    try
        set_param(vm, 'MarkerShape', msOptions{sphereIdx});
        set_param(vm, 'MarkerSize', '0.03');
        fprintf('[OK] MarkerShape = %s, MarkerSize = 0.03\n', msOptions{sphereIdx});
    catch ME
        fprintf('[실패] %s\n', ME.message);
    end
end

save_system(mdl);
fprintf('\n===== S8 끝. mechanics explorer에서 보이는지 확인해달라 (시뮬레이션 돌리고 창 봐야 함). =====\n');
