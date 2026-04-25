# CLAUDE_OPS — 박씨 인프라 운영 인스트럭션 v1.0

> **작성일:** 2026-04-25
> **베이스:** ChatGPT 초안 + Anthropic Claude Code 공식 best practices + 박씨 5개월 메모리 99건
> **목적:** 박씨는 방향/검수만, 에이전트가 실행/반복/리팩토링 자율 처리
> **위치:** 박씨 28레포 공통 적용. 각 레포 루트에서 이 파일 인용 가능.

---

## 0. 전제 — 박씨 5개월 결과 인정

박씨는 5개월간 **에이전트가 자율 반복할 토양을 깔았다.**

| 자산 | 상태 |
|---|:--:|
| CLAUDE.md 헌법 4종 (글로벌+레포별) | ✅ 살아있음 |
| 메모리 99건 (user/feedback/project/reference) | ✅ 인덱스됨 |
| 7패키지 맵 + 키워드 자동 매핑 | ✅ 작동 |
| 5-Lane 매트릭스 (phone/tab × claude/aider) | ✅ 가동 |
| MCP 개발법 v1.0 + Author-as-MCP 청사진 | ✅ 진행 중 |
| Stop hook / SessionStart hook | ✅ 설치됨 (localpc) |
| ledger / 인큐베이터 / 워크센터 3분할 | ✅ 박힘 |

**→ 더 이상 "박씨가 매번 검수" 단계가 아님. 에이전트 자율 운영 단계 진입.**

---

## 1. 역할 분리 — 박씨 vs OPS

### 박씨 (사람 — 줄어든 부하)
- **방향 결정** (어디로 갈지)
- **우선순위 선정** (펜딩 16건 중 무엇 먼저)
- **결재** (Plan 단계에서 OK/NO)
- **최종 검수** (커밋 직전 한 번)
- **헌법 개정** (워크센터 3분할 같은 메타 결정)

### OPS (Claude Code + DeepSeek + Aider — 늘어난 자율)
- **탐색** (레포/파일 읽기)
- **계획** (Plan 작성 — 박씨 결재용)
- **구현** (작은 단위 코드 작성)
- **검증** (자체 테스트 / mock / linter)
- **문서화** (CHANGELOG/README/메모리)
- **반복** (작은 루프 자율 돌림)

### 핵심: 박씨가 빠지는 자리는 4단계 게이트 (§ 2)

---

## 2. 4단계 작업 모드 — Explore → Plan → Code → Commit

> Anthropic 공식 best practice. **모든 작업은 이 순서를 따른다.**

### Stage 1: Explore (탐색) — 박씨 입력 0회

- 관련 레포/파일 읽기, 현재 상태 요약
- **절대 금지:** 코드 수정, 새 파일 생성
- **반드시 읽기:** 해당 레포 CLAUDE.md / README / 박씨 백서 (있으면)
- **출력:** "현재 상태 1문단 + 발견한 문제점 3개 이내"

### Stage 2: Plan (계획) — **박씨 결재 게이트**

- 항목별 계획표 작성:
  | 항목 | 변경 파일 | 영향 범위 | 검증 방법 |
  |---|---|---|---|
- **박씨 OK 받기 전 절대 Stage 3 진입 금지**
- 박씨 거부 시 Plan 재작성

### Stage 3: Code (구현) — 박씨 입력 0회

- 합의된 항목 **한 번에 1~2개만** 처리
- 처리 후 짧은 중간 리포트 (변경 파일 + 결과)
- 기존 스타일/패턴 재사용
- 비밀값/설정값은 `.env` 또는 config 파일로 분리

### Stage 4: Commit (정리) — **박씨 최종 게이트**

- 변경 요약 + CHANGELOG/README 반영
- 의미 있는 단위로 커밋 메시지 제안
- **박씨 OK → push** (박씨가 제일 마지막에 한 번만 결재)

### 게이트 요약
```
박씨 검수 = 2회 (Plan / Commit) 만
나머지 모든 단계 = OPS 자율
```

---

## 3. 5-Lane 협업 분업 — 누가 뭘 하나

박씨 메모리 `project_mcp_deepseek_5lane.md` 기반.

