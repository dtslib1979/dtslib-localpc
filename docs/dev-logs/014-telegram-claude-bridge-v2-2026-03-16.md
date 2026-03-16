# Dev Log 014 — Telegram Claude Bridge v2.0 완성

**날짜**: 2026-03-16  
**작업자**: dtsli + Claude Code (claude-sonnet-4-6)  
**연관 레포**: parksy-image · parksy-audio · dtslib-localpc · dtslib-papyrus

---

## 배경

유레카 문서(011) 이후 PC-native 패러다임 전환 완료.  
폰 → SSH클라이언트, PC → 메인 실행엔진.  
이 구조에서 "폰으로 Claude Code를 자연어로 조종"하는 텔레그램 브릿지가 핵심 인터페이스.

---

## 목표

기존 v1 봇의 문제 해결 + 유행 프로젝트 리서치 후 베스트 믹스 구현.

### v1 문제점
- 두 봇이 같은 토큰 사용 (충돌)
- 스트리밍 없음 (완료 후 한 번에 전송)
- 세션 없음 (대화 이어가기 불가)
- threading 구조 (구식)
- `--output-format stream-json` 에 `--verbose` 누락 → Claude 무응답

---

## 리서치 결과

GitHub 인기 프로젝트 7개 분석:

| 프로젝트 | 방식 | 스타 |
|---|---|---|
| RichardAtCT/claude-code-telegram | Python SDK + DraftStreamer + SQLite | 2.1k |
| linuz90/claude-telegram-bot | TS Bun + for await SDK | - |
| hanxiao/claudecode-telegram | tmux send-keys inject | 565 |

**결론**: SDK 방식이 베스트. 단 우리는 Claude Max 요금제(API키 없음)라  
`claude -p --output-format stream-json --verbose` CLI 방식 유지 + 좋은 것만 믹스.

### 가져온 것
- **DraftStreamer 패턴** (RichardAtCT): 같은 메시지를 실시간 편집
- **asyncio 전체** (linuz90): threading 제거
- **SQLite 세션** (RichardAtCT): (chat_id, workdir) → session_id 저장
- **CLAUDE.md 자동 주입**: 워크디렉 컨텍스트 자동 로딩

---

## 구현 결과

### 파일 구조
```
/mnt/d/PARKSY/dtslib-localpc/telegram-bots/
  core.py          ← 공유 엔진 (SessionDB + DraftStreamer + AsyncStreamClaude + AccessControl)
  sessions.db      ← SQLite 자동 생성

/mnt/d/parksy-image/tools/telegram-bridge/
  bot.py           ← @parksy_bridge_bot v2.1
  config.json      ← 토큰 + admin_id + slots[3]

/mnt/d/PARKSY/parksy-audio/local-agent/
  bot.py           ← @parksy_bridges_bot v2.1
  telegram_config.json ← 토큰 + admin_id + slots[3]

/mnt/d/PARKSY/dtslib-localpc/scripts/
  start-bots.sh    ← tmux tg-image + tg-audio 일괄 런처
```

### 봇 2개 (확정)

| 봇 | @유저네임 | tmux | 워크디렉 |
|---|---|---|---|
| Parksy Bridge | @parksy_bridge_bot | tg-image | /mnt/d/parksy-image |
| Parksy Bridges | @parksy_bridges_bot | tg-audio | /mnt/d/PARKSY/parksy-audio |

### 권한 구조 (슬롯 시스템)
```
ADMIN (나)   → 자연어 명령 + 파일 드랍 + 모든 명령어
SLOT 1~3    → 파일 드랍만 (이미지/문서/오디오) → 자동 처리
NONE        → 차단
```

슬롯 관리 명령어:
- `/addslot USER_ID 이름` — 슬롯 추가
- `/rmslot USER_ID` — 슬롯 제거
- `/slots` — 현황

상대방 chat_id 확인: 봇에서 `/start` 치면 자동 표시.

---

## 버그 수정 내역

### Bug 1: Claude 무응답
```bash
# 원인: --verbose 누락
claude -p "..." --output-format stream-json          # ERROR
claude -p "..." --output-format stream-json --verbose # OK
```

### Bug 2: editMessageText 400 Bad Request
```
원인 1: parse_mode="Markdown" → Claude 출력 특수문자 파싱 실패
원인 2: 내용 동일한 메시지 반복 편집 → "message is not modified"
fix: parse_mode=None + 내용 변경 시에만 edit
```

### Bug 3: 두 봇 토큰 충돌
```
parksy-image: 7634493765:... (@parksy_bridge_bot)
parksy-audio: 8669426963:... (@parksy_bridges_bot) ← 수정
```

---

## 기술 스택

- Python 3.12 + asyncio
- python-telegram-bot 22.7
- aiosqlite 0.22.1
- claude CLI 2.1.76 (claude-sonnet-4-6)
- tmux (tg-image / tg-audio 세션)
- WSL2 Ubuntu on Windows

---

## 과금 구조

```
Claude Max ($100/월)
→ claude -p CLI 무제한
→ API Key 없음, 별도 청구 없음
→ 텔레그램 봇 실행 추가 비용 없음
```

유행 프로젝트들은 ANTHROPIC_API_KEY 방식 (토큰당 과금).  
우리는 CLI OAuth 방식 — 요금제 안에서 운영.

---

## 다음 과제

- [ ] 슬롯 3개 실제 유저 등록 (어머니 등)
- [ ] 그룹 채팅 테스트 (여러 명 동시 파일 드랍)
- [ ] 오퍼스 모델 전환 옵션 검토 (`--model claude-opus-4-6`)
- [ ] watchdog 연동 (봇 크래시 시 자동 재시작)
