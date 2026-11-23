import os, json, datetime
ROOT = r'C:\Users\cogml\AppData\Local\Temp\claude\D--Capstone-design\edb736f6-0281-455c-9f8d-74587459bbc9\scratchpad\deck'
os.makedirs(os.path.join(ROOT, 'project', 'slides'), exist_ok=True)

LIGHT, CARD, INK, MUTE, BLUE, ORANGE, GREEN, LINE = '#F4F6F9', '#FBFCFD', '#17202C', '#586374', '#2A5DB0', '#B3560F', '#1F7A45', '#D6DCE6'
DARKBG, ONDARK, ACC = '#17202C', '#F4F6F9', '#9DBDF0'
FF = "font-family:'Noto Sans KR','Malgun Gothic',Arial,sans-serif"
IMG = {'response': '/_blob/3b73058754514df1b593b040ab417649', 'errors': '/_blob/214bfb57a3fd3ba777cc0178ead98780',
       'sat': '/_blob/580d600911bdfb24153f29ecba17e897', 'gantt': '/_blob/2252784e47df5cddb8aaad757e2c6de9'}
N = 14
order = ['cover', 'feedback', 'chain', 'response', 'errors', 'saturation', 'meaning', 'mujoco', 'pmsm', 'survey', 'average', 'task', 'gantt', 'questions']


def sec(id, body, notes='', bg=LIGHT, color=INK, pad='96px 128px 160px', justify=''):
    j = ';justify-content:' + justify if justify else ''
    return ('<section id="%s" data-transition="fade" style="background:%s;color:%s;%s;padding:%s;display:flex;flex-direction:column;gap:28px%s">\n%s\n<aside>%s</aside>\n</section>\n'
            % (id, bg, color, FF, pad, j, body, notes))


def head(eyebrow, title, size=60):
    return ('<p style="font-size:28px;font-weight:700;color:%s;letter-spacing:2px">%s</p>\n<h2 style="font-size:%dpx;font-weight:700;line-height:1.15">%s</h2>' % (BLUE, eyebrow, size, title))


def foot(i):
    return '<p style="position:absolute;left:128px;bottom:64px;width:1664px;font-size:24px;color:%s">5주차 진행 보고 · %d / %d</p>' % (MUTE, i, N)


def cap(text):
    return '<p style="font-size:28px;line-height:1.4;color:%s">%s</p>' % (MUTE, text)


def img(key, w, h, alt):
    return '<img src="%s" alt="%s" style="width:%dpx;height:%dpx;object-fit:contain;background:%s;border-radius:12px">' % (IMG[key], alt, w, h, CARD)


def card(inner, border=LINE, flex='1', pad='32px'):
    return ('<div style="flex:%s;display:flex;flex-direction:column;gap:14px;background:%s;padding:%s;border:2px solid %s;border-radius:16px">%s</div>' % (flex, CARD, pad, border, inner))


def bullets(items, size=30):
    return '<ul style="font-size:%dpx;line-height:1.45">%s</ul>' % (size, ''.join('<li>%s</li>' % x for x in items))


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


S = {}
# 1 cover
S['cover'] = sec('cover', '<p style="font-size:30px;font-weight:700;color:%s;letter-spacing:3px">종합설계 · W5 (9/28 ~ 10/4)</p>\n<h1 style="font-size:104px;font-weight:700;line-height:1.1">5주차 진행 보고</h1>\n<p style="font-size:40px;line-height:1.4;color:%s">로봇 액추에이터 관절 모델링 및<br>시뮬레이션 기반 제어 성능 평가</p>\n<p style="font-size:30px;color:%s">채희수 · 이민혁 · 강동하 | 유지원 교수님 미팅</p>' % (ACC, ONDARK, '#BFD0E8'),
                 '이번 주 한 일을 한 사람당 한 페이지씩 정리했습니다. 맨 뒤에 일정 점검과 질문이 있습니다.', bg=DARKBG, color=ONDARK, pad='128px', justify='center')

# 2 feedback
rows = [['지난 피드백 (9/29)', '이번 주 대응', '상태'],
        ['MuJoCo가 어디까지 구현되어 있는지, 어디를 바꿔야 하는지', '외부 Python PMSM을 연결하고 기어·회전자 관성까지 구현해 MATLAB과 일치 확인 (8쪽)', '일부 완료'],
        ['평균 모델만 써도 되는 이유를 설득', '지금 있는 근거와 앞으로 할 비교를 정리 (11쪽). PWM 비교는 아직 안 함', '진행 중'],
        ['액추에이터는 MATLAB, 로봇 시뮬레이션은 방향 미정, MuJoCo 이식을 알아볼 것', '현실 특성 지원 조사(동하)와 연결 방식 정리 (10쪽). 라이브러리·C 코드 변환은 아직 조사 안 함', '진행 중'],
        ['발표자료를 만들고 마지막에 일정 점검', '이 자료. 맨 뒤에 간트차트와 지연 여부 (13쪽)', '완료']]
