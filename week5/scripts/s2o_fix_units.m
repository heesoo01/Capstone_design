%% S2O_FIX_UNITS
% backlash_distance를 deg로 바꾼 것과 짝이 맞아야 하는 다른 길이/각도 파라미터
% (transition, r_base 등)의 단위를 확인하고 일관되게 맞춘다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2o_fix_units

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

gb = [mdl '/Gearbox'];

fprintf('===== S2o: 단위 일관성 확인 =====\n\n');

unit_fields = {'backlash_distance', 'transition', 'r_base'};
for i = 1:numel(unit_fields)
    name = unit_fields{i};
    try
        val = get_param(gb, name);
        unit = get_param(gb, [name '_unit']);
        fprintf('  %-20s = %s %s\n', name, val, unit);
    catch ME
        fprintf('  %-20s : [조회 실패] %s\n', name, ME.message);
    end
end

fprintf('\n--- transition_unit을 deg로 맞추기 ---\n');
try
    set_param(gb, 'transition_unit', 'deg');
    fprintf('[OK] transition_unit = deg\n');
    fprintf('     현재 transition 값: %s\n', get_param(gb, 'transition'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
set_param(mdl, 'StopTime', '3');

fprintf('\n--- Test A: 토크 0 ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '0');
    sim(mdl);
    fprintf('[OK] Test A 성공!\n');
catch ME
    fprintf('[실패]:\n');
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S2o 끝 =====\n');
