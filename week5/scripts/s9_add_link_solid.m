%% S9_ADD_LINK_SOLID
% RevoluteJoint와 LinkVarMass 사이에 실제 원통(Cylindrical Solid)을 넣어서
% 눈에 보이는 로봇팔 막대를 만든다. 질량은 거의 0으로 둬서 기존 물리(GenVarMass)
% 계산에 영향 안 주게 한다 (순수 시각화용).
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9_add_link_solid

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

fprintf('===== S9: 링크 원통 형상 추가 =====\n\n');

%% 1. 블록 배치
try
    add_block('sm_lib/Body Elements/Cylindrical Solid', [mdl '/LinkRod'], ...
        'Position', [620 40 680 90]);
    fprintf('[OK] LinkRod(Cylindrical Solid) 배치\n');
catch ME
    fprintf('[실패] %s\n', ME.message);
end

dp = get_param([mdl '/LinkRod'], 'DialogParameters');
fprintf('\n--- 파라미터 이름 목록 ---\n');
disp(fieldnames(dp));

fprintf('\n===== S9 1단계 끝. 파라미터 보고 다음 단계(치수/연결) 진행. =====\n');
