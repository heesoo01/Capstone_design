%% S0_BLOCK_DISCOVERY
% 목적: 이번 프로젝트에 필요한 Simscape 블록들이 이 MATLAB 설치본에
%       실제로 존재하는지, 정확한 라이브러리 경로가 무엇인지 확인한다.
%
% *** 아직 실행 전 — 이 스크립트는 MATLAB에서 한 번도 돌려보지 않았다. ***
%
% 사용법:
%   1) MATLAB을 켠다.
%   2) 현재 폴더(Current Folder 창)를 week5 폴더로 이동한다.
%      (경로: D:\Capstone_design\week5)
%   3) 명령창(Command Window)에 아래를 그대로 입력하고 Enter:
%        cd scripts
%        s0_block_discovery
%   4) 명령창에 출력된 내용을 전부 복사해서 붙여넣어 달라.
%      에러가 나도 괜찮다 — 에러 메시지도 그대로 붙여넣어 달라.
%
% 방식: 정확한 블록 경로를 추측하지 않는다. 대신
%   (a) 관련 라이브러리를 열어보고 존재 여부를 확인한 뒤
%   (b) 열린 라이브러리 안에서 필요한 기능과 이름이 비슷한 블록을
%       키워드로 검색해서 실제 전체 경로를 찾아낸다.

clear; clc;
fprintf('===== S0: 블록/라이브러리 탐색 시작 =====\n\n');

%% 0. 환경 정보
fprintf('--- 0. MATLAB / 설치된 관련 툴박스 ---\n');
try
    v = ver;
    names = {v.Name};
    keywords_tb = {'Simulink', 'Simscape'};
    for i = 1:numel(names)
        for k = 1:numel(keywords_tb)
            if contains(names{i}, keywords_tb{k}, 'IgnoreCase', true)
                fprintf('  설치됨: %s (%s)\n', names(i).Name, v(i).Version);
                break;
            end
        end
    end
catch ME
    fprintf('  [실패] 툴박스 목록 조회 중 에러: %s\n', ME.message);
end
fprintf('\n');

%% 1. 후보 라이브러리 열기 시도
fprintf('--- 1. 라이브러리 열기 시도 (실패해도 계속 진행) ---\n');
% 아래 이름들은 확정된 게 아니라 "시도해볼 후보"다.
candidate_libs = { ...
    'simscape', ...        % Simscape 기반 유틸리티 (Solver Configuration 등)
    'sm_lib', ...          % Simscape Multibody
    'sdl_lib', ...         % Simscape Driveline
    'sps_lib', ...         % Simscape Electrical (Specialized Power Systems 계열)
    'ee_lib', ...          % Simscape Electrical (Electronics 계열, 후보)
    'mcb_lib', ...         % Motor Control Blockset (설치돼 있을 경우)
    'powerlib' ...         % 구버전 Specialized Power Systems 이름 (후보)
};

opened_libs = {};
for i = 1:numel(candidate_libs)
    lib = candidate_libs{i};
    try
        load_system(lib);
        fprintf('  [성공] load_system(''%s'')\n', lib);
        opened_libs{end+1} = lib; %#ok<AGROW>
    catch ME
        fprintf('  [실패] load_system(''%s'') -> %s\n', lib, ME.message);
    end
end
fprintf('\n');

if isempty(opened_libs)
    fprintf(['어떤 후보 라이브러리도 이 이름으로 열리지 않았다.\n' ...
             '-> Simulink 시작 화면에서 "Library Browser"를 직접 열어서,\n' ...
             '   Simscape / Simscape Multibody / Simscape Driveline / Simscape Electrical\n' ...
             '   이 왼쪽 트리에 보이는지 스크린샷으로 알려달라.\n']);
end

%% 2. 열린 라이브러리 안에서 키워드로 블록 검색
fprintf('--- 2. 키워드로 블록 검색 (열린 라이브러리 안에서만) ---\n');

% 필요한 기능별 검색 키워드 (블록의 실제 이름 일부와 대략 일치하면 됨)
keyword_groups = struct( ...
    'revolute_joint',   {{'Revolute Joint', 'Revolute'}}, ...
    'rigid_body_or_solid', {{'Solid', 'Brick Solid', 'Inertia'}}, ...
    'rigid_transform',  {{'Rigid Transform'}}, ...
    'world_frame',      {{'World Frame'}}, ...
    'mechanism_config',  {{'Mechanism Configuration'}}, ...
    'solver_config',    {{'Solver Configuration'}}, ...
    'backlash',         {{'Backlash'}}, ...
    'rotational_friction', {{'Rotational Friction', 'Friction'}}, ...
    'pmsm',             {{'Permanent Magnet Synchronous', 'PMSM'}}, ...
    'inverter_or_bridge', {{'Inverter', 'Bridge', 'Universal Bridge'}}, ...
    'dc_voltage_source', {{'DC Voltage Source'}}, ...
    'current_sensor',   {{'Current Sensor'}}, ...
    'ideal_rot_sensor', {{'Ideal Rotational Motion Sensor', 'Rotational Motion Sensor'}} ...
);

fnames = fieldnames(keyword_groups);
results = struct();

for gi = 1:numel(fnames)
    key = fnames{gi};
    kw_list = keyword_groups.(key);
    fprintf('  [%s] 검색어: %s\n', key, strjoin(kw_list, ' / '));
    found_any = false;

    for li = 1:numel(opened_libs)
        lib = opened_libs{li};
        try
            all_blocks = find_system(lib, 'LookUnderMasks', 'all', 'FindAll', 'off', 'Type', 'block');
        catch ME
            fprintf('     [실패] find_system(''%s'') -> %s\n', lib, ME.message);
            continue;
        end

        for bi = 1:numel(all_blocks)
            bpath = all_blocks{bi};
            try
                bname = get_param(bpath, 'Name');
            catch
                continue;
            end
            for ki = 1:numel(kw_list)
                if contains(bname, kw_list{ki}, 'IgnoreCase', true)
                    fprintf('     -> 후보 발견: %s\n', bpath);
                    found_any = true;
                    break;
                end
            end
        end
    end

    if ~found_any
        fprintf('     (이 라이브러리들 안에서는 못 찾음)\n');
    end
    results.(key) = found_any;
    fprintf('\n');
end

%% 3. 요약
fprintf('===== 요약 =====\n');
for gi = 1:numel(fnames)
    key = fnames{gi};
    status = '없음';
    if results.(key)
        status = '후보 있음 (위 출력 참고)';
    end
    fprintf('  %-22s : %s\n', key, status);
end

fprintf('\n===== S0 끝. 위 전체 출력을 복사해서 붙여넣어 달라. =====\n');
