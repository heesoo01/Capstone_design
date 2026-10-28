"""2-3 비교 리포트(HTML). 먼저 w5s2_3_compare.py 실행 후: python w5s2_3_compare_report.py"""
import csv, math, io, sys, os, json
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W5 = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
MU = os.path.join(W5, '이민혁'); RES = os.path.join(W5, 'results')
M = json.load(open(os.path.join(RES, 'stage2_3_compare_metrics.json'), encoding='utf-8'))

def load(p):
    with open(p, encoding='utf-8-sig') as f:
        r = csv.DictReader(f); cols = {k: [] for k in r.fieldnames}
        for row in r:
            for k in cols: cols[k].append(float(row[k]))
    return cols

def svg(t, series, ymin, ymax, title, unit, colors, labels, W=600, H=140, xmax=2.0, fmt='%.3g'):
    L, R, T, B = 52, 8, 17, 21
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
        step = max(1, len(t) // 1000)
        pts = ' '.join('%.1f,%.1f' % (X(t[i]), Y(ser[i])) for i in range(0, len(t), step))
        s.append('<polyline fill="none" stroke="%s" stroke-width="1.4" points="%s"/>' % (c, pts))
    lx = W - R - 140
    for k, (lab, c) in enumerate(zip(labels, colors)):
        s.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="2"/><text x="%d" y="%d">%s</text>' % (lx, 13 + k * 11, lx + 16, 13 + k * 11, c, lx + 20, 16 + k * 11, lab))
    s.append('<text x="%d" y="%d" fill="#555">t [s] / %s</text></svg>' % (L + pw - 90, H - 1, unit))
    return '\n'.join(s)

ok = lambda v: '<td class="ok">PASS</td>' if v else '<td class="no">FAIL</td>'
f6 = lambda v: 'N/A' if v is None else ('%.3f' % v)
graphs = ''
for label, mu_tag, ml_tag in (('24V', 'normal_24V', '2-3_24V'), ('2V', 'low_2V', '2-3_2V')):
    mp = load(os.path.join(MU, mu_tag + '_position_dt6p25us.csv')); me = load(os.path.join(MU, mu_tag + '_electrical_dt6p25us.csv'))
    lp = load(os.path.join(RES, 'w5s2_%s_matlab_pos_dt6p25us.csv' % ml_tag)); le = load(os.path.join(RES, 'w5s2_%s_matlab_elec_dt6p25us.csv' % ml_tag))
    tp = mp['time_s']; te = me['time_s']
    graphs += '<h2>그래프 · %s</h2>' % label
    graphs += svg(tp, [lp['angle_rad'], mp['angle_rad'], mp['target_rad']], -0.1, 2.1, '각도 q (%s)' % label, 'rad', ['#2b5797', '#e07b00', '#999999'], ['MATLAB', 'MuJoCo', '목표'])
    graphs += svg(te, [le['iq_A'], me['iq_A'], le['iq_ref_A']], -2.4, 2.4, '전류 iq (%s)' % label, 'A', ['#2b5797', '#e07b00', '#999999'], ['MATLAB', 'MuJoCo', 'iq 지령'])
    dq = [lp['angle_rad'][i] - mp['angle_rad'][i] for i in range(len(tp))]
    lim = 6e-6 if label == '24V' else 3e-6
    graphs += svg(tp, [dq], -lim, lim, '각도 차이 Δq = MATLAB − MuJoCo (%s)' % label, 'rad', ['#c0504d'], ['Δq'], fmt='%.1e')

rows = ''
for label in ('24V', '2V'):
    r = M[label]
    rows += f'''<tr><td rowspan="5"><b>{label}</b></td><td>최대 각도 차이 ≤ 1e-3 rad (1 ms, 2001샘플)</td><td class="m">{r['max_dq']:.2e} rad (t={r['t_max_dq']:.3f} s)</td>{ok(r['pass_q'])}</tr>
<tr><td>최대 iq 차이 ≤ 0.01 A (100 µs, 20001샘플)</td><td class="m">{r['max_diq']:.2e} A (t={r['t_max_diq']:.4f} s)</td>{ok(r['pass_iq'])}</tr>
<tr><td>최대 관절 토크 차이 ≤ 0.003 N·m</td><td class="m">{r['max_dtq']:.2e} N·m</td>{ok(r['pass_tq'])}</tr>
<tr><td>정착시간 차이 ≤ 0.01 s (±0.04 rad, 스텝 후)</td><td class="m">MATLAB {f6(r['settle_ml'])} s / MuJoCo {f6(r['settle_mu'])} s</td>{ok(r['pass_ts'])}</tr>
<tr><td>전압 포화 구간 (보고)</td><td class="m">MATLAB {r['sat_dur_ml']:.4f} s ({100*r['sat_frac_ml']:.2f}%) / MuJoCo {r['sat_dur_mu']:.4f} s ({100*r['sat_frac_mu']:.2f}%), 플래그 불일치 {r['sat_flag_mismatch_rows']}행</td><td class="n">보고</td></tr>'''
met = ''
for label in ('24V', '2V'):
    r = M[label]
    met += f'''<tr><td><b>{label}</b></td><td class="m">{r['track_rmse_ml']:.6f} / {r['track_rmse_mu']:.6f}</td><td class="m">{r['env_rmse_q']:.2e}</td><td class="m">{r['peak_speed_ml']:.5f} / {r['peak_speed_mu']:.5f}</td><td class="m">{r['iq_track_rmse_ml']:.5f} / {r['iq_track_rmse_mu']:.5f}</td><td class="m">{r['vmag_max_ml']:.4f} / {r['vmag_max_mu']:.4f} (한계 {r['v_limit']:.4f})</td></tr>'''

html = f'''<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><title>2-3 전압 비교</title>
<style>@page{{size:A4;margin:11mm 12mm}}body{{font-family:"Malgun Gothic",sans-serif;font-size:9.1pt;line-height:1.36;color:#1a1a1a}}
h1{{font-size:15.5pt;margin:0 0 1.5mm}}h2{{font-size:10.5pt;margin:3.5mm 0 1.2mm;border-bottom:1.5px solid #2b5797;color:#2b5797;padding-bottom:.6mm}}
table{{border-collapse:collapse;width:100%;margin:1mm 0 1.5mm}}tr{{page-break-inside:avoid}}th,td{{border:1px solid #b8b8b8;padding:.8mm 1.8mm;vertical-align:top}}th{{background:#eef2f8;text-align:left}}
.ok{{background:#e4f4e4;color:#1d6b1d;font-weight:bold;text-align:center;width:8%}}.no{{background:#fde3e3;color:#a11d1d;font-weight:bold;text-align:center}}
.box{{border:1.5px solid #2b5797;background:#f3f7fc;padding:2.2mm 3mm;margin:1mm 0 1.5mm}}.n{{font-size:8.5pt;color:#555}}svg{{width:100%;height:auto;display:block;margin:.3mm 0}}td.m{{font-family:Consolas,"Malgun Gothic",monospace}}</style></head><body>
<h1>2-3 비교: DC 전압 24 V / 2 V (MuJoCo vs MATLAB)</h1>
<div class="n">목표 2 rad (0.2 s 스텝), 기어비 1, 회전자 관성 0, PMSM R 0.5 Ω · L 5 mH · ψf 0.05 Wb · 극쌍 4, 위치 PD 4/1 (1 ms), 전류 PI 1.5/150 (100 µs), 안티윈드업 300 · 두 환경 6.25 µs 결과, 같은 전압끼리 비교, 시간축 이동 없음 · MuJoCo 3.14.0 vs MATLAB R2026a (ode23t, MaxStep 6.25 µs)</div>
<div class="box"><b>결론: 24 V, 2 V 모두 합의 기준 4개를 전부 통과했다.</b> 각도 차이는 최대 {M['24V']['max_dq']:.1e} rad(24 V), {M['2V']['max_dq']:.1e} rad(2 V)로 허용 1e-3의 약 190~400분의 1이고, 전압 포화 구간은 2 V에서 0.2~0.807 s로 20001개 기록 중 불일치 0행이다.
이민혁 문서가 개발 환경에서 보고한 값(24 V RMSE 0.909490 rad·정착 1.193 s, 2 V RMSE 0.949104 rad·정착 1.271 s·포화 0.5326 s)을 이번 CSV로 그대로 재현했다.</div>
<h2>1. 합의 기준 판정</h2>
<table><tr><th style="width:6%">전압</th><th style="width:36%">기준</th><th>측정값</th><th>판정</th></tr>{rows}</table>
<h2>2. 보고 지표 (MATLAB / MuJoCo)</h2>
<table><tr><th>전압</th><th>위치 추종 RMSE [rad]</th><th>환경 간 RMSE(q) [rad]</th><th>최대 속도 [rad/s]</th><th>iq 추종 RMSE [A]</th><th>적용 전압 최대 [V]</th></tr>{met}</table>
<div class="n">위치 추종 RMSE(각 환경의 q−목표)와 환경 간 RMSE(두 환경의 q 차이)를 구분해서 보고했다. 2 V에서는 전압 포화 때문에 iq 지령(최대 2 A)을 못 따라가 iq 추종 RMSE가 24 V의 약 5배로 커지지만, 위치는 2초 안에 정착한다 (저전압이 항상 미정착은 아님).
남은 차이는 MuJoCo 적분 오차 수준이다: 이민혁 summary의 결합 ODE 기준 대비 iq 오차가 24 V 1.2e-4 A, 2 V 6.3e-5 A이며 이번 환경 간 iq 차이(1.2e-4 A, 6.5e-5 A)와 같은 크기다.</div>
{graphs}
<div class="n">한계: 가정 파라미터의 이상적 PMSM·평균 전압 모델 비교이며 PWM·스위칭·보호·DC 링크 동특성·실제 모터 사양은 포함하지 않는다. 2 V는 제한 현상을 보기 위한 극단적 가정 조건이다. 2-2(24 V, 0.3 rad)는 MuJoCo CSV 수령 전이라 비교하지 않았다.</div>
</body></html>'''
out = os.path.join(RES, 'stage2_3_mujoco_vs_matlab_comparison.html')
open(out, 'w', encoding='utf-8').write(html)
print('wrote', out)
