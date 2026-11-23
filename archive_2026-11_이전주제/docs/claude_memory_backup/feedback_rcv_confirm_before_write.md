---
name: feedback-rcv-confirm-before-write
description: RCV 연구노트(research-note MCP)는 쓰기 전에 항상 채희수 님께 본문을 보여주고 승인받는다. RAMS 작업실은 맡긴 범위에서 확인 없이 가능
metadata:
  node_type: memory
  type: feedback
  originSessionId: edb736f6-0281-455c-9f8d-74587459bbc9
  modified: 2026-10-04T05:09:56.164Z
---

RCV(research-note MCP, 교수님이 보는 종합설계 연구노트)에 쓰는 모든 작업(log_progress, add_task, update_task, update_stage, advance_stage, update_entry, add_comment, set_review)은 먼저 최종 본문을 보여주고 사용자의 명시적 승인("올려") 후에만 호출한다. 읽기(whoami, get_project, list_notices)는 확인 없이 가능.

**Why:** 교수님이 직접 보고 평가하는 기록이라 잘못 올라가면 되돌리기 어렵다. 사용자가 2026-10-04에 "RCV는 작업하기 전에 항상 확인받아야 돼"라고 명시했다. RAMS 작업실(팀 artifact)은 교수님이 안 보므로 맡긴 범위에서는 확인 없이 기록해도 된다고 함.

**How to apply:** 승인은 작업별로 새로 받는다(이전 승인 연장 금지). 본문에는 가정값·잠정 기준·못 한 것을 적고 CLAUDE.md 3장 미확정 항목을 확정처럼 쓰지 않는다. AI 활용 여부 문구는 사용자가 정하게 한다. 규칙은 D:\Capstone_design\CLAUDE.md 8장에 기록됨. 관련: [[rams-workspace-artifact]]
