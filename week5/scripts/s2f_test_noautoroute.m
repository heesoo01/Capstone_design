%% S2F_TEST_NOAUTOROUTE
% RotIfc 연결이 계속 실패하는 원인이 'autorouting' 옵션 때문인지 테스트.
% 연결 하나만, autorouting 없이 시도.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2f_test_noautoroute

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S2f: autorouting 없이 테스트 =====\n\n');

hIfc  = get_param([mdl '/RotIfc'], 'PortHandles');
hIRef = get_param([mdl '/InterfaceRef'], 'PortHandles');

fprintf('테스트 1: autorouting 옵션 자체를 빼고 시도\n');
try
    add_line(mdl, hIfc.RConn(1), hIRef.LConn(1));
    fprintf('  [OK] 성공!\n');
catch ME
    fprintf('  [실패] %s\n', ME.message);
    fprintf('  identifier: %s\n', ME.identifier);
end

fprintf('\n테스트 2: 블록 이름으로 (핸들 대신) 시도\n');
try
    add_line(mdl, 'RotIfc/1', 'InterfaceRef/1');
    fprintf('  [OK] 성공!\n');
catch ME
    fprintf('  [실패] %s\n', ME.message);
end

fprintf('\n테스트 3: RotIfc 블록 자체의 타입/마스크 정보\n');
try
    fprintf('  BlockType: %s\n', get_param([mdl '/RotIfc'], 'BlockType'));
    fprintf('  MaskType: %s\n', get_param([mdl '/RotIfc'], 'MaskType'));
    fprintf('  ReferenceBlock: %s\n', get_param([mdl '/RotIfc'], 'ReferenceBlock'));
catch ME
    fprintf('  [실패] %s\n', ME.message);
end

fprintf('\n===== 끝 =====\n');
