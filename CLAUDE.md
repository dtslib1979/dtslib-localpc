<!-- DTSLIB-LAW-PACK-START -->
---

## 헌법 제1조: 레포지토리는 소설이다

> **모든 레포지토리는 한 권의 소설책이다.**
> **커밋이 문장이고, 브랜치가 챕터이고, git log --reverse가 줄거리다.**

- 삽질, 실패, 방향 전환 전부 남긴다. squash로 뭉개지 않는다.
- 기능 구현 과정 = 플롯 (문제→시도→실패→전환→해결)
- 레포 서사 → 블로그/웹툰/방송 콘텐츠로 파생 (액자 구성)

---

## ⚙️ 헌법 제2조: 매트릭스 아키텍처

> **모든 레포지토리는 공장이다.**
> **가로축은 재무 원장(ERP)이고, 세로축은 제조 공정(FAB)이다.**

### 가로축: 재무 원장 (ERP 로직)

커밋은 전표다. 한번 기표하면 수정이 아니라 반대 분개로 정정한다.

| 회계 개념 | Git 대응 | 예시 |
|-----------|----------|------|
| 전표 (Journal Entry) | 커밋 | `feat: 새 기능 구현` |
| 원장 (General Ledger) | `git log --reverse` | 레포 전체 거래 이력 |
| 계정과목 (Account) | 디렉토리 | `tools/`, `scripts/`, `assets/` |
| 회계 인터페이스 | 크로스레포 동기화 | 명시적 스크립트/매니페스트 |
| 감사 추적 (Audit Trail) | Co-Authored-By | AI/Human 협업 기록 |

### 세로축: 제조 공정 (FAB 로직)

레포는 반도체 팹이다. 원자재(아이디어)가 들어와서 완제품(콘텐츠)이 나간다.

| 제조 개념 | 레포 대응 | 예시 |
|-----------|----------|------|
| BOM (자재 명세) | 의존성 + 에셋 목록 | `pubspec.yaml`, `package.json`, `assets/` |
| 라우팅 (공정 순서) | 파이프라인 스크립트 | 빌드→테스트→배포 순차 실행 |
| WIP (재공품) | 브랜치 + Queue | `claude/*` 브랜치, `_queue/` |
| 수율 (Yield) | 빌드 성공률 | CI 통과율, 테스트 커버리지 |
| MES (제조실행) | 자동화 스크립트 | 동기화, 추출, 배포 도구 |
| 검수 (QC) | 테스트 + 리뷰 | `tests/`, 체크리스트 |

### 4대 원칙

1. **삭제는 없다, 반대 분개만 있다** — `git revert`로 정정. `reset --hard` 금지.
2. **증빙 없는 거래는 없다** — 커밋 메시지에 이유와 맥락. 크로스레포 이동은 명시적 스크립트로.
3. **BOM 확인 후 착공한다** — 의존성/에셋 명세 먼저, 공정 순서 명시 후 실행.
4. **재공품을 방치하지 않는다** — WIP 브랜치와 큐는 정기적으로 소화한다.

---

### 특별법 제0조: 패러다임 전환 (2026-03-16)

> **전환 이유: Claude Code가 메인 드라이버다.**
> Claude Code는 에이전트다. 이 에이전트가 가장 잘 돌아가는 환경(WSL2)에 모든 걸 맞춘다.
> Windows 환경은 무시한다. WSL2 기준으로 모든 작업을 설계한다.

| | Before | After (지금) |
|---|---|---|
| 메인 기기 | 핸드폰 (Termux) | 집 PC (WSL2) |
| 보조 기기 | PC (원격 서버) | 핸드폰 (SSH 클라이언트) |
| 브라우저 자동화 | headless 우회, ADB 체인 | PC Chrome 직접 (Playwright headless=False) |
| 배치 작업 | 핸드폰 한 세션 | tmux 던져놓고 퇴근 |

### 죽은 패턴 (절대 부활 금지)
```
❌ headless Chromium 우회
❌ ADB 체인
❌ 핸드폰에서 CDP 흉내
❌ 세션 1개 제약 설계
```

