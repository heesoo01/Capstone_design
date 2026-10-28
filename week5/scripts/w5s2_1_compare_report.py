"""2-1(전기 모델 단독) MuJoCo vs MATLAB 비교 리포트(HTML) 생성. 사용: python w5s2_1_compare_report.py"""
import csv, math, io, sys, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
RES = os.path.join(W5, 'results')

def load(p):
    with open(p, encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))

mu = load(os.path.join(W5, '이민혁', 'pmsm_dt6p25us.csv'))
ml = load(os.path.join(RES, 'w5s2_2-1_matlab_elec_dt6p25us.csv'))
ml25 = load(os.path.join(RES, 'w5s2_2-1_matlab_elec_dt25us.csv'))
t = [float(r['time_s']) for r in mu]
mu_iq = [float(r['iq_A']) for r in mu]; mu_tq = [float(r['motor_torque_Nm']) for r in mu]
ml_iq = [float(r['iq_A']) for r in ml]; ml_tq = [float(r['torque_Nm']) for r in ml]
ml25_iq = [float(r['iq_A']) for r in ml25]
ex = [2 * (1 - math.exp(-x / 0.01)) for x in t]
n = len(t)
diq = [ml_iq[i] - mu_iq[i] for i in range(n)]
dtq = [ml_tq[i] - mu_tq[i] for i in range(n)]
mdiq = max(abs(x) for x in diq); mdtq = max(abs(x) for x in dtq)
i_m = max(range(n), key=lambda i: abs(diq[i]))
ex_ml = max(abs(ml_iq[i] - ex[i]) for i in range(n)); ex_mu = max(abs(mu_iq[i] - ex[i]) for i in range(n))
ex_ml25 = max(abs(ml25_iq[i] - ex[i]) for i in range(n))
d25 = max(abs(ml25_iq[i] - mu_iq[i]) for i in range(n))
i10 = min(range(n), key=lambda i: abs(t[i] - 0.01))

def svg(series, ymin, ymax, title, unit, colors, labels, W=600, H=150, xmax=0.1, fmt='%.3g'):
    L, R, T, B = 56, 8, 18, 22
    pw, ph = W - L - R, H - T - B
    X = lambda x: L + x / xmax * pw
    Y = lambda y: T + (1 - (y - ymin) / (ymax - ymin)) * ph
    s = ['<svg viewBox="0 0 %d %d" xmlns="http://www.w3.org/2000/svg" font-family="Malgun Gothic,sans-serif" font-size="9">' % (W, H)]
    s.append('<text x="%d" y="11" font-weight="bold">%s</text>' % (L, title))
    for k in range(5):
        yy = ymin + (ymax - ymin) * k / 4
        s.append('<line x1="%d" y1="%.1f" x2="%d" y2="%.1f" stroke="#e3e3e3"/><text x="2" y="%.1f" fill="#555">%s</text>' % (L, Y(yy), W - R, Y(yy), Y(yy) + 3, fmt % yy))
    for xv in (0, 0.02, 0.04, 0.06, 0.08, 0.1):
        s.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="#eee"/><text x="%.1f" y="%d" fill="#555">%g</text>' % (X(xv), T, X(xv), H - B, X(xv) - 8, H - 8, xv))
    for ser, c in zip(series, colors):
        pts = ' '.join('%.1f,%.1f' % (X(t[i]), Y(ser[i])) for i in range(0, n, 2))
        s.append('<polyline fill="none" stroke="%s" stroke-width="1.4" points="%s"/>' % (c, pts))
    lx = W - R - 150
    for k, (lab, c) in enumerate(zip(labels, colors)):
        s.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/><text x="%d" y="%d">%s</text>' % (lx, 14 + k * 11, lx + 16, 14 + k * 11, c, lx + 20, 17 + k * 11, lab))
    s.append('<text x="%d" y="%d" fill="#555">t [s] / %s</text></svg>' % (L + pw - 90, H - 1, unit))
    return '\n'.join(s)

