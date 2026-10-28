%% W5_PRESENT_MODELS
% 발표 캡처용: 2·3단계 통합 모델의 블록을 기능별 서브시스템으로 묶고 자동 배치한 사본을 만든다.
% 원본 모델(models/*.slx)은 수정하지 않고, models/present/ 아래에 *_present.slx 로 저장한다.
% 서브시스템: Position_PD, Current_PI_FF, Voltage_Limit, PMSM_dq, Gear(3단계만). 기계(Simscape) 블록은 최상위에 그대로 둔다.
% 그림용 사본이라 로깅 블록(Mux, To Workspace 등)은 지운다. 이 사본으로는 시뮬레이션 결과를 저장하지 않는다.
here = fileparts(mfilename('fullpath'));
mdlDir = fullfile(here, '..', 'models');
outDir = fullfile(mdlDir, 'present'); if ~exist(outDir, 'dir'), mkdir(outDir); end
shotDir = fullfile(here, '..', 'results', 'slides'); if ~exist(shotDir, 'dir'), mkdir(shotDir); end

groups = {
 'Position_PD',    {'Ref_Step','ZOH_ref','ZOH_q','ZOH_qd','PErr','PKp','PKd','PTau','PInvKt','PSat'}
 'Current_PI_FF',  {'ZOH_id','ZOH_iq','ZOH_wm','ZOH_iqref','Gwe_s','Ged','CEq','Pffd','Gffd','GLid','Cpsi','SffA','Pffq','GKpd','GKpq','UDd','UDq','Svd','Svq','GKid','GKiq','Sud','Suq','GTsd','GTsq','SIdn','SIqn'}
 'Voltage_Limit',  {'Pvd2','Pvq2','Snorm','Rsq','Ceps','Mxn','Cvmax','Dv','C1','Mns','Pvds','Pvqs','SDd','SDq','GKawd','GKawq','Rsat','Dsat'}
 'PMSM_dq',        {'Gwe','GvdL','GvqL','GRLd','GRLq','GpsiL','Pwi','Pwd','Sdid','Sdiq','Int_id','Int_iq','Gtau'}
 'Gear',           {'GwmN','GNt'}
};
list = {'w5_stage3_2_joint', 'w5_stage2_pmsm_joint'};
for k = 1:numel(list)
    m = list{k};
    load_system(fullfile(mdlDir, [m '.slx']));
    logNames = {'PMux','PLog','EMux','ELog','ZOH_Eref','ZOH_Etc','ZOH_Eraw'};
    for i = 1:numel(logNames)
        if getSimulinkBlockHandle([m '/' logNames{i}]) ~= -1, delete_block([m '/' logNames{i}]); end
    end
    ln = find_system(m, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'line');
    for i = 1:numel(ln)
        try
            sb = get_param(ln(i), 'SrcBlockHandle'); db = get_param(ln(i), 'DstBlockHandle');
            if isempty(db) || all(db == -1) || sb == -1, delete_line(ln(i)); end
        catch
        end
    end
    for g = 1:size(groups, 1)
        names = groups{g, 2};
        hs = [];
        for i = 1:numel(names)
            p = [m '/' names{i}];
            if getSimulinkBlockHandle(p) ~= -1, hs(end+1) = get_param(p, 'Handle'); end %#ok<AGROW>
        end
        if isempty(hs), continue; end
        try
            Simulink.BlockDiagram.createSubsystem(hs, 'Name', groups{g, 1});
            fprintf('[OK] %s: %s (%d 블록)\n', m, groups{g, 1}, numel(hs));
        catch ME
            fprintf('[실패] %s: %s : %s\n', m, groups{g, 1}, ME.message);
        end
    end
    try
        Simulink.BlockDiagram.arrangeSystem(m);
    catch ME
        fprintf('[경고] arrangeSystem 실패: %s\n', ME.message);
    end
    try
        print(['-s' m], '-dpng', '-r170', fullfile(shotDir, [m '_present.png']));
        fprintf('[OK] 캡처 %s\n', [m '_present.png']);
    catch ME
        fprintf('[실패] 캡처: %s\n', ME.message);
    end
    save_system(m, fullfile(outDir, [m '_present.slx']));   % 다른 이름으로 저장(원본 .slx는 건드리지 않음)
    close_system([m '_present'], 0);
end
