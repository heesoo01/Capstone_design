#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""w6s42_compare.py : 4-2 (기어 백래시) MATLAB/Simulink 결과 vs 이민혁 MuJoCo+Python 결과 비교.

입력  : week6/matlab_results/stage4_2/*.csv        (w6s42_run.m 이 만든 파일)
        week6/이민혁/stage4/stage4/stage4_2_*/       (민혁 패키지: summary.json, CSV)
출력  : week6/results/stage4_2/ (보고서 txt, metrics json, PNG 2장)
실행  : python w6s42_compare.py

판정 기준은 세 종류이며 보고서에 출처를 구분해 적는다.
  [민혁]  민혁 README 4-2 §9 의 수치 (그대로 사용)
  [5주차] 5주차 3단계 기준 (각도 1e-3 rad, iq 0.01 A, 관절 토크 0.015 N*m, 모터 토크 0.003 N*m, 정착 0.01 s)
  [신규]  이번에 새로 제안한 기준(MATLAB 자체 간격 수렴) -> 사용자 승인됨 (2026-10-11). 결과를 보고 바꾸지 않는다.
어느 기준도 하드웨어 정확도 기준이 아니다.

중요: 접촉 모델의 정의가 다르다. 민혁 = MuJoCo soft limit (solref=[0.001,1], solimp=[0.99,0.99,0.001,0.5,2]),
MATLAB = Simscape Multibody 관절 한계(강성 K, 감쇠 D, 전환 폭). 둘은 1:1 변환할 수 없어 K, D 를 값 목록으로 바꿔 민감도를 본다.
유격 폭(±0.5도 = 0.0087266 rad)만 같게 맞출 수 있다. 접촉 순간의 피크 토크는 판정에 쓰지 않는다 (민혁도 강제하지 않음).
"""
import os, glob, json, csv, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
W6 = os.path.abspath(os.path.join(HERE, '..'))
ML = os.environ.get('W6S42_ML', os.path.join(W6, 'matlab_results', 'stage4_2'))
OUT = os.environ.get('W6S42_OUT', os.path.join(W6, 'results', 'stage4_2'))
os.makedirs(OUT, exist_ok=True)
pyd = sorted(glob.glob(os.path.join(W6, '이민혁', 'stage4', 'stage4', 'stage4_2_*')))
if not pyd:
    sys.exit('민혁 4-2 폴더를 찾지 못했다: week6/이민혁/stage4/stage4/stage4_2_*')
PY = pyd[-1]
PS = json.load(open(os.path.join(PY, 'summary.json'), encoding='utf-8'))
PAR = PS['parameters']
JLOAD, JREF, B, N = PAR['J_LINK'], PAR['J_REFLECTED'], PAR['B'], PAR['GEAR']

PROP = dict(angle=1e-3, iq=1e-2, torque=1.5e-2, motor_torque=3e-3, settle=1e-2)   # [5주차]
CONV = dict(angle=1e-3, angle_rms=2e-4, speed=5e-2, iq=2e-2, torque_rms=0.1)       # [민혁] README §9 (dt25 vs dt6.25). MATLAB 자체 수렴에 재사용하므로 [신규]로 표시
SC = ['baseline_step', 'reversal_steps', 'slow_reversal']
TARGET = {'baseline_step': 0.3, 'reversal_steps': None, 'slow_reversal': None}
KS = ['1e5', '1e6', '1e7']
DS = ['Dcrit', 'D0p01']
HALF = {'near_zero_gap': 1e-6, 'backlash': 0.5 * np.pi / 180}

rep, checks, metrics = [], [], {}


def say(s=''):
    print(s)
    rep.append(s)


def chk(group, name, val, lim, src, note=''):
    ok = bool(np.isfinite(val) and val <= lim)
    checks.append(dict(group=group, name=name, value=float(val), limit=float(lim), source=src, ok=ok))
    say('  [%s] %-70s %.4g <= %.4g  [%s]%s' % ('PASS' if ok else 'FAIL', name, val, lim, src, (' ' + note) if note else ''))
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


def col_diff(a, b, key_a, key_b=None):
    key_b = key_b or key_a
    ta, tb = a['time_s'], b['time_s']
    if len(ta) == len(tb) and np.max(np.abs(ta - tb)) < 1e-9:
        return a[key_a] - b[key_b]
    return a[key_a] - np.interp(ta, tb, b[key_b])


def trans_torque(d, sign):
    """부하 전달 토크. MATLAB: 유격 관절 위/아래 한계 토크 합(부호는 부하 운동방정식으로 정한다)."""
    return sign * (d['limit_torque_lower_Nm'] + d['limit_torque_upper_Nm'])


def load_eq_residual(d, tau):
    acc = np.gradient(d['load_velocity_rad_s'], d['time_s'])
    return JLOAD * acc + B * d['load_velocity_rad_s'] - tau


say('4-2 비교 보고서: MATLAB/Simulink vs 이민혁 MuJoCo+Python (기어 백래시)')
say('민혁 데이터: ' + os.path.relpath(PY, W6))
say('MATLAB 데이터: ' + os.path.relpath(ML, W6))
say('판정 기준 출처: [민혁]=README 4-2 §9, [5주차]=3단계 기준, [신규]=새 기준(사용자 승인 2026-10-11). 하드웨어 정확도 기준 아님.')
say('접촉 정의: 민혁 = MuJoCo soft limit (solref %s, solimp %s), MATLAB = Simscape Multibody 관절 한계(K, D, 전환 폭 1e-7 rad). 1:1 변환 불가 -> K{1e5,1e6,1e7} x D{임계감쇠 근사, 0.01} 6개 설정.' % (
    PS['runs']['baseline_step_backlash']['gap_solref'], PS['runs']['baseline_step_backlash']['gap_solimp']))
say('같게 맞춘 것은 유격 폭(반폭 %.7f rad)뿐이다. 접촉 거동의 차이는 구현 오류와 접촉 모델 정의 차이를 구분할 수 없다.' % HALF['backlash'])

# ---- 0. 지표 정의 확인 ----
say('\n[0] 지표 정의 확인 (민혁 CSV 에 내 함수를 적용해 summary.json 값이 재현되는지)')
PYD, PYP = {}, {}
for sc in SC:
    for mdl in ('rigid_reference', 'near_zero_gap', 'backlash'):
        e = py('%s_%s_electrical_dt25us.csv' % (sc, mdl))
        pp = py('%s_%s_position_dt25us.csv' % (sc, mdl))
        PYD[(sc, mdl)], PYP[(sc, mdl)] = e, pp
        s = PS['runs']['%s_%s' % (sc, mdl)]
        rm = rmse(pp['time_s'], pp['load_angle_rad'], pp['target_rad'])
        ok = abs(rm - s['tracking_rmse_rad_after_0p2s']) < 1e-9
        line = '  %-34s RMSE 내 %.8f / summary %.8f' % ('%s_%s' % (sc, mdl), rm, s['tracking_rmse_rad_after_0p2s'])
        if TARGET[sc] is not None:
            st = settle(pp['time_s'], pp['load_angle_rad'], TARGET[sc])
            sref = s['settling_2percent_s_after_step']
            sref = float('nan') if sref is None else sref
            ok = ok and ((np.isnan(st) and np.isnan(sref)) or abs(st - sref) < 1e-9)
            line += ' | 정착 내 %.3f / summary %.3f' % (st, sref)
        if mdl != 'rigid_reference':
            tin = float(np.sum(e['inside_gap'] > 0.5) * 1e-4)
            line += ' | 유격 안 시간 내 %.4f / summary %.4f s' % (tin, s['time_inside_gap_s'])
        say(line + (' -> 재현 OK' if ok else ' -> 불일치(이 지표는 판정에 쓰지 않음)'))
        metrics['def_check_%s_%s' % (sc, mdl)] = dict(reproduced=bool(ok))

# ---- (a) rigid_reference ----
say('\n[a] rigid_reference (5주차 3-2 그대로, 같은 정의): MATLAB vs 민혁')
RG = {}
for sc in SC:
    m = ml('%s_rigid_reference_electrical_100us.csv' % sc)
    mp = ml('%s_rigid_reference_position_1ms.csv' % sc)
    if m is None:
        say('  %s: MATLAB 파일 없음 -> w6s42_run(''rigid'') 실행 필요' % sc); continue
    RG[sc] = (m, mp)
    b = PYD[(sc, 'rigid_reference')]
    say(' %s' % sc)
    chk('a', '%s rigid 최대 각도 차 [rad]' % sc, np.max(np.abs(col_diff(m, b, 'load_angle_rad'))), PROP['angle'], '5주차')
    chk('a', '%s rigid 최대 샘플 iq 차 [A]' % sc, np.max(np.abs(col_diff(m, b, 'iq_A'))), PROP['iq'], '5주차')
    chk('a', '%s rigid 최대 관절 토크 차 [N*m]' % sc, np.max(np.abs(col_diff(m, b, 'postgear_electromagnetic_torque_Nm'))), PROP['torque'], '5주차')
    chk('a', '%s rigid 최대 모터 토크 차 [N*m]' % sc, np.max(np.abs(col_diff(m, b, 'motor_electromagnetic_torque_Nm'))), PROP['motor_torque'], '5주차')
    if TARGET[sc] is not None:
        s_m = settle(mp['time_s'], mp['load_angle_rad'], TARGET[sc]); s_p = settle(PYP[(sc, 'rigid_reference')]['time_s'], PYP[(sc, 'rigid_reference')]['load_angle_rad'], TARGET[sc])
        chk('a', '%s rigid 2%% 정착시간 차 [s]' % sc, abs(s_m - s_p), PROP['settle'], '5주차', '(MATLAB %.3f / 민혁 %.3f s)' % (s_m, s_p))

# ---- 전달 토크 부호 확인 (유격 모델 하나로) ----
SIGN = None
probe = ml('reversal_steps_backlash_K1e6_Dcrit_electrical_100us.csv')
if probe is not None:
    r_pos = np.sqrt(np.mean(load_eq_residual(probe, trans_torque(probe, +1.0)) ** 2))
    r_neg = np.sqrt(np.mean(load_eq_residual(probe, trans_torque(probe, -1.0)) ** 2))
    SIGN = 1.0 if r_pos <= r_neg else -1.0
    say('\n전달 토크 부호 확인 (reversal_steps/backlash/K1e6/Dcrit): 부하 운동방정식 J*qdd + B*qd = tau 의 잔차 RMS  (+): %.4g, (-): %.4g N*m -> 부호 %+d 채택 (잔차는 수치미분 qdd 를 포함하는 관측값)' % (r_pos, r_neg, int(SIGN)))
    metrics['transmitted_torque_sign'] = dict(rms_plus=float(r_pos), rms_minus=float(r_neg), chosen=SIGN)

# ---- (b) near_zero_gap / (c) backlash ----
def compare_block(group, sc, mdl, tag, label):
    m = ml('%s_%s_electrical_100us.csv' % (sc, tag))
    mp = ml('%s_%s_position_1ms.csv' % (sc, tag))
    if m is None or mp is None:
        say('  %s: MATLAB 파일 없음 -> w6s42_run(''gap'') 실행 필요' % label); return None
    b = PYD[(sc, mdl)]
    ang = np.max(np.abs(col_diff(m, b, 'load_angle_rad')))
    chk(group, '%s 최대 각도 차 [rad]' % label, ang, PROP['angle'], '5주차')
    chk(group, '%s 최대 샘플 iq 차 [A]' % label, np.max(np.abs(col_diff(m, b, 'iq_A'))), PROP['iq'], '5주차')
    chk(group, '%s 최대 관절 토크 차 [N*m]' % label, np.max(np.abs(col_diff(m, b, 'postgear_electromagnetic_torque_Nm'))), PROP['torque'], '5주차')
    chk(group, '%s 최대 모터 토크 차 [N*m]' % label, np.max(np.abs(col_diff(m, b, 'motor_electromagnetic_torque_Nm'))), PROP['motor_torque'], '5주차')
    if TARGET[sc] is not None:
        s_m = settle(mp['time_s'], mp['load_angle_rad'], TARGET[sc]); s_p = settle(PYP[(sc, mdl)]['time_s'], PYP[(sc, mdl)]['load_angle_rad'], TARGET[sc])
        if np.isnan(s_m) and np.isnan(s_p):
            say('  [N/A ] %s 2%% 정착시간: 양쪽 모두 정착하지 않음' % label)
        elif np.isnan(s_m) != np.isnan(s_p):
            chk(group, '%s 2%% 정착시간 (한쪽만 정착: 불일치)' % label, float('inf'), PROP['settle'], '5주차', '(MATLAB %s / 민혁 %s)' % (s_m, s_p))
        else:
            chk(group, '%s 2%% 정착시간 차 [s]' % label, abs(s_m - s_p), PROP['settle'], '5주차', '(MATLAB %.3f / 민혁 %.3f s)' % (s_m, s_p))
    s = PS['runs']['%s_%s' % (sc, mdl)]
    half = HALF[mdl]
    over = max(0.0, np.max(np.abs(m['gap_coordinate_rad'])) - half)
    inside = float(np.sum(np.abs(m['gap_coordinate_rad']) < half - 1e-9) * 1e-4)
    ms = np.max(np.abs(m['motor_speed_rad_s'] / N - m['load_velocity_rad_s']))
    pk = ''
    if SIGN is not None:
        pk = ', 전달 토크 피크 MATLAB %.3f / 민혁 %.3f N*m (접촉 모델 의존, 판정 아님)' % (np.max(np.abs(trans_torque(m, SIGN))), s['peak_abs_load_transmitted_torque_Nm'])
    say('  (참고) 유격 안 시간 MATLAB %.4f / 민혁 %.4f s | 한계 초과(침투) 최대 MATLAB %.3e / 민혁 %.3e rad | 모터/N-부하 속도 차 최대 MATLAB %.4f / 민혁 %.4f rad/s%s' % (
        inside, s['time_inside_gap_s'], over, s['max_gap_penetration_rad'], ms, PS['effects'][sc]['backlash_motor_vs_load_output_equivalent_speed_max_difference_rad_s'] if mdl == 'backlash' else float('nan'), pk))
    metrics['%s_%s' % (sc, tag)] = dict(max_angle_diff_vs_py=float(ang), inside_gap_ml=inside, inside_gap_py=float(s['time_inside_gap_s']), penetration_ml=float(over))
    return m


say('\n[b] near_zero_gap (±1e-6 rad): MATLAB(K=1e6, 임계 감쇠 근사) vs 민혁')
NZ = {}
for sc in SC:
    say(' %s' % sc)
    NZ[sc] = compare_block('b', sc, 'near_zero_gap', 'near_zero_gap_K1e6_Dcrit', '%s near_zero_gap K1e6 Dcrit' % sc)
    if NZ[sc] is not None and sc in RG:
        d = np.max(np.abs(col_diff(NZ[sc], RG[sc][0], 'load_angle_rad')))
        say('  (참고) %s: MATLAB near_zero_gap vs MATLAB rigid 최대 각도 차 %.3e rad (민혁 near_zero_gap vs rigid %.3e rad)' % (sc, d, PS['effects'][sc]['near_zero_gap_vs_rigid_max_angle_difference_rad']))

say('\n[c] backlash (±0.5도): MATLAB 접촉 설정 6개 vs 민혁')
say('  ※ 접촉 정의가 달라 이 절의 FAIL 은 구현 오류의 증거가 아니다. 판정 기준은 5주차 값 그대로 두었고 완화하지 않았다.')
BL = {}
for sc in SC:
    for K in KS:
        for D in DS:
            tag = 'backlash_K%s_%s' % (K, D)
            say(' %s %s' % (sc, tag))
            BL[(sc, tag)] = compare_block('c', sc, 'backlash', tag, '%s %s' % (sc, tag))
        # 효과 크기 (백래시 - near_zero_gap, 같은 접촉 설정이 아니라 near_zero 는 K1e6/Dcrit 하나)
    if NZ.get(sc) is not None and BL.get((sc, 'backlash_K1e6_Dcrit')) is not None:
        m = BL[(sc, 'backlash_K1e6_Dcrit')]
        say('  (참고) %s: MATLAB backlash(K1e6,Dcrit) vs near_zero_gap 최대 각도 차 %.3e rad, 최대 iq 차 %.3e A | 민혁 %.3e rad, %.3e A' % (
            sc, np.max(np.abs(col_diff(m, NZ[sc], 'load_angle_rad'))), np.max(np.abs(col_diff(m, NZ[sc], 'iq_A'))),
            PS['effects'][sc]['backlash_vs_near_zero_gap_max_angle_difference_rad'], PS['effects'][sc]['backlash_vs_near_zero_gap_max_iq_difference_A']))
    ks = [(a) for a in BL if a[0] == sc and BL[a] is not None]
    if len(ks) >= 2:
        spread = max(np.max(np.abs(col_diff(BL[a], BL[b_], 'load_angle_rad'))) for a in ks for b_ in ks)
        say('  (참고) %s: 접촉 설정 %d개 사이 최대 각도 차 %.4e rad (관측값, 합격 조건 아님)' % (sc, len(ks), spread))
        metrics['sens_%s' % sc] = dict(max_angle_spread=float(spread), n=len(ks))

# ---- (d) MATLAB 자체 간격 수렴 ----
say('\n[d] MATLAB 자체 간격 수렴 (reversal_steps / backlash / K1e6 / Dcrit, 최대 스텝 5 us vs 2.5 us)')
a_ = ml('reversal_steps_backlash_K1e6_Dcrit_electrical_100us.csv'); b_ = ml('reversal_steps_backlash_K1e6_Dcrit_ms2p5us_electrical_100us.csv')
if a_ is not None and b_ is not None:
    chk('d', 'MATLAB 5 us vs 2.5 us 최대 각도 차 [rad]', np.max(np.abs(col_diff(a_, b_, 'load_angle_rad'))), CONV['angle'], '신규', '(값은 민혁 README §9 의 MuJoCo dt 수렴 기준을 재사용)')
    chk('d', 'MATLAB 5 us vs 2.5 us 각도 차 RMS [rad]', float(np.sqrt(np.mean(col_diff(a_, b_, 'load_angle_rad') ** 2))), CONV['angle_rms'], '신규')
    chk('d', 'MATLAB 5 us vs 2.5 us 최대 부하 속도 차 [rad/s]', np.max(np.abs(col_diff(a_, b_, 'load_velocity_rad_s'))), CONV['speed'], '신규')
    chk('d', 'MATLAB 5 us vs 2.5 us 최대 iq 차 [A]', np.max(np.abs(col_diff(a_, b_, 'iq_A'))), CONV['iq'], '신규')
    if SIGN is not None:
        chk('d', 'MATLAB 5 us vs 2.5 us 부하 전달 토크 차 RMS [N*m]', float(np.sqrt(np.mean((trans_torque(a_, SIGN) - trans_torque(b_, SIGN)) ** 2))), CONV['torque_rms'], '신규')
else:
    say('  MATLAB 수렴 파일이 없다 -> w6s42_run(''conv'') 실행 필요')

# ---- 그림 ----
if probe is not None:
    fig, ax = plt.subplots(3, 1, figsize=(8, 9), sharex=True)
    sc = 'reversal_steps'
    b = PYD[(sc, 'backlash')]
    ax[0].plot(b['time_s'], b['target_rad'], 'k:', label='target')
    ax[0].plot(b['time_s'], b['load_angle_rad'], 'k--', label='MuJoCo backlash')
    if sc in RG:
        ax[0].plot(RG[sc][0]['time_s'], RG[sc][0]['load_angle_rad'], color='0.6', label='MATLAB rigid')
    ax[1].plot(b['time_s'], b['iq_A'], 'k--', label='MuJoCo')
    ax[2].plot(b['time_s'], b['load_transmitted_torque_Nm'], 'k--', label='MuJoCo')
    for (tag, col) in (('backlash_K1e5_Dcrit', 'C0'), ('backlash_K1e6_Dcrit', 'C1'), ('backlash_K1e7_Dcrit', 'C2'), ('backlash_K1e6_D0p01', 'C3')):
        m = ml('%s_%s_electrical_100us.csv' % (sc, tag))
        if m is None:
            continue
        ax[0].plot(m['time_s'], m['load_angle_rad'], col, lw=1, label='MATLAB ' + tag)
        ax[1].plot(m['time_s'], m['iq_A'], col, lw=1, label=tag)
        if SIGN is not None:
            ax[2].plot(m['time_s'], trans_torque(m, SIGN), col, lw=1, label=tag)
    ax[0].set_ylabel('load angle [rad]'); ax[1].set_ylabel('iq [A]'); ax[2].set_ylabel('transmitted torque [N*m]'); ax[2].set_xlabel('time [s]')
    for a in ax:
        a.grid(alpha=.3); a.legend(fontsize=6)
    fig.suptitle('Stage 4-2 reversal steps'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_2_backlash_comparison.png'), dpi=130); plt.close(fig)
    fig, ax = plt.subplots(2, 1, figsize=(8, 6), sharex=True)
    b = PYD[(sc, 'backlash')]
    ax[0].plot(b['time_s'], b['gap_coordinate_rad'], 'k--', label='MuJoCo q_gap')
    ax[1].plot(b['time_s'], b['drive_velocity_output_equivalent_rad_s'] - b['load_velocity_rad_s'], 'k--', label='MuJoCo drive-load speed')
    for (tag, col) in (('backlash_K1e5_Dcrit', 'C0'), ('backlash_K1e6_Dcrit', 'C1'), ('backlash_K1e7_Dcrit', 'C2')):
        m = ml('%s_%s_electrical_100us.csv' % (sc, tag))
        if m is None:
            continue
        ax[0].plot(m['time_s'], m['gap_coordinate_rad'], col, lw=1, label='MATLAB ' + tag)
        ax[1].plot(m['time_s'], m['gap_velocity_rad_s'], col, lw=1, label=tag)
    for h in (HALF['backlash'], -HALF['backlash']):
        ax[0].axhline(h, color='r', ls=':', lw=.8)
    ax[0].set_ylabel('q_gap [rad]'); ax[1].set_ylabel('gap speed [rad/s]'); ax[1].set_xlabel('time [s]')
    for a in ax:
        a.grid(alpha=.3); a.legend(fontsize=6)
    fig.suptitle('Stage 4-2 gap coordinate (reversal steps)'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_2_backlash_signals.png'), dpi=130); plt.close(fig)

# ---- 요약 ----
say('\n[요약]')
n_ok = sum(c['ok'] for c in checks)
say('  검사 %d개 중 %d개 통과, %d개 실패' % (len(checks), n_ok, len(checks) - n_ok))
for g in ('a', 'b', 'c', 'd'):
    gg = [c for c in checks if c['group'] == g]
    if gg:
        say('   절 [%s]: %d개 중 %d개 통과' % (g, len(gg), sum(c['ok'] for c in gg)))
for c in checks:
    if not c['ok']:
        say('  실패: [%s] %s = %.4g (기준 %.4g, %s)' % (c['group'], c['name'], c['value'], c['limit'], c['source']))
say('  하지 않은 것: 민혁 단독 gap_probe 의 MATLAB 대응(제어기 분리 +-0.02 N*m 입력 시험), MuJoCo 내부 검사(운동방정식 잔차 1e-8, solver tolerance), 25/12.5/6.25 us 수렴(MATLAB 은 가변 스텝).')
say('  PASS 는 위 기준(출처 표시) 안에 들어왔다는 뜻이며 실제 하드웨어와 일치한다는 뜻이 아니다. [신규] 기준은 사용자 승인(2026-10-11)을 받았다.')
open(os.path.join(OUT, 'stage4_2_compare_report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
json.dump(dict(checks=checks, metrics=metrics), open(os.path.join(OUT, 'stage4_2_compare_metrics.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
print('\n저장: ' + OUT)