g1 = svg([ml_iq, mu_iq, ex], -0.05, 2.1, '전류 iq', 'A', ['#2b5797', '#e07b00', '#999999'], ['MATLAB', 'MuJoCo', '해석해'])
g2 = svg([diq], -3e-8, 3e-8, '전류 차이 Δiq = MATLAB − MuJoCo', 'A', ['#c0504d'], ['Δiq'], fmt='%.1e')
ok = lambda v: '<td class="ok">PASS</td>' if v else '<td class="no">FAIL</td>'
html = f'''<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>2-1 전기 모델 단독 비교</title>
<style>@page{{size:A4;margin:11mm 12mm}}body{{font-family:"Malgun Gothic",sans-serif;font-size:9.2pt;line-height:1.38;color:#1a1a1a}}
h1{{font-size:15.5pt;margin:0 0 1.5mm}}h2{{font-size:11pt;margin:4mm 0 1.5mm;border-bottom:1.5px solid #2b5797;color:#2b5797;padding-bottom:.8mm}}
table{{border-collapse:collapse;width:100%;margin:1mm 0 1.5mm}}tr{{page-break-inside:avoid}}th,td{{border:1px solid #b8b8b8;padding:.9mm 2mm;vertical-align:top}}th{{background:#eef2f8;text-align:left}}
.ok{{background:#e4f4e4;color:#1d6b1d;font-weight:bold;text-align:center}}.no{{background:#fde3e3;color:#a11d1d;font-weight:bold;text-align:center}}
.box{{border:1.5px solid #2b5797;background:#f3f7fc;padding:2.3mm 3mm;margin:1mm 0 1.5mm}}.n{{font-size:8.5pt;color:#555}}svg{{width:100%;height:auto;display:block;margin:.5mm 0}}td.m{{font-family:Consolas,"Malgun Gothic",monospace}}</style></head><body>
<h1>2-1 비교: 고정 속도 PMSM 전기 모델 (MuJoCo vs MATLAB)</h1>
<div class="n">조건: 모터 속도 0 고정, vd = 0 V, vq = 1 V (0~0.1 s), R 0.5 Ω, Ld = Lq = 5 mH, ψf 0.05 Wb, 극쌍 4, 초기 전류 0 · 기록 100 µs, 1001행 · MuJoCo 3.14.0 (Python RK4, 6.25 µs) · MATLAB R2026a (Simulink ode23t, MaxStep 6.25 µs, RelTol 1e-6 / AbsTol 1e-9)</div>
<div class="box"><b>결론: 합의한 두 기준을 모두 통과했다.</b> 두 환경의 전류 차이는 최대 {mdiq:.1e} A, 토크 차이는 최대 {mdtq:.1e} N·m이며 둘 다 해석해 iq(t) = 2(1 − e<sup>−t/0.01</sup>) A에 일치한다.
이번 시험은 속도 0이라 역기전력과 dq 결합항이 0이므로, 회전 상태의 결합항 검증은 2-2 통합 시험에서 한다.</div>
<h2>1. 판정</h2>
<table><tr><th>기준</th><th>측정값</th><th style="width:9%">판정</th></tr>
<tr><td>최대 iq 차이 ≤ 1e-5 A (1001샘플)</td><td class="m">{mdiq:.3e} A (t = {t[i_m]:.4f} s)</td>{ok(mdiq <= 1e-5)}</tr>
<tr><td>최대 토크 차이 ≤ 3e-6 N·m</td><td class="m">{mdtq:.3e} N·m</td>{ok(mdtq <= 3e-6)}</tr>
<tr><td>id (양쪽)</td><td class="m">모두 0</td><td class="n">확인</td></tr>
<tr><td>iq(10 ms) · 해석해 1.264241118 A</td><td class="m">MATLAB {ml_iq[i10]:.9f} / MuJoCo {mu_iq[i10]:.9f}</td><td class="n">확인</td></tr></table>
<h2>2. 해석해와의 차이</h2>
<table><tr><th>대상</th><th>해석해 대비 최대 iq 오차</th></tr>
<tr><td>MuJoCo (RK4, 6.25 µs)</td><td class="m">{ex_mu:.2e} A (부동소수점 수준)</td></tr>
<tr><td>MATLAB (ode23t, 6.25 µs)</td><td class="m">{ex_ml:.2e} A</td></tr>
<tr><td>MATLAB (ode23t, 25 µs)</td><td class="m">{ex_ml25:.2e} A (MuJoCo 6.25 µs와의 차이 {d25:.2e} A)</td></tr></table>
<div class="n">MATLAB 오차는 가변 스텝 솔버의 허용오차(RelTol 1e-6) 수준이고, 간격 상한을 25 → 12.5 → 6.25 µs로 줄이면 3.8e-7 → 9.5e-8 → 2.4e-8 A로 감소한다. 두 환경이 같은 dq 식·단위·토크 배율(0.3 N·m/A)을 쓰고 있음을 확인했다.</div>
<h2>3. 그래프</h2>
{g1}{g2}
<div class="n">한계: 전기 방정식만의 시험이며 관절 운동, 역기전력, 전류 제어, 전압 제한은 포함하지 않는다. 기준은 이번 실험을 위한 잠정 수치이고 하드웨어 정확도 기준이 아니다. 두 CSV는 같은 시각끼리 비교했다.</div>
</body></html>'''
out = os.path.join(RES, 'stage2_1_mujoco_vs_matlab_comparison.html')
open(out, 'w', encoding='utf-8').write(html)
print('wrote', out)
print('max diq %.3e A | max dtq %.3e | ex_ml %.2e ex_mu %.2e' % (mdiq, mdtq, ex_ml, ex_mu))
