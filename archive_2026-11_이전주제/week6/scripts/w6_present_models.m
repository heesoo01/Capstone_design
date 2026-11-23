%% W6_PRESENT_MODELS
% 발표 캡처용: 4단계 모델(4-1 마찰, 4-2 백래시, 4-3 PWM, 4-4 열)의 블록을 기능별 서브시스템으로 묶고 자동 배치한 사본을 만든다.
% 원본 모델(models/*.slx)은 수정하지 않고, models/present/ 아래에 *_present.slx 로 저장한다. (5주차 w5_present_models.m 과 같은 방식)
% 그림용 사본이라 로깅 블록(Mux, To Workspace, 에너지 적분 등)은 지운다. 이 사본으로는 시뮬레이션 결과를 저장하지 않는다.
% 서브시스템: Position_PD, Current_PI_FF, Voltage_Limit, PMSM_dq, Gear (5주차와 같음) + 단계별 추가 서브시스템
%   4-1 Reference, Friction_Simscape / 4-2 Reference / 4-3 PWM_Inverter / 4-4 Thermal_Node
here = fileparts(mfilename('fullpath'));
mdlDir = fullfile(here, '..', 'models');
outDir = fullfile(mdlDir, 'present'); if ~exist(outDir, 'dir'), mkdir(outDir); end
shotDir = fullfile(here, '..', 'results', 'slides'); if ~exist(shotDir, 'dir'), mkdir(shotDir); end

base = {
 'Position_PD',    {'ZOH_ref','ZOH_q','ZOH_qd','PErr','PKp','PKd','PTau','PInvKt','PSat'}
 'Current_PI_FF',  {'ZOH_id','ZOH_iq','ZOH_wm','ZOH_iqref','Gwe_s','Ged','CEq','Pffd','Gffd','GLid','Cpsi','SffA','Pffq','GKpd','GKpq','UDd','UDq','Svd','Svq','GKid','GKiq','Sud','Suq','GTsd','GTsq','SIdn','SIqn'}
 'Voltage_Limit',  {'Pvd2','Pvq2','Snorm','Rsq','Ceps','Mxn','Cvmax','Dv','C1','Mns','Pvds','Pvqs','SDd','SDq','GKawd','GKawq','Rsat','Dsat'}
 'PMSM_dq',        {'Gwe','GvdL','GvqL','GRLd','GRLq','GpsiL','Pwi','Pwd','Sdid','Sdiq','Int_id','Int_iq','Gtau'}
 'Gear',           {'GwmN','GNt'}
};
logBase = {'PMux','PLog','EMux','ELog','ZOH_Eref','ZOH_Etc','ZOH_Eraw'};

cfg(1).m = 'w6_stage4_1_joint';
cfg(1).extra = {'Reference', {'Ref_Step','XStepB','XSine','XEnS','XPs','XRsum'}; ...
                'Friction_Simscape', {'XSC','XREF1','XREF2','XWS','XRF','XTS','XS2PSw','XPS2Stf','XFen','XPf'}};
cfg(1).logs = {'XMux','XLog'};
cfg(2).m = 'w6_stage4_2_joint';
cfg(2).extra = {'Reference', {'Ref_Step','XStepB','XStepC','XSine','XEnS','XPs','XRsum'}};
cfg(2).logs = {'XMux','XLog'};
cfg(3).m = 'w6_stage4_3_pwm';
cfg(3).extra = {'PWM_Inverter', {}};      % X* 블록 중 로그를 뺀 나머지를 아래에서 채운다
cfg(3).logs = {'XMux','XLog','XIMux','XILog','XIid','XIiq','XIva','XIvb','XIvc'};
cfg(4).m = 'w6_stage4_4_joint';
cfg(4).extra = {'Thermal_Node', {}};
cfg(4).logs = {'XMux','XLog','XPvd','XPvq','XPvs','XPin','XEin','XQd2','XPvis','XEvis','XPmech','XEmech','XU','XKe'};

for k = 1:numel(cfg)
    m = cfg(k).m;
    fprintf('\n===== %s =====\n', m);
    load_system(fullfile(mdlDir, [m '.slx']));
    for nm = [logBase, cfg(k).logs]
        if getSimulinkBlockHandle([m '/' nm{1}]) ~= -1, delete_block([m '/' nm{1}]); end
    end
    ln = find_system(m, 'SearchDepth', 1, 'FindAll', 'on', 'Type', 'line');
    for i = 1:numel(ln)
        try
            sb = get_param(ln(i), 'SrcBlockHandle'); db = get_param(ln(i), 'DstBlockHandle');
            if isempty(db) || all(db == -1) || sb == -1, delete_line(ln(i)); end
        catch
        end
    end
    groups = base;
    if k == 1 || k == 2
        groups = [cfg(k).extra; groups];       % Reference 먼저 (Ref_Step 이 Reference 에 들어가므로)
    end
    % 4-3, 4-4: 새로 추가한 X* 블록을 한 서브시스템으로
    if k == 3 || k == 4
        allb = find_system(m, 'SearchDepth', 1, 'Type', 'Block');
        names = cellfun(@(s) strrep(s, [m '/'], ''), allb, 'UniformOutput', false);
        isX = startsWith(names, 'X');
        keep = names(isX);
        if k == 4
            % 저항 곱셈(XPRd, XPRq)은 PMSM 식 옆에 둔다
            keep = setdiff(keep, {'XPRd', 'XPRq'});
        end
        cfg(k).extra{1, 2} = keep(:)';
        groups = [groups; cfg(k).extra];
    end
    used = {};
    for g = 1:size(groups, 1)
        nms = setdiff(groups{g, 2}, used, 'stable');
        hs = [];
        for i = 1:numel(nms)
            p = [m '/' nms{i}];
            if getSimulinkBlockHandle(p) ~= -1, hs(end+1) = get_param(p, 'Handle'); end %#ok<AGROW>
        end
        if isempty(hs), continue; end
        try
            Simulink.BlockDiagram.createSubsystem(hs, 'Name', groups{g, 1});
            used = [used, nms(:)']; %#ok<AGROW>
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
