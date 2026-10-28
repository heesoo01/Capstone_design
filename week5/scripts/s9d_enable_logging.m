%% S9D_ENABLE_LOGGING
% 모든 Simscape 블록의 LogSimulationData를 on으로 켜서 Mechanics Explorer
% 애니메이션이 재생되게 한다. (.slx XML을 직접 열어서 확인한 결과, 전부 off였음)
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9d_enable_logging

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9d: 모든 블록 LogSimulationData 켜기 =====\n\n');

allBlocks = find_system(mdl, 'LookUnderMasks', 'all');
count = 0;
for i = 1:numel(allBlocks)
    b = allBlocks{i};
    try
        if isfield(get_param(b, 'ObjectParameters'), 'LogSimulationData')
            set_param(b, 'LogSimulationData', 'on');
            fprintf('[OK] %s\n', b);
            count = count + 1;
        end
    catch
        % LogSimulationData 파라미터가 없는 블록(Simulink 일반 블록 등)은 건너뜀
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

fprintf('\n===== S9d 끝. Mechanics Explorer 다시 확인해달라. =====\n');
