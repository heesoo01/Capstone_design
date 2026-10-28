function p = w5cmp_params()
%W5CMP_PARAMS MuJoCo vs MATLAB 1DOF 이상 토크 비교 시험의 합의 조건 (2026-10-03)
%   첫 비교용 공통 조건이며 최종 프로젝트 사양이 아니다. 모든 값은 이 파일에서만 읽는다.

p.name = 'w5_mujoco_vs_matlab_1dof';

%% 링크: 균일 직육면체 0.4 x 0.05 x 0.05 m, 길이방향 = +X, 회전축 = Z
p.link.size = [0.4 0.05 0.05];      % [m] X(길이) Y Z
p.link.mass = 1;                    % [kg] 고정
p.link.com  = [0.2 0 0];            % [m] 관절 기준 무게중심
m = p.link.mass; a = p.link.size(1); b = p.link.size(2); c = p.link.size(3);
p.link.I_com = [m/12*(b^2+c^2), m/12*(a^2+c^2), m/12*(a^2+b^2)];  % [Ixx Iyy Izz] 무게중심 기준
p.link.Izz_com = p.link.I_com(3);                                  % 0.0135416667
p.link.J_joint = p.link.Izz_com + m*p.link.com(1)^2;               % 0.0535416667 (관절 기준)

%% 관절/기계
p.damping = 0.1;                    % [N*m*s/rad] 점성 감쇠, 관절 한 곳에서만 반영
p.gravity = 'None';                 % 중력 끔

%% 제어: tau[k] = Kp*(q_ref[k]-q[k]) - Kd*qdot[k]  (측정 속도 사용)
p.Kp = 4;
p.Kd = 1;
p.Ts = 1e-3;                        % [s] 제어 주기, 토크 유지(ZOH)
p.q_step = 0.3;                     % [rad]
p.k_step = 200;                     % 제어 샘플 k=200 (0.2 s)부터 목표 0.3
p.t_step = p.k_step * p.Ts;         % 0.2 s
p.t_step_model = p.t_step - p.Ts/2; % Step 블록 시각: k=199 샘플은 0, k=200 샘플은 0.3이 되도록 반 샘플 앞
p.t_end = 2;                        % [s]
p.log_dt = 1e-3;                    % CSV 기록 간격

%% 판정 기준
p.band = 0.006;                     % [rad] 정착 기준 (목표 0.3의 2%)
p.rmse_window = [0.2 2];            % [s]

%% 해석 설정 (MATLAB, 가변 스텝). MuJoCo의 100/50/25 us와 같은 의미의 간격 상한 3종
p.solver = 'ode23t';
p.reltol = '1e-6';
p.abstol = '1e-9';
p.maxsteps = [1e-4 5e-5 2.5e-5];
p.maxstep_tags = {'', '_dt50us', '_dt25us'};   % 첫 번째가 기준 CSV

%% 연속시간 PD 이론해 (참고용 기준 해)
cdamp = p.damping + p.Kd;
disc = cdamp^2 - 4*p.link.J_joint*p.Kp;
p.pole = [(-cdamp + sqrt(disc))/(2*p.link.J_joint), (-cdamp - sqrt(disc))/(2*p.link.J_joint)];
p.zeta = cdamp/(2*sqrt(p.link.J_joint*p.Kp));
end