### 현재 작업 표준
```
핸드폰 → Tailscale SSH → 집 PC WSL2 → Claude Code
텔레그램 봇 → tmux 배치 세션 (tg-image, tg-audio)
브라우저 자동화 → Windows Chrome Playwright headless=False
```

---

### 특별법 제1조: 플랫폼 자동화 도구 우선순위 (2026-03-17)

> **플랫폼 자동화 작업 시 Claude는 반드시 이 순서를 따른다. 임의로 스크립트 작성 금지.**

```
0순위: API / 터미널
  → 항상 먼저 확인. 되면 끝. 아래로 내려가지 않는다.

      ↓ API/터미널로 안 될 때만

1순위: Claude in Chrome (Chrome 확장)
  → GUI 클릭 필수 작업 (구글 콘솔, YouTube Studio, OAuth 등)
  → Claude가 브라우저 안에서 직접 보고 클릭. UI 변화 자동 적응.

2순위: Playwright MCP
  → Claude가 브라우저 외부에서 직접 조작

3순위: CDP/스크립트 (tools/ 경로)
  → 반복 배치. 사람 없이 야간 자동 실행.
```

**Claude 행동 규칙: 위 순서를 건너뛰고 스크립트를 먼저 짜는 것은 헌법 위반이다.**

---
<!-- DTSLIB-LAW-PACK-END -->

---

# dtslib-localpc — 홈 PC 원격 관제탑

---

## ⚡ 헌법 특별법 제0조 — 패러다임 전환 선언 (2026-03-16)

> **이 조항은 모든 하위 조항보다 우선한다. 충돌 시 이 조항이 이긴다.**

### 공리 전환

| | Before (v5.1 이전) | After (v6.0~) |
|---|---|---|
| **메인 기기** | 핸드폰 (Termux) | 집 PC (WSL2) |
| **보조 기기** | PC (원격 서버) | 핸드폰 (SSH 클라이언트) |
| **브라우저 자동화** | headless 우회, ADB 체인, CDP 흉내 | PC Chrome 직접 실행 (정도) |
| **배치 작업** | 핸드폰에서 한 세션 겨우 | tmux 던져놓고 퇴근 |
| **Claude Code** | Termux에서 근사치 | WSL2 PC에서 풀스펙 |

### 죽은 패턴 (절대 부활 금지)

```
❌ headless Chromium 우회 — PC Chrome 있으니까 필요없음
❌ ADB 체인 — PC에서 직접 실행하면 됨
❌ 핸드폰에서 CDP 흉내 — PC가 메인이니까 의미없음
❌ 핸드폰 배터리/성능 고려한 설계 — PC 스펙으로 그냥 돌림
❌ 세션 1개 제약 — tmux로 N개 병렬 실행
```

### 정도(正道) 패턴

```
✅ 브라우저 자동화 → Playwright headless=False (봇 탐지 없음)
✅ 카카오/구글 로그인 → 실제 Chrome으로 직접 처리
✅ 배치 작업 → tmux 세션에 던지고 텔레그램으로 결과 수신
✅ 광역 작업 → 28개 레포 Claude Code 세션 1개에서 전부 처리
✅ 핸드폰 역할 → SSH 터미널 클라이언트 + 텔레그램 결과 수신
```

### 현재 작업 표준 아키텍처

```
핸드폰 (SSH 클라이언트)
  └─ Tailscale VPN
       └─ 집 PC (24시간 ON)
            ├─ WSL2 → Claude Code (광역 28레포 작업)
            ├─ tmux claude-main → 메인 작업 세션
            ├─ tmux tg-image → 이미지 배치 (텔레그램 봇)
            ├─ tmux tg-audio → 오디오 배치 (텔레그램 봇)
            └─ Windows Chrome → 브라우저 자동화 (Playwright 직접)
```

---

## 헌법 제1조: 레포지토리는 소설이다
## 헌법 제2조: 매트릭스 아키텍처

> 상위 규정: `~/CLAUDE.md` (사용자 글로벌 Claude 설정) 참조. 해당 파일이 없는 환경에서는 이 섹션 무시 가능.

---

## 1. Identity

| 항목 | 값 |
|------|-----|
| **Tier** | 인프라 (Infrastructure) |
| **Type** | 홈 PC 원격 관제탑 |
| **Owner** | 박씨 100% |
| **Role** | 밖에서 집 PC를 서버처럼 원격 통제하는 도구 + 자동화 모음 |

