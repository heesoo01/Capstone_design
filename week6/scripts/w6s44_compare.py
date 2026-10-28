#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""w6s44_compare.py : 4-4 (권선 열 모델) MATLAB/Simulink 결과 vs 이민혁 MuJoCo+Python 결과 비교.

입력  : week6/matlab_results/stage4_4/*.csv        (w6s44_run.m 이 만든 파일)
        week6/이민혁/stage4/stage4/stage4_4_*/       (민혁 패키지: summary.json, CSV)
출력  : week6/results/stage4_4/ (보고서 txt, metrics json, PNG 3장)
실행  : python w6s44_compare.py

판정 기준은 세 종류이며 보고서에 출처를 구분해 적는다.
  [민혁]  민혁 README 4-4 §5 의 허용치 (그대로 사용)
  [5주차] 5주차 3단계 기준 (각도 1e-3 rad, iq 0.01 A, 관절 토크 0.015 N*m, 모터 토크 0.003 N*m, 정착 0.01 s)
  [신규]  이번에 새로 제안한 기준 -> 사용자 승인됨 (2026-10-11). 결과를 보고 바꾸지 않는다.
어느 기준도 하드웨어 정확도 기준이 아니다.
MATLAB 에 대응이 없는 민혁 검사(MuJoCo 기어 토크 배율, MuJoCo 경고 수, 4-3 평균 모델 22개 신호 회귀, 열 업데이트 0.1 ms 세분,
25/12.5/6.25 us 기동 수렴)는 하지 않았고, 비슷한 값으로 대체하지도 않았다.
"""
import os, glob, json, csv, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
W6 = os.path.abspath(os.path.join(HERE, '..'))
ML = os.environ.get('W6S44_ML', os.path.join(W6, 'matlab_results', 'stage4_4'))
OUT = os.environ.get('W6S44_OUT', os.path.join(W6, 'results', 'stage4_4'))
os.makedirs(OUT, exist_ok=True)
pyd = sorted(glob.glob(os.path.join(W6, '이민혁', 'stage4', 'stage4', 'stage4_4_*')))
if not pyd:
    sys.exit('민혁 4-4 폴더를 찾지 못했다: week6/이민혁/stage4/stage4/stage4_4_*')
PY = pyd[-1]
PS = json.load(open(os.path.join(PY, 'summary.json'), encoding='utf-8'))
PAR = PS['parameters']
RREF, ALPHA, CTH, RTH = PAR['R_ref_phase_ohm'], PAR['alpha_copper_per_K'], PAR['winding_total_heat_capacity_J_per_K'], PAR['winding_to_ambient_thermal_resistance_K_per_W']
TAMB, TREF = PAR['ambient_temperature_C'], PAR['reference_temperature_C']

MH = dict(thermal_T=1e-8, thermal_E=1e-4, total_E=0.002, elec_E=1e-7, thermal_sub=1e-6)            # [민혁] README §5
PROP = dict(angle=1e-3, iq=1e-2, torque=1.5e-2, motor_torque=3e-3, settle=1e-2)                  # [5주차]
NEW = dict(T_vs_py=2e-8, T_int_vs_py=1e-3, E_rel=1e-3)                                           # [신규] (잠정)

rep, checks, metrics = [], [], {}


def say(s=''):
    print(s)
    rep.append(s)


def chk(group, name, val, lim, src, note=''):
    ok = bool(np.isfinite(val) and val <= lim)
    checks.append(dict(group=group, name=name, value=float(val), limit=float(lim), source=src, ok=ok))
    say('  [%s] %-62s %.4g <= %.4g  [%s]%s' % ('PASS' if ok else 'FAIL', name, val, lim, src, (' ' + note) if note else ''))
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


def settle(t, q, target, t0=0.2):
    band = 0.02 * target
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


# ---------------- 해석식 (README §3 의 식에서 직접 유도) ----------------
def analytic(kind, t, t_off=300.0):
    """C dT/dt = P - (T-Tamb)/Rth.  heat: P=10 W (t<300), current: P=1.5 R(T) iq^2 (iq=2 A, t<300), cooling: T0=80, P=0."""
    th = np.zeros_like(t)
    tau = CTH * RTH
    if kind == 'cooling':
        return TAMB + 55.0 * np.exp(-t / tau)
    if kind == 'heat':
        thk = lambda x: 10.0 * RTH * (1 - np.exp(-x / tau))
    else:
        a0 = 1.5 * RREF * 2.0 ** 2 * (1 + ALPHA * (TAMB - TREF))   # = 3 W (T=Tamb=Tref 에서)
        k = a0 * ALPHA - 1.0 / RTH
        ss = -a0 / k
        thk = lambda x: ss * (1 - np.exp(k * x / CTH))
    th300 = thk(t_off)
    th = np.where(t <= t_off, thk(np.minimum(t, t_off)), th300 * np.exp(-(t - t_off) / tau))
    return TAMB + th


say('4-4 비교 보고서: MATLAB/Simulink vs 이민혁 MuJoCo+Python')
say('민혁 데이터: ' + os.path.relpath(PY, W6))
say('MATLAB 데이터: ' + os.path.relpath(ML, W6))
say('판정 기준 출처: [민혁]=README 4-4 §5, [5주차]=3단계 기준, [신규]=새 기준(사용자 승인 2026-10-11). 하드웨어 정확도 기준 아님.')
say('열 업데이트: MATLAB 통합 시험은 방식 A (1 ms 이산, 구간 평균 전력 정확해). 이 식은 처음에 CSV 의 매 1 ms 온도 변화에서 추정했고, 이후 받은 민혁 stage4_4_core.py 의 thermal_step() 과 같은 식임을 읽어서 확인했다 (민혁 쪽 재실행은 안 함).')
say('독립 열 시험: MATLAB 은 연속시간 ODE (ode45), 민혁은 같은 ODE 를 RK4 dt 0.1 s 로 적분 (stage4_4_core.py thermal_series) -> 적분기만 다르다.')

# ---- 0. 지표 정의 확인: 민혁 CSV 에 내 함수/식을 적용해 summary.json 값이 재현되는지 ----
say('\n[0] 지표 정의 확인 (민혁 CSV 에 내 함수를 적용해 summary.json 값이 재현되는지)')
PYC = {}
for c in ('baseline_fixed25', 'baseline_thermal25', 'baseline_thermal80', 'stress_thermal25', 'stress_thermal80'):
    d = py(c + '.csv')
    PYC[c] = d
    s = PS['integrated'][c]
    sl = slice(None, None, 10)                                    # 100 us -> 1 ms
    tgt = float(s['parameters']['target_rad'])
    s_my = settle(d['time_s'][sl], d['angle_rad'][sl], tgt)
    r_my = rmse(d['time_s'][sl], d['angle_rad'][sl], d['target_rad'][sl])
    s_ref = s['settling_2percent_s_after_step']
    s_ref = float('nan') if s_ref is None else s_ref
    say('  %-20s 정착 내 함수 %s / summary %s | RMSE 내 함수 %.6f / summary %.6f | 최종 T 내 %.6f / summary %.6f | 최종 입력E 내 %.6f / summary %.6f | 동손E 내 %.6f / summary %.6f' % (
        c, '%.3f' % s_my, '%.3f' % s_ref, r_my, s['tracking_rmse_rad_on_1ms_grid'], d['winding_temperature_C'][-1], s['final_temperature_C'],
        d['electrical_input_energy_J'][-1], s['final_electrical_input_energy_J'], d['copper_loss_energy_J'][-1], s['final_copper_loss_energy_J']))
    same = (np.isnan(s_my) and np.isnan(s_ref)) or abs(s_my - s_ref) < 1e-9
    ok = same and abs(r_my - s['tracking_rmse_rad_on_1ms_grid']) < 1e-9 and abs(d['winding_temperature_C'][-1] - s['final_temperature_C']) < 1e-9 \
        and abs(d['electrical_input_energy_J'][-1] - s['final_electrical_input_energy_J']) < 1e-9
    nlim = int(np.sum(d['voltage_command_limited'] > 0.5))
    say('     -> 재현 %s (정착 일치, RMSE·최종 T·최종 입력E 오차 < 1e-9) | 전압 제한 행 수 내 %d / summary %d' % ('OK' if ok else '불일치', nlim, s['voltage_limited_control_samples']))
    metrics['def_check_' + c] = dict(settle_mine=s_my, settle_summary=s_ref, rmse_mine=r_my, rmse_summary=s['tracking_rmse_rad_on_1ms_grid'], reproduced=bool(ok), limited_rows_mine=nlim, limited_summary=s['voltage_limited_control_samples'])
for kind, f in (('heat', 'thermal_constant_heat'), ('current', 'thermal_constant_current'), ('cooling', 'thermal_cooling')):
    d = py(f + '.csv')
    my_an = analytic(kind, d['time_s'])
    e1 = np.max(np.abs(my_an - d['analytic_temperature_C']))
    s = PS['thermal_only'][{'heat': 'constant_heat', 'current': 'constant_current', 'cooling': 'cooling'}[kind]]
    e2 = np.max(np.abs(d['temperature_C'] - d['analytic_temperature_C']))
    say('  %-26s 내 해석식 vs 민혁 해석 열 최대 차 %.3e C | 민혁 온도 vs 해석 열 최대 차 %.3e (summary %.3e)' % (f, e1, e2, s['max_analytic_temperature_error_C']))
    chk('0', '%s 내 해석식이 민혁 해석 온도 열과 일치 (최대 차 [C])' % f, e1, 1e-9, '신규', '(식 확인용, MATLAB 결과 아님)')
    metrics['def_check_' + f] = dict(my_analytic_vs_py_analytic=float(e1), py_vs_analytic=float(e2))

# ---- (b) 독립 열 시험 ----
say('\n[b] 독립 열 시험 600 s (이상적 열원/전류 지정, 제어기·관절 없음)')
fig, ax = plt.subplots(3, 1, figsize=(7, 8), sharex=True)
for i, (kind, f) in enumerate((('heat', 'thermal_constant_heat'), ('current', 'thermal_constant_current'), ('cooling', 'thermal_cooling'))):
    m = ml(f + '.csv')
    if m is None:
        say('  MATLAB %s.csv 없음 -> w6s44_run(''thermal'') 실행 필요' % f)
        continue
    pyd_ = py(f + '.csv')
    t = m['time_s']
    an = analytic(kind, t)
    T0 = 80.0 if kind == 'cooling' else 25.0
    eT = np.max(np.abs(m['temperature_C'] - an))
    res = m['heat_input_energy_J'] - m['heat_exported_energy_J'] - CTH * (m['temperature_C'] - T0)
    dpy = np.max(np.abs(col := (m['temperature_C'] - pyd_['temperature_C'])))
    say(' %s: T(300 s) MATLAB %.8f / 민혁 %.8f / 해석 %.8f C' % (f, m['temperature_C'][3000], pyd_['temperature_C'][3000], an[3000]))
    chk('b', '%s MATLAB 온도 vs 해석식 최대 차 [C]' % f, eT, MH['thermal_T'], '민혁')
    chk('b', '%s MATLAB 열 에너지 수지 잔차 최대 [J]' % f, np.max(np.abs(res)), MH['thermal_E'], '민혁', '(입력-방열-C*dT, 로그 격자 0.1 s)')
    chk('b', '%s MATLAB vs 민혁 온도 최대 차 [C]' % f, dpy, NEW['T_vs_py'], '신규', '(두 방식 모두 해석식에서 1e-8 이내이면 서로 2e-8 이내)')
    metrics['thermal_' + kind] = dict(max_T_err_vs_analytic=float(eT), max_energy_residual=float(np.max(np.abs(res))), max_T_diff_vs_py=float(dpy))
    ax[i].plot(t, m['temperature_C'], label='MATLAB')
    ax[i].plot(pyd_['time_s'], pyd_['temperature_C'], '--', label='MuJoCo+Python')
    ax[i].plot(t, an, ':', label='analytic')
    ax[i].set_ylabel(f.replace('thermal_', '') + ' T [C]'); ax[i].grid(alpha=.3); ax[i].legend(fontsize=8)
ax[-1].set_xlabel('time [s]')
fig.suptitle('Stage 4-4 independent thermal tests (600 s)'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_4_heating_cooling.png'), dpi=130); plt.close(fig)

# ---- (d) 통합 2 s ----
say('\n[d] 통합 2 s (평균 인버터, 열 업데이트 1 ms)')
cases = ('baseline_fixed25', 'baseline_thermal25', 'baseline_thermal80', 'stress_thermal25', 'stress_thermal80')
MLC, MLP = {}, {}
for c in cases:
    MLC[c], MLP[c] = ml(c + '.csv'), ml(c + '_position_1ms.csv')
for c in cases:
    a, ap, b = MLC[c], MLP[c], PYC[c]
    if a is None or ap is None:
        say(' %s: MATLAB 파일 없음 -> w6s44_run(''main'') 실행 필요' % c)
        continue
    s = PS['integrated'][c]
    tgt = float(s['parameters']['target_rad'])
    say(' %s: MATLAB vs 민혁' % c)
    ta, tb = a['time_s'], b['time_s']
    assert len(ta) == len(tb) and np.max(np.abs(ta - tb)) < 1e-9, '시각 격자가 다르다'
    D = lambda k: a[k] - b[k]
    sl = slice(None, None, 10)
    chk('d', '%s 최대 각도 차 [rad]' % c, np.max(np.abs(D('angle_rad'))), PROP['angle'], '5주차')
    chk('d', '%s 최대 샘플 iq 차 [A]' % c, np.max(np.abs(D('iq_A'))), PROP['iq'], '5주차')
    chk('d', '%s 최대 관절 토크 차 [N*m]' % c, np.max(np.abs(D('postgear_electromagnetic_torque_Nm'))), PROP['torque'], '5주차')
    chk('d', '%s 최대 모터 토크 차 [N*m]' % c, np.max(np.abs(D('motor_torque_Nm'))), PROP['motor_torque'], '5주차')
    s_m = settle(ap['time_s'], ap['angle_rad'], tgt)
    s_p = settle(tb[sl], b['angle_rad'][sl], tgt)
    if np.isnan(s_m) and np.isnan(s_p):
        say('  [N/A ] %s 2%% 정착시간: 양쪽 모두 관찰 구간(2 s) 안에 정착하지 않음' % c)
    elif np.isnan(s_m) != np.isnan(s_p):
        chk('d', '%s 2%% 정착시간 (한쪽만 정착: 불일치)' % c, float('inf'), PROP['settle'], '5주차', '(MATLAB %s / 민혁 %s)' % (s_m, s_p))
    else:
        chk('d', '%s 2%% 정착시간 차 [s]' % c, abs(s_m - s_p), PROP['settle'], '5주차', '(MATLAB %.3f / 민혁 %.3f s)' % (s_m, s_p))
    chk('d', '%s 최대 권선 온도 차 [C]' % c, np.max(np.abs(D('winding_temperature_C'))), NEW['T_int_vs_py'], '신규', '(1 ms 업데이트 vs 0.1 ms 세분 비교의 민혁 허용치 0.001 C 값을 재사용)')
    for key, nm in (('electrical_input_energy_J', '전기 입력'), ('copper_loss_energy_J', '동손')):
        rel = abs(a[key][-1] - b[key][-1]) / abs(b[key][-1])
        chk('d', '%s 최종 %s 에너지 상대 차' % (c, nm), rel, NEW['E_rel'], '신규', '(MATLAB %.6f / 민혁 %.6f J)' % (a[key][-1], b[key][-1]))
    chk('d', '%s MATLAB 열 에너지 수지 잔차 최대 [J]' % c, np.max(np.abs(a['thermal_energy_residual_J'])), MH['thermal_sub'], '민혁', '(이 항은 방식 A 식이 정확해라 구성상 0 에 가깝다. 독립 검증은 [b])')
    chk('d', '%s MATLAB 전기 변환 수지 잔차 최대 [J]' % c, np.max(np.abs(a['electrical_conversion_residual_J'])), MH['elec_E'], '민혁')
    chk('d', '%s MATLAB 전체 수지 잔차 최대 [J]' % c, np.max(np.abs(a['total_energy_residual_J'])), MH['total_E'], '민혁')
    say('  (참고) 추종 RMSE MATLAB %.6f / 민혁 %.6f rad, 최종 T MATLAB %.6f / 민혁 %.6f C, 최대 T MATLAB %.6f / 민혁 %.6f C' % (
        rmse(ap['time_s'], ap['angle_rad'], ap['target_rad']), s['tracking_rmse_rad_on_1ms_grid'], a['winding_temperature_C'][-1], s['final_temperature_C'],
        a['winding_temperature_C'].max(), s['max_temperature_C']))
    say('  (참고) 최대 iq MATLAB %.6f / 민혁 %.6f A (샘플 100 us), 전압 제한 행 MATLAB %d / 민혁 %d, 최종 대기 에너지 MATLAB %.3e J' % (
        np.max(np.sqrt(a['id_A'] ** 2 + a['iq_A'] ** 2)), s['peak_actual_current_vector_A'], int(np.sum(a['voltage_command_limited'] > 0.5)), s['voltage_limited_control_samples'], a['pending_thermal_energy_J'][-1]))
    say('  (참고) 최종 전체 수지 잔차 MATLAB %.3e / 민혁 %.3e J, 최대 |잔차| MATLAB %.3e / 민혁 %.3e J (부호·정의 규칙 차이 가능)' % (
        a['total_energy_residual_J'][-1], b['total_energy_residual_J'][-1], np.max(np.abs(a['total_energy_residual_J'])), s['max_total_energy_residual_J']))
    metrics['main_' + c] = dict(max_angle=float(np.max(np.abs(D('angle_rad')))), max_iq=float(np.max(np.abs(D('iq_A')))), max_dT=float(np.max(np.abs(D('winding_temperature_C')))),
                                T_final_ml=float(a['winding_temperature_C'][-1]), T_final_py=float(s['final_temperature_C']),
                                res_total_ml=float(np.max(np.abs(a['total_energy_residual_J']))), res_total_py=float(s['max_total_energy_residual_J']))
# 사례 간 관찰
if MLC['baseline_fixed25'] is not None and MLC['baseline_thermal25'] is not None and MLC['baseline_thermal80'] is not None:
    say('\n 사례 간 관찰 (합격 조건 아님)')
    f25, t25, t80 = MLC['baseline_fixed25'], MLC['baseline_thermal25'], MLC['baseline_thermal80']
    say('  baseline 24 V: 최대 iq 25 C 고정 %.5f / 열 25 C %.5f / 열 80 C %.5f A (MATLAB), 민혁 %.5f / %.5f / %.5f' % (
        f25['iq_A'].max(), t25['iq_A'].max(), t80['iq_A'].max(), PYC['baseline_fixed25']['iq_A'].max(), PYC['baseline_thermal25']['iq_A'].max(), PYC['baseline_thermal80']['iq_A'].max()))
    say('  baseline fixed25 vs thermal25 최대 각도 차 MATLAB %.3e / 민혁 %.3e rad' % (np.max(np.abs(f25['angle_rad'] - t25['angle_rad'])), np.max(np.abs(PYC['baseline_fixed25']['angle_rad'] - PYC['baseline_thermal25']['angle_rad']))))
f4 = os.path.join(W6, 'matlab_results', 'stage4_3', 'main_avg_electrical_100us.csv')
if os.path.isfile(f4) and MLC['baseline_fixed25'] is not None:
    m43 = rd(f4)
    if len(m43['time_s']) == len(MLC['baseline_fixed25']['time_s']):
        say('  MATLAB baseline_fixed25 vs MATLAB 4-3 평균 모델(main_avg) 최대 각도 차 %.3e rad, 최대 iq 차 %.3e A (같은 3-2 모델 복사 두 번째 사용, 관측값)' % (
            np.max(np.abs(MLC['baseline_fixed25']['angle_rad'] - m43['angle_rad'])), np.max(np.abs(MLC['baseline_fixed25']['iq_A'] - m43['iq_A']))))

# 그림
if all(MLC[c] is not None for c in cases):
    fig, ax = plt.subplots(3, 2, figsize=(10, 8), sharex=True)
    for j, (c25, c80, ttl) in enumerate((('baseline_thermal25', 'baseline_thermal80', 'baseline 24 V / 0.3 rad'), ('stress_thermal25', 'stress_thermal80', 'stress 4 V / 2 rad'))):
        for c, col in ((c25, 'C0'), (c80, 'C1')):
            ax[0, j].plot(MLC[c]['time_s'], MLC[c]['winding_temperature_C'], col, label='MATLAB ' + c.split('_')[1])
            ax[0, j].plot(PYC[c]['time_s'], PYC[c]['winding_temperature_C'], col + '--', label='MuJoCo+Python ' + c.split('_')[1])
            ax[1, j].plot(MLC[c]['time_s'], MLC[c]['iq_A'], col, label=c.split('_')[1])
            ax[2, j].plot(MLC[c]['time_s'], MLC[c]['angle_rad'] - PYC[c]['angle_rad'], col, label='MATLAB - Python ' + c.split('_')[1])
        ax[0, j].set_title(ttl); ax[0, j].set_ylabel('winding T [C]'); ax[1, j].set_ylabel('iq [A]'); ax[2, j].set_ylabel('angle diff [rad]'); ax[2, j].set_xlabel('time [s]')
        for r in range(3):
            ax[r, j].grid(alpha=.3); ax[r, j].legend(fontsize=7)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_4_temperature_comparison.png'), dpi=130); plt.close(fig)
    fig, ax = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    for c, col in zip(cases, ('C0', 'C1', 'C2', 'C3', 'C4')):
        ax[0].plot(MLC[c]['time_s'], MLC[c]['total_energy_residual_J'], col, label=c)
        ax[1].plot(MLC[c]['time_s'], MLC[c]['electrical_conversion_residual_J'], col, label=c)
    ax[0].set_ylabel('MATLAB total energy residual [J]'); ax[1].set_ylabel('MATLAB electrical conversion residual [J]'); ax[1].set_xlabel('time [s]')
    for r in range(2):
        ax[r].grid(alpha=.3); ax[r].legend(fontsize=7)
    fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_4_energy_balance.png'), dpi=130); plt.close(fig)

# ---- 요약 ----
say('\n[요약]')
n_ok = sum(c['ok'] for c in checks)
say('  검사 %d개 중 %d개 통과, %d개 실패' % (len(checks), n_ok, len(checks) - n_ok))
for c in checks:
    if not c['ok']:
        say('  실패: [%s] %s = %.4g (기준 %.4g, %s)' % (c['group'], c['name'], c['value'], c['limit'], c['source']))
say('  MATLAB 에서 하지 않은 것: PWM+열 통합(민혁도 안 함), 열 업데이트 0.1 ms 세분 비교와 25/12.5/6.25 us 기동 수렴(민혁은 MuJoCo 에서 확인함, MATLAB 은 가변 스텝), MuJoCo 전용 검사, 별도 PWM 동손 시험.')
say('  PASS 는 위 기준(출처 표시) 안에 들어왔다는 뜻이며 실제 하드웨어와 일치한다는 뜻이 아니다. [신규] 기준은 사용자 승인(2026-10-11)을 받았다.')
open(os.path.join(OUT, 'stage4_4_compare_report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
json.dump(dict(checks=checks, metrics=metrics), open(os.path.join(OUT, 'stage4_4_compare_metrics.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
print('\n저장: ' + OUT)
