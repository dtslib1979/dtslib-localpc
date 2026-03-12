# PARKSY INFRASTRUCTURE WHITEPAPER v1.0

**PC 원격 제어 + CLI 통합 + 24시간 배치 자동화**
비개발자의 프로덕션 환경 구축 솔루션

EduArt Engineer | 박씨 (Park) | 2026년 3월
parksy.kr | eae.kr | dtslib.com

---

## Executive Summary

본 백서는 비개발자 Park이 3년간 AI 협업을 통해 구축한 개발/운영 인프라의 문제점을 분석하고, Claude Code CLI 기반의 통합 솔루션을 제시한다.

**핵심 과제:** 12시간 육체노동 중에도 집 PC에서 배치 작업을 돌리고, 모바일에서 원격으로 모든 작업을 제어할 수 있는 단일 에이전트 환경 구축.

> **결론:** Claude Desktop(GUI)을 Claude Code CLI로 전환하면, SSH+tmux 원격 제어, MCP 브라우저 자동화, 멀티 세션 배치 작업이 하나의 터미널에서 모두 가능하다. RustDesk 의존도 80% 감소, 세션 유실 문제 해결.

---

## 1. 문제 분석: 기존 환경의 한계

### 1.1 도구 파편화

| 도구 | 역할 | 한계 |
|------|------|------|
| Claude Desktop (Chat) | 일반 대화 | 파일시스템 직접 접근 불가 |
| Claude Desktop (Code) | 코드 작업 | GitHub 레포 1개만 선택 가능 |
| Claude Desktop (Cowork) | 파일 자동화 | 베타, 로컬 접근 제한적 |
| Claude in Chrome | 브라우저 GUI 자동화 | PC Chrome에서만 실행 |
| RustDesk | 원격 데스크톱 | LTE에서 세션 끊김 빈발 |
| MCP (Desktop 내) | 외부 서비스 연결 | Desktop 앱에 종속 |

### 1.2 핵심 문제 4가지

- **문제 1 — 광역 레포 접근 불가:** Code 탭은 레포 1개만 선택. 28개+ 레포 운용에 부적합.
- **문제 2 — 로컬 PC 제어 불가:** D: 드라이브 접근, Python 실행, 배치 작업 불가능.
- **문제 3 — 원격 세션 불안정:** RustDesk는 화면 스트리밍이라 LTE에서 끊기면 세션 유실.
- **문제 4 — 브라우저 자동화 분리:** Claude in Chrome과 Claude Code가 연결 안 됨.

### 1.3 근본 원인

Anthropic 제품 구조가 파편화. Claude Desktop, Claude Code CLI, Claude in Chrome이 각각 별개 제품. 하나의 에이전트에서 통합 제어하는 구조가 아님. Park이 직접 우회해야 함.

---

## 2. 솔루션: Claude Code CLI 통합 아키텍처

### 2.1 핵심 전환

> **패러다임:** Claude Desktop (GUI) → Claude Code CLI (터미널)로 메인 환경 전환. CLI에서 MCP를 직접 연결하면 Desktop 없이도 광역 파일 접근 + 브라우저 자동화 + 외부 서비스 연동이 하나의 터미널에서 가능.

### 2.2 Before vs After

| 항목 | Before (현재) | After (전환 후) |
|------|-------------|----------------|
| 메인 인터페이스 | Claude Desktop GUI | PowerShell + Claude Code CLI |
| 레포 접근 | 1개만 선택 | D: 드라이브 전체 광역 접근 |
| 로컬 PC 제어 | 불가 | 파일 CRUD + Python + 배치 실행 |
| MCP 연결 | Desktop 앱 종속 | CLI에서 직접 연결 |
| 브라우저 자동화 | Claude in Chrome (별도) | Puppeteer MCP (CLI 내 통합) |
| 원격 접속 | RustDesk (영상 스트리밍) | SSH + tmux (텍스트 기반) |
| 세션 안정성 | LTE 끊기면 세션 유실 | 끊겨도 tmux 세션 유지 |
| 동시 작업 | 창 하나 | tmux 멀티 세션 (3개+) |
| 데이터 사용량 | 높음 (화면 스트리밍) | 극소 (텍스트만) |

