function w6c_run(t_end, tag)
%W6C_RUN Simulink(전기·제어, MATLAB) <-> MuJoCo(기계, py.mujoco 3.14.0) 연동 시험 실행
%   w6c_run(2, 'main') : 24 V, 0.3 rad, 2 s (5주차 3-2 / 4-3 평균 모델과 같은 조건) -> week6\matlab_results\cosim\main_*.csv
%   w6c_run(0.3, 'quick') : 짧은 동작 확인
% 기대: Simscape 기계부를 MuJoCo 로 바꿔도 결과가 같아야 한다. 비교는 w6c_compare.py.
if nargin < 1, t_end = 2; end
if nargin < 2, tag = 'main'; end
here = fileparts(mfilename('fullpath'));
addpath(here);
w6 = fullfile(here, '..', '..');
addpath(fullfile(w6, 'config'));
p = w6s43_params();
outDir = fullfile(w6, 'matlab_results', 'cosim');
if ~exist(outDir, 'dir'), mkdir(outDir); end
mdl = 'w6_cosim_mujoco';
load_system(fullfile(w6, 'models', [mdl '.slx']));
set_param([mdl '/Ref_Step'], 'Time', num2str(0.2 - p.Ts / 2, 12), 'After', '0.3');
set_param([mdl '/Cvmax'], 'Value', num2str(p.vmax(24), 12));
set_param(mdl, 'StopTime', num2str(t_end, 12));
set_param(mdl, 'MaxStep', '25e-6');
fprintf('===== W6C RUN (%s): t_end %g s, 24 V, 0.3 rad, solver=%s RelTol=%s AbsTol=%s MaxStep 25e-6 =====\n', tag, t_end, p.solver, p.reltol, p.abstol);
tic; so = sim(mdl, 'ReturnWorkspaceOutputs', 'on'); el = toc;
[t1, P] = getlog(so, 'w5s3_plog', 5);
[t2, E] = getlog(so, 'w5s3_elog', 16);
names = {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','postgear_electromagnetic_torque_Nm', ...
    'id_reference_A','iq_reference_A','iq_raw_reference_A','id_A','iq_A','vd_raw_V','vq_raw_V','vd_command_V','vq_command_V', ...
    'motor_torque_Nm','motor_speed_rad_s','voltage_command_limited'};
M = [t2, E(:,11), E(:,12), E(:,13), E(:,14), E(:,15), zeros(numel(t2),1), E(:,1), E(:,16), E(:,2), E(:,3), E(:,4), E(:,5), E(:,6), E(:,7), E(:,10), E(:,9), E(:,8)];
writetable(array2table(M, 'VariableNames', names), fullfile(outDir, [tag '_electrical_100us.csv']));
writetable(table(t1, P(:,1), P(:,2), P(:,3), P(:,4), P(:,5), 'VariableNames', ...
    {'time_s','target_rad','angle_rad','velocity_rad_s','command_torque_Nm','postgear_electromagnetic_torque_Nm'}), fullfile(outDir, [tag '_position_1ms.csv']));
fprintf('  %.1f s (벽시계) | 행: 위치 %d, 전기 %d | 최종 각도 %.6f rad | 최대 iq %.4f A | 전압 제한 %d\n', el, numel(t1), numel(t2), P(end,2), max(E(:,3)), sum(E(:,8) > 0.5));
fid = fopen(fullfile(outDir, 'matlab_settings.txt'), 'a');
fprintf(fid, '%s %s MATLAB %s: Simulink(PMSM dq + 전류 PI + 위치 PD, ode23t RelTol 1e-6 AbsTol 1e-9 MaxStep 25e-6) + MATLAB System 블록 -> py.mujoco 3.14.0 (물리 25 us, implicitfast). t_end %g wall %.1f s q_end %.6f\n', ...
    datestr(now, 'yyyy-mm-dd HH:MM:SS'), tag, version, t_end, el, P(end,2));
fclose(fid);
close_system(mdl, 0);
end

function [t, D] = getlog(simOut, name, nc)
    ts = simOut.get(name);
    t = ts.Time(:);
    D = squeeze(ts.Data);
    if size(D, 2) ~= nc && size(D, 1) == nc, D = D.'; end
    if size(D, 2) ~= nc, error('로그 %s 의 열 수가 %d 가 아니다 (실제 %s)', name, nc, mat2str(size(D))); end
end
