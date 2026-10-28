# 6주차 새 세션 인수인계 (작성 2026-10-11, W5 작업 전체 요약)

> 이 문서는 W5(9/28~10/4)와 그 직후(10/5~10/6)에 한 일을 다음 세션이 이어받도록 정리한 것이다. W6(10/5~10/11)에 새로 한 일은 이 문서에 없다.
> 아래 "확정", "미확정"을 구분해서 읽을 것. **CLAUDE.md 3장 항목(시뮬레이터, 모터 모델, 제어기, 평가지표, 하드웨어)은 확정이 아니다.** 임의로 확정하지 않는다.

## 0. 새 세션 첫 메시지 (그대로 붙여넣기)

```
D:\Capstone_design\week6\NEXT_SESSION_HANDOFF.md 를 먼저 읽어줘.
읽고 나서 (1) 지금 상태를 5줄로 요약해주고, (2) 6주차에 우선 할 일을 제안만 해줘 (실행은 내가 정한 뒤에).
RCV(research-note MCP) 쓰기는 항상 내가 "올려"라고 하기 전에는 하지 마. RAMS 작업실은 확인 없이 기록해도 돼.
```

## 1. 역할과 규칙

- 채희수 = MATLAB/Simscape 담당, 이민혁 = MuJoCo + 외부 Python PMSM, 강동하 = Simscape Electrical PMSM+FOC와 현실 특성 조사. 지도교수는 **유지원 교수님**(사용자와 RCV 프로젝트 제목 기준). `CLAUDE.md`에는 "심인욱"으로 적혀 있어 불일치이니 사용자에게 확인할 것.
- **RCV(research-note MCP, 교수님이 봄)**: 쓰기(log_progress, add_task, update_entry, update_task, update_stage 등)는 **항상 최종 본문을 먼저 보여주고 "올려" 승인 후에만**. 승인은 작업마다 따로. 읽기는 자유. (`CLAUDE.md` 8장, 메모리에 기록됨)
- **RAMS 작업실(팀 artifact, 교수님은 안 봄)**: 맡긴 범위에서는 확인 없이 기록 가능. 팀원 칸을 대신 쓰면 그 사실을 칸에 적는다.
- **지어내지 않는다** (`CLAUDE.md` 7장): 모르는 값, 받지 못한 파일, 실행하지 않은 결과를 추측으로 채우지 않는다. 실행 확인 / 문서 확인 / 추정을 구분해서 쓴다. 판정 기준을 완화할 때는 이유와 사용자 승인.
- **MATLAB은 Claude가 실행할 수 있다**: `matlab -batch "스크립트"` (R2026a, Simscape, Simscape Electrical, Simscape Multibody, Simulink 설치 확인). 출력은 cp949라 `iconv -f cp949 -t utf-8`로 읽는다.
- Python은 `C:\Users\cogml\AppData\Local\Programs\Python\Python314\python`에 matplotlib, pypdf를 설치해 둠(다른 python에는 없음).
- 토큰(.mcp.json의 Bearer 등)은 다른 곳에 복사하지 않는다.
- 사용자는 **AI를 많이 써서 개념 이해가 어렵다**고 말했다. RCV의 AI 활용 문구는 지금 "일부 활용"인데 실제 정도에 맞게 수정할 가능성이 높다(수정 문구를 먼저 보여주고 승인받을 것).

## 2. 한눈에 보기

- **한 일**: 1자유도 회전 관절 액추에이터(모터 + 드라이브 + 감속기 + 위치 제어 + 막대 부하)를 MATLAB(Simscape)과 MuJoCo(+외부 Python)에 같은 가정값으로 구현해 3단계로 비교. 6개 단계 모두 잠정 기준 통과.
- **의미**: 두 환경이 같은 가정 모델을 같게 계산한다. 시뮬레이터 선정 근거는 아니고, 하드웨어 검증도 아니다.
- **태스크**: Pick-and-Place → "질량 변화에 대응하는 목표 지점 던지기"(거의 확정, 연구 후 발전 가능). 세부(질량 범위, 목표 거리, 착지 오차 허용치, 릴리스 조건, 평가지표)는 미정.
- **일정**: 간트 30개 일(W5~W18) 상세화, 지연 1건(간트 확정, 팀 합의 대기), 담당·진행률은 제안(팀 합의 전).

