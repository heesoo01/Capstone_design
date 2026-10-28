%% S4B_CHECK_UNITS_RUN
% Sense1 PS2S(위치 센싱 변환기)의 출력 단위를 확인/맞추고, PID 제어 시뮬레이션 실행.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s4b_check_units_run

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

s1ps = [mdl '/Sense1 PS2S'];

fprintf('===== S4b: 단위 확인 + 시뮬레이션 =====\n\n');

dp = get_param(s1ps, 'DialogParameters');
fprintf('--- Sense1 PS2S 파라미터 목록 ---\n');
disp(fieldnames(dp));

unitFields = fieldnames(dp);
unitFields = unitFields(contains(unitFields, 'unit', 'IgnoreCase', true));
for i = 1:numel(unitFields)
    name = unitFields{i};
    try
        fprintf('%s = %s\n', name, get_param(s1ps, name));
    catch ME
        fprintf('%s : 조회 실패 (%s)\n', name, ME.message);
    end
end

% 'deg'로 맞춰보기 (단위 파라미터 이름 후보)
candNames = {'SignalUnit', 'unit', 'Unit', 'OutputUnit'};
fixed = false;
for i = 1:numel(candNames)
    if isfield(dp, candNames{i})
        try
            set_param(s1ps, candNames{i}, 'deg');
            fprintf('\n[OK] %s = deg 로 설정\n', candNames{i});
            fixed = true;
        catch ME
            fprintf('\n[실패] %s=deg : %s\n', candNames{i}, ME.message);
        end
        break;
    end
end
if ~fixed
    fprintf('\n[정보] 단위 파라미터 이름을 못 찾음. 위 전체 목록에서 직접 찾아봐야 함.\n');
end

save_system(mdl);
set_param(mdl, 'StopTime', '3');

fprintf('\n--- PID 제어 시뮬레이션 실행 ---\n');
try
    sim(mdl);
    fprintf('[OK] 성공!\n');
catch ME
    fprintf('[실패]: %s\n', ME.message);
end

fprintf('\n===== S4b 끝. 성공했으면 Scope 스크린샷 보내달라. =====\n');
