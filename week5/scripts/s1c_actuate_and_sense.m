%% S1C_ACTUATE_AND_SENSE
% Revolute Joint에 토크 입력을 받게 하고(TorqueActuationMode=InputTorque),
% 위치/속도를 물리신호로 뽑아내게 한다(SensePosition/SenseVelocity=on).
% 중력(GravityVector)은 이미 기본값이 맞아서 건드리지 않는다.
%
% *** 아직 실행 전 ***
%
% 이 스크립트는 값만 바꾸고, 새로 생긴 포트를 연결하지는 않는다.
% (포트가 몇 개 어떤 이름으로 새로 생기는지 먼저 확인한 뒤 다음 스크립트에서 연결)
%
% 실행법: cd D:\Capstone_design\week5\scripts 후 s1c_actuate_and_sense

clear; clc;
mdl = 's1_mechanical';

if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

rj = [mdl '/RevoluteJoint'];

fprintf('===== S1c: 토크 입력 / 센싱 켜기 =====\n\n');

fprintf('--- 변경 전 포트 구성 ---\n');
try
    hBefore = get_param(rj, 'PortHandles');
    disp(hBefore);
catch ME
    fprintf('[실패] %s\n', ME.message);
end

%% 파라미터 변경
params_to_set = {'TorqueActuationMode', 'InputTorque'; ...
                  'SensePosition',       'on'; ...
                  'SenseVelocity',       'on'};

fprintf('\n--- 파라미터 변경 ---\n');
for i = 1:size(params_to_set, 1)
    pname = params_to_set{i,1};
    pval  = params_to_set{i,2};
    try
        set_param(rj, pname, pval);
        fprintf('[OK] %s = %s\n', pname, pval);
    catch ME
        fprintf('[실패] %s = %s : %s\n', pname, pval, ME.message);
    end
end

fprintf('\n--- 변경 후 포트 구성 ---\n');
try
    hAfter = get_param(rj, 'PortHandles');
    disp(hAfter);
    fn = fieldnames(hAfter);
    for i = 1:numel(fn)
        fprintf('  %s : %d개\n', fn{i}, numel(hAfter.(fn{i})));
    end
catch ME
    fprintf('[실패] %s\n', ME.message);
end

%% 중력 확인만 (변경 안 함)
fprintf('\n--- 중력 확인 (변경 없음) ---\n');
try
    mc = [mdl '/MechanismConfiguration'];
    fprintf('UniformGravity = %s\n', get_param(mc, 'UniformGravity'));
    fprintf('GravityVector  = %s\n', get_param(mc, 'GravityVector'));
catch ME
    fprintf('[실패] %s\n', ME.message);
end

save_system(mdl);
fprintf('\n===== 저장 완료. 모델 창 스크린샷(포트 늘어난 모습) + 명령창 출력 붙여넣어 달라. =====\n');
