# video-filter 설계 세션 — 2026-04-23

## 레포 / 브랜치

| 항목 | 값 |
|---|---|
| 레포 | `dtslib1979/parksy-image` |
| PR #31 | `claude/technical-whitepaper-v1-Xlaan` → main (Squash merge, SHA 7110807) |
| PR #32 | `PHASE1_INSTRUCTIONS.md` main 추가 (빠진 파일 보완) |

## main 현재 상태 (`docs/video-filter/`)

| 파일 | 내용 |
|---|---|
| `README.md` | 전체 개요, 엔진 구조도, 빠른 시작 |
| `v1.0_whitepaper.md` | 10 스타일 노드 초안 백서 |
| `evaluation_v1.md` | 자체평가 7.0/10 — 구멍 3개 식별 |
| `v2.0_engine_design.md` | 축/레이어/ceiling 추상화 |
| `community_research.md` | IPAdapter/LoRA/외부 scorer 누락 발견 |
| `v2.1_schema_contract.md` | 스키마 계약서 확정 |
| `PHASE1_INSTRUCTIONS.md` | Phase 1 풀빌드 인스트럭션 476줄 |

## 엔진 구조 (v2.1)

```
사용자 입력: "WES_ANDERSON + JUNG_IL_SEONG"
  ↓
L0 INTENT → L1 NARRATIVE(배우) → L2 COMPOSITION(감독) → L3 VISUAL(촬영+LoRA+Ref) → L4 COMPILE
  ↓
Resolver: 7축 벡터 머지 (priority 가중 + ceiling clamp)
  axes = {framing, shot_scale, palette, motion, pace, tone, dialog}
  ↓
Compiler → Adapter (SDXL/MJ/Gemini/Runway)
  + Safety Linter (실명 제거)
  ↓
생성 모델 호출
```

## 냉정한 자체 점수: 6.0/10

| 항목 | 점수 | 이유 |
|---|---|---|
| 문서/스펙 품질 | 9/10 | 구조 깔끔, 계약 명확 |
| 아키텍처 추상화 | 8/10 | 5-layer/7-axis/ceiling 진짜 괜찮음 |
| 실제 작동 가능성 | 4/10 | 이미지 한 장도 안 뽑아봄 |

## 구멍 6개 (핵심 문제)

1. **축 값이 전부 찍은 숫자** — palette +0.3, framing +0.2 근거 없음. 캘리브레이션 제로.
2. **+0.22 framing은 확산 모델이 못 읽음** — 실제론 임계값 넘으면 키워드 on/off 수준으로 떨어짐
3. **실명 스크러빙하면 감독 자체가 사라짐** — "봉준호" → "korean social thriller" = 아무 한국 스릴러
4. **레퍼런스 이미지 0장** — refs/ 폴더 플레이스홀더뿐. 반쪽 엔진.
5. **LoRA 0개** — 스키마에 lora_refs 있지만 실제 연결 없음. 텍스트 프롬프트 생성기 수준.
6. **이미지 한 장도 생성 안 해봄** — KOccult vs SymmetryNoir 블라인드 구별 가능한지 모름.

## 올바른 순서 — Phase 0.5 먼저 (합의됨)

```
Phase 1 풀빌드 전에 작동 증명 필수:

Step 1 (30분): Python 50줄. 하드코딩 프롬프트 2개. 출력 확인.
Step 2 (30분): Gemini API × 2 프로필 × 3장 = 6장 저장.
Step 3 (15분): 육안 판정 — KOccult 3장 vs SymmetryNoir 3장 구별 되냐?
Step 4 (판단):
  YES → Phase 1 풀빌드 Go
  NO  → 축 수치 재조정 or refs 이미지 수집 먼저
```

**Phase 0.5 인스트럭션 작성 → 터미널 Sonnet 실행 → 박씨 육안 판정 → Go/No-Go**

## 기존 parksy-image에 이미 있는 것 (LoRA 연결 자산)