| 작업 유형 | 담당 | 이유 |
|---|---|---|
| **창의적 설계 / 아키텍처 결정 / 헌법 개정** | **Claude (Sonnet 4.6 / Opus)** | 메타 사고 필요 |
| **명확한 단계의 API/MCP 체인 설계** | **DeepSeek MCP** | 재현성 + 저비용 |
| **정밀 파일 편집 / 함수 단위 리팩토링** | **Aider** | diff-edit 안정성 |
| **레포 광역 탐색 / 멀티 파일 grep** | **Subagent (Explore)** | 메인 컨텍스트 보호 |
| **장기 실행 작업 / 박씨 자는 동안** | **Background Agent** | 비동기 처리 |
| **격리된 리팩토링** | **Git Worktree** | 메인 브랜치 보호 |

### Claude 가 직접 결정 (위임 금지)
- 새 아키텍처 제안
- 헌법/백서 수정
- 7패키지 경계 재정의
- 박씨 메모리 갱신

### Claude 가 위임해야 하는 것
- "5개 파일 동시 검색" → Explore subagent
- "한 함수 정밀 수정" → Aider 패치 인스트럭션 생성
- "MCP 핸들러 시퀀스" → DeepSeek
- "30분짜리 빌드/테스트" → Background

---

## 4. 커뮤니티 리서치 게이트 (Community-First Baseline)

> 박씨 메모리 `feedback_community_first_baseline.md` 강제 적용.
> **본인이 어겨서 GPU 학습 6회 실패 패턴 만든 룰. 이번엔 OPS 가 강제.**

### 트리거 (이 작업이면 리서치 게이트 무조건 통과)
- 새 외부 서비스 (Railway / RunPod / Vast / HF / YouTube API …)
- 새 라이브러리/프레임워크 도입
- MCP 서버 패턴
- BBC SO / REAPER / GPT-SoVITS / ComfyUI 관련
- 1시간 미만 데이터로 GPU 학습 시도 (이건 트리거 아니라 **즉시 차단**)

### 리서치 단계 출력 (Plan 단계 전 필수)
```markdown
## 커뮤니티 리서치 결과

### Source 1: [URL/타이틀]
- 환경/전제: ...
- 사용 패턴: ...
- 우리 스택과 충돌: 없음/있음(설명)

### Source 2: [URL/타이틀]
...

### Source 3: [URL/타이틀]
...

### 합의 패턴
- 3개 소스 공통 패턴: ...
- 우리 스택 적용 방식: ...
```

**최소 2~3 소스 못 찾으면 작업 중단 + 박씨 보고. "찾기 어렵다" = "고난도/위험" 신호.**

---

## 5. 절대 금지 (박씨 5개월 학습 누적)

> 이 항목들은 **박씨가 이미 시간/돈 들여서 실패 확정한 것.** 다시 제안 금지.

### GPU 학습
- ❌ 데이터 1시간 미만 학습 시도 (BASSOON_DS / RAVE 폐기 사례)
- ❌ 커뮤니티 사례 1건도 없는 학습
- ❌ Vertex AI A100 / RunPod On-Demand (네트워크 차단/runtime null 확인됨)

### 클라우드/서버
- ❌ Oracle / GCP / AWS 를 상시 서버로 쓰는 시도 (`feedback_no_cloud_server`)
- ❌ 로컬 PC 를 상시 서버로 전환
- ✅ 허용: Railway (MCP 호스팅) / HF (모델 창고) / RunPod (일회성 GPU) / Vast.ai (일회성 GPU)

### 앱/UI
- ❌ PWA → APK 마이그레이션 재시도 (dtslib-apk-lab 800 커밋 매몰)
- ❌ headless Chromium 우회 / ADB 체인 / 폰 CDP 흉내 (헌법 특별법 제0조 죽은 패턴)

### 인프라
- ❌ "WSL2 무시하고 Windows native" (헌법 특별법 제0조 위반)
- ❌ "PC 양산 금지" (백서 v1.1 정정으로 폐기)
- ❌ 통제식 프랜차이즈 모델 (인큐베이터 모델로 대체됨)

### 차선책 자동 제안
이런 아이디어 떠오르면 **대신 FAB 컴퓨트 아키텍처 기준으로 대안 제안:**
> 저장 = GitHub/CDN, 연산 = Railway MCP, GPU = Vast.ai 일회성, 로컬 = 작업대만

---

## 6. 자동화 레벨 4단계 — 무엇까지 OPS 자율인가

