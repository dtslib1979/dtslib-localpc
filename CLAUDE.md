# dtslib-localpc — Agent Protocol

---

## 헌법 제1조: 레포지토리는 소설이다
## 헌법 제2조: 매트릭스 아키텍처

> 상위 규정: `~/CLAUDE.md` 참조

---

## 1. Identity

| 항목 | 값 |
|------|-----|
| **Tier** | 인프라 (Infrastructure) |
| **Parent** | dtslib-papyrus (Group HQ) |
| **Type** | 로컬 PC 복원 보험 |
| **Owner** | 박씨 100% |

---

## 2. Purpose — 왜 이 레포가 존재하는가

> **로컬 PC가 날아갔을 때, CLAUDE.md 수준으로 개발환경을 복원하기 위한 보험.**

### 핵심 시나리오

```
[사고 발생]
  로컬 PC 고장 / 분실 / 포맷
    ↓
[복원 시작]
  이 레포의 메타데이터 + 스냅샷을 읽는다
    ↓
  "D드라이브에 뭐가 있었는지" 전부 파악
    ↓
  새 PC에서 동일 환경 재구축
```

### 현재 상태 vs 목표

| 항목 | 현재 | 목표 |
|------|------|------|
| MIDI/오디오 샘플 | ✅ 차이콥스키 4곡 | DAW 프로젝트 전체 |
| 개발 환경 스냅샷 | ❌ 없음 | D드라이브 디렉토리 트리 + 버전 |
| 설치 프로그램 목록 | ❌ 없음 | 설치된 소프트웨어 전체 리스트 |
| WD 패스포트 연동 | ❌ 없음 | 외장 HDD 백업 매핑 |
| 프로젝트 메타데이터 | ❌ 없음 | 로컬 프로젝트별 CLAUDE.md 수준 기술 |

---

## 3. 로드맵 (점진적 확장)

### Phase 1: 현재 — 오디오 샘플 보관
- `midi/` — MIDI 변환본 4개
- `trimmed/` — 트림된 MP3 (parksy-audio 연동)
- `metadata/library.json` — 샘플 메타데이터

### Phase 2: D드라이브 스냅샷
- 디렉토리 트리 (`tree -L 3 D:/ > snapshot.txt`)
- 프로젝트 폴더별 용도 메모
- 용량/파일 수 통계

### Phase 3: 개발환경 복원 매뉴얼
- 설치 프로그램 리스트 + 버전 + 다운로드 경로
- VSCode 확장, 환경변수, PATH 설정
- Node/Python/Flutter 버전
- Git 설정, SSH 키 백업 방법

### Phase 4: WD 패스포트 연동
- 외장 HDD ↔ D드라이브 매핑
- 백업 주기/범위 정의
- 암호화 설정 (WD Security)

---

## 4. 설계 원칙

1. **이 레포에 바이너리를 넣지 않는다** — 메타데이터와 경로만. 실물은 로컬/WD에 있다
2. **CLAUDE.md 수준** — AI가 읽고 "이 PC를 복원하세요"라고 하면 할 수 있을 정도로 기술
3. **점진적 축적** — 한번에 다 하지 않는다. PC 앞에 앉을 때마다 조금씩 추가
4. **GitHub = 보험증서** — 실물(PC/HDD)이 없어져도 이 레포가 명세서 역할

---

## 5. 파일 구조

```
dtslib-localpc/
├── CLAUDE.md          ← 이 문서 (AI 파싱 진입점)
├── README.md          ← 차이콥스키 샘플러 (Phase 1 산출물)
├── metadata/
│   └── library.json   ← 오디오 샘플 메타데이터
├── midi/              ← MIDI 파일 4개
├── trimmed/           ← MP3 트림본 (있으면)
│
├── [TODO] env/        ← Phase 3: 개발환경 스냅샷
├── [TODO] drive-d/    ← Phase 2: D드라이브 트리
└── [TODO] wd-backup/  ← Phase 4: WD 패스포트 매핑
```

---

## 6. 크로스레포 연결

| 연결 | 용도 |
|------|------|
| parksy-audio | MIDI/오디오 샘플 공급 |
| dtslib-papyrus | 그룹 HQ 인프라 등록 |

---

*Version: 1.0*
*Created: 2026-02-26*
*Built with: Claude Code (Claude Opus 4.6)*
