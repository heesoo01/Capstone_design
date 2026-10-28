%% S9I_CHECK_MODEL_LOG_SETTING
% 모델 레벨의 Simscape 로깅 설정(SimscapeLogType 등)을 확인하고 켠다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9i_check_model_log_setting

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9i: 모델 레벨 로깅 설정 확인 =====\n\n');

% 가능한 파라미터 이름 후보들을 전부 시도 (존재하면 현재값 출력)
candNames = {'SimscapeLogType', 'SimscapeLogName', 'SimscapeLogToFile', ...
             'SimscapeLogDataFromGUI', 'SimMechanicsOpenEditorOnUpdate', ...
             'SimscapeLogLimitDataPoints', 'SimscapeLogDecimation'};

for i = 1:numel(candNames)
    name = candNames{i};
    try
        val = get_param(mdl, name);
        fprintf('[존재] %s = %s\n', name, mat2str(val));
    catch
        fprintf('[없음] %s\n', name);
    end
end

fprintf('\n===== 끝. 존재하는 파라미터들로 다음 단계 진행. =====\n');
