#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""w56_gantt.py : 5.6주차 발표용 간트 그림 (W5~W10 구간, 현재 W7).

일정(시작/끝 주차)은 RAMS 작업실 페이지의 TASKS 목록, 진행률은 RAMS gantt 컬렉션(2026-10-12 기준)에서 가져왔다.
담당·진행률은 팀 합의 전 제안값이다. 이 파일은 그림만 만들고 RAMS 에는 쓰지 않는다.
"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm
from matplotlib.patches import Rectangle, Polygon

for fam in ('Malgun Gothic', 'NanumGothic', 'Noto Sans CJK KR', 'Noto Sans KR', 'Apple SD Gothic Neo'):
    if any(fam == f.name for f in fm.fontManager.ttflist):
        plt.rcParams['font.family'] = fam
        break
plt.rcParams['axes.unicode_minus'] = False

# id, 분류, 이름, 시작주, 끝주, 마일스톤, 진행률(%)  -- 진행률은 RAMS gantt 2026-10-12 값
T = [
    ('p1', '프로젝트', '9/29 피드백 정리 · 간트 확정', 5, 5, 0, 90),
    ('p5', '프로젝트', '주간 기록 · 교수님 자료', 5, 18, 0, 15),
    ('p2', '프로젝트', '중간발표 준비', 8, 9, 0, 0),
    ('r1', '조사', '현실 특성 지원 조사', 5, 6, 0, 80),
    ('r5', '조사', '던지기 선행연구 · 요구사항 조사', 5, 7, 0, 30),
    ('r3', '조사', '조사 보완 (출처 · 측정 근거)', 6, 7, 0, 30),
    ('r4', '조사', '기존 시뮬레이터 후보 조사', 6, 7, 0, 25),
    ('r2', '조사', 'MATLAB–MuJoCo 이식·연결 가능성', 6, 7, 0, 60),
    ('a0', '액추에이터', '두 환경 일치 검증 (1~3단계)', 5, 5, 0, 100),
    ('a2', '액추에이터', 'PMSM+FOC 전기 모델 구현·검증', 5, 8, 0, 60),
    ('a3', '액추에이터', '기계 모델 확정 (기어·관성·마찰·백래시)', 6, 8, 0, 75),
    ('a1', '액추에이터', '모터 요구 사양 산출', 7, 8, 0, 0),
    ('a5', '액추에이터', '모터 후보 데이터시트 비교·선정', 8, 10, 0, 0),
    ('a4', '액추에이터', '현실 특성 구현 (마찰·백래시·PWM·열)', 10, 12, 0, 60),
    ('c1', '제어', '제어기 후보 문헌 검토 · 비교표', 6, 8, 0, 0),
    ('c2', '제어', '제어기 구현 · 튜닝', 9, 12, 0, 0),
    ('t1', '태스크', '던지기 태스크 정의', 6, 7, 0, 15),
    ('t2', '태스크', '던지기 시나리오 구현', 8, 11, 0, 0),
    ('e1', '평가', '평가 지표 정의', 7, 8, 0, 0),
    ('g1', '마일스톤', '시뮬레이터 · 태스크 결정', 7, 7, 1, 0),
    ('m1', '마일스톤', '중간발표', 9, 9, 1, 0),
]
W0, W1, CUR = 5, 10, 7
BLUE, LIGHT, ORANGE, RED, GREY = '#2A5DB0', '#C9D6EC', '#B3560F', '#B03A2E', '#586374'

fig, ax = plt.subplots(figsize=(16.64, 7.9), dpi=100)
n = len(T)
ax.set_xlim(W0 - 0.5 - 7.2, W1 + 0.5)
ax.set_ylim(n - 0.2, -1.9)
ax.axis('off')
# 주차 눈금
dates = {5: '9/28', 6: '10/5', 7: '10/12', 8: '10/19', 9: '10/26', 10: '11/2'}
for w in range(W0, W1 + 1):
    ax.text(w, -1.45, 'W%d' % w, ha='center', va='center', fontsize=15, fontweight='bold', color=GREY)
    ax.text(w, -0.85, dates[w], ha='center', va='center', fontsize=11, color=GREY)
    ax.plot([w - 0.5, w - 0.5], [-0.15, n - 0.5], color='#D6DCE6', lw=1, zorder=0)
ax.plot([W1 + 0.5, W1 + 0.5], [-0.15, n - 0.5], color='#D6DCE6', lw=1, zorder=0)
# 현재 주 강조
ax.add_patch(Rectangle((CUR - 0.5, -0.15), 1, n - 0.35, color='#FFF2D9', zorder=0))
ax.text(CUR, n - 0.1, '현재 W7', ha='center', va='center', fontsize=14, fontweight='bold', color=ORANGE)

for i, (tid, grp, name, s, e, ms, prog) in enumerate(T):
    y = i
    if i % 2 == 0:
        ax.add_patch(Rectangle((W0 - 0.5 - 7.2, y - 0.5), (W1 - W0 + 1) + 7.2, 1, color='#EEF1F6', zorder=0))
    late = (e < CUR and prog < 100)
    color_name = RED if late else '#17202C'
    ax.text(W0 - 0.5 - 7.1, y, grp, ha='left', va='center', fontsize=11, color=GREY)
    ax.text(W0 - 0.5 - 5.9, y, name, ha='left', va='center', fontsize=13, color=color_name, fontweight='bold' if tid in ('t1', 'a4', 'g1') else 'normal')
    xs, xe = max(s, W0) - 0.5, min(e, W1) + 0.5
    if ms:
        cx = s
        ax.add_patch(Polygon([[cx, y - 0.32], [cx + 0.32, y], [cx, y + 0.32], [cx - 0.32, y]], color=ORANGE, zorder=3))
        continue
    h = 0.5
    ax.add_patch(Rectangle((xs, y - h / 2), xe - xs, h, color=LIGHT, zorder=2))
    fill = (e - s + 1) * prog / 100.0
    fill = min(fill, min(e, W1) - max(s, W0) + 1 if s <= W1 else 0)
    if prog > 0:
        ax.add_patch(Rectangle((xs, y - h / 2), (xe - xs) * prog / 100.0 if e <= W1 else fill, h, color=BLUE, zorder=3))
    if late:
        ax.add_patch(Rectangle((xs, y - h / 2), xe - xs, h, fill=False, ec=RED, lw=2, zorder=4))
    if e > W1:
        ax.text(W1 + 0.45, y, '▶', ha='right', va='center', fontsize=11, color=GREY, zorder=5)
    ax.text(xe + 0.04 if e < W1 else xs - 0.04, y, '%d%%' % prog, ha='left' if e < W1 else 'right', va='center', fontsize=11, color=GREY, zorder=5)

ax.text(W0 - 0.5 - 7.1, -1.2, '일 (간트 30개 중 W5~W10 구간 21개)', ha='left', va='center', fontsize=13, fontweight='bold', color=GREY)
fig.text(0.015, 0.012, '진행률은 RAMS 2026-10-12 기준 제안값(팀 합의 전). 빨간 표시는 마감이 지났지만 100%가 아닌 일. ▶ 는 W10 이후로 이어지는 일.', fontsize=11, color=GREY)
fig.tight_layout(rect=(0, 0.03, 1, 1))
import os
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'results', 'slides', 'w56_gantt.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
fig.savefig(out, dpi=100, facecolor='white')
print('saved', out)
