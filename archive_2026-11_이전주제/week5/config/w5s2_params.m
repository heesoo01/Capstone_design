function p = w5s2_params()
%W5S2_PARAMS 2단계(PMSM + 전류 PI + 평균 인버터) MuJoCo vs MATLAB 합의 조건 (문서 2단계 기준)
%   기계 조건은 1단계(w5cmp_params)를 그대로 쓴다: 기어비 1, 회전자 관성 0, 중력/접촉/건마찰 없음.
p = w5cmp_params();
p.name_alone = 'w5_stage2_pmsm_alone';    % 2-1 전기 모델 단독
p.name_joint = 'w5_stage2_pmsm_joint';    % 2-2, 2-3 통합

%% 표면부착형 PMSM (Ld = Lq)
p.pmsm.R   = 0.5;       % [ohm]
p.pmsm.L   = 0.005;     % [H] Ld = Lq
p.pmsm.psi = 0.05;      % [Wb]
p.pmsm.pp  = 4;         % 극쌍
p.pmsm.Kt  = 1.5 * p.pmsm.pp * p.pmsm.psi;   % 0.3 N*m/A

%% 전류 제어 (100 us)
p.cur.Ts     = 1e-4;
p.cur.Kp     = 1.5;     % [V/A]
p.cur.Ki     = 150;     % [V/(A*s)]
p.cur.Kaw    = 300;     % 안티윈드업 이득
p.cur.iq_lim = 2;       % [A]
p.cur.id_ref = 0;

%% 인버터(평균 전압 모델)
p.Vdc  = 24;            % [V] 기본
p.vmax = @(V) V / sqrt(3);

%% 시험 정의
p.t21_end = 0.1;                 % 2-1: 모터 속도 0 고정, vd=0, vq=1 V
p.t21_vd  = 0;  p.t21_vq = 1;
p.t22_target = 0.3;              % 2-2: 24 V, 0.2 s에 0.3 rad
p.t23_target = 2;                % 2-3: 목표 2 rad, 24 V 와 2 V
p.t23_volts  = [24 2];

%% 해석 간격 상한 (MuJoCo 물리·전기 적분 간격 25 -> 12.5 -> 6.25 us 와 같은 의미)
p.s2.maxsteps = [2.5e-5 1.25e-5 6.25e-6];
p.s2.tags     = {'_dt25us', '_dt12p5us', '_dt6p25us'};
end