---

## 3. 시스템 아키텍처

### 3.1 전체 구조 (4 Layer)

```
┌──────────────────────────────────────────────┐
│  LAYER 1: MOBILE (Samsung Galaxy Phone)      │
│  Termux + Claude Code (Local)                │
│  ├─ SSH → PC 원격 제어                        │
│  ├─ Telegram Bot → 파일 송수신                │
│  └─ 음성입력 → STT → Claude Code              │
├──────────────────────────────────────────────┤
│  LAYER 2: PC — Windows (24시간 ON)            │
│  PowerShell + Claude Code CLI                │
│  ├─ MCP: Puppeteer (Browser Automation)      │
│  ├─ MCP: GitHub, Filesystem, etc.            │
│  ├─ D: Drive 광역 파일 접근                    │
│  └─ SSH Server + tmux (원격 접속 대기)        │
├──────────────────────────────────────────────┤
│  LAYER 3: WSL (Ubuntu) — 서버 환경            │
│  ├─ Telegram Bot Daemon (24시간 상주)         │
│  ├─ Cron 배치 작업                            │
│  └─ /mnt/d/ → Windows D: 드라이브 공유        │
├──────────────────────────────────────────────┤
│  LAYER 4: CLOUD                              │
│  ├─ GitHub (28+ repos, Actions CI/CD)        │
│  ├─ YouTube (CDN / 콘텐츠 배포)               │
│  └─ Vercel (PWA 배포)                        │
└──────────────────────────────────────────────┘
```

### 3.2 도구별 역할

| 도구 | 역할 | 실행 환경 |
|------|------|----------|
| Claude Code CLI | 코드/파일/배치, MCP 통합 | PC PowerShell |
| SSH + tmux | 원격 접속 + 세션 유지 | 폰 Termux → PC |
| Puppeteer MCP | 브라우저 자동화 | CLI 내 MCP 서버 |
| Telegram Bot | 대용량 파일 송수신 | WSL 데몬 |
| WSL Ubuntu | 서버 프로세스 상주 | PC 내 리눅스 |
| RustDesk | GUI 확인 필요 시만 | 태블릿 → PC |
| GitHub Actions | APK 빌드, CI/CD | GitHub 클라우드 |

---

## 4. 구현 가이드

### Phase 1: Claude Code CLI 설치 (3분)

```bash
# Node.js 확인 (18+ 필요)
node --version

# Claude Code CLI 설치
npm install -g @anthropic-ai/claude-code

# 실행
claude
```

PowerShell에서 `claude` 실행 = Termux에서 하던 것과 완전히 동일한 CLI 환경.

### Phase 2: MCP 서버 연결 (5분)

```bash
# Puppeteer (브라우저 자동화)
claude mcp add puppeteer -- npx -y puppeteer-mcp-claude serve

# GitHub
claude mcp add github -- npx -y @modelcontextprotocol/server-github

# Filesystem
claude mcp add filesystem -- npx -y @anthropic-ai/mcp-filesystem

# 연결 확인
claude
> /mcp
```

> 이제 하나의 CLI 세션에서 "YouTube Studio 열어서 업로드해"가 가능. Claude Desktop + Claude in Chrome 모두 불필요.

### Phase 3: SSH 서버 설정 (5분, 직접 1회)

```powershell
# PowerShell (관리자 권한)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# 방화벽 규칙
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' `
  -Enabled True -Direction Inbound -Protocol TCP `
  -Action Allow -LocalPort 22
```

```bash
# 폰 Termux에서 접속 테스트
ssh park@192.168.x.x
claude    # PC의 Claude Code가 폰에서 실행됨
```

