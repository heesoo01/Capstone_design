# simulator-survey

> 초안(2026-10-04). 강동하 조사 + 보완본 기준이며 팀 확인 전이다. 시뮬레이터 선정은 확정되지 않았다. 원본: `week5/강동하/realistic_features_simulation_comparison_ko.pdf`, 보완본: `week5/강동하/realistic_features_supplement_ko.md`. 출처 목록: `docs/references.md`.

## 1. 출처표 (접속일 2026-10-04)

| # | 출처 | URL | 버전/비고 | 확인한 내용 |
|---|---|---|---|---|
| S1 | MathWorks, PWM Generator | https://www.mathworks.com/help/sps/ref/pwmgenerator.html | Simscape Electrical, R2017b 도입 | 듀티비 비교로 PWM 신호 생성 |
| S2 | MathWorks, Rotational Friction | https://www.mathworks.com/help/simscape/ref/rotationalfriction.html | Simscape Foundation | Stribeck + Coulomb + viscous 합으로 마찰 토크 |
| S3 | MathWorks, Backlash (Simulink) | https://www.mathworks.com/help/simulink/slref/backlash.html | Simulink | Deadband width, Initial output 두 파라미터 |
| S4 | MathWorks, PMSM (Simscape Electrical) | https://www.mathworks.com/help/sps/ref/pmsm.html | Simscape Electrical | 권선·회전자 열 포트, 저항·자속 온도계수 |
| S5 | MuJoCo Changelog | https://mujoco.readthedocs.io/en/stable/changelog.html | 3.7.0(2026-04-14)에 `dcmotor` 도입, 최신 3.14.0 (우리 사용 버전 3.14.0) | `dcmotor`: 전기 동역학(인덕턴스), cogging, 열 저항 변화, LuGre 마찰 |
| S6 | MuJoCo XML Reference, actuator/dcmotor | https://mujoco.readthedocs.io/en/stable/XMLreference.html | stable | `motorconst`, `resistance`, `inductance`, `thermal`, `cogging`, `lugre` 속성 |
| S7 | MuJoCo Modeling, Backlash | https://mujoco.readthedocs.io/en/latest/modeling.html (검색 결과 요약으로 확인, 2.3.0 문서에도 있음: https://mujoco.readthedocs.io/en/2.3.0/modeling.html) | 같은 위치·방향의 hinge 2개, J2 범위를 작게, J1에 armature | 이중 hinge 백래시 방법 |
| S8 | MathWorks, Export Simulink Model to Standalone FMU | https://www.mathworks.com/help/slcompiler/ug/simulinkfmuexample.html | Simulink Compiler 필요 | Simulink 모델을 FMU 2.0/3.0으로 내보냄 |
| S9 | Isaac Lab, Actuators | https://isaac-sim.github.io/IsaacLab/main/source/api/lab/isaaclab.actuators.html | main | ImplicitActuator, IdealPDActuator, DCMotor, DelayedPDActuator, RemotizedPDActuator, ActuatorNetMLP/LSTM. 문서상 전기 동역학·PWM·열 모델은 없음 |
| S10 | Modelica Standard Library, Electrical.Machines | https://doc.modelica.org/Modelica%204.0.0/Resources/helpDymola/Modelica_Electrical_Machines.html | MSL 4.0.0 | SM_PermanentMagnet(PMSM), thermalPort. 열 손실은 권선·회전자 옴 손실만 구현(Thermal 문서, MSL 3.2.3) |
| S11 | Drake, MultibodyPlant | https://drake.mit.edu/doxygen_cxx/classdrake_1_1multibody_1_1_multibody_plant.html | doxygen | JointActuator의 `gear_ratio`, `rotor_inertia`로 반사 관성 반영 |

- S7은 직접 열어 본 페이지가 아니라 검색 결과 요약으로 확인했다. 최종 보고서에 쓰기 전에 원문 절(Modeling > Backlash)을 직접 열어 확인해야 한다.
- 우리 환경: MATLAB R2026a Update 2, Simscape Electrical·Simscape Multibody·Simulink 설치 확인(2026-10-04, 이 PC). Simulink Compiler는 설치 목록에 없음 → S8의 FMU 내보내기는 이 PC에서 사용 불가(라이선스는 확인 안 함).

## 2. 평가 기준표 (점수 정의)
원본의 5/1점에는 기준이 없었으므로 아래처럼 정의한다.

