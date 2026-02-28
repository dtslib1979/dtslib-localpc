# dtslib-localpc — 레포 비전 재정의

> **2026-02-28 세션에서 도출된 레포의 확장된 정체성과 로드맵**
> **이 문서는 Termux/PC Claude Code 세션이 읽고 개발 방향을 잡기 위한 인스트럭션이다.**

---

## 1. Before → After

### Before (v4.1까지)
```
"로컬 개발 이력 저장소"
= 세션 로그 텍스트 파일 모아놓는 곳
= git init 하면 필요 없어지는 곳
```

### After (v5.0)
```
"집 PC 원격 관제탑"
= 밖에서 저사양 홈PC를 서버처럼 원격 통제하는 도구 모음
= 비개발자가 Claude Code로 개발하면서 필요한 안전장치 + 자동화 전부
```

---

## 2. 핵심 인사이트 — 왜 이 레포가 필요한가

### Claude Code 시작 사용자의 맹점

```
전통 개발자 경로:
  git 배움 → GitHub 배움 → CLI 익숙 → 서버 배움 → 원격 작업 배움

Claude Code 시작 사용자 경로:
  Claude Code 시작 → Claude가 git/push 다 해줌 → GitHub에 코드 올라감
  → "git이 뭔지"는 결과적으로 알게 됨
  → 근데 "git init으로 로컬 이력 남긴다"는 몰름
  → "서버"가 뭔지 모르는데 PC를 서버처럼 쓰고 있음
  → "원격 개발"이란 개념 없이 원격으로 개발하고 있음
```

**Claude Code가 git, 서버, 원격 작업을 전부 추상화해버렸다.**
편한 대신, 기본 개념을 배울 기회가 사라졌다.

→ **이 레포는 그 빈틈을 메우는 안전장치 + 자동화 모음이다.**

---

## 3. 확장된 레포 역할 — 5개 축

### 축 1: 환경 스냅샷 (기존)
```
"내 PC에 뭐가 깔려있지?"
→ scripts/snapshot.ps1 → snapshots/*.json
→ PC 날아가면 이거 보고 재설치
```
| 상태 | 완성 |
|------|------|
| 구현 | snapshot.ps1 [8/8] |
| 자동화 | Task Scheduler 매일 실행 |

### 축 2: 세션 로그 강제 (기존)
```
"Claude가 뭘 했는지 기록이 없다"
→ hooks/stop-session-log.sh → 세션 로그 미작성 시 블록
→ hooks/start-session-recovery.sh → 비정상 종료 감지 + 복구
```
| 상태 | 완성 |
|------|------|
| 구현 | Stop hook + SessionStart hook |
| 설치 | install-hooks.ps1 / .sh |
| 참고 | git init 하면 대체 가능하지만, 그걸 모르는 사용자를 위한 안전장치 |

### 축 3: PC CCTV (NEW)
```
"Claude Code가 지금 뭘 하고 있는지 모르겠다"
→ cctv.py → 화면 캡처 + Claude.ai 자동 해설 + 읽어주기
→ OBS → 두 화면 합성 녹화 / YouTube Live
```
| 상태 | 프로토타입 |
|------|------|
| 구현 | cctv/cctv.py (셀렉터 미확정) |
| 상세 | cctv/INSTRUCTION.md |
| YouTube | https://www.youtube.com/@technician-parksy |
| 다음 | Windows PC에서 DOM 셀렉터 조사 + 테스트 |

### 축 4: 원격 데스크탑 (NEW — 미구현)
```
"밖에서 집 PC를 조작하고 싶다"
→ RustDesk로 태블릿에서 PC GUI 원격 접속
→ LTE 알뜰요금제 환경에서도 작동
→ Claude Code 세션 시작/감시/조작
```
| 상태 | 문서화만 |
|------|------|
| 도구 | RustDesk (오픈소스, 셀프호스팅 가능) |
| 대안 | AnyDesk, Chrome Remote Desktop |
| 구현 필요 | 설치 가이드 + 최적 설정 (LTE 저대역폭용) |
| 저장 위치 | env/remote-desktop.md (예정) |

