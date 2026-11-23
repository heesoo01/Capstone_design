#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""w6s43_compare.py : 4-3 (3상 2레벨 PWM) MATLAB/Simulink 결과 vs 이민혁 MuJoCo+Python 결과 비교.

입력  : week6/matlab_results/stage4_3/*.csv        (w6s43_run.m 이 만든 파일)
        week6/이민혁/stage4/stage4/stage4_3_*/       (민혁 패키지: summary.json, CSV)
출력  : week6/results/stage4_3/ (보고서 txt, metrics json, PNG 3장)
실행  : python w6s43_compare.py      (없는 MATLAB 파일은 건너뛰고 있는 것만 비교)

판정 기준은 세 종류이며 보고서에 출처를 구분해 적는다.
  [민혁]  민혁 README 4-3 §8(e) 의 수렴 기준 (그대로 사용)
  [5주차] 5주차 3단계에서 쓴 잠정 기준 재사용 (각도 1e-3 rad, iq 0.01 A, 토크 0.003 N*m, 정착 0.01 s)
  [신규]  이번에 새로 제안한 기준 (리플 5 %, 평균 전압 1e-3 V, 정확해 오차 1e-4 A, 평균 모델 리플 1e-4 A) -> 승인됨 (사용자, 2026-10-11). 승인 후에도 하드웨어 기준 아님
