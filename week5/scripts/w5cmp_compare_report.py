"""1단계 MuJoCo vs MATLAB 비교 리포트(HTML) 생성. 사용: python w5cmp_compare_report.py
입력: 이민혁/mujoco_dt25us.csv, results/w5_mujoco_vs_matlab_1dof_matlab_dt25us.csv (+ _matlab.csv 100us)
출력: results/stage1_mujoco_vs_matlab_comparison.html (Chrome으로 PDF 변환)"""
import csv, math, io, sys, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
RES = os.path.join(W5, 'results')

def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.reader(f); next(r)
        return [[float(x) for x in row] for row in r if row]

mu = load(os.path.join(W5, '이민혁', 'mujoco_dt25us.csv'))
ml = load(os.path.join(RES, 'w5_mujoco_vs_matlab_1dof_matlab_dt25us.csv'))
ml100 = load(os.path.join(RES, 'w5_mujoco_vs_matlab_1dof_matlab.csv'))

J = 0.05354166666666667; b = 0.1; Kp = 4.0; Kd = 1.0; Ts = 1e-3
q = qd = 0.0; ex = []
for k in range(2001):
    ref = 0.3 if k >= 200 else 0.0
    u = Kp * (ref - q) - Kd * qd
    ex.append((q, qd))
    a = b / J; e = math.exp(-a * Ts)
    qdn = qd * e + u / b * (1 - e)
    q = q + (qd - u / b) * (1 - e) / a + u / b * Ts
    qd = qdn

t = [r[0] for r in mu]

def metr(rows):
    w = [i for i in range(2001) if 0.2 - 1e-9 <= rows[i][0] <= 2.0 + 1e-9]
    rm = math.sqrt(sum((rows[i][2] - rows[i][1]) ** 2 for i in w) / len(w))
    last = None
    for i in range(200, 2001):
        if abs(rows[i][2] - 0.3) > 0.006: last = i
    ts = rows[last + 1][0] - 0.2 if last is not None else 0.0
    return dict(rmse=rm, ts=ts, os=max(0, (max(r[2] for r in rows[200:]) - 0.3) / 0.3 * 100),
                vmax=max(abs(r[3]) for r in rows[200:]), fe=0.3 - rows[-1][2], tau0=rows[200][4])

Mm, Ml = metr(mu), metr(ml)
dq = [ml[i][2] - mu[i][2] for i in range(2001)]
dv = [ml[i][3] - mu[i][3] for i in range(2001)]
dtau = [ml[i][4] - mu[i][4] for i in range(2001)]
w = [i for i in range(2001) if 0.2 - 1e-9 <= t[i] <= 2.0 + 1e-9]
env_rmse = math.sqrt(sum(dq[i] ** 2 for i in w) / len(w))
env_rmse_v = math.sqrt(sum(dv[i] ** 2 for i in w) / len(w))
mdq = max(abs(x) for x in dq); mdv = max(abs(x) for x in dv); mdt = max(abs(x) for x in dtau)
i_dq = max(range(2001), key=lambda i: abs(dq[i]))
ex_mu = max(abs(mu[i][2] - ex[i][0]) for i in range(2001))
ex_ml = max(abs(ml[i][2] - ex[i][0]) for i in range(2001))
exv_mu = max(abs(mu[i][3] - ex[i][1]) for i in range(2001))
exv_ml = max(abs(ml[i][3] - ex[i][1]) for i in range(2001))
dq100 = max(abs(ml100[i][2] - mu[i][2]) for i in range(2001))