## 3. 1~3단계 결과 (6.25 µs, 같은 사례끼리)

허용치(잠정): 각도 1e-3 rad, iq 0.01 A, 관절 토크 0.015 N·m(= N·Kt·0.01), 정착시간 차 0.01 s(양쪽 미정착이면 N/A). 아래는 각 단계의 최대 차이.

| 단계 | 구성 | 각도 | iq | 관절 토크 | 정착시간 |
|---|---|---|---|---|---|
| 1 | 이상 토크 + 위치 PD | 8.7e-6 rad | – | – | 0.904 s |
| 2-1 | PMSM 단독 | – | 2.4e-8 A | 7.1e-9 N·m (모터) | – |
| 2-2 | 24 V, 0.3 rad | 7.4e-7 rad | 9.5e-5 A | 2.9e-5 N·m | 0.920 s |
| 2-3 | 2 rad, 24 V / 2 V | 5.3e-6 rad | 1.2e-4 A | 3.7e-5 N·m | 1.193 / 1.271 s |
| 3-1 | 기어비 5 (3사례) | 7.2e-6 rad | 3.1e-4 A | 4.6e-4 N·m | 0.904 / 0.935 s, 2 V 둘 다 미정착(N/A) |
| 3-2 | + 회전자 관성 | 7.2e-6 rad | 3.0e-4 A | 4.5e-4 N·m | 0.894 / 0.926 s, 2 V 둘 다 미정착(N/A) |

- 3-3: 이민혁의 공식 비교 도구(`이민혁/MuJoCo_MATLAB_stage3_3_compare/run_stage3_3_compare.py`)를 MATLAB CSV에 그대로 실행해 3-1·3-2 모두 PASS. 처음엔 전기 CSV 필수 열 부족으로 거부됨 → 모델 로깅 열 추가 후 재실행(해석값 동일).
- MATLAB 간격 수렴(25 → 12.5 → 6.25 µs): 각도 변화 ≤ 1.6e-6 rad, iq ≤ 3.3e-5 A. 2 V는 전압 포화(3-1: 0.200~1.728 s)가 양쪽에서 일치.
- 3-1 → 3-2: 회전자 관성을 넣으면 24 V 정착이 소폭 빨라짐(0.904→0.894, 0.935→0.926 s), 두 환경 동일. 위치 루프 느린 극점 −4.72 → −4.82로 계산상 같은 방향.
- 2단계 → 3단계 정착시간 개선(2 rad, 24 V: 1.193 → 0.935 s)은 기어가 토크 상한을 0.6 → 3 N·m로 키운 모델 자체의 효과(두 환경 비교 결과 아님).
- 공통 가정값: 링크 1 kg, 0.4×0.05×0.05 m, 관절 관성 0.0535417(3-2는 +0.0025 = 0.0560417) kg·m², 감쇠 0.1, 위치 PD 4/1(1 ms), PMSM R 0.5 Ω, L 5 mH, ψ 0.05 Wb, 극쌍 4, Kt 0.3, 전류 PI 1.5/150(100 µs), 안티윈드업 300, iq 지령 ±2 A, Vdc 24/2 V.

## 4. 파일 위치 (D:\Capstone_design)

