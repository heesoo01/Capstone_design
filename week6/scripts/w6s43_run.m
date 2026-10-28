function w6s43_run(which)
%W6S43_RUN 4-3 (3상 2레벨 PWM) MATLAB/Simulink 시험 실행 -> week6\matlab_results\stage4_3\*.csv
%   w6s43_run('startup') : 시작 60 ms, PWM 최대 적분 간격 5 / 2.5 / 1.25 us + 평균 인버터 5 us  (가장 빠름, 먼저 실행)
%   w6s43_run('held')    : 회전축 고정 vq=1 V 0.1 s, PWM 10 kHz / 20 kHz / 평균
%   w6s43_run('main')    : 통합 2 s (0.3 rad), PWM 과 평균, 최대 적분 간격 5 us  (가장 오래 걸림)
%   w6s43_run('all')     : 위 세 개 순서대로
% 비교는 python w6s43_compare.py 가 한다 (같은 폴더).
% 주의: MATLAB 을 실행하지 않고 작성한 스크립트다. 오류나 [실패] 로그는 그대로 알려줄 것.
if nargin < 1, which = 'startup'; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s43_params();
mdlDir = fullfile(here, '..', 'models');
outDir = fullfile(here, '..', 'matlab_results', 'stage4_3');
if ~exist(outDir, 'dir'), mkdir(outDir); end
fid = fopen(fullfile(outDir, 'matlab_settings.txt'), 'a');
fprintf(fid, '\n==== %s w6s43_run(''%s'') MATLAB %s | Simulink 가변 스텝 solver=%s RelTol=%s AbsTol=%s ====\n', ...
    datestr(now, 'yyyy-mm-dd HH:MM:SS'), which, version, p.solver, p.reltol, p.abstol);
fprintf(fid, '인버터: 이상적 3상 2레벨, PWM %g Hz 중심 정렬 삼각 캐리어, min-max 공통모드, 데드타임 0, Vdc %g V. 전기 PMSM: 5주차 3-2와 동일(기어비 %g, 관절 환산 회전자 관성 %g 한 번만 가산).\n', ...
    p.pwm.f, p.pwm.Vdc, p.gear.N, p.stage.Jred);
fprintf(fid, '정의: 전류 PI 가 주기 시작(%g s) 샘플로 dq 전압 계산 -> 주기 시작 전기각으로 alpha-beta 고정 -> PWM(또는 평균) -> 순간 전기각으로 dq 변환.\n', p.cur.Ts);
cl = onCleanup(@() fclose(fid));
fprintf('===== W6S43 RUN (%s) =====\n', which);
if any(strcmp(which, {'startup', 'all'})), doStartup(p, mdlDir, outDir, fid); end
if any(strcmp(which, {'held', 'all'})),    doHeld(p, mdlDir, outDir, fid);    end
if any(strcmp(which, {'main', 'all'})),    doMain(p, mdlDir, outDir, fid);    end
fprintf('\n===== W6S43 RUN 끝 (%s). 결과: %s =====\n', which, outDir);
end

%% ---------------- (e) 시작 60 ms ----------------
function doStartup(p, mdlDir, outDir, fid)
    cfg = p.t43.startup;
    for k = 1:numel(cfg.maxsteps)
        runJoint(p, mdlDir, outDir, fid, p.t43.models.pwm, cfg, cfg.maxsteps(k), ['startup_pwm' cfg.tags{k}]);
    end
    runJoint(p, mdlDir, outDir, fid, p.t43.models.avg, cfg, cfg.maxsteps(1), ['startup_avg' cfg.tags{1}]);
end

%% ---------------- (d) 통합 2 s ----------------
function doMain(p, mdlDir, outDir, fid)
    cfg = p.t43.main;
    runJoint(p, mdlDir, outDir, fid, p.t43.models.avg, cfg, cfg.maxstep, 'main_avg');
    runJoint(p, mdlDir, outDir, fid, p.t43.models.pwm, cfg, cfg.maxstep, 'main_pwm');
end

%% ---------------- (c) 회전축 고정 ----------------
function doHeld(p, mdlDir, outDir, fid)
    tags = {'held_pwm10k', 'held_pwm20k', 'held_avg'};
    Tper = [1 / p.pwm.f, 1 / p.pwm.f2, 1 / p.pwm.f];
    te = p.t43.held.t_end;
    for k = 1:numel(tags)
        mdl = p.t43.models.(tags{k});
        fprintf('\n##### %s (%s) : vd=%g, vq=%g V, %g s, MaxStep %g #####\n', tags{k}, mdl, p.t43.held.vd, p.t43.held.vq, te, p.t43.held.maxstep);
        load_system(fullfile(mdlDir, [mdl '.slx']));
        set_param(mdl, 'StopTime', num2str(te, 12));
        set_param(mdl, 'MaxStep', num2str(p.t43.held.maxstep, 12));
        tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
        [t, H] = getlog(so, 'w6s43_hlog', 7);
        [tx, X] = getlog(so, 'w6s43_xlog', 8);
        writetable(table(t, H(:,1), H(:,2), H(:,3), H(:,4), H(:,5), H(:,6), H(:,7), 'VariableNames', ...
            {'time_s','id_A','iq_A','v_alpha_V','v_beta_V','va_V','vb_V','vc_V'}), fullfile(outDir, [tags{k} '.csv']));
        writetable(table(tx, X(:,1), X(:,2), X(:,3), X(:,4), X(:,5), X(:,6), X(:,7), X(:,8), 'VariableNames', ...
            {'time_s','duty_a','duty_b','duty_c','int_id_As','int_iq_As','int_va_Vs','int_vb_Vs','int_vc_Vs'}), fullfile(outDir, [tags{k} '_xlog.csv']));
        iq = H(:,2);
        w10 = t >= te - 0.01;
        m10 = trapz(t(w10), iq(w10)) / (t(end) - t(find(w10, 1)));
        wl = t >= te - Tper(k) - 1e-12;
        pp = max(iq(wl)) - min(iq(wl));
        fprintf('  %.1f s, 로그 %d 행 | 마지막 10 ms 평균 iq = %.8f A | 마지막 PWM 주기 iq 최대-최소 = %.6g A\n', el, numel(t), m10, pp);
        fprintf(fid, '%s MaxStep %g: rows=%d mean_iq_last10ms=%.8f iq_pp_last_period=%.6g wall=%.1fs\n', tags{k}, p.t43.held.maxstep, numel(t), m10, pp, el);
        close_system(mdl, 0);
    end