---

## 2. Purpose — 왜 이 레포가 존재하는가

> **비개발자가 Claude Code로 집 PC를 서버처럼 쓰면서 필요한**
> **모든 자동화 + 안전장치 + 원격 도구 모음**

### 사용 패턴 (v6.0 — PC 메인 전환 후) ← 특별법 제0조 적용

```
[어디서든] 핸드폰 → Tailscale SSH → PC tmux attach → Claude Code
[배치 작업] 텔레그램으로 지시 → tmux 세션이 처리 → 결과 텔레그램 수신
[브라우저 자동화] PC에서 Playwright headless=False 직접 실행
[귀찮은 작업] tmux에 던져놓고 퇴근 → 나중에 텔레그램으로 확인
```

### 6개 축 (v6.0)
1. **환경 스냅샷** — 내 PC에 뭐가 깔려있는지 자동 기록 (scripts/)
2. **세션 로그 강제** — Claude가 뭘 했는지 기록 누락 방지 (hooks/)
3. **PC CCTV** — Claude Code 작업 화면 녹화 + AI 실시간 해설 (cctv/)
4. **브라우저 자동화** — PC Chrome 직접 실행 (Playwright headless=False) ← RustDesk 대체
5. **텔레그램 봇 배치** — 이미지/오디오 Claude Code 원격 지시 + 결과 수신
6. **SSH + tmux 멀티 세션** — 핸드폰에서 N개 작업 병렬 제어

### 왜 필요한가
```
Claude Code가 git, 서버, 원격 작업을 전부 추상화해버렸다.
→ "git init" 하면 이력 남는다는 것도 모르고
→ "서버"가 뭔지 모르는데 PC를 서버처럼 쓰고 있고
→ "원격 개발"이란 개념 없이 원격으로 개발하고 있다.
→ 이 레포는 그 빈틈을 메우는 안전장치다.
```

### 저장 전략
| 대상 | 저장소 | 비용 |
|------|--------|------|
| 코드 | GitHub | 무료 |
| 개발 과정 영상 | YouTube (Live VOD) | 무료 |
| PC 환경/도구/스크립트 | **이 레포** | 무료 |

> 상세: `docs/VISION.md` — 레포 비전 + 로드맵 + 대화에서 나온 모든 결정

---

## 3. 세션 부트스트랩 프로토콜

**새 Claude 세션 시작 시 반드시 먼저 읽을 파일:**

1. `repos/status.json` — 3개 프로덕션 레포 현황 (JSON, 자동 갱신)
2. `repos/{레포명}.md` — 해당 레포 상세 현황
3. `drive-map/structure.json` — D드라이브 논리 구조
4. `drive-map/repo-map.json` — 20개 GitHub 레포 의존성 맵
5. `snapshots/env-versions.json` — 설치된 개발도구 버전
6. `docs/ISSUES.md` — 미완료 이슈/팔로우업 목록
7. `docs/PC_QUICKSTART.md` — PC 환경 최초 세팅 가이드 (미실행 시)

**갱신 명령:** `powershell -File scripts/snapshot.ps1`

**PC 최초 세팅:** `docs/PC_QUICKSTART.md` 참조 → `scripts/setup-all.ps1` 실행

---

## 4. 크로스레포 맵 (3개 프로덕션 레포)

### parksy-audio — 클래식 음악 파이프라인
| 항목 | 값 |
|------|-----|
| 로컬 경로 | `D:\PARKSY\parksy-audio` |
| 작업 디렉토리 | `D:\tmp` |
| Phase | Phase 8 Complete → Phase 9 (YouTube 배포) |
| Piano Score | avg 96.4 (15/22 at 100.0) |
| Orchestral | avg 99.9 (12/12 >= 99.5) |
| 상세 | `repos/parksy-audio.md` |

### parksy-image — 이미지/웹툰 생산 시스템
| 항목 | 값 |
|------|-----|
| 로컬 경로 | `D:\parksy-image` |
| Phase | Phase 2 (PSE 한글 확장) |
| PSE | 86 glyphs, 33/33 tests |
| Blocker | 사용자 태블릿 손글씨 SVG |
| 상세 | `repos/parksy-image.md` |

