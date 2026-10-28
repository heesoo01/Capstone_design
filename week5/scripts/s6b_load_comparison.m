%% S6B_LOAD_COMPARISON
% 동적 질량 변화 대신(안 되는 것 확인됨), No Load vs Load 두 모델 비교로 대체.
% config/params.m: link_mass=0.5, end_mass_loaded=0.2 -> 부하 시 0.7kg
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s6b_load_comparison

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

li = [mdl '/LinkInertia'];

fprintf('===== S6b: No Load vs Load 비교 =====\n\n');

% Mass_conf 되돌리기
try
    set_param(li, 'Mass_conf', 'compiletime');
    fprintf('[OK] Mass_conf = compiletime (되돌림)\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '8');

%% No Load
fprintf('\n--- No Load (mass=%.2fkg) 시뮬레이션 ---\n', p.mech.link_mass);
try
    set_param(li, 'Mass', num2str(p.mech.link_mass));
    simOutNoLoad = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    fprintf('[OK] 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

%% Load
loadedMass = p.mech.link_mass + p.mech.end_mass_loaded;
fprintf('\n--- Load (mass=%.2fkg) 시뮬레이션 ---\n', loadedMass);
try
    set_param(li, 'Mass', num2str(loadedMass));
    simOutLoad = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    fprintf('[OK] 완료\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

% 원래 No Load로 되돌려 저장 (기본 상태 유지)
set_param(li, 'Mass', num2str(p.mech.link_mass));
save_system(mdl);

fprintf('\n===== S6b 끝 =====\n');
fprintf('Scope는 마지막(Load) 결과만 보여줄 거라, Load 상태 스크린샷 먼저 보내주고,\n');
fprintf('그 다음 No Load로 한 번 더 돌려서(아래 명령) 비교해보자:\n');
fprintf('  set_param(''%s'', ''Mass'', ''%.2f''); sim(''%s'')\n', li, p.mech.link_mass, mdl);