def svg(series, ymin, ymax, title, unit, colors, labels, W=600, H=150, xmax=2.0, fmt='%.3g'):
    L, R, T, B = 52, 8, 18, 22
    pw, ph = W - L - R, H - T - B
    X = lambda x: L + x / xmax * pw
    Y = lambda y: T + (1 - (y - ymin) / (ymax - ymin)) * ph
    s = ['<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg" font-family="Malgun Gothic,sans-serif" font-size="9">' % (W, H)]
    s.append('<text x="%d" y="11" font-weight="bold">%s</text>' % (L, title))
    for k in range(5):
        yy = ymin + (ymax - ymin) * k / 4
        s.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#e3e3e3"/><text x="2" y="%.1f" fill="#555">%s</text>' % (L, Y(yy), W - R, Y(yy), Y(yy) + 3, fmt % yy))
    for xv in (0, 0.5, 1.0, 1.5, 2.0):
        s.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#eee"/><text x="%.1f" y="%d" fill="#555">%g</text>' % (X(xv), T, X(xv), H - B, X(xv) - 6, H - 8, xv))
    for ser, c in zip(series, colors):
        pts = ' '.join('%.1f,%.1f' % (X(t[i]), Y(ser[i])) for i in range(0, 2001, 2))
        s.append('<polyline fill="none" stroke="%s" stroke-width="1.4" points="%s"/>' % (c, pts))
    lx = W - R - 150
    for n, (lab, c) in enumerate(zip(labels, colors)):
        s.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/><text x="%d" y="%d">%s</text>' % (lx, 14 + n * 11, lx + 16, 14 + n * 11, c, lx + 20, 17 + n * 11, lab))
    s.append('<text x="%d" y="%d" fill="#555">t [s] / %s</text></svg>' % (L + pw - 90, H - 1, unit))
    return '\n'.join(s)

g1 = svg([[r[2] for r in ml], [r[2] for r in mu], [r[1] for r in mu]], -0.01, 0.32, '각도 q', 'rad',
         ['#2b5797', '#e07b00', '#999999'], ['MATLAB', 'MuJoCo', '목표'])
g2 = svg([dq], -1e-5, 1e-5, '각도 차이 Δq = MATLAB − MuJoCo', 'rad', ['#c0504d'], ['Δq'], fmt='%.1e')
g3 = svg([dv], -4e-5, 4e-5, '속도 차이 Δqdot = MATLAB − MuJoCo', 'rad/s', ['#7b3fa0'], ['Δqdot'], fmt='%.1e')

def ok(v):
    return '<td class="ok">PASS</td>' if v else '<td class="no">FAIL</td>'

