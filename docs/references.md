# references

출처가 필요한 주장은 여기에 출처와 함께 남긴다 (CLAUDE.md 7장). 아래는 현실 특성 지원 조사 보완본(`week5/강동하/realistic_features_supplement_ko.md`)에서 옮긴 것이다. 접속일 2026-10-04.

## 시뮬레이터·액추에이터 기능 조사 출처 (S1~S11)

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

