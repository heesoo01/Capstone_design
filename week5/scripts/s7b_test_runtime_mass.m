%% S7B_TEST_RUNTIME_MASS
% VarMass에 Mass_conf=runtime + ComputedVariable 확인해서 물리신호 포트가 생기는지.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7b_test_runtime_mass

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

vm = [testmdl '/VarMass'];

fprintf('===== S7b: ComputedVariable + runtime 테스트 =====\n\n');

dp = get_param(vm, 'DialogParameters');
fprintf('--- ComputedVariable 상세 ---\n');
disp(dp.ComputedVariable);
fprintf('현재값: %s\n\n', get_param(vm, 'ComputedVariable'));

fprintf('--- MassType 상세 ---\n');
disp(dp.MassType);
fprintf('현재값: %s\n\n', get_param(vm, 'MassType'));

% Mass를 runtime으로
try
    set_param(vm, 'Mass_conf', 'runtime');
    fprintf('[OK] Mass_conf = runtime\n');
catch ME
    fprintf('[실패] Mass_conf: %s\n', ME.message);
end

fprintf('\n--- 포트 구성 (Mass_conf=runtime 후) ---\n');
h = get_param(vm, 'PortHandles');
fn = fieldnames(h);
for i = 1:numel(fn)
    fprintf('  %s : %d개\n', fn{i}, numel(h.(fn{i})));
end

save_system(testmdl);
fprintf('\n===== 끝. 포트 개수 변화 알려달라. =====\n');
