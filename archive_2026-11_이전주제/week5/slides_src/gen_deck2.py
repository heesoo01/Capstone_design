import os, json
ROOT = r'C:\Users\cogml\AppData\Local\Temp\claude\D--Capstone-design\edb736f6-0281-455c-9f8d-74587459bbc9\scratchpad\deck2'
os.makedirs(os.path.join(ROOT, 'project', 'slides'), exist_ok=True)
LIGHT, CARD, INK, MUTE, BLUE, ORANGE, GREEN, LINE = '#F4F6F9', '#FBFCFD', '#17202C', '#586374', '#2A5DB0', '#B3560F', '#1F7A45', '#D6DCE6'
FF = "font-family:'Noto Sans KR','Malgun Gothic',Arial,sans-serif"
IMG = {'s1': '/_blob/2b0a0c48d666f2477e090d91fbd10085', 's2': '/_blob/dacb995567e01f0cd83300eac03d223b', 's3': '/_blob/f713f58f5cbe1304eb0e8327a6de4610',
       'errors': '/_blob/214bfb57a3fd3ba777cc0178ead98780', 'gantt': '/_blob/2252784e47df5cddb8aaad757e2c6de9'}
N = 9
order = ['feedback', 'stage1', 'stage2', 'stage3', 'compare', 'result', 'task', 'gantt', 'questions']


def sec(id, body, notes=''):
    import re
    body = re.sub(r'· \d+ / \d+', '· %d / %d' % (order.index(id) + 1, N), body)
    return ('<section id="%s" data-transition="fade" style="background:%s;color:%s;%s;padding:96px 128px 160px;display:flex;flex-direction:column;gap:28px">\n%s\n<aside>%s</aside>\n</section>\n'
            % (id, LIGHT, INK, FF, body, notes))


def head(eyebrow, title, size=58):
    return ('<p style="font-size:28px;font-weight:700;color:%s;letter-spacing:2px">%s</p>\n<h2 style="font-size:%dpx;font-weight:700;line-height:1.15">%s</h2>' % (BLUE, eyebrow, size, title))


def foot(i):
    return '<p style="position:absolute;left:128px;bottom:64px;width:1664px;font-size:24px;color:%s">5주차 진행 보고 · %d / %d</p>' % (MUTE, i, N)


def cap(text):
    return '<p style="font-size:28px;line-height:1.4;color:%s">%s</p>' % (MUTE, text)


def img(key, w, h, alt):
    return '<img src="%s" alt="%s" style="width:%dpx;height:%dpx;object-fit:contain;background:#FFFFFF;border-radius:12px;border:2px solid %s">' % (IMG[key], alt, w, h, LINE)


def card(inner, border=LINE):
    return '<div style="flex:1;display:flex;flex-direction:column;gap:14px;background:%s;padding:32px;border:2px solid %s;border-radius:16px">%s</div>' % (CARD, border, inner)


def bullets(items, size=28):
    return '<ul style="font-size:%dpx;line-height:1.45">%s</ul>' % (size, ''.join('<li>%s</li>' % x for x in items))


def lab(t, col=BLUE):
    return '<p style="font-size:30px;font-weight:700;color:%s">%s</p>' % (col, t)


def table(rows, widths, size=26):
    out = '<table style="font-size:%dpx;color:%s;%s">' % (size, INK, FF)
    for r_i, r in enumerate(rows):
        out += '<tr>'
        tag = 'th' if r_i == 0 else 'td'
        for c_i, c in enumerate(r):
            st = ' style="width:%d%%"' % widths[c_i] if r_i == 0 else ''
            out += '<%s%s>%s</%s>' % (tag, st, c, tag)
        out += '</tr>'
    return out + '</table>'


def stage(id, n, title, key, w, h, alt, col_w, structure, results, notes):
    right = ('<div style="width:%dpx;display:flex;flex-direction:column;gap:18px">' % col_w + lab('구조') + bullets(structure, 26) + lab('결과 (MATLAB과 MuJoCo의 최대 차이)', GREEN) + bullets(results, 26) + '</div>')
    return sec(id, head('두 환경 비교 · 단계 %d / 3' % n, title) + '\n<div style="display:flex;gap:40px;align-items:center">' + img(key, w, h, alt) + right + '</div>\n' + foot(n + 1), notes)