### dtslib-apk-lab — Flutter Android 앱
| 항목 | 값 |
|------|-----|
| 로컬 경로 | `D:\1_GITHUB\dtslib-apk-lab` |
| Phase | Active (5 apps) |
| Active Dev | ChronoCall v1.0.0 (build pending) |
| Store | https://dtslib-apk-lab.vercel.app/ |
| 상세 | `repos/dtslib-apk-lab.md` |

---

## 5. D드라이브 논리 구조

| 폴더 | 용도 |
|------|------|
| `PARKSY/` | 프로덕션 워킹 카피 (Claude Code 세션) |
| `1_GITHUB/` | 모든 GitHub 레포 클론 (sync.bat 자동) |
| `2_WORKSPACE/` | PC 작업용 (비Git, 임시) |
| `3_APK/` | APK 개발/빌드 환경 |
| `4_ARCHIVE/` | GitHub/YouTube 이전 백업 |
| `5_YOUTUBE/` | YouTube 업로드 스테이징 |
| `_SYSTEM/` | 시스템 래퍼 (sync.bat, dashboard, logs) — scripts는 dtslib-localpc로 이관됨 |
| `_TOOLS/` | 유틸리티 도구 |
| `VST/` | SoundFont/SFZ/VSTi (음악 파이프라인용) |
| `tmp/` | parksy-audio 작업 디렉토리 |

> 상세: `drive-map/structure.json`

---

## 6. 파일 구조

```
dtslib-localpc/
├── CLAUDE.md                    ← 이 문서 (AI 파싱 진입점)
├── README.md
│
├── docs/                        ← 비전 + 가이드 문서
│   ├── VISION.md                ← 레포 비전 재정의 + 로드맵
│   ├── INFRA_WHITEPAPER.md      ← CLI 통합 전환 기술 백서 (v1.0)
│   └── logs/                    ← 의사결정 원본 대화 아카이브
│       └── 20260312_cli-transition-qa.md
│
├── snapshots/                   ← 자동 생성 스냅샷
│   ├── drive-d.txt              ← D드라이브 디렉토리 트리
│   ├── installed-software.json  ← 설치된 소프트웨어
│   ├── env-versions.json        ← 개발도구 버전
│   └── infra-verify.json        ← CLI 인프라 검증 결과 (자동 생성)
│
├── repos/                       ← 크로스레포 상태 (핵심)
│   ├── status.json              ← 3개 레포 현황 요약
│   ├── parksy-audio.md
│   ├── parksy-image.md
│   └── dtslib-apk-lab.md
│
├── env/                         ← 환경 설정 + 복원 매뉴얼
│   ├── RESTORE.md               ← 새 PC 복원 가이드
│   ├── SSH_SETUP.md             ← SSH 서버 세팅 가이드 (원격 제어)
│   ├── CLI_MIGRATION.md         ← Claude Desktop → CLI 전환 체크리스트
│   ├── path-settings.json       ← PATH + 바이너리 경로 (자동 갱신)
│   └── git-config.md            ← Git 글로벌 설정 (자동 갱신)
│
├── drive-map/                   ← D드라이브 논리 구조
│   ├── repo-map.json            ← 20개 레포 의존성 맵
│   ├── structure.json           ← 폴더 구조 + 용도
│   └── duplicates.md            ← 중복 클론 정리 권고
│
├── hooks/                       ← Claude Code 자동화 훅
│   ├── stop-session-log.sh      ← Stop hook: 세션 로그 미작성 시 블록
│   └── start-session-recovery.sh ← SessionStart hook: 비정상 종료 감지 + 복구
│
├── cctv/                        ← PC CCTV 시스템 (화면 녹화 + AI 해설)
│   ├── INSTRUCTION.md           ← Termux Claude Code용 개발 인스트럭션
│   ├── cctv.py                  ← 메인 스크립트 (스크린샷 + Claude.ai 자동화)
│   ├── cctv-config.json         ← 설정 (간격, 프롬프트, YouTube 채널, OBS)
│   └── requirements.txt         ← Python 의존성 (mss, playwright)
│
├── scripts/                     ← 자동화 (Task Scheduler + CLI 인프라)
│   ├── snapshot.ps1             ← 원클릭 스냅샷 갱신 [8/8]
│   ├── sync-all.ps1             ← GitHub 전체 sync (매일 18시)
│   ├── health-check.ps1         ← 시스템 점검 (매일 09시)
│   ├── register-scheduler.ps1   ← Task Scheduler 등록
│   ├── install-hooks.ps1        ← 프로덕션 레포에 Stop hook 설치 (Windows)
│   ├── install-hooks.sh         ← 프로덕션 레포에 Stop hook 설치 (Linux)
│   ├── setup-all.ps1            ← [NEW] 원클릭 전체 인프라 구축 (마스터)
│   ├── setup-ssh.ps1            ← [NEW] SSH 서버 자동 세팅
│   ├── setup-cli.ps1            ← [NEW] Claude Code CLI + MCP 설치
│   ├── setup-wsl.ps1            ← [NEW] WSL + tmux + Telegram Bot 환경
│   ├── verify-infra.ps1         ← [NEW] CLI 인프라 전체 검증
│   ├── telegram-bot.py          ← [NEW] Telegram 파일 전송 봇 (WSL 데몬)
│   ├── telegram-bot-config.json ← [NEW] 봇 설정
│   ├── tmux-workspace.sh        ← [NEW] tmux 멀티 세션 런처 (4 프리셋)
│   └── remote-connect.sh        ← [NEW] Termux→PC SSH 접속 헬퍼
│
└── samples/                     ← Phase 1 유산 (차이콥스키)
    ├── metadata/library.json
    ├── midi/
    └── trimmed/
```

