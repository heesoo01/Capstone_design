# Linux 환경 설치 지침

**이 문서의 명령은 Windows에서 확인한 환경을 바탕으로 쓴 것이며 Linux에서 직접 실행해 검증하지 않았다.** 막히면 오류 메시지를 사용자에게 보여주고, 추측으로 넘어가지 않는다. 파일 다운로드와 패키지 설치는 사용자에게 먼저 묻는다.

## 0. 먼저
- 이 PC는 **Windows와 Linux가 함께 설치된 구성**이다(같은 PC, 두 OS). Windows는 그대로 둔다. 프로젝트 원본은 Windows의 `D:\Capstone_design`(별도 물리 디스크, NTFS)에 있고 Linux에서는 읽기 전용으로 마운트해서 복사만 하는 것이 안전하다.
- 작업은 NTFS가 아니라 **Linux 파일시스템(예: `~/Capstone_design`)에서** 한다. NTFS에서 Simulink 모델을 열면 권한과 잠금 문제가 생길 수 있다.
- Windows가 "빠른 시작(Fast Startup)"이나 최대 절전으로 꺼져 있으면 NTFS가 잠겨서 Linux에서 쓰기로 마운트되지 않는다. 읽기 전용 마운트는 보통 가능하다. 쓰기가 필요하면 Windows에서 빠른 시작을 끄고 완전히 종료한 뒤 Linux로 들어간다.
- 배포판은 MathWorks가 R2026a에서 검증한 **Ubuntu 24.04 LTS 또는 22.04 LTS**(그 밖에 Debian 12·13, RHEL 8·9, SUSE 15 SP4 이상)가 안전하다. 요구사항 원문: https://www.mathworks.com/support/requirements/matlab-linux.html (Ubuntu 20.04는 R2026a에서 지원 종료).
- 권장 사양은 4코어 이상(AVX2), RAM 16 GB, 설치에 5~7 GB, SSD.

## 1. 프로젝트 가져오기
`D:\Capstone_design`은 git 저장소다. 같은 PC이므로 인터넷 저장소 없이 **D: 디스크의 저장소를 그대로 clone**하면 된다. 먼저 NTFS 파티션을 읽기 전용으로 마운트한다(장치 이름은 `lsblk`로 확인. 아래 `/dev/nvme1n1p2`는 예시이며 실제와 다를 수 있다):
```bash
lsblk -f
```
```bash
sudo mkdir -p /mnt/d && sudo mount -t ntfs3 -o ro /dev/nvme1n1p2 /mnt/d
```
그다음 clone한다:
```bash
git clone /mnt/d/Capstone_design ~/Capstone_design
```
Linux에서 한 작업은 Windows 쪽으로 합치려면 Linux에서 `git push`가 아니라, Windows 저장소에서 `git pull` 또는 `git fetch <Linux 경로>`로 가져온다(둘 다 작업하면 충돌할 수 있으니 한쪽을 기준으로 정한다). **큰 결과 CSV와 민혁 자료는 git에 없다.** 필요하면 마운트한 `/mnt/d/Capstone_design/...`에서 직접 복사한다.
그다음 **`.mcp.json`은 git에 없다.** 토큰이 들어 있어서다. 새 PC에 안전하게 따로 옮기거나, RCV 사이트에서 토큰을 발급해 프로젝트 루트에 직접 만든다. 형식은 `{"mcpServers": {"research-note": {"type": "http", "url": "...", "headers": {"Authorization": "Bearer ..."}}}}` 이고 키는 `type`, `url`, `headers`다(값은 RCV 쪽에서 확인).

## 2. Claude Code
프로젝트 폴더에서 실행해야 `CLAUDE.md`, `.claude/skills/research-note`, `.mcp.json`을 읽는다.
```bash
cd ~/Capstone_design
```
처음 `.mcp.json`을 만나면 승인을 묻는다. 승인 후 `research-note` 도구가 보이는지 확인한다. 로그인은 같은 계정으로 한다(claude.ai의 RAMS 작업실과 발표 덱 3개가 같은 계정에 있다). **사용자 홈의 기억(memory)은 옮겨지지 않는다.** 내용은 `docs/PROJECT_CONTEXT.md`와 `docs/claude_memory_backup/`에 있다.

## 3. Python (MuJoCo, 비교 스크립트)
```bash
python3 -m venv ~/.venvs/capstone
```
```bash
source ~/.venvs/capstone/bin/activate
```
```bash
pip install -r requirements.txt
```
확인:
```bash
python -c "import mujoco, numpy, matplotlib; print(mujoco.__version__)"
```
`3.14.0`이 나와야 한다(민혁과 같은 버전). 그래프의 한글은 폰트가 필요하다(예: Ubuntu `fonts-nanum` 패키지, 그리고 `fc-cache -f`).

## 4. MATLAB
- 같은 MathWorks 계정으로 Linux용 설치 프로그램을 받는다. **라이선스가 Linux 설치를 허용하는지는 MathWorks 계정에서 확인한다**(확인하지 못했다).
- 필요한 제품: MATLAB, Simulink, Simscape, Simscape Multibody, Simscape Electrical. Windows에서는 Simulink Coder와 Simulink Compiler 없이 모든 시험이 돌았다.
- 설치 후 확인:
```bash
matlab -batch "ver"
```
- Python 연동(연동 시험 `w6c_*`에만 필요). MATLAB이 지원하는 Python 버전을 확인하고, 그 파이썬을 `pyenv`로 지정한다:
```bash
matlab -batch "pyenv('Version', fullfile(getenv('HOME'), '.venvs', 'capstone', 'bin', 'python')); disp(pyenv)"
```
이 상태에서 `py.importlib.import_module('mujoco')`가 되어야 한다.

## 5. 재현 확인 순서 (환경이 제대로 됐는지)
1. 비교 스크립트(MATLAB 없이): 저장된 결과 CSV는 git에 없으므로 일부는 돌릴 수 없다. 코드가 그대로 읽히는지만 본다.
2. 기준 모델 실행: `week6/scripts/` 에서 `matlab -batch "w6s43_build"` 후 `w6s43_run('startup')`. 4단계 build와 run은 5주차 모델 `week5/models/w5_stage3_2_joint.slx`를 복사해서 쓴다.
3. 연동 시험: `week6/scripts/cosim/` 에서 `w6c_build` → `w6c_run(0.3,'quick')`. 이후 `w6c_run(2,'main')`과 `python w6c_compare.py`. Windows에서는 24 V 0.3 rad, 2 s에 9 s가 걸렸고 15개 검사가 모두 통과했다.

## 6. Linux에서 달라질 것
- 경로는 대부분 `fullfile`과 상대 경로라 문제가 없다. 대소문자를 구분하므로 모델 이름을 정확히 맞춘다.
- `matlab -batch`의 출력 인코딩은 Windows에서는 cp949였다. Linux는 UTF-8이라 변환이 필요 없다.
- 한글 폴더 이름(`week6/이민혁`)은 UTF-8이라 괜찮다. 이 폴더는 git에 없다.
- MATLAB이 시작하는 데 오래 걸리면 그래픽 없이 쓰는 `-batch`를 쓴다. Simulink 모델을 화면으로 보려면 데스크톱 세션이 필요하다.
