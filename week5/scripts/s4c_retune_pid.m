%% S4C_RETUNE_PID
% PID 게인이 너무 커서(기어비 50배 증폭까지 겹침) 발산한 것으로 보임.
% 게인을 크게 낮춰서 재시도 (placeholder, 나중에 제대로 튜닝 필요).
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s4c_retune_pid

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

pid = [mdl '/PID Controller'];

fprintf('===== S4c: PID 게인 낮춰서 재시도 =====\n\n');

try
    set_param(pid, 'P', '0.05');
    set_param(pid, 'I', '0.01');
    set_param(pid, 'D', '0.005');
    fprintf('[OK] Kp=0.05, Ki=0.01, Kd=0.005 (훨씬 작게, placeholder)\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '3');

fprintf('\n--- 시뮬레이션 ---\n');
try
    sim(mdl);
    fprintf('[OK] 성공!\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n===== S4c 끝. 성공하면 Scope 스크린샷(현재각 궤적) 보내달라. =====\n');
