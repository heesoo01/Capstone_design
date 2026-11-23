---
name: rams-workspace-artifact
description: 팀 사이트 RAMS 작업실 artifact의 URL과 DB 구조 (주간 기록·간트·결정 기록)
metadata:
  node_type: memory
  type: reference
  originSessionId: edb736f6-0281-455c-9f8d-74587459bbc9
  modified: 2026-10-04T05:10:01.894Z
---

RAMS 작업실: https://claude.ai/artifact/Ln2tu72aJVKTqKoZ7XUj9e (채희수 소유, 단일 HTML + artifact DB).
DB 컬렉션: `entries`(문서 id `w{주차}_{hee|min|dong}`, 필드 plan/done/result/blockers/next/memo/progress/by/updated), `gantt`(작업 id별 owners/progress, 현재 비어 있음), `prof`, `talks`, `decisions`(id 예 d20261004a, 필드 date/title/reason/by/updated).
쓰기는 ArtifactData batch/update에 if_version 필요. 이민혁 칸(w5_min)은 희수 이름(by:hee)으로 대신 작성된 것이라 본인 확인이 필요하다. 교수님은 RAMS를 보지 않는다 (RCV는 별도, [[feedback-rcv-confirm-before-write]]).