---

## 7. PC CCTV 시스템

> **Claude Code 작업 화면을 자동 캡처 + Claude.ai가 실시간 해설하는 무인 방송 시스템**

### 구조
```
집 PC (무인 가동)
├── 화면 1: Claude Code 터미널 (자율 작업)
├── 화면 2: Chrome Claude.ai (자동 해설 + 읽어주기)
├── cctv.py: 스크린샷 → Claude.ai 업로드 → 프롬프트 → 해설 (자동 루프)
└── OBS: 두 화면 합성 녹화 (→ YouTube Live)
```

### 3가지 용도
1. **원격 모니터링** — 밖에서 폰으로 "지금 내 PC가 뭐 하고 있지?" 확인
2. **YouTube 콘텐츠** — AI가 AI를 해설하는 무인 이원 방송
3. **개발 이력 영상 보존** — 세션 로그(텍스트)의 상위호환

### 저장 전략
```
현재: OBS 로컬 녹화 → D:\5_YOUTUBE\raw\recordings\
목표: OBS → YouTube Live → 자동 VOD 아카이브 (로컬 저장 0, 용량 무제한)
```

### YouTube 채널
| 항목 | 값 |
|------|-----|
| 채널 | https://www.youtube.com/@technician-parksy |
| 라이브 조건 | 구독자 50명 이상 |

### 상세
> `cctv/INSTRUCTION.md` — 전체 설계 + 개발 단계 + 코드 설계

---

## 7.5. SSH + CLI 통합 원격 제어 (2026-03-12 추가)

> **Claude Desktop GUI → Claude Code CLI 전환. SSH+tmux로 모바일에서 PC 완전 제어.**

### 핵심 발견
- Claude Code CLI에서 MCP 직접 연결 가능 (`claude mcp add`)
- Claude Desktop 없이 CLI 하나로 코드 + 브라우저 자동화 + 외부 서비스 통합
- SSH + tmux = RustDesk 대비 세션 안정성 압도적 (끊겨도 세션 유지)

### 설계 철학
> **귀찮을수록 Claude Code 우선순위가 높다.**
> 귀찮다 = 사람이 반복하기 싫다 = 정확히 자동화해야 하는 지점.
> 돈이 없어서 AWS 못 쓰는 게 아니라, 집 PC로 할 수 있는 걸 먼저 다 해보는 것.
> 이 레포는 그 철학의 실행 기록이다.

