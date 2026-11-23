function p = w6s43_params()
%W6S43_PARAMS 4-3 (이상적 3상 2레벨 PWM 인버터) MATLAB/Simulink 쪽 시험 조건
%   근거: 이민혁 README_stage4_3.txt 와 summary.json (week6/이민혁/stage4/stage4/stage4_3_*).
%   기계·전기·제어 값은 5주차 3-2 (w5s3_params: 기어비 5, 회전자 관성 1e-4 -> 관절 환산 0.0025)를 그대로 쓴다.
%   모든 값은 가정값이며 하드웨어 사양이 아니다.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', '..', 'week5', 'config'));
p = w5s3_params();
p.stage  = p.s3.stages(2);                    % 3-2: Jred = N^2*Jm = 0.0025 를 관절 축 관성에 한 번만 가산
p.Jtotal = p.link.J_joint + p.stage.Jred;     % 기대 0.0560416667 (민혁 J_TOTAL)

%% PWM (README 4-3 §4): 중심 정렬 삼각 캐리어 c = |2t/T - 1| (주기 시작이 최대, c=1), 상단 S_k = (duty_k > c)
p.pwm.Vdc = 24;
p.pwm.f   = 1e4;   p.pwm.T = 1 / p.pwm.f;      % 10 kHz (= 전류 제어 주기 100 us)
p.pwm.f2  = 2e4;                               % 고정 회전자 시험 20 kHz

%% 시험 정의 (README 4-3 §8)
% (d) 통합: 0.2 s에 0.3 rad, 2 s. 기록 행 k=200 부터 목표 0.3 이므로 Step 블록은 반 샘플(0.5 ms) 앞.
p.t43.main    = struct('t_end', 2,    'target', 0.3, 't_step_model', 0.2 - p.Ts/2, 'maxstep', 5e-6);
% (e) 시작 60 ms: 5 ms 에 0.3 rad, 최대 적분 간격 5 / 2.5 / 1.25 us
p.t43.startup = struct('t_end', 0.06, 'target', 0.3, 't_step_model', 0.005 - p.Ts/2, 'maxsteps', [5e-6 2.5e-6 1.25e-6], 'tags', {{'_dt5us', '_dt2p5us', '_dt1p25us'}});
% (c) 회전축 고정: vd=0, vq=1 V, 0.1 s, 초기 전류 0
p.t43.held    = struct('t_end', 0.1,  'vd', 0, 'vq', 1, 'maxstep', 5e-6);

p.t43.models = struct('pwm', 'w6_stage4_3_pwm', 'avg', 'w6_stage4_3_avg', ...
    'held_pwm10k', 'w6_stage4_3_held_pwm10k', 'held_pwm20k', 'w6_stage4_3_held_pwm20k', 'held_avg', 'w6_stage4_3_held_avg');

%% 민혁 summary.json 과 값이 맞는지 확인 (다르면 경고만 출력)
chk = {'R', p.pmsm.R, 0.5; 'L', p.pmsm.L, 0.005; 'psi', p.pmsm.psi, 0.05; 'pp', p.pmsm.pp, 4; 'N', p.gear.N, 5; ...
       'Jtotal', p.Jtotal, 0.05604166666666668; 'damping', p.damping, 0.1; 'Kp', p.Kp, 4; 'Kd', p.Kd, 1; ...
       'Vdc', p.pwm.Vdc, 24; 'Kpi', p.cur.Kp, 1.5; 'Kii', p.cur.Ki, 150; 'Kaw', p.cur.Kaw, 300; 'iq_lim', p.cur.iq_lim, 2; ...
       'Ts_cur', p.cur.Ts, 1e-4; 'Ts_pos', p.Ts, 1e-3; 'vmax', p.vmax(p.pwm.Vdc), 13.85640646055102};
for k = 1:size(chk, 1)
    if abs(chk{k, 2} - chk{k, 3}) > 1e-9 * max(1, abs(chk{k, 3}))
        warning('w6s43_params: %s = %.10g 이(가) 민혁 summary.json 값 %.10g 과 다름', chk{k, 1}, chk{k, 2}, chk{k, 3});
    end
end
end
