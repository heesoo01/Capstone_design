function w5s3_run(idx, stageIds)
%W5S3_RUN 3단계 시험 3-1, 3-2 실행 -> matlab_results\stage3_x\ CSV + 기어 단독 검사 + 해석 간격 수렴
%   w5s3_run(1)        : 간격 상한 25 us 한 번씩 (빠른 확인)
%   w5s3_run           : 25 / 12.5 / 6.25 us 전부
%   w5s3_run(1:3, {'3-1'}) : 3-1만
% CSV 이름은 MuJoCo(이민혁) 파일과 같게 {case}_position_dtXX.csv / {case}_electrical_dtXX.csv, 열 이름도 MuJoCo 쪽에 맞춘다.
if nargin < 1, idx = 1:3; end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, '..', 'config'));
p = w5s3_params();
if nargin < 2, stageIds = {p.s3.stages.id}; end
mdlDir = fullfile(here, '..', 'models');
outRoot = fullfile(here, '..', 'matlab_results');
if ~exist(outRoot, 'dir'), mkdir(outRoot); end

fprintf('===== W5S3 RUN (MaxStep 인덱스 %s, 단계 %s) =====\n', mat2str(idx), strjoin(stageIds, ','));
for si = 1:numel(p.s3.stages)
    st = p.s3.stages(si);
    if ~ismember(st.id, stageIds), continue; end
    outDir = fullfile(outRoot, st.dir);
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    fid = fopen(fullfile(outDir, 'matlab_settings.txt'), 'w');
    fprintf(fid, '%s MATLAB %s | Simulink 가변 스텝 solver=%s RelTol=%s AbsTol=%s | MaxStep=%s\n', st.id, version, p.solver, p.reltol, p.abstol, mat2str(p.s3.maxsteps(idx)));
    fprintf(fid, '위치 루프 %g s, 전류 루프 %g s, 로그 간격 위치 %g s / 전기 %g s, 로컬 솔버 사용 안 함\n', p.Ts, p.cur.Ts, p.log_dt, p.cur.Ts);
    fprintf(fid, '기어: 이상 기어비 N=%g (모터 속도 = N*관절 속도), 효율 100%%, 마찰/백래시/탄성 없음, 양의 방향 동일. Simscape 기어 블록 미사용(수식 구현)이므로 숨은 관성·마찰 없음.\n', p.gear.N);
    fprintf(fid, '관성: 링크 관절 축 관성 %.10g + 관절 환산 회전자 관성 %.10g = %.10g kg*m^2 (방식 A만 적용, 방식 B 미사용). 감쇠 %.3g는 관절에서 한 번만.\n', ...
        p.link.J_joint, st.Jred, p.link.J_joint + st.Jred, p.damping);
    fprintf(fid, '- 위치 루프(1 ms): tau* = Kp(qref-q) - Kd*qdot (관절 각도/속도), iq_raw = tau*/(N*Kt), iq* = clip(iq_raw, +-2 A), id* = 0\n');
    fprintf(fid, '- 전류 루프(100 us): 모터 속도 wm = N*qdot, we = pp*wm. 병렬형 PI v = Kpi*e + I + ff, ff_d = -we*L*iq, ff_q = we*(L*id+psi). 벡터 전압 제한 Vdc/sqrt(3), 역계산 안티윈드업 Kaw=%g\n', p.cur.Kaw);
    fprintf(fid, '- PMSM dq 방정식 연속시간 적분, 모터 토크 Tm = Kt*iq, 관절 입력 토크 Tj = N*Tm\n\n');

    fprintf('\n################ %s (%s) ################\n', st.id, st.name);
    %% 기어 단독 검사
    chk = [st.name '_gearcheck'];
    load_system(fullfile(mdlDir, [chk '.slx']));
    so = sim(chk, 'ReturnWorkspaceOutputs', 'on');
    ts = so.get('w5s3_chk'); t = ts.Time(:); w = squeeze(ts.Data); w = w(:);
    Tj = p.s3.chk_Tj; b = p.damping;
    J_exp = p.link.J_joint + st.Jred;
    [~, ik] = min(abs(t - 0.01));
    Jest = -b * t(ik) / log(1 - w(ik) * b / Tj);        % qd(t) = (Tj/b)(1-exp(-b t/J)) 로부터 총관성 추정
    a0 = Tj / Jest;
    fprintf('  [기어 단독 검사] 모터 토크 %.3f -> 관절 입력 %.3f N*m | 추정 총관성 %.10f (기대 %.10f) | 초기 가속도 %.9f rad/s^2 (기대 %.9f)\n', ...
        p.s3.chk_Tm, Tj, Jest, J_exp, a0, Tj / J_exp);
    fprintf(fid, '기어 단독 검사: 모터 0.02 -> 관절 %.3f N*m, 추정 총관성 %.10f (기대 %.10f), 초기 가속도 %.9f (기대 %.9f) rad/s^2\n', Tj, Jest, J_exp, a0, Tj / J_exp);
    close_system(chk, 0);

    %% 통합 3 사례
    mdl = st.name;
    load_system(fullfile(mdlDir, [mdl '.slx']));
    for c = 1:numel(p.s3.cases)
        cs = p.s3.cases(c);
        fprintf('\n##### %s %s : 목표 %g rad, Vdc = %g V (전압 한계 %.4f V) #####\n', st.id, cs.name, cs.target, cs.V, p.vmax(cs.V));
        res = cell(1, numel(idx));
        for k = 1:numel(idx)
            res{k} = runJoint(mdl, p, st, cs, idx(k), outDir, fid);
        end
        for k = 2:numel(idx)
            fprintf('  수렴: MaxStep %g vs %g : max|dq| = %.3e rad, max|diq| = %.3e A\n', ...
                p.s3.maxsteps(idx(k)), p.s3.maxsteps(idx(1)), max(abs(res{k}.q - res{1}.q)), max(abs(res{k}.iq - res{1}.iq)));
            fprintf(fid, '%s convergence MaxStep %g vs %g: max|dq|=%.3e max|diq|=%.3e\n', cs.name, ...
                p.s3.maxsteps(idx(k)), p.s3.maxsteps(idx(1)), max(abs(res{k}.q - res{1}.q)), max(abs(res{k}.iq - res{1}.iq)));
        end
    end
    close_system(mdl, 0);
    fclose(fid);
    fprintf('\n[OK] %s 결과: %s\n', st.id, outDir);
