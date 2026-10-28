%% S6_DYNAMIC_MASS
% LinkInertia의 Mass_conf를 runtime으로 바꿔서 시뮬레이션 도중 질량을
% 바꿀 수 있는 포트가 생기는지 확인 (동적 부하변화 테스트).
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s6_dynamic_mass

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

li = [mdl '/LinkInertia'];

fprintf('===== S6: 동적 질량 변화 테스트 =====\n\n');

fprintf('--- 변경 전 포트 구성 ---\n');
hBefore = get_param(li, 'PortHandles');
disp(hBefore);

dp = get_param(li, 'DialogParameters');
fprintf('--- Mass_conf 상세 ---\n');
disp(dp.Mass_conf);
fprintf('현재값: %s\n\n', get_param(li, 'Mass_conf'));

try
    set_param(li, 'Mass_conf', 'runtime');
    fprintf('[OK] Mass_conf = runtime\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- 변경 후 포트 구성 ---\n');
try
    hAfter = get_param(li, 'PortHandles');
    disp(hAfter);
    fn = fieldnames(hAfter);
    for i = 1:numel(fn)
        fprintf('  %s : %d개\n', fn{i}, numel(hAfter.(fn{i})));
    end
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
fprintf('\n===== S6 1단계 끝. 포트가 새로 생겼는지 알려달라. =====\n');
