%% W6S42_BUILD
% 4-2 (기어 백래시) 모델을 만든다: 5주차 검증 모델 w5_stage3_2_joint.slx 를 복사해 필요한 부분만 바꾼다.
%   w6_stage4_2_joint : 기계부를 민혁 4-2 와 같은 구조로 바꾼다 (두 회전 관절 직렬, MuJoCo 공식 백래시 레시피에 대응)
%       World --[구동 관절 q_drive: 토크 입력 N*Te, 감쇠 0]-- RotorInertia(0.0025, 회전자 관성은 여기에만)
%             --[유격 관절 q_gap: 위치 한계 +-half (스프링-댐퍼 접촉), 감쇠 0]-- LinkInertia(링크만, 3-2 의 Jred 가산 제거)
%       점성 B=0.1 은 부하 절대 속도(qd_drive+qd_gap)에 대해 링크에 외부 토크로 가함 (구동축 감쇠 아님)
%       위치 PD 는 부하 각도·속도(q_drive+q_gap, qd_drive+qd_gap), PMSM 역기전력은 모터 속도 N*qd_drive 를 쓴다
%       부하 전달 토크 = 유격 관절 위/아래 한계 토크 합 (로그 w6s42_glog)
%       ※ MuJoCo soft limit(solref/solimp)과 Simscape Multibody 관절 한계(강성·감쇠·전환 폭)는 정의가 달라 1:1 변환할 수 없다.
%   w6_stage4_2_rigid : 5주차 3-2 그대로 (rigid_reference). 지령만 4-2 시험 3종을 만들 수 있게 확장.
% 주의: [실패] 또는 [경고] 로그가 나오면 그대로 알려줄 것.
% 실행: cd week6\scripts 후  w6s42_build

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s42_params();
modelsDir = fullfile(here, '..', 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
srcMdl = fullfile(here, '..', '..', 'week5', 'models', 'w5_stage3_2_joint.slx');
if ~isfile(srcMdl), error('5주차 모델이 없다: %s', srcMdl); end
n2s = @(x) num2str(x, 16);

%% ---------- rigid (지령만 확장) ----------
mdl = p.t42.models.rigid;
fprintf('\n===== BUILD %s =====\n', mdl);
dst = fullfile(modelsDir, [mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl, 0); end
copyfile(srcMdl, dst); fileattrib(dst, '+w'); load_system(dst);
reference(mdl, p);
setm(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
save_system(mdl, dst); close_system(mdl, 0);
fprintf('[OK] 저장: %s\n', dst);

%% ---------- 백래시 모델 ----------
mdl = p.t42.models.joint;
fprintf('\n===== BUILD %s =====\n', mdl);
dst = fullfile(modelsDir, [mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl, 0); end
copyfile(srcMdl, dst); fileattrib(dst, '+w'); load_system(dst);
reference(mdl, p);
P = @(n) get_param([mdl '/' n], 'PortHandles');

% (1) 구동 관절: 감쇠 0, 링크는 유격 관절 뒤로 옮긴다
setb(mdl, 'RevoluteJoint', 'DampingCoefficient', '0');
ph = P('RevoluteJoint');
lh = get_param(ph.RConn(1), 'Line');
if lh ~= -1, delete_line(lh); fprintf('  [OK] RevoluteJoint.F -> LinkInertia 연결 제거\n'); else, fprintf('  [경고] RevoluteJoint.F 에 연결이 없다\n'); end
setb(mdl, 'LinkInertia', 'MomentsOfInertia', mat2str(p.link.I_com, 12));          % 3-2 의 Jred 가산을 제거
add1(mdl, 'sm_lib/Body Elements/Inertia', 'RotorInertia', 'InertiaType', 'Custom', 'Mass', '1e-9', 'CenterOfMass', '[0 0 0]', ...
    'MomentsOfInertia', mat2str([p.Jref p.Jref p.Jref], 12), 'ProductsOfInertia', '[0 0 0]');
add1(mdl, 'sm_lib/Joints/Revolute Joint', 'GapJoint', 'TorqueActuationMode', 'NoTorque', 'SensePosition', 'on', 'SenseVelocity', 'on', ...
    'SenseLowerLimitTorqueForce', 'on', 'SenseUpperLimitTorqueForce', 'on', 'LowerLimitSpecify', 'on', 'UpperLimitSpecify', 'on');
for nm = {'LowerLimitBound', 'UpperLimitBound', 'LowerLimitTransitionRegionWidth', 'UpperLimitTransitionRegionWidth'}
    setb(mdl, 'GapJoint', [nm{1} 'Units'], 'rad');
end
for nm = {'LowerLimitStiffness', 'UpperLimitStiffness'}, setb(mdl, 'GapJoint', [nm{1} 'Units'], 'N*m/rad'); end
for nm = {'LowerLimitDamping', 'UpperLimitDamping'}, setb(mdl, 'GapJoint', [nm{1} 'Units'], 'N*m/(rad/s)'); end
setb(mdl, 'GapJoint', 'LowerLimitBound', n2s(-p.t42.half.backlash)); setb(mdl, 'GapJoint', 'UpperLimitBound', n2s(p.t42.half.backlash));
setb(mdl, 'GapJoint', 'LowerLimitStiffness', n2s(p.t42.K(2))); setb(mdl, 'GapJoint', 'UpperLimitStiffness', n2s(p.t42.K(2)));
setb(mdl, 'GapJoint', 'LowerLimitDamping', n2s(p.t42.Dcrit(2))); setb(mdl, 'GapJoint', 'UpperLimitDamping', n2s(p.t42.Dcrit(2)));
setb(mdl, 'GapJoint', 'LowerLimitTransitionRegionWidth', n2s(p.t42.trans)); setb(mdl, 'GapJoint', 'UpperLimitTransitionRegionWidth', n2s(p.t42.trans));
setb(mdl, 'GapJoint', 'SpringStiffness', '0'); setb(mdl, 'GapJoint', 'DampingCoefficient', '0');
pj = P('RevoluteJoint'); pr = P('RotorInertia'); pg = P('GapJoint'); pl = P('LinkInertia');
fprintf('  GapJoint 포트: LConn %d개, RConn %d개\n', numel(pg.LConn), numel(pg.RConn));
wpp(mdl, pj.RConn(1), pr.RConn(1), 'Joint.F -> RotorInertia');
wpp(mdl, pj.RConn(1), pg.LConn(1), 'Joint.F -> GapJoint.B');
wpp(mdl, pg.RConn(1), pl.RConn(1), 'GapJoint.F -> LinkInertia');

% (2) 점성 B: 링크에 외부 토크 -B*(qd_drive+qd_gap)
add1(mdl, 'sm_lib/Forces and Torques/External Force and Torque', 'XDamp', 'EnableTorqueZ', 'on');
add1(mdl, 'nesl_utility/Simulink-PS Converter', 'XS2PSdamp');
setb(mdl, 'XS2PSdamp', 'Unit', 'N*m');
pd = P('XDamp'); ps = P('XS2PSdamp');
fprintf('  XDamp 포트: LConn %d개, RConn %d개\n', numel(pd.LConn), numel(pd.RConn));
wpp(mdl, pd.RConn(1), pl.RConn(1), 'XDamp frame -> LinkInertia');
if ~isempty(pd.LConn), wpp(mdl, ps.RConn(1), pd.LConn(1), 'S2PSdamp -> XDamp torque'); else, wpp(mdl, ps.RConn(1), pd.RConn(2), 'S2PSdamp -> XDamp torque'); end
add1(mdl, 'simulink/Math Operations/Gain', 'XGB', 'Gain', n2s(-p.damping));
wn(mdl, 'XGB', 1, 'XS2PSdamp', 1);

% (3) 유격 관절 센서 -> Simulink 신호
names = {'XPS2S_q2', 'rad'; 'XPS2S_qd2', 'rad/s'; 'XPS2S_tl', 'N*m'; 'XPS2S_tu', 'N*m'};
for k = 1:4
    add1(mdl, 'nesl_utility/PS-Simulink Converter', names{k, 1});
    setb(mdl, names{k, 1}, 'Unit', names{k, 2});
    pp_ = P(names{k, 1});
    wpp(mdl, pg.RConn(1 + k), pp_.LConn(1), ['GapJoint.RConn' num2str(1 + k) ' -> ' names{k, 1}]);
end

% (4) 부하 각도·속도 합성, PS2S_q/qd 소비처를 부하 값으로 바꾼다 (모터 속도 GwmN 은 구동 속도 그대로)
add1(mdl, 'simulink/Math Operations/Sum', 'XQL', 'Inputs', '++');
add1(mdl, 'simulink/Math Operations/Sum', 'XQDL', 'Inputs', '++');
rewire(mdl, 'PS2S_q', @(dstBlk) 'XQL');
rewire(mdl, 'PS2S_qd', @(dstBlk) ifelse(strcmp(dstBlk, 'GwmN'), 'PS2S_qd', 'XQDL'));
wn(mdl, 'PS2S_q', 1, 'XQL', 1); wn(mdl, 'XPS2S_q2', 1, 'XQL', 2);
wn(mdl, 'PS2S_qd', 1, 'XQDL', 1); wn(mdl, 'XPS2S_qd2', 1, 'XQDL', 2);
wn(mdl, 'XQDL', 1, 'XGB', 1);

% (5) 로그: q_drive q_gap qd_drive qd_gap tau_lower tau_upper (100 us)
add1(mdl, 'simulink/Signal Routing/Mux', 'XMux', 'Inputs', '6');
add1(mdl, 'simulink/Sinks/To Workspace', 'XLog', 'VariableName', 'w6s42_glog', 'SaveFormat', 'Timeseries', 'SampleTime', n2s(p.cur.Ts));
src = {'PS2S_q', 'XPS2S_q2', 'PS2S_qd', 'XPS2S_qd2', 'XPS2S_tl', 'XPS2S_tu'};
for k = 1:6, wn(mdl, src{k}, 1, 'XMux', k); end
wn(mdl, 'XMux', 1, 'XLog', 1);
setm(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
try
    set_param(mdl, 'SimulationCommand', 'update');
    fprintf('  [OK] 다이어그램 업데이트(컴파일) 성공\n');
catch ME
    fprintf('  [실패] 다이어그램 업데이트: %s\n', ME.message);
end
save_system(mdl, dst); close_system(mdl, 0);
fprintf('[OK] 저장: %s\n', dst);
fprintf('\n===== W6S42 BUILD 끝. [실패]/[경고] 가 있었는지 확인 =====\n');

%% ================= 지령 (Ref_Step + 계단 2개 + 사인) =================
function reference(mdl, p)
    n2s = @(x) num2str(x, 16);
    cutInport(mdl, 'ZOH_ref', 1);
    add1(mdl, 'simulink/Sources/Step', 'XStepB', 'Time', '1e9', 'Before', '0', 'After', '0');
    add1(mdl, 'simulink/Sources/Step', 'XStepC', 'Time', '1e9', 'Before', '0', 'After', '0');
    add1(mdl, 'simulink/Sources/Sine Wave', 'XSine', 'Amplitude', '0', 'Frequency', n2s(p.t42.sin_w), 'Phase', n2s(p.t42.sin_phase), 'Bias', '0');
    add1(mdl, 'simulink/Sources/Step', 'XEnS', 'Time', n2s(p.t42.t0), 'Before', '0', 'After', '1');
    add1(mdl, 'simulink/Math Operations/Product', 'XPs', 'Inputs', '2');
    add1(mdl, 'simulink/Math Operations/Sum', 'XRsum', 'Inputs', '++++');
    wn(mdl, 'XSine', 1, 'XPs', 1); wn(mdl, 'XEnS', 1, 'XPs', 2);
    wn(mdl, 'Ref_Step', 1, 'XRsum', 1); wn(mdl, 'XStepB', 1, 'XRsum', 2); wn(mdl, 'XStepC', 1, 'XRsum', 3); wn(mdl, 'XPs', 1, 'XRsum', 4);
    wn(mdl, 'XRsum', 1, 'ZOH_ref', 1);
end

%% ================= 헬퍼 =================
function rewire(mdl, srcName, pickFn)
    ph = get_param([mdl '/' srcName], 'PortHandles');
    lh = get_param(ph.Outport(1), 'Line');
    dsts = get_param(lh, 'DstPortHandle');
    dsts = dsts(dsts > 0);
    info = cell(numel(dsts), 2);
    for k = 1:numel(dsts)
        parent = get_param(dsts(k), 'Parent');
        info{k, 1} = strrep(parent, [mdl '/'], '');
        info{k, 2} = get_param(dsts(k), 'PortNumber');
    end
    delete_line(lh);
    for k = 1:size(info, 1)
        newSrc = pickFn(info{k, 1});
        fprintf('  재연결: %s -> %s:%d  (원래 %s)\n', newSrc, info{k, 1}, info{k, 2}, srcName);
        wn(mdl, newSrc, 1, info{k, 1}, info{k, 2});
    end
end

function r = ifelse(c, a, b)
    if c, r = a; else, r = b; end
end

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

function wpp(mdl, h1, h2, label)
    try
        add_line(mdl, h1, h2);
    catch ME
        fprintf('  [실패] 물리 연결 %s : %s\n', label, ME.message);
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