### Phase 4: tmux 멀티 세션 (2분)

```bash
# 새 세션 시작
tmux new -s work

# 창 관리
Ctrl+b c     # 새 창
Ctrl+b 0~9   # 창 전환
Ctrl+b d     # 세션 분리 (detach)

# 재접속 (끊겨도 세션 유지)
tmux attach -t work
```

**Park 워크플로우:**
```
tmux 창 0: cd D:\repos\nodedash && claude
tmux 창 1: cd D:\repos\parksy-audio && claude
tmux 창 2: python D:\scripts\batch_render.py
```

> SSH 끊겨도 tmux 세션은 PC에서 계속 실행. 배치 중이면 끊긴 동안에도 진행됨.

### Phase 5: WSL + Telegram Bot (25분)

**역할 분리:**

| 환경 | 역할 | 특징 |
|------|------|------|
| Windows PowerShell | Claude Code CLI 메인 작업 | D: 드라이브 직접 접근 |
| WSL Ubuntu | Telegram Bot, Cron 데몬 | 24시간 안정 상주 |

```bash
# WSL에서 Windows D: 드라이브 접근
ls /mnt/d/repos/

# 파일 공유
cp /mnt/d/output/video.mp4 ~/telegram-send/
```

**파일 전송 채널 분리:**

| 채널 | 용도 | 파일 크기 제한 |
|------|------|--------------|
| GitHub | 코드/설정 동기화 | 100MB |
| Telegram Bot | 콘텐츠 파일 송수신 | 2GB |
| YouTube | 완성본 CDN 배포 | 256GB |

---

## 5. 작업 시나리오

### A: 외출 중 배치 작업 지시

```
박씨 (식당 근무 중, 폰)
  ├─ Termux → ssh park@집PC
  ├─ tmux attach -t work
  ├─ 창 2: claude "parksy-audio MIDI 렌더링 배치 돌려"
  ├─ claude가 Python 스크립트 실행
  └─ 접속 끊고 다시 근무 (배치는 PC에서 계속 진행)
```

### B: 브라우저 자동화

```
박씨 (집 PC 앞)
  ├─ PowerShell → claude
  ├─ "YouTube Studio 열어서 영상 3개 업로드해"
  ├─ Puppeteer MCP → Chrome 실행 → 자동 업로드
  ├─ "티스토리 블로그에 새 글 발행해"
  └─ Puppeteer MCP → 티스토리 접속 → 자동 발행
```

### C: 대용량 파일 전송

```
박씨 (폰에서 콘텐츠 제작 완료)
  ├─ Telegram Bot으로 파일 전송
  ├─ PC WSL Bot이 수신 → /mnt/d/content/ 저장
  ├─ Claude Code가 후처리 (변환/렌더링)
  └─ 완성본 YouTube 업로드 (스크립트 자동화)
```

### D: 멀티 레포 동시 작업

```
박씨 (폰 SSH 접속)
  ├─ tmux 창 0: claude (nodedash 작업)
  ├─ tmux 창 1: claude (parksy-image 작업)
  ├─ tmux 창 2: claude (parksy-audio 배치)
  ├─ tmux 창 3: python batch.py
  └─ Ctrl+b 0~3으로 창 전환하며 작업
```

---

## 6. RustDesk 잔존 역할

완전 제거 아님. GUI 필요 시 사용.

| 작업 유형 | 도구 | 이유 |
|----------|------|------|
| 코드/배치/파일 | SSH + Claude Code | CLI로 완결 |
| 브라우저 자동화 | Puppeteer MCP (CLI) | headless 가능 |
| APK UI 테스트 | RustDesk (태블릿) | 실제 화면 필요 |
| 디자인 확인 | RustDesk (태블릿) | 시각적 검증 필요 |

**작업 비율:** SSH+CLI 80%, RustDesk GUI 20%. 기존 대비 RustDesk 의존도 80%+ 감소.

