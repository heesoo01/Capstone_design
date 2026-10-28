%% S7H_MASS_ONLY
% CenterOfMassType=Constant로 바꿔서 질량 입력 포트만 남기기.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7h_mass_only

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

gm = [testmdl '/GenVarMass'];

fprintf('===== S7h: 질량 전용 포트로 =====\n\n');

try
    set_param(gm, 'CenterOfMassType', 'Constant');
    fprintf('[OK] CenterOfMassType = Constant\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- 포트 구성 ---\n');
pc = get_param(gm, 'PortConnectivity');
for i = 1:numel(pc)
    fprintf('  (%d) Type=''%s'', Position=[%.0f,%.0f]\n', i, pc(i).Type, pc(i).Position(1), pc(i).Position(2));
end

save_system(testmdl);
fprintf('\n===== 끝. 포트가 2개(Mass신호+RConn1)로 줄었는지 알려달라. =====\n');