S = {}
rows = [['지난 피드백', '해본 것', '결론'],
        ['MuJoCo는 어디까지 구현되어 있고, 어디를 바꿔야 하나', '같은 조건으로 Simscape에 모델을 만들고, 외부 Python PMSM을 쓴 MuJoCo와 단계별로 비교', '두 환경 모두 같은 액추에이터 모델을 구현할 수 있고 결과가 같았다. MuJoCo는 전기 쪽을 코드로 넣어야 한다'],
        ['평균 모델만 써도 되는 이유를 설득', '평균 인버터로 구현하고 전압 한계·포화까지 반영해서 비교', 'PWM과의 직접 비교는 아직 못 했다. 다음 계획'],
        ['발표자료를 만들고 마지막에 일정 점검', '이 자료와 간트차트 상세화', '지연 1건 (8쪽)']]
S['feedback'] = sec('feedback', head('5주차 진행 보고 · 채희수', '지난 피드백에 해본 것과 결론') + '\n' + table(rows, [24, 40, 36], 26) + '\n' +
                    cap('비교 조건(모두 가정값): 1자유도, 링크 1 kg, 위치 PD Kp 4 / Kd 1 (1 ms), PMSM R 0.5 Ω · L 5 mH · Kt 0.3 N·m/A, 전류 PI 1.5 / 150 (100 µs), 전원 24 V · 2 V, 목표 0.3 · 2 rad') + '\n' + foot(1),
                    '지난 미팅의 세 가지 피드백에 이번 주 무엇을 해서 어떤 결론이 났는지 한 장으로 정리했습니다. MuJoCo에는 PMSM과 인버터 기본 기능이 없어서 민혁이 외부 Python으로 넣었고, 저는 같은 조건으로 Simscape에서 만들어 비교했습니다. 평균 모델이 충분한지는 아직 PWM과 직접 비교하지 못했습니다.')

S['stage1'] = stage('stage1', 1, '1단계: 이상 토크 + 위치 PD', 's1', 974, 640, '1단계 Simulink 모델: 관절, 위치 PD, 로깅', 650,
                    ['Simscape 관절(RevoluteJoint, LinkInertia)에 이상 토크를 직접 입력', '위치 PD (Kp 4, Kd 1)를 1 ms마다 계산', '조건은 MuJoCo와 같게 맞춤'],
                    ['각도 8.7e-6 rad (허용 1e-3)', '정착시간 둘 다 0.904 s'],
                    '1단계는 모터 없이 이상 토크를 넣는 가장 단순한 구조입니다. 관절 기계 부분과 위치 PD만 맞는지 먼저 확인했습니다.')
S['stage2'] = stage('stage2', 2, '2단계: PMSM + 전류 PI + 평균 인버터', 's2', 1000, 525, '2단계 Simulink 모델: 위치 PD, 전류 PI, 전압 제한, PMSM', 624,
                    ['위치 PD → 전류 PI(전향 보상) → 전압 제한 → PMSM → 관절', '전압 한계 Vdc÷√3, 안티윈드업', 'PMSM 식은 dq 좌표에서 직접 구현'],
                    ['각도 5.3e-6 rad, iq 1.2e-4 A', '2 V 전압 포화 구간(0.200~0.807 s)까지 일치'],
                    'Position_PD가 필요한 토크를 정하고, Current_PI_FF가 전류를 제어해 전압을 만들고, Voltage_Limit가 인버터 한계로 자르고, PMSM_dq가 전류와 토크를 계산합니다. 2 V는 일부러 전압이 모자라게 한 조건입니다.')
