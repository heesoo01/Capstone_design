%% S9B_CONFIGURE_LINK_SOLID
% LinkRod 치수/질량 설정하고, RevoluteJoint의 follower 프레임(F, RigidTransformLink
% 랑 같은 시작점)에 연결. 질량은 아주 작게 둬서 기존 물리에 영향 최소화.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9b_configure_link_solid

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

addpath(fullfile(pwd, '..', 'config'));
p = params();

lr = [mdl '/LinkRod'];

fprintf('===== S9b: LinkRod 설정 + 연결 =====\n\n');

try
    set_param(lr, 'CylinderRadius', '0.01');
    set_param(lr, 'CylinderLength', num2str(p.mech.link_len));
    fprintf('[OK] Radius=0.01m, Length=%.2fm\n', p.mech.link_len);
catch ME
    fprintf('[실패] 치수: %s\n', ME.message);
end

try
    fprintf('BasedOnType 현재값 = %s\n', get_param(lr, 'BasedOnType'));
catch ME
    fprintf('BasedOnType 조회 실패: %s\n', ME.message);
end

try
    set_param(lr, 'Mass', '0.001');
    fprintf('[OK] Mass = 0.001kg (거의 0, 시각화 전용)\n');
catch ME
    fprintf('[실패] Mass: %s\n', ME.message);
end

%% 연결: RevoluteJoint의 F(follower) 포트와 같은 곳에서 branch
hRJ = get_param([mdl '/RevoluteJoint'], 'PortHandles');
hLR = get_param(lr, 'PortHandles');

fprintf('\nLinkRod 포트 구성:\n');
fn = fieldnames(hLR);
for i = 1:numel(fn)
    fprintf('  %s : %d개\n', fn{i}, numel(hLR.(fn{i})));
end

try
    % RevoluteJoint.RConn(1)은 F(follower), 이미 RigidTransformLink에 연결돼
    % 있으므로 같은 포트에서 branch
    add_line(mdl, hRJ.RConn(1), hLR.RConn(1), 'autorouting', 'on');
    fprintf('\n[OK] RevoluteJoint.F -> LinkRod 연결\n');
catch ME
    fprintf('\n[실패] 연결: %s\n', ME.message);
end

save_system(mdl);

fprintf('\n===== S9b 끝. 시뮬레이션 다시 돌리고 Multibody Explorer 확인해달라. =====\n');
