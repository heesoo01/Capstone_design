%% S8B_CHECK_VISPROPT
% GraphicVisPropType이 렌더링을 막고 있는지 확인.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s8b_check_vispropt

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

vm = [mdl '/LinkVarMass'];
dp = get_param(vm, 'DialogParameters');

fprintf('===== S8b: GraphicVisPropType 확인 =====\n\n');
disp(dp.GraphicVisPropType);
fprintf('현재값: %s\n\n', get_param(vm, 'GraphicVisPropType'));

fprintf('현재 설정 요약:\n');
fprintf('  GraphicType = %s\n', get_param(vm, 'GraphicType'));
fprintf('  MarkerShape = %s\n', get_param(vm, 'MarkerShape'));
fprintf('  MarkerSize = %s\n', get_param(vm, 'MarkerSize'));

fprintf('\n===== 끝 =====\n');
