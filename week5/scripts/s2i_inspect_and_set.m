%% S2I_INSPECT_AND_SET
% Simple Gear / Rotational Friction 파라미터를 config/params.m 값으로 설정.
% friction_model enum만 먼저 출력해서 "마찰 없음" 옵션을 찾고(이미 JointFriction이
% 따로 있으니 기어 자체 마찰은 끔), 나머지는 boolean/string이라 확인된 패턴대로 설정.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s2i_inspect_and_set

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

fprintf('===== S2i: 기어/마찰 파라미터 설정 =====\n\n');

gb = [mdl '/Gearbox'];
fr = [mdl '/JointFriction'];

%% friction_model enum 확인
dpG = get_param(gb, 'DialogParameters');
fprintf('--- Gearbox.friction_model 옵션 ---\n');
disp(dpG.friction_model.Enum);
noFricIdx = find(contains(dpG.friction_model.Enum, {'No', 'none', 'None'}, 'IgnoreCase', true), 1);
if isempty(noFricIdx)
    fprintf('[정보] "No friction" 비슷한 옵션을 못 찾음. 현재값 유지: %s\n', get_param(gb, 'friction_model'));
else
    noFricVal = dpG.friction_model.Enum{noFricIdx};
    try
        set_param(gb, 'friction_model', noFricVal);
        fprintf('[OK] friction_model = %s (기어 자체 마찰 끔, JointFriction이 대신 담당)\n', noFricVal);
    catch ME
        fprintf('[실패] friction_model 설정: %s\n', ME.message);
    end
end

%% 기어비
try
    set_param(gb, 'ratio', num2str(p.gear.N));
    fprintf('[OK] ratio = %g\n', p.gear.N);
catch ME
    fprintf('[실패] ratio: %s\n', ME.message);
end

%% 백래시 켜기 + 각도
try
    set_param(gb, 'enable_backlash', 'on');
    fprintf('[OK] enable_backlash = on\n');
catch ME
    fprintf('[실패] enable_backlash: %s\n', ME.message);
end

try
    set_param(gb, 'backlash_distance', num2str(p.gear.backlash_deg));
    fprintf('[OK] backlash_distance = %g deg (단위 확인 필요, 아래 출력 참고)\n', p.gear.backlash_deg);
    fprintf('     실제 단위: %s\n', get_param(gb, 'backlash_distance_unit'));
catch ME
    fprintf('[실패] backlash_distance: %s\n', ME.message);
end

%% Rotational Friction: 점성계수만 설정 (Coulomb/breakaway는 0으로 둬서 영향 최소화, placeholder)
try
    set_param(fr, 'visc_coef', num2str(p.mech.joint_damping));
    fprintf('[OK] JointFriction.visc_coef = %g\n', p.mech.joint_damping);
catch ME
    fprintf('[실패] visc_coef: %s\n', ME.message);
end

try
    set_param(fr, 'Col_trq', '0');
    set_param(fr, 'brkwy_trq', '0');
    fprintf('[OK] Col_trq, brkwy_trq = 0 (점성마찰만 우선 테스트)\n');
catch ME
    fprintf('[실패] Col_trq/brkwy_trq: %s\n', ME.message);
end

save_system(mdl);
fprintf('\n');

%% 시뮬레이션
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

fprintf('\n===== S2i 끝. 에러 있으면 그대로, 성공하면 Scope 스크린샷(A/B) 보내달라. =====\n');
