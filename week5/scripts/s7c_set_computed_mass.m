%% S7C_SET_COMPUTED_MASS
% ComputedVariable을 Mass로 바꿔서 질량 입력 포트가 생기는지 확인.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7c_set_computed_mass

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

vm = [testmdl '/VarMass'];

fprintf('===== S7c: ComputedVariable = Mass =====\n\n');

try
    set_param(vm, 'ComputedVariable', 'Mass');
    fprintf('[OK] ComputedVariable = Mass\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- 포트 구성 ---\n');
h = get_param(vm, 'PortHandles');
disp(h);
fn = fieldnames(h);
for i = 1:numel(fn)
    fprintf('  %s : %d개\n', fn{i}, numel(h.(fn{i})));
end

save_system(testmdl);
fprintf('\n===== 끝. 결과 알려달라. =====\n');
