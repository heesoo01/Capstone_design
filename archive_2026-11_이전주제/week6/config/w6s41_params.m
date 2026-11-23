function p = w6s41_params()
%W6S41_PARAMS 4-1 (관절 건마찰) MATLAB/Simulink 쪽 시험 조건
%   근거: 이민혁 README_stage4_1.txt 와 summary.json (week6/이민혁/stage4/stage4/stage4_1_*).
%   기계·전기·제어 값은 5주차 3-2 (w5s3_params)를 그대로 쓴다. 건마찰 0.05 N*m 는 민혁이 정한 영향 관찰용 가정값이다.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', '..', 'week5', 'config'));
p = w5s3_params();
p.stage  = p.s3.stages(2);
p.Jtotal = p.link.J_joint + p.stage.Jred;

%% 건마찰: Simscape Rotational Friction 블록 (Coulomb = Breakaway = 0.05 N*m, 점성 0: 점성 b=0.1 은 관절 블록에 이미 있음)
%  블록은 속도만의 함수라 정지 시 마찰이 0 이다. MuJoCo frictionloss 는 제약이라 정지 시에도 한계까지 버틴다 (정의가 다르다).
%  블록의 '속도 임계값' 파라미터(brkwy_vel)는 민혁 모델에 대응이 없어 3개 값으로 민감도를 본다 (사용자 승인 2026-10-11).
p.t41.fric = 0.05;
p.t41.vb   = [1e-3 1e-2 1e-1];                 % [rad/s]. 1e-1 이 블록 기본값
p.t41.vbtag = {'vb0p001', 'vb0p01', 'vb0p1'};

%% 시험 (README §3). 모든 케이스는 id=iq=q=qdot=0 에서 시작. 0.2 s 전환은 반 샘플(0.5 ms) 앞에 둔다(4-3 과 같은 처리)
t0 = 0.2 - p.Ts / 2;
p.t41.sc = struct( ...
    'name',  {'baseline_step', 'small_step', 'slow_reversal', 'hold_restart'}, ...
    't_end', {2, 3, 4.2, 5.2}, ...
    'stepA', {0.3, 0.01, 0, 0.12}, ...          % 0.2 s 에서 0 -> stepA
    'tB',    {0, 0, 0, 2.8 - p.Ts / 2}, ...     % hold_restart: 2.8 s 에 -0.24 (합계 -0.12)
    'stepB', {0, 0, 0, -0.24}, ...
    'sinA',  {0, 0, 0.08, 0});                  % slow_reversal: 0.2 s 부터 0.08*sin(2*pi*(t-0.2)/4)
p.t41.t0 = t0;
p.t41.sin_w = 2 * pi / 4;
p.t41.sin_phase = -p.t41.sin_w * 0.2;
p.t41.maxstep = 5e-6;
p.t41.conv_maxstep = 2.5e-6;                   % slow_reversal, vb=0.01 에서 MATLAB 간격 수렴 확인용
p.t41.model = 'w6_stage4_1_joint';

%% 민혁 summary.json 과 값이 맞는지 확인 (다르면 경고만 출력)
chk = {'R', p.pmsm.R, 0.5; 'L', p.pmsm.L, 0.005; 'psi', p.pmsm.psi, 0.05; 'pp', p.pmsm.pp, 4; 'N', p.gear.N, 5; ...
       'Jtotal', p.Jtotal, 0.05604166666666668; 'damping', p.damping, 0.1; 'Kp', p.Kp, 4; 'Kd', p.Kd, 1; ...
       'Kpi', p.cur.Kp, 1.5; 'Kii', p.cur.Ki, 150; 'Kaw', p.cur.Kaw, 300; 'iq_lim', p.cur.iq_lim, 2; ...
       'Ts_cur', p.cur.Ts, 1e-4; 'Ts_pos', p.Ts, 1e-3; 'vmax24', p.vmax(24), 13.85640646055102};
for k = 1:size(chk, 1)
    if abs(chk{k, 2} - chk{k, 3}) > 1e-9 * max(1, abs(chk{k, 3}))
        warning('w6s41_params: %s = %.10g 이(가) 민혁 summary.json 값 %.10g 과 다름', chk{k, 1}, chk{k, 2}, chk{k, 3});
    end
end
end
