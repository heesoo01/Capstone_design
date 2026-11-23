function w6s41_run(which)
%W6S41_RUN 4-1 (관절 건마찰) MATLAB/Simulink 시험 실행 -> week6\matlab_results\stage4_1\*.csv
%   w6s41_run('base') : 마찰 없음(baseline) 4개 시험  (5주차 3-2 재현 + 지령 변경 확인)
%   w6s41_run('dry')  : 건마찰 0.05 N*m, 속도 임계값 3개 x 4개 시험 + slow_reversal 간격 수렴 1건
%   w6s41_run('all')  : 위 둘 순서대로
% 비교는 python w6s41_compare.py 가 한다 (같은 폴더).
% 주의: [실패] 또는 오류 로그는 그대로 알려줄 것.
if nargin < 1, which = 'base'; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w6s41_params();
mdlDir = fullfile(here, '..', 'models');
outDir = fullfile(here, '..', 'matlab_results', 'stage4_1');
if ~exist(outDir, 'dir'), mkdir(outDir); end
fid = fopen(fullfile(outDir, 'matlab_settings.txt'), 'a');
fprintf(fid, '\n==== %s w6s41_run(''%s'') MATLAB %s | Simulink 가변 스텝 solver=%s RelTol=%s AbsTol=%s ====\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'), which, version, p.solver, p.reltol, p.abstol);
fprintf(fid, '건마찰: Simscape Rotational Friction 블록 Coulomb=Breakaway=%g N*m, 점성 0, 속도 임계값(brkwy_vel) %s rad/s. 관절 속도를 이상 속도원에 강제하고 토크 센서로 읽어 관절 입력에 더함. 평균 인버터. 5주차 3-2 와 동일 파라미터.\n', p.t41.fric, mat2str(p.t41.vb));
cl = onCleanup(@() fclose(fid));
fprintf('===== W6S41 RUN (%s) =====\n', which);
if any(strcmp(which, {'base', 'all'}))
    for s = 1:numel(p.t41.sc), runCase(p, mdlDir, outDir, fid, p.t41.sc(s), 'baseline', 0, p.t41.vb(end), p.t41.maxstep); end
end
if any(strcmp(which, {'dry', 'all'}))
    for s = 1:numel(p.t41.sc)
        for k = 1:numel(p.t41.vb)
            runCase(p, mdlDir, outDir, fid, p.t41.sc(s), ['dry_' p.t41.vbtag{k}], 1, p.t41.vb(k), p.t41.maxstep);
        end
    end
    runCase(p, mdlDir, outDir, fid, p.t41.sc(3), ['dry_' p.t41.vbtag{2} '_ms2p5us'], 1, p.t41.vb(2), p.t41.conv_maxstep);
end
fprintf('\n===== W6S41 RUN 끝 (%s). 결과: %s =====\n', which, outDir);
end

function runCase(p, mdlDir, outDir, fid, sc, tag, fen, vb, maxstep)
    mdl = p.t41.model;
    name = [sc.name '_' tag];
    fprintf('\n##### %s : t_end %g s, 마찰 %d, brkwy_vel %g rad/s, MaxStep %g #####\n', name, sc.t_end, fen, vb, maxstep);
    load_system(fullfile(mdlDir, [mdl '.slx']));
    set_param([mdl '/Ref_Step'], 'Time', num2str(p.t41.t0, 12), 'After', num2str(sc.stepA, 12));
    tB = sc.tB; if tB == 0, tB = 1e9; end
    set_param([mdl '/XStepB'], 'Time', num2str(tB, 12), 'After', num2str(sc.stepB, 12));
    set_param([mdl '/XSine'], 'Amplitude', num2str(sc.sinA, 12));
    set_param([mdl '/XFen'], 'Value', num2str(fen));
    set_param([mdl '/XRF'], 'brkwy_vel', num2str(vb, 12));
    set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(p.Vdc), 12));
    set_param(mdl, 'StopTime', num2str(sc.t_end, 12));
    set_param(mdl, 'MaxStep', num2str(maxstep, 12));
    tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
    [t1, P] = getlog(so, 'w5s3_plog', 5);     % ref q qd tau_cmd tau_joint (1 ms)
    [t2, E] = getlog(so, 'w5s3_elog', 16);    % iq_ref id iq vd_raw vq_raw vd_cmd vq_cmd sat wm Tm | target q qd tau_cmd tau_joint iq_raw (100 us)
    [t3, F] = getlog(so, 'w6s41_flog', 2);    % 마찰 토크(관절 입력에 더한 값), 관절 속도 (100 us)
    if numel(t2) ~= numel(t3), error('전기 로그(%d)와 마찰 로그(%d)의 행 수가 다르다', numel(t2), numel(t3)); end
    names = {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','actual_torque_Nm', ...
        'iq_reference_A','iq_raw_reference_A','id_A','iq_A','vd_raw_V','vq_raw_V','vd_V','vq_V','motor_torque_Nm','motor_speed_rad_s','voltage_limited','dry_friction_torque_Nm'};
    M = [t2, E(:,11), E(:,12), E(:,13), E(:,14), E(:,15), E(:,1), E(:,16), E(:,2), E(:,3), E(:,4), E(:,5), E(:,6), E(:,7), E(:,10), E(:,9), E(:,8), F(:,1)];
    writetable(array2table(M, 'VariableNames', names), fullfile(outDir, [name '_electrical_100us.csv']));
    writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,4), P(:,5), 'VariableNames', ...
        {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','actual_torque_Nm'}), fullfile(outDir, [name '_position_1ms.csv']));
    q = P(:,2);
    fprintf('  %.1f s | 행: 위치 %d, 전기 %d | 최종 각도 %.6f rad (최종 오차 %.4e) | 최대 iq %.4f A | 최대 |마찰 토크| %.4f N*m | 전압 제한 %d\n', ...
        el, numel(t1), numel(t2), q(end), P(end,1) - q(end), max(E(:,3)), max(abs(F(:,1))), sum(E(:,8) > 0.5));
    fprintf(fid, '%s MaxStep %g t_end %g: rows pos=%d elec=%d q_end=%.6f iqmax=%.4f frmax=%.4f wall=%.1fs\n', name, maxstep, sc.t_end, numel(t1), numel(t2), q(end), max(E(:,3)), max(abs(F(:,1))), el);
    close_system(mdl, 0);
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
    if size(D, 2) ~= nc, error('로그 %s 의 열 수가 %d 가 아니다 (실제 %s)', name, nc, mat2str(size(D))); end
end
