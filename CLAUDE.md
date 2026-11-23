# CLAUDE.md — 종합설계: PMSM 액추에이터를 Kinova Gen3에 넣어 던지기 성능 평가

> Claude Code와 Claude 데스크탑 채팅이 **같은 폴더(`D:\Capstone_design`)** 를 함께 쓴다. 두 쪽 대화는 서로 이어지지 않으므로, 맥락은 이 파일과 `STATUS.md`로 넘긴다.
> 세션을 시작하면 이 파일 → `STATUS.md` → `docs/민혁_작업_정리.md` 순서로 읽는다.
> 작업을 마치면 `STATUS.md`의 "작업 로그"에 한 줄 이상 남긴다(누가, 무엇을, 결과 파일 위치). 앞에 `[Code]` 또는 `[채팅]`을 붙인다.
> 2026-11-23에 주제가 바뀐 것을 반영해 새로 썼다. 이전 주제(1자유도 Generic 관절, MuJoCo↔MATLAB 비교)의 지침과 파일은 `archive_2026-11_이전주제/`에 있다. 참고만 하고 새 작업의 기준으로 쓰지 않는다.

## 1. 프로젝트 한 줄
PMSM 모터·인버터(전압/전류 한계)·하모닉 감속기(탄성)·회전자 관성을 포함한 관절 액추에이터를 **직접 구현**한다. 이것을 Kinova Gen3 7축 로봇팔(Simscape Multibody + Computed Torque Control)의 관절에 하나씩 꽂는다. 그리고 "이상 토크 입력"과 비교해 관절 추종 오차, 전류·전압 제한, 공 릴리스 속도와 착지 위치 차이를 평가한다.

- 과목: 스마트 모빌리티 공학 종합 설계. 과목 담당은 심인욱 교수님(사용자 프로필 기준)이다. `feedback/` 원문의 피드백 주신 분은 유지원 교수님이다. **두 분의 관계(담당/지도)는 확인되지 않았으니 문서에 쓸 때 사용자에게 묻는다.**
- 팀: 이민혁(로봇·CTC·통합, GitHub 저장소 관리), 강동하(모터·액추에이터 단계 2), 채희수(사용자). **희수의 현재 담당은 아직 정하지 않았다 → 사용자에게 확인.**
- 팀 원본 저장소: GitHub `RAMS-Capstone/SME_Capstone` (main). 2026-11-23 민혁이 `chatelard25/SME_Capstone`에서 팀 계정(Organization) `RAMS-Capstone`으로 옮겼다(예전 주소는 자동 연결). 희수·민혁은 팀 계정 Owner다.
- 진행 보드: https://github.com/orgs/RAMS-Capstone/projects/1 (비공개, 위 저장소와 연결됨). 진행 상황은 민혁 저장소 기준으로 관리한다.
- 이 폴더의 `SME_Capstone_git/`은 위 저장소의 **git clone**(원격 연결 있음, `git pull`로 최신화)이다. 옛 사본 `SME_Capstone/`(git 연결 없음)은 2026-11-23 사용자 요청으로 휴지통에 보냈다(clone과 줄바꿈·PNG 재인코딩만 달랐음).

## 2. 교수님 피드백 (현재 방향을 만든 것)
- week11: 모터를 라이브러리 블록으로 "딸깍" 하지 말고 **직접 구현**할 것. **던지기 전에 움직이는 것부터** 확인할 것.
- 관절 사이 관성 변화(질량 행렬 결합)를 볼 것.
- 이전 피드백(DC 모터는 너무 단순, 제어기 선정 근거, 태스크 난이도)은 `feedback/` 원문 참고.
- 출처: 민혁 README·stage3 README의 인용(문서 확인). 원문 녹취는 이 폴더에 없다.