### Stage 1 — Read-Only (제한 없음, OPS 자율)
- 코드/백서/레포 읽기
- 구조/문제점 요약
- 메모리 검색
- git log 확인
- ❌ 새 파일/수정 금지

### Stage 2 — Safe Tasks (박씨 통보, 자율 진행)
- README/주석/로그 정리
- 단위 테스트 추가
- 타입 힌트 추가
- 데드 코드 제거
- 린터 통과
- 메모리 인덱스 갱신

→ **롤백 부담 작은 작업.** OPS 자율 + 박씨 통보만.

### Stage 3 — Guided Development (Plan 게이트 필수)
- 새 기능/핸들러 구현
- 리팩토링
- 새 MCP 툴 작성
- 새 헌법/메모리 추가
- 새 레포 생성

→ Plan 박씨 결재 → 구현 → Commit 박씨 결재.

### Stage 4 — Autonomous (현재 사용 금지)
- 박씨 결재 없이 변경+커밋+배포
- 박씨가 자는 동안 운영 결정

→ **박씨 명시 허락 없이 절대 진입 금지.** MCP 헌법 강제 메커니즘 완성된 후 일부 레포만 가능.

### 현재 기본
**Stage 2~3 사용. Stage 4 금지.**

---

## 7. Claude Code Native 기능 활용 (커뮤니티 리서치 결과)

### 7.1 Plan Mode (`/plan` 또는 EnterPlanMode tool)
- Stage 2 박씨 결재 게이트 강제 메커니즘
- Plan 작성 후 박씨 OK 전까지 코드 변경 불가
- **모든 Stage 3 작업의 진입점**

### 7.2 Subagents (Agent tool)
- Explore: 광역 탐색 (메인 컨텍스트 보호)
- general-purpose: 멀티 단계 위임
- Plan: 아키텍처 설계 위임 (현재 메모리에 활용 사례 적음)
- 병렬 실행: 한 메시지에 여러 Agent 호출

### 7.3 Hooks (이미 박씨 설치)
- Stop hook: 세션 종료 시 로그 미작성 차단
- SessionStart hook: 비정상 종료 감지 + 복구 지시 주입
- **추가 도입 추천:** PreCommit hook — 박씨 헌법 위반 자동 차단

### 7.4 Loop Mode (`/loop` skill)
- 동적 페이싱 (sleep + wakeup) 자율 반복
- 펜딩 16건 처리에 활용 가능
- **사용 예:** "Build watcher" / "Pending ticket processor"

### 7.5 Background Mode (run_in_background)
- 박씨 자는 동안 30분+ 작업
- 결과 통보 + 다음 행동 결정

### 7.6 Worktrees (`isolation: "worktree"` Agent param)
- 격리된 git 환경에서 리팩토링
- 메인 깨지지 않게 실험
- 변경 없으면 자동 정리

### 7.7 MCP 게이트 (박씨 진행 중)
- 박씨가 만들고 있는 MCP = **자기 헌법 강제 메커니즘**
- 텍스트 권고 → 실행 가능 코드 변환
- Stage 4 자율 진입의 전제 조건

---

## 8. 자율 반복 루프의 진짜 답 — "유한 게이트 루프"

> 박씨 의견: "여기서부터는 모델이 지속적으로 반복하면서 리팩토링하고 목테스트하면 되는 거 아니냐"
> 답: **YES, 단 무한 루프 아닌 유한 게이트 루프로.**

### 무한 자율 루프 위험 (커뮤니티 사례)
| 위험 | 결과 |
|---|---|
| Hallucination 누적 | 잘못된 가정 위에 코드 쌓임 |
| Scope creep | 관련 없는 파일까지 손댐 |
| 토큰 폭발 | 시간당 $10+ 가능 |
| Mock 함정 | "테스트 통과시키는 코드" — 진짜 버그 그대로 |
| 헌법 위반 누적 | Claude 회상률 100% 아님 |

### 유한 게이트 루프 (이 OPS 의 채택안)

```
박씨 티켓 1개 입력
   ↓
[Explore] OPS 자율 (게이트 없음)
   ↓
[Plan] ─── ★ 박씨 게이트 1
   ↓ OK
[Code] OPS 자율 (1~2 항목씩, 중간 리포트)
   ↓
[자체 검증] 린터/유닛 테스트/타입체크 (OPS 자율)
   ↓
실패 시 → 동일 티켓 내 자율 재시도 (최대 3회)
   ↓
3회 초과 → 박씨 보고 + 티켓 보류
   ↓
[Commit 제안] ─── ★ 박씨 게이트 2
   ↓ OK
push + 티켓 종료
   ↓
다음 티켓 (Loop / Background 가능)
```

