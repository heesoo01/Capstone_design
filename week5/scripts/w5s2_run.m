function w5s2_run(idx)
%W5S2_RUN 2단계 시험 2-1, 2-2, 2-3 실행 -> CSV + 지표 + 해석 간격 수렴
%   w5s2_run(1)  : 간격 상한 25 us 한 번씩만 (빠른 확인, 먼저 이걸로)
%   w5s2_run     : 25 / 12.5 / 6.25 us 전부 (느릴 수 있음)
%
% *** 아직 실행 전 -- 먼저 w5s2_build 가 [실패] 없이 끝나야 한다. ***
if nargin < 1, idx = 1:3; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w5s2_params();
resDir = fullfile(here, '..', 'results');
if ~exist(resDir, 'dir'), mkdir(resDir); end
mdlDir = fullfile(here, '..', 'models');

fid = fopen(fullfile(resDir, 'w5s2_matlab_settings.txt'), 'w');
fprintf(fid, 'MATLAB %s | Simulink 가변 스텝 solver=%s RelTol=%s AbsTol=%s | MaxStep=%s\n', ...
    version, p.solver, p.reltol, p.abstol, mat2str(p.s2.maxsteps(idx)));
fprintf(fid, '위치 루프 %g s, 전류 루프 %g s, 로그 간격 위치 %g s / 전기 %g s, 로컬 솔버 사용 안 함\n', p.Ts, p.cur.Ts, p.log_dt, p.cur.Ts);
fprintf(fid, '\n구현 가정 (MuJoCo 코드와 대조 필요):\n');
fprintf(fid, '- 위치 루프(1 ms): tau* = Kp(qref-q) - Kd*qdot (샘플 시점 측정), iq* = clip(tau*/Kt, +-2 A), id* = 0, 다음 위치 샘플까지 유지\n');
fprintf(fid, '- 전류 루프(100 us): 샘플 시점의 id, iq, 모터 속도 사용. 병렬형 PI v = Kpi*e + I + ff, ff_d = -we*L*iq, ff_q = we*(L*id+psi), we = pp*wm\n');
fprintf(fid, '- 전압 제한: |v| > Vdc/sqrt(3) 이면 방향 유지, 크기를 한계로 축소 (s = min(1, Vmax/|v|))\n');
fprintf(fid, '- 안티윈드업(역계산): I[k+1] = I[k] + Ts*(Ki*e + Kaw*(v_sat - v_cmd)), v_cmd는 ff 포함, 현재 I로 전압을 계산한 뒤 적분 상태 갱신, Ts=100 us 전방 오일러\n');
fprintf(fid, '- 계산한 v_sat는 다음 100 us 동안 유지. 위치·전류 루프 시각이 겹치면 위치 루프가 먼저 갱신된 iq*를 전류 루프가 사용\n');
fprintf(fid, '- PMSM dq 방정식은 연속시간으로 적분, tau_m = 1.5*pp*psi*iq 를 관절에 연속 인가\n\n');

fprintf('===== W5S2 RUN (MaxStep 인덱스 %s) =====\n', mat2str(idx));

%% ---------- 2-1: 전기 모델 단독 ----------
fprintf('\n##### 2-1 전기 모델 단독 (wm=0, vd=%g, vq=%g V) #####\n', p.t21_vd, p.t21_vq);
mdl = p.name_alone;
load_system(fullfile(mdlDir, [mdl '.slx']));
R = p.pmsm.R; L = p.pmsm.L;
for r = idx
    set_param(mdl, 'MaxStep', num2str(p.s2.maxsteps(r)));
    tic; simOut = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
    [t, D] = getlog(simOut, 'w5s2_alone', 6);   % vd vq wm id iq tau
    iq_ex = (p.t21_vq / R) * (1 - exp(-t * R / L));
    [~, i10] = min(abs(t - 0.01));
    fprintf('  MaxStep %g: %d행, %.1f s 소요 | iq(10 ms) = %.5f A (기대 1.26424) | max|iq-정확해| = %.3e A | max|id| = %.3e A | iq(끝) = %.5f A\n', ...
        p.s2.maxsteps(r), numel(t), el, D(i10, 5), max(abs(D(:,5) - iq_ex)), max(abs(D(:,4))), D(end, 5));
    T = table(t, D(:,1), D(:,2), D(:,3), D(:,4), D(:,5), D(:,6), iq_ex, 'VariableNames', ...
        {'time_s','vd_V','vq_V','omega_rad_s','id_A','iq_A','torque_Nm','iq_exact_A'});
    writetable(T, fullfile(resDir, ['w5s2_2-1_matlab_elec' p.s2.tags{r} '.csv']));
    fprintf(fid, '2-1 MaxStep %g: iq(10ms)=%.6f max|iq-exact|=%.3e\n', p.s2.maxsteps(r), D(i10,5), max(abs(D(:,5) - iq_ex)));
end
close_system(mdl, 0);

