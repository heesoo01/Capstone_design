# 다음 세션 인수인계 (작성 2026-10-03, 3단계는 2026-10-04 진행 예정)

## 0. 새 세션 첫 메시지 (그대로 붙여넣기)

```
D:\Capstone_design\week5\NEXT_SESSION_HANDOFF.md 를 먼저 읽어줘.
읽고 나서 (A) 3단계 이어서 검증, (B) RCV 연구노트 업로드 순서로 진행할 건데,
RCV(research-note MCP)는 내가 "올려"라고 할 때까지 쓰지 마. 먼저 (A)의 준비 상태와 (B)의 초안만 보여줘.
```

## 1. 역할과 규칙

- 나(채희수) = MATLAB/Simscape 담당, 이민혁 = MuJoCo + 외부 Python PMSM 담당. 같은 조건으로 단계별 검증 후 CSV 비교.
- 순서: ① 검증 끝 → ② 팀 사이트 RAM(RAMS 작업실 artifact)에 먼저 기록 → ③ 내가 승인하면 RCV(종설 연구노트, 교수님이 봄)에 기록.
- **RCV(research-note MCP)는 쓰기 작업(log_progress, add_task, update_* 등) 전에 항상 나에게 최종 본문을 보여주고 "올려" 승인을 받은 뒤에만 한다. 승인은 작업마다 따로 받는다.** 읽기(whoami, get_project, list_notices)는 확인 없이 가능. RAM은 교수님이 안 보고, 내가 맡긴 범위에서는 확인 없이 기록해도 된다. (CLAUDE.md 8장에도 같은 규칙이 있다)
- MATLAB은 내가 실행하고 출력을 붙여준다 (Claude는 MATLAB 실행 불가).
- 토큰(.mcp.json의 Bearer)은 다른 곳에 복사하지 않는다.
- CLAUDE.md 3장 항목(시뮬레이터, 태스크, 모터 모델, 제어기, 평가지표, 하드웨어)은 확정되지 않았으므로 임의로 확정하지 않는다. 이번 비교는 "가정값 기반 두 환경 일치 검증"이다.

## 2. 이번 세션(10/03)에 끝난 것

| 단계 | 내용 | 결과 |
|---|---|---|
| 1 | 이상 토크 1관절, 기어비 1, 1 ms 위치 PD | 합의 기준 PASS (최대 각도 차 8.7e-6 rad, 정착 둘 다 0.904 s) |
| 2-1 | PMSM 전기 모델 단독 (vd=0, vq=1 V) | PASS (iq 차 2.4e-8 A, 토크 차 7.1e-9 N·m) |
| 2-2 | PMSM + 위치 PD + 전류 PI + 평균 인버터 (24 V, 0.3 rad) | PASS (각도 7.4e-7 rad, iq 9.5e-5 A, 토크 2.9e-5 N·m, 정착 0.920 s) |
| 2-3 | 같은 통합 모델, 목표 2 rad, 24 V / 2 V | 양쪽 PASS (24 V: 5.3e-6 rad, 정착 1.193 s / 2 V: 2.5e-6 rad, 정착 1.271 s, 전압 포화 0.2~0.807 s 일치) |

- MATLAB 간격 수렴 (25 → 12.5 → 6.25 µs): 최대 각도 변화 ≤ 2.9e-6 rad, 최대 전류 변화 ≤ 1.8e-5 A.
- MATLAB은 정확해(1 ms 토크 유지 닫힌 식)와 약 1e-7 rad로 일치한다. 두 환경 차이는 MuJoCo 쪽 적분 오차 수준이다.
- 공통 조건: 링크 0.4×0.05×0.05 m 1 kg, 관절 관성 0.0535417 kg·m², 감쇠 0.1, 중력/접촉/마찰 없음, 위치 PD 4/1 (1 ms), PMSM R 0.5 Ω, L 5 mH, ψ 0.05 Wb, 극쌍 4 (Kt 0.3), 전류 PI 1.5/150 (100 µs), 안티윈드업 300, iq 지령 ±2 A.
- 판정 기준(잠정, 하드웨어 정확도 기준 아님): 1단계 각도 ≤1e-3 rad·정착 ≤0.01 s / 2-1 iq ≤1e-5 A·토크 ≤3e-6 N·m / 2-2·2-3 각도 ≤1e-3 rad·iq ≤0.01 A·토크 ≤0.003 N·m·정착 ≤0.01 s.
- 모든 모터·기계 값은 비교용 가정값. PWM, 스위칭, 보호, DC 링크 동특성은 없음. 2 V는 제한 현상을 보기 위한 극단 조건.

## 3. 파일 위치 (D:\Capstone_design\week5)

