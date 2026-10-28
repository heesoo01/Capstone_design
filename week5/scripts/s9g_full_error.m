%% S9G_FULL_ERROR
% LinkRod의 LogSimulationData 설정 실패 원인을 전체 에러로 확인.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9g_full_error

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9g: 전체 에러 메시지 =====\n\n');

try
    set_param([mdl '/LinkRod'], 'LogSimulationData', 'on');
    fprintf('[OK]\n');
catch ME
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== 끝 =====\n');
