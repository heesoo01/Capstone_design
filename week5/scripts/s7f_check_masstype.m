%% S7F_CHECK_MASSTYPE
% GenVarMass의 MassType enum과 현재값, 포트 위치를 확인.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7f_check_masstype

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

gm = [testmdl '/GenVarMass'];

fprintf('===== S7f: MassType 확인 =====\n\n');

dp = get_param(gm, 'DialogParameters');
fprintf('--- MassType ---\n');
disp(dp.MassType);
fprintf('현재값: %s\n\n', get_param(gm, 'MassType'));

fprintf('--- VariableInertiaType ---\n');
disp(dp.VariableInertiaType);
fprintf('현재값: %s\n\n', get_param(gm, 'VariableInertiaType'));

fprintf('--- 포트 상세 위치 ---\n');
pc = get_param(gm, 'PortConnectivity');
for i = 1:numel(pc)
    fprintf('  (%d) Type=''%s'', Position=[%.0f,%.0f]\n', i, pc(i).Type, pc(i).Position(1), pc(i).Position(2));
end

fprintf('\n===== 끝. 결과 알려달라. =====\n');
