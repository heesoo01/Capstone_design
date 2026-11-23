#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""w6s41_compare.py : 4-1 (관절 건마찰) MATLAB/Simulink 결과 vs 이민혁 MuJoCo+Python 결과 비교.

입력  : week6/matlab_results/stage4_1/*.csv        (w6s41_run.m 이 만든 파일)
        week6/이민혁/stage4/stage4/stage4_1_*/       (민혁 패키지: summary.json, CSV)
출력  : week6/results/stage4_1/ (보고서 txt, metrics json, PNG 2장)
실행  : python w6s41_compare.py

판정 기준은 세 종류이며 보고서에 출처를 구분해 적는다.
  [민혁]  민혁 README 4-1 §5 의 수치 (그대로 사용)
  [5주차] 5주차 3단계 기준 (각도 1e-3 rad, iq 0.01 A, 관절 토크 0.015 N*m, 모터 토크 0.003 N*m, 정착 0.01 s)
  [신규]  이번에 새로 제안한 기준(MATLAB 자체 간격 수렴) -> 사용자 승인됨 (2026-10-11). 결과를 보고 바꾸지 않는다.
어느 기준도 하드웨어 정확도 기준이 아니다.

중요: 마찰 모델의 정의가 다르다. 민혁은 MuJoCo frictionloss(제약: 정지 시에도 한계까지 버팀), MATLAB 은 Simscape Rotational Friction 블록
(속도만의 함수: 정지 시 0, 속도 임계값 파라미터 있음). 건마찰 케이스의 큰 차이는 이 정의 차이가 원인일 수 있으며 구현 오류와 구분되지 않는다.
baseline(마찰 0) 케이스는 같은 정의라 5주차 기준으로 직접 판정한다.
"""
import os, glob, json, csv, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
W6 = os.path.abspath(os.path.join(HERE, '..'))
ML = os.environ.get('W6S41_ML', os.path.join(W6, 'matlab_results', 'stage4_1'))
OUT = os.environ.get('W6S41_OUT', os.path.join(W6, 'results', 'stage4_1'))
os.makedirs(OUT, exist_ok=True)
pyd = sorted(glob.glob(os.path.join(W6, '이민혁', 'stage4', 'stage4', 'stage4_1_*')))
if not pyd:
    sys.exit('민혁 4-1 폴더를 찾지 못했다: week6/이민혁/stage4/stage4/stage4_1_*')
PY = pyd[-1]
PS = json.load(open(os.path.join(PY, 'summary.json'), encoding='utf-8'))

PROP = dict(angle=1e-3, iq=1e-2, torque=1.5e-2, motor_torque=3e-3, settle=1e-2)   # [5주차]
CONV = dict(angle=2e-4, speed=3e-3, iq=5e-3)                                       # [민혁] README §5 (MuJoCo 자체 dt 수렴 기준). MATLAB 자체 수렴에 재사용하므로 [신규]로 표시
SC = ['baseline_step', 'small_step', 'slow_reversal', 'hold_restart']
TARGET = {'baseline_step': 0.3, 'small_step': 0.01, 'slow_reversal': None, 'hold_restart': None}
VBS = [('vb0p001', 1e-3), ('vb0p01', 1e-2), ('vb0p1', 1e-1)]

rep, checks, metrics = [], [], {}


def say(s=''):
    print(s)
    rep.append(s)


def chk(group, name, val, lim, src, note=''):
    ok = bool(np.isfinite(val) and val <= lim)
    checks.append(dict(group=group, name=name, value=float(val), limit=float(lim), source=src, ok=ok))
    say('  [%s] %-66s %.4g <= %.4g  [%s]%s' % ('PASS' if ok else 'FAIL', name, val, lim, src, (' ' + note) if note else ''))
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


def restart_time(t, q, t0=2.8, thr=1e-3):
    idx = np.nonzero(t >= t0 - 1e-9)[0]
    q0 = q[idx[0]]
    hit = np.nonzero(np.abs(q[idx] - q0) >= thr)[0]
    return float(t[idx[hit[0]]] - t0) if len(hit) else float('nan')


def col_diff(a, b, key):
    ta, tb = a['time_s'], b['time_s']
    if len(ta) == len(tb) and np.max(np.abs(ta - tb)) < 1e-9:
        return a[key] - b[key]
    return a[key] - np.interp(ta, tb, b[key])


def pyrun(sc, kind):
    return PS['runs']['%s_%s' % (sc, 'baseline' if kind == 'baseline' else 'dry_friction')]


say('4-1 비교 보고서: MATLAB/Simulink vs 이민혁 MuJoCo+Python (관절 건마찰)')
say('민혁 데이터: ' + os.path.relpath(PY, W6))
say('MATLAB 데이터: ' + os.path.relpath(ML, W6))
say('판정 기준 출처: [민혁]=README 4-1 §5, [5주차]=3단계 기준, [신규]=새 기준(사용자 승인 2026-10-11). 하드웨어 정확도 기준 아님.')
say('마찰 정의: 민혁 = MuJoCo frictionloss 0.05 N*m (제약, solref/solimp 는 MuJoCo 기본값 %s / %s), MATLAB = Simscape Rotational Friction 블록(Coulomb=Breakaway 0.05, 점성 0, 속도 임계값 3개).' % (
    PS['runs']['baseline_step_dry_friction']['dof_solref_friction'], PS['runs']['baseline_step_dry_friction']['dof_solimp_friction']))
say('두 마찰 모델은 정의가 달라 같은 조건이 아니다: 건마찰 케이스의 차이는 구현 오류와 모델 정의 차이를 구분할 수 없다.')

# ---- 0. 지표 정의 확인 ----
say('\n[0] 지표 정의 확인 (민혁 CSV 에 내 함수를 적용해 summary.json 값이 재현되는지)')
PYD = {}
for sc in SC:
    for kind in ('baseline', 'dry_friction'):
        d = py('%s_%s_position_dt25us.csv' % (sc, kind))
        PYD[(sc, kind)] = d
        s = PS['runs']['%s_%s' % (sc, kind)]
        rm = rmse(d['time_s'], d['angle_rad'], d['target_rad'])
        fe = abs(d['target_rad'][-1] - d['angle_rad'][-1])
        line = '  %-30s RMSE 내 %.8f / summary %.8f | 최종 오차 내 %.8f / summary %.8f' % ('%s_%s' % (sc, kind), rm, s['tracking_rmse_rad_after_0p2s'], fe, abs(s['final_error_rad']))
        ok = abs(rm - s['tracking_rmse_rad_after_0p2s']) < 1e-9 and abs(fe - abs(s['final_error_rad'])) < 1e-9
        if TARGET[sc] is not None:
            st = settle(d['time_s'], d['angle_rad'], TARGET[sc])
            sref = s['settling_2percent_s_after_step']
            sref = float('nan') if sref is None else sref
            line += ' | 정착 내 %s / summary %s' % ('%.3f' % st, '%.3f' % sref)
            ok = ok and ((np.isnan(st) and np.isnan(sref)) or abs(st - sref) < 1e-9)
        if sc == 'hold_restart':
            rt = restart_time(d['time_s'], d['angle_rad'])
            line += ' | 재출발 내 %.4f / summary %.4f' % (rt, s['restart_time_to_1mrad_motion_s'])
            ok = ok and abs(rt - s['restart_time_to_1mrad_motion_s']) < 1e-9
        say(line + ' -> ' + ('재현 OK' if ok else '불일치(이 지표는 판정에 쓰지 않음)'))
        metrics['def_check_%s_%s' % (sc, kind)] = dict(reproduced=bool(ok))

# ---- (a) baseline: 같은 정의 ----
say('\n[a] baseline (마찰 없음, 같은 정의): MATLAB vs 민혁')
for sc in SC:
    m = ml('%s_baseline_electrical_100us.csv' % sc)
    mp = ml('%s_baseline_position_1ms.csv' % sc)
    if m is None or mp is None:
        say('  %s: MATLAB 파일 없음 -> w6s41_run(''base'') 실행 필요' % sc); continue
    b = py('%s_baseline_electrical_dt25us.csv' % sc)
    say(' %s' % sc)
    chk('a', '%s_baseline 최대 각도 차 [rad]' % sc, np.max(np.abs(col_diff(m, b, 'angle_rad'))), PROP['angle'], '5주차')
    chk('a', '%s_baseline 최대 샘플 iq 차 [A]' % sc, np.max(np.abs(col_diff(m, b, 'iq_A'))), PROP['iq'], '5주차')
    chk('a', '%s_baseline 최대 관절 토크 차 [N*m]' % sc, np.max(np.abs(col_diff(m, b, 'actual_torque_Nm'))), PROP['torque'], '5주차')
    chk('a', '%s_baseline 최대 모터 토크 차 [N*m]' % sc, np.max(np.abs(col_diff(m, b, 'motor_torque_Nm'))), PROP['motor_torque'], '5주차')
    if TARGET[sc] is not None:
        s_m = settle(mp['time_s'], mp['angle_rad'], TARGET[sc]); s_p = settle(PYD[(sc, 'baseline')]['time_s'], PYD[(sc, 'baseline')]['angle_rad'], TARGET[sc])
        if np.isnan(s_m) and np.isnan(s_p):
            say('  [N/A ] %s_baseline 2%% 정착시간: 양쪽 모두 정착하지 않음' % sc)
        elif np.isnan(s_m) != np.isnan(s_p):
            chk('a', '%s_baseline 2%% 정착시간 (한쪽만 정착: 불일치)' % sc, float('inf'), PROP['settle'], '5주차', '(MATLAB %s / 민혁 %s)' % (s_m, s_p))
        else:
            chk('a', '%s_baseline 2%% 정착시간 차 [s]' % sc, abs(s_m - s_p), PROP['settle'], '5주차', '(MATLAB %.3f / 민혁 %.3f s)' % (s_m, s_p))

# ---- (b) 건마찰: 정의가 다른 두 마찰 모델 ----
say('\n[b] 건마찰 0.05 N*m: MATLAB(Simscape Rotational Friction, 속도 임계값 3개) vs 민혁(MuJoCo frictionloss)')
say('  ※ 정의가 달라 이 절의 FAIL 은 구현 오류의 증거가 아니다. 판정 기준은 5주차 값 그대로 두었고 완화하지 않았다.')
DRY = {}
for sc in SC:
    pd_ = PS['runs']['%s_dry_friction' % sc]
    pb_ = PS['runs']['%s_baseline' % sc]
    for tag, vb in VBS:
        m = ml('%s_dry_%s_electrical_100us.csv' % (sc, tag))
        mp = ml('%s_dry_%s_position_1ms.csv' % (sc, tag))
        if m is None or mp is None:
            say('  %s dry_%s: MATLAB 파일 없음 -> w6s41_run(''dry'') 실행 필요' % (sc, tag)); continue
        DRY[(sc, tag)] = (m, mp)
        b = py('%s_dry_friction_electrical_dt25us.csv' % sc)
        n = '%s dry %s' % (sc, tag)
        say(' %s (속도 임계값 %g rad/s)' % (n, vb))
        ang = np.max(np.abs(col_diff(m, b, 'angle_rad')))
        chk('b', '%s 최대 각도 차 [rad]' % n, ang, PROP['angle'], '5주차')
        chk('b', '%s 최대 샘플 iq 차 [A]' % n, np.max(np.abs(col_diff(m, b, 'iq_A'))), PROP['iq'], '5주차')
        chk('b', '%s 최대 관절 토크 차 [N*m]' % n, np.max(np.abs(col_diff(m, b, 'actual_torque_Nm'))), PROP['torque'], '5주차')
        chk('b', '%s 최대 모터 토크 차 [N*m]' % n, np.max(np.abs(col_diff(m, b, 'motor_torque_Nm'))), PROP['motor_torque'], '5주차')
        if TARGET[sc] is not None:
            s_m = settle(mp['time_s'], mp['angle_rad'], TARGET[sc]); s_p = settle(PYD[(sc, 'dry_friction')]['time_s'], PYD[(sc, 'dry_friction')]['angle_rad'], TARGET[sc])
            if np.isnan(s_m) and np.isnan(s_p):
                say('  [N/A ] %s 2%% 정착시간: 양쪽 모두 관찰 구간 안에 정착하지 않음' % n)
            elif np.isnan(s_m) != np.isnan(s_p):
                chk('b', '%s 2%% 정착시간 (한쪽만 정착: 불일치)' % n, float('inf'), PROP['settle'], '5주차', '(MATLAB %s / 민혁 %s)' % (s_m, s_p))
            else:
                chk('b', '%s 2%% 정착시간 차 [s]' % n, abs(s_m - s_p), PROP['settle'], '5주차', '(MATLAB %.3f / 민혁 %.3f s)' % (s_m, s_p))
        # 관측값
        rm_m = rmse(mp['time_s'], mp['angle_rad'], mp['target_rad'])
        fe_m = abs(mp['target_rad'][-1] - mp['angle_rad'][-1])
        extra = ''
        if sc == 'hold_restart':
            extra = ', 재출발 시간(2.8 s 후 1 mrad) MATLAB %.4f / 민혁 %.4f s' % (restart_time(mp['time_s'], mp['angle_rad']), pd_['restart_time_to_1mrad_motion_s'])
        say('  (참고) RMSE MATLAB %.6f / 민혁 %.6f rad | 최종 오차 MATLAB %.5f / 민혁 %.5f rad | 마찰 on-off 최대 각도 효과 MATLAB %.5f / 민혁 %.5f rad%s' % (
            rm_m, pd_['tracking_rmse_rad_after_0p2s'], fe_m, abs(pd_['final_error_rad']),
            0.0 if ml('%s_baseline_electrical_100us.csv' % sc) is None else np.max(np.abs(col_diff(m, ml('%s_baseline_electrical_100us.csv' % sc), 'angle_rad'))),
            PS['effects'][sc]['max_angle_difference_rad'], extra))
        metrics['b_%s_%s' % (sc, tag)] = dict(max_angle_diff_vs_py=float(ang), rmse_ml=float(rm_m), rmse_py=float(pd_['tracking_rmse_rad_after_0p2s']), final_err_ml=float(fe_m), final_err_py=float(abs(pd_['final_error_rad'])))
    # 속도 임계값 민감도 (관측)
    ks = [k for k in (t for t, _ in VBS) if (sc, k) in DRY]
    if len(ks) >= 2:
        spread = max(np.max(np.abs(col_diff(DRY[(sc, a)][0], DRY[(sc, b_)][0], 'angle_rad'))) for a in ks for b_ in ks)
        say('  (참고) %s: 속도 임계값 3개 사이 최대 각도 차 %.4e rad (관측값, 합격 조건 아님)' % (sc, spread))
        metrics['sens_%s' % sc] = dict(max_angle_spread=float(spread))

# ---- (c) MATLAB 자체 간격 수렴 ----
say('\n[c] MATLAB 자체 간격 수렴 (slow_reversal, dry, 속도 임계값 0.01 rad/s, 최대 스텝 5 us vs 2.5 us)')
a_ = ml('slow_reversal_dry_vb0p01_electrical_100us.csv'); b_ = ml('slow_reversal_dry_vb0p01_ms2p5us_electrical_100us.csv')
if a_ is not None and b_ is not None:
    chk('c', 'MATLAB 5 us vs 2.5 us 최대 각도 차 [rad]', np.max(np.abs(col_diff(a_, b_, 'angle_rad'))), CONV['angle'], '신규', '(값은 민혁 README §5 의 MuJoCo dt 수렴 기준을 재사용)')
    chk('c', 'MATLAB 5 us vs 2.5 us 최대 속도 차 [rad/s]', np.max(np.abs(col_diff(a_, b_, 'velocity_rad_s'))), CONV['speed'], '신규')
    chk('c', 'MATLAB 5 us vs 2.5 us 최대 iq 차 [A]', np.max(np.abs(col_diff(a_, b_, 'iq_A'))), CONV['iq'], '신규')
else:
    say('  MATLAB 수렴 파일이 없다 -> w6s41_run(''dry'') 실행 필요')

# ---- 그림 ----
fig, ax = plt.subplots(4, 1, figsize=(8, 11))
for i, sc in enumerate(SC):
    b = PYD[(sc, 'dry_friction')]
    ax[i].plot(b['time_s'], b['target_rad'], 'k:', label='target')
    ax[i].plot(b['time_s'], b['angle_rad'], 'k--', label='MuJoCo frictionloss')
    mb = ml('%s_baseline_position_1ms.csv' % sc)
    if mb is not None:
        ax[i].plot(mb['time_s'], mb['angle_rad'], color='0.6', label='MATLAB no friction')
    for (tag, vb), col in zip(VBS, ('C0', 'C1', 'C2')):
        if (sc, tag) in DRY:
            mp = DRY[(sc, tag)][1]
            ax[i].plot(mp['time_s'], mp['angle_rad'], col, lw=1, label='MATLAB Simscape vth=%g' % vb)
    ax[i].set_title(sc); ax[i].set_ylabel('angle [rad]'); ax[i].grid(alpha=.3); ax[i].legend(fontsize=6)
ax[-1].set_xlabel('time [s]')
fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_1_friction_comparison.png'), dpi=130); plt.close(fig)
fig, ax = plt.subplots(3, 1, figsize=(8, 8), sharex=True)
b = py('slow_reversal_dry_friction_electrical_dt25us.csv')
ax[0].plot(b['time_s'], b['velocity_rad_s'], 'k--', label='MuJoCo')
ax[1].plot(b['time_s'], b['dry_friction_torque_Nm'], 'k--', label='MuJoCo dry_friction_torque (sign as logged)')
ax[2].plot(b['time_s'], b['iq_A'], 'k--', label='MuJoCo')
for (tag, vb), col in zip(VBS, ('C0', 'C1', 'C2')):
    if ('slow_reversal', tag) in DRY:
        m = DRY[('slow_reversal', tag)][0]
        ax[0].plot(m['time_s'], m['velocity_rad_s'], col, lw=1, label='MATLAB vth=%g' % vb)
        ax[1].plot(m['time_s'], m['dry_friction_torque_Nm'], col, lw=1, label='MATLAB vth=%g' % vb)
        ax[2].plot(m['time_s'], m['iq_A'], col, lw=1, label='MATLAB vth=%g' % vb)
ax[0].set_ylabel('velocity [rad/s]'); ax[1].set_ylabel('friction torque [N*m]'); ax[2].set_ylabel('iq [A]'); ax[2].set_xlabel('time [s]')
for a in ax:
    a.grid(alpha=.3); a.legend(fontsize=6)
fig.suptitle('Stage 4-1 slow reversal'); fig.tight_layout(); fig.savefig(os.path.join(OUT, 'stage4_1_friction_signals.png'), dpi=130); plt.close(fig)

# ---- 요약 ----
say('\n[요약]')
n_ok = sum(c['ok'] for c in checks)
say('  검사 %d개 중 %d개 통과, %d개 실패' % (len(checks), n_ok, len(checks) - n_ok))
for g in ('a', 'b', 'c'):
    gg = [c for c in checks if c['group'] == g]
    if gg:
        say('   절 [%s]: %d개 중 %d개 통과' % (g, len(gg), sum(c['ok'] for c in gg)))
for c in checks:
    if not c['ok']:
        say('  실패: [%s] %s = %.4g (기준 %.4g, %s)' % (c['group'], c['name'], c['value'], c['limit'], c['source']))
say('  하지 않은 것: MuJoCo 내부 검사(운동방정식 잔차, 제약 일 비양수 등), 민혁 단독 마찰 probe 의 MATLAB 대응, 25/12.5/6.25 us 수렴(MATLAB 은 가변 스텝).')
say('  PASS 는 위 기준(출처 표시) 안에 들어왔다는 뜻이며 실제 하드웨어와 일치한다는 뜻이 아니다. [신규] 기준은 사용자 승인(2026-10-11)을 받았다.')
open(os.path.join(OUT, 'stage4_1_compare_report.txt'), 'w', encoding='utf-8').write('\n'.join(rep) + '\n')
json.dump(dict(checks=checks, metrics=metrics), open(os.path.join(OUT, 'stage4_1_compare_metrics.json'), 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
print('\n저장: ' + OUT)