S['feedback'] = sec('feedback', head('지난 미팅', '지난 피드백에 이번 주 무엇으로 답했나') + '\n' + table(rows, [34, 50, 16], 28) + '\n' + foot(2),
                    '9/29 피드백 네 가지에 대한 이번 주 대응입니다. 완료가 아닌 항목은 상태를 그대로 적었습니다. 라이브러리·C 코드로 변환해 MuJoCo로 옮기는 방법은 아직 조사하지 못했습니다.')

# 3 chain
def box(t, s, col):
    return ('<div style="width:176px;display:flex;flex-direction:column;gap:6px;align-items:center;background:%s;padding:22px 8px;border:3px solid %s;border-radius:14px"><p style="font-size:28px;font-weight:700;text-align:center">%s</p><p style="font-size:24px;color:%s;text-align:center">%s</p></div>' % (CARD, col, t, MUTE, s))
arrow = '<p style="font-size:36px;color:%s">→</p>' % MUTE
chain = [('위치 명령', '스텝', LINE), ('위치 PD', '1 ms', BLUE), ('전류 지령', 'iq*', BLUE), ('전류 PI', '100 µs', BLUE), ('전압 제한', 'Vdc÷√3', BLUE), ('PMSM', 'Tm = Kt·iq', ORANGE), ('기어', '×5', ORANGE), ('관절', 'J, b', GREEN)]
row = '<div style="display:flex;align-items:center;justify-content:space-between">' + arrow.join(box(*c) for c in chain).replace('</div><div', '</div>' + arrow + '<div') + '</div>'
# 위 replace는 이중 삽입을 막기 위해 아래에서 다시 구성
row = '<div style="display:flex;align-items:center;justify-content:space-between">' + ''.join((box(*c) + (arrow if i < len(chain) - 1 else '')) for i, c in enumerate(chain)) + '</div>'
S['chain'] = sec('chain', head('희수 · 개요', '위치 명령에서 관절까지, 액추에이터 체인을 두 환경에 만들었다') + '\n' + row + '\n' +
                 bullets(['<b>1단계</b> 이상 토크 + 위치 PD  →  <b>2단계</b> PMSM · 전류 PI · 평균 인버터  →  <b>3단계</b> 기어비 5, 회전자 관성', '부품을 하나 추가할 때마다 MATLAB과 MuJoCo를 같은 조건으로 돌려 비교했다 (모든 값은 가정값)'], 30) + '\n' + cap('파랑 = 제어기, 주황 = 모터·기어, 초록 = 기계. 되먹임: 관절 각도·속도 → 위치 PD, 모터 속도(= 5 × 관절 속도) → 역기전력 보상') + '\n' + foot(3),
                 '모터는 토크를 전류로 만들고 전류는 전압으로 만듭니다. 그래서 제어도 위치, 전류, 전압 순서로 겹쳐 있습니다. 3단계에서 기어를 넣으면 전류 지령 변환, 모터 속도, 관절 토크 세 곳이 바뀝니다.')

# 4 response
S['response'] = sec('response', head('희수 · 3-2 결과', '두 환경의 응답이 겹치고 차이는 최대 7 µrad') + '\n' + img('response', 1503, 560, '3-2 세 사례에서 MuJoCo와 MATLAB의 관절 각도 응답과 차이') + '\n' + cap('3-2 = 기어비 5 + 회전자 관성. 주황 = MuJoCo, 파랑 점선 = MATLAB, 아래 = 차이 (허용치 1000 µrad)') + '\n' + foot(4),
                    '세 사례(0.3 rad 24 V, 2 rad 24 V, 2 rad 2 V)에서 두 환경 응답이 겹칩니다. 아래 그래프가 MATLAB에서 MuJoCo를 뺀 차이이고 최대 약 7 마이크로라디안입니다.')

