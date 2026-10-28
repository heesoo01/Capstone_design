%% W5CMP_RUN
% w5_mujoco_vs_matlab_1dof 를 해석 간격 상한 3종(100/50/25 us)으로 돌려 CSV와 합의된 지표를 만든다.
% CSV 열: t, q_ref, q, qdot, tau  (2001행, 1 ms 간격, 단위 rad, rad/s, N*m)
%   tau = 그 시각 t에 계산해서 다음 1 ms 동안 유지한 토크
%
% *** 아직 실행 전 -- 먼저 w5cmp_build 가 [실패] 없이 끝나야 한다. ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 w5cmp_run

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w5cmp_params();
mdl = p.name;
resDir = fullfile(here, '..', 'results');
if ~exist(resDir, 'dir'), mkdir(resDir); end

if ~bdIsLoaded(mdl)
    load_system(fullfile(here, '..', 'models', [mdl '.slx']));
end

fprintf('===== W5CMP RUN =====\n');
fprintf('이론(연속시간 PD): 극점 %.2f / %.2f, 감쇠비 %.3f, 초기 토크 %.2f N*m, 초기 가속도 %.2f rad/s^2\n\n', ...
    p.pole(1), p.pole(2), p.zeta, p.Kp*p.q_step, p.Kp*p.q_step/p.link.J_joint);

nRun = numel(p.maxsteps);
res = cell(1, nRun);
base = fullfile(resDir, [p.name '_matlab']);
settingsFile = [base '_settings.txt'];
fid = fopen(settingsFile, 'w');
fprintf(fid, 'MATLAB %s | Simulink solver=%s RelTol=%s AbsTol=%s | Ts=%g s | log_dt=%g s\n', ...
    version, p.solver, p.reltol, p.abstol, p.Ts, p.log_dt);

for r = 1:nRun
    set_param(mdl, 'MaxStep', num2str(p.maxsteps(r)));
    fprintf('--- 실행 %d/%d: MaxStep = %g s ---\n', r, nRun, p.maxsteps(r));
    try
        simOut = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    catch ME
        fprintf('[실패] 시뮬레이션: %s\n', ME.message);
        disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
        fclose(fid);
        return;
    end
    ts = simOut.get('w5cmp_log');
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= 4 && size(D, 1) == 4, D = D.'; end
    q_ref = D(:,1); q = D(:,2); qd = D(:,3); tau = D(:,4);

    fprintf('  행 수 %d (기대 2001), t 간격 최소/최대 %.6f/%.6f\n', numel(t), min(diff(t)), max(diff(t)));
    T = table(t, q_ref, q, qd, tau, tau, 'VariableNames', ...
        {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','actual_torque_Nm'});
    csvPath = [base p.maxstep_tags{r} '.csv'];
    writetable(T, csvPath);
    fprintf('  [OK] CSV: %s\n', csvPath);

    m = metrics(t, q_ref, q, qd, tau, p);
    res{r} = struct('t', t, 'q', q, 'm', m);
    fprintf('  tau(0.200s) = %.6f N*m (기대 1.2) | q(0.201s) = %.3e rad (부호: +토크 -> +각도면 양수)\n', m.tau_first, m.q_after);
    fprintf('  최대 각도 %.6f rad | 오버슈트 %.4f %% | 최대 속도 %.6f rad/s\n', m.qmax, m.overshoot, m.qdmax);
    fprintf('  정착시간(±%.3f rad, 0.2 s부터) = %.3f s (시뮬레이션 시각 %.3f s)\n', p.band, m.ts, m.ts + p.t_step);
    fprintf('  RMSE(q-q_ref, 0.2~2 s) = %.6f rad | RMSE(q-연속시간 이론해) = %.6f rad\n\n', m.rmse_ref, m.rmse_theory);
    fprintf(fid, 'run %d: MaxStep=%g | tau(0.2)=%.6f | qmax=%.6f | overshoot=%.4f%% | qdmax=%.6f | ts=%.3f | RMSE_ref=%.6f | RMSE_theory=%.6f\n', ...
        r, p.maxsteps(r), m.tau_first, m.qmax, m.overshoot, m.qdmax, m.ts, m.rmse_ref, m.rmse_theory);
end

fprintf('--- 해석 간격 수렴 (기준 100us 대비) ---\n');
for r = 2:nRun
    dq = max(abs(res{r}.q - res{1}.q));
    fprintf('  MaxStep %g vs %g : 최대 |Δq| = %.3e rad\n', p.maxsteps(r), p.maxsteps(1), dq);
    fprintf(fid, 'convergence: MaxStep %g vs %g max|dq|=%.3e rad\n', p.maxsteps(r), p.maxsteps(1), dq);
end
fclose(fid);
fprintf('\n[OK] 설정 기록: %s\n', settingsFile);
fprintf('\n===== RUN 끝. 위 출력 전체를 붙여넣어 달라. CSV는 week5\\results 에 있다. =====\n');

%% ---- 로컬 함수 ----
function m = metrics(t, q_ref, q, qd, tau, p)
    [~, ik] = min(abs(t - p.t_step));
    m.tau_first = tau(ik);
    [~, ia] = min(abs(t - (p.t_step + p.Ts)));
    m.q_after = q(ia);
    w = t >= p.rmse_window(1) - 1e-9 & t <= p.rmse_window(2) + 1e-9;
    m.qmax = max(q);
    m.overshoot = max(0, (max(q) - p.q_step) / p.q_step * 100);
    m.qdmax = max(abs(qd));
    m.rmse_ref = sqrt(mean((q(w) - q_ref(w)).^2));
    s1 = p.pole(1); s2 = p.pole(2);
    tt = max(t - p.t_step, 0);
    q_th = p.q_step * (1 - (s2*exp(s1*tt) - s1*exp(s2*tt)) / (s2 - s1));
    q_th(t < p.t_step) = 0;
    m.rmse_theory = sqrt(mean((q(w) - q_th(w)).^2));
    after = find(t >= p.t_step - 1e-9);
    err = abs(q(after) - p.q_step);
    last = find(err > p.band, 1, 'last');
    if isempty(last)
        m.ts = 0;
    elseif last == numel(after)
        m.ts = NaN;
    else
        m.ts = t(after(last + 1)) - p.t_step;
    end
end
