%% S9F_DEBUG_REMAINING
% LinkRod, LinkVarMass, WorldFrame, MechanismConfiguration,
% RigidTransformJointAxis, RigidTransformLink에서 LogSimulationData 설정이
% 왜 실패하는지 에러 메시지 직접 확인.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9f_debug_remaining

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9f: 실패 원인 확인 =====\n\n');

targets = {'LinkRod', 'LinkVarMass', 'WorldFrame', 'MechanismConfiguration', ...
           'RigidTransformJointAxis', 'RigidTransformLink'};

for i = 1:numel(targets)
    b = [mdl '/' targets{i}];
    fprintf('--- %s ---\n', targets{i});
    try
        set_param(b, 'LogSimulationData', 'on');
        fprintf('  [OK] 성공\n');
    catch ME
        fprintf('  [실패] %s\n', ME.message);
    end
end

save_system(mdl);
fprintf('\n===== 끝 =====\n');