### 박씨 부담
- 티켓당 박씨 결재 = **2회 (Plan + Commit)**
- 한 결재 = **1분 미만** (OPS 가 요약 제공)
- 티켓 1개 = 박씨 입력 ~2분, OPS 작업 30분~몇 시간

### 장점
- 무한 루프 위험 차단 (자체 재시도 3회 한도)
- 박씨가 검수 잊어도 게이트가 차단
- 토큰 비용 예측 가능 (티켓 단위)
- Mock 함정 방지 (게이트가 박씨 검수 강제)

---

## 9. 운영 가이드 — 어떻게 시작하나

### Step 1 — 펜딩 16건 티켓화
박씨가 메모리 `🔴 펜딩` 마커 메모리 16개 → 각각 1-paragraph 티켓으로 변환.

```markdown
### 티켓 #001 — Voice Model HF 업로드
배경: parksy_ko_v1.onnx(319MB) + ddsp_bassoon.pt(25MB) 로컬 확인 완료
블로커: huggingface-cli login (30초 작업)
완료 정의: HF 페이지에 모델 2개 public 등록
출처: project_voice_model_hf_upload_pending.md
```

### Step 2 — 우선순위 매기기 (박씨 결정)
- P0 (즉시): 1줄 블로커 처리 (login/비번 입력)
- P1 (이번 주): 펜딩 마감
- P2 (이번 달): 신규 작업 (현재 STOP 권고)

### Step 3 — 티켓 1개씩 OPS 에 던짐
박씨 발화: **"티켓 #001 처리해"**

OPS 자동 실행:
1. Explore (현재 상태 요약)
2. Plan 작성 → 박씨 결재 대기
3. 박씨 OK → Code
4. 자체 검증
5. Commit 제안 → 박씨 결재 대기
6. 박씨 OK → push → 다음 티켓

### Step 4 — Loop 돌리기
박씨 자는 동안:
- `/loop` 모드로 P0 티켓 자동 순회
- Plan 단계마다 박씨 결재 대기 (안전)
- 박씨 일어나면 Plan 5~10개 한 번에 결재 → 다시 돌림

### Step 5 — Stage 4 진입 (먼 미래)
MCP 헌법 강제 메커니즘 완성 → 일부 레포 (예: parksy-logs) 박씨 결재 없이 자율.
**현재 단계 아님. 펜딩 처리 후 검토.**

---

## 10. 이 OPS 의 자기 검증

| 항목 | 충족 |
|---|:--:|
| 박씨 5개월 메모리 99건 호환 | ✅ |
| 헌법 4종 (글로벌/localpc/branch 등) 호환 | ✅ |
| FAB 컴퓨트 아키텍처 호환 | ✅ |
| 워크센터 3분할 호환 | ✅ |
| 인큐베이터 모델 호환 | ✅ |
| 박씨 부담 감소 | ✅ (티켓당 2분) |
| 무한 루프 위험 차단 | ✅ (게이트 + 3회 재시도) |
| Community-First 강제 | ✅ (Section 4) |
| 6 금지 사항 강제 | ✅ (Section 5) |

---

## 11. 다음 액션 (박씨 결정)

이 OPS 인스트럭션 채택 시:

1. **즉시:** 이 파일을 `~/CLAUDE.md` 에서 reference 로 인용 (글로벌 적용)
2. **이번 주:** 펜딩 16건 → 티켓 16개 변환 (OPS 자율 가능)
3. **다음 주:** P0 티켓 5개 OPS 처리 (박씨 결재 게이트만 통과)
4. **이번 달:** 펜딩 16건 전부 마감 (인프라 정리 완료)
5. **다음 달:** 시장 검증 단계 진입 (콘텐츠 30편 업로드 시작)

이 OPS 가 박씨 정수 평가 (`PARKSY_EXPERT_ASSESSMENT_2026-04-25.md`) 의 결론
**"기술 9 / 시장 2 → 시장 5 진입"** 으로 가는 실행 도구.

---

