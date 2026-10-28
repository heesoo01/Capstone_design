%% S9E_ENABLE_LOGGING_V2
% 모든 블록에 직접 set_param 시도해서 LogSimulationData를 켠다 (실패하는 건
% 그냥 그 파라미터가 없는 블록이니 넘어감).
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9e_enable_logging_v2

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9e: LogSimulationData 켜기 (v2) =====\n\n');

allBlocks = find_system(mdl, 'LookUnderMasks', 'all', 'Type', 'block');
count = 0;
for i = 1:numel(allBlocks)
    b = allBlocks{i};
    try
        set_param(b, 'LogSimulationData', 'on');
        fprintf('[OK] %s\n', b);
        count = count + 1;
    catch
        % 파라미터 없는 블록은 조용히 넘어감
    end
end

fprintf('\n총 %d개 블록 로깅 켬\n', count);

save_system(mdl);
set_param(mdl, 'StopTime', '8');

fprintf('\n--- 다시 시뮬레이션 ---\n');
try
    sim(mdl);
    fprintf('[OK] 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n===== S9e 끝. Mechanics Explorer 새로 열어서 확인해달라. =====\n');
