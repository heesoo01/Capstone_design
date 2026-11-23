function p = w6s42_params()
%W6S42_PARAMS 4-2 (기어 백래시) MATLAB/Simulink 쪽 시험 조건
%   근거: 이민혁 README_stage4_2.txt 와 summary.json (week6/이민혁/stage4/stage4/stage4_2_*).
%   기계·전기·제어 값은 5주차 3-2 (w5s3_params)를 그대로 쓴다. 유격 폭 ±0.5도는 민혁이 정한 가정값.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', '..', 'week5', 'config'));
p = w5s3_params();
p.stage  = p.s3.stages(2);
p.Jtotal = p.link.J_joint + p.stage.Jred;
p.Jload  = p.link.J_joint;                      % 0.0535417 (링크, 관절축 기준)
p.Jref   = p.stage.Jred;                        % 0.0025 (구동축 환산 회전자 관성, 구동 쪽에만)
p.Jred_eff = p.Jref * p.Jload / (p.Jref + p.Jload);   % 두 관성의 환산 질량 (접촉 감쇠 임계값 추정용)

%% 백래시 (README §3, §6). 두 회전 관절 직렬: q_drive(구동, 회전자 관성 + 토크 입력), q_gap(유격 관절, 한계로 접촉 표현)
%  부하 각도 q_load = q_drive + q_gap, 모터 속도 = N * q_drive_dot, 점성 B 는 부하 절대 속도에 적용(구동축 감쇠 아님)
p.t42.half = struct('rigid', NaN, 'near_zero_gap', 1e-6, 'backlash', 0.5 * pi / 180);   % 반폭 [rad]
%  접촉 모델: Simscape Multibody 관절 한계(스프링-댐퍼, 전환 영역). MuJoCo solref/solimp 와 1:1 변환 불가 -> 값 목록으로 민감도 확인(사용자 승인 2026-10-11)
%  강성 1e6 N*m/rad: 블록 기본 1e4 가 아니라 Hard Stop 블록 기본값과 민혁 gap_probe(피크 4.14 N*m / 최대 침투 4.2e-6 rad)의 거친 환산과 같은 자릿수
p.t42.K  = [1e5 1e6 1e7];                       % [N*m/rad]
p.t42.Dcrit = 2 * sqrt(p.t42.K * p.Jred_eff);   % 임계 감쇠 근사 2*sqrt(K*J_red) [N*m*s/rad]  (추정)
p.t42.D0 = 0.01;                                % [N*m*s/rad] Rotational Hard Stop 블록 기본값
p.t42.trans = 1e-7;                             % [rad] 전환 영역 폭 (가정: 유격 1e-6 rad 보다 작게)
p.t42.sw = struct('tag', {'K1e5', 'K1e6', 'K1e7'});

%% 시험 (README §8). 모든 케이스는 id=iq=q_drive=q_gap=속도=0 에서 시작. 0.2 s 전환은 반 샘플 앞에 둔다
t0 = 0.2 - p.Ts / 2;
p.t42.sc = struct( ...
    'name',  {'baseline_step', 'reversal_steps', 'slow_reversal'}, ...
    't_end', {2, 4.2, 4.2}, ...
    'stepA', {0.3, 0.12, 0}, ...                 % 0.2 s: 0 -> stepA
    'tB',    {0, 1.5 - p.Ts / 2, 0}, 'stepB', {0, -0.24, 0}, ...   % 1.5 s: +0.12 -> -0.12
    'tC',    {0, 2.8 - p.Ts / 2, 0}, 'stepC', {0, 0.24, 0}, ...    % 2.8 s: -0.12 -> +0.12
    'sinA',  {0, 0, 0.08});
p.t42.t0 = t0;
p.t42.sin_w = 2 * pi / 4;
p.t42.sin_phase = -p.t42.sin_w * 0.2;
p.t42.maxstep = 5e-6;
p.t42.models = struct('joint', 'w6_stage4_2_joint', 'rigid', 'w6_stage4_2_rigid');

%% 민혁 summary.json 과 값이 맞는지 확인 (다르면 경고만 출력)
chk = {'R', p.pmsm.R, 0.5; 'L', p.pmsm.L, 0.005; 'psi', p.pmsm.psi, 0.05; 'pp', p.pmsm.pp, 4; 'N', p.gear.N, 5; ...
       'Jload', p.Jload, 0.053541666666666675; 'Jref', p.Jref, 0.0025; 'damping', p.damping, 0.1; 'Kp', p.Kp, 4; 'Kd', p.Kd, 1; ...
       'Kpi', p.cur.Kp, 1.5; 'Kii', p.cur.Ki, 150; 'Kaw', p.cur.Kaw, 300; 'iq_lim', p.cur.iq_lim, 2; ...
       'Ts_cur', p.cur.Ts, 1e-4; 'Ts_pos', p.Ts, 1e-3; 'vmax24', p.vmax(24), 13.85640646055102};
for k = 1:size(chk, 1)
    if abs(chk{k, 2} - chk{k, 3}) > 1e-9 * max(1, abs(chk{k, 3}))
        warning('w6s42_params: %s = %.10g 이(가) 민혁 summary.json 값 %.10g 과 다름', chk{k, 1}, chk{k, 2}, chk{k, 3});
    end
end
end
