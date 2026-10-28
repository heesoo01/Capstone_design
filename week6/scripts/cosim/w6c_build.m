%% W6C_BUILD
% Simulink <-> MuJoCo 연동 시험 모델: 5주차 3-2 모델(w5_stage3_2_joint)을 복사해
%   기계부(Simscape: WorldFrame, RevoluteJoint, LinkInertia, SolverConfiguration, MechanismConfiguration, S2PS_tau, PS2S_q, PS2S_qd)를
%   MATLAB System 블록 MuJoCoJointSys (py. 로 MuJoCo 3.14.0 호출) 하나로 바꾼다.
%   전기·제어(위치 PD, 전류 PI, 전압 제한, PMSM dq, 기어비 5)는 Simulink 그대로.
% 주의: [실패] 또는 [경고] 로그가 나오면 그대로 알려줄 것.
clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
w6 = fullfile(here, '..', '..');
modelsDir = fullfile(w6, 'models');
srcMdl = fullfile(w6, '..', 'week5', 'models', 'w5_stage3_2_joint.slx');
mdl = 'w6_cosim_mujoco';
dst = fullfile(modelsDir, [mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl, 0); end
copyfile(srcMdl, dst); fileattrib(dst, '+w'); load_system(dst);
fprintf('\n===== BUILD %s =====\n', mdl);

% PS2S_q / PS2S_qd 의 소비처를 기록해 두고 선을 지운다
dstsQ  = collect(mdl, 'PS2S_q');
dstsQd = collect(mdl, 'PS2S_qd');
for nm = {'S2PS_tau', 'PS2S_q', 'PS2S_qd', 'RevoluteJoint', 'LinkInertia', 'WorldFrame', 'SolverConfiguration', 'MechanismConfiguration'}
    if getSimulinkBlockHandle([mdl '/' nm{1}]) ~= -1
        delete_block([mdl '/' nm{1}]);
        fprintf('  [OK] 삭제: %s\n', nm{1});
    else
        fprintf('  [경고] 없음: %s\n', nm{1});
    end
end
% 남은 끊긴 선 정리
ln = find_system(mdl, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'line');
for i = 1:numel(ln)
    try
        sb = get_param(ln(i), 'SrcBlockHandle'); db = get_param(ln(i), 'DstBlockHandle');
        if isempty(db) || all(db == -1) || sb == -1, delete_line(ln(i)); end
    catch
    end
end

blk = [mdl '/MJ'];
try
    add_block('simulink/User-Defined Functions/MATLAB System', blk, 'Position', [30 30 150 90]);
    set_param(blk, 'System', 'MuJoCoJointSys');
    try, set_param(blk, 'SimulateUsing', 'Interpreted execution'); catch ME, fprintf('  [경고] SimulateUsing: %s\n', ME.message); end
    fprintf('  [OK] MATLAB System 블록 MJ 추가\n');
catch ME
    fprintf('  [실패] MJ 블록: %s\n', ME.message);
end
connect(mdl, 'MJ', 1, dstsQ);
connect(mdl, 'MJ', 2, dstsQd);
% 입력 포트는 System 객체를 읽은 뒤에 생긴다: 먼저 업데이트(입력 미연결 경고는 무시)한 뒤 GNt 를 연결
try
    set_param(mdl, 'SimulationCommand', 'update');
catch ME
    fprintf('  (1차 업데이트 메시지: %s)\n', strtok(ME.message, newline));
end
pb = get_param(blk, 'PortHandles');
fprintf('  MJ 포트: 입력 %d개, 출력 %d개\n', numel(pb.Inport), numel(pb.Outport));
try
    pa = get_param([mdl '/GNt'], 'PortHandles');
    add_line(mdl, pa.Outport(1), pb.Inport(1), 'autorouting', 'on');
    fprintf('  [OK] GNt -> MJ 입력\n');
catch ME
    fprintf('  [실패] GNt -> MJ: %s\n', ME.message);
end
try
    set_param(mdl, 'SimulationCommand', 'update');
    fprintf('  [OK] 다이어그램 업데이트 성공\n');
catch ME
    fprintf('  [실패] 다이어그램 업데이트: %s\n', ME.message);
end
save_system(mdl, dst); close_system(mdl, 0);
fprintf('[OK] 저장: %s\n===== W6C BUILD 끝 =====\n', dst);

function info = collect(mdl, srcName)
    ph = get_param([mdl '/' srcName], 'PortHandles');
    lh = get_param(ph.Outport(1), 'Line');
    dsts = get_param(lh, 'DstPortHandle'); dsts = dsts(dsts > 0);
    info = cell(numel(dsts), 2);
    for k = 1:numel(dsts)
        info{k, 1} = strrep(get_param(dsts(k), 'Parent'), [mdl '/'], '');
        info{k, 2} = get_param(dsts(k), 'PortNumber');
    end
    delete_line(lh);
end

function connect(mdl, src, srcPort, info)
    for k = 1:size(info, 1)
        try
            pa = get_param([mdl '/' src], 'PortHandles'); pb = get_param([mdl '/' info{k, 1}], 'PortHandles');
            add_line(mdl, pa.Outport(srcPort), pb.Inport(info{k, 2}), 'autorouting', 'on');
            fprintf('  [OK] %s:%d -> %s:%d\n', src, srcPort, info{k, 1}, info{k, 2});
        catch ME
            fprintf('  [실패] %s:%d -> %s:%d : %s\n', src, srcPort, info{k, 1}, info{k, 2}, ME.message);
        end
    end
end