S['stage3'] = stage('stage3', 3, '3단계: 기어비 5 + 회전자 관성', 's3', 818, 640, '3단계 Simulink 모델: 2단계에 Gear 블록 추가', 806,
                    ['Gear 블록: 모터 속도 = 5 × 관절 속도, 관절 토크 = 5 × 모터 토크, iq 지령 = 토크 ÷ (5·Kt)', '회전자 관성은 환산값 0.0025 kg·m²를 한 번만 더함 (중복 금지)'],
                    ['각도 7.2e-6 rad, iq 3.1e-4 A, 관절 토크 4.6e-4 N·m', '이민혁의 공식 비교 도구도 3-1, 3-2 전부 통과'],
                    '기어를 넣으면 전류 지령 변환, 모터 속도, 관절 토크 세 곳이 바뀝니다. 모터 속도가 5배라 역기전력도 5배가 됩니다. 단독 검사로 모터 토크 0.02가 관절 토크 0.1이 되는 것을 먼저 확인했습니다.')

rows = [['이번에 구현한 것', 'MuJoCo', 'Simscape (Simulink)', '두 환경 비교'],
        ['관절 강체 (관성, 감쇠)', 'MuJoCo 기본', 'Simscape 블록', '일치 (1단계)'],
        ['위치 PD (1 ms)', 'Python 코드', 'Simulink 블록', '일치 (1단계)'],
        ['PMSM 전기 모델 (dq)', 'Python 코드', 'Simulink 블록', '일치 (2-1, 2-2)'],
        ['전류 PI + 전향 보상', 'Python 코드', 'Simulink 블록', '일치 (2-2)'],
        ['전압 제한 · 안티윈드업', 'Python 코드', 'Simulink 블록', '포화 구간 일치 (2-3)'],
        ['평균 인버터', 'Python 코드', 'Simulink 블록', '일치 (2-2, 2-3)'],
        ['전류 지령 제한 ±2 A', 'Python 코드', 'Simulink 블록', '일치 (2-2)'],
        ['기어비 5', 'Python 코드', 'Simulink 블록', '일치 (3-1)'],
        ['회전자 관성 0.0025', '관절 armature', '관성 가산', '일치 (3-2)']]
S['compare'] = sec('compare', head('두 환경 비교표', '이번에 구현한 것 전부: MuJoCo는 전기 쪽이 코드, Simscape는 블록', 50) + '\n' + table(rows, [30, 22, 26, 22], 24) + '\n' +
                   cap('아직 구현 안 함: PWM 스위칭, 마찰, 백래시, 열. 문서상 Simscape는 블록이 있고 MuJoCo는 마찰·백래시를 설정으로, PWM·열은 코드로 넣어야 한다. 직접 구현 비교는 다음 단계') + '\n' + foot(5),
                   'MuJoCo는 관절과 기계 부분만 기본 기능이고, 위치 PD부터 전류 제어, 전압 제한, 인버터, PMSM까지 전기 쪽은 민혁이 Python으로 직접 넣었습니다. Simscape는 같은 식을 Simulink 블록으로 구성했고, 동하는 Simscape Electrical의 PMSM 블록으로 따로 구현했습니다. 표의 모든 항목은 두 환경에서 일치했습니다. 아래 줄은 아직 구현하지 않은 현실 특성입니다.')

S['result'] = sec('result', head('결론', '두 환경의 차이는 허용치의 1/30 이하') + '\n' + img('errors', 1350, 455, '단계별 최대 각도 차이와 iq 차이, 허용치 비교') + '\n' +
                  bullets(['두 환경 모두 같은 액추에이터 모델(전류 제어, 전압 포화, 기어, 관성)을 구현할 수 있고 결과가 같다. MuJoCo는 전기 쪽을 코드로 넣어야 한다', '한계: 가정값이고 하드웨어 검증이 아니다. 마찰·백래시·PWM·열은 다음 단계에서 확인하며, 이것만으로 시뮬레이터를 고르지는 않는다'], 28) + '\n' + foot(6),
                  '각도는 허용치의 약 140분의 1, iq와 관절 토크는 약 30분의 1입니다. 허용치는 이번에 정한 잠정 기준입니다. 이 결과는 두 환경이 같은 가정 모델을 같게 계산한다는 뜻이고, 어느 시뮬레이터가 낫다는 뜻은 아닙니다.')