---

## 7. 비용 분석

| 항목 | 비용 | 비고 |
|------|------|------|
| Claude Code CLI | 무료 | Max 구독 포함 |
| SSH (OpenSSH) | 무료 | Windows 내장 |
| tmux | 무료 | 오픈소스 |
| WSL Ubuntu | 무료 | Windows 내장 |
| Telegram Bot API | 무료 | 2GB 전송 |
| PC 24시간 전기세 | 월 1~2만원 | 노트북 기준 |
| 클라우드 서버 | 불필요 | 월 5~10만원 절약 |

> **총 추가 비용: 0원.** 기존 하드웨어 + 기존 구독으로 충분. 전기세만 월 1~2만원.

---

## 8. 하드웨어 요구사항

현재 노트북으로 충분.

| 작업 | PC 부하 | 이유 |
|------|--------|------|
| Claude Code 실행 | 극소 | API 호출, 로컬 연산 없음 |
| GitHub Actions | 없음 | GitHub 서버에서 실행 |
| Python 자동화 | 낮음 | 경량 스크립트 |
| MIDI→Audio 렌더링 | 중간 | SoundFont, 노트북 충분 |
| Puppeteer | 중간 | Chrome 1~2개 |
| SSH + WSL + Bot | 극소 | 텍스트/경량 데몬 |

워크스테이션/클라우드 불필요. 24시간 가동 시 발열 관리만 고려.

---

## 9. 구현 우선순위

| 단계 | 작업 | 소요시간 | 직접/자동 |
|------|------|---------|----------|
| 1 | PC OpenSSH 서버 활성화 | 5분 | 직접 (1회) |
| 2 | Claude Code CLI 설치 | 3분 | 직접 (1회) |
| 3 | MCP 서버 추가 | 5분 | Claude Code 실행 |
| 4 | tmux 설치 | 2분 | Claude Code 실행 |
| 5 | WSL Ubuntu 설치 | 10분 | 직접 (1회) |
| 6 | Telegram Bot 세팅 | 15분 | Claude Code 실행 |
| 7 | 전체 테스트 | 20분 | 직접 확인 |

> **총 60분.** Park이 직접 할 건 SSH(5분) + WSL(10분)뿐. 나머지는 Claude Code에게 시키면 됨.

---

## 10. 활용도 점수

| 영역 | 현재 | 목표 |
|------|------|------|
| Termux + Claude Code (모바일) | 95 | 95 |
| GitHub Actions CI/CD | 90 | 90 |
| 멀티 레포 운용 (28개+) | 70 | 95 |
| PC 로컬 제어 | 30 | 95 |
| 원격 접속 안정성 | 40 | 95 |
| 브라우저 자동화 통합 | 50 | 90 |
| 대용량 파일 파이프라인 | 20 | 85 |
| 멀티 세션 병렬 작업 | 10 | 90 |
| **종합** | **75** | **92** |

---

## Appendix: 용어 정리

| 용어 | 설명 |
|------|------|
| CLI | Command Line Interface. 텍스트로 명령 입력하는 인터페이스 |
| SSH | Secure Shell. 암호화된 원격 터미널 접속 프로토콜 |
| tmux | Terminal Multiplexer. 하나의 터미널에서 여러 세션 실행 |
| MCP | Model Context Protocol. AI를 외부 도구와 연결하는 오픈 표준 |
| WSL | Windows Subsystem for Linux. Windows 안에서 리눅스 실행 |
| Puppeteer | Chrome을 프로그래밍으로 제어하는 라이브러리 |
| Headless | 브라우저를 화면 없이 백그라운드 실행하는 모드 |
| Daemon | 24시간 상주하며 실행되는 백그라운드 프로세스 |

---

*"코드 한 줄 못 치는 비개발자가 3년간 AI와 삽질해서 만든 프로덕션 환경"*

EduArt Engineer | parksy.kr | 2026.03