# 5 errors
S['errors'] = sec('errors', head('희수 · 단계별 비교', '모든 단계에서 최대 차이가 허용치보다 30배 이상 작다') + '\n' + img('errors', 1664, 560, '단계별 최대 각도 차이와 iq 차이, 허용치와의 비교') + '\n' + cap('각 단계의 최악 사례, 세로축은 로그. 허용치는 잠정 기준(각도 1e-3 rad, iq 0.01 A)이며 하드웨어 정확도 기준이 아니다') + '\n' + foot(5),
                  '1단계부터 3-2까지 최악 사례의 최대 차이입니다. 각도는 허용치의 약 140분의 1, iq는 약 30분의 1입니다. 관절 토크 차이도 허용치 0.015 N·m의 약 30분의 1입니다. 3-3에서 이민혁의 공식 비교 도구로도 전부 통과했습니다.')

# 6 saturation
S['saturation'] = sec('saturation', head('희수 · 2 V 극단 조건', '전압이 모자라 목표에 못 가는 구간도 두 환경이 일치', 52) + '\n' + img('sat', 1664, 580, '2 V 조건의 전압 크기와 iq, 두 환경 비교') + '\n' + cap('3-1, 목표 2 rad. 전압 한계 1.155 V에 0.200~1.728 s 동안 걸려 iq가 지령 2 A에 못 미치고 2초 안에 정착하지 못한다. 포화 플래그 불일치 0행') + '\n' + foot(6),
                      '2 V는 일부러 전압을 모자라게 한 극단 조건입니다. 정착하지 못한 것은 2초 관찰 구간 안의 결과이고 발산을 뜻하지 않습니다.')

# 7 meaning
S['meaning'] = sec('meaning', head('희수 · 의미와 한계', '일치 검증이 말해 주는 것과 말해 주지 않는 것') + '\n<div style="display:flex;gap:32px">' +
                   card('<p style="font-size:34px;font-weight:700;color:%s">확인한 것</p>' % GREEN + bullets(['같은 가정 모델을 두 환경이 같게 계산한다 (1단계~3-3 전부 잠정 기준 통과)', 'MATLAB은 간격을 줄여도 결과가 변하지 않는다 (각도 변화 1.6e-6 rad 이하)', '2 V 전압 포화 구간까지 일치한다'], 28), GREEN) +
                   card('<p style="font-size:34px;font-weight:700;color:%s">말할 수 없는 것</p>' % ORANGE + bullets(['실제 모터에서 이렇게 움직인다는 증명 (모든 값은 가정값)', '어느 시뮬레이터가 더 낫다는 결론', 'PWM · 마찰 · 백래시 · 열 효과 (아직 모델에 없음)'], 28), ORANGE) + '</div>\n' + foot(7),
                   '일치했다는 것은 두 환경 모두 같은 식을 같게 푼다는 확인이고, 선정 근거로 쓰려면 한쪽만 되는 것을 찾아야 합니다. 그 부분이 동하의 현실 특성 조사와 이후 직접 구현 비교입니다.')

# 8 mujoco
rows = [['항목', 'MuJoCo에서 상태', '비고'],
        ['관절 강체 동역학', '구현', '1자유도, 관성·감쇠, implicitfast'],
        ['PMSM 전기 모델', '외부 Python으로 구현', 'MuJoCo 기본 기능이 아님 (RK4)'],
        ['전류 PI · 전압 제한 · 안티윈드업', '외부 Python으로 구현', 'MATLAB과 같은 식'],
        ['기어비 5', '구현', '모터 속도 5배, 관절 토크 5배'],
        ['모터 회전자 관성', '구현', '관절 환산 0.0025 kg·m²'],
        ['마찰 · 백래시', '최소 모델 실험만', '정식 구현은 아직'],
        ['PWM 스위칭 · 열', '미구현', 'PMSM 용도의 기본 기능 없음 (문서 기준)']]
S['mujoco'] = sec('mujoco', head('민혁 · MuJoCo 구현', 'MuJoCo에서 지금 구현된 것과 아직 없는 것') + '\n' + table(rows, [34, 28, 38], 28) + '\n' + foot(8),
                  '민혁 발표 페이지입니다. 이 표는 민혁의 자료와 우리 실험을 기준으로 정리한 초안이므로 민혁이 확인하고 고쳐 주세요. 마찰·백래시는 확장 실험에서 최소 모델을 시도한 수준입니다.')

