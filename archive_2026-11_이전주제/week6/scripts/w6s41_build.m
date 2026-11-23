%% W6S41_BUILD
% 4-1 (관절 건마찰) 모델을 만든다: 5주차 검증 모델 w5_stage3_2_joint.slx 를 복사해 필요한 부분만 바꾼다.
%   (1) 관절 마찰: 관절 속도(PS2S_qd)를 Simscape 회로의 이상 속도원에 강제하고, Rotational Friction 블록(Coulomb=Breakaway=0.05 N*m,
%       점성 0)이 내는 토크를 이상 토크 센서로 읽어 관절 입력 토크(기어 후)에 더한다. 블록의 마찰 법칙을 그대로 쓰며 관절 축에 한 번만 적용한다.
%       ※ 블록 마찰은 속도만의 함수라 정지 시 0 이다. 민혁 frictionloss(제약, 정지 시에도 한계까지 버팀)와 정의가 다르다.
%   (2) 지령: Ref_Step 외에 두 번째 계단(XStepB)과 사인(XSine, 0.2 s 부터)을 더해 4개 시험 지령을 모두 만든다. 값은 w6s41_run 이 설정.
%   (3) 마찰 on/off(XFen), 마찰 토크 로그(w6s41_flog: 마찰 토크, 관절 속도).
% 주의: [실패] 또는 [경고] 로그가 나오면 그대로 알려줄 것.
% 실행: cd week6\scripts 후  w6s41_build

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s41_params();
modelsDir = fullfile(here, '..', 'models');
if ~exist(modelsDir, 'dir'), mkdir(modelsDir); end
srcMdl = fullfile(here, '..', '..', 'week5', 'models', 'w5_stage3_2_joint.slx');
if ~isfile(srcMdl), error('5주차 모델이 없다: %s', srcMdl); end
mdl = p.t41.model;
n2s = @(x) num2str(x, 16);
fprintf('\n===== BUILD %s =====\n', mdl);
dst = fullfile(modelsDir, [mdl '.slx']);
if bdIsLoaded(mdl), close_system(mdl, 0); end
copyfile(srcMdl, dst);
fileattrib(dst, '+w');
load_system(dst);

% --- (2) 지령 ---
cutInport(mdl, 'ZOH_ref', 1);
add1(mdl, 'simulink/Sources/Step', 'XStepB', 'Time', '10', 'Before', '0', 'After', '0');
add1(mdl, 'simulink/Sources/Sine Wave', 'XSine', 'Amplitude', '0', 'Frequency', n2s(p.t41.sin_w), 'Phase', n2s(p.t41.sin_phase), 'Bias', '0');
add1(mdl, 'simulink/Sources/Step', 'XEnS', 'Time', n2s(p.t41.t0), 'Before', '0', 'After', '1');
add1(mdl, 'simulink/Math Operations/Product', 'XPs', 'Inputs', '2');
add1(mdl, 'simulink/Math Operations/Sum', 'XRsum', 'Inputs', '+++');
wn(mdl, 'XSine', 1, 'XPs', 1); wn(mdl, 'XEnS', 1, 'XPs', 2);
wn(mdl, 'Ref_Step', 1, 'XRsum', 1); wn(mdl, 'XStepB', 1, 'XRsum', 2); wn(mdl, 'XPs', 1, 'XRsum', 3);
wn(mdl, 'XRsum', 1, 'ZOH_ref', 1);

% --- (1) 마찰 회로 ---
add1(mdl, 'nesl_utility/Solver Configuration', 'XSC');
add1(mdl, 'fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference', 'XREF1');
add1(mdl, 'fl_lib/Mechanical/Rotational Elements/Mechanical Rotational Reference', 'XREF2');
add1(mdl, 'fl_lib/Mechanical/Mechanical Sources/Ideal Angular Velocity Source', 'XWS');
add1(mdl, 'fl_lib/Mechanical/Rotational Elements/Rotational Friction', 'XRF', 'brkwy_trq', n2s(p.t41.fric), 'Col_trq', n2s(p.t41.fric), ...
    'visc_coef', '0', 'brkwy_vel', n2s(p.t41.vb(end)));
add1(mdl, 'fl_lib/Mechanical/Mechanical Sensors/Ideal Torque Sensor', 'XTS');
add1(mdl, 'nesl_utility/Simulink-PS Converter', 'XS2PSw');
add1(mdl, 'nesl_utility/PS-Simulink Converter', 'XPS2Stf');
setb(mdl, 'XS2PSw', 'Unit', 'rad/s'); setb(mdl, 'XPS2Stf', 'Unit', 'N*m');
P = @(n) get_param([mdl '/' n], 'PortHandles');
wpp(mdl, P('XS2PSw').RConn(1), P('XWS').RConn(1), 'S2PSw -> 속도원 S');
wpp(mdl, P('XWS').LConn(1), P('XREF1').LConn(1), '속도원 -> REF1');
wpp(mdl, P('XSC').RConn(1), P('XWS').LConn(1), 'Solver -> 속도원 노드');
wpp(mdl, P('XWS').RConn(2), P('XTS').LConn(1), '속도원 -> 토크센서');
wpp(mdl, P('XTS').RConn(1), P('XRF').LConn(1), '토크센서 -> 마찰');
wpp(mdl, P('XRF').RConn(1), P('XREF2').LConn(1), '마찰 -> REF2');
wpp(mdl, P('XTS').RConn(2), P('XPS2Stf').LConn(1), '토크센서 T -> PS2S');
wn(mdl, 'PS2S_qd', 1, 'XS2PSw', 1);
% 센서 값은 속도 > 0 에서 음수 (probe 로 확인): 마찰 토크 그대로 관절 입력에 더한다
add1(mdl, 'simulink/Sources/Constant', 'XFen', 'Value', '1');
add1(mdl, 'simulink/Math Operations/Product', 'XPf', 'Inputs', '2');
add1(mdl, 'simulink/Math Operations/Sum', 'XSf', 'Inputs', '++');
wn(mdl, 'XPS2Stf', 1, 'XPf', 1); wn(mdl, 'XFen', 1, 'XPf', 2);
cutInport(mdl, 'S2PS_tau', 1);
wn(mdl, 'GNt', 1, 'XSf', 1); wn(mdl, 'XPf', 1, 'XSf', 2); wn(mdl, 'XSf', 1, 'S2PS_tau', 1);

% --- (3) 로그 ---
add1(mdl, 'simulink/Signal Routing/Mux', 'XMux', 'Inputs', '2');
add1(mdl, 'simulink/Sinks/To Workspace', 'XLog', 'VariableName', 'w6s41_flog', 'SaveFormat', 'Timeseries', 'SampleTime', n2s(p.cur.Ts));
wn(mdl, 'XPf', 1, 'XMux', 1); wn(mdl, 'PS2S_qd', 1, 'XMux', 2); wn(mdl, 'XMux', 1, 'XLog', 1);
setm(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
save_system(mdl, dst);
close_system(mdl, 0);
fprintf('[OK] 저장: %s\n', dst);
fprintf('\n===== W6S41 BUILD 끝. [실패]/[경고] 가 있었는지 확인 =====\n');

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