어느 기준도 하드웨어 정확도 기준이 아니다.
"""
import os, glob, json, csv, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
W6 = os.path.abspath(os.path.join(HERE, '..'))
ML = os.environ.get('W6S43_ML', os.path.join(W6, 'matlab_results', 'stage4_3'))
OUT = os.environ.get('W6S43_OUT', os.path.join(W6, 'results', 'stage4_3'))
os.makedirs(OUT, exist_ok=True)
pyd = sorted(glob.glob(os.path.join(W6, '이민혁', 'stage4', 'stage4', 'stage4_3_*')))
if not pyd:
    sys.exit('민혁 4-3 폴더를 찾지 못했다: week6/이민혁/stage4/stage4/stage4_3_*')
PY = pyd[-1]
PS = json.load(open(os.path.join(PY, 'summary.json'), encoding='utf-8'))
PAR = PS['parameters']
VDC, R, L = PAR['VDC'], PAR['R'], PAR['L']
TS = PAR['CURRENT_TS']

CONV = dict(angle=5e-4, speed=1e-2, iq=3e-3, iqmean=3e-3)             # [민혁]
PROP = dict(angle=1e-3, iq=1e-2, torque=1.5e-2, motor_torque=3e-3, settle=1e-2)   # [5주차] w5s3_compare.py TOL: tj(관절 입력 토크)=0.015, tm(모터 토크)=0.003
# 2026-10-11 정정: 관절 쪽(기어 이후) 토크에 모터 토크 허용치 0.003 을 잘못 적용했었다. 사용자 승인 후 0.015(관절)/0.003(모터)로 분리.
NEW = dict(ripple_rel=0.05, volt_mean=1e-3, ref_iq=1e-4, avg_ripple=1e-4)   # [신규]

rep = []
checks = []
metrics = {}


def say(s=''):
    print(s)
    rep.append(s)


def chk(group, name, val, lim, src, note=''):
    ok = bool(np.isfinite(val) and val <= lim)
    checks.append(dict(group=group, name=name, value=float(val), limit=float(lim), source=src, ok=ok))
    say('  [%s] %-58s %.4g <= %.4g  [%s]%s' % ('PASS' if ok else 'FAIL', name, val, lim, src, (' ' + note) if note else ''))
    return ok


def rd(path):
    with open(path, newline='', encoding='utf-8') as f:
        r = csv.reader(f)
        h = next(r)
        a = np.array([[float(x) for x in row] for row in r])
    return {k: a[:, i] for i, k in enumerate(h)}


def ml(name):
    p = os.path.join(ML, name)
    return rd(p) if os.path.isfile(p) else None


def py(name):
    return rd(os.path.join(PY, name))


def col_diff(a, b, key):
    """같은 시각 격자에서 열 차이 (격자가 다르면 b 를 a 시각으로 선형 보간)."""
    ta, tb = a['time_s'], b['time_s']
    if len(ta) == len(tb) and np.max(np.abs(ta - tb)) < 1e-9:
        return a[key] - b[key]
    return a[key] - np.interp(ta, tb, b[key])


def settle(t, q, target=0.3, t0=0.2, band=0.006):
    idx = np.nonzero(t >= t0 - 1e-9)[0]
    out = np.nonzero(np.abs(q[idx] - target) > band)[0]
    if len(out) == 0:
        return 0.0
    if out[-1] == len(idx) - 1:
        return float('nan')
    return float(t[idx[out[-1] + 1]] - t0)


def rmse(t, q, tgt, t0=0.2):
    w = t >= t0 - 1e-9
    return float(np.sqrt(np.mean((q[w] - tgt[w]) ** 2)))


def cycle_pp(t, y, grid):
    out = np.zeros(len(grid))
    for k in range(1, len(grid)):
        a, b = grid[k - 1], grid[k]
        i0, i1 = np.searchsorted(t, a, 'left'), np.searchsorted(t, b, 'right')
        v = np.concatenate([y[i0:i1], [np.interp(a, t, y), np.interp(b, t, y)]])
        out[k] = v.max() - v.min()
    return out


def window(t, y, a, b):
    m = (t > a) & (t < b)
    return np.concatenate([[a], t[m], [b]]), np.concatenate([[np.interp(a, t, y)], y[m], [np.interp(b, t, y)]])


def pp_window(t, y, a, b):
    _, yy = window(t, y, a, b)
    return float(yy.max() - yy.min())


def mean_window(t, y, a, b):
    tt, yy = window(t, y, a, b)
    integ = getattr(np, 'trapezoid', None) or np.trapz
    return float(integ(yy, tt) / (b - a))


# ---------------- 민혁 정의 그대로의 변환 (README §4) ----------------
def duty_from_dq(vd, vq, th):
    al = vd * np.cos(th) - vq * np.sin(th)
    be = vd * np.sin(th) + vq * np.cos(th)
    v = np.array([al, -al / 2 + np.sqrt(3) * be / 2, -al / 2 - np.sqrt(3) * be / 2])
    u0 = -(v.max() + v.min()) / 2
    return v, 0.5 + (v + u0) / VDC


def segments(duty, T, mode, vcmd):
    """한 PWM 주기를 전환 시각으로 나눈 (tau0, tau1, v_alpha, v_beta). 캐리어 c=|2tau/T-1|, S_k=(duty_k>c)."""
    if mode == 'avg':
        return [(0.0, T, vcmd[0], (vcmd[1] - vcmd[2]) / np.sqrt(3))]
    edges = sorted(set([0.0, T] + [(1 - d) * T / 2 for d in duty] + [(1 + d) * T / 2 for d in duty]))
    segs = []
    for a, b in zip(edges[:-1], edges[1:]):
        if b - a <= 1e-15:
            continue
        c = abs(2 * (a + b) / 2 / T - 1)
        S = np.array([1.0 if d > c else 0.0 for d in duty])
        v = VDC * (S - S.mean())
        segs.append((a, b, v[0], (v[1] - v[2]) / np.sqrt(3)))
    return segs


def prop(i, v, d):
    a = np.exp(-R * d / L)
    return v / R + (i - v / R) * a


def held_ref(t_eval, segs, T):
    """회전자 고정(theta_e = 0, we = 0)에서 alpha-beta R-L 의 구간별 정확해. 반환 [i_alpha(=id), i_beta(=iq)]."""
    N = int(np.ceil(t_eval.max() / T)) + 2
    i0 = np.zeros((N + 1, 2))
    for n in range(N):
        i = i0[n].copy()
        for a, b, va, vb in segs:
            i = np.array([prop(i[0], va, b - a), prop(i[1], vb, b - a)])
        i0[n + 1] = i
    n = np.minimum(np.floor(t_eval / T + 1e-12).astype(int), N)
    tau = t_eval - n * T
    cur = i0[n].copy()
    for a, b, va, vb in segs:
        d = np.clip(tau - a, 0, b - a)
        cur[:, 0] = prop(cur[:, 0], va, d)
        cur[:, 1] = prop(cur[:, 1], vb, d)
    return cur


# =====================================================================
say('4-3 비교 보고서: MATLAB/Simulink vs 이민혁 MuJoCo+Python')
say('민혁 데이터: ' + os.path.relpath(PY, W6))
say('MATLAB 데이터: ' + os.path.relpath(ML, W6))
say('판정 기준 출처: [민혁]=README 4-3 §8(e), [5주차]=3단계 잠정 기준 재사용, [신규]=새 기준(사용자 승인 2026-10-11). 하드웨어 정확도 기준 아님.')

# ---- 0. 지표 정의 확인: 민혁 summary.json 값을 내 함수로 재현하는가 ----
say('\n[0] 지표 정의 확인 (민혁 CSV 에 내 함수를 적용해 summary.json 값이 재현되는지)')
for run, f in (('pwm', 'pwm_position_1ms.csv'), ('average', 'average_position_1ms.csv')):
    d = py(f)
    s_my, r_my = settle(d['time_s'], d['angle_rad']), rmse(d['time_s'], d['angle_rad'], d['target_rad'])
    s_ref, r_ref = PS['runs'][run]['settling_2percent_s_after_step'], PS['runs'][run]['tracking_rmse_rad_1ms_grid_after_step']
    say('  %-8s 정착 내 함수 %.3f s / summary %.3f s | RMSE 내 함수 %.6f / summary %.6f' % (run, s_my, s_ref, r_my, r_ref))
    metrics['def_check_' + run] = dict(settle_mine=s_my, settle_summary=s_ref, rmse_mine=r_my, rmse_summary=r_ref)

# ---- (a) 변환식: 민혁 CSV 의 duty 를 내 식(= Simulink 에 넣은 식)으로 재현 ----
say('\n[a] 변환식 확인: 민혁 CSV 의 vd/vq/전기각으로 내 duty 식을 계산해 민혁 duty 와 비교')
d = py('pwm_electrical_100us.csv')
dm = 0.0
for i in range(0, len(d['time_s']), 7):
    _, du = duty_from_dq(d['vd_command_V'][i], d['vq_command_V'][i], d['electrical_angle_rad'][i])
    dm = max(dm, np.max(np.abs(du - np.array([d['duty_a'][i], d['duty_b'][i], d['duty_c'][i]]))))
chk('a', '내 duty 식 vs 민혁 duty (최대 차)', dm, 1e-9, '신규', '(식 확인용, MATLAB 결과 아님)')

# ---- (e) 시작 60 ms: MATLAB 수렴 + MATLAB vs 민혁 ----
say('\n[e] 시작 60 ms (5 ms 에 0.3 rad)')
tags = ['_dt5us', '_dt2p5us', '_dt1p25us']
S = {t: ml('startup_pwm%s_electrical_100us.csv' % t) for t in tags}
if all(S[t] is not None for t in tags):
    fine = S['_dt1p25us']
    say(' MATLAB 수렴 (기준: 최대 스텝 1.25 us 와의 차이, 100 us 격자)')
    conv = {}
    for t in tags[:2]:
        a = S[t]
        conv[t] = dict(angle=np.max(np.abs(col_diff(a, fine, 'angle_rad'))), speed=np.max(np.abs(col_diff(a, fine, 'velocity_rad_s'))),
                       iq=np.max(np.abs(col_diff(a, fine, 'iq_A'))), iqmean=np.max(np.abs(col_diff(a, fine, 'previous_cycle_mean_iq_A'))))
    for key, nm in (('angle', '각도 [rad]'), ('speed', '속도 [rad/s]'), ('iq', '샘플 iq [A]'), ('iqmean', '주기 평균 iq [A]')):
        chk('e', 'MATLAB 5 us vs 1.25 us 최대 차 %s' % nm, conv['_dt5us'][key], CONV[key], '민혁')
    ok = conv['_dt2p5us']['angle'] <= conv['_dt5us']['angle']
    say('  [%s] 간격을 줄이면 각도 차가 감소: 5 us %.3e -> 2.5 us %.3e rad' % ('PASS' if ok else 'FAIL', conv['_dt5us']['angle'], conv['_dt2p5us']['angle']))
    metrics['startup_convergence'] = conv
    say(' MATLAB(1.25 us) vs 민혁 PWM(1.25 us)')
    pyf = py('startup_pwm_dt1p25us.csv')
    st = dict(angle=np.max(np.abs(col_diff(fine, pyf, 'angle_rad'))), iq=np.max(np.abs(col_diff(fine, pyf, 'iq_A'))),
              iqmean=np.max(np.abs(col_diff(fine, pyf, 'previous_cycle_mean_iq_A'))), torque=np.max(np.abs(col_diff(fine, pyf, 'postgear_electromagnetic_torque_Nm'))),
              speed=np.max(np.abs(col_diff(fine, pyf, 'velocity_rad_s'))))
    chk('e', '최대 각도 차 [rad]', st['angle'], PROP['angle'], '5주차')
    chk('e', '최대 샘플 iq 차 [A]', st['iq'], PROP['iq'], '5주차')
    chk('e', '최대 주기 평균 iq 차 [A]', st['iqmean'], PROP['iq'], '5주차')
    chk('e', '최대 관절 토크 차 [N*m]', st['torque'], PROP['torque'], '5주차')
    chk('e', '최대 모터 토크 차 [N*m]', np.max(np.abs(col_diff(fine, pyf, 'motor_torque_Nm'))), PROP['motor_torque'], '5주차')
    say('  (참고) 최대 속도 차 %.3e rad/s' % st['speed'])
    metrics['startup_vs_python'] = st
    fig, ax = plt.subplots(2, 1, figsize=(7, 5), sharex=True)
    ax[0].plot(fine['time_s'] * 1e3, fine['angle_rad'], label='MATLAB 1.25us')
    ax[0].plot(pyf['time_s'] * 1e3, pyf['angle_rad'], '--', label='MuJoCo+Python 1.25us')
    ax[0].set_ylabel('joint angle [rad]'); ax[0].legend(); ax[0].grid(alpha=.3)
    ax[1].plot(fine['time_s'] * 1e3, col_diff(fine, pyf, 'angle_rad'), label='MATLAB - Python')
    for t in tags[:2]:
        ax[1].plot(S[t]['time_s'] * 1e3, col_diff(S[t], fine, 'angle_rad'), label='MATLAB %s - 1.25us' % t[3:])
    ax[1].set_xlabel('time [ms]'); ax[1].set_ylabel('angle difference [rad]'); ax[1].legend(); ax[1].grid(alpha=.3)
    fig.suptitle('Stage 4-3 startup (60 ms)'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_3_startup_compare.png'), dpi=130); plt.close(fig)
else:
    say('  MATLAB startup 파일이 없다 -> w6s43_run(''startup'') 실행 필요')
sa = ml('startup_avg_dt5us_electrical_100us.csv')
if sa is not None:
    say(' MATLAB 평균(5 us) vs 민혁 평균 (MuJoCo / 독립 ODE)')
    for nm, f in (('MuJoCo', 'startup_average_mujoco.csv'), ('독립 ODE', 'startup_average_independent_ODE.csv')):
        pa = py(f)
        say('   vs %-8s 최대 각도 차 %.3e rad | 최대 샘플 iq 차 %.3e A | 최대 주기 평균 iq 차 %.3e A' % (nm, np.max(np.abs(col_diff(sa, pa, 'angle_rad'))),
            np.max(np.abs(col_diff(sa, pa, 'iq_A'))), np.max(np.abs(col_diff(sa, pa, 'previous_cycle_mean_iq_A')))))

# ---- (c) 회전축 고정 ----
say('\n[c] 회전축 고정: vd=0, vq=1 V, 0.1 s, 초기 전류 0')
vabc, du = duty_from_dq(0.0, 1.0, 0.0)
held = {}
for tag, mode, T, pyfile, pykey in (('held_pwm10k', 'pwm', 1e-4, 'held_rotor_pwm_10kHz.csv', 'pwm_10kHz'),
                                    ('held_pwm20k', 'pwm', 5e-5, 'held_rotor_pwm_20kHz.csv', 'pwm_20kHz'),
                                    ('held_avg', 'avg', 1e-4, 'held_rotor_average.csv', 'average')):
    segs = segments(du, T, mode, vabc)
    pyd_ = py(pyfile)
    ref_py = held_ref(pyd_['time_s'], segs, T)
    e_ref_py = max(np.max(np.abs(ref_py[:, 0] - pyd_['id_A'])), np.max(np.abs(ref_py[:, 1] - pyd_['iq_A'])))
    say(' %s: 내 정확해 vs 민혁 CSV 최대 차 %.3e A (정확해 검증용)' % (tag, e_ref_py))
    m = ml(tag + '.csv')
    held[tag] = dict(T=T, mode=mode, segs=segs, py=pyd_, pykey=pykey, ml=m)
    if m is None:
        say('  MATLAB %s.csv 없음 -> w6s43_run(''held'') 실행 필요' % tag)
        continue
    t = m['time_s']
    ref = held_ref(t, segs, T)
    chk('c', '%s MATLAB iq vs 정확해 최대 차 [A]' % tag, np.max(np.abs(ref[:, 1] - m['iq_A'])), NEW['ref_iq'], '신규')
    chk('c', '%s MATLAB id vs 정확해 최대 차 [A]' % tag, np.max(np.abs(ref[:, 0] - m['id_A'])), NEW['ref_iq'], '신규')
    te = 0.1
    m10 = mean_window(t, m['iq_A'], te - 0.01, te)
    m10_py = PS['held_rotor'][pykey]['mean_iq_A_final_10ms']
    chk('c', '%s 마지막 10 ms 평균 iq 민혁과 차 [A]' % tag, abs(m10 - m10_py), 1e-4, '신규', '(MATLAB %.8f / 민혁 %.8f)' % (m10, m10_py))
    ppm = pp_window(t, m['iq_A'], te - T, te)
    ppp = PS['held_rotor'][pykey]['last_period_iq_peak_to_peak_A']
    if mode == 'pwm':
        chk('c', '%s 마지막 주기 iq 리플(p-p) 민혁과 상대차' % tag, abs(ppm - ppp) / ppp, NEW['ripple_rel'], '신규', '(MATLAB %.6g / 민혁 %.6g A)' % (ppm, ppp))
        lv = np.concatenate([m['va_V'] - m['vb_V'], m['vb_V'] - m['vc_V'], m['vc_V'] - m['va_V']])
        dist = np.min(np.abs(lv[:, None] - np.array([-VDC, 0.0, VDC])[None, :]), axis=1).max()
        chk('c', '%s 선간 전압이 -24/0/+24 V 중 하나 (최대 거리 [V])' % tag, dist, 1e-6, '신규')
    else:
        chk('c', '%s 평균 모델 iq 리플(p-p) [A]' % tag, ppm, NEW['avg_ripple'], '신규', '(민혁 %.3g A)' % ppp)
    chk('c', '%s 세 상전압 합 최대 [V]' % tag, np.max(np.abs(m['va_V'] + m['vb_V'] + m['vc_V'])), 1e-9, '신규')
    held[tag].update(m10=m10, pp=ppm)
    metrics[tag] = dict(mean_iq_last10ms=m10, iq_pp_last_period=ppm, py_mean=m10_py, py_pp=ppp)
if held['held_pwm10k'].get('pp') and held['held_pwm20k'].get('pp'):
    r = held['held_pwm20k']['pp'] / held['held_pwm10k']['pp']
    pr = PS['held_rotor']['pwm_20kHz']['last_period_iq_peak_to_peak_A'] / PS['held_rotor']['pwm_10kHz']['last_period_iq_peak_to_peak_A']
    say('  20 kHz / 10 kHz 리플 비: MATLAB %.4f / 민혁 %.4f (20 kHz 에서 줄어드는지 확인)' % (r, pr))
if held['held_pwm10k'].get('ml') is not None and held['held_pwm20k'].get('ml') is not None:
    fig, ax = plt.subplots(figsize=(7, 4))
    for tag, c in (('held_pwm10k', 'C1'), ('held_pwm20k', 'C0')):
        h = held[tag]
        m = h['ml']; a, b = 0.1 - 2e-4, 0.1
        w = (m['time_s'] >= a) & (m['time_s'] <= b)
        ax.plot((m['time_s'][w] - a) * 1e6, m['iq_A'][w], c, label='MATLAB ' + tag[5:])
        pdv = h['py']; w2 = (pdv['time_s'] >= a) & (pdv['time_s'] <= b)
        ax.plot((pdv['time_s'][w2] - a) * 1e6, pdv['iq_A'][w2], c + '--', label='MuJoCo+Python ' + tag[5:])
    ax.set_xlabel('time [us] (from 0.0998 s)'); ax.set_ylabel('iq [A]'); ax.legend(fontsize=8); ax.grid(alpha=.3)
    ax.set_title('Stage 4-3 held-rotor current ripple'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_3_held_rotor_ripple.png'), dpi=130); plt.close(fig)

# 평균 전압(주기 평균) 확인: 고정 회전자 xlog
for tag in ('held_pwm10k', 'held_pwm20k'):
    x = ml(tag + '_xlog.csv')
    if x is None:
        continue
    e = []
    for k in range(1, len(x['time_s'])):
        dut = np.array([x['duty_a'][k], x['duty_b'][k], x['duty_c'][k]])
        mean_v = np.array([x['int_va_Vs'][k] - x['int_va_Vs'][k - 1], x['int_vb_Vs'][k] - x['int_vb_Vs'][k - 1], x['int_vc_Vs'][k] - x['int_vc_Vs'][k - 1]]) / TS
        e.append(np.max(np.abs(mean_v - VDC * (dut - dut.mean()))))
    chk('c', '%s 100 us 평균 상전압 vs 24*(duty-평균 duty) 최대 차 [V]' % tag, max(e), NEW['volt_mean'], '신규')

# ---- (d) 통합 2 s ----
say('\n[d] 통합 2 s (0.2 s 에 0.3 rad)')
M = {k: ml('main_%s_electrical_100us.csv' % k) for k in ('pwm', 'avg')}
MP = {k: ml('main_%s_position_1ms.csv' % k) for k in ('pwm', 'avg')}
if M['pwm'] is not None and MP['pwm'] is not None:
    P = {'pwm': (py('pwm_electrical_100us.csv'), py('pwm_position_1ms.csv'), PS['runs']['pwm']),
         'avg': (py('average_electrical_100us.csv'), py('average_position_1ms.csv'), PS['runs']['average'])}
    for k in ('pwm', 'avg'):
        if M[k] is None or MP[k] is None:
            continue
        pe, pp_, run = P[k]
        a, b = M[k], pe
        say(' %s: MATLAB vs 민혁 (%s)' % (k, '이상적 PWM' if k == 'pwm' else '평균 인버터'))
        chk('d', '%s 최대 각도 차 [rad]' % k, np.max(np.abs(col_diff(a, b, 'angle_rad'))), PROP['angle'], '5주차')
        chk('d', '%s 최대 샘플 iq 차 [A]' % k, np.max(np.abs(col_diff(a, b, 'iq_A'))), PROP['iq'], '5주차')
        chk('d', '%s 최대 주기 평균 iq 차 [A]' % k, np.max(np.abs(col_diff(a, b, 'previous_cycle_mean_iq_A'))), PROP['iq'], '5주차')
        chk('d', '%s 최대 관절 토크 차 [N*m]' % k, np.max(np.abs(col_diff(a, b, 'postgear_electromagnetic_torque_Nm'))), PROP['torque'], '5주차')
        chk('d', '%s 최대 모터 토크 차 [N*m]' % k, np.max(np.abs(col_diff(a, b, 'motor_torque_Nm'))), PROP['motor_torque'], '5주차')
        s_m, s_p = settle(MP[k]['time_s'], MP[k]['angle_rad']), settle(pp_['time_s'], pp_['angle_rad'])
        chk('d', '%s 2%% 정착시간 차 [s]' % k, abs(s_m - s_p), PROP['settle'], '5주차', '(MATLAB %.3f / 민혁 %.3f s)' % (s_m, s_p))
        r_m, r_p = rmse(MP[k]['time_s'], MP[k]['angle_rad'], MP[k]['target_rad']), run['tracking_rmse_rad_1ms_grid_after_step']
        say('  (참고) 추종 RMSE MATLAB %.6f / 민혁 %.6f rad, 최종 오차 MATLAB %.3e / 민혁 %.3e rad' % (r_m, r_p, abs(MP[k]['angle_rad'][-1] - 0.3), run['final_error_rad']))
        say('  (참고) 전압 지령 제한 횟수 MATLAB %d / 민혁 %d' % (int(np.sum(a['voltage_command_limited'] > 0.5)), run['voltage_command_limited_cycles']))
        metrics['main_' + k] = dict(settle_ml=s_m, settle_py=s_p, rmse_ml=r_m, rmse_py=r_p)
        # 평균 전압 / 주기 평균 확인
        dut = np.vstack([a['duty_a'], a['duty_b'], a['duty_c']])
        vmean = np.vstack([a['previous_cycle_mean_va_V'], a['previous_cycle_mean_vb_V'], a['previous_cycle_mean_vc_V']])
        exp0 = VDC * (dut[:, :-1] - dut[:, :-1].mean(axis=0))      # 행 k-1 에서 정한 duty 가 [t_{k-1}, t_k] 에 유지됐다고 가정
        exp1 = VDC * (dut[:, 1:] - dut[:, 1:].mean(axis=0))        # 행 k 의 duty 가 직전 주기에 해당하는 경우
        e0, e1 = np.max(np.abs(vmean[:, 1:] - exp0)), np.max(np.abs(vmean[:, 1:] - exp1))
        chk('d', '%s 100 us 평균 상전압 vs 24*(duty-평균 duty) 최대 차 [V]' % k, min(e0, e1), NEW['volt_mean'], '신규',
            '(duty 로그 정렬: %s)' % ('행 k-1 duty -> 주기 [k-1,k]' if e0 <= e1 else '행 k duty -> 직전 주기 (로그 시점이 한 행 어긋남, 확인 필요)'))
    if M['pwm'] is not None and M['avg'] is not None:
        say(' MATLAB PWM vs MATLAB 평균 (같은 모델 두 인버터)')
        mx = np.max(np.abs(col_diff(M['pwm'], M['avg'], 'angle_rad')))
        rm = np.sqrt(np.mean(col_diff(M['pwm'], M['avg'], 'previous_cycle_mean_iq_A') ** 2))
        say('  최대 각도 차 MATLAB %.3e rad / 민혁 %.3e rad ; 주기 평균 iq RMS 차 MATLAB %.3e A / 민혁 %.3e A (관측값, 합격 조건 아님)' %
            (mx, PS['comparison']['max_angle_difference_rad'], rm, PS['comparison']['rms_cycle_mean_iq_difference_A']))
        metrics['main_pwm_vs_avg'] = dict(max_angle=mx, rms_cycle_iq=rm)
    # 주기 내 iq 최대-최소
    ia = ml('main_pwm_iq_allsteps.csv')
    if ia is not None:
        pp_cyc = cycle_pp(ia['time_s'], ia['iq_A'], M['pwm']['time_s'])
        pe = P['pwm'][0]
        say(' 주기 내 iq 최대-최소(스위칭 시각 포함): MATLAB 최대 %.5f A / 민혁 최대 %.5f A (제어 과도응답 변화 포함, 관측값)' % (pp_cyc.max(), PS['runs']['pwm']['max_cycle_iq_peak_to_peak_A']))
        metrics['main_cycle_pp'] = dict(ml_max=float(pp_cyc.max()), py_max=PS['runs']['pwm']['max_cycle_iq_peak_to_peak_A'])
    fig, ax = plt.subplots(2, 1, figsize=(7, 5), sharex=True)
    for k, c in (('pwm', 'C1'), ('avg', 'C0')):
        if MP[k] is None:
            continue
        pp_ = P[k][1]
        ax[0].plot(MP[k]['time_s'], MP[k]['angle_rad'], c, label='MATLAB ' + k)
        ax[0].plot(pp_['time_s'], pp_['angle_rad'], c + '--', label='MuJoCo+Python ' + k)
        ax[1].plot(MP[k]['time_s'], col_diff(MP[k], pp_, 'angle_rad'), c, label='MATLAB - Python (%s)' % k)
    ax[0].set_ylabel('joint angle [rad]'); ax[0].legend(fontsize=8); ax[0].grid(alpha=.3)
    ax[1].set_xlabel('time [s]'); ax[1].set_ylabel('angle difference [rad]'); ax[1].legend(fontsize=8); ax[1].grid(alpha=.3)
    fig.suptitle('Stage 4-3 integrated response (24 V, 0.3 rad)'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_3_position_compare.png'), dpi=130); plt.close(fig)
else:
    say('  MATLAB main 파일이 없다 -> w6s43_run(''main'') 실행 필요')

# ---- 요약 ----
say('\n[요약]')
n_ok = sum(c['ok'] for c in checks)
say('  검사 %d개 중 %d개 통과, %d개 실패' % (len(checks), n_ok, len(checks) - n_ok))
for c in checks:
    if not c['ok']:
        say('  실패: [%s] %s = %.4g (기준 %.4g, %s)' % (c['group'], c['name'], c['value'], c['limit'], c['source']))
say('  PASS 는 위 기준(출처 표시) 안에 들어왔다는 뜻이며 실제 하드웨어와 일치한다는 뜻이 아니다. [신규] 기준은 사용자 승인(2026-10-11)을 받았다.')
open(os.path.join(OUT, 'stage4_3_compare_report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
json.dump(dict(checks=checks, metrics=metrics), open(os.path.join(OUT, 'stage4_3_compare_metrics.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
print('\n저장: ' + OUT)
