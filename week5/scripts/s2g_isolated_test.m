%% S2G_ISOLATED_TEST
% 완전히 새 빈 모델에서 RotIfc + InterfaceRef 딱 2개만 놓고 연결 테스트.
% s1_mechanical에 뭔가 쌓인 문제인지, 이 블록 자체 규칙 문제인지 구분하기 위함.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2g_isolated_test

clear; clc;
testmdl = 's2_isolated_test';
if bdIsLoaded(testmdl)
    close_system(testmdl, 0);
end
new_system(testmdl);
open_system(testmdl);

fprintf('===== S2g: 격리 테스트 =====\n\n');

add_block('nesl_utility/Solver Configuration', [testmdl '/Solver Configuration'], 'Position', [30 30 90 60]);
add_block('fl_lib/Mechanical/Multibody Interfaces/Rotational Multibody Interface', [testmdl '/RotIfc'], 'Position', [150 30 210 80]);
add_block('fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference', [testmdl '/Ref'], 'Position', [280 30 340 60]);

hIfc = get_param([testmdl '/RotIfc'], 'PortHandles');
hRef = get_param([testmdl '/Ref'], 'PortHandles');
hSolver = get_param([testmdl '/Solver Configuration'], 'PortHandles');

fprintf('RotIfc 포트: LConn=%d개, RConn=%d개\n', numel(hIfc.LConn), numel(hIfc.RConn));

% Solver Configuration도 네트워크에 연결해야 하니 RotIfc의 conserving 포트 중 하나에 브랜치
fprintf('\n테스트: RotIfc.RConn(1) -> Ref\n');
try
    add_line(testmdl, hIfc.RConn(1), hRef.LConn(1), 'autorouting', 'on');
    fprintf('  [OK] 성공!\n');
catch ME
    fprintf('  [실패] %s\n', ME.message);
end

fprintf('\n테스트: RotIfc.LConn(1) -> Solver Configuration\n');
try
    add_line(testmdl, hIfc.LConn(1), hSolver.RConn(1), 'autorouting', 'on');
    fprintf('  [OK] 성공!\n');
catch ME
    fprintf('  [실패] %s\n', ME.message);
end

save_system(testmdl);
fprintf('\n===== 끝. 결과 알려달라. =====\n');
