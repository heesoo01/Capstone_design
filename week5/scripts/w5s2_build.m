%% W5S2_BUILD
% 2단계 모델 2개를 새로 만든다 (표준 Simulink 블록 + Simscape 관절만 사용, 컴파일러 불필요).
%   w5_stage2_pmsm_alone : 2-1 전기 모델 단독 (모터 속도 0 고정, vd=0, vq=1 V)
%   w5_stage2_pmsm_joint : 2-2 / 2-3 PMSM + 전류 PI + 평균 인버터 + 1단계 관절
%
% *** 아직 실행 전 -- MATLAB에서 한 번도 돌려보지 않았다. ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 w5s2_build

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w5s2_params();
modelsDir = fullfile(here, '..', 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end

buildAlone(p, modelsDir);
buildJoint(p, modelsDir);
fprintf('\n===== W5S2 BUILD 끝. [실패]/[경고]가 있으면 출력 전체를 붙여넣어 달라. 없으면 w5s2_run(1) 로 빠르게 먼저 확인. =====\n');

%% ================= 2-1 전기 단독 =================
function buildAlone(p, modelsDir)
    mdl = p.name_alone;
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl); open_system(mdl);
    fprintf('\n===== BUILD %s =====\n', mdl);
    n2s = @(x) num2str(x, 12);
    add1(mdl, 'simulink/Sources/Constant', 'Cvd', 'Value', n2s(p.t21_vd));
    add1(mdl, 'simulink/Sources/Constant', 'Cvq', 'Value', n2s(p.t21_vq));
    add1(mdl, 'simulink/Sources/Constant', 'Cwm', 'Value', '0');
    plant(mdl, p, 'Cvd', 'Cvq', 'Cwm');
    add1(mdl, 'simulink/Signal Routing/Mux', 'LogMux', 'Inputs', '6');
    add1(mdl, 'simulink/Sinks/To Workspace', 'LogOut', 'VariableName', 'w5s2_alone', ...
         'SaveFormat', 'Timeseries', 'SampleTime', n2s(p.cur.Ts));
    wn(mdl, 'Cvd', 1, 'LogMux', 1);
    wn(mdl, 'Cvq', 1, 'LogMux', 2);
    wn(mdl, 'Cwm', 1, 'LogMux', 3);
    wn(mdl, 'Int_id', 1, 'LogMux', 4);
    wn(mdl, 'Int_iq', 1, 'LogMux', 5);
    wn(mdl, 'Gtau', 1, 'LogMux', 6);
    wn(mdl, 'LogMux', 1, 'LogOut', 1);
    setm(mdl, 'Solver', p.solver); setm(mdl, 'StopTime', n2s(p.t21_end));
    setm(mdl, 'RelTol', p.reltol); setm(mdl, 'AbsTol', p.abstol);
    setm(mdl, 'MaxStep', n2s(p.s2.maxsteps(1)));
    save_system(mdl, fullfile(modelsDir, [mdl '.slx']));
    fprintf('[OK] 저장: %s\n', fullfile(modelsDir, [mdl '.slx']));
end

