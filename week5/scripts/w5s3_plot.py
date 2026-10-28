"""3단계 비교 그래프(정적 PNG). 사용: python w5s3_plot.py -> results/stage3_1_comparison.png, stage3_2_comparison.png"""
import csv, os, math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = ['Malgun Gothic', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
CASES = (('baseline_24V', '0.3 rad, 24 V'), ('large_24V', '2 rad, 24 V'), ('large_2V', '2 rad, 2 V'))
STAGES = (('3-1', 'stage_3_1', 'stage3_1', '기어비 5, 회전자 관성 0'), ('3-2', 'stage_3_2', 'stage3_2', '기어비 5, 회전자 관성 1e-4 (환산 0.0025)'))


def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.DictReader(f)
        c = {k: [] for k in r.fieldnames}
        for row in r:
            for k in c:
                c[k].append(float(row[k]))
    return c


for sid, mu_dir, ml_dir, desc in STAGES:
    fig, ax = plt.subplots(5, 3, figsize=(15, 13), sharex=True)
    for j, (cn, lab) in enumerate(CASES):
        mp = load(os.path.join(W5, '이민혁', mu_dir, cn + '_position_dt6p25us.csv'))
        me = load(os.path.join(W5, '이민혁', mu_dir, cn + '_electrical_dt6p25us.csv'))
        lp = load(os.path.join(W5, 'matlab_results', ml_dir, cn + '_position_dt6p25us.csv'))
        le = load(os.path.join(W5, 'matlab_results', ml_dir, cn + '_electrical_dt6p25us.csv'))
        t, te = mp['time_s'], me['time_s']
        N = me['gear_ratio'][0]
        ax[0, j].plot(t, mp['target_rad'], 'k:', lw=1, label='목표')
        ax[0, j].plot(t, mp['angle_rad'], 'C1', lw=2.2, label='MuJoCo')
        ax[0, j].plot(t, lp['angle_rad'], 'C0--', lw=1.2, label='MATLAB')
        ax[0, j].set_title('%s %s (%s)' % (sid, cn, lab)); ax[0, j].set_ylabel('관절 각도 [rad]')
        ax[1, j].plot(t, [a - b for a, b in zip(lp['angle_rad'], mp['angle_rad'])], 'C3', lw=1)
        ax[1, j].axhline(1e-3, color='gray', ls=':'); ax[1, j].axhline(-1e-3, color='gray', ls=':')
        ax[1, j].set_ylabel('각도 차 (MATLAB-MuJoCo) [rad]\n점선 ±1e-3 허용')
        ax[2, j].plot(te, me['iq_A'], 'C1', lw=2.2); ax[2, j].plot(te, le['iq_A'], 'C0--', lw=1.2)
        ax[2, j].plot(te, me['iq_reference_A'], 'k:', lw=1); ax[2, j].set_ylabel('iq [A] (점선: 지령)')
        ax[3, j].plot(te, me['actual_torque_Nm'], 'C1', lw=2.2); ax[3, j].plot(te, [N * 0.3 * x for x in le['iq_A']], 'C0--', lw=1.2)
        ax[3, j].set_ylabel('관절 입력 토크 [N·m]')
        ax[4, j].plot(te, me['voltage_magnitude_V'], 'C1', lw=2.2)
        ax[4, j].plot(te, le['voltage_magnitude_V'], 'C0--', lw=1.2)
        ax[4, j].plot(te, me['voltage_limit_V'], 'r:', lw=1)
        ax[4, j].set_ylabel('|v| [V] (빨강: 한계)'); ax[4, j].set_xlabel('time [s]')
        if j == 0: ax[0, j].legend(loc='lower right')
        for r in range(5): ax[r, j].grid(alpha=.3)
    fig.suptitle('%s MuJoCo vs MATLAB (%s) · 6.25 µs · 가정값 기반 수치 비교, 하드웨어 검증 아님' % (sid, desc), fontsize=13)
    fig.tight_layout()
    out = os.path.join(W5, 'results', 'stage%s_comparison.png' % sid.replace('-', '_'))
    fig.savefig(out, dpi=110); plt.close(fig)
    print('saved', out)
