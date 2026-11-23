# 프로젝트 인수인계: 새 환경(Linux)의 Claude가 가장 먼저 읽는 문서

작성 2026-10-28. 이 문서가 반영한 마지막 작업은 **2026-10-12**이다. 간트 기준으로 오늘(10/28)은 W9(10/26~11/1)이고 중간발표 주간이다. 10/12 이후의 진행은 이 문서에 없으니 **사용자에게 먼저 물어볼 것**.
이 파일과 `CLAUDE.md`, `STATUS.md`를 읽고 시작한다. 모르는 값은 지어내지 않고 묻는다.

## 1. 한 문단 요약
스마트 모빌리티 공학 종합설계. 1자유도 회전 관절(특정 로봇에 종속되지 않는 Generic Rotary Actuator Joint)의 액추에이터를 현실 특성까지 반영해 모델링하고, 시뮬레이션에서 제어 성능을 평가한다. 액추에이터 체인은 위치 명령 → 제어기 → 전력전자(인버터) → 모터 → 기어 → 관절이다. 지금까지는 같은 가정 모델을 MATLAB(Simulink/Simscape)과 MuJoCo(외부 Python)에 구현해 단계별로 비교했다. 태스크는 "질량 변화에 대응하는 목표 지점 던지기"로 거의 확정이고 세부 요구사항은 미정이다. 곧 새 태스크 기준으로 모델링을 새로 시작한다.

## 2. 사람과 역할
| 사람 | 역할 |
|---|---|
| 채희수 (사용자) | MATLAB/Simscape 담당. RCV·RAMS 기록의 주인. 프로젝트 오너 |
| 이민혁 | MuJoCo + 외부 Python PMSM 담당. 4단계 실험의 MuJoCo 쪽을 만들었다 |
| 강동하 | Simscape Electrical PMSM+FOC 모델, 현실 특성(PWM·마찰·백래시·열) 조사 |
| 지도교수 | 유지원 교수님(RCV 프로젝트 제목 기준). CLAUDE.md에는 "심인욱"으로 적혀 있어 **불일치. 사용자에게 확인** |

사용자는 AI를 많이 써서 개념 이해가 어렵다고 했다. **개념은 쉬운 말로, 짧은 비유와 숫자로 설명한다.** 한국어로 답한다.

## 3. 반드시 지킬 규칙
1. **지어내지 않는다** (CLAUDE.md 7장). 받지 못한 파일, 실행하지 않은 결과, 모르는 값을 추측으로 채우지 않는다. 실행 확인, 문서 확인, 추정을 구분해서 쓴다. 할 수 없는 일은 "안 된다"고 먼저 말한다.
2. **RCV(research-note MCP, 교수님이 봄) 쓰기는 항상** 최종 본문을 보여주고 사용자가 "올려"라고 한 뒤에만 한다. 승인은 작업마다 새로 받는다. 읽기는 자유다. AI 활용 문구는 사용자가 정한다.
3. **RAMS 작업실(팀 artifact, 교수님은 안 봄)** 은 맡긴 범위에서 확인 없이 기록해도 된다. 팀원 칸을 대신 쓰면 그 사실을 칸에 적는다.
4. **판정 기준은 출처를 구분**한다: [민혁]=각 README 수치, [5주차]=각도 1e-3 rad, iq 0.01 A, 관절 토크 0.015 N·m, 모터 토크 0.003 N·m, 정착 0.01 s, [신규]=새로 정한 기준(사용자 승인 후 사용). **결과를 보고 기준을 바꾸지 않는다.** 바꿀 때는 이유를 밝히고 승인받는다.
5. 파라미터는 모두 가정값이고 하드웨어 검증이 아니다. CLAUDE.md 3장 항목(시뮬레이터, 모터 모델, 제어기, 평가지표, 하드웨어)은 **확정이 아니다.** 임의로 확정하지 않는다.
6. 말하는 방식: "MuJoCo가 낫다/MATLAB이 낫다", "현실을 완전히 반영했다", "평균 모델로 충분하다"고 단정하지 않는다. 마찰·백래시의 FAIL은 "구현 오류인지 모델 차이인지 구분할 수 없다"고 쓴다.
7. 파일 다운로드, 패키지 설치는 사용자에게 먼저 묻는다(출처, 파일명, 크기를 밝히고).
8. 작업을 마칠 때 `STATUS.md`를 갱신한다(한 일, 결과, 결정, 막힌 점, 다음 검토 사항). 중요한 결정은 `docs/decisions.md`에 한 줄씩 남긴다.

## 4. 지금까지 한 일

