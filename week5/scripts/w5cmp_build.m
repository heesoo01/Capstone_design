%% W5CMP_BUILD
% 비교 전용 모델 w5_mujoco_vs_matlab_1dof.slx 를 새로 만든다 (s1_mechanical은 건드리지 않음).
% 1자유도 Z축 회전 관절 + 이상 토크 직접 입력 + 1 ms 샘플-유지 PD. 기어/부호반전/쿨롱/PMSM/중력 없음.
%
% *** 아직 실행 전 -- MATLAB에서 한 번도 돌려보지 않았다. ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 w5cmp_build

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w5cmp_params();
mdl = p.name;

modelsDir = fullfile(here, '..', 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
open_system(mdl);

fprintf('===== W5CMP BUILD: %s =====\n\n', mdl);
fprintf('예상값: 관절 기준 관성 %.10f, 극점 %.2f / %.2f, 감쇠비 %.3f\n\n', ...
    p.link.J_joint, p.pole(1), p.pole(2), p.zeta);

%% 1. 블록 배치
blk.solver = add1(mdl, 'nesl_utility/Solver Configuration', 'SolverConfiguration', [30 30 90 60]);
blk.mech   = add1(mdl, 'sm_lib/Utilities/Mechanism Configuration', 'MechanismConfiguration', [130 30 190 60]);
blk.world  = add1(mdl, 'sm_lib/Frames and Transforms/World Frame', 'WorldFrame', [230 30 290 60]);
blk.joint  = add1(mdl, 'sm_lib/Joints/Revolute Joint', 'RevoluteJoint', [340 30 400 80]);
blk.link   = add1(mdl, 'sm_lib/Body Elements/Inertia', 'LinkInertia', [460 30 520 80]);

blk.psq    = add1(mdl, 'nesl_utility/PS-Simulink Converter', 'PS2S_q',  [460 130 520 160]);
blk.psqd   = add1(mdl, 'nesl_utility/PS-Simulink Converter', 'PS2S_qd', [460 190 520 220]);
blk.s2ps   = add1(mdl, 'nesl_utility/Simulink-PS Converter', 'S2PS_tau', [250 130 310 160]);

blk.ref    = add1(mdl, 'simulink/Sources/Step', 'Ref_Step', [20 300 60 330]);
blk.zref   = add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_ref', [100 300 140 330]);
blk.zq     = add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_q',   [560 130 600 160]);
blk.zqd    = add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_qd',  [560 190 600 220]);
blk.err    = add1(mdl, 'simulink/Math Operations/Sum', 'Err', [180 300 210 330]);
blk.kp     = add1(mdl, 'simulink/Math Operations/Gain', 'Kp', [250 300 290 330]);
blk.kd     = add1(mdl, 'simulink/Math Operations/Gain', 'Kd', [640 190 680 220]);
blk.tau    = add1(mdl, 'simulink/Math Operations/Sum', 'Tau', [340 300 370 340]);
blk.mux    = add1(mdl, 'simulink/Signal Routing/Mux', 'LogMux', [450 380 455 440]);
blk.log    = add1(mdl, 'simulink/Sinks/To Workspace', 'LogOut', [500 395 580 425]);
fprintf('\n');

%% 2. 파라미터 설정
fprintf('--- 파라미터 ---\n');
setp(blk.mech,  'UniformGravity', p.gravity);

setp(blk.joint, 'TorqueActuationMode', 'InputTorque');
setp(blk.joint, 'SensePosition', 'on');
setp(blk.joint, 'SenseVelocity', 'on');
% 감쇠 0.1 N*m*s/rad: 단위 필드를 rad 기준으로 바꿔 한 곳에서만 반영 (실패하면 deg 환산값으로 대체)
try
    set_param(blk.joint, 'DampingCoefficientUnits', 'N*m/(rad/s)');
    set_param(blk.joint, 'DampingCoefficient', num2str(p.damping));
    fprintf('  [OK] 관절 감쇠 = %s %s\n', get_param(blk.joint, 'DampingCoefficient'), get_param(blk.joint, 'DampingCoefficientUnits'));
catch ME
    fprintf('  [경고] rad 단위 설정 실패 (%s) -> deg 환산값으로 대체\n', ME.message);
    set_param(blk.joint, 'DampingCoefficientUnits', 'N*m/(deg/s)');
    set_param(blk.joint, 'DampingCoefficient', num2str(p.damping*pi/180, 10));
    fprintf('  [OK] 관절 감쇠 = %s %s\n', get_param(blk.joint, 'DampingCoefficient'), get_param(blk.joint, 'DampingCoefficientUnits'));
end

setp(blk.link, 'InertiaType', 'Custom');
setp(blk.link, 'Mass', num2str(p.link.mass));
setp(blk.link, 'CenterOfMass', mat2str(p.link.com));
setp(blk.link, 'MomentsOfInertia', mat2str(p.link.I_com, 10));
setp(blk.link, 'ProductsOfInertia', '[0 0 0]');
setp(blk.link, 'MassUnits', 'kg');
setp(blk.link, 'CenterOfMassUnits', 'm');
setp(blk.link, 'MomentsOfInertiaUnits', 'kg*m^2');
setp(blk.link, 'ProductsOfInertiaUnits', 'kg*m^2');

setp(blk.psq,  'Unit', 'rad');
setp(blk.psqd, 'Unit', 'rad/s');
setp(blk.s2ps, 'Unit', 'N*m');

setp(blk.ref, 'Time', num2str(p.t_step_model, 10));
setp(blk.ref, 'Before', '0');
setp(blk.ref, 'After', num2str(p.q_step));
setp(blk.zref, 'SampleTime', num2str(p.Ts));
setp(blk.zq,   'SampleTime', num2str(p.Ts));
setp(blk.zqd,  'SampleTime', num2str(p.Ts));
setp(blk.err,  'Inputs', '+-');
setp(blk.kp,   'Gain', num2str(p.Kp));
setp(blk.kd,   'Gain', num2str(p.Kd));
setp(blk.tau,  'Inputs', '+-');
setp(blk.mux,  'Inputs', '4');
setp(blk.log,  'VariableName', 'w5cmp_log');
setp(blk.log,  'SaveFormat', 'Timeseries');
setp(blk.log,  'SampleTime', num2str(p.log_dt));

setp(mdl, 'Solver', p.solver);
setp(mdl, 'StopTime', num2str(p.t_end));
setp(mdl, 'RelTol', p.reltol);
setp(mdl, 'AbsTol', p.abstol);
setp(mdl, 'MaxStep', num2str(p.maxsteps(1)));
setp(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
setp(mdl, 'SimscapeLogType', 'none');
fprintf('\n');

%% 3. 연결
fprintf('--- 물리 연결 ---\n');
hW = get_param(blk.world, 'PortHandles');
hJ = get_param(blk.joint, 'PortHandles');
hL = get_param(blk.link,  'PortHandles');
hS = get_param(blk.solver, 'PortHandles');
hM = get_param(blk.mech,   'PortHandles');
fprintf('  Joint 포트: LConn %d개, RConn %d개 (기대: 2, 3)\n', numel(hJ.LConn), numel(hJ.RConn));

conn(mdl, hW.RConn(1), hJ.LConn(1), 'WorldFrame -> Joint.B');
conn(mdl, hJ.RConn(1), hL.RConn(1), 'Joint.F -> LinkInertia');
if ~conn(mdl, hW.RConn(1), hS.RConn(1), 'WorldFrame 노드 -> SolverConfiguration')
    conn(mdl, hJ.LConn(1), hS.RConn(1), 'Joint.B 노드 -> SolverConfiguration (대체)');
end
if ~conn(mdl, hW.RConn(1), hM.RConn(1), 'WorldFrame 노드 -> MechanismConfiguration')
    conn(mdl, hJ.LConn(1), hM.RConn(1), 'Joint.B 노드 -> MechanismConfiguration (대체)');
end

fprintf('--- 신호 연결 ---\n');
hq   = get_param(blk.psq,  'PortHandles');
hqd  = get_param(blk.psqd, 'PortHandles');
hs   = get_param(blk.s2ps, 'PortHandles');
hzr  = get_param(blk.zref, 'PortHandles');
hzq  = get_param(blk.zq,   'PortHandles');
hzqd = get_param(blk.zqd,  'PortHandles');
hr   = get_param(blk.ref,  'PortHandles');
he   = get_param(blk.err,  'PortHandles');
hkp  = get_param(blk.kp,   'PortHandles');
hkd  = get_param(blk.kd,   'PortHandles');
ht   = get_param(blk.tau,  'PortHandles');
hmx  = get_param(blk.mux,  'PortHandles');
hlg  = get_param(blk.log,  'PortHandles');

% 관절 센싱: RConn(2)=q(위치), RConn(3)=w(속도), 토크 입력 LConn(2)
conn(mdl, hJ.RConn(2), hq.LConn(1),  'Joint.q -> PS2S_q');
conn(mdl, hJ.RConn(3), hqd.LConn(1), 'Joint.w -> PS2S_qd');
conn(mdl, hs.RConn(1), hJ.LConn(2),  'S2PS_tau -> Joint.t(토크 입력)');

conn(mdl, hr.Outport(1),  hzr.Inport(1), 'Ref_Step -> ZOH_ref');
conn(mdl, hq.Outport(1),  hzq.Inport(1), 'PS2S_q -> ZOH_q');
conn(mdl, hqd.Outport(1), hzqd.Inport(1), 'PS2S_qd -> ZOH_qd');
conn(mdl, hzr.Outport(1), he.Inport(1),  'ZOH_ref -> Err(+)');
conn(mdl, hzq.Outport(1), he.Inport(2),  'ZOH_q -> Err(-)');
conn(mdl, he.Outport(1),  hkp.Inport(1), 'Err -> Kp');
conn(mdl, hzqd.Outport(1), hkd.Inport(1), 'ZOH_qd -> Kd');
conn(mdl, hkp.Outport(1), ht.Inport(1),  'Kp -> Tau(+)');
conn(mdl, hkd.Outport(1), ht.Inport(2),  'Kd -> Tau(-)');
conn(mdl, ht.Outport(1),  hs.Inport(1),  'Tau -> S2PS_tau');

% 로그: [ref q qdot tau]  (q, qdot는 샘플-유지 전 실제 상태, tau는 그 시각에 계산해 유지한 토크)
conn(mdl, hzr.Outport(1), hmx.Inport(1), 'ZOH_ref -> LogMux(1)');
conn(mdl, hq.Outport(1),  hmx.Inport(2), 'PS2S_q -> LogMux(2)');
conn(mdl, hqd.Outport(1), hmx.Inport(3), 'PS2S_qd -> LogMux(3)');
conn(mdl, ht.Outport(1),  hmx.Inport(4), 'Tau -> LogMux(4)');
conn(mdl, hmx.Outport(1), hlg.Inport(1), 'LogMux -> To Workspace');

save_system(mdl, fullfile(modelsDir, [mdl '.slx']));
fprintf('\n[OK] 저장: %s\n', fullfile(modelsDir, [mdl '.slx']));

%% 4. 설정 읽어서 확인
fprintf('\n--- 저장된 값 읽기(확인) ---\n');
chk = {blk.mech, 'UniformGravity'; blk.joint, 'TorqueActuationMode'; blk.joint, 'DampingCoefficient'; ...
       blk.joint, 'DampingCoefficientUnits'; blk.joint, 'SpringStiffness'; blk.link, 'Mass'; ...
       blk.link, 'CenterOfMass'; blk.link, 'MomentsOfInertia'; blk.psq, 'Unit'; blk.psqd, 'Unit'; ...
       blk.s2ps, 'Unit'; blk.ref, 'Time'; blk.kp, 'Gain'; blk.kd, 'Gain'};
for i = 1:size(chk, 1)
    try
        fprintf('  %-28s %-26s = %s\n', strrep(chk{i,1}, [mdl '/'], ''), chk{i,2}, get_param(chk{i,1}, chk{i,2}));
    catch ME
        fprintf('  %-28s %-26s : 조회 실패 (%s)\n', strrep(chk{i,1}, [mdl '/'], ''), chk{i,2}, ME.message);
    end
end
fprintf('\n===== BUILD 끝. [실패]/[경고]가 있으면 출력 전체를 붙여넣어 달라. 없으면 w5cmp_run 실행. =====\n');

%% ---- 로컬 함수 ----
function path = add1(mdl, src, name, pos)
    path = [mdl '/' name];
    try
        add_block(src, path, 'Position', pos);
        fprintf('  [OK] %s\n', name);
    catch ME
        fprintf('  [실패] %s (%s): %s\n', name, src, ME.message);
    end
end

function setp(blockpath, name, value)
    try
        set_param(blockpath, name, value);
        fprintf('  [OK] %s.%s = %s\n', regexprep(blockpath, '^[^/]*/?', ''), name, value);
    catch ME
        fprintf('  [실패] %s.%s = %s : %s\n', regexprep(blockpath, '^[^/]*/?', ''), name, value, ME.message);
    end
end

function ok = conn(mdl, src, dst, label)
    ok = false;
    try
        add_line(mdl, src, dst, 'autorouting', 'on');
        fprintf('  [OK] %s\n', label);
        ok = true;
    catch ME
        fprintf('  [실패] %s : %s\n', label, ME.message);
    end
end
