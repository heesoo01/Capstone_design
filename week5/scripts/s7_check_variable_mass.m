%% S7_CHECK_VARIABLE_MASS
% Variable Spherical Solid가 질량을 물리신호 입력으로 실시간 변경 가능한지 확인.
% 아직 모델에 적용 안 함 -- 격리 테스트만.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7_check_variable_mass

clear; clc;
testmdl = 's7_varmass_test';
if bdIsLoaded(testmdl)
    close_system(testmdl, 0);
end
new_system(testmdl);

fprintf('===== S7: Variable Spherical Solid 확인 =====\n\n');

try
    add_block('sm_lib/Body Elements/Variable Mass/Variable Spherical Solid', ...
        [testmdl '/VarMass'], 'Position', [100 100 160 150]);
    fprintf('[OK] 배치 성공\n');
catch ME
    fprintf('[실패] 배치: %s\n', ME.message);
end

try
    h = get_param([testmdl '/VarMass'], 'PortHandles');
    disp(h);
    fn = fieldnames(h);
    for i = 1:numel(fn)
        fprintf('  %s : %d개\n', fn{i}, numel(h.(fn{i})));
    end
catch ME
    fprintf('[실패] 포트 조회: %s\n', ME.message);
end

try
    dp = get_param([testmdl '/VarMass'], 'DialogParameters');
    fprintf('\n--- 파라미터 목록 ---\n');
    disp(fieldnames(dp));
catch ME
    fprintf('[실패] 파라미터 조회: %s\n', ME.message);
end

fprintf('\n===== 끝. 결과 알려달라. =====\n');