| 점수 | 정의 |
|---|---|
| 5 | 기본 제공 블록/요소가 있고 파라미터 입력만으로 동작 |
| 4 | 기본 제공이 있으나 주변 요소(열 네트워크, 별도 구조 등)를 추가 구성해야 함 |
| 3 | 문서화된 구성 방법이 있으나 모델 구조를 직접 만들어야 함 |
| 2 | 관련 기능은 있으나 우리 목적(PMSM)과 다른 모델이라 직접 구현·확장이 필요 |
| 1 | 기본 기능이 없어 외부 코드로 전부 구현해야 함 |

## 3. 점수 재검토

| 현실 특성 | 원본 Simulink / MuJoCo | 보완 후 Simulink / MuJoCo | 근거 상태 |
|---|---|---|---|
| PWM·인버터 | 5 / 1 | 5 / 1 | Simulink: S1 문서 확인. MuJoCo: 기본 PWM 없음 → 우리는 평균 전압 + 외부 Python으로 구현해 **실행 확인**(2-2~3-3 일치 PASS) |
| PMSM + FOC | 5 / 2 | 5 / 2 | 동하 Simscape PMSM+FOC 구현·검증, 민혁 외부 Python PMSM, 희수 Simulink 표준 블록 구현 **실행 확인**. MuJoCo `dcmotor`(S5, S6)는 DC 모터용이라 PMSM 대체 아님 (직접 시험 안 함) |
| 마찰 | 5 / 4 | 5 / 4 | S2, MuJoCo damping·frictionloss·`dcmotor` LuGre(S5) 문서 확인. 직접 구현 시험은 아직 안 함 |
| 백래시 | 5 / 3 | 5 / 3 | S3, S7 문서 확인(S7은 요약 확인). 직접 구현 시험 안 함 |
| 열 | **5** / 2 | **4** / 2 | S4: 열 포트·온도계수는 있으나 열 네트워크(열용량·방열 경로)를 따로 구성해야 하므로 기준표상 4. 원본의 난이도 순서(열이 가장 어렵다)와 맞추기 위한 수정 |
| 기어·반사관성 | 4 / 5 | 4 / 5 | 우리 구현에서 양쪽 모두 구현·일치 **실행 확인**(3-1, 3-2). Simscape는 수식 구현, MuJoCo는 armature 사용 |
| 접촉·중력·외란 | 4 / 5 | 4 / 5 | 아직 시험 안 함 → 던지기 태스크(4절)에서 직접 확인 필요 |

- 위 점수는 여전히 정성 평가이며 "문서 확인"과 "실행 확인"을 구분해 표기했다. 마찰·백래시·열·접촉은 우리가 직접 구현해 비교하기 전이다.

## 4. 던지기 태스크 관점에서 추가해야 하는 평가 항목
원본은 Pick-and-Place를 가정했다. 태스크가 "질량 변화에 대응하는 목표 지점 던지기"로 바뀌므로 아래 항목을 평가에 넣어야 한다 (모두 아직 미평가).
- **물체 분리(릴리스) 모델링**: 던지는 순간 물체가 손을 떠나는 처리.
- **질량 변화 처리**: 실행 중 또는 시험마다 질량을 바꾸는 편의. MuJoCo는 모델 파라미터이지만 이 항목은 직접 확인 필요. MATLAB Simscape Multibody는 과거 스크립트(`s6_dynamic_mass.m`, `s7*_variable_mass.m`)로 실시간 질량 변경 가능 여부를 시도한 흔적이 있으나 **결과 기록을 확인하지 못했다** → 결과 확인 필요.
- **비행·착지 계산**: 던진 뒤 물체 궤적과 착지 오차를 평가지표로 쓰려면 비행 구간을 어디서 계산할지(시뮬레이터 안/밖) 정해야 한다.
- **고속·고토크 영역**: 던지기는 순간 토크·속도가 커서 전류·전압 포화, 반사관성 영향이 크다. 우리가 확인한 2 V 포화 일치는 이 영역의 기반 증거가 된다.
- **접촉(손에서 물체)**: 잡는 구간이 필요하면 접촉 모델이 중요하다.

## 5. 환경 연결(역할 분리 구성)의 방식과 비용
원본이 제안한 "전기는 Simulink, 기계는 MuJoCo" 구성의 연결 방식을 정리했다.

