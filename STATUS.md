# STATUS

## 2026-10-12 — Simulink ↔ MuJoCo 연동 시험 (r2)

**조사 (문서 확인, 실행 아님)**: 방법 3가지. (A) MATLAB System 블록에서 `py.` 로 MuJoCo 파이썬 호출 — MathWorks 문서가 지원(Interpreted Execution). (B) MathWorks 로보틱스팀 `mujoco-simulink-blockset`(C-MEX S-Function, MuJoCo Plant 블록) — File Exchange 설명에 요구 버전이 모순(R2022b 이상 / R2026b 이상), C++ 컴파일러 필요, 이 PC 는 MATLAB 이 컴파일러를 인식하지 못해 시도하지 않음. (C) FMU — MuJoCo 의 FMU 지원은 검색에서 못 찾음(없다는 증거는 아님), Simulink FMU 내보내기는 Simulink Compiler 필요(미설치).
**시험 (실행 확인)**: (A) 방식. 5주차 3-2 모델의 전기·제어(Simulink)는 그대로 두고 기계부(Simscape)를 MATLAB System 블록 `MuJoCoJointSys`(py.mujoco 3.14.0, 물리 25 us, implicitfast)로 교체. 토크는 구간 시작 값을 구간 동안 유지(민혁과 같은 결합 순서). 24 V, 0.3 rad, 2 s, 평균 인버터.
- 결과: 연동 vs 민혁(MuJoCo+Python) 최대 각도 차 5.4e-6 rad, iq 1.7e-4 A, 관절 토크 2.5e-4 N·m, 정착 0.894 s 일치. 연동 vs Simulink+Simscape 6.8e-6 rad. 검사 15개 중 15개 통과([5주차] 기준만 사용, 새 기준 없음). 벽시계 9 s (2 s 시뮬레이션).
- 파일: `week6/scripts/cosim/` (mj_cosim.py, MuJoCoJointSys.m, w6c_build.m, w6c_run.m, w6c_compare.py), 모델 `week6/models/w6_cosim_mujoco.slx`, 결과 `week6/matlab_results/cosim/`, `week6/results/cosim/`.
- 한계: 한 사례(24 V 0.3 rad), 평균 인버터, 마찰·백래시·열·접촉·던지기 없음. MuJoCo XML 은 민혁 파일이 아니라 같은 파라미터로 새로 쓴 것(링크 1 kg 0.4x0.05x0.05, armature 0.0025, 감쇠 0.1). 양방향 실시간 연동의 일반 가능성이나 던지기 태스크에서의 동작은 확인하지 않았다. 설치한 것: 이 PC 의 Python 3.14 에 `mujoco==3.14.0` 과 의존 패키지(사용자 승인 2026-10-12).

## 2026-10-11 — week6 4단계(4-1~4-4) MATLAB/Simulink 구현·실행·비교

기준 모델은 5주차 3-2 (기어비 5, 회전자 관성 1e-4 -> 관절 환산 0.0025를 한 번만 가산). `week5/models/w5_stage3_2_joint.slx` 를 복사해 필요한 부분만 바꿨다.
민혁(MuJoCo + 외부 Python) 자료: `week6/이민혁/stage4/stage4/stage4_1~4_*`. 모든 모터·기계·열 파라미터는 가정값이고, 비교는 가정 모델끼리의 수치 일치 확인이다 (하드웨어 검증 아님).

**한 일** (전부 `matlab -batch` 로 실행, 스크립트는 `week6/scripts/w6s4X_{build,run}.m`, `w6s4X_compare.py`, 파라미터는 `week6/config/w6s4X_params.m`)
- 4-3 PWM: 이상적 3상 2레벨 PWM(10 kHz) 모델 + 평균 모델, 회전축 고정 시험, 시작 60 ms 간격 수렴
- 4-4 열: R(T) + 1 ms 열 업데이트(방식 A) + 에너지 로그, 독립 열 시험 3종(600 s), 통합 5종(2 s)
- 4-1 건마찰: Simscape Rotational Friction 블록(0.05 N·m), 속도 임계값 3개 x 시험 4개 + 마찰 없는 baseline
- 4-2 백래시: 두 회전 관절 직렬 + 관절 한계 접촉(±0.5도), 접촉 설정 6개 x 시험 3개 + rigid_reference + near_zero_gap
- 발표용 모델 구조 그림 `week6/scripts/w6_present_models.m` (그림은 `week6/results/slides/`)
- 미팅 덱(14장)과 RAMS 기록(`entries/w6_hee`, 결정 d20261011a~d, `prof/w6`)

**결과** (실행해서 확인. 결과 파일은 `week6/results/stage4_X/`, MATLAB CSV는 `week6/matlab_results/stage4_X/`)