S['task'] = sec('task', head('태스크 조사', '목표 지점 던지기가 액추에이터 영향을 가장 잘 드러낸다', 52) + '\n<div style="display:flex;gap:32px">' +
                card(lab('왜 던지기인가', GREEN) + bullets(['사거리 R = v²·sin2θ / g. 릴리스 속도 오차 1%가 착지 오차 약 2%로 커짐', 'Pick-and-Place는 저속이라 토크 한계나 포화가 결과에 거의 안 나타남', '선행연구: TossingBot (Zeng et al.)'], 26), GREEN) +
                card(lab('범위와 아직 미정인 것', ORANGE) + bullets(['1자유도 던지기 팔, 릴리스는 스크립트로 처리', 'Pick-and-Place는 질량 변화 검증용 1단계로 재배치', '미정: 질량 범위, 목표 거리, 착지 오차 허용치, 평가지표'], 26), ORANGE) + '</div>\n' + foot(6),
                '태스크 조사는 팀 자료(제안발표 피드백 수정구성안, 태스크 조사)를 정리한 것입니다. 던지기는 릴리스 속도가 착지 오차를 직접 결정해서 액추에이터 재현도의 영향을 정량적으로 볼 수 있습니다. 세부 요구사항은 아직 정하지 않았습니다.')

S['gantt'] = sec('gantt', head('일정 점검', '지연 1건(간트 확정이 팀 합의 대기), 나머지는 진행 중', 52) + '\n' + img('gantt', 1479, 658, '이번 주부터 W9까지 간트차트와 진행률') + '\n' + foot(7),
                 '지난 주 마감 항목 중 간트차트 확정만 팀 합의가 남아 있어 지연으로 셉니다. 담당과 진행률은 현재 기록 기준의 제안입니다. 전체 30개 일(W5~W18)은 RAMS 간트차트에 있습니다.')

qs = ['기존 시뮬레이터는 MATLAB·MuJoCo 외에 몇 개, 어떤 기준으로 보면 충분한가요?',
      '던지기 요구사항(질량 범위, 목표 거리, 착지 오차)은 어떤 기준으로 정할까요? 물체의 비행 구간은 시뮬레이터 안에서 계산해도 되나요?',
      '평균 인버터 모델이 충분하다고 설명하려면 PWM 비교를 어느 수준까지 보여야 하나요?',
      '시뮬레이터 선정을 W7로 미루고, 그때까지 MATLAB 우선, MuJoCo 보조로 가도 될까요?']
S['questions'] = sec('questions', head('질문', '교수님께 드리는 질문 4개') + '\n<ol style="font-size:34px;line-height:1.5">' + ''.join('<li>%s</li>' % q for q in qs) + '</ol>\n' + foot(8),
                     '1번은 지난 피드백의 시뮬레이터 질문 후속, 2번은 태스크 요구사항, 3번은 평균 모델 설득, 4번은 일정과 선정 시점에 관한 질문입니다.')

for k in order:
    open(os.path.join(ROOT, 'project', 'slides', k + '.html'), 'w', encoding='utf-8').write(S[k])
deck = {"v": 4, "attachments": {}, "createdOnFiles": {"at": "2026-10-05T15:00:45Z", "v": 1}, "designSystems": [],
        "faces": {"noto-sans-kr": {"family": "Noto Sans KR", "href": "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap"}},
        "lists": "css", "order": order,
        "sections": {"s1": {"description": "지난 피드백에 해본 것과 결론", "start": "feedback"}, "s2": {"description": "단계별 구조와 결과", "start": "stage1"},
                     "s3": {"description": "비교표, 결론, 태스크, 일정, 질문", "start": "compare"}},
        "title": "5주차 진행 보고"}
json.dump(deck, open(os.path.join(ROOT, 'project', 'deck.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('ok')