## 3. 현재 기준 (팀 문서에 근거가 있는 것만)
| 항목 | 값 | 근거 |
|---|---|---|
| 로봇 | Kinova Gen3 7축, CTC, 관절 2부터 통합 (2 → 4 → 1) | `SME_Capstone_git/README.md` |
| 모터 | maxon EC-i 52 180 W, 24 V 권선 #574741 (p=8, Kt 0.04362 N·m/A, Rs 0.04675 Ω, L 0.0615 mH, Jm 1.7e-5 kg·m²) | `SME_Capstone_git/docs/03_관절2_기준사양_결정.md`, `stage1_motor/j2_params.m` |
| 감속기 | Harmonic Drive CSG-17-100 (N=100, s=−1, Kg 1.4e4 N·m/rad, J_WG 0.79e-5) | 같은 문서 |
| 전원·드라이브 | Vdc 24 V(민감도 18 V), 전압 한계 0.9·Vdc/√3 = 12.47 V, 전류 명령 제한 20.9 A(사례 A) / 10.4 A(사례 B) | 같은 문서 |
| 전류 제어 | FOC, id=0, PI ωc=2π·1 kHz (Kp 0.386, Ki 294), 전향 디커플링, 원형 전압 제한, back-calculation anti-windup | 단계 1 |
| 위치 제어 | CTC, 질량 행렬에 반사 관성 Jr = N²(Jm+J_WG) = 0.249 kg·m² 옵션(`ctc_Jr`), 공 0.1 kg 페이로드 반영 | `stage3_robot/README.md` |
| 시험 사례 | A-24 (24 V, 20.9 A), B-24 (24 V, 10.4 A), A-18 (18 V, 20.9 A) | 기준사양 문서 3.4절 |

**가정값으로 표시된 것**(제조사 값 아님): 감속기 감쇠비 0.05, 효율 0.6–0.8, 전류 제한 2배 계수, 비돌극(Ld=Lq), Y결선, Vdc 24 V 선택. 이 값을 쓰는 결과에는 "가정"이라고 적는다. 값마다 [M]/[C]/[A] 표기는 `j2_params.m`을 따른다.

## 4. 단계와 상태 (2026-11-21 민혁 저장소 기준, 문서 확인. 이 PC에서 실행 확인한 것은 아직 없음)
| 단계 | 내용 | 상태 |
|---|---|---|
| 1 | dq PMSM + FOC 직접 구현, Simscape PMSM과 비교 | 완료 (iq 차 3.5e-4 A) |
| 2 | 관절 2 액추에이터 블록 `J2_Actuator` (토크→iq, FOC, 모터, 모터축, 감속기 스프링), 1자유도 시험 T1–T4b | 틀 완료·12개 항목 통과(민혁). 동하가 다듬는 중 |
| 3 | Gen3 관절 2 슬롯 → 느린 point-to-point 동작 → 액추에이터 꽂기 | 슬롯·페이로드 CTC·Jr 옵션 완료. **꽂기(`Gen3_J2_act.slx`)는 아직** |
| 4 | 던지기: 릴리스 속도·착지 위치, 사례 A-24/B-24/A-18 | 예정 |

## 5. 폴더 구조
```
CLAUDE.md, STATUS.md      공통 지침과 진행 상황 (Code·채팅 공용)
SME_Capstone_git/         팀 저장소 git clone (RAMS-Capstone/SME_Capstone). 코드·모델·결과의 원본은 GitHub 쪽이다
docs/
  민혁_작업_정리.md        민혁 작업을 희수가 이해할 수 있게 푼 설명
  team_notes/             동하용 안내 PDF 2개 (FOC 비교 11/18, Gen3 인터페이스 11/21)
  decisions.md            결정 기록 (날짜, 결정, 이유)
  references.md           출처 목록 (이전 조사 S1–S11 포함)
work/                     희수(와 Claude)가 새로 만드는 스크립트·모델·결과. 필요할 때 만든다
feedback/                 교수님 피드백 원문 (9월)
archive_2026-11_이전주제/   이전 주제 자료 전부 (week5, week6, 중간발표, 옛 CLAUDE/STATUS/문서)
.mcp.json                 RCV 연구노트 MCP 연결 (토큰 포함, git 제외, 절대 내용 출력·커밋 금지)
```
- `SME_Capstone_git/` 안의 파일은 팀 공용이다. main에 직접 커밋하지 않는다. 고칠 때는 branch를 만들어 Pull Request로 올리거나 `work/`에서 작업하고 민혁과 상의한다(`.slx`는 git 병합이 안 됨).
- 모델은 가능하면 `build_*.m` 스크립트로 만든다(스크립트가 원본, `.slx`는 결과물). 민혁 규칙과 같다.