| 경로 | 내용 |
|---|---|
| `CLAUDE.md` | 프로젝트 지침(3장 태스크 행 갱신, 7장 "지어내지 않는다", 8장 RCV 확인 규칙 반영) |
| `docs/` | `decisions.md`(10/3, 10/4 결정 3건), `references.md`(공식 문서 출처 S1~S11), `simulator-survey.md`(초안) |
| `week5/config/` | `w5cmp_params.m`(1단계), `w5s2_params.m`, `w5s3_params.m` |
| `week5/scripts/` | `w5cmp_*`, `w5s2_*`(2단계), `w5s3_build.m / w5s3_run.m / w5s3_compare.py / w5s3_plot.py`(3단계), `w5_present_models.m`(그림용 서브시스템 사본), `w5_slide_figs.py`, `w5_slide_figs2.py` |
| `week5/models/` | `w5_mujoco_vs_matlab_1dof.slx`, `w5_stage2_pmsm_alone/joint.slx`, `w5_stage3_1_joint.slx`, `w5_stage3_2_joint.slx`(+`_gearcheck`), `present/*_present.slx`(그림용, 로깅 블록 삭제, 실행 결과 저장 금지) |
| `week5/matlab_results/stage3_1, stage3_2` | 3단계 MATLAB CSV(25/12.5/6.25 µs, MuJoCo 열 이름에 맞춘 23열 전기 CSV) + `matlab_settings.txt` |
| `week5/results/` | 단계별 비교 PDF·지표 json, `stage3_compare_metrics.json / report.txt`, `stage3_3_3_1_*`, `stage3_3_3_2_*`(공식 도구 출력), `slides/`(발표 그림) |
| `week5/이민혁/` | 민혁 CSV·README·summary(단계별 이름: `summary_stage1_mujoco.json`, `summary_stage2_2_mujoco.json` 등), `stage_3_1`, `stage_3_2`, 3-3 도구, 팀 조사 PDF들 |
| `week5/강동하/` | `realistic_features_simulation_comparison_ko.pdf`(원본 조사), `realistic_features_supplement_ko.md`(보완본 초안) |
| `week5/RAM_upload_2026-10-03(.zip)`, `RAM_upload_2026-10-04(.zip)` | 1~2단계, 3단계 업로드 묶음(`00_README.md` 포함) |
| `week5/RCV_draft_W5.md`, `RCV_draft_W5_v2.md` | RCV 초안(v2가 업로드된 최종본과 같음) |
| `week5/개념정리_PMSM_FOC_기어_설명용.md` | 팀이 설명할 수 있게 한 개념 정리(10절 연습 질문) |
| `week5/시뮬레이터_선정_상의_1장.md` | 시뮬레이터 선정 상의용 한 장(안 A~D) |
| `week5/slides_src/` | 발표 덱 생성 스크립트와 슬라이드 HTML 원본(`gen_deck2.py`, `deck2_project/`) |
| `week5/5주차 진행 보고.pdf` | 사용자가 덱을 내려받은 PDF |
| `week5/NEXT_SESSION_HANDOFF.md/.txt` | 5주차 시작 시점 인수인계(10/3). 이 문서가 최신 |

## 5. RAMS 작업실 (팀 artifact)

- URL: https://claude.ai/artifact/Ln2tu72aJVKTqKoZ7XUj9e (채희수 소유, 단일 HTML + artifact DB, `ArtifactData`로 읽고 씀. 쓰기는 `if_version` 필요)
- 컬렉션: `entries`(`w5_hee`, `w5_min`, `w5_dong`), `gantt`(30개 일, id p1~p5, r1~r5, a0~a5, c1~c3, t1~t4, e1~e3, g1, m1~m3), `prof`(`w5` 교수님께 보낼 칸: 요약, 지연 "일부 지연"(간트 확정 1건), 발표 구성, 질문 6개), `decisions`(`d20261003d`, `d20261003e`, `d20261004a`, `d20261004b` 등).
- 페이지 코드(TASKS 30개)는 W5에 재게시(Version 2). 페이지를 다시 고칠 때는 `Artifact read path=index.html`로 받아 편집 후 같은 URL에 게시(먼저 url만으로 read).
- 강동하는 `w5_dong`를 직접 작성해 편집 권한이 있는 것으로 보임. `w5_min`은 희수가 민혁 대신 정리한 것(민혁 확인 필요, 칸에 표시됨).
- 간트 담당·진행률은 "제안 10/4, 팀 합의 필요" 메모로 입력됨. 오늘이 W6 이후라 p1(간트 확정, W5 마감, 90%)은 지연으로 집계됨.

