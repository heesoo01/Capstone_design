"""2-2(24 V, 0.3 rad) MuJoCo vs MATLAB 비교. 사용: python w5s2_2_compare.py
이민혁 README_stage2_2.txt의 합의 기준: 각도 <=0.001 rad, 정착시간 차이 <=0.01 s, iq <=0.01 A, 관절 토크 <=0.003 N*m"""
import csv, math, io, sys, os, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
MU = os.path.join(W5, '이민혁'); RES = os.path.join(W5, 'results')

def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.DictReader(f)
        cols = {k: [] for k in r.fieldnames}
        for row in r:
            for k in cols: cols[k].append(float(row[k]))
    return cols

def settle(t, q, target, band, t0=0.2):
    idx = [i for i in range(len(t)) if t[i] >= t0 - 1e-9]
    last = None
    for i in idx:
        if abs(q[i] - target) > band: last = i
    if last is None: return 0.0
    if last == idx[-1]: return None
    return t[last + 1] - t0

def rmse(a, b, mask):
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in mask) / len(mask))

TOL = dict(q=1e-3, iq=1e-2, tq=3e-3, ts=1e-2)
TARGET = 0.3; BAND = 0.006; VLIM = 24 / math.sqrt(3)
mp = load(os.path.join(MU, 'position_dt6p25us.csv')); me = load(os.path.join(MU, 'electrical_dt6p25us.csv'))
lp = load(os.path.join(RES, 'w5s2_2-2_24V_matlab_pos_dt6p25us.csv')); le = load(os.path.join(RES, 'w5s2_2-2_24V_matlab_elec_dt6p25us.csv'))
tp = mp['time_s']; te = me['time_s']; n = len(te)
r = {}
r['rows'] = dict(mu_pos=len(tp), mu_el=n, ml_pos=len(lp['time_s']), ml_el=len(le['time_s']))
r['time_axis_max_diff_pos'] = max(abs(a - b) for a, b in zip(tp, lp['time_s']))
r['time_axis_max_diff_elec'] = max(abs(a - b) for a, b in zip(te, le['time_s']))
r['target_max_diff'] = max(abs(a - b) for a, b in zip(mp['target_rad'], lp['target_rad']))
dq = [lp['angle_rad'][i] - mp['angle_rad'][i] for i in range(len(tp))]
dv = [lp['velocity_rad_s'][i] - mp['velocity_rad_s'][i] for i in range(len(tp))]
i_dq = max(range(len(dq)), key=lambda i: abs(dq[i]))
wpos = [i for i in range(len(tp)) if 0.2 - 1e-9 <= tp[i] <= 2.0 + 1e-9]
r['max_dq'] = abs(dq[i_dq]); r['t_max_dq'] = tp[i_dq]
r['max_dv'] = max(abs(x) for x in dv)
r['env_rmse_q'] = math.sqrt(sum(dq[i] ** 2 for i in wpos) / len(wpos)); r['n_wpos'] = len(wpos)
for nm, p in (('mu', mp), ('ml', lp)):
    r['track_rmse_' + nm] = rmse(p['angle_rad'], p['target_rad'], wpos)
    r['settle_' + nm] = settle(tp, p['angle_rad'], TARGET, BAND)
    r['peak_speed_' + nm] = max(abs(p['velocity_rad_s'][i]) for i in range(len(tp)) if tp[i] >= 0.2 - 1e-9)
    r['final_err_' + nm] = TARGET - p['angle_rad'][-1]
    r['overshoot_' + nm] = max(0.0, (max(p['angle_rad'][i] for i in range(len(tp)) if tp[i] >= 0.2 - 1e-9) - TARGET) / TARGET * 100)
miq, mid = me['iq_A'], me['id_A']; liq, lid = le['iq_A'], le['id_A']
ltq = [0.3 * x for x in liq]
diq = [liq[i] - miq[i] for i in range(n)]
dtq = [ltq[i] - me['actual_torque_Nm'][i] for i in range(n)]
r['max_diq'] = max(abs(x) for x in diq); r['t_max_diq'] = te[max(range(n), key=lambda i: abs(diq[i]))]
r['max_dtq'] = max(abs(x) for x in dtq)
r['max_did'] = max(abs(lid[i] - mid[i]) for i in range(n))
r['max_diqref'] = max(abs(le['iq_ref_A'][i] - me['iq_reference_A'][i]) for i in range(n))
r['max_dvd'] = max(abs(le['vd_sat_V'][i] - me['vd_V'][i]) for i in range(n))
r['max_dvq'] = max(abs(le['vq_sat_V'][i] - me['vq_V'][i]) for i in range(n))
r['max_dw'] = max(abs(le['omega_rad_s'][i] - me['velocity_rad_s'][i]) for i in range(n))
ctrl = [i for i in range(n) if te[i] < 2.0 - 1e-9]           # 종료 행 제외 20000 제어 구간
r['n_ctrl'] = len(ctrl)
r['volt_limited_mu'] = sum(1 for i in ctrl if me['voltage_limited'][i] > 0.5)
r['volt_limited_ml'] = sum(1 for i in ctrl if le['saturated'][i] > 0.5)
r['cur_limited_mu'] = sum(1 for i in ctrl if me['current_reference_limited'][i] > 0.5)
r['cur_limited_ml'] = sum(1 for i in ctrl if abs(le['iq_ref_A'][i]) >= 2.0 - 1e-9)
r['cur_limited_mismatch_rows'] = sum(1 for i in ctrl if (me['current_reference_limited'][i] > 0.5) != (abs(le['iq_ref_A'][i]) >= 2.0 - 1e-9))
r['iq_peak_mu'] = max(miq); r['iq_peak_ml'] = max(liq)
r['vmag_max_mu'] = max(me['voltage_magnitude_V']); r['vmag_max_ml'] = max(math.hypot(le['vd_sat_V'][i], le['vq_sat_V'][i]) for i in range(n))
r['v_limit'] = VLIM
i02 = min(range(n), key=lambda i: abs(te[i] - 0.2)); j02 = min(range(len(tp)), key=lambda i: abs(tp[i] - 0.2))
r['first_step'] = dict(tau_cmd_ml=lp['command_torque_Nm'][j02], tau_cmd_mu=mp['command_torque_Nm'][j02], iq_ref_ml=le['iq_ref_A'][i02], iq_ref_mu=me['iq_reference_A'][i02],
                       vq_ml=le['vq_sat_V'][i02], vq_mu=me['vq_V'][i02], act_tq_ml=ltq[i02], act_tq_mu=me['actual_torque_Nm'][i02])