#### RustDesk가 적합한 이유
- 오픈소스 (무료)
- 셀프호스팅 가능 (외부 서버 의존 없음)
- 저대역폭에서도 작동 (LTE 알뜰요금제 OK)
- Windows/Android/iOS 전부 지원
- 파일 전송 지원

#### 구현할 것
- [ ] RustDesk 설치 + 설정 가이드 (Windows PC 서버 측)
- [ ] 태블릿/폰 클라이언트 설정 가이드
- [ ] LTE 환경 최적 설정 (해상도 낮춤, 프레임레이트 제한, 색상 깊이 감소)
- [ ] 자동 시작 설정 (PC 부팅 시 RustDesk 자동 실행)
- [ ] 보안 설정 (비밀번호, 허용 기기 등)

### 축 5: Termux ↔ PC 동기화 (NEW — 미구현)
```
"폰에서 한 작업과 PC에서 한 작업이 따로 논다"
→ Termux Claude Code ↔ PC Claude Code 작업 동기화
→ git push/pull 기반 동기화
→ 같은 레포를 폰/PC 양쪽에서 작업
```
| 상태 | 문서화만 |
|------|------|
| 현재 | 폰(Termux)과 PC가 같은 GitHub 레포를 공유 |
| 문제 | 동기화 수동, 충돌 가능 |
| 구현 필요 | 자동 동기화 스크립트 + 충돌 방지 |
| 저장 위치 | scripts/termux-sync.sh (예정) |

#### 현재 워크플로우 (수동)
```
[폰 Termux]
Claude Code로 작업 → git push

[PC]
git pull → Claude Code로 작업 → git push

[폰 Termux]
git pull → 이어서 작업
```

#### 목표 워크플로우 (자동)
```
[폰에서 원격으로 PC 작업 시작]
1. RustDesk로 PC 접속 (또는 SSH)
2. Claude Code 세션 시작
3. PC CCTV 자동 녹화 시작
4. 폰에서 모니터링 (YouTube Live 또는 RustDesk)
5. 작업 끝나면 자동 push
6. 폰 Termux에서 pull → 이어서 작업 가능
```

#### 구현할 것
- [ ] Termux용 PC 원격 시작 스크립트 (SSH 또는 RustDesk CLI)
- [ ] 자동 git pull on session start (Termux)
- [ ] 자동 git pull on session start (PC)
- [ ] 충돌 감지 + 알림

---

## 4. 홈 PC 서버화 — 개념

### 박씨의 PC 사용 패턴
```
[외출 전]
PC 켜놓음 → Claude Code 세션 시작 → 집 나감

[밖에서]
태블릿으로 RustDesk 접속 → PC 화면 확인/조작
또는
폰으로 YouTube Live로 CCTV 시청
또는
Termux Claude Code로 같은 레포 작업

[귀가 후]
PC 화면 확인 → 결과 확인 → 다음 작업 시작
```

### 이건 사실상 서버다
- 24시간 가동 (외출 중에도)
- 원격 접속 (RustDesk)
- 원격 모니터링 (CCTV / YouTube Live)
- 자동 작업 실행 (Claude Code 자율)
- 결과물 자동 push (GitHub)

**"서버"라는 단어를 모르지만 서버처럼 쓰고 있다.**
이 레포는 그 서버 운영에 필요한 도구를 모아놓는 곳이다.

### PC 서버화 체크리스트
- [ ] 절전 모드 비활성화 (화면만 끔, PC는 안 꺼짐)
- [ ] 자동 로그인 설정 (Windows)
- [ ] RustDesk 자동 시작
- [ ] OBS 자동 시작 (CCTV용)
- [ ] Claude Code 세션 원격 시작 방법
- [ ] UPS (무정전 전원) 또는 정전 대비 (선택)
- [ ] 정기 재부팅 스케줄 (주 1회)

---

## 5. 레포 구조 (확장 후)

