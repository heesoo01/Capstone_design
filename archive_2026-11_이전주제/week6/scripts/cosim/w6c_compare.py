#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""w6c_compare.py : Simulink(전기·제어) <-> MuJoCo(기계) 연동 시험 결과 비교.

세 가지를 같은 조건(24 V, 0.3 rad, 2 s, 평균 인버터, 5주차 3-2 파라미터)에서 비교한다.
  [연동]  Simulink 전기·제어 + MuJoCo 기계 (py.mujoco 3.14.0, 물리 25 us)          week6/matlab_results/cosim/main_*.csv
  [MATLAB] Simulink + Simscape 기계 (4-3 의 평균 모델 main_avg)                       week6/matlab_results/stage4_3/main_avg_*.csv
  [민혁]   MuJoCo + 외부 Python 전기·제어 (4-3 의 average)                             week6/이민혁/stage4/stage4/stage4_3_*/average_*.csv
판정 기준은 [5주차] 값만 쓴다 (각도 1e-3 rad, iq 0.01 A, 관절 토크 0.015 N*m, 모터 토크 0.003 N*m, 정착 0.01 s). 새 기준은 만들지 않았다.
이 시험은 연동이 동작하는지의 확인이며, 실제 하드웨어나 던지기 태스크 검증이 아니다.
"""
import os, glob, csv, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
W6 = os.path.abspath(os.path.join(HERE, '..', '..'))
CO = os.path.join(W6, 'matlab_results', 'cosim')
ML = os.path.join(W6, 'matlab_results', 'stage4_3')
OUT = os.path.join(W6, 'results', 'cosim')
os.makedirs(OUT, exist_ok=True)
PYD = sorted(glob.glob(os.path.join(W6, '이민혁', 'stage4', 'stage4', 'stage4_3_*')))
PYD = [d for d in PYD if os.path.isdir(d)][-1]
PROP = dict(angle=1e-3, iq=1e-2, torque=1.5e-2, motor_torque=3e-3, settle=1e-2)
rep, checks = [], []


def say(s=''):
    print(s); rep.append(s)


def chk(name, val, lim):
    ok = bool(np.isfinite(val) and val <= lim)
    checks.append(ok)
    say('  [%s] %-52s %.4g <= %.4g  [5주차]' % ('PASS' if ok else 'FAIL', name, val, lim))


def rd(path):
    with open(path, newline='', encoding='utf-8') as f:
        r = csv.reader(f); h = next(r); a = np.array([[float(x) for x in row] for row in r])
    return {k: a[:, i] for i, k in enumerate(h)}


def diff(a, b, k):
    assert len(a['time_s']) == len(b['time_s']) and np.max(np.abs(a['time_s'] - b['time_s'])) < 1e-9, '시각 격자가 다르다'
    return a[k] - b[k]


def settle(t, q, target=0.3, t0=0.2, band=0.006):
    idx = np.nonzero(t >= t0 - 1e-9)[0]
    out = np.nonzero(np.abs(q[idx] - target) > band)[0]
    if len(out) == 0: return 0.0
    if out[-1] == len(idx) - 1: return float('nan')
    return float(t[idx[out[-1] + 1]] - t0)


co, coP = rd(os.path.join(CO, 'main_electrical_100us.csv')), rd(os.path.join(CO, 'main_position_1ms.csv'))
ml, mlP = rd(os.path.join(ML, 'main_avg_electrical_100us.csv')), rd(os.path.join(ML, 'main_avg_position_1ms.csv'))
py, pyP = rd(os.path.join(PYD, 'average_electrical_100us.csv')), rd(os.path.join(PYD, 'average_position_1ms.csv'))
say('Simulink <-> MuJoCo 연동 시험 비교 (24 V, 0.3 rad, 2 s)')
say('연동: Simulink 전기·제어 + MuJoCo 기계 | MATLAB: Simulink + Simscape 기계 (4-3 평균 모델) | 민혁: MuJoCo + 외부 Python (4-3 average)')
say('판정 기준은 [5주차] 값만 사용. 새 기준 없음. 결과를 보고 기준을 바꾸지 않았다.')
for title, a, b, aP, bP in (('연동 vs 민혁 (MuJoCo 기계 끼리, 전기·제어 구현만 다름)', co, py, coP, pyP),
                            ('연동 vs MATLAB (전기·제어 같음, 기계만 MuJoCo vs Simscape)', co, ml, coP, mlP),
                            ('참고: MATLAB vs 민혁 (4-3 에서 이미 확인한 값)', ml, py, mlP, pyP)):
    say('\n' + title)
    chk('최대 각도 차 [rad]', np.max(np.abs(diff(a, b, 'angle_rad'))), PROP['angle'])
    chk('최대 샘플 iq 차 [A]', np.max(np.abs(diff(a, b, 'iq_A'))), PROP['iq'])
    chk('최대 관절 토크 차 [N*m]', np.max(np.abs(diff(a, b, 'postgear_electromagnetic_torque_Nm'))), PROP['torque'])
    chk('최대 모터 토크 차 [N*m]', np.max(np.abs(diff(a, b, 'motor_torque_Nm'))), PROP['motor_torque'])
    sa, sb = settle(aP['time_s'], aP['angle_rad']), settle(bP['time_s'], bP['angle_rad'])
    chk('2%% 정착시간 차 [s]  (%.3f / %.3f s)' % (sa, sb), abs(sa - sb), PROP['settle'])
    say('  (참고) 최종 각도 %.6f / %.6f rad, 최대 각도 차 위치 t=%.4f s' % (aP['angle_rad'][-1], bP['angle_rad'][-1], a['time_s'][np.argmax(np.abs(diff(a, b, 'angle_rad')))]))
say('\n[요약] 검사 %d개 중 %d개 통과' % (len(checks), sum(checks)))
say('의미: 전기·제어를 Simulink 에 두고 기계를 MuJoCo 로 바꿔도 결과가 기존 두 환경과 같은 크기 안에서 일치하는지 확인한 것이다.')
say('한계: 24 V 0.3 rad 한 사례, 평균 인버터, 마찰·백래시·열·접촉·던지기 없음. MuJoCo 모델 XML 은 민혁 파일이 아니라 같은 파라미터로 새로 쓴 것이다 (scripts/cosim/mj_cosim.py).')
open(os.path.join(OUT, 'cosim_compare_report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
fig, ax = plt.subplots(2, 1, figsize=(7.5, 6), sharex=True)
ax[0].plot(mlP['time_s'], mlP['angle_rad'], label='Simulink + Simscape')  # noqa
ax[0].plot(pyP['time_s'], pyP['angle_rad'], '--', label='MuJoCo + Python (teammate)')
ax[0].plot(coP['time_s'], coP['angle_rad'], ':', lw=2, label='Simulink + MuJoCo (연동)')
ax[0].set_ylabel('joint angle [rad]'); ax[0].legend(fontsize=8); ax[0].grid(alpha=.3)
ax[1].plot(co['time_s'], diff(co, py, 'angle_rad'), label='coupled - MuJoCo+Python')
ax[1].plot(co['time_s'], diff(co, ml, 'angle_rad'), label='coupled - Simscape')
ax[1].set_xlabel('time [s]'); ax[1].set_ylabel('angle difference [rad]'); ax[1].legend(fontsize=8); ax[1].grid(alpha=.3)
fig.suptitle('Simulink - MuJoCo co-simulation check (24 V, 0.3 rad)'); fig.tight_layout()
fig.savefig(os.path.join(OUT, 'cosim_compare.png'), dpi=130)
print('\n저장: ' + OUT)