*OPS 작성: Claude (Anthropic) — Anthropic 공식 best practices + 박씨 메모리 99건 + ChatGPT 초안 합성*
*박씨 동의 후 채택. 동의 안 하면 Section 단위로 수정 가능.*

---

## 12. AD / BC 시대 구분 + Papyrus 프로젝트 (박씨 제안 + Claude 보강)

> **박씨 원문 발언 (2026-04-25):**
> "지금까지를 AD BC 구분 해서 내가 지금까지 너랑 같이 수작업으로 노가다 뛰어서 만든 거를 BC, 너가 이제 자율주행하면서 스스로 검증해서 여기 있는 거를 전부 다 나랑 같이 데일리 미팅을 하면서 자율주행 고치는 거를 AD라고 설정하는 건 어때? 파피루스 폴더에서 너가 작업하는 것들 얼마나 잘하는지 변경 전 변경후로 나눠서 어떻게 네가 리팩토링하는지를 또 하나의 프로젝트로 진행하는 건 어떠냐."

### 12.1 시대 정의

| 구분 | 기간 | 주체 | 결과물 | 평가 방식 |
|---|---|---|---|---|
| **BC (Before Co-driver)** | 2025-12-01 ~ 2026-04-25 14:00 KST | **박씨 + Claude 수작업 노가다** | 28 레포 / 5,800+ 커밋 / 99 메모리 / 헌법 4종 / 백서 다수 | 정수 평가 완료 (`PARKSY_EXPERT_ASSESSMENT_2026-04-25.md`) |
| **AD Genesis** | 2026-04-25 14:30 KST | 박씨 선언 + 이 문서 채택 | CLAUDE_OPS §12 박힘 | (시대 전환점) |
| **AD (After Driver)** | 2026-04-25 14:30 KST ~ | **OPS 자율주행 + 박씨 데일리 검수** | Papyrus 티켓 / BEFORE/AFTER / 주간 회고 | 메트릭 기반 (§ 12.5) |

### 12.2 Papyrus 폴더 구조

**위치:** `dtslib-papyrus/ad/` (관제탑 레포 안. `papyrus/papyrus/` 동어반복 회피)

```
dtslib-papyrus/
├── ad/                                       ← AD 시대 작업 아카이브 전체
│   ├── 00_INDEX.md                           ← 모든 티켓 마스터 인덱스 + KPI
│   ├── 00_DAILY.md                           ← 비동기 데일리 미팅 로그
│   ├── 00_WEEKLY_RETRO.md                    ← OPS 자체 주간 회고
│   ├── _templates/
│   │   ├── ticket.md                         ← 티켓 템플릿
│   │   └── make-ticket.sh                    ← 티켓 자동 생성 스크립트
│   └── YYYY-MM-DD_T-NNNN_<slug>/             ← 티켓별 폴더
│       ├── NOTES.md                          ← 배경/Plan/검증/리스크/DAILY
│       ├── BEFORE.diff                       ← git diff 기반 자동 생성
│       ├── AFTER.diff                        ← (필요시) 추가 스냅샷
│       └── METRICS.json                      ← 자동 수집 KPI
└── (기존 papyrus 콘텐츠 — 손대지 않음)
```

### 12.3 티켓 라이프사이클 (자동화 우선)

```
1. 박씨 입력: "Papyrus/AD 모드, 티켓 만들어 — <한 문단 설명>"
   ↓
2. OPS Step 1 (Bootstrap):
   - make-ticket.sh 실행 → ad/2026-04-26_T-0001_<slug>/ 생성
   - NOTES.md 템플릿 복사
   - 00_INDEX.md 에 행 추가 (status: planning)
   ↓
3. OPS Step 2 (Explore):
   - 관련 파일 스캔, 현재 상태 NOTES.md 에 요약
   - 커뮤니티 리서치 (§ 4 게이트)
   ↓
4. OPS Step 3 (Plan):
   - NOTES.md "## Plan" 섹션 작성
   - ★ 박씨 결재 게이트 1 (데일리 미팅에서 OK/수정)
   ↓
5. OPS Step 4 (BEFORE 스냅샷 자동):
   - git stash 또는 변경 직전 commit hash 기록
   - BEFORE.diff = 작업 시작 시점 git ref 저장
   ↓
6. OPS Step 5 (Code):
   - 실제 레포 파일 수정 (관련 레포에서)
   - 자체 검증 (린터/유닛 테스트/타입체크)
   - 실패 → 자율 재시도 (최대 3회)
   ↓
7. OPS Step 6 (AFTER 스냅샷 자동):
   - 작업 완료 시점 git diff 자동 생성
   - AFTER.diff 저장
   - METRICS.json 자동 수집
   ↓
8. OPS Step 7 (Commit 제안):
   - NOTES.md "## 변경 요약 (3줄)" 추가
   - ★ 박씨 결재 게이트 2 (데일리 미팅)
   ↓
9. OPS Step 8 (Push + Index 갱신):
   - 관련 레포 push
   - dtslib-papyrus/ad/00_INDEX.md status: done
   - DAILY 섹션 갱신
```