| 주차 | 내용 |
|---|---|
| W4 (~9/21) | 제안발표. DC 모터, Pick-and-Place, MuJoCo, PID+LQR이 초기안이었으나 교수님 피드백으로 재검토 |
| W5 (9/28~10/4) | 1~3단계: 이상 토크+위치 PD → PMSM+전류 PI+평균 인버터 → 기어비 5+회전자 관성. MATLAB과 MuJoCo가 모든 단계에서 허용치의 3.1% 이하로 일치. 태스크를 던지기로 변경, 간트 30개 일(W5~W18)로 상세화 |
| W6 (10/5~10/11) | 4단계 현실 특성 4가지를 MATLAB에서 구현해 MuJoCo(민혁)와 비교 |
| W7 (10/12~) | Simulink↔MuJoCo 연동 시험, 5·6주차 합본 발표 자료, 발표 대본 |

**4단계 결과(MATLAB 측 통과/검사)**: 4-3 PWM 43/43 일치, 4-4 열 67/67 일치(권선 온도 차 최대 4.9e-6 °C), 4-1 건마찰 56/69(속도 임계값에 따라 달라짐), 4-2 백래시 56/109(접촉 모델이 달라 전류·토크 어긋남). **PWM과 열은 두 환경이 같은 식을 풀어 일치, 마찰과 백래시는 모델 정의가 달라 같은 값으로 맞출 수 없었다.**
**연동 시험**: 전기·제어는 Simulink, 기계는 MuJoCo(MATLAB System 블록이 `py.mujoco` 호출, 25 µs 간격). 24 V 0.3 rad 한 사례에서 민혁 결과와 최대 각도 차 5.4e-6 rad, 15/15 통과.
**의미**: 시뮬레이터를 고르기 위한 비교 자료다. 어느 쪽이 낫다고 정하지 않았다. 경향은 전기·열·PWM은 Simulink가 블록으로 쉽고, 마찰·백래시·접촉은 MuJoCo가 설정으로 쉽다(문서와 이번 경험 기준, 단정 금지).

## 5. 외부 시스템 지도
- **RCV**: 프로젝트 `prj_mso3xznduxw0` (종합설계 2026-2, 단계 `design`). 5주차 기록 `ent_tixpoznuzy10`, 6주차 기록 `ent_xftvvhq1zclo`(2026-10-11, 첨부 없음). 열린 할 일 5건(`tsk_vjropi2tirxo` PMSM PI 튜닝, `tsk_yrwl43jyy51p` 간트 합의, `tsk_wx0psl365oda` 던지기 태스크 정의 10/18, `tsk_fe9abhgm8z4c` 시뮬레이터 조사 범위, `tsk_mc37oubfuog6` 현실 특성 비교와 연동 조사 10/25). 연결은 프로젝트 루트 `.mcp.json`(토큰 포함, git 제외)과 `.claude/skills/research-note/SKILL.md`.
- **RAMS 작업실**(팀 artifact): https://claude.ai/artifact/Ln2tu72aJVKTqKoZ7XUj9e . DB 컬렉션 `entries`(문서 id `w{주차}_{hee|min|dong}`), `gantt`(30개 일, 진행률은 제안값), `prof`(교수님께 보낼 칸 `w5`, `w6`), `decisions`(날짜별 결정). **쓰기에는 `if_version`이 필요하다.** 이민혁 칸은 희수 이름으로 대신 쓴 것이라 본인 확인이 필요하다. 간트 일 이름과 주차는 페이지 코드의 `TASKS`에 있고 DB에는 진행률과 메모만 있다.
- **발표 덱**(claude.ai): 5주차 https://claude.ai/artifact/BcuvGF3VGS88FQ2xUcLqSD , 6주차 https://claude.ai/artifact/TjieZVN2Am4Rwiqj9CFiP6 , 5·6주차 합본 https://claude.ai/artifact/24MknpcPUAVuvnL7G1B6Dh . 대본은 `week6/발표_스크립트_5_6주차.md`.
- **교수님 피드백 원문**: `feedback/` 폴더(9/18, 9/21, 9/29).

## 6. 파일 지도
```
CLAUDE.md, STATUS.md        지침과 현재 상태
docs/                       decisions.md, references.md, simulator-survey.md(초안), 이 문서, SETUP_LINUX.md, claude_memory_backup/
feedback/                   교수님 피드백 원문
week5/                      config/(파라미터 4개), models/w5_stage3_2_joint.slx(4단계 기준 모델), results/, 이민혁/, 강동하/
week6/                      4단계: config/w6s41~44_params.m, scripts/w6s4X_{build,run}.m + w6s4X_compare.py, scripts/cosim/(Python만 남김), models/(4단계 모델 12개), results/, RCV 초안, 발표 대본
```
모델 이름: 1단계 `w5_mujoco_vs_matlab_1dof`, 2단계 `w5_stage2_pmsm_joint`, 3단계 `w5_stage3_2_joint`(**기준 모델**), 4단계 `w6_stage4_{1_joint,2_joint,3_pwm,3_avg,4_joint}`, 연동 `w6_cosim_mujoco`. 결과 CSV와 민혁 CSV는 git에 넣지 않았다.