### 아키텍처
```
핸드폰 (SSH 클라이언트 — 입출력 단말기)
  └─ Tailscale VPN
       └─ 집 PC (24시간 ON) ← 모든 연산/저장/실행은 여기서
            ├─ WSL2 → Claude Code (광역 28레포 작업)
            ├─ tmux claude-main → 메인 작업 세션
            ├─ tmux tg-image → 이미지 배치 (Telegram Claude Bot)
            ├─ tmux tg-audio → 오디오 배치 (Telegram Claude Bot)
            └─ Windows Chrome → Playwright headless=False (브라우저 자동화)
```

### 도구별 역할 (v6.0)
| 도구 | 역할 |
|------|------|
| Tailscale + SSH + tmux | 원격 터미널 + 세션 유지 (메인) |
| Claude Code CLI (WSL2) | 코드/파일/배치 + 28레포 광역 작업 (메인) |
| Playwright headless=False | 브라우저 자동화 정도 (카카오/구글 로그인, 티스토리, YouTube) |
| Telegram Claude Bot | 배치 작업 지시 + 결과 수신 (던져놓고 퇴근) |
| RustDesk | APK UI 테스트, 디자인 확인 시만 (5% 이하) |

### 구현 상태
| Phase | 내용 | 상태 |
|-------|------|------|
| 1 | Claude Code CLI 설치 | ✅ 완료 |
| 2 | MCP 서버 연결 | ✅ 완료 |
| 3 | SSH 서버 설정 (Tailscale) | ✅ 완료 |
| 4 | tmux 멀티 세션 (4세션) | ✅ 완료 |
| 5 | WSL + Telegram Claude Bot | ✅ 완료 |
| 6 | **패러다임 전환 — PC 메인** | ✅ 2026-03-16 선언 |

### 상세
> `docs/INFRA_WHITEPAPER.md` — 기술 백서 (문제 분석 + 솔루션 + 구현 가이드)
> `env/SSH_SETUP.md` — SSH 서버 세팅 실행 매뉴얼
> `env/CLI_MIGRATION.md` — Desktop → CLI 전환 체크리스트

---

## 8. 설계 원칙

1. **Single Source of Truth** — `D:\_SYSTEM/`의 기존 자산을 흡수, 중복 제거
2. **Machine-Readable** — JSON은 Claude 파싱용, Markdown은 사람용
3. **Auto-Updatable** — `scripts/snapshot.ps1`로 스냅샷 자동 갱신
4. **Cross-Session Bootstrap** — `repos/status.json` 읽으면 전체 컨텍스트 획득
5. **바이너리 금지** — 메타데이터와 경로만. 실물은 로컬/WD에 존재

---

## 9. 환경 요약 (2026-02-28 기준)

| 도구 | 버전 |
|------|------|
| Node.js | 22.18.0 |
| Python | 3.12.10 |
| Git | 2.50.1 |
| Java (OpenJDK) | 17.0.17 |
| Go | 1.24.6 |
| FFmpeg | 8.0.1 |
| PowerShell | 5.1 |
| Flutter | not in PATH |

> 상세: `snapshots/env-versions.json`

---

## 10. GitHub 엔드포인트

| 항목 | 값 |
|------|-----|
| Account | dtslib1979 |
| Plan | Pro (무제한) |
| Total Repos | 20 |
| YouTube Channels | 8 |

> 상세: `drive-map/repo-map.json`

---

## 11. 세션 종료 프로토콜 (자동 강제)

> **Claude Code Stop hook이 자동으로 강제한다. Claude가 까먹어도 hook이 블록한다.**

### 자동화 구조

```
[정상 종료 보호 — Stop hook]
Claude 세션 종료 시도
  → Stop hook 자동 실행 (hooks/stop-session-log.sh)
  → 프로덕션 레포인가? → 아니면 통과
  → 오늘 세션 로그 있는가? → 있으면 통과 + 세션 마커 삭제
  → 없으면 → 블록 + Claude에게 포맷/경로 안내
  → Claude가 로그 작성 → 재시도 → 통과

[비정상 종료 복구 — SessionStart hook]
새 세션 시작 (startup만, resume 제외)
  → SessionStart hook 실행 (hooks/start-session-recovery.sh)
  → 이전 세션 마커(.sessions/{repo}.json) 존재?
  → 마커 있음 + 세션 로그 없음 = 이전 세션 비정상 종료 (서버/PC 다운)
  → Claude context에 복구 지시 주입 (git log 확인 + catch-up 로그 작성)
  → 현재 세션 마커 생성
```

