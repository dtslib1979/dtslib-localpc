# Claude Desktop → Claude Code CLI 전환 체크리스트

> GUI 파편화 문제 해결. 하나의 터미널에서 전부 제어.
> 최종 업데이트: 2026-03-12

---

## 왜 전환하는가

| 문제 | Claude Desktop (GUI) | Claude Code CLI |
|------|---------------------|-----------------|
| 레포 접근 | 1개만 선택 | D: 전체 광역 접근 |
| 로컬 PC 제어 | 불가 | 파일 CRUD + Python + 배치 |
| MCP 연결 | Desktop 앱 종속 | CLI에서 직접 연결 |
| 브라우저 자동화 | Claude in Chrome (별도) | Puppeteer MCP (통합) |
| 원격 접속 | RustDesk (끊김) | SSH+tmux (세션 유지) |
| 동시 작업 | 창 1개 | tmux 멀티 세션 |

---

## 전환 체크리스트

### Phase 1: CLI 설치 (3분)

- [ ] Node.js 22+ 확인: `node --version`
- [ ] Claude Code CLI 설치: `npm install -g @anthropic-ai/claude-code`
- [ ] 실행 확인: `claude --version`
- [ ] PowerShell에서 `claude` 실행 → 자연어 대화 가능 확인

### Phase 2: MCP 서버 연결 (5분)

- [ ] Puppeteer MCP 추가:
  ```bash
  claude mcp add puppeteer -- npx -y puppeteer-mcp-claude serve
  ```
- [ ] GitHub MCP 추가:
  ```bash
  claude mcp add github -- npx -y @modelcontextprotocol/server-github
  ```
- [ ] Filesystem MCP 추가:
  ```bash
  claude mcp add filesystem -- npx -y @anthropic-ai/mcp-filesystem
  ```
- [ ] MCP 연결 확인: `claude` → `/mcp`

### Phase 3: SSH 서버 설정 (5분)

> 상세: `env/SSH_SETUP.md`

- [ ] OpenSSH 서버 설치
- [ ] sshd 서비스 시작 + 자동시작
- [ ] 방화벽 규칙 추가
- [ ] 폰 Termux에서 SSH 접속 테스트

### Phase 4: tmux 멀티 세션 (2분)

- [ ] WSL Ubuntu에서 tmux 설치
- [ ] tmux 기본 조작 확인 (new, detach, attach)
- [ ] 멀티 창 테스트 (claude 2개 + 배치 1개)

### Phase 5: WSL + Telegram Bot (25분)

- [ ] WSL Ubuntu 설치 (미설치 시)
- [ ] `/mnt/d/` 경로로 D: 드라이브 접근 확인
- [ ] Telegram Bot 토큰 발급 (@BotFather)
- [ ] Bot 데몬 스크립트 작성
- [ ] 파일 송수신 테스트

### Phase 6: 검증 (20분)

- [ ] 폰 SSH → PC tmux → Claude Code 실행 → 코드 작업 성공
- [ ] Puppeteer MCP로 브라우저 자동화 동작 확인
- [ ] tmux detach → SSH 재접속 → tmux attach → 세션 유지 확인
- [ ] Telegram Bot 파일 전송 확인

---

## 전환 후 도구 역할 정리

| 도구 | 역할 | 사용 빈도 |
|------|------|----------|
| PowerShell + Claude Code CLI | 메인 작업 환경 | 매일 |
| SSH + tmux | 원격 접속 + 세션 유지 | 외출 시 |
| Puppeteer MCP | 브라우저 자동화 | 필요 시 |
| Telegram Bot | 대용량 파일 전송 | 필요 시 |
| Claude Desktop | MCP 가끔 사용 또는 **폐기** | 거의 안 씀 |
| RustDesk | GUI 확인 필요 시만 | 가끔 |
| Claude in Chrome | **불필요** (Puppeteer MCP로 대체) | 안 씀 |

---

## Claude Desktop 처리

전환 완료 후 Claude Desktop은:
- **삭제해도 됨** — CLI에서 MCP 전부 가능
- **남겨놔도 됨** — 간단한 채팅용으로 가끔 사용
- Desktop 전용 기능이 필요한 경우는 거의 없음

---

*출처: docs/INFRA_WHITEPAPER.md에서 추출*
*작성: 2026-03-12*