## 6. RCV 현황 (프로젝트 `prj_mso3xznduxw0`, 종합설계 2026-2)

- 5주차 기록 `ent_tixpoznuzy10`(제목 `[10.04] 5주차 MuJoCo–MATLAB 일치 검증(1~3단계), 던지기 태스크 변경, 현실 특성 조사 보완`, stage `design`, 검토 요청 안 함). 10/6에 개인별·환경별 구조로 `update_entry` 완료. 구성: 한눈에 보기 → 채희수(Simscape 구현) → 이민혁(MuJoCo 구현, "민혁 확인 필요") → 두 환경 비교 결과(허용치 대비 % 표) → 강동하 → 공통(태스크·간트) → 다음 할 일 → 메모(한계, AI 활용 "일부").
- 등록한 할 일 5건(담당 없음, design): 던지기 태스크 정의(10/18, `tsk_wx0psl365oda`), 교수님 피드백 반영·시뮬레이터 조사 범위와 선정 시점(10/18, `tsk_fe9abhgm8z4c`), 현실 특성 비교 측정(10/25, `tsk_mc37oubfuog6`), PMSM+FOC PI 튜닝(10/11, `tsk_vjropi2tirxo`), 간트 팀 합의(10/11, `tsk_yrwl43jyy51p`). 완료 처리는 `update_task`(쓰기라 승인 필요).
- 프로젝트 stage는 `proposal`(doing) 그대로, `advance_stage` 안 함. 공지(list_notices)는 비어 있었음.

## 7. 발표자료 (지도교수 주간 Zoom 보고)

- 덱: https://claude.ai/artifact/BcuvGF3VGS88FQ2xUcLqSD (Slides 형식, 9장, 희수 부분만). 사용자가 슬라이드를 직접 편집한 이력이 있음(질문 슬라이드는 질문 2개로 줄여 둠, 제목은 "질문 2개"로 맞춤). 수정하기 전에 항상 `read`로 최신본을 받고, 사용자 편집을 덮어쓰지 말 것. 렌더링 확인은 하지 않았음.
- 순서: 1 피드백→한 것→결론 / 2 1단계 / 3 2단계 / 4 3단계 / 5 결론(액추에이터 = 모터+드라이브+감속기, 단계별 표) / 6 비교표(MuJoCo는 전기 쪽 Python 코드, Simscape는 블록) / 7 태스크(던지기) / 8 일정(지연 1건) / 9 질문.
- 구조 화면은 사용자가 캡처해 준 것(1단계 원본, 2·3단계 그림용 사본)을 잘라 사용(`week5/results/slides/shot_stage*.png`).
- 민혁·동하는 각자 한 장씩 따로 준비하기로 함(교수님 요청: 1인 1페이지). 발표 설명 가이드는 대화로 제공했고 파일로는 저장하지 않았음.

## 8. 교수님 피드백(9/29, 5주차) 요약과 대응 상태

| 피드백 | 상태 |
|---|---|
| MuJoCo 어디까지 구현, 어디를 갈면 되나 | 전기 구동부(PMSM·전류 제어·인버터)만 기본 기능이 없어 외부 Python. 기계는 MuJoCo 기본. 라이브러리·C 코드 변환은 미조사 |
| 평균 모델만 쓸 수 있는 이유 설득 | **근거 없음.** PWM 모델과의 직접 비교가 필요(다음 계획) |
| 액추에이터는 MATLAB, 로봇 시뮬레이션은 방향 미정, MuJoCo 이식을 알아볼 것 | 현실 특성 조사(동하)와 연결 방식 정리 1차. 양방향 연동은 미검증 |
| 발표자료 필수, 마지막에 일정 점검, 1인 1페이지 | 완료(덱) |

