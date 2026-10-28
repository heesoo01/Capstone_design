"""3단계(3-1, 3-2) MuJoCo vs MATLAB 비교. 사용: python w5s3_compare.py
MuJoCo: 이민혁/stage_3_1, stage_3_2 (*_position_dt6p25us.csv, *_electrical_dt6p25us.csv)
MATLAB: matlab_results/stage3_1, stage3_2 (w5s3_run.m 이 만든 CSV, MuJoCo와 같은 이름/열)
판정(이민혁 README 3-1/3-2의 잠정 기준, 하드웨어 정확도 기준 아님):
  최대 각도 차 <= 1e-3 rad (1 ms), 최대 iq 차 <= 0.01 A, 최대 관절 입력 토크 차 <= 0.015 N*m (100 us),
  양쪽 정착 시 정착시간 차 <= 0.01 s, 양쪽 미정착이면 정착시간은 N/A, 한쪽만 정착이면 불일치.
결과: results/stage3_compare_metrics.json"""
import csv, math, io, sys, os, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
RES = os.path.join(W5, 'results')
TOL = dict(q=1e-3, iq=1e-2, tj=1.5e-2, tm=3e-3, ts=1e-2)
CASES = (('baseline_24V', 0.3, 24.0), ('large_24V', 2.0, 24.0), ('large_2V', 2.0, 2.0))
STAGES = (('3-1', 'stage_3_1', 'stage3_1'), ('3-2', 'stage_3_2', 'stage3_2'))


def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.DictReader(f)
        cols = {k: [] for k in r.fieldnames}
        for row in r:
            for k in cols:
                cols[k].append(float(row[k]))
    return cols


def settle(t, q, target, band, t0=0.2):
    idx = [i for i in range(len(t)) if t[i] >= t0 - 1e-9]
    last = None
    for i in idx:
        if abs(q[i] - target) > band:
            last = i
    if last is None:
        return 0.0
    if last == idx[-1]:
        return None
    return t[last + 1] - t0


def rmse(a, b, mask):
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in mask) / len(mask))


def amax(seq):
    return max(abs(x) for x in seq)


