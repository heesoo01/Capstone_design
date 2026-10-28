function p = params()
%PARAMS 관절 액추에이터 체인 시뮬레이션 파라미터 (모두 가정값/placeholder)
%
%   하드웨어가 아직 미정이므로 아래 값은 전부 임시 가정값이다.
%   실제 데이터시트가 정해지면 이 파일만 교체하면 되도록,
%   숫자는 스크립트에 하드코딩하지 말고 이 함수를 통해서만 읽는다.
%
%   사용: p = params();  disp(p.motor.Kt)

p = struct();

%% 기계 (링크 + 관절)
p.mech.g          = 9.81;      % [m/s^2] 중력가속도
p.mech.link_len   = 0.30;      % [m] 링크 길이 (placeholder)
p.mech.link_mass  = 0.50;      % [kg] 링크 질량 (placeholder)
p.mech.end_mass_nominal = 0.00;  % [kg] No-Load 상태 말단 질량
p.mech.end_mass_loaded  = 0.20;  % [kg] Pick 이후 말단 질량 (placeholder, Phase2~3)
p.mech.joint_damping = 0.01;   % [N*m*s/rad] 관절 점성 마찰 계수 (placeholder)

%% 감속기 (기어)
p.gear.N       = 50;           % [-] 감속비 (placeholder)
p.gear.eta     = 0.85;         % [-] 기어 효율 (placeholder)
p.gear.backlash_deg = 0.5;     % [deg] 백래시 각도 (placeholder)

%% 모터 (PMSM, placeholder — 데이터시트 확정 전)
p.motor.Rs   = 0.5;    % [Ohm] 상저항 (placeholder)
p.motor.Ld   = 5e-3;   % [H] d축 인덕턴스 (placeholder)
p.motor.Lq   = 5e-3;   % [H] q축 인덕턴스 (placeholder)
p.motor.Kt   = 0.1;    % [N*m/A] 토크 상수 (placeholder)
p.motor.Ke   = 0.1;    % [V*s/rad] 역기전력 상수 (placeholder, Kt=Ke 가정 SI 단위)
p.motor.pole_pairs = 4; % [-] 극쌍수 (placeholder)
p.motor.J_rotor = 1e-5; % [kg*m^2] 로터 관성 (placeholder)
p.motor.B_rotor = 1e-6; % [N*m*s/rad] 로터 점성마찰 (placeholder)

%% 전원 / 인버터
p.elec.Vdc = 24;         % [V] DC 버스 전압 (placeholder)
p.elec.Ts_current = 1e-5; % [s] 전류 루프(PWM) 샘플 시간 (placeholder, 검토 대상: S4에서 확인)
p.elec.Ts_mech    = 1e-4; % [s] 기계 동역학 스텝 (placeholder, 검토 대상: S4에서 확인)
p.elec.current_limit = 5; % [A] 전류 제한 (placeholder)

%% 제어기 (PID, placeholder — 근거 확정 전)
p.ctrl.Kp = 10;   % placeholder
p.ctrl.Ki = 1;    % placeholder
p.ctrl.Kd = 0.1;  % placeholder

%% 궤적 (다중 각도, S5용)
p.traj.angles_deg = [0, 30, 60, 90]; % [deg] 목표각 리스트 (placeholder)
p.traj.step_time  = 2.0;             % [s] 스텝 간 대기 시간 (placeholder)

%% 시뮬레이션
p.sim.stop_time = 10; % [s] (placeholder, S1~S2는 더 짧게 오버라이드해서 사용 가능)

end
