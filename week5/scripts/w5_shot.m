% 발표용 Simulink 모델 화면 캡처 (모델 구조도 PNG)
here = fileparts(mfilename('fullpath'));
out = fullfile(here, '..', 'results', 'slides');
if ~exist(out, 'dir'), mkdir(out); end
mdlDir = fullfile(here, '..', 'models');
list = {'w5_stage3_2_joint', 'w5_stage2_pmsm_joint'};
for k = 1:numel(list)
    m = list{k};
    load_system(fullfile(mdlDir, [m '.slx']));
    try
        print(['-s' m], '-dpng', '-r200', fullfile(out, [m '_diagram.png']));
        fprintf('[OK] %s\n', m);
    catch ME
        fprintf('[실패] %s: %s\n', m, ME.message);
    end
    close_system(m, 0);
end