out = {}
for sid, mu_dir, ml_dir in STAGES:
    out[sid] = {}
    for cname, target, V in CASES:
        band = 0.02 * target
        mp = load(os.path.join(W5, '이민혁', mu_dir, cname + '_position_dt6p25us.csv'))
        me = load(os.path.join(W5, '이민혁', mu_dir, cname + '_electrical_dt6p25us.csv'))
        lp = load(os.path.join(W5, 'matlab_results', ml_dir, cname + '_position_dt6p25us.csv'))
        le = load(os.path.join(W5, 'matlab_results', ml_dir, cname + '_electrical_dt6p25us.csv'))
        tp, te = mp['time_s'], me['time_s']
        n = len(te)
        r = {'n_pos': len(tp), 'n_elec': n}
        r['time_axis_max_diff_pos'] = max(abs(a - b) for a, b in zip(tp, lp['time_s']))
        r['time_axis_max_diff_elec'] = max(abs(a - b) for a, b in zip(te, le['time_s']))
        r['target_max_diff'] = max(abs(a - b) for a, b in zip(mp['target_rad'], lp['target_rad']))
        # 위치 1 ms
        dq = [lp['angle_rad'][i] - mp['angle_rad'][i] for i in range(len(tp))]
        i_dq = max(range(len(dq)), key=lambda i: abs(dq[i]))
        wpos = [i for i in range(len(tp)) if 0.2 - 1e-9 <= tp[i] <= 2.0 + 1e-9]
        r['max_dq'] = abs(dq[i_dq]); r['t_max_dq'] = tp[i_dq]
        r['max_dv'] = amax(lp['velocity_rad_s'][i] - mp['velocity_rad_s'][i] for i in range(len(tp)))
        r['env_rmse_q'] = math.sqrt(sum(dq[i] ** 2 for i in wpos) / len(wpos))
        for nm, p in (('mu', mp), ('ml', lp)):
            r['track_rmse_' + nm] = rmse(p['angle_rad'], p['target_rad'], wpos)
            r['settle_' + nm] = settle(tp, p['angle_rad'], target, band)
            r['peak_speed_' + nm] = max(abs(p['velocity_rad_s'][i]) for i in range(len(tp)) if tp[i] >= 0.2 - 1e-9)
            r['final_err_' + nm] = target - p['angle_rad'][-1]
        r['band'] = band
        # 전기/토크 100 us
        miq, liq = me['iq_A'], le['iq_A']
        diq = [liq[i] - miq[i] for i in range(n)]
        r['max_diq'] = amax(diq); r['t_max_diq'] = te[max(range(n), key=lambda i: abs(diq[i]))]
        r['max_did'] = amax(le['id_A'][i] - me['id_A'][i] for i in range(n))
        r['max_diqref'] = amax(le['iq_reference_A'][i] - me['iq_reference_A'][i] for i in range(n))
        # MATLAB 관절 입력 토크 = N*Kt*iq (위치 CSV의 actual_torque 1 ms 값과도 일치), MuJoCo actual_torque_Nm와 비교 (전기 CSV 100 us)
        N = me['gear_ratio'][0]
        ltj = [N * 0.3 * x for x in liq]
        dtj = [ltj[i] - me['actual_torque_Nm'][i] for i in range(n)]
        r['max_dtj'] = amax(dtj)
        r['max_dtm'] = amax(le['motor_torque_Nm'][i] - me['motor_torque_Nm'][i] for i in range(n))
        r['max_dtj_pos1ms'] = amax(lp['actual_torque_Nm'][i] - mp['actual_torque_Nm'][i] for i in range(len(tp)))
        r['max_dwm'] = amax(le['motor_speed_rad_s'][i] - me['motor_speed_rad_s'][i] for i in range(n))
        r['max_dvd'] = amax(le['vd_V'][i] - me['vd_V'][i] for i in range(n))
        r['max_dvq'] = amax(le['vq_V'][i] - me['vq_V'][i] for i in range(n))
        r['max_dvq_raw'] = amax(le['vq_raw_V'][i] - me['vq_raw_V'][i] for i in range(n))
        wel = [i for i in range(n) if 0.2 - 1e-9 <= te[i] < 2.0 - 1e-9]
        mu_sat = [i for i in wel if me['voltage_limited'][i] > 0.5]
        ml_sat = [i for i in wel if le['voltage_limited'][i] > 0.5]
        r['n_wel'] = len(wel)
        r['sat_dur_mu'] = len(mu_sat) * 1e-4; r['sat_dur_ml'] = len(ml_sat) * 1e-4
        r['sat_first_mu'] = te[mu_sat[0]] if mu_sat else None; r['sat_last_mu'] = te[mu_sat[-1]] if mu_sat else None
        r['sat_first_ml'] = te[ml_sat[0]] if ml_sat else None; r['sat_last_ml'] = te[ml_sat[-1]] if ml_sat else None
        r['sat_flag_mismatch_rows'] = sum(1 for i in range(n) if (me['voltage_limited'][i] > 0.5) != (le['voltage_limited'][i] > 0.5))
        r['iq_track_rmse_mu'] = rmse(miq, me['iq_reference_A'], wel); r['iq_track_rmse_ml'] = rmse(liq, le['iq_reference_A'], wel)
        r['iq_peak_mu'] = max(miq); r['iq_peak_ml'] = max(liq)
        r['vmag_max_mu'] = max(me['voltage_magnitude_V']); r['vmag_max_ml'] = max(le['voltage_magnitude_V'])
        r['v_limit'] = me['voltage_limit_V'][0]
        # 판정
        r['pass_q'] = r['max_dq'] <= TOL['q']
        r['pass_iq'] = r['max_diq'] <= TOL['iq']
        r['pass_tj'] = r['max_dtj'] <= TOL['tj']
        smu, sml = r['settle_mu'], r['settle_ml']
        if smu is None and sml is None:
            r['settle_status'] = 'N/A (양쪽 미정착)'; r['pass_ts'] = True
        elif smu is None or sml is None:
            r['settle_status'] = '불일치 (한쪽만 정착)'; r['pass_ts'] = False
        else:
            r['settle_status'] = 'diff %.3f s' % abs(smu - sml); r['pass_ts'] = abs(smu - sml) <= TOL['ts']
        r['pass_all'] = r['pass_q'] and r['pass_iq'] and r['pass_tj'] and r['pass_ts']
        out[sid][cname] = r
        pf = lambda b: 'PASS' if b else 'FAIL'
        print('\n=========== %s %s (목표 %g rad, %g V) ===========' % (sid, cname, target, V))
        print('시간축 차이 위치 %.1e / 전기 %.1e s, 목표각 차이 %.1e | 행 수 %d / %d' % (r['time_axis_max_diff_pos'], r['time_axis_max_diff_elec'], r['target_max_diff'], r['n_pos'], r['n_elec']))
        print('[각도 1ms] 최대 |Δq| = %.3e rad (t=%.3f) [<=1e-3 %s] | 환경 간 RMSE(q) = %.3e | 최대 |Δqdot| = %.3e rad/s' % (r['max_dq'], r['t_max_dq'], pf(r['pass_q']), r['env_rmse_q'], r['max_dv']))
        print('  추종 RMSE  MATLAB %.6f / MuJoCo %.6f rad | 정착(±%.3f) MATLAB %s / MuJoCo %s s -> %s [%s] | 최대속도 %.4f / %.4f | 최종오차 %.6f / %.6f' % (
            r['track_rmse_ml'], r['track_rmse_mu'], band, sml if sml is None else '%.3f' % sml, smu if smu is None else '%.3f' % smu, r['settle_status'], pf(r['pass_ts']), r['peak_speed_ml'], r['peak_speed_mu'], r['final_err_ml'], r['final_err_mu']))
        print('[전류 100us] 최대 |Δiq| = %.3e A (t=%.4f) [<=0.01 %s] | 최대 |Δid| = %.2e | 최대 |Δiq_ref| = %.2e A' % (r['max_diq'], r['t_max_diq'], pf(r['pass_iq']), r['max_did'], r['max_diqref']))
        print('[토크] 관절 입력 최대 |ΔTj| = %.3e N*m [<=0.015 %s] (1 ms 행 %.3e) | 모터 토크 최대 |ΔTm| = %.3e [<=0.003 %s]' % (
            r['max_dtj'], pf(r['pass_tj']), r['max_dtj_pos1ms'], r['max_dtm'], pf(r['max_dtm'] <= TOL['tm'])))
        print('[기타] 모터속도 최대 차 %.3e rad/s | 적용전압 최대 |Δvd| %.2e, |Δvq| %.2e V | 요청 vq 차 %.2e V' % (r['max_dwm'], r['max_dvd'], r['max_dvq'], r['max_dvq_raw']))
        print('  포화: MATLAB %.4f s (%s~%s) / MuJoCo %.4f s (%s~%s) | 플래그 불일치 %d행 | |v|최대 %.4f / %.4f V (한계 %.4f) | iq 추종 RMSE %.5f / %.5f A | iq 최대 %.4f / %.4f' % (
            r['sat_dur_ml'], r['sat_first_ml'], r['sat_last_ml'], r['sat_dur_mu'], r['sat_first_mu'], r['sat_last_mu'], r['sat_flag_mismatch_rows'],
            r['vmag_max_ml'], r['vmag_max_mu'], r['v_limit'], r['iq_track_rmse_ml'], r['iq_track_rmse_mu'], r['iq_peak_ml'], r['iq_peak_mu']))
        print('  >> 판정: %s' % pf(r['pass_all']))

# 3-1 -> 3-2 회전자 관성 추가 효과 (같은 환경끼리, 참고)
print('\n=========== 회전자 관성 추가 효과 (3-1 -> 3-2, 참고) ===========')
for cname, target, V in CASES:
    a, b = out['3-1'][cname], out['3-2'][cname]
    print('%s: MATLAB RMSE %.6f -> %.6f, 정착 %s -> %s | MuJoCo RMSE %.6f -> %.6f, 정착 %s -> %s' % (
        cname, a['track_rmse_ml'], b['track_rmse_ml'], a['settle_ml'], b['settle_ml'], a['track_rmse_mu'], b['track_rmse_mu'], a['settle_mu'], b['settle_mu']))
out['_overall_pass'] = all(out[s][c]['pass_all'] for s in ('3-1', '3-2') for c, _, _ in CASES)
print('\n전체 판정:', 'PASS' if out['_overall_pass'] else 'FAIL')
json.dump(out, open(os.path.join(RES, 'stage3_compare_metrics.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('saved results/stage3_compare_metrics.json')
