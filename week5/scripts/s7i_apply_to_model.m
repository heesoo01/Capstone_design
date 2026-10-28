%% S7I_APPLY_TO_MODEL
% 실제 s1_mechanical 모델에 GenVarMass 적용 + 질량 변화 신호 연결.
% 궤적(0.5초 t=0.5, 2.5, 4.5에 30/60/90도)에 맞춰:
%   t=2.0s에 Pick(질량 0.5->0.7kg), t=6.0s에 Place(0.7->0.5kg)
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s7i_apply_to_model

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

fprintf('===== S7i: GenVarMass를 실제 모델에 적용 =====\n\n');

%% 1. 기존 LinkInertia 제거
li = [mdl '/LinkInertia'];
hLI = get_param(li, 'PortHandles');
lineH = get_param(hLI.RConn(1), 'Line');
if lineH ~= -1
    delete_line(lineH);
    fprintf('[OK] LinkInertia 연결선 제거\n');
end
try
    delete_block(li);
    fprintf('[OK] LinkInertia 삭제\n');
catch ME
    fprintf('[정보] %s\n', ME.message);
end

%% 2. GenVarMass 배치 + 설정
try
    add_block('sm_lib/Body Elements/Variable Mass/General Variable Mass', ...
        [mdl '/LinkVarMass'], 'Position', [700 40 760 90]);
    set_param([mdl '/LinkVarMass'], 'VariableInertiaType', 'PointMass');
    set_param([mdl '/LinkVarMass'], 'CenterOfMassType', 'Constant');
    fprintf('[OK] LinkVarMass 배치 + PointMass/CoM=Constant 설정\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

%% 3. RigidTransformLink <-> LinkVarMass 연결
hRT = get_param([mdl '/RigidTransformLink'], 'PortHandles');
hVM = get_param([mdl '/LinkVarMass'], 'PortHandles');
try
    add_line(mdl, hRT.RConn(1), hVM.RConn(1), 'autorouting', 'on');
    fprintf('[OK] RigidTransformLink -> LinkVarMass 연결\n');
catch ME
    fprintf('[실패] 연결: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 4. 질량 신호 체인: 기본(0.5) + Pick 스텝(+0.2 at t=2.0) - Place 스텝(-0.2 at t=6.0)
try
    add_block('simulink/Sources/Constant', [mdl '/Mass Base'], ...
        'Position', [20 500 60 530], 'Value', num2str(p.mech.link_mass));
    add_block('simulink/Sources/Step', [mdl '/Mass Pick Step'], ...
        'Position', [20 540 60 570], 'Time', '2.0', 'Before', '0', 'After', num2str(p.mech.end_mass_loaded));
    add_block('simulink/Sources/Step', [mdl '/Mass Place Step'], ...
        'Position', [20 580 60 610], 'Time', '6.0', 'Before', '0', 'After', num2str(-p.mech.end_mass_loaded));
    add_block('simulink/Math Operations/Sum', [mdl '/Mass Sum'], ...
        'Position', [100 540 130 580], 'Inputs', '+++');
    fprintf('[OK] 질량 신호 블록 배치 (base=%.2f, pick=+%.2f@t=2.0, place=%.2f@t=6.0)\n', ...
        p.mech.link_mass, p.mech.end_mass_loaded, -p.mech.end_mass_loaded);
catch ME
    fprintf('[실패] 질량 신호 블록: %s\n', ME.message);
end

try
    add_block('nesl_utility/Simulink-PS Converter', [mdl '/Mass S2PS'], ...
        'Position', [170 540 230 580]);
    fprintf('[OK] Mass S2PS 배치\n');
catch ME
    fprintf('[실패] Mass S2PS: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 5. 연결
fprintf('--- 질량 신호 연결 ---\n');
hBase = get_param([mdl '/Mass Base'], 'PortHandles');
hPick = get_param([mdl '/Mass Pick Step'], 'PortHandles');
hPlace = get_param([mdl '/Mass Place Step'], 'PortHandles');
hMSum = get_param([mdl '/Mass Sum'], 'PortHandles');
hMS2PS = get_param([mdl '/Mass S2PS'], 'PortHandles');
hVM = get_param([mdl '/LinkVarMass'], 'PortHandles');

try
    add_line(mdl, hBase.Outport(1), hMSum.Inport(1), 'autorouting', 'on');
    add_line(mdl, hPick.Outport(1), hMSum.Inport(2), 'autorouting', 'on');
    add_line(mdl, hPlace.Outport(1), hMSum.Inport(3), 'autorouting', 'on');
    fprintf('  [OK] Base,Pick,Place -> Mass Sum\n');
catch ME
    fprintf('  [실패]: %s\n', ME.message);
end

try
    add_line(mdl, hMSum.Outport(1), hMS2PS.Inport(1), 'autorouting', 'on');
    add_line(mdl, hMS2PS.RConn(1), hVM.LConn(1), 'autorouting', 'on');
    fprintf('  [OK] Mass Sum -> S2PS -> LinkVarMass.Mass\n');
catch ME
    fprintf('  [실패]: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n===== S7i 끝. [실패] 있으면 알려달라. =====\n');
