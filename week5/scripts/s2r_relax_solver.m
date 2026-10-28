%% S2R_RELAX_SOLVER
% Solver Configuration의 허용오차 관련 파라미터를 확인하고 완화해서 재시도.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2r_relax_solver

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

sc = [mdl '/SolverConfiguration'];

fprintf('===== S2r: Solver Configuration 허용오차 확인 =====\n\n');

dpSC = get_param(sc, 'DialogParameters');
fn = fieldnames(dpSC);
fprintf('--- 전체 파라미터 이름 ---\n');
disp(fn);

% tolerance/consistency 관련 이름 찾기
cand = fn(contains(fn, {'toler', 'Toler', 'consist', 'Consist', 'Relax', 'relax'}));
fprintf('\n--- tolerance/consistency 관련 후보 ---\n');
for i = 1:numel(cand)
    name = cand{i};
    try
        fprintf('[%s]\n', name);
        disp(dpSC.(name));
        fprintf('현재값: %s\n\n', mat2str(get_param(sc, name)));
    catch ME
        fprintf('  조회 실패: %s\n\n', ME.message);
    end
end

fprintf('===== 끝. 이 출력 보고 다음 스크립트에서 실제로 완화할 것. =====\n');
