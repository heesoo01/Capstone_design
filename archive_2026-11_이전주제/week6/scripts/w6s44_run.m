function w6s44_run(which)
%W6S44_RUN 4-4 (권선 열 모델) MATLAB/Simulink 시험 실행 -> week6\matlab_results\stage4_4\*.csv
%   w6s44_run('thermal') : 독립 열 시험 600 s 3종 (10 W 열원 / 정전류 iq=2 A / 80 C 냉각), 연속시간 ODE
%   w6s44_run('main')    : 통합 2 s 5종 (baseline_fixed25/thermal25/thermal80, stress_thermal25/thermal80), 열 업데이트 1 ms (방식 A)
%   w6s44_run('all')     : 위 둘 순서대로
% 비교는 python w6s44_compare.py 가 한다 (같은 폴더).
% 주의: [실패] 또는 오류 로그는 그대로 알려줄 것.
if nargin < 1, which = 'thermal'; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s44_params();
mdlDir = fullfile(here, '..', 'models');
outDir = fullfile(here, '..', 'matlab_results', 'stage4_4');
if ~exist(outDir, 'dir'), mkdir(outDir); end
fid = fopen(fullfile(outDir, 'matlab_settings.txt'), 'a');
fprintf(fid, '\n==== %s w6s44_run(''%s'') MATLAB %s ====\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), which, version);
fprintf(fid, '통합: 5주차 3-2 모델(Simulink 가변 스텝 solver=%s RelTol=%s AbsTol=%s, MaxStep %g) + R(T) + 열 업데이트 %g s (방식 A, 구간 평균 전력 정확해, 민혁 stage4_4_core.py 의 thermal_step() 과 같은 식). 평균 인버터(PWM 없음).\n', ...
    p.solver, p.reltol, p.abstol, p.t44.maxstep, p.th.dt_upd);
fprintf(fid, '독립 열 시험: Simulink 연속시간 ode45 RelTol 1e-10 AbsTol 1e-12 MaxStep 0.1 (민혁은 같은 ODE 를 RK4, dt 0.1 s 로 적분: stage4_4_core.py thermal_series()). 열 파라미터는 가정값.\n');
cl = onCleanup(@() fclose(fid));
fprintf('===== W6S44 RUN (%s) =====\n', which);
if any(strcmp(which, {'thermal', 'all'})), doThermal(p, mdlDir, outDir, fid); end
if any(strcmp(which, {'main', 'all'})),    doMain(p, mdlDir, outDir, fid);    end
fprintf('\n===== W6S44 RUN 끝 (%s). 결과: %s =====\n', which, outDir);
end

%% ---------------- 독립 열 시험 ----------------
function doThermal(p, mdlDir, outDir, fid)
    names = {'heat', 'current', 'cooling'};
    files = {'thermal_constant_heat', 'thermal_constant_current', 'thermal_cooling'};
    for k = 1:3
        mdl = p.t44.models.(names{k});
        fprintf('\n##### %s (%s) : %g s #####\n', files{k}, mdl, p.t44.thermal.t_end);
        load_system(fullfile(mdlDir, [mdl '.slx']));
        tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
        [t, D] = getlog(so, 'w6s44_thlog', 5);
        writetable(table(t, D(:,1), D(:,2), D(:,3), D(:,4), D(:,5), 'VariableNames', ...
            {'time_s', 'temperature_C', 'heat_power_W', 'instant_cooling_W', 'heat_input_energy_J', 'heat_exported_energy_J'}), fullfile(outDir, [files{k} '.csv']));
        i300 = find(abs(t - p.t44.thermal.t_off) < 1e-9, 1);
        fprintf('  %.1f s, 로그 %d 행 | T(300 s) = %.8f C | T(600 s) = %.8f C\n', el, numel(t), D(i300, 1), D(end, 1));
        fprintf(fid, '%s: rows=%d T300=%.10f Tend=%.10f wall=%.1fs\n', files{k}, numel(t), D(i300, 1), D(end, 1), el);
        close_system(mdl, 0);
    end
end

%% ---------------- 통합 2 s ----------------
function doMain(p, mdlDir, outDir, fid)
    mdl = p.t44.models.joint;
    for k = 1:numel(p.t44.cases)
        c = p.t44.cases(k);
        fprintf('\n##### %s : T0=%g C, 열모델 %d, Vdc=%g V, 목표 %g rad, 2 s, MaxStep %g #####\n', c.name, c.T0, c.thermal, c.Vdc, c.target, p.t44.maxstep);
        load_system(fullfile(mdlDir, [mdl '.slx']));
        set_param([mdl '/Ref_Step'], 'Time', num2str(p.t44.t_step_model, 12), 'After', num2str(c.target, 12));
        set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(c.Vdc), 12));
        set_param([mdl '/XT0'], 'Value', num2str(c.T0, 12));
        set_param([mdl '/XEn'], 'Value', num2str(c.thermal, 12));
        set_param([mdl '/XTprev'], 'InitialCondition', num2str(c.T0, 12));
        set_param([mdl '/XTfdel'], 'InitialCondition', num2str(c.T0, 12));
        set_param(mdl, 'StopTime', num2str(p.t44.t_end, 12));
        set_param(mdl, 'MaxStep', num2str(p.t44.maxstep, 12));
        tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
        [t1, P] = getlog(so, 'w5s3_plog', 5);     % ref q qd tau_cmd tau_joint (1 ms)
        [t2, E] = getlog(so, 'w5s3_elog', 16);    % iq_ref id iq vd_raw vq_raw vd_cmd vq_cmd sat wm Tm | target q qd tau_cmd tau_joint iq_raw (100 us)
        [t3, X] = getlog(so, 'w6s44_xlog', 12);   % T R Pcu Pcool Ein Ecu Eexp Evis Emech U Ekin pending (100 us)
        if numel(t2) ~= numel(t3), error('전기 로그(%d)와 열 로그(%d)의 행 수가 다르다', numel(t2), numel(t3)); end
        th = p.th;
        dU = X(:,10) - X(1,10); dK = X(:,11) - X(1,11);
        dTh = th.C * (X(:,1) - c.T0);
        Edel = X(:,6) - X(:,12);                                    % 열 노드에 전달된 동손
        res_total = X(:,5) - (dU + dK + dTh + X(:,7) + X(:,8) + X(:,12));   % 동손은 축열+방열(+대기)로만 셈. 최종 손실 항에 다시 더하지 않음
        res_thermal = Edel - (dTh + X(:,7));
        res_elec = X(:,5) - dU - X(:,6) - X(:,9);                   % 전기 입력 = 자기 + 동손 + 기계(관절 입력 토크*속도)
        names = {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','postgear_electromagnetic_torque_Nm', ...
            'iq_reference_A','iq_raw_reference_A','id_A','iq_A','vd_raw_V','vq_raw_V','vd_command_V','vq_command_V', ...
            'motor_torque_Nm','motor_speed_rad_s','voltage_command_limited', ...
            'winding_temperature_C','phase_resistance_ohm','instant_copper_loss_W','instant_cooling_to_ambient_W', ...
            'electrical_input_energy_J','copper_loss_energy_J','heat_exported_to_ambient_J','viscous_loss_energy_J','mechanical_work_energy_J', ...
            'magnetic_energy_change_J','kinetic_energy_change_J','winding_thermal_energy_change_J','pending_thermal_energy_J', ...
            'total_energy_residual_J','thermal_energy_residual_J','electrical_conversion_residual_J'};
        M = [t2, E(:,11), E(:,12), E(:,13), E(:,14), E(:,15), E(:,1), E(:,16), E(:,2), E(:,3), E(:,4), E(:,5), E(:,6), E(:,7), ...
            E(:,10), E(:,9), E(:,8), X(:,1), X(:,2), X(:,3), X(:,4), X(:,5), X(:,6), X(:,7), X(:,8), X(:,9), ...
            dU, dK, dTh, X(:,12), res_total, res_thermal, res_elec];
        writetable(array2table(M, 'VariableNames', names), fullfile(outDir, [c.name '.csv']));
        writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,4), P(:,5), 'VariableNames', ...
            {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','postgear_electromagnetic_torque_Nm'}), fullfile(outDir, [c.name '_position_1ms.csv']));
        q = P(:,2);
        fprintf('  %.1f s | 행: 위치 %d, 전기 %d | 최종 각도 %.6f rad | 최종 T %.6f C | 최대 iq %.4f A | 전압 제한 %d | 잔차 최대: 전체 %.3e, 열 %.3e, 전기변환 %.3e J\n', ...
            el, numel(t1), numel(t2), q(end), X(end,1), max(E(:,3)), sum(E(:,8) > 0.5), max(abs(res_total)), max(abs(res_thermal)), max(abs(res_elec)));
        fprintf(fid, '%s MaxStep %g: rows pos=%d elec=%d q_end=%.6f T_end=%.6f iqmax=%.4f res_total=%.3e res_thermal=%.3e res_elec=%.3e wall=%.1fs\n', ...
            c.name, p.t44.maxstep, numel(t1), numel(t2), q(end), X(end,1), max(E(:,3)), max(abs(res_total)), max(abs(res_thermal)), max(abs(res_elec)), el);
        close_system(mdl, 0);
    end
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
    if size(D, 2) ~= nc, error('로그 %s 의 열 수가 %d 가 아니다 (실제 %s)', name, nc, mat2str(size(D))); end
end