## 9. 미해결과 6주차 후보 작업 (우선순위는 사용자가 정함)

1. 간트차트 담당·진행률 팀 합의(p1 지연 해소).
2. 던지기 태스크 정의: 질량 범위, 목표 거리, 착지 오차 허용치, 릴리스 모델, 비행·착지 계산 위치 → 모터 요구 사양(피크 토크·최대 각속도) 역산 → 모터 후보 데이터시트 비교.
3. 기존 시뮬레이터 후보 조사 보완(후보 5곳 1차: MATLAB, MuJoCo, Isaac Lab, Modelica, Drake). 범위가 충분한지는 교수님 확인 사항.
4. 현실 특성 직접 구현 비교: 마찰·백래시를 양쪽에 구현해 구현량·응답 측정, PWM 모델(별도 사례) vs 평균 모델 비교, Simulink↔MuJoCo 양방향 연동 조사.
5. 동하: Iq 추종 오차 PI 튜닝, 파라미터 정리. 민혁: 마찰·백래시 정식 구현, 던지기 시나리오 방향.
6. 동하 조사 보완본(`realistic_features_supplement_ko.md`) 동하 확인. MuJoCo 백래시 방법(S7)은 검색 요약으로만 확인했으므로 원문 확인 필요.
7. RCV 후속: 이민혁·동하 섹션 확인 후 표시 정리, AI 활용 문구 실제 정도에 맞게 수정(승인 후), 완료한 할 일 처리.
8. `docs/references.md`에 교재·논문 출처 추가(개념정리의 수식은 교재 수준 일반 설명, 출처 미기재).
9. `STATUS.md` 아직 없음(`CLAUDE.md` 8장 규칙상 작업 후 갱신). 새로 만들지 사용자에게 확인.
10. 사용자의 개념 이해 지원: `개념정리_PMSM_FOC_기어_설명용.md` 10절 질문으로 연습, 막히는 부분은 더 쉽게 설명.

## 10. 알려진 한계와 주의

- 모든 모터·기계 값은 가정값. 2 V는 포화 관찰용 극단 조건. "정착 못 함"은 2초 관찰 구간 안의 결과이지 발산 증명이 아님.
- 모델에 없는 것: PWM·스위칭·보호·DC 링크, 마찰·백래시·열, 접촉. 기어는 효율 100%의 이상 전달비.
- 두 환경 간 차이의 원인은 MuJoCo 쪽 적분 방식(고정 간격, 구간 시작 전류의 토크 유지). MATLAB은 간격을 줄여도 거의 변하지 않음.
- 문서 기준으로만 확인한 것: MuJoCo `dcmotor`(3.7.0 도입, 3.14.0 포함, DC 모터용), MuJoCo 이중 hinge 백래시, Simscape Electrical PMSM 열 포트, PWM Generator. 우리가 직접 구현해 확인하지 않은 것.
- 자동 배치된 Simulink 모델 화면은 흩어져 있어 발표용으로 쓰기 어려움 → `models/present/` 사본 또는 사용자가 정리한 캡처를 사용.
- 개념 설명이나 발표 답변에서 "MuJoCo가 더 낫다/MATLAB이 더 낫다", "현실을 완전히 반영했다", "평균 모델로 충분하다"고 단정하지 말 것.

## 11. 한 줄 요약

1~3단계(3-3 포함) 두 환경 비교 전부 통과, 태스크는 던지기로(세부 미정), RAMS·RCV·발표 덱 5주차 반영 완료. 다음은 던지기 요구사항 정의, 간트 합의, 시뮬레이터 조사 보완, 마찰·백래시·PWM 직접 비교. RCV 쓰기는 항상 승인 후.