%% ---------- 2-2, 2-3: 통합 ----------
mdl = p.name_joint;
load_system(fullfile(mdlDir, [mdl '.slx']));
cases = {'2-2_24V', p.t22_target, 24; '2-3_24V', p.t23_target, 24; '2-3_2V', p.t23_target, 2};
allRes = cell(size(cases, 1), numel(idx));
for c = 1:size(cases, 1)
    fprintf('\n##### %s : 목표 %g rad, Vdc = %g V (전압 한계 %.4f V) #####\n', cases{c,1}, cases{c,2}, cases{c,3}, p.vmax(cases{c,3}));
    for k = 1:numel(idx)
        r = idx(k);
        allRes{c, k} = runJoint(mdl, p, cases{c,2}, cases{c,3}, r, cases{c,1}, resDir, fid);
    end
    if numel(idx) > 1
        base = allRes{c, 1};
        for k = 2:numel(idx)
            fprintf('  수렴: MaxStep %g vs %g : max|Δq| = %.3e rad, max|Δiq| = %.3e A\n', ...
                p.s2.maxsteps(idx(k)), p.s2.maxsteps(idx(1)), ...
                max(abs(allRes{c,k}.q - base.q)), max(abs(allRes{c,k}.iq - base.iq)));
            fprintf(fid, '%s convergence MaxStep %g vs %g: max|dq|=%.3e max|diq|=%.3e\n', cases{c,1}, ...
                p.s2.maxsteps(idx(k)), p.s2.maxsteps(idx(1)), max(abs(allRes{c,k}.q - base.q)), max(abs(allRes{c,k}.iq - base.iq)));
        end
    end
end
fclose(fid);
fprintf('\n[OK] 설정/가정 기록: %s\n', fullfile(resDir, 'w5s2_matlab_settings.txt'));
fprintf('\n===== W5S2 RUN 끝. 출력 전체를 붙여넣어 달라. CSV는 week5\\results 에 있다. =====\n');
end

%% ---------------- 로컬 함수 ----------------
function res = runJoint(mdl, p, target, V, r, caseName, resDir, fid)
    set_param([mdl '/Ref_Step'], 'After', num2str(target, 12));
    set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(V), 12));
    set_param(mdl, 'MaxStep', num2str(p.s2.maxsteps(r)));
    try
        tic; simOut = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
    catch ME
        fprintf('  [실패] 시뮬레이션: %s\n', ME.message);
        disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
        error('w5s2:simfail', '시뮬레이션 실패');
    end
    [t1, P] = getlog(simOut, 'w5s2_plog', 5);    % ref q qd tau_cmd tau_act
    [t2, E] = getlog(simOut, 'w5s2_elog', 9);    % iq_ref id iq vd_cmd vq_cmd vd_sat vq_sat sat wm
    tag = p.s2.tags{r};
    base = fullfile(resDir, ['w5s2_' caseName '_matlab']);
    writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,4), P(:,5), 'VariableNames', ...
        {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','actual_torque_Nm'}), [base '_pos' tag '.csv']);
    writetable(table(t2, E(:,1), E(:,2), E(:,3), E(:,4), E(:,5), E(:,6), E(:,7), E(:,8), E(:,9), 'VariableNames', ...
        {'time_s','iq_ref_A','id_A','iq_A','vd_cmd_V','vq_cmd_V','vd_sat_V','vq_sat_V','saturated','omega_rad_s'}), [base '_elec' tag '.csv']);

    % 지표
    q = P(:,2); qd = P(:,3);
    w = t1 >= 0.2 - 1e-9 & t1 <= 2.0 + 1e-9;
    rmse = sqrt(mean((q(w) - P(w,1)).^2));
    band = 0.02 * target;
    after = find(t1 >= 0.2 - 1e-9);
    last = find(abs(q(after) - target) > band, 1, 'last');
    if isempty(last), ts = 0; elseif last == numel(after), ts = NaN; else, ts = t1(after(last + 1)) - 0.2; end
    ov = max(0, (max(q(after)) - target) / target * 100);
    [~, i02] = min(abs(t2 - 0.2));
    vmag = hypot(E(:,6), E(:,7));
    satIdx = find(E(:,8) > 0.5);
    if isempty(satIdx), satInfo = '포화 없음'; else, satInfo = sprintf('포화 구간 %.4f ~ %.4f s (%.1f%% 시간)', t2(satIdx(1)), t2(satIdx(end)), 100*numel(satIdx)/numel(t2)); end
    [~, i02p] = min(abs(t1 - 0.2));
    fprintf('  MaxStep %g (%.1f s 소요) | 행 수 위치 %d (기대 2001), 전기 %d (기대 20001)\n', p.s2.maxsteps(r), el, numel(t1), numel(t2));
    fprintf('    첫 요구 토크 tau*(0.2s) = %.6f N*m | iq_ref(0.2s) = %.4f A | 최대 iq = %.4f A | 최대 |iq_ref-iq| = %.4f A\n', ...
        P(i02p,4), E(i02,1), max(E(:,3)), max(abs(E(:,1) - E(:,3))));
    fprintf('    |v_sat| 최대 = %.4f V (한계 %.4f V) | %s\n', max(vmag), p.vmax(V), satInfo);
    fprintf('    최종 각도 %.6f rad | 최대 속도 %.6f rad/s | 오버슈트 %.3f %% | 정착(±%.4f rad) %.3f s | 추종 RMSE %.6f rad\n', ...
        q(end), max(abs(qd(after))), ov, band, ts, rmse);
    fprintf(fid, '%s MaxStep %g: tau*(0.2)=%.6f iq_ref(0.2)=%.4f iqmax=%.4f q_end=%.6f vmax=%.6f ts=%.3f rmse=%.6f %s\n', ...
        caseName, p.s2.maxsteps(r), P(i02p,4), E(i02,1), max(E(:,3)), q(end), max(abs(qd(after))), ts, rmse, satInfo);
    res.q = q; res.iq = E(:,3);
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
end