- 파라미터: `config/w5cmp_params.m`(1단계), `config/w5s2_params.m`(2단계)
- 스크립트: `scripts/w5cmp_build.m`, `w5cmp_run.m`, `w5s2_build.m`, `w5s2_run.m`, 비교·리포트 py (`w5cmp_compare_report.py`, `w5s2_1_compare_report.py`, `w5s2_2_compare.py`, `w5s2_2_compare_report.py`, `w5s2_3_compare.py`, `w5s2_3_compare_report.py`)
- 모델: `models/w5_mujoco_vs_matlab_1dof.slx`, `w5_stage2_pmsm_alone.slx`, `w5_stage2_pmsm_joint.slx`
- 결과: `results/` (MATLAB CSV, 설정 txt, 비교 PDF, 지표 json)
- 이민혁 자료: `이민혁/` (CSV, README_stage*.txt, summary.json)
- RAM 업로드 묶음: `RAM_upload_2026-10-03/` 와 `.zip` (README `00_README.md`에 전체 요약)

## 4. RAM(RAMS 작업실) 현황

- 기록됨: 희수 W5 칸, 이민혁 W5 칸 (done/result/blockers/next, progress 100), 결정 기록 2건 (d20261003d, d20261003e).
- 남은 것:
  - 간트차트 미기입 (담당자·진행률 팀 합의 필요)
  - 이민혁 칸은 내가 대신 작성한 것이므로 본인 확인 필요
  - 이민혁 1단계·2-2 `summary.json` 미수령 (단계마다 덮어써짐) → 단계별 이름으로 다시 받아 묶음에 추가하고 zip 재생성
  - 3단계 결과는 아직 기록 안 됨

## 5. (A) 3단계 이어서 검증 — 준비 프롬프트

```
3단계(기어비 + 회전자 관성 추가)를 2단계와 같은 방식으로 진행하자.
이민혁이 보낸 3단계 정의문을 아래에 붙일게. (또는 파일 경로: week5/이민혁/...)
그 정의문 기준으로:
1) 합의 조건 요약 (기어비 값, 회전자 관성 값, 시험 입력, 새 판정 기준)을 먼저 확인시켜줘. 정의문에 없는 값은 네가 정하지 말고 물어봐.
2) w5s2_joint 모델을 복사한 3단계 모델과 params/build/run 스크립트를 만들어줘
   (기어 출력 부호 확인, 감쇠 한 곳에서만 적용, 백래시 off, 모터측 관성 환산 확인).
3) 내가 MATLAB에서 돌려서 출력을 붙일게. MaxStep 25→12.5→6.25 µs 수렴 확인 포함.
4) 이민혁 CSV와 비교 → PDF → RAM 업로드 묶음 갱신. RCV는 아직 쓰지 마.
```

- 참고: 이민혁의 예전 통합 실험은 기어비 5, 회전자 관성 1e-4 kg·m²였지만, 3단계 값은 정의문 기준으로 정한다. 임의로 가정하지 않는다.
- 기어를 넣으면 달라지는 부분: 토크 N배, 모터 속도 = N × 관절 속도(역기전력 항), 반사 관성 = 회전자 관성 × N², 부호 방향.

## 6. (B) RCV 연구노트 업로드 — 프롬프트 초안

(내가 "올려"라고 하기 전에는 실행하지 말 것. 3단계까지 끝낸 뒤 올릴지, 지금 1~2단계만 먼저 올릴지는 올리기 직전에 내가 정한다.)

```
research-note MCP로 RCV(종합설계 연구노트, 프로젝트 prj_mso3xznduxw0)에 5주차 기록을 올려줘.
순서:
1) whoami, get_project(단계 순서 확인), list_notices(제출 형식·요령 확인)를 먼저 읽고 보고해줘.
2) 어느 stage에 log_progress 할지는 get_project의 단계 순서를 보고 나에게 제안만 해. 내가 정해줄게.
3) 제목은 "N주차 ..." 형식(5주차)으로, 본문은 ## 한 일 / ## 결과 / ## 다음 할 일 / ## 메모.
4) 내용은 week5/NEXT_SESSION_HANDOFF.md 2절과 RAM_upload_2026-10-03/00_README.md를 근거로 하고,
   수치(차이, 허용값, 정착시간, 포화 구간)와 사용 조건(MATLAB R2026a ode23t, MuJoCo 3.14.0, 간격 6.25 µs)을 구체적으로 적어줘.
5) 반드시 명시할 것:
   - 파라미터는 모두 가정값이고 하드웨어 사양 검증이 아님
   - 판정 기준은 잠정 수치 기준이며 하드웨어 정확도 기준이 아님
   - 남은 차이는 MuJoCo 적분 오차 수준
   - 시뮬레이터/모터 모델/제어기 선정은 아직 확정이 아님 (CLAUDE.md 3장 항목을 확정된 것처럼 쓰지 말 것)
   - 못 한 것: 이민혁 1단계·2-2 summary.json 미수령, MATLAB 내장 PMSM 블록 비교 안 함
6) 지어낸 내용 없이, 위 파일에 없는 건 나에게 물어봐.
7) log_progress 호출 전에 최종 본문을 먼저 보여주고, 내가 "올려"라고 하면 그때 호출해. add_task(다음 할 일 등록)도 마찬가지로 승인 후에.
```