**2026-10-29 정리**: 작업 폴더에는 6주차 4단계 모델과 그 의존 파일(week5/config, w5_stage3_2_joint.slx)만 남겼다. 1~3단계 모델, week5/scripts, 연동(w6c_*.m, MuJoCoJointSys.m, w6_cosim_mujoco.slx), present 복사본은 작업 폴더에서만 지웠고 커밋 73aac1f에서 복구할 수 있다(`git checkout 73aac1f -- <경로>`). 결과 CSV(week5 약 110 MB, week6 약 613 MB)는 git에 없어서 `D:\Capstone_design_backup\week{5,6}_matlab_results_20261029.zip`에 보관했다.

## 7. 새 모델링에서 재사용할 것
- **기준 구조**: 위치 PD(1 ms) → 전류 PI(100 µs, 전향 보상) → 전압 벡터 제한(Vdc/√3, 안티윈드업) → PMSM dq → 기어(N=5) → 관절. 파라미터는 `week5/config/w5s3_params.m`(R 0.5 Ω, L 5 mH, ψ 0.05 Wb, 극쌍 4, Kt 0.3, 링크 1 kg 0.4×0.05×0.05 m, 감쇠 0.1, 회전자 관성 환산 0.0025)에 모았다. 모두 가정값이다.
- **방법론**: 비교 전에 상대 CSV에 내 지표 계산을 적용해 summary.json이 재현되는지 먼저 확인, 출처별 판정 기준, 민감도는 값 목록으로, 시간 간격을 줄여 수렴 확인.
- **4단계 블록**: PWM 인버터, 열 노드(R(T), 1 ms 갱신, 식은 민혁 `thermal_step`과 같음), Simscape 마찰 회로(속도원+마찰 블록+토크센서), 두 관절 직렬 백래시.
- **연동**: 정리 후 `week6/scripts/cosim/`에는 mj_cosim.py, w6c_compare.py만 있다. MATLAB 쪽(MuJoCoJointSys.m, w6c_build/run.m)은 커밋 73aac1f에서 복구.
- 던지기 쪽: 1자유도 팔 + 스크립트 릴리스가 5주차 방향. 1자유도는 팔이 도는 평면 안의 거리만 맞출 수 있고 옆 방향 목표는 최소 2자유도가 필요하다(투사체 역학으로 따진 것, 시뮬레이션 확인은 아님).

## 8. 열린 결정과 다음 단계
- 시뮬레이터 선정(간트 W7 마일스톤 g1)과 던지기 태스크 요구사항 정의(질량 범위, 목표 거리, 착지 오차 허용치, 릴리스 조건, 평가지표)가 **가장 급하다.** 그 뒤 모터 요구 사양 역산 → 데이터시트 비교 → 제어기 → 평가.
- 교수님께 드릴 질문: (1) 두 시뮬레이터가 같은 현상을 다른 모델로 구현할 때 어느 쪽을 기준으로 삼을지, (2) 마찰·백래시 파라미터를 민감도 범위로 보고해도 되는지, (3) 현실 특성 범위를 PWM·열까지로 하고 마찰·백래시는 요구 사양 후 결정해도 되는지, (4) 우선순위를 던지기 요구사항 정의로 옮겨도 되는지. **교수님 답변 여부는 모른다. 사용자에게 확인.**
- 아직 안 한 것: 마찰·접촉 공통 힘 계산식 양쪽 구현, 네 특성 동시 적용, 다관절, 던지기 상황에서의 연동 비용, 실제 하드웨어 보정.

## 9. 환경과 알려진 함정 (Windows에서 확인한 것)
- MATLAB R2026a Update 2. 제품: Simulink, Simscape, Simscape Multibody, Simscape Electrical. **없는 것**: Simulink Coder, Embedded Coder, Simulink Compiler. Python 3.14.2, `mujoco==3.14.0`. 실행은 `matlab -batch "스크립트"`. 설치는 `docs/SETUP_LINUX.md`.
- MATLAB System 블록(`MuJoCoJointSys`)은 `getNumInputsImpl`을 명시하고 `outputImpl(obj, varargin)`로 받아야 입력 포트가 생겼다. 입력 포트는 객체를 읽은 뒤 업데이트하고 나서야 생긴다.
- Simscape 마찰은 속도만의 함수라 정지 시 0이다. 관절 속도를 이상 속도원에 넣고 토크센서로 읽는 회로를 썼다(블록 포트 순서는 시험으로 확인). 속도 임계값은 민혁 모델에 대응이 없어 0.001/0.01/0.1 rad/s로 민감도를 봤다.
- 백래시 접촉은 관절 한계(스프링-댐퍼)로 표현했고 MuJoCo solref/solimp와 1:1 변환이 안 된다. 접촉 강성·감쇠는 값 목록이며 감쇠 임계근사 2·sqrt(K·J)는 추정이다.
- 민혁 코드는 `stage4_4_core.py` 하나만 받았다. 나머지는 없다.
- Windows 전용 문제(cp949 출력, PowerShell 삭제 권한 제한)는 Linux에서는 해당하지 않는다.