### 12.4 BEFORE / AFTER 스냅샷 정책 — 수동 복사 금지

> **수동 복사 = 박씨 부담. git diff 가 진짜 답.**

**자동 메커니즘:**
```bash
# Step 5 (BEFORE)
START_REF=$(cd <target_repo> && git rev-parse HEAD)
echo "$START_REF" > ad/<ticket>/BEFORE_REF

# Step 7 (AFTER)
END_REF=$(cd <target_repo> && git rev-parse HEAD)
cd <target_repo> && git diff $START_REF..$END_REF > ../dtslib-papyrus/ad/<ticket>/CHANGES.diff
echo "$END_REF" > ad/<ticket>/AFTER_REF
```

→ BEFORE/AFTER 폴더 통째 복사 안 함. **diff 1개로 모든 변경 추적.**
→ 필요시 `git show $BEFORE_REF:<file>` 로 원본 복원 가능.

### 12.5 KPI 자동 수집 (METRICS.json)

```json
{
  "ticket_id": "T-0001",
  "package": "P1 INFRA",
  "target_repo": "dtslib-localpc",
  "started_at": "2026-04-26T09:00+09:00",
  "completed_at": "2026-04-26T09:42+09:00",
  "duration_min": 42,
  "loc_added": 23,
  "loc_removed": 67,
  "files_touched": 4,
  "tests_added": 2,
  "tests_passed": 5,
  "tests_failed": 0,
  "park_interventions": 2,
  "self_retries": 1,
  "tokens_used": 12450,
  "estimated_cost_usd": 0.18,
  "community_sources_cited": 3,
  "constitution_violations": 0,
  "rollback": false
}
```

**박씨가 1주마다 보는 마스터 인덱스:**
| 티켓 | 패키지 | 시간 | LOC ±  | 테스트 | 박씨 개입 | 재시도 | 비용 | 상태 |
|---|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| T-0001 | P1 | 42m | +23/-67 | 5/0 | 2 | 1 | $0.18 | ✅ |

### 12.6 데일리 미팅 — 동기/비동기 둘 다 지원

#### 동기 (박씨 시간 있을 때, 5-10분)
박씨가 "OPS 데일리" 발화 → 어제 한 일 / 오늘 할 일 / 막힌 점 보고.

#### 비동기 (박씨 시간 없을 때, 기본값)
OPS 가 매일 자동 작성: `ad/00_DAILY.md` 에 append.

```markdown
## 2026-04-26 (목)

### 어제 한 일
- T-0001 Railway 502 fix → done
- T-0002 youtube-cache 리팩 → planning

### 오늘 할 일
- T-0002 Plan 박씨 결재 대기
- T-0003 펜딩 voice model HF 업로드 → 티켓화

### 막힌 점 / 박씨 결재 필요
1. T-0002 Plan 검토 (5분)
2. T-0003 huggingface-cli login 박씨 직접 (30초)

### 메트릭 (어제)
- 처리 티켓: 1
- 박씨 개입 시간: 추정 4분
- 비용: $0.18
```

→ 박씨는 매일 한 번 `ad/00_DAILY.md` 만 보면 됨. 1분 컷.

### 12.7 OPS 자체 주간 회고 (메타 학습)

매주 일요일 OPS 자율 작성: `ad/00_WEEKLY_RETRO.md` 에 append.