## 7. 한 줄 요약

1~2-3단계 두 환경 PASS, RAM 기록 완료(간트 제외), RCV 미작성, 3단계는 10/04에 이민혁 정의문 받은 뒤 시작.

---

## 추가 (2026-10-04): 3단계 3-1·3-2 진행 결과

- MATLAB: `matlab -batch`로 이 PC에서 직접 실행 가능(Claude가 실행). 모델 `models/w5_stage3_{1,2}_joint.slx`(+`_gearcheck`), `config/w5s3_params.m`, `scripts/w5s3_build.m / w5s3_run.m / w5s3_compare.py / w5s3_plot.py`. 결과 CSV `matlab_results/stage3_1`, `stage3_2`.
- 3-2는 방식 A(관절 환산 0.0025 가산)만 사용. 6개 사례(3-1, 3-2 × 0.3 rad 24 V / 2 rad 24 V / 2 rad 2 V) 모두 PASS: 최대 각도 차 7.2e-6 rad, iq 3.1e-4 A, 관절 토크 4.6e-4 N·m, 정착 일치(2 V는 양쪽 미정착 N/A), 포화 구간 일치. 간격 수렴 각도 ≤1.6e-6 rad, iq ≤3.3e-5 A.
- 이민혁의 `run_stage3_3_compare.py`는 받지 못해(zip 안 열림) 같은 판정 기준으로 `w5s3_compare.py`를 따로 작성. 이민혁 도구로 교차 확인 필요.
- 묶음: `RAM_upload_2026-10-04/`(+zip, README `00_README.md`). 이민혁 1단계·2-2 summary는 `이민혁/summary_stage1_mujoco.json`, `summary_stage2_2_mujoco.json`로 받아 `RAM_upload_2026-10-03/`에 반영·zip 재생성 완료.
- RAMS 작업실: w5_hee, w5_min 칸에 3단계 추가, 결정 기록 d20261004a 추가. 간트차트는 여전히 비어 있음.
- RCV: 아직 안 씀. 초안은 `RCV_draft_W5.md`(3단계 내용 미반영 → 올리기 전에 3단계 추가 필요).

### 3-3 완료 (2026-10-04 오후)
- 이민혁 3-3 공식 비교 도구(`이민혁/MuJoCo_MATLAB_stage3_3_compare/`)를 MATLAB CSV에 실행: 3-1, 3-2 모두 Overall numerical CSV PASS (출력 `results/stage3_3_3_1_*`, `stage3_3_3_2_*`). 자체 스크립트(`w5s3_compare.py`)와 수치 동일.
- 도구 필수 열 때문에 MATLAB 전기 CSV를 23열로 확장(w5s3_build/run 수정, 해석값은 이전과 동일). 묶음 `RAM_upload_2026-10-04`에 `04_stage3-3_official_compare` 추가·zip 재생성. RAMS 칸 갱신 완료.
- RCV 초안(`RCV_draft_W5.md`)은 3-3 반영 완료, 여전히 미업로드(올리기 전 확인 필요).

### 추가 (2026-10-04 저녁)
- 태스크 변경(거의 확정): Pick-and-Place → 질량 변화에 대응하는 목표 지점 던지기. CLAUDE.md 3장, docs/decisions.md, RAMS 결정 d20261004b에 기록.
- 강동하 조사 보완본: week5/강동하/realistic_features_supplement_ko.md (+ docs/references.md, docs/simulator-survey.md 초안). 동하 RAMS 칸 memo에 반영(동하 확인 필요).
- RAMS: 간트차트를 30개 일(W5~W18)로 상세화·재게시(Version 2), 담당·진행률은 "제안 10/4, 팀 합의 필요"로 DB에 입력. 교수님께 W5 칸 완성(prof/w5 v2).
- 다음: RCV 5주차 기록 최종 정리(초안 week5/RCV_draft_W5.md는 던지기 변경과 동하 조사 반영 필요). 업로드는 항상 사용자 확인 후.
