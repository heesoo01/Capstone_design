"""발표 슬라이드용 그림(1920x1080 캔버스에 1:1로 놓는 크기, 큰 글자). 사용: python w5_slide_figs2.py -> results/slides/s_*.png"""
import csv, os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.rcParams['font.family'] = ['Malgun Gothic', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
plt.rcParams['font.size'] = 15
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(W5, 'results', 'slides'); os.makedirs(OUT, exist_ok=True)
INK, MUTE, BLUE, ORANGE, RED = '#17202C', '#586374', '#2A5DB0', '#B3560F', '#B23B3B'
BG = '#FBFCFD'
DPI = 100


def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.DictReader(f); c = {k: [] for k in r.fieldnames}
        for row in r:
            for k in c: c[k].append(float(row[k]))
    return c


def style(ax):
    for s in ('top', 'right'): ax.spines[s].set_visible(False)
    ax.grid(alpha=.25); ax.tick_params(colors=MUTE, labelsize=14)


def save(fig, name):
    fig.savefig(os.path.join(OUT, name), dpi=DPI, facecolor=BG); plt.close(fig)


# 응답 비교 (3-2)
cases = (('baseline_24V', '0.3 rad, 24 V'), ('large_24V', '2 rad, 24 V'), ('large_2V', '2 rad, 2 V'))
fig, ax = plt.subplots(2, 3, figsize=(16.64, 6.2), sharex=True, gridspec_kw={'height_ratios': [3, 1.25]})
for j, (cn, lab) in enumerate(cases):
    mp = load(os.path.join(W5, '이민혁', 'stage_3_2', cn + '_position_dt6p25us.csv'))
    lp = load(os.path.join(W5, 'matlab_results', 'stage3_2', cn + '_position_dt6p25us.csv'))
    t = mp['time_s']
    ax[0, j].plot(t, mp['target_rad'], ':', color=MUTE, lw=1.6, label='목표')
    ax[0, j].plot(t, mp['angle_rad'], color=ORANGE, lw=4, label='MuJoCo')
    ax[0, j].plot(t, lp['angle_rad'], '--', color=BLUE, lw=2, label='MATLAB')
    ax[0, j].set_title(lab, color=INK, fontsize=18, fontweight='bold'); ax[0, j].set_ylabel('관절 각도 [rad]' if j == 0 else '', fontsize=15)
    d = [(b - a) * 1e6 for a, b in zip(mp['angle_rad'], lp['angle_rad'])]
    ax[1, j].plot(t, d, color=RED, lw=2); ax[1, j].set_xlabel('time [s]', fontsize=15)
    ax[1, j].set_ylabel('차이 [µrad]' if j == 0 else '', fontsize=15); ax[1, j].set_ylim(-12, 12)
    style(ax[0, j]); style(ax[1, j])
ax[0, 0].legend(frameon=False, loc='lower right', fontsize=15)
fig.tight_layout(); save(fig, 's_response.png')

# 단계별 오차
stages = ['1단계', '2-1', '2-2', '2-3', '3-1', '3-2']
ang = [8.7e-6, None, 7.4e-7, 5.3e-6, 7.2e-6, 7.2e-6]
iq = [None, 2.4e-8, 9.5e-5, 1.2e-4, 3.1e-4, 3.0e-4]
fig, ax = plt.subplots(1, 2, figsize=(16.64, 5.6))
for a, vals, tol, ttl, unit in ((ax[0], ang, 1e-3, '최대 각도 차이 [rad]', 'rad'), (ax[1], iq, 1e-2, '최대 iq 차이 [A]', 'A')):
    xs = [i for i, v in enumerate(vals) if v]; ys = [v for v in vals if v]
    a.bar(xs, ys, color=BLUE, width=.55); a.axhline(tol, color=RED, lw=2.5, ls='--')
    a.text(len(stages) - 0.6, tol * 1.5, '허용치 %g' % tol, color=RED, ha='right', fontsize=16, fontweight='bold')
    for x, y in zip(xs, ys): a.text(x, y * 1.5, '%.1e' % y, ha='center', fontsize=14, color=INK)
    a.set_yscale('log'); a.set_xticks(range(len(stages))); a.set_xticklabels(stages, fontsize=16); a.set_title(ttl, color=INK, fontsize=18, fontweight='bold')
    a.set_ylim(min(ys) / 10, tol * 12); style(a)
fig.tight_layout(); save(fig, 's_errors.png')

# 2 V 포화
me = load(os.path.join(W5, '이민혁', 'stage_3_1', 'large_2V_electrical_dt6p25us.csv'))
le = load(os.path.join(W5, 'matlab_results', 'stage3_1', 'large_2V_electrical_dt6p25us.csv'))
fig, ax = plt.subplots(1, 2, figsize=(16.64, 5.8))
ax[0].axvspan(0.2, 1.728, color='#F6EBD0', alpha=.7)
ax[0].plot(me['time_s'], me['voltage_magnitude_V'], color=ORANGE, lw=4); ax[0].plot(le['time_s'], le['voltage_magnitude_V'], '--', color=BLUE, lw=2)
ax[0].axhline(me['voltage_limit_V'][0], color=RED, ls=':', lw=2.5); ax[0].text(1.97, me['voltage_limit_V'][0] * 1.04, '전압 한계 1.155 V', ha='right', color=RED, fontsize=16)
ax[0].text(0.96, 0.35, '포화 구간 0.200~1.728 s', ha='center', fontsize=16, color=INK)
ax[0].set_title('전압 크기 |v| [V]', color=INK, fontsize=18, fontweight='bold'); ax[0].set_xlabel('time [s]', fontsize=15)
ax[1].plot(me['time_s'], me['iq_reference_A'], ':', color=MUTE, lw=2.5, label='지령 (2 A)')
ax[1].plot(me['time_s'], me['iq_A'], color=ORANGE, lw=4, label='MuJoCo'); ax[1].plot(le['time_s'], le['iq_A'], '--', color=BLUE, lw=2, label='MATLAB')
ax[1].set_title('iq [A]', color=INK, fontsize=18, fontweight='bold'); ax[1].set_xlabel('time [s]', fontsize=15); ax[1].legend(frameon=False, fontsize=15)
for a in ax: style(a)
fig.tight_layout(); save(fig, 's_saturation.png')

# 간트 (이번 주 ~ W8 중심 + 마일스톤)
G = [('r1', '현실 특성 지원 조사 (동하)', 5, 6, 80, '#2A5DB0'), ('r3', '조사 보완', 6, 7, 30, '#2A5DB0'), ('r4', '기존 시뮬레이터 후보 조사', 6, 7, 25, '#2A5DB0'),
     ('r2', 'MATLAB-MuJoCo 이식·연결 가능성', 6, 7, 40, '#2A5DB0'), ('r5', '던지기 선행연구·요구사항', 5, 7, 30, '#2A5DB0'),
     ('a0', '두 환경 일치 검증 (1~3단계)', 5, 5, 100, '#7650BE'), ('a2', 'PMSM+FOC 전기 모델', 5, 8, 60, '#7650BE'), ('a3', '기계 모델 확정', 6, 8, 50, '#7650BE'),
     ('a1', '모터 요구 사양 산출', 7, 8, 0, '#7650BE'), ('c1', '제어기 후보 문헌 검토', 6, 8, 0, '#B3560F'),
     ('t1', '던지기 태스크 정의', 6, 7, 15, '#16808F'), ('t2', '던지기 시나리오 구현', 8, 11, 0, '#16808F'), ('e1', '평가 지표 정의', 7, 8, 0, '#2C8641')]
fig, ax = plt.subplots(figsize=(16.64, 7.4))
for i, (k, name, s, e, p, c) in enumerate(G):
    y = len(G) - i
    ax.barh(y, e - s + 1, left=s - .5, color=c, alpha=.25, height=.62, zorder=2)
    ax.barh(y, (e - s + 1) * p / 100, left=s - .5, color=c, height=.62, zorder=3)
    ax.text(4.4, y, name, ha='right', va='center', fontsize=15, color=INK)
    ax.text(e + .6, y, '%d%%' % p, va='center', fontsize=14, color=MUTE)
ax.axvspan(5.5, 6.5, color='#E2EBF8', alpha=.9, zorder=0); ax.text(6, len(G) + .75, '이번 주 (W6)', ha='center', fontsize=15, color=BLUE, fontweight='bold')
for w, lab in ((7, 'W7 시뮬레이터·\n태스크 결정'), (9, 'W9 중간발표')):
    ax.axvline(w + .5, color=INK, ls=':', lw=1.5, zorder=1); ax.text(w + .5, len(G) + .75, lab, ha='center', fontsize=14, color=INK, bbox=dict(fc=BG, ec='none', pad=1.5), zorder=5)
ax.set_xlim(4.3, 9.9); ax.set_ylim(0, len(G) + 2); ax.set_xticks(range(5, 10)); ax.set_xticklabels(['W%d\n%s' % (w, d) for w, d in zip(range(5, 10), ['9/28', '10/5', '10/12', '10/19', '10/26'])], fontsize=15)
ax.set_yticks([]); style(ax); ax.spines['left'].set_visible(False)
fig.subplots_adjust(left=0.27, right=0.99, top=0.97, bottom=0.12)
save(fig, 's_gantt.png')
print(sorted(f for f in os.listdir(OUT) if f.startswith('s_')))
