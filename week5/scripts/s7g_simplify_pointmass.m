%% S7G_SIMPLIFY_POINTMASS
% VariableInertiaType=PointMass로 바꿔서 질량만 시변으로 단순화.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7g_simplify_pointmass

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

gm = [testmdl '/GenVarMass'];

fprintf('===== S7g: PointMass로 단순화 =====\n\n');

dp = get_param(gm, 'DialogParameters');
try
    fprintf('CenterOfMassType = %s\n', get_param(gm, 'CenterOfMassType'));
catch
    fprintf('CenterOfMassType 필드 없음(PointMass 쪽엔 없을 수도)\n');
end
try
    fprintf('InertiaMatrixType = %s\n\n', get_param(gm, 'InertiaMatrixType'));
catch
    fprintf('InertiaMatrixType 필드 없음\n\n');
end

try
    set_param(gm, 'VariableInertiaType', 'PointMass');
    fprintf('[OK] VariableInertiaType = PointMass\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- 포트 구성 (PointMass 후) ---\n');
pc = get_param(gm, 'PortConnectivity');
for i = 1:numel(pc)
    fprintf('  (%d) Type=''%s'', Position=[%.0f,%.0f]\n', i, pc(i).Type, pc(i).Position(1), pc(i).Position(2));
end

save_system(testmdl);
fprintf('\n===== 끝. 결과 알려달라. =====\n');