| 단계 | 통과 / 검사 | 요약 |
|---|---|---|
| 4-3 | 43 / 43 | MATLAB vs 민혁 PWM 최대 각도 차 6.6e-5 rad, 평균 모델 1.4e-6 rad. 리플 p-p 10 kHz 0.00928 A, 20 kHz 0.00464 A(비 0.5000)로 민혁과 일치 |
| 4-4 | 67 / 67 | 독립 열 시험 해석식 대비 최대 5.5e-13 °C. 통합 5종 각도 차 baseline 7e-6 rad, stress 2.6e-4 rad. 권선 온도 차 최대 4.9e-6 °C |
| 4-1 | 56 / 69 | baseline 18/18. 건마찰: 속도 임계값 0.001 -> 15/16, 0.01 -> 16/16, 0.1(블록 기본) -> 4/16 |
| 4-2 | 56 / 109 | rigid 13/13, near_zero_gap 13/13, MATLAB 자체 수렴 5/5. backlash는 접촉 감쇠 임계근사 설정에서 각도는 대부분 통과하나 iq·토크 차가 baseline_step/reversal_steps 에서 기준 초과, 감쇠 0.01 은 접촉이 진동해 전부 크게 어긋남 |

**결정 사항** (사용자 승인 2026-10-11)
- 토크 허용치를 관절 쪽(기어 이후) 0.015 N·m / 모터 0.003 N·m 로 구분 (4-3 에서 관절 토크에 0.003 을 잘못 적용했던 것을 정정)
- [신규] 기준 승인: 4-3 네 개(리플 5%, 평균 전압 1e-3 V, 정확해 오차 1e-4 A, 평균 모델 리플 1e-4 A), 4-4 세 개(온도 차 1e-3 °C, 최종 에너지 상대 차 1e-3, 해석식 간 온도 차 2e-8 °C), 4-1·4-2 MATLAB 자체 간격 수렴 기준(민혁 README 의 MuJoCo dt 수렴 수치 재사용)
- 4-4 열 업데이트는 1 ms 이산(방식 A). 갱신 식은 처음에 CSV 에서 추정했고(구간 평균 전력 정확해, 오차 1.4e-14 °C), 이후 받은 민혁 `stage4_4_core.py` 의 `thermal_step()` 과 같은 식임을 코드를 읽어 확인(민혁 쪽 재실행은 안 함)
- 4-1·4-2 마찰·접촉 파라미터는 한 값으로 정하지 않고 여러 값으로 민감도 확인

**막힌 점 / 주의**
- 4-1·4-2 는 MuJoCo 와 Simscape 의 마찰·접촉 모델 정의가 달라, 선택한 기본 마찰·접촉 모델로는 같은 파라미터 값만으로 동등한 조건이 되지 않는다. 공통 힘 계산식을 양쪽에 구현하면 추가 비교는 가능하지만 하지 않았다. 같게 맞춘 것은 마찰 크기와 유격 폭뿐이어서 FAIL 은 구현 오류와 모델 차이를 구분할 수 없다. 판정 기준은 완화하지 않았다
- 4-2 접촉 피크 토크는 접촉 모델에 크게 의존해 판정에 쓰지 않았다. 전달 토크(유격 관절 한계 토크 합)의 운동방정식 잔차 RMS 가 0.20 N·m 로 작지 않아 참고용이다
- 4-4 열 업데이트 식은 민혁 `stage4_4_core.py` 와 같은 식임을 확인했다. 단 그 파일만 받았고 `run_stage4_4_thermal.py`, `stage4_4_pwm_reference.py` 는 못 받았다. 독립 열 시험은 민혁이 같은 ODE 를 RK4(dt 0.1 s)로 적분하고 MATLAB 은 ode45 라 적분기만 다르다. 에너지 수지 잔차 MATLAB 5e-8 J / 민혁 1.7e-5 J 차이는 결합 방식 차이이며 MATLAB 이 더 정확하다는 뜻이 아니다. stress 전기 변환 잔차 9.9e-8 J 은 기준 1e-7 에 거의 닿았다
- MATLAB 에서 하지 않은 것: PWM+열 통합(민혁도 안 함), 열 업데이트 0.1 ms 세분 비교와 25/12.5/6.25 us 수렴(민혁은 MuJoCo 에서 이미 확인함, MATLAB 은 가변 스텝이라 4-4 에서는 대응 안 함), MuJoCo 내부 검사, 4-1 단독 마찰 probe·4-2 단독 gap_probe 의 MATLAB 대응
- 속도 임계값, 접촉 강성·감쇠 값 목록과 감쇠 임계근사 2*sqrt(K*J) 는 제안·추정값이며 근거가 되는 실제 데이터가 없다

**다음에 검토받고 싶은 것**
- 민혁: 4단계 MATLAB 비교 결과 확인(특히 4-1 마찰 모델, 4-2 접촉 모델 정의 차이)- 교수님 미팅: 두 시뮬레이터가 같은 현상을 다른 모델로 구현할 때 기준을 어느 쪽으로 할지, 현실 특성 구현 범위
- RCV 연구노트는 아직 기록하지 않았다 (본문을 먼저 보여드리고 "올려" 승인 후에만 기록)
- 던지기 태스크 요구사항 정의(질량 범위, 목표 거리, 착지 오차)
