%% W6S43_BUILD
% 4-3 (이상적 3상 2레벨 PWM 인버터) 모델을 만든다.
%   w6_stage4_3_pwm / w6_stage4_3_avg : 5주차 검증 모델 w5_stage3_2_joint.slx 를 복사해 'dq 평균 전압 -> PMSM 플랜트' 연결만 교체
%       교체 내용(민혁 README 4-3 §4~§5 와 같은 정의):
%         제어기 dq 전압(주기 시작 샘플, 100 us 유지) -> 주기 시작 전기각으로 역 Park -> alpha-beta (주기 동안 고정)
%         -> 역 Clarke(abc) -> min-max 공통모드 u0 -> duty_k = 0.5 + (v_k + u0)/Vdc
%         pwm : S_k = (duty_k > 캐리어 c(t)), 상전압 v_k = Vdc*(S_k - mean(S))  (Y결선, 중성선 없음, 데드타임 0)
%         avg : 상전압 = 한 PWM 주기 평균 전압 = 지령 abc 그대로 (평균 인버터)
%         -> 순간 전기각(= pp*N*관절각)으로 alpha-beta -> dq 변환 -> PMSM dq 플랜트(연속시간)
%   w6_stage4_3_held_pwm10k / _pwm20k / _avg : 회전축 고정(wm=0, 전기각 0), vd=0, vq=1 V 전기 시험용 (기계 없음)
% 주의: 이 스크립트는 MATLAB 을 실행하지 않고 작성했다. [실패] 또는 [경고] 로그가 나오면 그대로 알려줄 것.
% 실행: cd week6\scripts 후  w6s43_build

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s43_params();
modelsDir = fullfile(here, '..', 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
srcMdl = fullfile(here, '..', '..', 'week5', 'models', 'w5_stage3_2_joint.slx');
if ~isfile(srcMdl), error('5주차 모델이 없다: %s', srcMdl); end
M = p.t43.models;

buildJoint(p, srcMdl, modelsDir, M.pwm, 'pwm');
buildJoint(p, srcMdl, modelsDir, M.avg, 'avg');
buildHeld(p, modelsDir, M.held_pwm10k, 'pwm', 1 / p.pwm.f);
buildHeld(p, modelsDir, M.held_pwm20k, 'pwm', 1 / p.pwm.f2);
buildHeld(p, modelsDir, M.held_avg,    'avg', 1 / p.pwm.f);
fprintf('\n===== W6S43 BUILD 끝. [실패]/[경고] 가 있었는지 확인 =====\n');

%% ================= 통합 모델 (5주차 3-2 복사 후 인버터 교체) =================
function buildJoint(p, srcMdl, modelsDir, mdl, mode)
    fprintf('\n===== BUILD %s (%s) =====\n', mdl, mode);
    dst = fullfile(modelsDir, [mdl '.slx']);
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    copyfile(srcMdl, dst);
    fileattrib(dst, '+w');
    load_system(dst);
    % 기존 dq 평균 전압 -> 플랜트 연결(Pvds->GvdL, Pvqs->GvqL)만 끊는다. 다른 곳으로 가는 분기(안티윈드업, 로그)는 유지.
    cutInport(mdl, 'GvdL', 1);
    cutInport(mdl, 'GvqL', 1);
    add1(mdl, 'simulink/Math Operations/Gain', 'XGth', 'Gain', num2str(p.pmsm.pp * p.gear.N, 12));   % 전기각 = pp*N*관절각 (= 20*q)
    wn(mdl, 'PS2S_q', 1, 'XGth', 1);
    pwmStage(mdl, p, mode, 'Pvds', 'Pvqs', 'XGth', 'XGth', p.pwm.T, p.cur.Ts);
    wn(mdl, 'XVd_i', 1, 'GvdL', 1);
    wn(mdl, 'XVq_i', 1, 'GvqL', 1);
    extraLogs(mdl, p, false);
    setm(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
    save_system(mdl, dst);
    close_system(mdl, 0);
    fprintf('[OK] 저장: %s\n', dst);
end

%% ================= 고정 회전자 전기 시험 모델 =================
function buildHeld(p, modelsDir, mdl, mode, Tpwm)
    fprintf('\n===== BUILD %s (%s, PWM 주기 %g s) =====\n', mdl, mode, Tpwm);
    n2s = @(x) num2str(x, 12);
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl);
    add1(mdl, 'simulink/Sources/Constant', 'XCvd', 'Value', n2s(p.t43.held.vd));
    add1(mdl, 'simulink/Sources/Constant', 'XCvq', 'Value', n2s(p.t43.held.vq));
    add1(mdl, 'simulink/Sources/Constant', 'XCth', 'Value', '0');      % 회전자 고정: 전기각 0
    add1(mdl, 'simulink/Sources/Constant', 'XCwm', 'Value', '0');      % 회전자 고정: 모터 속도 0
    pwmStage(mdl, p, mode, 'XCvd', 'XCvq', 'XCth', 'XCth', Tpwm, Tpwm);
    plant(mdl, p, 'XVd_i', 'XVq_i', 'XCwm');
    extraLogs(mdl, p, true);
    setm(mdl, 'Solver', p.solver); setm(mdl, 'StopTime', n2s(p.t43.held.t_end));
    setm(mdl, 'RelTol', p.reltol); setm(mdl, 'AbsTol', p.abstol);
    setm(mdl, 'MaxStep', n2s(p.t43.held.maxstep));
    save_system(mdl, fullfile(modelsDir, [mdl '.slx']));
    close_system(mdl, 0);
    fprintf('[OK] 저장: %s\n', fullfile(modelsDir, [mdl '.slx']));
end

%% ================= PWM 단: dq 지령(주기 샘플) -> 상전압 -> 순간 dq 전압 =================
function pwmStage(mdl, p, mode, vdSrc, vqSrc, thSrc, thInst, Tpwm, Tzoh)
    n2s = @(x) num2str(x, 12);
    Vdc = p.pwm.Vdc;
    ph = {'a', 'b', 'c'};
    % --- 주기 시작 전기각 샘플 -> 역 Park: alpha = vd cos - vq sin, beta = vd sin + vq cos ---
    add1(mdl, 'simulink/Discrete/Zero-Order Hold', 'XZOHth', 'SampleTime', n2s(Tzoh));
    add1(mdl, 'simulink/Math Operations/Trigonometric Function', 'XCs', 'Operator', 'cos');
    add1(mdl, 'simulink/Math Operations/Trigonometric Function', 'XSn', 'Operator', 'sin');
    wn(mdl, thSrc, 1, 'XZOHth', 1); wn(mdl, 'XZOHth', 1, 'XCs', 1); wn(mdl, 'XZOHth', 1, 'XSn', 1);
    add1(mdl, 'simulink/Math Operations/Product', 'XPa1', 'Inputs', '2');   % vd*cos
    add1(mdl, 'simulink/Math Operations/Product', 'XPa2', 'Inputs', '2');   % vq*sin
    add1(mdl, 'simulink/Math Operations/Sum', 'XAl', 'Inputs', '+-');       % alpha
    add1(mdl, 'simulink/Math Operations/Product', 'XPb1', 'Inputs', '2');   % vd*sin
    add1(mdl, 'simulink/Math Operations/Product', 'XPb2', 'Inputs', '2');   % vq*cos
    add1(mdl, 'simulink/Math Operations/Sum', 'XBe', 'Inputs', '++');       % beta
    wn(mdl, vdSrc, 1, 'XPa1', 1); wn(mdl, 'XCs', 1, 'XPa1', 2);
    wn(mdl, vqSrc, 1, 'XPa2', 1); wn(mdl, 'XSn', 1, 'XPa2', 2);
    wn(mdl, 'XPa1', 1, 'XAl', 1); wn(mdl, 'XPa2', 1, 'XAl', 2);
    wn(mdl, vdSrc, 1, 'XPb1', 1); wn(mdl, 'XSn', 1, 'XPb1', 2);
    wn(mdl, vqSrc, 1, 'XPb2', 1); wn(mdl, 'XCs', 1, 'XPb2', 2);
    wn(mdl, 'XPb1', 1, 'XBe', 1); wn(mdl, 'XPb2', 1, 'XBe', 2);
    % --- 역 Clarke: a = alpha, b = -alpha/2 + sqrt(3)/2 beta, c = -alpha/2 - sqrt(3)/2 beta ---
    add1(mdl, 'simulink/Math Operations/Gain', 'XGh', 'Gain', '-0.5');
    add1(mdl, 'simulink/Math Operations/Gain', 'XGs', 'Gain', n2s(sqrt(3) / 2));
    add1(mdl, 'simulink/Math Operations/Sum', 'XCb', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Sum', 'XCc', 'Inputs', '+-');
    wn(mdl, 'XAl', 1, 'XGh', 1); wn(mdl, 'XBe', 1, 'XGs', 1);
    wn(mdl, 'XGh', 1, 'XCb', 1); wn(mdl, 'XGs', 1, 'XCb', 2);
    wn(mdl, 'XGh', 1, 'XCc', 1); wn(mdl, 'XGs', 1, 'XCc', 2);
    cmd = {'XAl', 'XCb', 'XCc'};
    % --- min-max 공통모드 u0 = -(max+min)/2, duty_k = 0.5 + (v_k + u0)/Vdc ---
    add1(mdl, 'simulink/Math Operations/MinMax', 'XMx', 'Function', 'max', 'Inputs', '3');
    add1(mdl, 'simulink/Math Operations/MinMax', 'XMn', 'Function', 'min', 'Inputs', '3');
    add1(mdl, 'simulink/Math Operations/Sum', 'XU0s', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Gain', 'XU0', 'Gain', '-0.5');
    for k = 1:3
        wn(mdl, cmd{k}, 1, 'XMx', k); wn(mdl, cmd{k}, 1, 'XMn', k);
    end
    wn(mdl, 'XMx', 1, 'XU0s', 1); wn(mdl, 'XMn', 1, 'XU0s', 2); wn(mdl, 'XU0s', 1, 'XU0', 1);
    add1(mdl, 'simulink/Sources/Constant', 'XC05', 'Value', '0.5');
    for k = 1:3
        add1(mdl, 'simulink/Math Operations/Sum', ['XDs_' ph{k}], 'Inputs', '++');
        add1(mdl, 'simulink/Math Operations/Gain', ['XDg_' ph{k}], 'Gain', n2s(1 / Vdc));
        add1(mdl, 'simulink/Math Operations/Sum', ['XDut_' ph{k}], 'Inputs', '++');
        wn(mdl, cmd{k}, 1, ['XDs_' ph{k}], 1); wn(mdl, 'XU0', 1, ['XDs_' ph{k}], 2);
        wn(mdl, ['XDs_' ph{k}], 1, ['XDg_' ph{k}], 1);
        wn(mdl, ['XDg_' ph{k}], 1, ['XDut_' ph{k}], 1); wn(mdl, 'XC05', 1, ['XDut_' ph{k}], 2);
    end
    % --- 상전압 ---
    if strcmp(mode, 'pwm')
        % 캐리어 c = |2 (t mod T)/T - 1|, S_k = duty_k > c, v_k = Vdc (S_k - mean S)
        Ts_ = n2s(Tpwm);
        add1(mdl, 'simulink/Sources/Clock', 'XClk');
        add1(mdl, 'simulink/User-Defined Functions/Fcn', 'XCar', 'Expr', sprintf('abs(2*(u-%s*floor(u/%s))/%s-1)', Ts_, Ts_, Ts_));
        wn(mdl, 'XClk', 1, 'XCar', 1);
        add1(mdl, 'simulink/Math Operations/Sum', 'XSS', 'Inputs', '+++');
        add1(mdl, 'simulink/Math Operations/Gain', 'XGm', 'Gain', n2s(1 / 3));
        for k = 1:3
            add1(mdl, 'simulink/Logic and Bit Operations/Relational Operator', ['XRg_' ph{k}], 'Operator', '>');
            add1(mdl, 'simulink/Signal Attributes/Data Type Conversion', ['XSg_' ph{k}], 'OutDataTypeStr', 'double');
            add1(mdl, 'simulink/Math Operations/Sum', ['XDf_' ph{k}], 'Inputs', '+-');
            add1(mdl, 'simulink/Math Operations/Gain', ['XV' ph{k}], 'Gain', n2s(Vdc));
            wn(mdl, ['XDut_' ph{k}], 1, ['XRg_' ph{k}], 1); wn(mdl, 'XCar', 1, ['XRg_' ph{k}], 2);
            wn(mdl, ['XRg_' ph{k}], 1, ['XSg_' ph{k}], 1);
            wn(mdl, ['XSg_' ph{k}], 1, 'XSS', k);
        end
        wn(mdl, 'XSS', 1, 'XGm', 1);
        for k = 1:3
            wn(mdl, ['XSg_' ph{k}], 1, ['XDf_' ph{k}], 1); wn(mdl, 'XGm', 1, ['XDf_' ph{k}], 2);
            wn(mdl, ['XDf_' ph{k}], 1, ['XV' ph{k}], 1);
        end
    else
        % 평균 인버터: 한 PWM 주기의 평균 상전압 = 지령 abc
        for k = 1:3
            add1(mdl, 'simulink/Math Operations/Gain', ['XV' ph{k}], 'Gain', '1');
            wn(mdl, cmd{k}, 1, ['XV' ph{k}], 1);
        end
    end
    % --- alpha-beta (Y결선, 중성선 없음): alpha = va, beta = (vb - vc)/sqrt(3) ---
    add1(mdl, 'simulink/Math Operations/Sum', 'XBc', 'Inputs', '+-');
    add1(mdl, 'simulink/Math Operations/Gain', 'XBi', 'Gain', n2s(1 / sqrt(3)));
    wn(mdl, 'XVb', 1, 'XBc', 1); wn(mdl, 'XVc', 1, 'XBc', 2); wn(mdl, 'XBc', 1, 'XBi', 1);
    % --- 순간 전기각으로 dq: vd = alpha cos + beta sin, vq = -alpha sin + beta cos ---
    add1(mdl, 'simulink/Math Operations/Trigonometric Function', 'XCi', 'Operator', 'cos');
    add1(mdl, 'simulink/Math Operations/Trigonometric Function', 'XSi', 'Operator', 'sin');
    wn(mdl, thInst, 1, 'XCi', 1); wn(mdl, thInst, 1, 'XSi', 1);
    add1(mdl, 'simulink/Math Operations/Product', 'XPd1', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'XPd2', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XVd_i', 'Inputs', '++');
    add1(mdl, 'simulink/Math Operations/Product', 'XPq1', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Product', 'XPq2', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XVq_i', 'Inputs', '-+');
    wn(mdl, 'XVa', 1, 'XPd1', 1); wn(mdl, 'XCi', 1, 'XPd1', 2);
    wn(mdl, 'XBi', 1, 'XPd2', 1); wn(mdl, 'XSi', 1, 'XPd2', 2);
    wn(mdl, 'XPd1', 1, 'XVd_i', 1); wn(mdl, 'XPd2', 1, 'XVd_i', 2);
    wn(mdl, 'XVa', 1, 'XPq1', 1); wn(mdl, 'XSi', 1, 'XPq1', 2);
    wn(mdl, 'XBi', 1, 'XPq2', 1); wn(mdl, 'XCi', 1, 'XPq2', 2);
    wn(mdl, 'XPq1', 1, 'XVq_i', 1); wn(mdl, 'XPq2', 1, 'XVq_i', 2);
end

%% ================= 추가 로그 =================
%  XLog  (Ts 간격)            : duty_a duty_b duty_c, int(id) int(iq), int(va) int(vb) int(vc)  -> 주기 평균 전류·전압 계산용
%  ILog  (솔버 스텝마다, 통합) : id iq                                                          -> 주기 내 iq 최대-최소(스위칭 시각 포함)
%  HLog  (솔버 스텝마다, 고정) : id iq v_alpha v_beta va vb vc
function extraLogs(mdl, p, held)
    n2s = @(x) num2str(x, 12);
    Ts = n2s(p.cur.Ts);
    add1(mdl, 'simulink/Continuous/Integrator', 'XIid', 'InitialCondition', '0');
    add1(mdl, 'simulink/Continuous/Integrator', 'XIiq', 'InitialCondition', '0');
    add1(mdl, 'simulink/Continuous/Integrator', 'XIva', 'InitialCondition', '0');
    add1(mdl, 'simulink/Continuous/Integrator', 'XIvb', 'InitialCondition', '0');
    add1(mdl, 'simulink/Continuous/Integrator', 'XIvc', 'InitialCondition', '0');
    wn(mdl, 'Int_id', 1, 'XIid', 1); wn(mdl, 'Int_iq', 1, 'XIiq', 1);
    wn(mdl, 'XVa', 1, 'XIva', 1); wn(mdl, 'XVb', 1, 'XIvb', 1); wn(mdl, 'XVc', 1, 'XIvc', 1);
    add1(mdl, 'simulink/Signal Routing/Mux', 'XMux', 'Inputs', '8');
    add1(mdl, 'simulink/Sinks/To Workspace', 'XLog', 'VariableName', 'w6s43_xlog', 'SaveFormat', 'Timeseries', 'SampleTime', Ts);
    src = {'XDut_a', 'XDut_b', 'XDut_c', 'XIid', 'XIiq', 'XIva', 'XIvb', 'XIvc'};
    for k = 1:8, wn(mdl, src{k}, 1, 'XMux', k); end
    wn(mdl, 'XMux', 1, 'XLog', 1);
    if ~held
        add1(mdl, 'simulink/Signal Routing/Mux', 'XIMux', 'Inputs', '2');
        add1(mdl, 'simulink/Sinks/To Workspace', 'XILog', 'VariableName', 'w6s43_ilog', 'SaveFormat', 'Timeseries', 'SampleTime', '-1');
        wn(mdl, 'Int_id', 1, 'XIMux', 1); wn(mdl, 'Int_iq', 1, 'XIMux', 2); wn(mdl, 'XIMux', 1, 'XILog', 1);
    else
        add1(mdl, 'simulink/Signal Routing/Mux', 'XHMux', 'Inputs', '7');
        add1(mdl, 'simulink/Sinks/To Workspace', 'XHLog', 'VariableName', 'w6s43_hlog', 'SaveFormat', 'Timeseries', 'SampleTime', '-1');
        hs = {'Int_id', 'Int_iq', 'XVa', 'XBi', 'XVa', 'XVb', 'XVc'};
        for k = 1:7, wn(mdl, hs{k}, 1, 'XHMux', k); end
        wn(mdl, 'XHMux', 1, 'XHLog', 1);
    end
end

%% ================= PMSM dq 플랜트 (5주차 w5s3_build 와 동일) =================
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
    add1(mdl, 'simulink/Math Operations/Gain', 'Gtau', 'Gain', n2s(Kt));
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

function setm(mdl, name, value)
    try
        set_param(mdl, name, value);
    catch ME
        fprintf('  [실패] 모델 설정 %s = %s : %s\n', name, value, ME.message);
    end
end