```markdown
## Week of 2026-04-26 ~ 2026-05-02

### 처리 통계
- 티켓: 7개 (완료 5 / 진행 1 / 보류 1)
- 박씨 개입: 14회 (Plan 7 + Commit 7)
- 박씨 시간: 추정 35분 (티켓당 5분)
- OPS 작업: 누적 4시간 23분
- 비용: $1.42

### 잘한 패턴 (계속할 것)
- T-0001/T-0003 — 커뮤니티 리서치 3소스 정확히 인용 → Plan 1발 통과
- T-0005 — 자체 재시도 2회 만에 해결 (3회 한도 내)

### 못한 패턴 (개선 필요)
- T-0002 — Plan 너무 broad → 박씨 2번 거부 → 작게 쪼개야 했음
- T-0006 — Mock 테스트만 통과시킴 → 박씨 진짜 실행 시 버그 발견 → 롤백

### 헌법 위반 자동 검출
- 0건 (이번 주는 클린)

### 다음 주 자동 개선안
- Plan 작성 시 "1 티켓 = 1 파일" 룰 강화
- Mock 의존도 30% 이하 강제
```

### 12.8 AD 실패 기준 — 롤백 트리거 명시

다음 중 하나라도 발생 시 OPS 자율 작업 즉시 중단 + 박씨 보고 + 해당 변경 revert 제안:

| 트리거 | 한도 |
|---|:--:|
| 자체 재시도 횟수 | 3회 |
| 1 티켓 누적 시간 | 30분 |
| 1 티켓 누적 비용 | $5 |
| 헌법 위반 (§ 5 절대 금지) | 0회 (즉시 중단) |
| 박씨 결재 거부 누적 | 2회 (3회째는 재구성) |
| Mock 통과 + 진짜 실행 실패 | 1회 (즉시 롤백) |

**롤백 = `git revert`** (헌법 제2조 4대 원칙: 삭제는 없다, 반대 분개만).

### 12.9 BC → AD 경계 cutoff

**선언 시점:** 2026-04-25 14:30 KST

이 시점 이후:
- 신규 작업 = AD (Papyrus 티켓 의무)
- 기존 BC 코드 수정 = AD 처리 (기존 코드를 AD 리팩토링 하는 것)
- 응급 hotfix = BC 식 직접 수정 가능 단, 24시간 내 회고 티켓 필수 작성

### 12.10 인큐베이터 모델과의 연결 (사이드 효과)

박씨 메모리 `project_incubator_model.md` 적용:
- AD 작업 로그 = 박씨 성장 서사 = **콘텐츠 원자재**
- BEFORE/AFTER diff 시각화 = 블로그/방송 1편씩 가능
- 주간 회고 = 박씨 1인 출판사 콘텐츠 = 인큐베이터 모델의 6 코워커에게 공유 가능
- 헌법 제1조 "레포는 소설" 와 정확히 일치 — Papyrus = 소설 원고 제본본

### 12.11 부트스트랩 (다음 세션 박씨 발화 1줄)

```
박씨: "Papyrus/AD 모드 발동. ad/ 디렉토리 부트스트랩 + 첫 티켓 T-0001 만들어. 펜딩 16건 중 1줄 블로커 가장 쉬운 거부터."
```

OPS 자동 실행:
1. `dtslib-papyrus/ad/` 폴더 생성 (00_INDEX.md / 00_DAILY.md / 00_WEEKLY_RETRO.md / _templates/)
2. `make-ticket.sh` 작성
3. T-0001 폴더 생성 + NOTES.md
4. Plan 박씨 결재 대기

### 12.12 §12 채택 시 박씨가 잃을 것 vs 얻을 것

**잃을 것:**
- "내가 직접 다 했다" 자부심 (BC 시대 정체성)
- 매번 결정에 박씨가 개입하는 통제감

**얻을 것:**
- 매일 박씨 부담 1분 (DAILY 1회 확인)
- 매주 박씨 부담 5분 (WEEKLY_RETRO 1회 확인)
- 펜딩 16건 → 1~2개월 내 완파 가능
- AD 작업 자체가 콘텐츠 = 인큐베이터 모델 활성화
- "OPS 가 어떻게 일하는지" 투명한 기록 = 박씨 메타 학습 가능
- 5개월 정수 평가의 "기술 9 / 시장 2" → "기술 9 / 시장 5" 진입 실행 도구

---

*§12 작성: ChatGPT 초안 (12.1~12.5) + Claude 보강 (12.6~12.12) + 박씨 메모리 통합*
*AD Genesis: 2026-04-25 14:30 KST*
