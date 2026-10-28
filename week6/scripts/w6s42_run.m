function w6s42_run(which)
%W6S42_RUN 4-2 (기어 백래시) MATLAB/Simulink 시험 실행 -> week6\matlab_results\stage4_2\*.csv
%   w6s42_run('rigid')  : rigid_reference (5주차 3-2) 3개 시험
%   w6s42_run('gap')    : 유격 관절 모델. near_zero_gap(±1e-6 rad) 1개 접촉 설정 x 3시험, backlash(±0.5도) 접촉 설정 6개 x 3시험
%   w6s42_run('conv')   : MATLAB 자체 간격 수렴 1건 (reversal_steps, backlash, K=1e6, 임계 감쇠 근사, 최대 스텝 2.5 us)
%   w6s42_run('all')    : 위 셋 순서대로
% 접촉 설정 6개 = 강성 K {1e5,1e6,1e7} N*m/rad  x  감쇠 {0.01(블록 기본), 2*sqrt(K*J_red)(임계 감쇠 근사, 추정)}
% 비교는 python w6s42_compare.py 가 한다 (같은 폴더).
% 주의: [실패] 또는 오류 로그는 그대로 알려줄 것.
if nargin < 1, which = 'rigid'; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s42_params();
mdlDir = fullfile(here, '..', 'models');
outDir = fullfile(here, '..', 'matlab_results', 'stage4_2');
if ~exist(outDir, 'dir'), mkdir(outDir); end
fid = fopen(fullfile(outDir, 'matlab_settings.txt'), 'a');
fprintf(fid, '\n==== %s w6s42_run(''%s'') MATLAB %s | Simulink 가변 스텝 solver=%s RelTol=%s AbsTol=%s ====\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), which, version, p.solver, p.reltol, p.abstol);
fprintf(fid, '백래시: Simscape Multibody 두 회전 관절 직렬(구동 + 유격), 유격 관절 위치 한계 스프링-댐퍼(전환 폭 %g rad)로 접촉 표현. K=%s N*m/rad, 감쇠 0.01 또는 2*sqrt(K*Jred)=%s. 반폭 backlash=%g rad, near_zero_gap=%g rad. 평균 인버터. MaxStep %g.\n', ...
    p.t42.trans, mat2str(p.t42.K), mat2str(p.t42.Dcrit, 4), p.t42.half.backlash, p.t42.half.near_zero_gap, p.t42.maxstep);
cl = onCleanup(@() fclose(fid));
fprintf('===== W6S42 RUN (%s) =====\n', which);
if any(strcmp(which, {'rigid', 'all'}))
    for s = 1:numel(p.t42.sc), runCase(p, mdlDir, outDir, fid, p.t42.models.rigid, p.t42.sc(s), 'rigid_reference', NaN, NaN, NaN); end
end
if any(strcmp(which, {'gap', 'all'}))
    kc = 2;    % near_zero_gap: K=1e6, 임계 감쇠 근사
    for s = 1:numel(p.t42.sc)
        runCase(p, mdlDir, outDir, fid, p.t42.models.joint, p.t42.sc(s), sprintf('near_zero_gap_K%s_Dcrit', fmtK(p.t42.K(kc))), p.t42.half.near_zero_gap, p.t42.K(kc), p.t42.Dcrit(kc));
    end
    for s = 1:numel(p.t42.sc)
        for k = 1:numel(p.t42.K)
            runCase(p, mdlDir, outDir, fid, p.t42.models.joint, p.t42.sc(s), sprintf('backlash_K%s_Dcrit', fmtK(p.t42.K(k))), p.t42.half.backlash, p.t42.K(k), p.t42.Dcrit(k));
            runCase(p, mdlDir, outDir, fid, p.t42.models.joint, p.t42.sc(s), sprintf('backlash_K%s_D0p01', fmtK(p.t42.K(k))), p.t42.half.backlash, p.t42.K(k), p.t42.D0);
        end
    end
end
if any(strcmp(which, {'conv', 'all'}))
    % MATLAB 자체 간격 수렴: reversal_steps / backlash / K=1e6 / 임계 감쇠 근사 를 최대 스텝 2.5 us 로 한 번 더
    kc = 2;
    p.t42.maxstep = p.t42.maxstep / 2;
    runCase(p, mdlDir, outDir, fid, p.t42.models.joint, p.t42.sc(2), sprintf('backlash_K%s_Dcrit_ms2p5us', fmtK(p.t42.K(kc))), p.t42.half.backlash, p.t42.K(kc), p.t42.Dcrit(kc));
end
fprintf('\n===== W6S42 RUN 끝 (%s). 결과: %s =====\n', which, outDir);
end

function s = fmtK(K)
    s = strrep(sprintf('%.0e', K), '+0', '');
    s = strrep(s, 'e', 'e');
end

function runCase(p, mdlDir, outDir, fid, mdl, sc, tag, half, K, D)
    name = [sc.name '_' tag];
    fprintf('\n##### %s : t_end %g s, 반폭 %g rad, K %g, D %g #####\n', name, sc.t_end, half, K, D);
    load_system(fullfile(mdlDir, [mdl '.slx']));
    set_param([mdl '/Ref_Step'], 'Time', num2str(p.t42.t0, 12), 'After', num2str(sc.stepA, 12));
    tB = sc.tB; if tB == 0, tB = 1e9; end
    tC = sc.tC; if tC == 0, tC = 1e9; end
    set_param([mdl '/XStepB'], 'Time', num2str(tB, 12), 'After', num2str(sc.stepB, 12));
    set_param([mdl '/XStepC'], 'Time', num2str(tC, 12), 'After', num2str(sc.stepC, 12));
    set_param([mdl '/XSine'], 'Amplitude', num2str(sc.sinA, 12));
    set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(p.Vdc), 12));
    isgap = ~isnan(half);
    if isgap
        g = [mdl '/GapJoint'];
        set_param(g, 'LowerLimitBound', num2str(-half, 16), 'UpperLimitBound', num2str(half, 16));
        set_param(g, 'LowerLimitStiffness', num2str(K, 16), 'UpperLimitStiffness', num2str(K, 16));
        set_param(g, 'LowerLimitDamping', num2str(D, 16), 'UpperLimitDamping', num2str(D, 16));
    end
    set_param(mdl, 'StopTime', num2str(sc.t_end, 12));
    set_param(mdl, 'MaxStep', num2str(p.t42.maxstep, 12));
    tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
    [t1, P] = getlog(so, 'w5s3_plog', 5);     % ref q_load qd_load tau_cmd tau_joint (1 ms)
    [t2, E] = getlog(so, 'w5s3_elog', 16);    % iq_ref id iq vd_raw vq_raw vd_cmd vq_cmd sat wm Tm | target q_load qd_load tau_cmd tau_joint iq_raw (100 us)
    if isgap
        [t3, G] = getlog(so, 'w6s42_glog', 6);    % q_drive q_gap qd_drive qd_gap tau_lower tau_upper (100 us)
        if numel(t2) ~= numel(t3), error('전기 로그(%d)와 유격 로그(%d)의 행 수가 다르다', numel(t2), numel(t3)); end
    else
        G = [E(:,12), zeros(numel(t2), 1), E(:,13), zeros(numel(t2), 1), nan(numel(t2), 2)];
    end
    names = {'time_s','target_rad','load_angle_rad','load_velocity_rad_s','postgear_electromagnetic_torque_Nm','id_A','iq_A','iq_reference_A','iq_raw_reference_A', ...
        'vd_V','vq_V','motor_electromagnetic_torque_Nm','motor_speed_rad_s','voltage_limited','drive_angle_output_equivalent_rad','gap_coordinate_rad', ...
        'drive_velocity_output_equivalent_rad_s','gap_velocity_rad_s','limit_torque_lower_Nm','limit_torque_upper_Nm'};
    M = [t2, E(:,11), E(:,12), E(:,13), E(:,15), E(:,2), E(:,3), E(:,1), E(:,16), E(:,6), E(:,7), E(:,10), E(:,9), E(:,8), G(:,1), G(:,2), G(:,3), G(:,4), G(:,5), G(:,6)];
    writetable(array2table(M, 'VariableNames', names), fullfile(outDir, [name '_electrical_100us.csv']));
    writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,5), 'VariableNames', ...
        {'time_s','target_rad','load_angle_rad','load_velocity_rad_s','postgear_electromagnetic_torque_Nm'}), fullfile(outDir, [name '_position_1ms.csv']));
    q = P(:,2);
    gapmax = NaN; if isgap, gapmax = max(abs(G(:,2))); end
    fprintf('  %.1f s | 행: 위치 %d, 전기 %d | 최종 각도 %.6f rad | 최대 iq %.4f A | 최대 |q_gap| %.6g rad (반폭 %g) | 전압 제한 %d\n', ...
        el, numel(t1), numel(t2), q(end), max(E(:,3)), gapmax, half, sum(E(:,8) > 0.5));
    fprintf(fid, '%s t_end %g: rows pos=%d elec=%d q_end=%.6f iqmax=%.4f max|qgap|=%.6g wall=%.1fs\n', name, sc.t_end, numel(t1), numel(t2), q(end), max(E(:,3)), gapmax, el);
    close_system(mdl, 0);
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
    if size(D, 2) ~= nc, error('로그 %s 의 열 수가 %d 가 아니다 (실제 %s)', name, nc, mat2str(size(D))); end
end
