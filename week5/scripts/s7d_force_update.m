%% S7D_FORCE_UPDATE
% 모델을 강제로 업데이트(컴파일)한 뒤 포트 구성을 다시 확인.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7d_force_update

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

vm = [testmdl '/VarMass'];

fprintf('===== S7d: 강제 업데이트 후 포트 확인 =====\n\n');

try
    set_param(testmdl, 'SimulationCommand', 'update');
    fprintf('[OK] 다이어그램 업데이트 완료\n');
catch ME
    fprintf('[실패] 업데이트: %s (무시하고 계속)\n', ME.message);
end

fprintf('\n--- 포트 구성 ---\n');
h = get_param(vm, 'PortHandles');
disp(h);

fprintf('\n--- PortConnectivity (더 상세) ---\n');
try
    pc = get_param(vm, 'PortConnectivity');
    for i = 1:numel(pc)
        fprintf('  (%d) Type=''%s'', Position=[%.0f,%.0f]\n', i, pc(i).Type, pc(i).Position(1), pc(i).Position(2));
    end
catch ME
    fprintf('  [실패] %s\n', ME.message);
end

fprintf('\n===== 끝. 결과 알려달라. =====\n');