%% ================= 2-2 / 2-3 통합 =================
function buildJoint(p, modelsDir)
    mdl = p.name_joint;
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl); open_system(mdl);
    fprintf('\n===== BUILD %s =====\n', mdl);
    n2s = @(x) num2str(x, 12);
    pm = p.pmsm; cu = p.cur;

    % --- 기계 (1단계와 동일) ---
    add1(mdl, 'nesl_utility/Solver Configuration', 'SolverConfiguration');
    add1(mdl, 'sm_lib/Utilities/Mechanism Configuration', 'MechanismConfiguration');
    add1(mdl, 'sm_lib/Frames and Transforms/World Frame', 'WorldFrame');
    add1(mdl, 'sm_lib/Joints/Revolute Joint', 'RevoluteJoint');
    add1(mdl, 'sm_lib/Body Elements/Inertia', 'LinkInertia');
    add1(mdl, 'nesl_utility/PS-Simulink Converter', 'PS2S_q');
    add1(mdl, 'nesl_utility/PS-Simulink Converter', 'PS2S_qd');
    add1(mdl, 'nesl_utility/Simulink-PS Converter', 'S2PS_tau');
    j = [mdl '/RevoluteJoint'];
    setp([mdl '/MechanismConfiguration'], 'UniformGravity', p.gravity);
    setp(j, 'TorqueActuationMode', 'InputTorque');
    setp(j, 'SensePosition', 'on');
    setp(j, 'SenseVelocity', 'on');
    try
        set_param(j, 'DampingCoefficientUnits', 'N*m/(rad/s)');
        set_param(j, 'DampingCoefficient', n2s(p.damping));
        fprintf('  [OK] 관절 감쇠 = %s %s\n', get_param(j, 'DampingCoefficient'), get_param(j, 'DampingCoefficientUnits'));
    catch ME
        fprintf('  [경고] rad 단위 실패 (%s) -> deg 환산\n', ME.message);
        set_param(j, 'DampingCoefficientUnits', 'N*m/(deg/s)');
        set_param(j, 'DampingCoefficient', num2str(p.damping * pi / 180, 10));
    end
    li = [mdl '/LinkInertia'];
    setp(li, 'InertiaType', 'Custom');
    setp(li, 'Mass', n2s(p.link.mass));
    setp(li, 'CenterOfMass', mat2str(p.link.com));
    setp(li, 'MomentsOfInertia', mat2str(p.link.I_com, 10));
    setp(li, 'ProductsOfInertia', '[0 0 0]');
    setp([mdl '/PS2S_q'], 'Unit', 'rad');
    setp([mdl '/PS2S_qd'], 'Unit', 'rad/s');
    setp([mdl '/S2PS_tau'], 'Unit', 'N*m');

    hW = get_param([mdl '/WorldFrame'], 'PortHandles');
    hJ = get_param(j, 'PortHandles');
    hL = get_param(li, 'PortHandles');
    hS = get_param([mdl '/SolverConfiguration'], 'PortHandles');
    hM = get_param([mdl '/MechanismConfiguration'], 'PortHandles');
    fprintf('  Joint 포트: LConn %d개, RConn %d개 (기대 2, 3)\n', numel(hJ.LConn), numel(hJ.RConn));
    wp(mdl, hW.RConn(1), hJ.LConn(1), 'WorldFrame -> Joint.B');
    wp(mdl, hJ.RConn(1), hL.RConn(1), 'Joint.F -> LinkInertia');
    if ~wp(mdl, hW.RConn(1), hS.RConn(1), 'World 노드 -> Solver'), wp(mdl, hJ.LConn(1), hS.RConn(1), 'Joint.B 노드 -> Solver'); end
    if ~wp(mdl, hW.RConn(1), hM.RConn(1), 'World 노드 -> Mechanism'), wp(mdl, hJ.LConn(1), hM.RConn(1), 'Joint.B 노드 -> Mechanism'); end
    hq = get_param([mdl '/PS2S_q'], 'PortHandles');
    hqd = get_param([mdl '/PS2S_qd'], 'PortHandles');
    hs = get_param([mdl '/S2PS_tau'], 'PortHandles');
    wp(mdl, hJ.RConn(2), hq.LConn(1), 'Joint.q -> PS2S_q');
    wp(mdl, hJ.RConn(3), hqd.LConn(1), 'Joint.w -> PS2S_qd');
    wp(mdl, hs.RConn(1), hJ.LConn(2), 'S2PS_tau -> Joint.t');

    % --- 위치 제어 (1 ms) : tau* = Kp(qref-q) - Kd*qdot, iq* = clip(tau*/Kt, +-2) ---
    add1(mdl, 'simulink/Sources/Step', 'Ref_Step', 'Time', n2s(p.t_step_model), 'Before', '0', 'After', n2s(p.t22_target));
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_ref', 'SampleTime', n2s(p.Ts));
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_q', 'SampleTime', n2s(p.Ts));
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_qd', 'SampleTime', n2s(p.Ts));
    add1(mdl, 'simulink/Math Operations/Sum', 'PErr', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'PKp', 'Gain', n2s(p.Kp));
    add1(mdl, 'simulink/Math Operations/Gain', 'PKd', 'Gain', n2s(p.Kd));
    add1(mdl, 'simulink/Math Operations/Sum', 'PTau', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'PInvKt', 'Gain', n2s(1 / pm.Kt));
    add1(mdl, 'simulink/Discontinuities/Saturation', 'PSat', 'UpperLimit', n2s(cu.iq_lim), 'LowerLimit', n2s(-cu.iq_lim));
    wn(mdl, 'Ref_Step', 1, 'ZOH_ref', 1);
    wn(mdl, 'PS2S_q', 1, 'ZOH_q', 1);
    wn(mdl, 'PS2S_qd', 1, 'ZOH_qd', 1);
    wn(mdl, 'ZOH_ref', 1, 'PErr', 1); wn(mdl, 'ZOH_q', 1, 'PErr', 2);
    wn(mdl, 'PErr', 1, 'PKp', 1); wn(mdl, 'ZOH_qd', 1, 'PKd', 1);
    wn(mdl, 'PKp', 1, 'PTau', 1); wn(mdl, 'PKd', 1, 'PTau', 2);
    wn(mdl, 'PTau', 1, 'PInvKt', 1); wn(mdl, 'PInvKt', 1, 'PSat', 1);

    % --- 전류 제어 (100 us) ---
    Ts = n2s(cu.Ts);
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_id', 'SampleTime', Ts);
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_iq', 'SampleTime', Ts);
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_wm', 'SampleTime', Ts);
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'ZOH_iqref', 'SampleTime', Ts);
    add1(mdl, 'simulink/Math Operations/Gain', 'Gwe_s', 'Gain', n2s(pm.pp));
    add1(mdl, 'simulink/Math Operations/Gain', 'Ged', 'Gain', '-1');                 % ed = 0 - id
    add1(mdl, 'simulink/Math Operations/Sum', 'CEq', 'Inputs', '+-');                % eq = iq* - iq
    add1(mdl, 'simulink/Math Operations/Product', 'Pffd', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Gain', 'Gffd', 'Gain', n2s(-pm.L));          % ffd = -we*L*iq
    add1(mdl, 'simulink/Math Operations/Gain', 'GLid', 'Gain', n2s(pm.L));
    add1(mdl, 'simulink/Sources/Constant', 'Cpsi', 'Value', n2s(pm.psi));
    add1(mdl, 'simulink/Math Operations/Sum', 'SffA', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Product', 'Pffq', 'Inputs', '2');            % ffq = we*(L*id+psi)
    add1(mdl, 'simulink/Math Operations/Gain', 'GKpd', 'Gain', n2s(cu.Kp));
    add1(mdl, 'simulink/Math Operations/Gain', 'GKpq', 'Gain', n2s(cu.Kp));
    add1(mdl, 'simulink/Discrete/Unit Delay', 'UDd', 'InitialCondition', '0', 'SampleTime', Ts);
    add1(mdl, 'simulink/Discrete/Unit Delay', 'UDq', 'InitialCondition', '0', 'SampleTime', Ts);
    add1(mdl, 'simulink/Math Operations/Sum', 'Svd', 'Inputs', '+++');               % vd_cmd
    add1(mdl, 'simulink/Math Operations/Sum', 'Svq', 'Inputs', '+++');               % vq_cmd
    add1(mdl, 'simulink/Math Operations/Product', 'Pvd2', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'Pvq2', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'Snorm', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Sqrt', 'Rsq');
    add1(mdl, 'simulink/Sources/Constant', 'Ceps', 'Value', '1e-12');
    add1(mdl, 'simulink/Math Operations/MinMax', 'Mxn', 'Function', 'max', 'Inputs', '2');
    add1(mdl, 'simulink/Sources/Constant', 'Cvmax', 'Value', n2s(p.vmax(p.Vdc)));
    add1(mdl, 'simulink/Math Operations/Product', 'Dv', 'Inputs', '*/');
    add1(mdl, 'simulink/Sources/Constant', 'C1', 'Value', '1');
    add1(mdl, 'simulink/Math Operations/MinMax', 'Mns', 'Function', 'min', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'Pvds', 'Inputs', '2');            % vd_sat
    add1(mdl, 'simulink/Math Operations/Product', 'Pvqs', 'Inputs', '2');            % vq_sat
    add1(mdl, 'simulink/Math Operations/Sum', 'SDd', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Sum', 'SDq', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'GKawd', 'Gain', n2s(cu.Kaw));
    add1(mdl, 'simulink/Math Operations/Gain', 'GKawq', 'Gain', n2s(cu.Kaw));
    add1(mdl, 'simulink/Math Operations/Gain', 'GKid', 'Gain', n2s(cu.Ki));
    add1(mdl, 'simulink/Math Operations/Gain', 'GKiq', 'Gain', n2s(cu.Ki));
    add1(mdl, 'simulink/Math Operations/Sum', 'Sud', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Sum', 'Suq', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Gain', 'GTsd', 'Gain', Ts);
    add1(mdl, 'simulink/Math Operations/Gain', 'GTsq', 'Gain', Ts);
    add1(mdl, 'simulink/Math Operations/Sum', 'SIdn', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Sum', 'SIqn', 'Inputs', '++');
    add1(mdl, 'simulink/Logic and Bit Operations/Relational Operator', 'Rsat', 'Operator', '>');
    add1(mdl, 'simulink/Signal Attributes/Data Type Conversion', 'Dsat', 'OutDataTypeStr', 'double');

    plant(mdl, p, 'Pvds', 'Pvqs', 'PS2S_qd');

    wn(mdl, 'Int_id', 1, 'ZOH_id', 1);
    wn(mdl, 'Int_iq', 1, 'ZOH_iq', 1);
    wn(mdl, 'PS2S_qd', 1, 'ZOH_wm', 1);
    wn(mdl, 'PSat', 1, 'ZOH_iqref', 1);
    wn(mdl, 'ZOH_wm', 1, 'Gwe_s', 1);
    wn(mdl, 'ZOH_id', 1, 'Ged', 1);
    wn(mdl, 'ZOH_iqref', 1, 'CEq', 1); wn(mdl, 'ZOH_iq', 1, 'CEq', 2);
    wn(mdl, 'Gwe_s', 1, 'Pffd', 1); wn(mdl, 'ZOH_iq', 1, 'Pffd', 2); wn(mdl, 'Pffd', 1, 'Gffd', 1);
    wn(mdl, 'ZOH_id', 1, 'GLid', 1); wn(mdl, 'GLid', 1, 'SffA', 1); wn(mdl, 'Cpsi', 1, 'SffA', 2);
    wn(mdl, 'Gwe_s', 1, 'Pffq', 1); wn(mdl, 'SffA', 1, 'Pffq', 2);
    wn(mdl, 'Ged', 1, 'GKpd', 1); wn(mdl, 'CEq', 1, 'GKpq', 1);
    wn(mdl, 'GKpd', 1, 'Svd', 1); wn(mdl, 'UDd', 1, 'Svd', 2); wn(mdl, 'Gffd', 1, 'Svd', 3);
    wn(mdl, 'GKpq', 1, 'Svq', 1); wn(mdl, 'UDq', 1, 'Svq', 2); wn(mdl, 'Pffq', 1, 'Svq', 3);
    wn(mdl, 'Svd', 1, 'Pvd2', 1); wn(mdl, 'Svd', 1, 'Pvd2', 2);
    wn(mdl, 'Svq', 1, 'Pvq2', 1); wn(mdl, 'Svq', 1, 'Pvq2', 2);
    wn(mdl, 'Pvd2', 1, 'Snorm', 1); wn(mdl, 'Pvq2', 1, 'Snorm', 2);
    wn(mdl, 'Snorm', 1, 'Rsq', 1);
    wn(mdl, 'Rsq', 1, 'Mxn', 1); wn(mdl, 'Ceps', 1, 'Mxn', 2);
    wn(mdl, 'Cvmax', 1, 'Dv', 1); wn(mdl, 'Mxn', 1, 'Dv', 2);
    wn(mdl, 'C1', 1, 'Mns', 1); wn(mdl, 'Dv', 1, 'Mns', 2);
    wn(mdl, 'Mns', 1, 'Pvds', 1); wn(mdl, 'Svd', 1, 'Pvds', 2);
    wn(mdl, 'Mns', 1, 'Pvqs', 1); wn(mdl, 'Svq', 1, 'Pvqs', 2);
    wn(mdl, 'Pvds', 1, 'SDd', 1); wn(mdl, 'Svd', 1, 'SDd', 2); wn(mdl, 'SDd', 1, 'GKawd', 1);
    wn(mdl, 'Pvqs', 1, 'SDq', 1); wn(mdl, 'Svq', 1, 'SDq', 2); wn(mdl, 'SDq', 1, 'GKawq', 1);
    wn(mdl, 'Ged', 1, 'GKid', 1); wn(mdl, 'CEq', 1, 'GKiq', 1);
    wn(mdl, 'GKid', 1, 'Sud', 1); wn(mdl, 'GKawd', 1, 'Sud', 2);
    wn(mdl, 'GKiq', 1, 'Suq', 1); wn(mdl, 'GKawq', 1, 'Suq', 2);
    wn(mdl, 'Sud', 1, 'GTsd', 1); wn(mdl, 'Suq', 1, 'GTsq', 1);
    wn(mdl, 'GTsd', 1, 'SIdn', 1); wn(mdl, 'UDd', 1, 'SIdn', 2); wn(mdl, 'SIdn', 1, 'UDd', 1);
    wn(mdl, 'GTsq', 1, 'SIqn', 1); wn(mdl, 'UDq', 1, 'SIqn', 2); wn(mdl, 'SIqn', 1, 'UDq', 1);
    wn(mdl, 'Rsq', 1, 'Rsat', 1); wn(mdl, 'Cvmax', 1, 'Rsat', 2); wn(mdl, 'Rsat', 1, 'Dsat', 1);
    wn(mdl, 'Gtau', 1, 'S2PS_tau', 1);

    % --- 로그: 위치 CSV(1 ms) / 전기 CSV(100 us) ---
    add1(mdl, 'simulink/Signal Routing/Mux', 'PMux', 'Inputs', '5');
    add1(mdl, 'simulink/Sinks/To Workspace', 'PLog', 'VariableName', 'w5s2_plog', 'SaveFormat', 'Timeseries', 'SampleTime', n2s(p.log_dt));
    wn(mdl, 'ZOH_ref', 1, 'PMux', 1); wn(mdl, 'PS2S_q', 1, 'PMux', 2); wn(mdl, 'PS2S_qd', 1, 'PMux', 3);
    wn(mdl, 'PTau', 1, 'PMux', 4); wn(mdl, 'Gtau', 1, 'PMux', 5); wn(mdl, 'PMux', 1, 'PLog', 1);
    add1(mdl, 'simulink/Signal Routing/Mux', 'EMux', 'Inputs', '9');
    add1(mdl, 'simulink/Sinks/To Workspace', 'ELog', 'VariableName', 'w5s2_elog', 'SaveFormat', 'Timeseries', 'SampleTime', Ts);
    wn(mdl, 'ZOH_iqref', 1, 'EMux', 1); wn(mdl, 'Int_id', 1, 'EMux', 2); wn(mdl, 'Int_iq', 1, 'EMux', 3);
    wn(mdl, 'Svd', 1, 'EMux', 4); wn(mdl, 'Svq', 1, 'EMux', 5); wn(mdl, 'Pvds', 1, 'EMux', 6);
    wn(mdl, 'Pvqs', 1, 'EMux', 7); wn(mdl, 'Dsat', 1, 'EMux', 8); wn(mdl, 'PS2S_qd', 1, 'EMux', 9);
    wn(mdl, 'EMux', 1, 'ELog', 1);

    setm(mdl, 'Solver', p.solver); setm(mdl, 'StopTime', n2s(p.t_end));
    setm(mdl, 'RelTol', p.reltol); setm(mdl, 'AbsTol', p.abstol);
    setm(mdl, 'MaxStep', n2s(p.s2.maxsteps(1)));
    setm(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
    setm(mdl, 'SimscapeLogType', 'none');
    save_system(mdl, fullfile(modelsDir, [mdl '.slx']));
    fprintf('[OK] 저장: %s\n', fullfile(modelsDir, [mdl '.slx']));
end

%% ================= PMSM dq 플랜트 (연속시간) =================
function plant(mdl, p, vdSrc, vqSrc, wmSrc)
    n2s = @(x) num2str(x, 12);
    R = p.pmsm.R; L = p.pmsm.L; psi = p.pmsm.psi; pp = p.pmsm.pp; Kt = p.pmsm.Kt;
    add1(mdl, 'simulink/Math Operations/Gain', 'Gwe', 'Gain', n2s(pp));                 % we = pp*wm
    add1(mdl, 'simulink/Math Operations/Gain', 'GvdL', 'Gain', n2s(1 / L));
    add1(mdl, 'simulink/Math Operations/Gain', 'GvqL', 'Gain', n2s(1 / L));
    add1(mdl, 'simulink/Math Operations/Gain', 'GRLd', 'Gain', n2s(R / L));
    add1(mdl, 'simulink/Math Operations/Gain', 'GRLq', 'Gain', n2s(R / L));
    add1(mdl, 'simulink/Math Operations/Gain', 'GpsiL', 'Gain', n2s(psi / L));
    add1(mdl, 'simulink/Math Operations/Product', 'Pwi', 'Inputs', '2');                % we*iq
    add1(mdl, 'simulink/Math Operations/Product', 'Pwd', 'Inputs', '2');                % we*id
    add1(mdl, 'simulink/Math Operations/Sum', 'Sdid', 'Inputs', '+-+');                 % did = vd/L - (R/L)id + we*iq
    add1(mdl, 'simulink/Math Operations/Sum', 'Sdiq', 'Inputs', '+---');                % diq = vq/L - (R/L)iq - we*id - (psi/L)*we
    add1(mdl, 'simulink/Continuous/Integrator', 'Int_id', 'InitialCondition', '0');
    add1(mdl, 'simulink/Continuous/Integrator', 'Int_iq', 'InitialCondition', '0');
    add1(mdl, 'simulink/Math Operations/Gain', 'Gtau', 'Gain', n2s(Kt));                % tau = 1.5*pp*psi*iq
    wn(mdl, wmSrc, 1, 'Gwe', 1);
    wn(mdl, vdSrc, 1, 'GvdL', 1); wn(mdl, vqSrc, 1, 'GvqL', 1);
    wn(mdl, 'Int_id', 1, 'GRLd', 1); wn(mdl, 'Int_iq', 1, 'GRLq', 1);
    wn(mdl, 'Gwe', 1, 'Pwi', 1); wn(mdl, 'Int_iq', 1, 'Pwi', 2);
    wn(mdl, 'Gwe', 1, 'Pwd', 1); wn(mdl, 'Int_id', 1, 'Pwd', 2);
    wn(mdl, 'Gwe', 1, 'GpsiL', 1);
    wn(mdl, 'GvdL', 1, 'Sdid', 1); wn(mdl, 'GRLd', 1, 'Sdid', 2); wn(mdl, 'Pwi', 1, 'Sdid', 3);
    wn(mdl, 'GvqL', 1, 'Sdiq', 1); wn(mdl, 'GRLq', 1, 'Sdiq', 2); wn(mdl, 'Pwd', 1, 'Sdiq', 3); wn(mdl, 'GpsiL', 1, 'Sdiq', 4);
    wn(mdl, 'Sdid', 1, 'Int_id', 1); wn(mdl, 'Sdiq', 1, 'Int_iq', 1);
    wn(mdl, 'Int_iq', 1, 'Gtau', 1);
end

%% ================= 헬퍼 =================
function ok = add1(mdl, src, name, varargin)
    n = numel(find_system(mdl, 'SearchDepth', 1, 'Type', 'Block'));
    col = mod(n, 9); row = floor(n / 9);
    pos = [30 + col * 150, 30 + row * 60, 100 + col * 150, 60 + row * 60];
    ok = true;
    try
        add_block(src, [mdl '/' name], 'Position', pos, varargin{:});
    catch ME
        ok = false;
        fprintf('  [실패] 블록 %s (%s): %s\n', name, src, ME.message);
    end
end

function wn(mdl, a, ai, b, bi)
    try
        pa = get_param([mdl '/' a], 'PortHandles');
        pb = get_param([mdl '/' b], 'PortHandles');
        add_line(mdl, pa.Outport(ai), pb.Inport(bi), 'autorouting', 'on');
    catch ME
        fprintf('  [실패] 신호선 %s:%d -> %s:%d : %s\n', a, ai, b, bi, ME.message);
    end
end

function ok = wp(mdl, src, dst, label)
    ok = false;
    try
        add_line(mdl, src, dst, 'autorouting', 'on');
        fprintf('  [OK] %s\n', label);
        ok = true;
    catch ME
        fprintf('  [실패] %s : %s\n', label, ME.message);
    end
end

function setp(blockpath, name, value)
    try
        set_param(blockpath, name, value);
    catch ME
        fprintf('  [실패] %s.%s = %s : %s\n', blockpath, name, value, ME.message);
    end
end

function setm(mdl, name, value)
    try
        set_param(mdl, name, value);
    catch ME
        fprintf('  [실패] 모델 설정 %s = %s : %s\n', name, value, ME.message);
    end
end
