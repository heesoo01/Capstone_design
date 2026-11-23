# STATUS

Claude Code와 채팅이 같이 쓰는 진행 상황 파일이다. 맨 위가 최신이다. 항목 앞에 `[Code]` 또는 `[채팅]`을 붙인다.
이전 주제의 STATUS(2026-10-12까지)는 `archive_2026-11_이전주제/STATUS_old.md`에 있다.

## 지금 상태 요약 (2026-11-23)
- 주제: PMSM 액추에이터를 직접 구현해 Kinova Gen3 관절에 넣고, 이상 토크와 던지기 성능을 비교한다 (CLAUDE.md 1장).
- 팀 진행(민혁 저장소, 11/21 기준, 문서 확인): 단계 1 완료, 단계 2 틀 완료(동하가 다듬는 중), 단계 3 슬롯·페이로드·Jr 옵션 완료, 액추에이터 꽂기와 던지기는 아직.
- 이 PC에서 실행해 확인한 것: 없음.

## 열린 질문 (사용자 확인 필요)
- 희수의 담당 범위
- 과목 담당(심인욱)과 피드백 주신 분(유지원) 표기
- 현재 주차와 남은 발표 일정
- `baseline_input_decel.mat`, Gen3 모델 실행 파일 공유 여부 (단계 3·4 재실행에 필요)
- `SME_Capstone/`을 git clone으로 바꿀지 (지금은 aadfae2 사본)

## 작업 로그

### 2026-11-23 [채팅] 주제 변경에 맞춰 폴더·지침 재구성
- 한 일:
  - 민혁 GitHub 저장소(aadfae2)를 `SME_Capstone/`으로 복사했다 (.git은 원격 도구로 쓸 수 없어 제외).
  - 동하용 안내 PDF 2개를 `docs/team_notes/`에 넣었다.
  - 이전 주제 자료(week5, week6, 중간발표, 제안발표 pptx, 간트, 옛 문서)를 `archive_2026-11_이전주제/`로 옮겼다. 삭제는 하지 않았다. 옛 CLAUDE.md, STATUS.md는 `CLAUDE_old.md`, `STATUS_old.md`로 보관했다.
  - CLAUDE.md를 새 주제로 다시 썼다. 민혁 작업 설명 `docs/민혁_작업_정리.md`를 작성했다.
  - `.gitignore`에 `SME_Capstone/`을 추가했다 (팀 저장소는 GitHub에서 관리).
- 결과: 위 파일들. 실행·수치 생성은 없다.
- 막힌 점: 이 PC 작업 환경에서는 GitHub에 접속할 수 없어 git clone을 못 했다.
- 다음: 희수 담당 정하기 → 단계 2 결과 이 PC에서 재현(`stage2_actuator`의 build/test 실행, MATLAB R2026a 호환 확인).