end

%% ---------------- 통합 모델 1회 실행 + CSV ----------------
function runJoint(p, mdlDir, outDir, fid, mdl, cfg, maxstep, name)
    fprintf('\n##### %s (%s) : t_end %g s, 목표 %g rad, MaxStep %g #####\n', name, mdl, cfg.t_end, cfg.target, maxstep);
    load_system(fullfile(mdlDir, [mdl '.slx']));
    set_param([mdl '/Ref_Step'], 'Time', num2str(cfg.t_step_model, 12), 'After', num2str(cfg.target, 12));
    set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(p.pwm.Vdc), 12));
    set_param(mdl, 'StopTime', num2str(cfg.t_end, 12));
    set_param(mdl, 'MaxStep', num2str(maxstep, 12));
    tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
    [t1, P] = getlog(so, 'w5s3_plog', 5);     % ref q qd tau_cmd tau_joint (1 ms)
    [t2, E] = getlog(so, 'w5s3_elog', 16);    % iq_ref id iq vd_raw vq_raw vd_cmd vq_cmd sat wm Tm | target q qd tau_cmd tau_joint iq_raw (100 us)
    [t3, X] = getlog(so, 'w6s43_xlog', 8);    % duty_abc, int id, int iq, int va vb vc (100 us)
    [t4, I] = getlog(so, 'w6s43_ilog', 2);    % id iq (솔버 스텝마다)
    if numel(t2) ~= numel(t3), error('전기 로그(%d)와 추가 로그(%d)의 행 수가 다르다', numel(t2), numel(t3)); end
    Ts = p.cur.Ts;
    mid = [0; diff(X(:,4))] / Ts;  miq = [0; diff(X(:,5))] / Ts;
    mva = [0; diff(X(:,6))] / Ts;  mvb = [0; diff(X(:,7))] / Ts;  mvc = [0; diff(X(:,8))] / Ts;
    th_e = p.pmsm.pp * p.gear.N * E(:,12);
    names = {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','postgear_electromagnetic_torque_Nm', ...
        'id_reference_A','iq_reference_A','iq_raw_reference_A','id_A','iq_A','vd_raw_V','vq_raw_V','vd_command_V','vq_command_V', ...
        'motor_torque_Nm','motor_speed_rad_s','electrical_angle_rad','duty_a','duty_b','duty_c', ...
        'previous_cycle_mean_id_A','previous_cycle_mean_iq_A','previous_cycle_mean_motor_torque_Nm', ...
        'previous_cycle_mean_va_V','previous_cycle_mean_vb_V','previous_cycle_mean_vc_V','voltage_command_limited'};
    M = [t2, E(:,11), E(:,12), E(:,13), E(:,14), E(:,15), zeros(numel(t2),1), E(:,1), E(:,16), E(:,2), E(:,3), E(:,4), E(:,5), E(:,6), E(:,7), ...
        E(:,10), E(:,9), th_e, X(:,1), X(:,2), X(:,3), mid, miq, p.pmsm.Kt * miq, mva, mvb, mvc, E(:,8)];
    writetable(array2table(M, 'VariableNames', names), fullfile(outDir, [name '_electrical_100us.csv']));
    writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,4), P(:,5), 'VariableNames', ...
        {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','postgear_electromagnetic_torque_Nm'}), fullfile(outDir, [name '_position_1ms.csv']));
    writetable(table(t4, I(:,1), I(:,2), 'VariableNames', {'time_s','id_A','iq_A'}), fullfile(outDir, [name '_iq_allsteps.csv']));

    q = P(:,2);
    band = 0.02 * cfg.target;
    after = find(t1 >= cfg.t_step_model + p.Ts/2 - 1e-9);
    last = find(abs(q(after) - cfg.target) > band, 1, 'last');
    if isempty(last), ts = 0; elseif last == numel(after), ts = NaN; else, ts = t1(after(last + 1)) - t1(after(1)); end
    fprintf('  %.1f s | 행: 위치 %d, 전기 %d, 모든 스텝 %d | 최종 각도 %.6f rad | 2%% 정착 %.3f s | 최대 iq %.4f A | 전압 지령 제한 횟수 %d\n', ...
        el, numel(t1), numel(t2), numel(t4), q(end), ts, max(E(:,3)), sum(E(:,8) > 0.5));
    fprintf(fid, '%s %s MaxStep %g t_end %g: rows pos=%d elec=%d allsteps=%d q_end=%.6f ts=%.3f iqmax=%.4f wall=%.1fs\n', ...
        name, mdl, maxstep, cfg.t_end, numel(t1), numel(t2), numel(t4), q(end), ts, max(E(:,3)), el);
    close_system(mdl, 0);
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
    if size(D, 2) ~= nc, error('로그 %s 의 열 수가 %d 가 아니다 (실제 %s)', name, nc, mat2str(size(D))); end
end
