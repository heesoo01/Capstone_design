%% S9N_WRITE_VIDEO
% smwritevideo로 시뮬레이션 애니메이션을 동영상 파일로 직접 추출.
%
% *** 아직 실행 전 ***
% 실행법: cd D:\Capstone_design\week5\scripts 후 s9n_write_video

clear; clc;
mdl = 's1_mechanical';
if ~bdIsLoaded(mdl)
    open_system(fullfile(pwd, [mdl '.slx']));
end

fprintf('===== S9n: 동영상으로 애니메이션 추출 =====\n\n');

set_param(mdl, 'StopTime', '8');

fprintf('--- 시뮬레이션 (Explorer 창 열림) ---\n');
sim(mdl);
fprintf('[OK] 완료\n');

pause(2);  % Explorer가 완전히 뜰 시간 확보

fprintf('\n--- 동영상 추출 ---\n');
outDir = fullfile(pwd, '..', 'results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
videoPath = fullfile(outDir, 'pick_place_demo');

try
    smwritevideo(mdl, videoPath, 'PlaybackSpeedRatio', 1, 'FrameRate', 20);
    fprintf('[OK] 동영상 생성 완료: %s\n', videoPath);
catch ME
    fprintf('[실패]: %s\n', ME.message);
    disp(getReport(ME, 'extended', 'hyperlinks', 'off'));
end

fprintf('\n===== S9n 끝. results 폴더에 동영상 파일 있는지 확인해달라. =====\n');
