# dtslib-localpc — 홈 PC 원격 관제탑

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

### 사용 패턴
```
[외출 전] PC 켜놓음 → Claude Code 세션 시작 → 집 나감
[밖에서]  태블릿(RustDesk)으로 PC 조작 / YouTube Live로 CCTV 시청
          / Termux Claude Code로 같은 레포 작업
[귀가 후] PC 결과 확인 → 다음 작업
```

### 5개 축
1. **환경 스냅샷** — 내 PC에 뭐가 깔려있는지 자동 기록 (scripts/)
2. **세션 로그 강제** — Claude가 뭘 했는지 기록 누락 방지 (hooks/)
3. **PC CCTV** — Claude Code 작업 화면 녹화 + AI 실시간 해설 (cctv/)
4. **원격 데스크탑** — RustDesk로 밖에서 PC GUI 접속 (env/ 예정)
5. **Termux ↔ PC 동기화** — 폰과 PC 작업 연결 (scripts/ 예정)

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

**갱신 명령:** `powershell -File scripts/snapshot.ps1`

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
│   └── VISION.md                ← 레포 비전 재정의 + 로드맵
│
├── snapshots/                   ← 자동 생성 스냅샷
│   ├── drive-d.txt              ← D드라이브 디렉토리 트리
│   ├── installed-software.json  ← 설치된 소프트웨어
│   └── env-versions.json        ← 개발도구 버전
│
├── repos/                       ← 크로스레포 상태 (핵심)
│   ├── status.json              ← 3개 레포 현황 요약
│   ├── parksy-audio.md
│   ├── parksy-image.md
│   └── dtslib-apk-lab.md
│
├── env/                         ← 환경 설정 + 복원 매뉴얼
│   ├── RESTORE.md               ← 새 PC 복원 가이드
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
├── scripts/                     ← 자동화 (Task Scheduler 연동)
│   ├── snapshot.ps1             ← 원클릭 스냅샷 갱신 [8/8]
│   ├── sync-all.ps1             ← GitHub 전체 sync (매일 18시)
│   ├── health-check.ps1         ← 시스템 점검 (매일 09시)
│   ├── register-scheduler.ps1   ← Task Scheduler 등록
│   ├── install-hooks.ps1        ← 프로덕션 레포에 Stop hook 설치 (Windows)
│   └── install-hooks.sh         ← 프로덕션 레포에 Stop hook 설치 (Linux)
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

*Version: 5.0 — 홈 PC 원격 관제탑으로 재정의 (CCTV + RustDesk + Termux 동기화)*
*Updated: 2026-02-28*
*Built with: Claude Code (Claude Opus 4.6)*
