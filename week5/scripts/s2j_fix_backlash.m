%% S2J_FIX_BACKLASH
% enable_backlash의 실제 Type/Enum을 확인하고 올바른 값으로 설정.
% backlash_distance_unit을 'deg'로 바꿀 수 있는지 확인 후 각도로 직접 설정.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2j_fix_backlash

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

gb = [mdl '/Gearbox'];
dpG = get_param(gb, 'DialogParameters');

fprintf('===== S2j: 백래시 파라미터 정정 =====\n\n');

fprintf('--- enable_backlash 상세 ---\n');
disp(dpG.enable_backlash);
fprintf('현재값: %s\n', get_param(gb, 'enable_backlash'));

fprintf('\n--- backlash_distance_unit 상세 ---\n');
disp(dpG.backlash_distance_unit);
fprintf('현재값: %s\n', get_param(gb, 'backlash_distance_unit'));

%% enable_backlash: Enum에서 'on' 비슷한 값 찾아서 설정
if isfield(dpG.enable_backlash, 'Enum') && ~isempty(dpG.enable_backlash.Enum)
    onIdx = find(contains(dpG.enable_backlash.Enum, 'on', 'IgnoreCase', true) & ...
                 ~contains(dpG.enable_backlash.Enum, 'off', 'IgnoreCase', true), 1);
    if ~isempty(onIdx)
        onVal = dpG.enable_backlash.Enum{onIdx};
        try
            set_param(gb, 'enable_backlash', onVal);
            fprintf('\n[OK] enable_backlash = %s\n', onVal);
        catch ME
            fprintf('\n[실패] enable_backlash 설정: %s\n', ME.message);
        end
    else
        fprintf('\n[실패] Enum에서 on 비슷한 값을 못 찾음: %s\n', strjoin(dpG.enable_backlash.Enum, ' / '));
    end
else
    fprintf('\n[정보] enable_backlash는 Enum이 없는 타입(%s). true/1 시도\n', dpG.enable_backlash.Type);
    try
        set_param(gb, 'enable_backlash', 'true');
        fprintf('[OK] enable_backlash = true\n');
    catch ME
        fprintf('[실패] %s\n', ME.message);
    end
end

%% backlash_distance_unit을 deg로
try
    set_param(gb, 'backlash_distance_unit', 'deg');
    fprintf('\n[OK] backlash_distance_unit = deg\n');
    set_param(gb, 'backlash_distance', num2str(p.gear.backlash_deg));
    fprintf('[OK] backlash_distance = %g deg\n', p.gear.backlash_deg);
catch ME
    fprintf('\n[실패] backlash_distance 단위/값 설정: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 재시뮬레이션
set_param(mdl, 'StopTime', '3');

fprintf('--- Test A: 토크 0 ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '0');
    sim(mdl);
    fprintf('[OK] Test A 완료\n');
catch ME
    fprintf('[실패] Test A: %s\n', ME.message);
end

fprintf('\n--- Test B: 토크 5 N*m ---\n');
try
    set_param([mdl '/Motor Torque Command'], 'Value', '5');
    sim(mdl);
    fprintf('[OK] Test B 완료\n');
catch ME
    fprintf('[실패] Test B: %s\n', ME.message);
end

fprintf('\n===== S2j 끝 =====\n');