### 설치 (최초 1회)

```powershell
# Windows (PowerShell)
powershell -File scripts/install-hooks.ps1

# Linux / Git Bash
bash scripts/install-hooks.sh

# 제거
powershell -File scripts/install-hooks.ps1 -Uninstall
bash scripts/install-hooks.sh --uninstall
```

설치하면 각 프로덕션 레포에 `.claude/settings.local.json`이 생성된다.
이 파일은 gitignore 대상이므로 레포를 오염시키지 않는다.

### 세션 로그 포맷 (hook이 자동 안내)

```markdown
---
### YYYY-MM-DD | 세션 요약 한 줄
**작업**: 구체적으로 뭘 했는지 (파일명, 함수명, 파라미터 포함)
**결정**: 왜 그렇게 했는지 (비교 대상, 시도한 대안, 버린 이유)
**결과**: 수치 포함 (점수, 파일 크기, 에러 메시지 등)
**교훈**: 다음 세션이 반드시 알아야 할 것
**재구축 힌트**: D: 유실 시 이걸 다시 만들려면 Claude에게 이렇게 시켜라
---
```

### 자동화 범위

| 항목 | 자동화 | 담당 |
|------|--------|------|
| 세션 로그 미작성 감지 + 블록 | **자동** | Stop hook |
| 세션 로그 포맷 안내 | **자동** | Stop hook (블록 메시지에 포함) |
| 비정상 종료 감지 | **자동** | SessionStart hook (마커 기반) |
| crash 후 catch-up 로그 지시 | **자동** | SessionStart hook (Claude context 주입) |
| 세션 로그 내용 생성 | Claude | Claude가 세션 내용 기반으로 작성 |
| repos/{레포}.md append | Claude | Stop hook 블록 후 Claude가 실행 |
| repos/status.json 갱신 | Claude | Stop hook 블록 후 Claude가 실행 |
| git commit + push | Claude | 로그 작성 후 Claude가 실행 |
| 환경 스냅샷 수집 | **자동** | snapshot.ps1 (Task Scheduler) |
| status.json git 필드 | **자동** | snapshot.ps1 [7/8] |
| 세션 로그 staleness 경고 | **자동** | snapshot.ps1 [8/8] (7일 초과 시) |

### 왜 이 포맷인가

- **작업/결정/결과** = 로컬 개발의 git log 대체 (D:\tmp에는 git이 없다)
- **교훈** = 같은 삽질 반복 방지 (파인튜닝 효과)
- **재구축 힌트** = D: 유실 시 Claude가 읽고 처음부터 다시 만들 수 있는 인스트럭션

### 순서 (Claude가 자동 실행)

```
1. 작업 레포에서 git add + commit
2. dtslib-localpc/repos/status.json 갱신
3. dtslib-localpc/repos/{레포}.md 끝에 세션 로그 append
4. dtslib-localpc에서 git add + commit + push
```

### 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| hook이 안 걸림 | 설치 안 됨 | `scripts/install-hooks.ps1` 실행 |
| dtslib-localpc 경로 못 찾음 | 비표준 경로 | `DTSLIB_LOCALPC` 환경변수 설정 |
| 단순 질문인데 블록됨 | 정상 (1회만) | Claude가 "작업 없음" 응답 → 자동 통과 |
| 세션 시작마다 "복구 필요" 뜸 | 이전 세션 비정상 종료 | catch-up 로그 작성하면 해소 |

---

*Version: 6.0 — PC 메인 패러다임 전환 (특별법 제0조, 정도 자동화 선언)*
*Updated: 2026-03-16*
*Built with: Claude Code (Claude Sonnet 4.6)*

---

## Browser Runtime

> Parksy OS 2+2 매트릭스 — 이 레포 전담 브라우저

| 항목 | 값 |
|------|-----|
| **브라우저** | Google Chrome |
| **이유** | 로컬 PC 실행 노드 — 오프라인 자동화 시연 |
| **URL** | https://github.com/dtslib1979/dtslib-localpc |