end
fprintf('\n===== W5S3 RUN 끝 =====\n');
end

%% ---------------- 로컬 함수 ----------------
function res = runJoint(mdl, p, st, cs, r, outDir, fid)
    N = p.gear.N;
    set_param([mdl '/Ref_Step'], 'After', num2str(cs.target, 12));
    set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(cs.V), 12));
    set_param(mdl, 'MaxStep', num2str(p.s3.maxsteps(r)));
    tic; simOut = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
    [t1, P] = getlog(simOut, 'w5s3_plog', 5);    % ref q qd tau_cmd tau_joint
    [t2, E] = getlog(simOut, 'w5s3_elog', 16);   % iq_ref id iq vd_cmd vq_cmd vd_sat vq_sat sat wm tm | target q qd tau_cmd tau_joint iq_raw
    tag = p.s3.tags{r};
    writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,4), P(:,5), 'VariableNames', ...
        {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','actual_torque_Nm'}), ...
        fullfile(outDir, [cs.name '_position' tag '.csv']));
    n = numel(t2);
    vmag = hypot(E(:,6), E(:,7));
    % 전기 CSV: 이민혁 MuJoCo CSV와 같은 열 이름 (3-3 비교 도구 필수 열 포함). PI 적분 상태 열은 내보내지 않음.
    curlim = double(abs(E(:,16)) > p.cur.iq_lim);
    writetable(table(t2, E(:,11), E(:,12), E(:,13), E(:,14), E(:,15), zeros(n,1), E(:,1), E(:,16), E(:,2), E(:,3), E(:,4), E(:,5), E(:,6), E(:,7), vmag, repmat(p.vmax(cs.V), n, 1), E(:,10), curlim, E(:,8), E(:,9), repmat(N, n, 1), repmat(p.link.J_joint + st.Jred, n, 1), 'VariableNames', ...
        {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','actual_torque_Nm','id_reference_A','iq_reference_A','iq_raw_reference_A','id_A','iq_A','vd_raw_V','vq_raw_V','vd_V','vq_V','voltage_magnitude_V','voltage_limit_V','motor_torque_Nm','current_reference_limited','voltage_limited','motor_speed_rad_s','gear_ratio','effective_joint_inertia_kg_m2'}), ...
        fullfile(outDir, [cs.name '_electrical' tag '.csv']));

    q = P(:,2); qd = P(:,3);
    w = t1 >= 0.2 - 1e-9 & t1 <= 2.0 + 1e-9;
    rmse = sqrt(mean((q(w) - P(w,1)).^2));
    band = 0.02 * cs.target;
    after = find(t1 >= 0.2 - 1e-9);
    last = find(abs(q(after) - cs.target) > band, 1, 'last');
    if isempty(last), ts = 0; elseif last == numel(after), ts = NaN; else, ts = t1(after(last + 1)) - 0.2; end
    satIdx = find(E(:,8) > 0.5);
    if isempty(satIdx), satInfo = '포화 없음'; else, satInfo = sprintf('포화 구간 %.4f ~ %.4f s (%.1f%% 시간)', t2(satIdx(1)), t2(satIdx(end)), 100*numel(satIdx)/numel(t2)); end
    [~, i02p] = min(abs(t1 - 0.2)); [~, i02] = min(abs(t2 - 0.2));
    fprintf('  MaxStep %g (%.1f s) | 행 위치 %d (기대 2001), 전기 %d (기대 20001)\n', p.s3.maxsteps(r), el, numel(t1), numel(t2));
    fprintf('    첫 요구 토크 %.6f N*m | iq_ref(0.2s) %.4f A | 최대 iq %.4f A | 최대 관절 입력 토크 %.4f N*m | 최대 모터속도 %.4f rad/s\n', ...
        P(i02p,4), E(i02,1), max(E(:,3)), max(abs(P(:,5))), max(abs(E(:,9))));
    fprintf('    %s | 최종 각도 %.6f rad | 정착(±%.4f) %.3f s | 추종 RMSE %.6f rad\n', satInfo, q(end), band, ts, rmse);
    fprintf(fid, '%s MaxStep %g: tau*(0.2)=%.6f iq_ref(0.2)=%.4f iqmax=%.4f q_end=%.6f ts=%.3f rmse=%.6f %s\n', cs.name, p.s3.maxsteps(r), P(i02p,4), E(i02,1), max(E(:,3)), q(end), ts, rmse, satInfo);
    res.q = q; res.iq = E(:,3);
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
end
