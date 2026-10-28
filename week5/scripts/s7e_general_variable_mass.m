%% S7E_GENERAL_VARIABLE_MASS
% "General Variable Mass" 블록 확인 -- 질량만 독립적으로 시변 가능할 수 있음.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7e_general_variable_mass

clear; clc;
testmdl = 's7_varmass_test';
if ~bdIsLoaded(testmdl)
    open_system([testmdl '.slx']);
end

fprintf('===== S7e: General Variable Mass 확인 =====\n\n');

try
    add_block('sm_lib/Body Elements/Variable Mass/General Variable Mass', ...
        [testmdl '/GenVarMass'], 'Position', [250 100 310 150]);
    fprintf('[OK] 배치 성공\n');
catch ME
    fprintf('[실패] 배치: %s\n', ME.message);
    fprintf('(경로가 다를 수 있음 -- 격리 테스트라 괜찮음)\n');
end

try
    h = get_param([testmdl '/GenVarMass'], 'PortHandles');
    fn = fieldnames(h);
    fprintf('\n--- 포트 구성 ---\n');
    for i = 1:numel(fn)
        fprintf('  %s : %d개\n', fn{i}, numel(h.(fn{i})));
    end
catch ME
    fprintf('[실패] 포트 조회: %s\n', ME.message);
end

try
    dp = get_param([testmdl '/GenVarMass'], 'DialogParameters');
    fprintf('\n--- 파라미터 목록 ---\n');
    disp(fieldnames(dp));
catch ME
    fprintf('[실패] 파라미터 조회: %s\n', ME.message);
end

save_system(testmdl);
fprintf('\n===== 끝. 결과 알려달라. =====\n');
