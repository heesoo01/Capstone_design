%% S1F_FIX_LINK_MASS
% RevoluteJoint follower 쪽 "질량 분포 degenerate" 에러 원인 확인 및 수정.
% 추정 원인: RigidTransformLink의 오프셋을 한 번도 안 정해서 0인 채로,
%           질량이 관절축 바로 위에 있어 회전 관성이 0인 상태.
%
% 1) RigidTransformLink, LinkInertia의 실제 파라미터 이름/현재값을 먼저 출력한다
%    (추측 금지).
% 2) 이름이 확인되면, config/params.m 값(링크 길이 0.30 m, 질량 0.50 kg)으로 설정한다.
%    -- 파라미터 이름이 예상과 다르면 set_param 부분은 실패만 하고 죽지 않는다.
% 3) 다시 시뮬레이션(Test A, B)을 돌린다.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s1f_fix_link_mass

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S1f: 링크 오프셋/질량 확인 및 수정 =====\n\n');

rt = [mdl '/RigidTransformLink'];
li = [mdl '/LinkInertia'];

fprintf('--- RigidTransformLink 파라미터 목록 ---\n');
try
    dpRT = get_param(rt, 'DialogParameters');
    disp(fieldnames(dpRT));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

fprintf('\n--- LinkInertia 파라미터 목록 ---\n');
try
    dpLI = get_param(li, 'DialogParameters');
    disp(fieldnames(dpLI));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

% 이름에 Translation/Mass 비슷한 게 있으면 상세 출력 (Type, Enum, 현재값)
fprintf('\n--- 후보 파라미터 상세 ---\n');
candidate_names_RT = fieldnames(dpRT);
for i = 1:numel(candidate_names_RT)
    n = candidate_names_RT{i};
    if contains(n, 'Translat', 'IgnoreCase', true) || contains(n, 'Method', 'IgnoreCase', true)
        try
            fprintf('[RigidTransformLink.%s]\n', n);
            disp(dpRT.(n));
            fprintf('현재값: %s\n\n', mat2str(get_param(rt, n)));
        catch ME
            fprintf('  (조회 실패: %s)\n', ME.message);
        end
    end
end

candidate_names_LI = fieldnames(dpLI);
for i = 1:numel(candidate_names_LI)
    n = candidate_names_LI{i};
    if contains(n, 'Mass', 'IgnoreCase', true) || contains(n, 'Inertia', 'IgnoreCase', true) || contains(n, 'Density', 'IgnoreCase', true)
        try
            fprintf('[LinkInertia.%s]\n', n);
            disp(dpLI.(n));
            fprintf('현재값: %s\n\n', mat2str(get_param(li, n)));
        catch ME
            fprintf('  (조회 실패: %s)\n', ME.message);
        end
    end
end

fprintf('\n===== 여기까지 출력을 먼저 확인하자 =====\n');
fprintf('이 출력을 보고 정확한 파라미터 이름으로 다음 스크립트(s1g)에서 값을 설정할 것이다.\n');
