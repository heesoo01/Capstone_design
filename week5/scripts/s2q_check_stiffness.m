%% S2Q_CHECK_STIFFNESS
% backlash_stiffness/backlash_damping 등이 0이나 이상한 값이라 초기화가
% 안 되는 건지 확인.
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2q_check_stiffness

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

gb = [mdl '/Gearbox'];

fprintf('===== S2q: 백래시 강성/감쇠 확인 =====\n\n');

fields_to_check = {'backlash_stiffness', 'backlash_damping', 'coeff_rest', ...
                    'hardstop_model', 'efficiency_nom', 'efficiency', 'mu_visc'};
for i = 1:numel(fields_to_check)
    name = fields_to_check{i};
    try
        val = get_param(gb, name);
        unitFieldName = [name '_unit'];
        try
            unit = get_param(gb, unitFieldName);
        catch
            unit = '';
        end
        fprintf('  %-22s = %s %s\n', name, val, unit);
    catch ME
        fprintf('  %-22s : [조회 실패] %s\n', name, ME.message);
    end
end

fprintf('\n===== 끝 =====\n');
