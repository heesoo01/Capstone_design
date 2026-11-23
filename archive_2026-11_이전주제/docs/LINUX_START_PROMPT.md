# Linux에서 Claude에게 처음 붙여넣을 프롬프트

사용법: Linux에서 터미널을 열고 아무 폴더에서 Claude Code를 실행한 뒤 아래 ``` 안의 내용을 통째로 붙여넣는다. 프로젝트 폴더를 가져오기 전에는 이 파일이 `/mnt/d/...`에만 있으니, 마운트 후 `cat /mnt/d/Capstone_design/docs/LINUX_START_PROMPT.md`로 읽거나 Windows에서 복사해 둔다.

```
이 PC에는 Windows와 Linux가 같이 설치돼 있고, 지금은 Linux야. Windows 쪽 D: 디스크(NTFS)에 있는 종합설계 프로젝트(D:\Capstone_design)를 이 Linux에서 이어서 진행하려고 해. 네가 아래 순서대로 스스로 진행해줘. 막히면 추측하지 말고 오류 메시지와 함께 나에게 물어봐.

## 지킬 것
- 지어내지 않는다. 확인하지 않은 것은 "확인 안 했다"고 말한다. 실행한 것, 문서에서 읽은 것, 추정한 것을 구분한다.
- 패키지 설치, 파일 다운로드, sudo가 필요한 명령은 실행 전에 나에게 먼저 말해줘. 무엇을, 출처, 크기를 밝히고 내가 허락한 뒤에 해. sudo 비밀번호는 네가 못 넣으니 명령을 보여주면 내가 직접 실행할게.
- Windows의 D: 원본은 읽기 전용으로만 다룬다. 원본을 수정하거나 삭제하지 않는다.
- .mcp.json에는 RCV 토큰이 들어 있다. 내용을 열어 보거나 출력하거나 다른 곳에 복사하지 말고, 파일만 복사해.
- RCV(research-note MCP) 쓰기는 내가 "올려"라고 하기 전에는 절대 하지 마. 읽기(whoami, get_project 등)는 해도 돼.

## 1단계: 프로젝트 가져오기
1. `lsblk -f`와 OS 버전을 확인하고 어떤 디스크/파티션이 Windows의 D: 데이터 디스크인지 찾아줘. 약 477 GB 디스크 하나가 통째로 NTFS이고 그 안에 `Capstone_design` 폴더가 있어. 후보가 여러 개면 나에게 물어봐.
2. 읽기 전용 마운트 명령(`/mnt/d`)을 나에게 보여줘. 내가 실행하면 마운트됐는지 확인해. NTFS가 잠겨 있다고 나오면 Windows의 빠른 시작 문제일 수 있으니 말해줘.
3. `git clone /mnt/d/Capstone_design ~/Capstone_design`으로 가져와. 큰 CSV와 민혁 자료는 git에 없는 게 정상이야.
4. `/mnt/d/Capstone_design/.mcp.json`을 `~/Capstone_design/.mcp.json`으로 복사만 해(내용은 열지 마).

## 2단계: 맥락 읽기
`~/Capstone_design`에서 Claude Code를 다시 시작해야 `CLAUDE.md`와 `.claude/skills`가 적용된다면 그렇게 안내해줘(예: 내가 새로 `cd ~/Capstone_design && claude`를 실행). 그 폴더에서 다음 순서로 읽어줘.
1. `CLAUDE.md`
2. `docs/PROJECT_CONTEXT.md` (가장 중요: 목적, 규칙, 이력, 외부 시스템 지도, 열린 결정)
3. `STATUS.md`
4. `docs/SETUP_LINUX.md`
5. `docs/claude_memory_backup/` (옛 환경의 기억 파일. 이 환경에서도 유지할 만한 규칙만 네 기억으로 저장해도 돼. 저장 전에 무엇을 저장할지 나에게 알려줘)

읽고 나서 **현재 상태를 5줄로 요약**해줘. 그리고 `docs/PROJECT_CONTEXT.md`의 마지막 반영일이 2026-10-12라는 점에 따라, 그 이후 진행(중간발표, 교수님 답변, 팀 결정 등)을 나에게 물어봐. 내가 답하기 전에는 새 작업을 시작하지 마.

## 3단계: 환경 점검 (읽기만, 설치는 아직)
이 Linux에 다음이 있는지 확인해서 표로 알려줘.
- python3 버전, git, pip, venv 가능 여부
- `mujoco` 파이썬 패키지(필요 버전 3.14.0), numpy, matplotlib
- MATLAB(`matlab` 명령, 버전, `matlab -batch "ver"`로 Simulink, Simscape, Simscape Multibody, Simscape Electrical 설치 여부). 없으면 없다고만 해. MATLAB 설치는 내가 직접 할 거야.
- 한글 폰트(`fc-list :lang=ko`)
- `research-note` MCP 연결(`whoami`로 읽기 확인만)

## 4단계: 설치 계획
`docs/SETUP_LINUX.md`를 바탕으로 이 환경에 필요한 설치 항목과 명령을 번호 붙여 제안해줘(출처와 크기 포함). 내가 승인한 항목만 실행해. Python은 `~/.venvs/capstone` 가상환경에 `requirements.txt`로 설치하는 안을 기본으로 해.

## 5단계: 동작 확인
설치가 끝나면 아래를 순서대로 해보고 결과를 그대로 보고해줘.
1. `python scripts/cosim/mj_cosim.py` (week6/scripts/cosim). 기대: 관성 약 0.0560417, mujoco 버전 3.14.0, 해석해와 3e-5 이내.
2. MATLAB이 있으면 `matlab -batch "ver"`와, Python 연동이 필요하면 `pyenv` 설정 후 `py.importlib.import_module('mujoco')`.
3. MATLAB이 있으면 `week6/scripts/cosim`에서 `w6c_build` 후 `w6c_run(0.3,'quick')`. (이 시험은 Windows에서 통과했던 것이고 Linux에서는 처음이야. 실패하면 원인을 추측하지 말고 로그를 보여줘.)

## 마무리
- 위 결과를 `STATUS.md`에 "Linux 환경 설정" 항목으로 추가해줘(한 일, 확인한 것, 안 된 것, 다음에 검토받을 것).
- 변경한 파일은 git으로 커밋해(push는 하지 마).
- 그다음 다음 작업(시뮬레이터 선정과 던지기 태스크 요구사항 정의)으로 어떻게 들어갈지 제안만 하고, 내가 정하면 시작해.
```