```
dtslib-localpc/
├── CLAUDE.md                    ← AI 파싱 진입점 (v5.0)
├── README.md
│
├── docs/                        ← NEW: 비전 + 가이드 문서
│   └── VISION.md                ← 이 문서 (레포 비전 재정의)
│
├── cctv/                        ← PC CCTV 시스템
│   ├── INSTRUCTION.md           ← 개발 인스트럭션
│   ├── cctv.py                  ← 메인 스크립트
│   ├── cctv-config.json         ← 설정
│   └── requirements.txt         ← 의존성
│
├── env/                         ← 환경 + 원격 접속 설정
│   ├── RESTORE.md               ← 새 PC 복원 가이드
│   ├── path-settings.json       ← PATH 설정
│   ├── git-config.md            ← Git 설정
│   └── remote-desktop.md        ← (예정) RustDesk 설정 가이드
│
├── hooks/                       ← Claude Code 자동화 훅
│   ├── stop-session-log.sh
│   └── start-session-recovery.sh
│
├── scripts/                     ← 자동화 스크립트
│   ├── snapshot.ps1             ← 환경 스냅샷
│   ├── sync-all.ps1             ← GitHub 전체 sync
│   ├── health-check.ps1         ← 시스템 점검
│   ├── register-scheduler.ps1   ← Task Scheduler 등록
│   ├── install-hooks.ps1        ← hook 설치 (Windows)
│   ├── install-hooks.sh         ← hook 설치 (Linux)
│   └── termux-sync.sh           ← (예정) Termux ↔ PC 동기화
│
├── repos/                       ← 크로스레포 상태
│   ├── status.json
│   ├── parksy-audio.md
│   ├── parksy-image.md
│   └── dtslib-apk-lab.md
│
├── drive-map/                   ← D드라이브 구조
│   ├── repo-map.json
│   ├── structure.json
│   └── duplicates.md
│
├── snapshots/                   ← 환경 스냅샷
│   ├── drive-d.txt
│   ├── installed-software.json
│   └── env-versions.json
│
└── samples/                     ← Phase 1 유산
```

---

## 6. 대화에서 나온 핵심 결정들

### "git init 하면 되잖아" → 맞지만 모르는 사람이 있다
- 세션 로그 hook은 개발자 기준 과잉이지만, Claude Code로 처음 개발 시작한 비개발자에게는 필요한 안전장치
- "당연한 것"이 당연하지 않은 사용자층이 존재

### "API 쓰면 되잖아" → 돈 낭비다
- Claude Max 요금제 이미 결제 중 → Claude.ai 브라우저 자동화로 0원
- Playwright DOM 자동화 >> PyAutoGUI GUI 자동화 (안정성)
- ChatGPT Desktop이 아니라 Claude.ai in Chrome이 정답

### "YouTube Live가 저장 전략이다"
- 로컬 녹화 → 용량 문제
- YouTube Live → 자동 VOD 아카이브, 용량 무제한, 무료
- 구독자 50명 필요 → 그때까지 로컬 녹화로 테스트
- "저장 강박" "용량 강박" 동시 해결

### "이 레포가 20개 중 하나를 차지할 가치가 있냐"
- Before: 의문 (세션 로그만으로는 git init 대체)
- After: **있다** (CCTV + 원격 관제 + Termux 동기화 = 대체재 없음)

---

## 7. 개발 우선순위

| 순위 | 항목 | 이유 | 난이도 |
|------|------|------|--------|
| 1 | PC CCTV 실동작 | 핵심 기능, Windows PC에서 DOM 셀렉터 조사 필요 | 중 |
| 2 | RustDesk 설정 가이드 | 원격 접속 없으면 CCTV 시작도 못 함 | 하 |
| 3 | PC 서버화 체크리스트 | 절전모드 끄기, 자동로그인 등 기본 설정 | 하 |
| 4 | Termux ↔ PC 동기화 | 양쪽에서 작업하려면 필요 | 중 |
| 5 | YouTube Live 연동 | 구독자 50명 이후 | 중 |

---

## 8. 한 줄 요약

> **비개발자가 Claude Code로 집 PC를 서버처럼 쓰면서 필요한 모든 자동화 + 안전장치 + 원격 도구 모음**

이게 dtslib-localpc의 정체성이다.

---

*이 문서는 2026-02-28 Claude Code 세션 대화에서 도출되었다.*
*대화 참여: 박씨 + Claude Opus 4.6*