r['pass_q'] = r['max_dq'] <= TOL['q']; r['pass_iq'] = r['max_diq'] <= TOL['iq']; r['pass_tq'] = r['max_dtq'] <= TOL['tq']
r['pass_ts'] = (r['settle_mu'] is not None and r['settle_ml'] is not None and abs(r['settle_mu'] - r['settle_ml']) <= TOL['ts'])
json.dump({'2-2_24V': r}, open(os.path.join(RES, 'stage2_2_compare_metrics.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

print('행 수:', r['rows'])
print('시간축 차이 위치 %.1e / 전기 %.1e s, 목표각 차이 %.1e' % (r['time_axis_max_diff_pos'], r['time_axis_max_diff_elec'], r['target_max_diff']))
print('[0.2 s 스텝 직후] 요구 토크 ML %.4f / MU %.4f | iq_ref ML %.3f / MU %.3f | vq ML %.4f / MU %.4f | 실제 토크 ML %.2e / MU %.2e' % (
    r['first_step']['tau_cmd_ml'], r['first_step']['tau_cmd_mu'], r['first_step']['iq_ref_ml'], r['first_step']['iq_ref_mu'], r['first_step']['vq_ml'], r['first_step']['vq_mu'], r['first_step']['act_tq_ml'], r['first_step']['act_tq_mu']))
print('[위치 1ms] 최대 |Δq| = %.3e rad (t=%.3f) [<=1e-3 %s] | 환경 간 RMSE(q) = %.3e rad | 최대 |Δqdot| = %.3e rad/s' % (r['max_dq'], r['t_max_dq'], 'PASS' if r['pass_q'] else 'FAIL', r['env_rmse_q'], r['max_dv']))
print('  추종 RMSE ML %.9f / MU %.9f | 정착(±0.006) ML %s / MU %s [차이<=0.01 %s] | 오버슈트 %.3f%% / %.3f%% | 최대속도 %.6f / %.6f | 최종오차 %.3e / %.3e' % (
    r['track_rmse_ml'], r['track_rmse_mu'], r['settle_ml'], r['settle_mu'], 'PASS' if r['pass_ts'] else 'FAIL', r['overshoot_ml'], r['overshoot_mu'], r['peak_speed_ml'], r['peak_speed_mu'], r['final_err_ml'], r['final_err_mu']))
print('[전기 100us] 최대 |Δiq| = %.3e A (t=%.4f) [<=0.01 %s] | 최대 |Δ토크| = %.3e N*m [<=0.003 %s] | 최대 |Δid| = %.2e A | |Δiq_ref| = %.2e A' % (
    r['max_diq'], r['t_max_diq'], 'PASS' if r['pass_iq'] else 'FAIL', r['max_dtq'], 'PASS' if r['pass_tq'] else 'FAIL', r['max_did'], r['max_diqref']))
print('  적용전압 최대 |Δvd| = %.2e V, |Δvq| = %.2e V | 속도 최대 차이(전기 격자) %.2e rad/s' % (r['max_dvd'], r['max_dvq'], r['max_dw']))
print('  전압 제한 구간: ML %d / MU %d (of %d) | 전류 지령 제한 구간: ML %d / MU %d, 플래그 불일치 %d행' % (r['volt_limited_ml'], r['volt_limited_mu'], r['n_ctrl'], r['cur_limited_ml'], r['cur_limited_mu'], r['cur_limited_mismatch_rows']))
print('  iq 최대 ML %.6f / MU %.6f A | |v| 최대 ML %.4f / MU %.4f V (한계 %.4f)' % (r['iq_peak_ml'], r['iq_peak_mu'], r['vmag_max_ml'], r['vmag_max_mu'], r['v_limit']))