| 방식 | 내용 | 확인 상태 |
|---|---|---|
| (a) 독립 구현 + CSV 비교 | 양쪽이 같은 조건을 각자 구현하고 결과를 비교 | **실행 확인** (1~3-3단계) |
| (b) 한 쪽에서 전기를 구현하고 기계 쪽에 토크 전달 | MuJoCo + 외부 Python PMSM (민혁 방식) | **실행 확인** (2-2~3-3, 간격 6.25 µs) |
| (c) Simulink FMU 내보내기 | Simulink 모델을 FMU로 내보내 다른 툴에서 실행 (S8) | 문서 확인. Simulink Compiler 필요, 이 PC에는 미설치 |
| (d) 실시간 양방향 연동(Simulink ↔ MuJoCo) | 매 스텝 상태·토크 교환 | **미조사·미검증** |

- 현재 검증된 것은 (a)와 (b)다. 원본이 제안한 Simulink와 MuJoCo의 직접 연결은 (c)나 (d)가 필요하고 이는 아직 평가되지 않았다.
- 비용 관점의 정리: 열이나 PWM 영향을 MuJoCo에 되돌려 주려면 양방향 교환이 필요하다. 한 환경에 집중하면 이 비용이 사라지지만 해당 환경에서 부족한 현실 특성을 직접 구현해야 한다.

## 6. 기존 시뮬레이터 후보 (교수님 질문: "이미 잘 만들어진 시뮬레이터는 없는가")

| 후보 | 액추에이터/모터 관련 기능 (문서 기준) | 우리 목적과의 관계 |
|---|---|---|
| MATLAB Simulink + Simscape Electrical/Multibody | PMSM, PWM Generator, 열 포트, Backlash, Rotational Friction 제공 (S1~S4) | PMSM+FOC+PWM+열까지 한 환경에서 구성 가능. 접촉·던지기는 확인 필요 |
| MuJoCo | 강체·접촉 중심. `dcmotor`(3.7.0 이후)로 DC 모터의 인덕턴스·cogging·열·LuGre 마찰 (S5, S6). 이중 hinge 백래시 (S7) | PMSM은 직접 구현(우리가 실행 확인). 접촉·던지기 유리 가능성, 아직 시험 전 |
| Isaac Lab | ImplicitActuator, IdealPD, DCMotor(속도 기반 포화), DelayedPD, ActuatorNet(MLP/LSTM) (S9). 문서상 전기 동역학·PWM·열 없음 | 학습 기반 로봇 제어에 강점일 수 있으나 PMSM 전기 모델 용도에는 맞지 않아 보임 (직접 확인 전) |
| Modelica (MSL) | PMSM(SM_PermanentMagnet), 열 포트(옴 손실만) (S10) | 전기·열 모델링 가능. 멀티바디·접촉과의 결합은 미조사. 도구(Dymola/OpenModelica) 가용성 미확인 |
| Drake | JointActuator의 gear_ratio, rotor_inertia로 반사 관성 반영 (S11). 모터 전기 모델은 문서에서 확인하지 못함 | 반사 관성 처리는 명확하나 PMSM 전기부는 직접 구현해야 할 가능성 |

- 이 조사는 5개 후보만 다뤘고 PyBullet, Gazebo, Webots 등은 조사하지 않았다. 후보 수가 충분한지는 교수님께 확인할 사항이다.
- "한 환경에 PMSM 전기·PWM·열·접촉·던지기를 모두 내장한" 후보는 이번 조사 범위에서는 확인하지 못했다.

## 7. 보완 후 판정과 남은 일
- 출처: 공식 문서 URL·버전·접속일을 붙였다. 단, S7은 요약으로만 확인했으므로 원문 확인이 남았다.
- 점수: 기준표를 만들었고 열만 5→4로 수정했다. 나머지는 유지했다. **직접 구현해 측정한 항목은 PWM(평균 전압), PMSM 전기부, 기어·반사관성**이고 마찰·백래시·열·접촉은 문서 확인 단계다.
- 아직 안 한 것:
  1. 마찰·백래시를 양쪽에 직접 구현해 구현량과 응답을 측정
  2. Simulink ↔ MuJoCo 양방향 연동 방식(5절 (d)) 조사와 시험
  3. 던지기 관점 항목(4절) 직접 확인, 특히 MuJoCo/Simscape의 질량 변화 처리
  4. 후보 시뮬레이터 범위 확대 여부(교수님 확인)
  5. 센서 양자화·노이즈, 통신·제어 지연, 자기 포화 등 원본의 "등"에 해당하는 항목
