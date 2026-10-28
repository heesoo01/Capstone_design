"""Simulink <-> MuJoCo 연동 시험용 MuJoCo 쪽 기계 모델 (1관절 + 막대 링크).

기준은 5주차 3-2 / 민혁 4-1~4-4 와 같은 조건이다.
  링크 1 kg, 0.4 x 0.05 x 0.05 m, 관절축에서 COM 까지 0.2 m  -> 관절 관성 0.0535417 kg*m^2
  회전자 관성은 관절 환산 0.0025 (armature) 를 한 번만 넣는다 -> 전체 0.0560417 kg*m^2
  점성 감쇠 0.1 N*m*s/rad, 중력 0, 건마찰·백래시·접촉 없음
  적분기 implicitfast, 물리 간격 dt (기본 25 us)
관절 입력 토크(기어 이후 N*m)는 qfrc_applied 로 직접 준다. 한 스텝 동안 토크를 유지한다 (민혁과 같은 결합 방식).
이 파일은 Simulink 의 MATLAB System 블록(MuJoCoJointSys.m)이 py. 로 호출한다.
"""
import mujoco
import numpy as np

XML = """<mujoco model="w6_cosim_joint">
  <option timestep="2.5e-05" gravity="0 0 0" integrator="implicitfast"/>
  <worldbody>
    <body name="link" pos="0 0 0">
      <joint name="hinge" type="hinge" axis="0 0 1" damping="0.1" armature="0.0025"/>
      <geom type="box" size="0.2 0.025 0.025" pos="0.2 0 0" mass="1" contype="0" conaffinity="0"/>
    </body>
  </worldbody>
</mujoco>"""


class Sim:
    def __init__(self, dt=2.5e-5):
        self.m = mujoco.MjModel.from_xml_string(XML)
        self.m.opt.timestep = float(dt)
        self.d = mujoco.MjData(self.m)
        self.n = 0

    def state(self):
        return np.array([self.d.qpos[0], self.d.qvel[0]], dtype=float)

    def step(self, tau):
        """토크 tau [N*m] 를 한 물리 스텝 동안 유지하고 스텝 후 [q, qdot] 을 돌려준다."""
        self.d.qfrc_applied[0] = float(tau)
        mujoco.mj_step(self.m, self.d)
        self.n += 1
        return np.array([self.d.qpos[0], self.d.qvel[0]], dtype=float)

    def info(self):
        """설정 확인용: 관절 전체 관성 근사(질량행렬), 감쇠, armature, 물리 간격."""
        # 정지 상태에서 1 N*m 를 주고 초기 가속도로 관절 전체 관성을 구한다 (J = tau / qacc)
        self.d.qfrc_applied[0] = 1.0
        mujoco.mj_forward(self.m, self.d)
        J = 1.0 / self.d.qacc[0]
        self.d.qfrc_applied[0] = 0.0
        mujoco.mj_forward(self.m, self.d)
        return np.array([J, self.m.dof_damping[0], self.m.dof_armature[0], self.m.opt.timestep, mujoco.mj_version()], dtype=float)


if __name__ == '__main__':
    # 단독 시험: 일정 토크 1 N*m 를 0.1 s 가한 뒤 해석해와 비교
    s = Sim(2.5e-5)
    print('info [M, damping, armature, dt, version]:', s.info())
    J, b, tau = 0.0560416666667, 0.1, 1.0
    for _ in range(4000):
        r = s.step(tau)
    t = 4000 * 2.5e-5
    w_exact = (tau / b) * (1 - np.exp(-b * t / J))
    q_exact = (tau / b) * (t - (J / b) * (1 - np.exp(-b * t / J)))
    print('t=%.3f s  MuJoCo qdot=%.8f / exact %.8f  | q=%.8f / exact %.8f' % (t, r[1], w_exact, r[0], q_exact))
