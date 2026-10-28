%% S9Q_FIX_ROD_ORIENTATION
% LinkRod가 회전축(Y)과 같은 방향으로 뻗어있어서 제자리에서 팽이처럼 돌기만
% 하고 안 움직이는 것처럼 보였음. 원통이 X방향(질량이 있는 쪽)으로 뻗도록
% 회전 변환을 하나 추가한다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9q_fix_rod_orientation

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9q: LinkRod 방향 수정 =====\n\n');

%% 1. 기존 RevoluteJoint.F -> LinkRod 연결 제거
hRJ = get_param([mdl '/RevoluteJoint'], 'PortHandles');
hLR = get_param([mdl '/LinkRod'], 'PortHandles');
lineH = get_param(hLR.RConn(1), 'Line');
if lineH ~= -1
    delete_line(lineH);
    fprintf('[OK] 기존 LinkRod 연결 제거\n');
end

%% 2. 방향 보정용 Rigid Transform 추가 (Z축이 X를 향하게, Y축 기준 90도 회전)
try
    add_block('sm_lib/Frames and Transforms/Rigid Transform', [mdl '/RigidTransformRodOrient'], ...
        'Position', [700 150 760 180]);
    dpR = get_param([mdl '/RigidTransformRodOrient'], 'DialogParameters');
    rotOptions = dpR.RotationMethod.Enum;
    stdIdx = find(contains(rotOptions, 'Standard', 'IgnoreCase', true), 1);
    set_param([mdl '/RigidTransformRodOrient'], 'RotationMethod', rotOptions{stdIdx});
    set_param([mdl '/RigidTransformRodOrient'], 'RotationStandardAxis', '+Y');
    set_param([mdl '/RigidTransformRodOrient'], 'RotationAngle', '90');
    fprintf('[OK] RigidTransformRodOrient 배치 (Y축 기준 90도 회전, Z->X)\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

%% 3. 재연결: RevoluteJoint.F -> RigidTransformRodOrient -> LinkRod
hRO = get_param([mdl '/RigidTransformRodOrient'], 'PortHandles');
hLR = get_param([mdl '/LinkRod'], 'PortHandles');

try
    add_line(mdl, hRJ.RConn(1), hRO.LConn(1), 'autorouting', 'on');
    add_line(mdl, hRO.RConn(1), hLR.RConn(1), 'autorouting', 'on');
    fprintf('[OK] RevoluteJoint.F -> RigidTransformRodOrient -> LinkRod 연결\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '8');

fprintf('\n--- 시뮬레이션 ---\n');
try
    sim(mdl);
    fprintf('[OK] 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S9q 끝. 새 Explorer 창에서 막대가 길게 보이는지, 돌아가는지 확인해달라. =====\n');