# 9 pmsm
S['pmsm'] = sec('pmsm', head('동하 · PMSM + FOC', 'Simscape로 만든 FOC 전류 제어 모델 검증') + '\n<div style="display:flex;gap:40px;align-items:stretch">' +
                '<div style="flex:1;display:flex;flex-direction:column;gap:20px">' + bullets(['3상 전압원, 전류·토크·각속도 센서, Clarke → Park → 역변환', 'd·q 전류 PI, 전압 ±12 V 제한, 안티윈드업', '시험: Id* = 0, Iq* = 1 A (0.02 s 스텝)'], 28) +
                '<p style="font-size:30px;font-weight:700;color:%s">결과</p>' % BLUE + bullets(['Id ≈ 0 유지, Iq 1 A 추종, 전압 포화 없음', '축 토크 0.10~0.13 N·m, 0.1 s에 약 0.93 rad/s', '후반 Iq가 0.85~0.9 A로 약간 낮아져 PI 튜닝 예정'], 28) + '</div>' +
                '<div style="width:640px;display:flex;align-items:center;justify-content:center;border:3px dashed %s;border-radius:16px;padding:32px"><p style="font-size:28px;line-height:1.5;color:%s;text-align:center">[Scope 화면 캡처 자리]<br>Id, Iq, Vd, Vq, 토크, 속도<br>(동하가 추가)</p></div></div>\n' % (LINE, MUTE) + foot(9),
                '동하 발표 페이지입니다. 수치는 동하의 W5 기록 기준입니다. 오른쪽에는 Simulink Scope 화면을 직접 캡처해 넣어 주세요. 이 모델은 평균 전압 모델이며 PWM 스위칭 소자는 없습니다.')

# 10 survey
rows = [['현실 특성', 'Simulink + Simscape', 'MuJoCo', '판단'],
        ['PWM · 인버터', '5 (블록 제공)', '1 (외부 코드)', 'Simulink'],
        ['PMSM + FOC', '5', '2', 'Simulink'],
        ['열 · 온도', '4 (열 네트워크 구성 필요)', '2', 'Simulink'],
        ['마찰', '5', '4', '둘 다 쉬움'],
        ['백래시', '5 (블록 하나)', '3 (이중 hinge)', 'Simulink가 빠름'],
        ['기어 · 반사 관성', '4', '5', 'MuJoCo'],
        ['접촉 · 중력 · 외란', '4', '5', 'MuJoCo']]
S['survey'] = sec('survey', head('동하 · 현실 특성 조사', '전기·열은 Simulink가, 관절·접촉은 MuJoCo가 쉽다 (문서 기준)', 54) + '\n' + table(rows, [24, 30, 24, 22], 28) + '\n' + cap('5 = 파라미터 입력만, 1 = 외부 코드 전부. 문서 확인 수준이며 마찰·백래시·열·접촉은 직접 구현해 측정하기 전. 출처: 공식 문서 11건') + '\n' + foot(10),
                  '동하가 공식 문서 기준으로 조사한 표입니다. 보완 과정에서 열 점수를 5에서 4로 고쳤고, 점수 기준표와 출처 URL을 붙였습니다. 아직 한 번도 직접 구현해 측정하지 않은 항목이 있다는 점을 같이 말씀드립니다. MATLAB에서 MuJoCo로 옮기는 방법과 기존 시뮬레이터 후보(Isaac Lab, Modelica, Drake)는 1차 정리만 했습니다.')

# 11 average
S['average'] = sec('average', head('교수님 질문 · 평균 모델', '평균 인버터 모델로 충분한 이유, 지금 있는 근거와 앞으로 할 것', 52) + '\n<div style="display:flex;gap:32px">' +
                   card('<p style="font-size:34px;font-weight:700;color:%s">지금 있는 근거</p>' % GREEN + bullets(['목적이 제어 성능 비교라서 PWM 스위칭 파형은 별도 사례로 두는 구성을 택함 (동하 조사)', '전압 한계 Vdc÷√3와 포화 거동까지 모델에 넣었고 두 환경이 일치', '평균 모델에 없는 것을 명시: 스위칭 리플, 데드타임, 스위치 손실, 보호'], 28), GREEN) +
                   card('<p style="font-size:34px;font-weight:700;color:%s">아직 없는 것과 계획</p>' % ORANGE + bullets(['평균 모델과 PWM 모델의 응답 차이는 아직 측정 안 함', '계획: Simscape에서 PWM 스위칭 사례를 같은 시험(0.3 rad, 24 V)으로 돌려 차이를 비교', '차이가 작으면 "충분하다"의 근거, 크면 원인을 정리'], 28), ORANGE) + '</div>\n' + foot(11),
                   '교수님이 "평균 모델만 쓸 수 있는 이유를 설득하라"고 하셨습니다. 지금은 설득할 만한 직접 비교가 없고, PWM 스위칭 모델을 Simscape에서 같은 조건으로 돌려 비교하는 것이 다음 단계입니다. 어느 수준까지 보여야 충분한지는 질문에 넣었습니다.')