### specs/style/ — BD 스타일 스펙 (확정)
- `bd_prompts.yaml` — Franco-Belgian BD 스타일 프롬프트 드라이버 (emotion/angle/detail 수식어)
- `palette.yaml` — 16색 제한 팔레트 (#1a1a2e 잉크, #f5f0e8 종이, HSL S≤60%)
- `line_weights.yaml` — Ligne Claire + Moebius 하이브리드 선 규격

### pipeline/comfyui/
- `README.md` — AnimateDiff + ControlNet + IPAdapter 워크플로우 명세
- `img2vid_basic.json`, `animate_sequence.json`, `interpolate.json` (워크플로 파일)

### PARKSY_2D_AI_TOOLMIX.md — 툴 스택 확정
| 도구 | 용도 | 인프라 |
|---|---|---|
| Florence-2 | 이미지 자동 태깅 | 로컬 CPU |
| FLUX.1-dev | 선화 → AI 마감 | Vast.ai GPU |
| ControlNet | 박씨 구도 고정 | Vast.ai GPU |
| **박씨 LoRA** | **스타일 고정 ($5 1회 학습)** | **Vast.ai GPU** |
| IP-Adapter | 캐릭터 얼굴 일관성 | Vast.ai GPU |
| WAN 2.1 I2V | 이미지 → 5초 영상 | Vast.ai GPU |

**박씨 LoRA: 박씨 스케치 20~50장 학습 → 어떤 프롬프트써도 박씨 스타일로 나옴**
**학습 데이터 상태: 스케치 + AI마감 페어 수집 필요 (별도 세션 예정)**

## video-filter ↔ 기존 자산 연결 포인트

video-filter의 `lora_refs`에 박씨 LoRA 연결하면:
- 노드별 스타일 선택 + 박씨 선화 스타일 강제 동시 적용
- BD specs/style/ 팔레트/선 규격이 L3 VISUAL 노드로 들어갈 수 있음
- IPAdapter refs/ 폴더에 BD 스타일 레퍼런스 이미지 넣으면 시그널 10배

## 다음 액션

1. **Phase 0.5 인스트럭션 작성** (박씨 요청 시) — Gemini 스모크 50줄짜리
2. **박씨 LoRA 학습 데이터 수집** — 스케치 20~50장 + AI마감 페어
3. **refs/ 폴더 실제 이미지 수집** — KOccult용 한국 오컬트 스틸, SymmetryNoir용 대칭 영화 스틸
4. 스모크 통과 후 → Phase 1 풀빌드

## 관련 파일 경로

```
parksy-image/
├── docs/video-filter/          ← 설계 문서 전체
│   ├── README.md
│   ├── v2.1_schema_contract.md  ← 이게 법
│   └── PHASE1_INSTRUCTIONS.md  ← 풀빌드 인스트럭션
├── specs/style/                ← BD 스타일 스펙 (연결 가능)
│   ├── bd_prompts.yaml
│   ├── palette.yaml
│   └── line_weights.yaml
├── pipeline/comfyui/           ← ComfyUI 워크플로
└── PARKSY_2D_AI_TOOLMIX.md    ← 툴스택 + 박씨 LoRA 계획
```

---
### 2026-04-23 2차 | Style Engine Phase 1 구현 완료 — 31/31 pytest 통과

**작업**:
- `tools/style_engine/engine/` 전체 구현: errors.py / types.py / loader.py / resolver.py / linter.py / adapters 4종 / compiler.py
- 11개 노드 YAML + 2개 프로필 YAML + JSON Schema 3개
- CLI (Typer) + 31개 테스트 4파일
- 버그 수정: linter.py `v` 미정의 → `_SCRUB_TABLE[k]`, loader `_snake` 부정확 → id 필드 직접 비교
- 브랜치 `claude/style-engine-phase1` push → PR #33 생성

**결정**:
- `numbers.py` (repo root)가 stdlib `numbers` 모듈 shadowing → `/tmp`에서 pytest 실행 우회
- conftest.py로 sys.path 통합 관리 (개별 test 파일에서 sys.path.insert 제거)
- JSON Schema에 `format` 카테고리 + `external_refs` 필드 추가 (BD_LIGNE_CLAIRE 검증 통과)

**결과**: 31/31 통과, 7개 커밋 (서사 구조), PR #33 오픈

**교훈**:
- repo root에 `numbers.py` 같은 동명 파일 있으면 pytest 자체가 임포트 불가 → CWD 주의
- YAML id 필드와 파일명이 일치하지 않는 경우 loader가 id 직접 비교로 탐색해야 함

**재구축 힌트**:
  `cd /tmp && python3 -m pytest /home/dtsli/parksy-image/tools/style_engine/tests/ -v`
  PR #33 브랜치: `claude/style-engine-phase1`
---

---
### 2026-04-23 3차 | Style Engine Phase 1 완성 + 방향 전환 확정

**작업**:
- style_engine Phase 1 풀빌드 완료 (PR #33 main 머지)
  - engine/: errors, types, loader, resolver, linter, compiler, adapters 4종
  - nodes/ 11개 (actor3 / director_kr3 / director_global3 / cinematography1 / format1)
  - profiles/ 2개 (KOccult_DarkComedy_v2_1, SymmetryNoir_v2_1)
  - schema/ JSON Schema 3개
  - CLI (Typer): list-nodes, list-profiles, compile, inspect-*
  - tests/ 31개 전부 green (cd /tmp && python3 -m pytest ...)
- 버그 수정 2개:
  - linter.py: _compiled 리스트컴프리헨션 v 미정의 → _SCRUB_TABLE[k]
  - loader.py: CamelCase→snake 변환 부정확 → YAML id 필드 직접 비교로 교체
- JSON Schema: format 카테고리 + external_refs 필드 추가
- conftest.py: numbers.py 그림자 회피 (repo root에 numbers.py 있어서 pytest /tmp에서 실행)

**결정 (방향 전환)**:
- 기존 Gemini 이미지 생성 워크플로우 → 폐기
- style_engine → ComfyUI/FLUX via Vast.ai 파이프라인으로 교체 확정
- 근거: parksy-image에 이미 ComfyUI 인프라 있음
  - pipeline/comfyui/ (워크플로우 JSON 3개)
  - tools/web2video/comfyui_opening.py (FLUX.1-schnell 구현)
  - tools/web2video/vastai_setup_comfyui.sh (Vast.ai 자동 설치)
  - Grok도 이미 ComfyUI로 교체됨 (커밋 7f45e11)
- tools/video_filter/ → dead code, style_engine으로 대체됨, 삭제 대상

**결과**:
- Phase 1: 31/31 tests, PR #33 merged, 7개 서사 커밋
- 다음 단계 명확화: style_engine 출력 → ComfyUI API JSON 브릿지 작성

**교훈**:
- repo root에 동명 파일(numbers.py) 있으면 pytest 자체가 stdlib 충돌로 뻗음
- YAML 파일명이 CamelCase ID와 다를 때 loader는 id 필드 직접 비교로 탐색해야 함
- "인프라 더 쌓기 전에 이미지 1장 먼저" 원칙 (이미지 없으면 검증 불가)

**재구축 힌트**:
  git clone parksy-image && cd /tmp
  python3 -m pytest /home/dtsli/parksy-image/tools/style_engine/tests/ -v
  → 31/31이면 Phase 1 정상
---
