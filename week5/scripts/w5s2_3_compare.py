"""2-3(24 V / 2 V) MuJoCo vs MATLAB 비교. 사용: python w5s2_3_compare.py
이민혁 README_stage2_3.txt의 합의 기준: 각도 <=0.001 rad, iq <=0.01 A, 관절 토크 <=0.003 N*m, 정착시간 차이 <=0.01 s"""
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
out = {}
for label, mu_tag, ml_tag, vlim in (('24V', 'normal_24V', '2-3_24V', 24 / math.sqrt(3)), ('2V', 'low_2V', '2-3_2V', 2 / math.sqrt(3))):
    mp = load(os.path.join(MU, mu_tag + '_position_dt6p25us.csv'))
    me = load(os.path.join(MU, mu_tag + '_electrical_dt6p25us.csv'))
    lp = load(os.path.join(RES, 'w5s2_%s_matlab_pos_dt6p25us.csv' % ml_tag))
    le = load(os.path.join(RES, 'w5s2_%s_matlab_elec_dt6p25us.csv' % ml_tag))
    tp = mp['time_s']; te = me['time_s']
    r = {}
    # --- 시간축/목표 ---
    r['time_axis_max_diff_pos'] = max(abs(a - b) for a, b in zip(tp, lp['time_s']))
    r['time_axis_max_diff_elec'] = max(abs(a - b) for a, b in zip(te, le['time_s']))
    r['target_max_diff'] = max(abs(a - b) for a, b in zip(mp['target_rad'], lp['target_rad']))
    # --- 위치 (1 ms) ---
    dq = [lp['angle_rad'][i] - mp['angle_rad'][i] for i in range(len(tp))]
    dv = [lp['velocity_rad_s'][i] - mp['velocity_rad_s'][i] for i in range(len(tp))]
    i_dq = max(range(len(dq)), key=lambda i: abs(dq[i]))
    wpos = [i for i in range(len(tp)) if 0.2 - 1e-9 <= tp[i] <= 2.0 + 1e-9]
    r['max_dq'] = abs(dq[i_dq]); r['t_max_dq'] = tp[i_dq]
    r['max_dv'] = max(abs(x) for x in dv)
    r['env_rmse_q'] = math.sqrt(sum(dq[i] ** 2 for i in wpos) / len(wpos))
    target = 2.0; band = 0.04
    for nm, p in (('mu', mp), ('ml', lp)):
        r['track_rmse_' + nm] = rmse(p['angle_rad'], p['target_rad'], wpos)
        r['settle_' + nm] = settle(tp, p['angle_rad'], target, band)
        r['peak_speed_' + nm] = max(abs(p['velocity_rad_s'][i]) for i in range(len(tp)) if tp[i] >= 0.2 - 1e-9)
        r['final_err_' + nm] = target - p['angle_rad'][-1]
    r['n_wpos'] = len(wpos)
    # --- 전기 (100 us) ---
    n = len(te)
    miq, mid = me['iq_A'], me['id_A']
    liq, lid = le['iq_A'], le['id_A']
    ltq = [0.3 * x for x in liq]
    diq = [liq[i] - miq[i] for i in range(n)]
    dtq = [ltq[i] - me['actual_torque_Nm'][i] for i in range(n)]
    r['max_diq'] = max(abs(x) for x in diq); r['t_max_diq'] = te[max(range(n), key=lambda i: abs(diq[i]))]
    r['max_dtq'] = max(abs(x) for x in dtq)
    r['max_did'] = max(abs(lid[i] - mid[i]) for i in range(n))
    r['max_diqref'] = max(abs(le['iq_ref_A'][i] - me['iq_reference_A'][i]) for i in range(n))
    r['max_dvd'] = max(abs(le['vd_sat_V'][i] - me['vd_V'][i]) for i in range(n))
    r['max_dvq'] = max(abs(le['vq_sat_V'][i] - me['vq_V'][i]) for i in range(n))
    r['max_dvq_cmd'] = max(abs(le['vq_cmd_V'][i] - me['vq_raw_V'][i]) for i in range(n))
    # 포화 (0.2 <= t < 2.0, 18000 구간)
    wel = [i for i in range(n) if 0.2 - 1e-9 <= te[i] < 2.0 - 1e-9]
    r['n_wel'] = len(wel)
    mu_sat = [i for i in wel if me['voltage_limited'][i] > 0.5]
    ml_sat = [i for i in wel if le['saturated'][i] > 0.5]
    r['sat_dur_mu'] = len(mu_sat) * 1e-4; r['sat_dur_ml'] = len(ml_sat) * 1e-4
    r['sat_frac_mu'] = len(mu_sat) / len(wel); r['sat_frac_ml'] = len(ml_sat) / len(wel)
    r['sat_first_mu'] = te[mu_sat[0]] if mu_sat else None; r['sat_last_mu'] = te[mu_sat[-1]] if mu_sat else None
    r['sat_first_ml'] = te[ml_sat[0]] if ml_sat else None; r['sat_last_ml'] = te[ml_sat[-1]] if ml_sat else None
    r['sat_flag_mismatch_rows'] = sum(1 for i in range(n) if (me['voltage_limited'][i] > 0.5) != (le['saturated'][i] > 0.5))
    r['vmag_max_mu'] = max(me['voltage_magnitude_V']); r['vmag_max_ml'] = max(math.hypot(le['vd_sat_V'][i], le['vq_sat_V'][i]) for i in range(n))
    r['v_limit'] = vlim
    r['iq_track_rmse_mu'] = rmse(miq, me['iq_reference_A'], wel); r['iq_track_rmse_ml'] = rmse(liq, le['iq_ref_A'], wel)
    r['iq_peak_mu'] = max(miq); r['iq_peak_ml'] = max(liq)
    # 판정
    r['pass_q'] = r['max_dq'] <= TOL['q']; r['pass_iq'] = r['max_diq'] <= TOL['iq']; r['pass_tq'] = r['max_dtq'] <= TOL['tq']
    r['pass_ts'] = (r['settle_mu'] is not None and r['settle_ml'] is not None and abs(r['settle_mu'] - r['settle_ml']) <= TOL['ts'])
    out[label] = r
    print('\n================ %s ================' % label)
    print('시간축 차이 위치 %.1e / 전기 %.1e s, 목표각 차이 %.1e' % (r['time_axis_max_diff_pos'], r['time_axis_max_diff_elec'], r['target_max_diff']))
    print('[위치 1ms] 최대 |Δq| = %.3e rad (t=%.3f) [<=1e-3 %s] | 환경 간 RMSE(q) = %.3e rad | 최대 |Δqdot| = %.3e rad/s' % (r['max_dq'], r['t_max_dq'], 'PASS' if r['pass_q'] else 'FAIL', r['env_rmse_q'], r['max_dv']))
    print('  추종 RMSE  MATLAB %.6f / MuJoCo %.6f rad | 정착(±0.04) MATLAB %s / MuJoCo %s s | 최대속도 %.5f / %.5f | 최종오차 %.6f / %.6f' % (
        r['track_rmse_ml'], r['track_rmse_mu'], r['settle_ml'], r['settle_mu'], r['peak_speed_ml'], r['peak_speed_mu'], r['final_err_ml'], r['final_err_mu']))
    print('  정착시간 차이 판정 [<=0.01 s]: %s' % ('PASS' if r['pass_ts'] else 'FAIL'))
    print('[전기 100us] 최대 |Δiq| = %.3e A (t=%.4f) [<=0.01 %s] | 최대 |Δ토크| = %.3e N*m [<=0.003 %s] | 최대 |Δid| = %.2e A' % (r['max_diq'], r['t_max_diq'], 'PASS' if r['pass_iq'] else 'FAIL', r['max_dtq'], 'PASS' if r['pass_tq'] else 'FAIL', r['max_did']))
    print('  최대 |Δiq_ref| = %.2e A | 적용전압 최대 |Δvd| = %.2e V, |Δvq| = %.2e V | 요청 vq 차이 %.2e V' % (r['max_diqref'], r['max_dvd'], r['max_dvq'], r['max_dvq_cmd']))
    print('  포화: MATLAB %.4f s (%.2f%%, %s~%s s) / MuJoCo %.4f s (%.2f%%, %s~%s s) | 플래그 불일치 행 %d / %d' % (
        r['sat_dur_ml'], 100 * r['sat_frac_ml'], r['sat_first_ml'], r['sat_last_ml'], r['sat_dur_mu'], 100 * r['sat_frac_mu'], r['sat_first_mu'], r['sat_last_mu'], r['sat_flag_mismatch_rows'], n))
    print('  |v| 최대 MATLAB %.4f / MuJoCo %.4f V (한계 %.4f) | iq 추종 RMSE MATLAB %.5f / MuJoCo %.5f A | iq 최대 %.5f / %.5f A' % (
        r['vmag_max_ml'], r['vmag_max_mu'], r['v_limit'], r['iq_track_rmse_ml'], r['iq_track_rmse_mu'], r['iq_peak_ml'], r['iq_peak_mu']))
json.dump(out, open(os.path.join(RES, 'stage2_3_compare_metrics.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('\nsaved results/stage2_3_compare_metrics.json')
