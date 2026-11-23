%% W6S44_BUILD
% 4-4 (권선 열 모델) 모델을 만든다.
%   w6_stage4_4_joint : 5주차 검증 모델 w5_stage3_2_joint.slx (기어비 5, 회전자 관성 관절 환산 0.0025 한 번만 가산)를 복사해
%       PMSM 전기식의 R/L 항에 R(T) 를 넣고, 열 노드(방식 A: 1 ms 이산 업데이트)와 에너지 로그를 추가한다.
%       열 업데이트(README §3): 1 ms 동안 R 과 온도 유지, 누적 동손 E_cu 를 전달.
%         구간 평균 전력 P = dE/dt 를 일정 입력으로 보고 C dT/dt = P - (T-Tamb)/Rth 의 정확해로 T 갱신
%         T_k = Tamb + P*Rth + (T_{k-1} - Tamb - P*Rth) * exp(-dt/(C*Rth))
%         (처음에는 민혁 코드를 받지 못해 CSV 의 매 1 ms 온도 변화를 대조해 정했다: 오차 1.4e-14 C. 이후 받은 stage4_4_core.py 의
%          thermal_step() 을 읽고 같은 식임을 확인했다. 열 업데이트는 k%nth==0 (1 ms) 시점, 평균 전력 = 누적 동손 / 1 ms. 코드를 읽어 확인한 것이며 민혁 쪽을 다시 실행하지는 않았다.)
%       T0 = 25(고정/열 모델), 80 과 열 모델 on/off 는 w6s44_run 이 블록 값(XT0, XEn, 지연 블록 초기값)으로 설정한다.
%   w6_stage4_4_thermal_heat / _current / _cooling : 독립 열 시험(600 s) 연속시간 ODE (Simulink 적분기, 제어기·관절 없음)
% 주의: [실패] 또는 [경고] 로그가 나오면 그대로 알려줄 것.
% 실행: cd week6\scripts 후  w6s44_build

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s44_params();
modelsDir = fullfile(here, '..', 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
srcMdl = fullfile(here, '..', '..', 'week5', 'models', 'w5_stage3_2_joint.slx');
if ~isfile(srcMdl), error('5주차 모델이 없다: %s', srcMdl); end
M = p.t44.models;

buildJoint(p, srcMdl, modelsDir, M.joint);
buildThermal(p, modelsDir, M.heat, 'heat');
buildThermal(p, modelsDir, M.current, 'current');
buildThermal(p, modelsDir, M.cooling, 'cooling');
fprintf('\n===== W6S44 BUILD 끝. [실패]/[경고] 가 있었는지 확인 =====\n');

%% ================= 통합 모델 (5주차 3-2 복사 후 R(T)·열 노드 추가) =================
function buildJoint(p, srcMdl, modelsDir, mdl)
    fprintf('\n===== BUILD %s =====\n', mdl);
    n2s = @(x) num2str(x, 16);
    th = p.th; dt = th.dt_upd; a = exp(-dt / th.tau);
    dst = fullfile(modelsDir, [mdl '.slx']);
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    copyfile(srcMdl, dst);
    fileattrib(dst, '+w');
    load_system(dst);
    % --- R(T): Int_id/Int_iq -> GRLd/GRLq 연결을 끊고 (R(T)/L * i) 곱셈을 끼운다. GRLd/GRLq 이득은 1 (통과) ---
    cutInport(mdl, 'GRLd', 1);
    cutInport(mdl, 'GRLq', 1);
    setb(mdl, 'GRLd', 'Gain', '1');
    setb(mdl, 'GRLq', 'Gain', '1');
    add1(mdl, 'simulink/Math Operations/Product', 'XPRd', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'XPRq', 'Inputs', '2');
    wn(mdl, 'Int_id', 1, 'XPRd', 1); wn(mdl, 'XPRd', 1, 'GRLd', 1);
    wn(mdl, 'Int_iq', 1, 'XPRq', 1); wn(mdl, 'XPRq', 1, 'GRLq', 1);   % XRL(= R(T)/L) 은 아래에서 만든 뒤 입력 2 에 연결
    % --- 동손 P_cu = 1.5 R (id^2 + iq^2), 누적 E_cu ---
    add1(mdl, 'simulink/Math Operations/Product', 'XSqd', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'XSqq', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XSs', 'Inputs', '++');                      % id^2 + iq^2
    wn(mdl, 'Int_id', 1, 'XSqd', 1); wn(mdl, 'Int_id', 1, 'XSqd', 2);
    wn(mdl, 'Int_iq', 1, 'XSqq', 1); wn(mdl, 'Int_iq', 1, 'XSqq', 2);
    wn(mdl, 'XSqd', 1, 'XSs', 1); wn(mdl, 'XSqq', 1, 'XSs', 2);
    add1(mdl, 'simulink/Math Operations/Product', 'XPcuS', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Gain', 'XPcu', 'Gain', '1.5');
    add1(mdl, 'simulink/Continuous/Integrator', 'XEcu', 'InitialCondition', '0');
    wn(mdl, 'XSs', 1, 'XPcuS', 1); wn(mdl, 'XPcuS', 1, 'XPcu', 1); wn(mdl, 'XPcu', 1, 'XEcu', 1);
    % --- 열 업데이트 (이산, dt): dE = E(t_k) - E(t_{k-1}) ---
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'XEz', 'SampleTime', n2s(dt));
    add1(mdl, 'simulink/Discrete/Unit Delay', 'XEzd', 'SampleTime', n2s(dt), 'InitialCondition', '0');
    add1(mdl, 'simulink/Math Operations/Sum', 'XdE', 'Inputs', '+-');
    wn(mdl, 'XEcu', 1, 'XEz', 1); wn(mdl, 'XEz', 1, 'XEzd', 1); wn(mdl, 'XEz', 1, 'XdE', 1); wn(mdl, 'XEzd', 1, 'XdE', 2);
    add1(mdl, 'simulink/Math Operations/Gain', 'XA1', 'Gain', n2s(th.Rth / dt * (1 - a)));   % Rth*(dE/dt)*(1-a)
    add1(mdl, 'simulink/Sources/Constant', 'XCta', 'Value', n2s(th.Tamb * (1 - a)));
    add1(mdl, 'simulink/Discrete/Unit Delay', 'XTprev', 'SampleTime', n2s(dt), 'InitialCondition', '25');   % IC 는 run 에서 T0 로 설정
    add1(mdl, 'simulink/Math Operations/Gain', 'XAp', 'Gain', n2s(a));
    add1(mdl, 'simulink/Math Operations/Sum', 'XTc', 'Inputs', '+++');
    wn(mdl, 'XdE', 1, 'XA1', 1); wn(mdl, 'XTprev', 1, 'XAp', 1);
    wn(mdl, 'XA1', 1, 'XTc', 1); wn(mdl, 'XCta', 1, 'XTc', 2); wn(mdl, 'XAp', 1, 'XTc', 3);
    % t = 0 에서는 T0 유지: F = 지연된 1 (t=0 에서 0, 이후 1)
    add1(mdl, 'simulink/Sources/Constant', 'XC1', 'Value', '1');
    add1(mdl, 'simulink/Discrete/Unit Delay', 'XF', 'SampleTime', n2s(dt), 'InitialCondition', '0');
    add1(mdl, 'simulink/Sources/Constant', 'XT0', 'Value', '25');                                  % run 에서 T0 로 설정
    add1(mdl, 'simulink/Math Operations/Sum', 'XTd', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Product', 'XTf', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XTo', 'Inputs', '++');
    wn(mdl, 'XC1', 1, 'XF', 1);
    wn(mdl, 'XTc', 1, 'XTd', 1); wn(mdl, 'XT0', 1, 'XTd', 2);
    wn(mdl, 'XF', 1, 'XTf', 1); wn(mdl, 'XTd', 1, 'XTf', 2);
    wn(mdl, 'XT0', 1, 'XTo', 1); wn(mdl, 'XTf', 1, 'XTo', 2);
    wn(mdl, 'XTo', 1, 'XTprev', 1);
    % 열 모델 on/off (off: 항온 25 C 고정, 이상적 항온 장치)
    add1(mdl, 'simulink/Sources/Constant', 'XEn', 'Value', '1');
    add1(mdl, 'simulink/Sources/Constant', 'XTa', 'Value', n2s(th.Tamb));
    add1(mdl, 'simulink/Math Operations/Sum', 'XTfd', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Product', 'XTfp', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XTfin', 'Inputs', '++');
    wn(mdl, 'XTo', 1, 'XTfd', 1); wn(mdl, 'XTa', 1, 'XTfd', 2);
    wn(mdl, 'XEn', 1, 'XTfp', 1); wn(mdl, 'XTfd', 1, 'XTfp', 2);
    wn(mdl, 'XTa', 1, 'XTfin', 1); wn(mdl, 'XTfp', 1, 'XTfin', 2);
    % --- 저항 R(T) = Rref [1 + alpha (T - Tref)], 유지값 ---
    add1(mdl, 'simulink/Math Operations/Gain', 'XRg', 'Gain', n2s(th.Rref * th.alpha));
    add1(mdl, 'simulink/Sources/Constant', 'XRc', 'Value', n2s(th.Rref * (1 - th.alpha * th.Tref)));
    add1(mdl, 'simulink/Math Operations/Sum', 'XR', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Gain', 'XRL', 'Gain', n2s(1 / p.pmsm.L));
    wn(mdl, 'XTfin', 1, 'XRg', 1); wn(mdl, 'XRg', 1, 'XR', 1); wn(mdl, 'XRc', 1, 'XR', 2); wn(mdl, 'XR', 1, 'XRL', 1);
    wn(mdl, 'XRL', 1, 'XPRd', 2); wn(mdl, 'XRL', 1, 'XPRq', 2);
    wn(mdl, 'XR', 1, 'XPcuS', 2);                                                                   % 동손 곱셈에도 같은 유지값 R
    % --- 주변 방열 출력, 열 노드 쪽 소구간 방열량 (온도 변화에서 구한 값, 이산 누적) ---
    add1(mdl, 'simulink/Math Operations/Sum', 'XTcm', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'XPcool', 'Gain', n2s(1 / th.Rth));
    wn(mdl, 'XTfin', 1, 'XTcm', 1); wn(mdl, 'XTa', 1, 'XTcm', 2); wn(mdl, 'XTcm', 1, 'XPcool', 1);
    add1(mdl, 'simulink/Discrete/Unit Delay', 'XTfdel', 'SampleTime', n2s(dt), 'InitialCondition', '25');   % run 에서 T0(고정이면 25)
    add1(mdl, 'simulink/Math Operations/Sum', 'XdT', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'XCdT', 'Gain', n2s(th.C));
    add1(mdl, 'simulink/Math Operations/Sum', 'XEexk', 'Inputs', '+-');
    add1(mdl, 'simulink/Discrete/Unit Delay', 'XAccD', 'SampleTime', n2s(dt), 'InitialCondition', '0');
    add1(mdl, 'simulink/Math Operations/Sum', 'XAccS', 'Inputs', '++');
    wn(mdl, 'XTfin', 1, 'XTfdel', 1);
    wn(mdl, 'XTfin', 1, 'XdT', 1); wn(mdl, 'XTfdel', 1, 'XdT', 2); wn(mdl, 'XdT', 1, 'XCdT', 1);
    wn(mdl, 'XdE', 1, 'XEexk', 1); wn(mdl, 'XCdT', 1, 'XEexk', 2);
    wn(mdl, 'XAccD', 1, 'XAccS', 1); wn(mdl, 'XEexk', 1, 'XAccS', 2); wn(mdl, 'XAccS', 1, 'XAccD', 1);
    add1(mdl, 'simulink/Math Operations/Sum', 'XPend', 'Inputs', '+-');                          % 아직 열 노드에 전달하지 않은 에너지
    wn(mdl, 'XEcu', 1, 'XPend', 1); wn(mdl, 'XEz', 1, 'XPend', 2);
    % --- 전기 입력·점성·기계 에너지 적분, 자기·운동 에너지 ---
    add1(mdl, 'simulink/Math Operations/Product', 'XPvd', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'XPvq', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XPvs', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Gain', 'XPin', 'Gain', '1.5');
    add1(mdl, 'simulink/Continuous/Integrator', 'XEin', 'InitialCondition', '0');
    wn(mdl, 'Pvds', 1, 'XPvd', 1); wn(mdl, 'Int_id', 1, 'XPvd', 2); wn(mdl, 'Pvqs', 1, 'XPvq', 1); wn(mdl, 'Int_iq', 1, 'XPvq', 2);
    wn(mdl, 'XPvd', 1, 'XPvs', 1); wn(mdl, 'XPvq', 1, 'XPvs', 2); wn(mdl, 'XPvs', 1, 'XPin', 1); wn(mdl, 'XPin', 1, 'XEin', 1);
    add1(mdl, 'simulink/Math Operations/Product', 'XQd2', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Gain', 'XPvis', 'Gain', n2s(p.damping));
    add1(mdl, 'simulink/Continuous/Integrator', 'XEvis', 'InitialCondition', '0');
    wn(mdl, 'PS2S_qd', 1, 'XQd2', 1); wn(mdl, 'PS2S_qd', 1, 'XQd2', 2); wn(mdl, 'XQd2', 1, 'XPvis', 1); wn(mdl, 'XPvis', 1, 'XEvis', 1);
    add1(mdl, 'simulink/Math Operations/Product', 'XPmech', 'Inputs', '2');                    % 관절 입력 토크 N*Te * qdot
    add1(mdl, 'simulink/Continuous/Integrator', 'XEmech', 'InitialCondition', '0');
    wn(mdl, 'GNt', 1, 'XPmech', 1); wn(mdl, 'PS2S_qd', 1, 'XPmech', 2); wn(mdl, 'XPmech', 1, 'XEmech', 1);
    add1(mdl, 'simulink/Math Operations/Gain', 'XU', 'Gain', n2s(0.75 * p.pmsm.L));             % U_mag = 3/4 L (id^2+iq^2)
    add1(mdl, 'simulink/Math Operations/Gain', 'XKe', 'Gain', n2s(0.5 * p.Jtotal));             % E_kin = 1/2 J_total qdot^2
    wn(mdl, 'XSs', 1, 'XU', 1); wn(mdl, 'XQd2', 1, 'XKe', 1);
    % --- 로그 (100 us, 전기 로그와 같은 행 수) ---
    add1(mdl, 'simulink/Signal Routing/Mux', 'XMux', 'Inputs', '12');
    add1(mdl, 'simulink/Sinks/To Workspace', 'XLog', 'VariableName', 'w6s44_xlog', 'SaveFormat', 'Timeseries', 'SampleTime', n2s(p.cur.Ts));
    src = {'XTfin', 'XR', 'XPcu', 'XPcool', 'XEin', 'XEcu', 'XAccS', 'XEvis', 'XEmech', 'XU', 'XKe', 'XPend'};
    for k = 1:12, wn(mdl, src{k}, 1, 'XMux', k); end
    wn(mdl, 'XMux', 1, 'XLog', 1);
    setm(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
    save_system(mdl, dst);
    close_system(mdl, 0);
    fprintf('[OK] 저장: %s\n', dst);
end

%% ================= 독립 열 시험 모델 (연속시간 ODE) =================
%  C dT/dt = P(t) - (T - Tamb)/Rth.  heat: P = 10 W (t<300), current: P = 1.5 R(T) iq^2 (iq = 2 A, t<300), cooling: P = 0, T0 = 80
function buildThermal(p, modelsDir, mdl, kind)
    fprintf('\n===== BUILD %s (%s) =====\n', mdl, kind);
    n2s = @(x) num2str(x, 16);
    th = p.th; tt = p.t44.thermal;
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl);
    T0 = th.Tamb; if strcmp(kind, 'cooling'), T0 = tt.T80; end
    add1(mdl, 'simulink/Continuous/Integrator', 'XIT', 'InitialCondition', n2s(T0));
    add1(mdl, 'simulink/Sources/Constant', 'XTa', 'Value', n2s(th.Tamb));
    add1(mdl, 'simulink/Math Operations/Sum', 'XTcm', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'XPcool', 'Gain', n2s(1 / th.Rth));
    add1(mdl, 'simulink/Math Operations/Sum', 'XNet', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'XGC', 'Gain', n2s(1 / th.C));
    wn(mdl, 'XIT', 1, 'XTcm', 1); wn(mdl, 'XTa', 1, 'XTcm', 2); wn(mdl, 'XTcm', 1, 'XPcool', 1);
    wn(mdl, 'XNet', 1, 'XGC', 1); wn(mdl, 'XGC', 1, 'XIT', 1); wn(mdl, 'XPcool', 1, 'XNet', 2);
    % 입력 전력
    switch kind
        case 'heat'
            add1(mdl, 'simulink/Sources/Step', 'XP', 'Time', n2s(tt.t_off), 'Before', n2s(tt.P_heat), 'After', '0');
            Pname = 'XP';
        case 'current'
            add1(mdl, 'simulink/Sources/Step', 'Xiq', 'Time', n2s(tt.t_off), 'Before', n2s(tt.iq), 'After', '0');
            add1(mdl, 'simulink/Math Operations/Product', 'Xiq2', 'Inputs', '2');
            add1(mdl, 'simulink/Math Operations/Gain', 'XRg', 'Gain', n2s(th.Rref * th.alpha));
            add1(mdl, 'simulink/Sources/Constant', 'XRc', 'Value', n2s(th.Rref * (1 - th.alpha * th.Tref)));
            add1(mdl, 'simulink/Math Operations/Sum', 'XR', 'Inputs', '++');
            add1(mdl, 'simulink/Math Operations/Product', 'XPr', 'Inputs', '2');
            add1(mdl, 'simulink/Math Operations/Gain', 'XP', 'Gain', '1.5');
            wn(mdl, 'Xiq', 1, 'Xiq2', 1); wn(mdl, 'Xiq', 1, 'Xiq2', 2);
            wn(mdl, 'XIT', 1, 'XRg', 1); wn(mdl, 'XRg', 1, 'XR', 1); wn(mdl, 'XRc', 1, 'XR', 2);
            wn(mdl, 'Xiq2', 1, 'XPr', 1); wn(mdl, 'XR', 1, 'XPr', 2); wn(mdl, 'XPr', 1, 'XP', 1);
            Pname = 'XP';
        case 'cooling'
            add1(mdl, 'simulink/Sources/Constant', 'XP', 'Value', '0');
            Pname = 'XP';
    end
    wn(mdl, Pname, 1, 'XNet', 1);
    add1(mdl, 'simulink/Continuous/Integrator', 'XEin', 'InitialCondition', '0');
    add1(mdl, 'simulink/Continuous/Integrator', 'XEexp', 'InitialCondition', '0');
    wn(mdl, Pname, 1, 'XEin', 1); wn(mdl, 'XPcool', 1, 'XEexp', 1);
    add1(mdl, 'simulink/Signal Routing/Mux', 'XMux', 'Inputs', '5');
    add1(mdl, 'simulink/Sinks/To Workspace', 'XLog', 'VariableName', 'w6s44_thlog', 'SaveFormat', 'Timeseries', 'SampleTime', n2s(tt.logdt));
    src = {'XIT', Pname, 'XPcool', 'XEin', 'XEexp'};
    for k = 1:5, wn(mdl, src{k}, 1, 'XMux', k); end
    wn(mdl, 'XMux', 1, 'XLog', 1);
    setm(mdl, 'Solver', 'ode45'); setm(mdl, 'StopTime', n2s(tt.t_end));
    setm(mdl, 'RelTol', '1e-10'); setm(mdl, 'AbsTol', '1e-12'); setm(mdl, 'MaxStep', '0.1');
    save_system(mdl, fullfile(modelsDir, [mdl '.slx']));
    close_system(mdl, 0);
    fprintf('[OK] 저장: %s\n', fullfile(modelsDir, [mdl '.slx']));
end

%% ================= 헬퍼 =================
function cutInport(mdl, blk, k)
    ph = get_param([mdl '/' blk], 'PortHandles');
    lh = get_param(ph.Inport(k), 'Line');
    if lh ~= -1
        delete_line(lh);
        fprintf('  [OK] %s 입력 %d 연결 제거\n', blk, k);
    else
        fprintf('  [경고] %s 입력 %d 에 연결이 없다\n', blk, k);
    end
end

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

function setb(mdl, blk, name, value)
    try
        set_param([mdl '/' blk], name, value);
    catch ME
        fprintf('  [실패] 블록 설정 %s.%s = %s : %s\n', blk, name, value, ME.message);
    end
end

function setm(mdl, name, value)
    try
        set_param(mdl, name, value);
    catch ME
        fprintf('  [실패] 모델 설정 %s = %s : %s\n', name, value, ME.message);
    end
end
