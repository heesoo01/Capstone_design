"""발표용 그림(정적 PNG) 생성. 사용: python w5_slide_figs.py -> results/slides/*.png
입력: 이민혁/stage_3_x, matlab_results/stage3_x CSV, 간트 데이터(아래 GANTT 상수, RAMS gantt와 동일)"""
import csv, os, json
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
plt.rcParams['font.family'] = ['Malgun Gothic', 'DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(W5, 'results', 'slides'); os.makedirs(OUT, exist_ok=True)
INK, MUTE, BLUE, ORANGE, GREEN, GREY = '#17202c', '#586374', '#2a5db0', '#c0601a', '#1f7a45', '#d6dce6'


def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.DictReader(f); c = {k: [] for k in r.fieldnames}
        for row in r:
            for k in c: c[k].append(float(row[k]))
    return c


def style(ax):
    for s in ('top', 'right'): ax.spines[s].set_visible(False)
    ax.grid(alpha=.25); ax.tick_params(colors=MUTE)


# 1. 액추에이터 체인 구조도
fig, ax = plt.subplots(figsize=(13, 3.6)); ax.axis('off'); ax.set_xlim(0, 13); ax.set_ylim(0, 3.6)
boxes = [('위치 명령\n(스텝)', 0.1, GREY), ('위치 PD\n1 ms', 1.65, BLUE), ('÷(N·Kt)\n전류 지령 iq*\n(±2 A 제한)', 3.2, BLUE),
         ('전류 PI\n+ 전향 보상\n100 µs', 4.95, BLUE), ('전압 제한\nVdc/√3', 6.55, BLUE), ('PMSM\nTm = Kt·iq', 8.05, ORANGE),
         ('기어 ×N\n(N=5)', 9.55, ORANGE), ('관절\nJ, b', 11.0, GREEN)]
for t, x, col in boxes:
    ax.add_patch(FancyBboxPatch((x, 1.5), 1.35, 1.2, boxstyle='round,pad=0.02,rounding_size=0.08', fc='white', ec=col, lw=2))
    ax.text(x + .675, 2.1, t, ha='center', va='center', fontsize=10.5, color=INK)
for i in range(len(boxes) - 1):
    x0 = boxes[i][1] + 1.35; x1 = boxes[i + 1][1]
    ax.add_patch(FancyArrowPatch((x0 + .02, 2.1), (x1 - .02, 2.1), arrowstyle='-|>', mutation_scale=14, color=MUTE, lw=1.5))
ax.add_patch(FancyArrowPatch((11.7, 1.45), (11.7, 0.55), arrowstyle='-', color=MUTE, lw=1.5))
ax.add_patch(FancyArrowPatch((11.7, 0.55), (1.0, 0.55), arrowstyle='-', color=MUTE, lw=1.5))
ax.add_patch(FancyArrowPatch((1.0, 0.55), (1.0, 1.45), arrowstyle='-|>', mutation_scale=14, color=MUTE, lw=1.5))
ax.text(6.3, 0.3, '관절 각도 q, 속도 q̇ 되먹임   |   모터 속도 wm = N·q̇ → 역기전력 보상', ha='center', fontsize=10, color=MUTE)
ax.text(0.1, 3.3, '파랑 = 제어기   주황 = 모터·기어   초록 = 기계(관절)', fontsize=10, color=MUTE)
fig.savefig(os.path.join(OUT, 'fig_chain.png'), dpi=160, bbox_inches='tight'); plt.close(fig)

# 2. 응답 비교 (3-2, 세 사례)
cases = (('baseline_24V', '0.3 rad, 24 V'), ('large_24V', '2 rad, 24 V'), ('large_2V', '2 rad, 2 V'))
fig, ax = plt.subplots(2, 3, figsize=(13, 5.6), sharex=True, gridspec_kw={'height_ratios': [3, 1.3]})
for j, (cn, lab) in enumerate(cases):
    mp = load(os.path.join(W5, '이민혁', 'stage_3_2', cn + '_position_dt6p25us.csv'))
    lp = load(os.path.join(W5, 'matlab_results', 'stage3_2', cn + '_position_dt6p25us.csv'))
    t = mp['time_s']
    ax[0, j].plot(t, mp['target_rad'], ':', color=MUTE, lw=1.2, label='목표')
    ax[0, j].plot(t, mp['angle_rad'], color=ORANGE, lw=3.2, label='MuJoCo')
    ax[0, j].plot(t, lp['angle_rad'], '--', color=BLUE, lw=1.6, label='MATLAB')
    ax[0, j].set_title(lab, color=INK, fontsize=12); ax[0, j].set_ylabel('관절 각도 [rad]' if j == 0 else '')
    d = [(b - a) * 1e6 for a, b in zip(mp['angle_rad'], lp['angle_rad'])]
    ax[1, j].plot(t, d, color='#b23b3b', lw=1.2); ax[1, j].set_xlabel('time [s]')
    ax[1, j].set_ylabel('MATLAB-MuJoCo [µrad]' if j == 0 else ''); ax[1, j].set_ylim(-12, 12)
    style(ax[0, j]); style(ax[1, j])
ax[0, 0].legend(frameon=False, loc='lower right')
fig.suptitle('3-2 (기어비 5 + 회전자 관성): 두 환경 응답이 겹침, 차이는 최대 7 µrad (허용 1000 µrad)', color=INK, fontsize=13)
fig.tight_layout(); fig.savefig(os.path.join(OUT, 'fig_response.png'), dpi=160); plt.close(fig)

# 3. 단계별 최대 차이 vs 허용치
stages = ['1단계', '2-1', '2-2', '2-3', '3-1', '3-2']
ang = [8.7e-6, None, 7.4e-7, 5.3e-6, 7.2e-6, 7.2e-6]
iq = [None, 2.4e-8, 9.5e-5, 1.2e-4, 3.1e-4, 3.0e-4]
fig, ax = plt.subplots(1, 2, figsize=(13, 4.4))
for a, vals, tol, ttl, unit in ((ax[0], ang, 1e-3, '최대 각도 차이', 'rad'), (ax[1], iq, 1e-2, '최대 q축 전류(iq) 차이', 'A')):
    xs = [i for i, v in enumerate(vals) if v]; ys = [v for v in vals if v]
    a.bar(xs, ys, color=BLUE, width=.55); a.axhline(tol, color='#b23b3b', lw=2, ls='--')
    a.text(len(stages) - 0.6, tol * 1.35, '허용치 %g %s' % (tol, unit), color='#b23b3b', ha='right', fontsize=11)
    for x, y in zip(xs, ys): a.text(x, y * 1.4, '%.1e' % y, ha='center', fontsize=10, color=INK)
    a.set_yscale('log'); a.set_xticks(range(len(stages))); a.set_xticklabels(stages); a.set_title(ttl, color=INK, fontsize=12)
    a.set_ylim(min(ys) / 10, tol * 10); style(a)
fig.suptitle('단계별 MATLAB–MuJoCo 최대 차이 (6.25 µs, 각 단계의 최악 사례, 세로축 로그)', color=INK, fontsize=13)
fig.tight_layout(); fig.savefig(os.path.join(OUT, 'fig_errors.png'), dpi=160); plt.close(fig)

# 4. 2 V 포화 (3-1 large_2V)
me = load(os.path.join(W5, '이민혁', 'stage_3_1', 'large_2V_electrical_dt6p25us.csv'))
le = load(os.path.join(W5, 'matlab_results', 'stage3_1', 'large_2V_electrical_dt6p25us.csv'))
fig, ax = plt.subplots(1, 2, figsize=(13, 4.2))
ax[0].plot(me['time_s'], me['voltage_magnitude_V'], color=ORANGE, lw=3); ax[0].plot(le['time_s'], le['voltage_magnitude_V'], '--', color=BLUE, lw=1.5)
ax[0].axhline(me['voltage_limit_V'][0], color='#b23b3b', ls=':', lw=1.5); ax[0].text(1.95, me['voltage_limit_V'][0] * 1.03, '전압 한계 1.155 V', ha='right', color='#b23b3b', fontsize=10)
ax[0].axvspan(0.2, 1.728, color='#f6ebd0', alpha=.6); ax[0].text(0.96, 0.3, '포화 구간 0.200~1.728 s\n(양쪽 일치, 플래그 불일치 0행)', ha='center', fontsize=10, color=INK)
ax[0].set_title('전압 크기 |v| [V]', color=INK); ax[0].set_xlabel('time [s]')
ax[1].plot(me['time_s'], me['iq_A'], color=ORANGE, lw=3, label='MuJoCo'); ax[1].plot(le['time_s'], le['iq_A'], '--', color=BLUE, lw=1.5, label='MATLAB')
ax[1].plot(me['time_s'], me['iq_reference_A'], ':', color=MUTE, label='지령'); ax[1].set_title('iq [A]: 지령(2 A)에 못 미침', color=INK); ax[1].set_xlabel('time [s]')
ax[1].legend(frameon=False)
for a in ax: style(a)
fig.suptitle('2 V 극단 조건: 전압이 모자라 전류가 지령을 못 따라감 (3-1, 목표 2 rad)', color=INK, fontsize=13)
fig.tight_layout(); fig.savefig(os.path.join(OUT, 'fig_saturation.png'), dpi=160); plt.close(fig)

# 5. 간트차트 (RAMS 간트와 동일 데이터)
G = [('프로젝트', 'p1', '9/29 피드백 정리·간트 확정', 5, 5, 90), ('프로젝트', 'p5', '주간 기록·교수님 자료', 5, 18, 10), ('프로젝트', 'p2', '중간발표 준비', 8, 9, 0),
     ('프로젝트', 'p3', '최종발표 준비', 15, 16, 0), ('프로젝트', 'p4', '보고서 작성', 16, 18, 0),
     ('조사', 'r1', '현실 특성 지원 조사', 5, 6, 80), ('조사', 'r3', '조사 보완', 6, 7, 30), ('조사', 'r4', '기존 시뮬레이터 후보 조사', 6, 7, 25),
     ('조사', 'r2', 'MATLAB–MuJoCo 이식·연결 가능성', 6, 7, 40), ('조사', 'r5', '던지기 선행연구·요구사항', 5, 7, 30),
     ('액추에이터', 'a0', '두 환경 일치 검증(1~3단계)', 5, 5, 100), ('액추에이터', 'a2', 'PMSM+FOC 전기 모델', 5, 8, 60), ('액추에이터', 'a3', '기계 모델 확정', 6, 8, 50),
     ('액추에이터', 'a1', '모터 요구 사양 산출', 7, 8, 0), ('액추에이터', 'a5', '모터 후보 선정', 8, 10, 0), ('액추에이터', 'a4', '현실 특성 구현', 10, 12, 0),
     ('제어', 'c1', '제어기 후보 문헌 검토', 6, 8, 0), ('제어', 'c2', '제어기 구현·튜닝', 9, 12, 0), ('제어', 'c3', '질량 변화 대응 제어', 10, 12, 0),
     ('태스크', 't1', '던지기 태스크 정의', 6, 7, 15), ('태스크', 't2', '던지기 시나리오 구현', 8, 11, 0), ('태스크', 't3', '던지기 기준 실험', 11, 13, 0), ('태스크', 't4', '태스크 발전 여부 결정', 12, 12, 0),
     ('평가', 'e1', '평가 지표 정의', 7, 8, 0), ('평가', 'e2', '평가 실험', 11, 14, 0), ('평가', 'e3', '개선·한계 정리', 14, 15, 0)]
col = {'프로젝트': '#68768a', '조사': BLUE, '액추에이터': '#7650be', '제어': ORANGE, '태스크': '#16808f', '평가': '#2c8641'}
fig, ax = plt.subplots(figsize=(13, 8.2))
for i, (g, k, name, s, e, p) in enumerate(G):
    y = len(G) - i
    ax.barh(y, e - s + 1, left=s - .5, color=col[g], alpha=.25, height=.62, zorder=2)
    ax.barh(y, (e - s + 1) * p / 100, left=s - .5, color=col[g], height=.62, zorder=3)
    ax.text(4.35, y, name, ha='right', va='center', fontsize=9.5, color=INK)
    ax.text(e + .6, y, '%d%%' % p, va='center', fontsize=8.5, color=MUTE)
for w, lab in ((7, '시뮬레이터·태스크\n결정'), (9, '중간발표'), (16, '최종발표'), (18, '제출')):
    ax.axvline(w, color=INK, ls=':', lw=1, zorder=1); ax.text(w, len(G) + 1.5, lab, ha='center', fontsize=9, color=INK, bbox=dict(fc='white', ec='none', pad=1.5), zorder=5)
ax.axvspan(4.5, 5.5, color='#e2ebf8', alpha=.8, zorder=0); ax.text(5, len(G) + 0.35, '이번 주', ha='center', fontsize=9, color=BLUE)
ax.set_xlim(4.4, 19); ax.set_ylim(0, len(G) + 2.4); ax.set_xticks(range(5, 19)); ax.set_xticklabels(['W%d' % w for w in range(5, 19)], fontsize=9)
ax.set_yticks([]); style(ax); ax.spines['left'].set_visible(False)
ax.set_title('간트차트 W5~W18 (담당·진행률은 제안, 팀 합의 전) — 지연 0건', color=INK, fontsize=13)
fig.tight_layout(); fig.savefig(os.path.join(OUT, 'fig_gantt.png'), dpi=150); plt.close(fig)
print('saved', sorted(os.listdir(OUT)))