## 6. 실행 환경
- MATLAB **R2026b Update 1** (이 PC, 2026-11-23 설치, `C:\Program Files\MATLAB\R2026b\bin\matlab.exe`) + Simulink, Simscape, Simscape Multibody, Simscape Electrical, Simscape Driveline, Robotics System Toolbox. 민혁과 같은 R2026b라 민혁 `.slx`가 열린다(`Gen3_throw_baseline.slx` 열기 확인).
- R2026a Update 2도 아직 깔려 있고 PATH의 `matlab`은 **R2026a를 가리킨다.** 명령으로 실행할 때는 R2026b 전체 경로를 쓴다. R2026a에서는 R2026b로 저장된 `.slx`가 안 열린다(확인함).
- Gen3 모델 `Gen3_throw_baseline.slx`는 팀 저장소 `models/original/`에 있다. 던지기 입력 `baseline_input_decel.mat`은 저장소에 없고 민혁 PC에만 있다. 단계 4 재실행에 필요하다. 없으면 "없어서 못 한다"고 말한다.
- Python 검증 스크립트(`verify_stage1.py`, `verify_stage2.py`)는 numpy, matplotlib만 쓴다.
- 채팅 쪽 Claude는 이 PC에서 MATLAB을 실행할 수 없다. MATLAB 실행은 Claude Code(`matlab -batch`)나 사용자가 한다.

## 7. 작업 규칙
- **지어내지 않는다 (가장 중요).** 모르는 값, 받지 못한 파일, 실행하지 않은 결과를 추측으로 채우지 않는다. 결과를 쓸 때는 실행해서 확인한 것 / 문서에서 읽은 것 / 추정한 것을 구분한다. 할 수 없는 것은 먼저 "안 된다"고 말한다. 비슷한 값으로 대체해 PASS를 만들지 않는다. 판정 기준을 바꿀 때는 이유를 밝히고 사용자 승인을 받는다.
- 출처가 필요한 주장은 `docs/references.md`에 남긴다. 파라미터는 출처(데이터시트, 팀 문서, 사용자 발언)가 있는 것만 쓴다.
- 수치 결과에는 파라미터, 조건, 솔버 설정을 함께 저장한다. 그래프는 matplotlib 또는 MATLAB 정적 PNG로 저장한다.
- 이전 주제 자료를 새 결과의 근거로 섞지 않는다(파라미터가 다름: 예전 Kt 0.3, N 5 등).
- 사용자는 개념 설명을 쉬운 말, 짧은 비유, 숫자로 듣는 것을 선호한다. **기초 용어(예: 회전자, 고정자)도 모른다고 가정하고 설명하되, 정식 용어 이름은 반드시 함께 알려준다.** 한국어로 답한다.

## 8. 기록 규칙
- 작업을 마칠 때마다 `STATUS.md`의 작업 로그를 갱신한다: 한 일 / 결과(수치, 파일 위치) / 막힌 점 / 다음 할 일.
- 중요한 결정은 `docs/decisions.md`에 한 줄로 남긴다 (날짜, 결정, 이유, 누가 승인).
- **RCV(research-note MCP, 교수님이 보는 연구노트) 쓰기는 항상 사용자 확인 후에만 한다.** log_progress, add_task, update_task, update_stage, advance_stage, update_entry, add_comment, set_review 등 모든 쓰기가 해당한다. 먼저 최종 본문을 보여주고, 사용자가 그 작업에 대해 "올려"처럼 명시적으로 승인한 뒤에만 호출한다. 승인은 작업마다 새로 받는다. 읽기는 확인 없이 해도 된다. 본문에는 가정값과 못 한 것을 반드시 적는다. RCV 프로젝트 id와 이전 기록은 `archive_2026-11_이전주제/docs/PROJECT_CONTEXT.md` 5장에 있다.
- RAMS 작업실(팀 artifact, 교수님은 안 봄)은 사용자가 맡긴 범위에서 확인 없이 기록해도 된다. 팀원 칸을 대신 쓰면 그 사실을 칸에 적는다.
