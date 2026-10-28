function p = w6s44_params()
%W6S44_PARAMS 4-4 (권선 열 모델) MATLAB/Simulink 쪽 시험 조건
%   근거: 이민혁 README_stage4_4.txt 와 summary.json (week6/이민혁/stage4/stage4/stage4_4_*).
%   기계·전기·제어 값은 5주차 3-2 (w5s3_params: 기어비 5, 회전자 관성 1e-4 -> 관절 환산 0.0025)를 그대로 쓴다.
%   열 파라미터는 모두 가정값이며 실제 모터 데이터·온도 측정으로 보정하지 않았다 (민혁 README §3).
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', '..', 'week5', 'config'));
p = w5s3_params();
p.stage  = p.s3.stages(2);                    % 3-2: Jred = N^2*Jm = 0.0025 를 관절 축 관성에 한 번만 가산
p.Jtotal = p.link.J_joint + p.stage.Jred;     % 기대 0.0560416667

%% 열 모델 (README §3). 세 상 권선을 동일 온도 열 노드 하나로 묶음
p.th.Tref  = 25;          % [C]
p.th.Tamb  = 25;          % [C]
p.th.alpha = 0.00393;     % [1/K] R(T) = R_ref [1 + alpha (T - T_ref)]
p.th.Rref  = p.pmsm.R;    % 0.5 ohm (상당 저항)
p.th.C     = 20;          % [J/K]
p.th.Rth   = 10;          % [K/W]
p.th.tau   = p.th.C * p.th.Rth;   % 200 s
p.th.dt_upd = 1e-3;       % 열 업데이트 주기 (README §3: 그 사이 R 과 온도 유지, 누적 동손 전달) -- 방식 A (사용자 위임 2026-10-11)

%% 독립 열 시험 (README §2). 이상적 열원/전류를 지정한 열 노드 시험 (제어기·관절 없음)
p.t44.thermal = struct('t_end', 600, 't_off', 300, 'P_heat', 10, 'iq', 2, 'T80', 80, 'logdt', 0.1);

%% 통합 2 s (README §2). Vdc 는 Cvmax 로, 목표는 Ref_Step 으로 반영
%  기록 행 k=200 부터 목표이므로 Step 은 반 샘플 앞 (4-3 과 같은 처리)
p.t44.cases = struct( ...
    'name',   {'baseline_fixed25', 'baseline_thermal25', 'baseline_thermal80', 'stress_thermal25', 'stress_thermal80'}, ...
    'T0',     {25, 25, 80, 25, 80}, ...
    'thermal',{0, 1, 1, 1, 1}, ...
    'Vdc',    {24, 24, 24, 4, 4}, ...
    'target', {0.3, 0.3, 0.3, 2, 2});
p.t44.t_end = 2;
p.t44.t_step_model = 0.2 - p.Ts/2;
p.t44.maxstep = 5e-6;

p.t44.models = struct('joint', 'w6_stage4_4_joint', 'heat', 'w6_stage4_4_thermal_heat', ...
    'current', 'w6_stage4_4_thermal_current', 'cooling', 'w6_stage4_4_thermal_cooling');

%% 민혁 summary.json 과 값이 맞는지 확인 (다르면 경고만 출력)
chk = {'R', p.pmsm.R, 0.5; 'L', p.pmsm.L, 0.005; 'psi', p.pmsm.psi, 0.05; 'pp', p.pmsm.pp, 4; 'N', p.gear.N, 5; ...
       'Jtotal', p.Jtotal, 0.05604166666666668; 'damping', p.damping, 0.1; 'Kp', p.Kp, 4; 'Kd', p.Kd, 1; ...
       'Kpi', p.cur.Kp, 1.5; 'Kii', p.cur.Ki, 150; 'Kaw', p.cur.Kaw, 300; 'iq_lim', p.cur.iq_lim, 2; ...
       'Ts_cur', p.cur.Ts, 1e-4; 'Ts_pos', p.Ts, 1e-3; 'vmax24', p.vmax(24), 13.85640646055102; 'vmax4', p.vmax(4), 2.3094010767585034; ...
       'alpha', p.th.alpha, 0.00393; 'C', p.th.C, 20; 'Rth', p.th.Rth, 10; 'tau', p.th.tau, 200};
for k = 1:size(chk, 1)
    if abs(chk{k, 2} - chk{k, 3}) > 1e-9 * max(1, abs(chk{k, 3}))
        warning('w6s44_params: %s = %.10g 이(가) 민혁 summary.json 값 %.10g 과 다름', chk{k, 1}, chk{k, 2}, chk{k, 3});
    end
end
end
