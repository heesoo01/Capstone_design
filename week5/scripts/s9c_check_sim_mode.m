%% S9C_CHECK_SIM_MODE
% SimulationMode가 Accelerator면 Mechanics Explorer 애니메이션이 안 그려짐.
% Normal로 바꾸고 재확인.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9c_check_sim_mode

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9c: 시뮬레이션 모드 확인 =====\n\n');

try
    fprintf('현재 SimulationMode = %s\n', get_param(mdl, 'SimulationMode'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

try
    set_param(mdl, 'SimulationMode', 'normal');
    fprintf('[OK] SimulationMode = normal 로 설정\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

% Mechanics Explorer 관련 설정도 확인
try
    fprintf('\nMaxStep = %s\n', get_param(mdl, 'MaxStep'));
catch
end

save_system(mdl);

fprintf('\n--- 다시 시뮬레이션 ---\n');
try
    sim(mdl);
    fprintf('[OK] 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n===== S9c 끝. 다시 Mechanics Explorer 확인해달라. =====\n');