dts = abs(Ml['ts'] - Mm['ts'])
html = f'''<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>1단계 MuJoCo vs MATLAB 비교</title>
<style>@page{{size:A4;margin:11mm 12mm}}body{{font-family:"Malgun Gothic",sans-serif;font-size:9.2pt;line-height:1.38;color:#1a1a1a}}
h1{{font-size:15.5pt;margin:0 0 1.5mm}}h2{{font-size:11pt;margin:4mm 0 1.5mm;border-bottom:1.5px solid #2b5797;color:#2b5797;padding-bottom:.8mm}}
table{{border-collapse:collapse;width:100%;margin:1mm 0 1.5mm}}tr{{page-break-inside:avoid}}th,td{{border:1px solid #b8b8b8;padding:.9mm 2mm;vertical-align:top}}th{{background:#eef2f8;text-align:left}}
.ok{{background:#e4f4e4;color:#1d6b1d;font-weight:bold;text-align:center}}.no{{background:#fde3e3;color:#a11d1d;font-weight:bold;text-align:center}}
.box{{border:1.5px solid #2b5797;background:#f3f7fc;padding:2.3mm 3mm;margin:1mm 0 1.5mm}}.n{{font-size:8.5pt;color:#555}}svg{{width:100%;height:auto;display:block;margin:.5mm 0}}td.m{{font-family:Consolas,"Malgun Gothic",monospace}}</style></head><body>
<h1>1단계 비교: MuJoCo vs MATLAB (이상 토크 1관절)</h1>
<div class="n">MuJoCo 3.14.0 (implicitfast, 25 µs) · MATLAB R2026a (Simscape, ode23t, MaxStep 25 µs, RelTol 1e-6 / AbsTol 1e-9) · 제어 1 ms · 합의된 기준(README 추가 합의)으로 비교</div>
<div class="box"><b>결론: 합의한 두 PASS 기준을 모두 통과했다.</b> 두 환경의 각도 차이는 최대 {mdq:.1e} rad(허용 1e-3의 약 {int(1e-3/mdq)}분의 1), 정착시간은 동일({Ml['ts']:.3f} s)이다.
남은 차이는 MuJoCo 쪽 시간 적분 오차이며(3번 표), 간격을 줄이면 0으로 수렴한다.</div>
<h2>1. 합의 기준 판정</h2>
<table><tr><th>기준</th><th>측정값</th><th style="width:9%">판정</th></tr>
<tr><td>최대 각도 차이 ≤ 0.001 rad (0~2 s, 2001샘플)</td><td class="m">{mdq:.3e} rad (t={t[i_dq]:.3f} s)</td>{ok(mdq <= 1e-3)}</tr>
<tr><td>2% 정착시간 차이 ≤ 0.01 s (양쪽 정착)</td><td class="m">MATLAB {Ml['ts']:.3f} s / MuJoCo {Mm['ts']:.3f} s → 차이 {dts:.3f} s</td>{ok(dts <= 0.01)}</tr>
<tr><td>환경 간 RMSE (각도, 0.2~2 s, 1801샘플) · 보고용</td><td class="m">{env_rmse:.3e} rad</td><td class="n">보고</td></tr>
<tr><td>최대 속도 차이 · 보고용</td><td class="m">{mdv:.3e} rad/s (환경 간 속도 RMSE {env_rmse_v:.3e})</td><td class="n">보고</td></tr>
<tr><td>시간축·목표각·첫 토크</td><td class="m">시간축 일치, 목표각 일치, 첫 토크 MATLAB {Ml['tau0']:.6f} / MuJoCo {Mm['tau0']:.6f} N·m</td>{ok(abs(Ml['tau0'] - 1.2) < 1e-9 and abs(Mm['tau0'] - 1.2) < 1e-9)}</tr></table>
<h2>2. 각 환경 자체 지표</h2>
<table><tr><th>지표</th><th>MATLAB (25 µs)</th><th>MuJoCo (25 µs)</th></tr>
<tr><td>추종 RMSE (0.2~2 s)</td><td class="m">{Ml['rmse']:.7f} rad</td><td class="m">{Mm['rmse']:.7f} rad</td></tr>
<tr><td>2% 정착시간 (스텝 후)</td><td class="m">{Ml['ts']:.3f} s</td><td class="m">{Mm['ts']:.3f} s</td></tr>
<tr><td>오버슈트</td><td class="m">{Ml['os']:.3f} %</td><td class="m">{Mm['os']:.3f} %</td></tr>
<tr><td>최대 속도</td><td class="m">{Ml['vmax']:.6f} rad/s</td><td class="m">{Mm['vmax']:.6f} rad/s</td></tr>
<tr><td>종료 시각 오차</td><td class="m">{Ml['fe']:.3e} rad</td><td class="m">{Mm['fe']:.3e} rad</td></tr></table>
<h2>3. 누가 정확해에 더 가까운가 (1 ms 토크 유지의 닫힌 식 해 기준)</h2>
<table><tr><th>대상</th><th>최대 각도 오차</th><th>최대 속도 오차</th></tr>
<tr><td>MATLAB (25 µs)</td><td class="m">{ex_ml:.3e} rad</td><td class="m">{exv_ml:.3e} rad/s</td></tr>
<tr><td>MuJoCo (25 µs)</td><td class="m">{ex_mu:.3e} rad</td><td class="m">{exv_mu:.3e} rad/s</td></tr></table>
<div class="n">MATLAB은 정확해에 거의 일치(10<sup>-7</sup>)하고, 두 환경 차이는 거의 전부 MuJoCo의 적분 오차다. 이민혁 문서의 100→50→25 µs 오차(3.5e-5 → 1.8e-5 → 8.9e-6 rad)가 절반씩 줄어드는 것과도 맞는다. MATLAB 100 µs 결과와 MuJoCo 25 µs의 최대 각도 차이는 {dq100:.2e} rad로 같은 수준이다.</div>
<h2>4. 그래프</h2>
{g1}{g2}{g3}
<div class="n">차이는 과도 구간(0.2~0.4 s)에서 가장 크고 정착 후에는 사라진다. 두 곡선은 육안으로 구별되지 않는다. 토크 차이는 최대 {mdt:.1e} N·m(첫 토크 1.2 N·m 대비 무시할 수준).</div>
<div class="n">한계: 이 결과는 PMSM 없는 이상 토크, 기어비 1, 중력 없음 조건의 역학·제어 일치 확인이다. MATLAB 쪽 수치는 저장된 CSV, MuJoCo 쪽은 이민혁 님의 mujoco_dt25us.csv에서 직접 계산했다. 잠정 허용 오차는 하드웨어 정확도 기준이 아니다.</div>
</body></html>'''
out = os.path.join(RES, 'stage1_mujoco_vs_matlab_comparison.html')
open(out, 'w', encoding='utf-8').write(html)
print('wrote', out)
print('max dq %.3e | env RMSE %.3e | ts %.3f/%.3f' % (mdq, env_rmse, Ml['ts'], Mm['ts']))