# 12 task
S['task'] = sec('task', head('태스크', 'Pick-and-Place에서 질량 변화에 대응하는 목표 지점 던지기로', 52) + '\n<div style="display:flex;gap:32px">' +
                card('<p style="font-size:34px;font-weight:700;color:%s">정해진 것 (거의 확정)</p>' % GREEN + bullets(['방향: 질량이 바뀌어도 목표 지점에 던지기', '이유: Pick-and-Place는 단순하고 검증 난이도가 낮다는 지적', '연구 후 태스크를 발전시킬 수 있음'], 28), GREEN) +
                card('<p style="font-size:34px;font-weight:700;color:%s">아직 정하지 않은 것</p>' % ORANGE + bullets(['질량 범위, 목표 거리, 착지 오차 허용치', '릴리스(물체가 손을 떠나는) 조건', '평가지표 (착지 오차, 질량 변화 강건성 등 후보)', '비행·착지를 시뮬레이터 안에서 계산할지'], 28), ORANGE) + '</div>\n' + foot(12),
                '태스크는 던지기로 거의 정했고 세부는 미정입니다. 던지기는 순간 토크와 속도가 커서 전류·전압 포화와 반사 관성 영향이 커지므로, 이번에 확인한 2 V 포화 일치가 기반 증거가 됩니다.')

# 13 gantt
S['gantt'] = sec('gantt', head('일정 점검', '지연 1건: 간트 확정(팀 합의 대기). 나머지는 진행 중', 54) + '\n' + img('gantt', 1479, 658, '이번 주부터 W9까지 간트차트와 진행률') + '\n' + foot(13),
                 '지난 주 마감 항목 중 간트차트 확정만 팀 합의가 남아 있어 지연으로 셉니다. 담당과 진행률은 현재 기록 기준의 제안이고 팀 합의 전입니다. 전체 30개 일(W5~W18)은 RAMS 간트차트에 있습니다.')

# 14 questions
qs = ['기존 시뮬레이터 조사는 MATLAB·MuJoCo 외에 몇 개, 어떤 기준이면 충분한가요? (지금 Isaac Lab, Modelica, Drake를 1차 정리)',
      '던지기 요구사항(질량 범위, 목표 거리, 착지 오차)은 어떤 기준으로 정할까요? 물체 비행 구간은 시뮬레이터 안에서 계산해도 되나요?',
      '시뮬레이터 선정을 W7로 미루고 그때까지 MATLAB 우선, MuJoCo 보조로 가도 될까요?',
      '평균 인버터 모델이 충분하다고 설명하려면 PWM 비교를 어느 수준까지 보여야 하나요?',
      '전기부는 Simulink, 기계부는 MuJoCo로 나누는 구성에서 연결 비용을 어떻게 보시나요? (양방향 연동은 아직 미검증)',
      '다음 우선순위: 현실 특성 직접 구현, 시뮬레이터 비교 조사, 던지기 요구사항 정의 중 무엇을 먼저 할까요?']
S['questions'] = sec('questions', head('질문', '교수님께 드리는 질문') + '\n<ol style="font-size:30px;line-height:1.45">' + ''.join('<li>%s</li>' % q for q in qs) + '</ol>\n' + foot(14),
                     '질문 여섯 개입니다. 1번과 4번은 지난 피드백에 대한 후속이고, 2번과 3번은 태스크와 선정 시점에 관한 질문입니다.')

for k in order:
    open(os.path.join(ROOT, 'project', 'slides', k + '.html'), 'w', encoding='utf-8').write(S[k])
deck = {"v": 4, "createdOnFiles": {"v": 1, "at": datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')}, "lists": "css", "title": "5주차 진행 보고", "order": order,
        "sections": {"s1": {"description": "지난 피드백과 이번 주 대응", "start": "cover"}, "s2": {"description": "희수: 두 환경 일치 검증", "start": "chain"},
                     "s3": {"description": "민혁: MuJoCo 구현 현황", "start": "mujoco"}, "s4": {"description": "동하: PMSM+FOC와 현실 특성 조사", "start": "pmsm"},
                     "s5": {"description": "평균 모델, 태스크, 일정, 질문", "start": "average"}},
        "faces": {"noto-sans-kr": {"family": "Noto Sans KR", "href": "https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap"}}}
json.dump(deck, open(os.path.join(ROOT, 'project', 'deck.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print(len(order), 'ok')
