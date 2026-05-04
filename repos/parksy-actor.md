# parksy-actor 개발 일지

> **강의 영상 액션 배우 MCP — markdown + page_url → 자동 mp4 (15분 RPM 최적)**

---

## 1. 프로젝트 정체성

**parksy-actor**는 "박씨 비전 = 15분 강의영상" 자동화 MCP다.
- **박씨 비전:** "유튜브 강의 15분 = RPM 광고 최적 (mid-roll 2~3개)"
- **시스템 설계:** 4 레이어 분리 (Director / Choreographer / Performer / Editor)
- **입력 4 변수:** markdown_path, page_url, target_duration_sec=900, rpm_optimization=True
- **출력:** mp4 + chapter markers (mid-roll hint) + Telegram 송출

### 4 레이어 아키텍처

```
Layer 1 — Director (의도)
  ├─ DurationAllocator (target_duration × density 가중)
  └─ → 섹션별 시간 분배 + mid_roll_hints

Layer 2 — Choreographer (계획 + 페이지 적응)
  ├─ Markdown Parser (heading + emphasis 추출)
  ├─ Claude vision scout (per-slide screenshot → bbox/whitespace/density)
  └─ → 액션 시퀀스 (vision bbox 기반)

Layer 3 — Performer (wall-clock 실행)
  ├─ Playwright headless + record_video
  ├─ perfect_freehand 손글씨 + 펜 sprite 트래킹
  ├─ handwriting + handwriting_kr (Catmull-Rom + Gaegu 폰트)
  └─ → webm + per-action timing log

Layer 4 — Editor (시간 정합)
  ├─ Audio track 박음 (plan section.duration_sec 따라 narrate + silence padding)
  ├─ Video stretch (freeze_tail / setpts_slow)
  ├─ Chapter markers (ffmetadata, mid-roll friendly 표시)
  └─ → target_duration 정확한 mp4 (-t cap)

Layer 5 — Distributor (송출)
  └─ Telegram (manual curl) → 다음: YouTube/Discord MCP
```

---

## 2. 현재 상태 (2026-05-05)

| 항목 | 값 |
|------|-----|
| Branch | `main` |
| Last Commit | `751acb0` — docs(parksy-actor): DEV_LOG.md |
| Latest Render | v14 = **DUR 900.0s 정확 일치 ✅** / 51 actions / 0 fail / 19MB |
| Telegram msg | 765 |
| Actor SSE PID | 4083087 (port 8012) |
| MCP 툴 | 5개 노출 (render/compile/scout/capability_matrix/list) |

### 박은 v3.1 핵심

- ✅ target 900s = actual 900s 정확 (v13 2343s 버그 해결)
- ✅ 6 chapters 박힘 (s0 표지 / s1~s4 본론 / s5 결론)
- ✅ 매직 넘버 0개 (v2.0 변수화 풀 실현)
- ✅ Claude vision per-slide scout (5/6 슬라이드 OK)
- ✅ 한영 손글씨 (Excalidraw 필체)

---

## 3. 커밋 이력 (v1.3 → v3.1)

```
751acb0 docs: DEV_LOG.md 박음
198c8f3 v1.9+v2.0 통합: per-slide vision + whitespace + density 가중
5afee3e v3.1: Editor target duration cap
a69af54 v3.0: 4 레이어 분리 + Layer 4 Editor 신설
75673c9 v1.8: bbox_hint priority — vision 좌표를 resolver 우회
d44f86e v1.7: lecture_compiler에 Claude vision scout 통합
394c85b v1.6: scout/Claude vision wire up + capability matrix
ea01518 v1.4: perfect_freehand 연필 sprite 트래킹
916e15e v1.5: lecture_compiler 모듈 신설
68ae4bc v1.3: SSE async + esm.sh + recorder 풀길이
9ab583a docs(v1.2): WHITEPAPER 17 섹션
```

### 의사결정 핵심 7개

1. **하드코딩 → 모델링** (v1.5~v2.0): markdown + page_url 변수만 박으면 자동
2. **Claude vision wire up** (v1.6): is_available()=False 하드코딩 → claude CLI subprocess 박음
3. **3단계 capability matrix** (v1.6): Perplexity 진단 채택 — implemented/wired/available 분리
4. **per-slide vision** (v1.9): 한 페이지에 click(Next) 박으며 슬라이드별 vision 호출
5. **target_duration_sec 1차 변수** (v2.0): 박씨 명제 "15분 RPM 최적" 인코딩
6. **4 레이어 분리** (v3.0): 시간축 3개 충돌 해결, Editor 신설
7. **Editor target cap** (v3.1): final mux `-t target_duration`이 진실 소스

### 핵심 교훈

- **박씨 1차 비전을 매 결정에 검증 필수.** "15분 RPM"을 7번 커밋 동안 잊었음 = Junior 패턴.
- **Layer 분리 안 하면 시간축 충돌.** Compiler/Performer/Editor 책임 분리해야 timeline 시간 = mp4 시간.
- **dead wire ≠ 격하.** 박씨 비전에 중요한 모듈은 wire up이 정답.

---

## 4. 핵심 파일 매핑

| Layer | 파일 |
|-------|------|
| Director | `parksy_actor/compile/lecture_compiler.py::DurationAllocator` |
| Choreographer | `parksy_actor/compile/lecture_compiler.py::build_section_actions` + `parksy_actor/scout/claude_in_chrome.py` |
| Performer | `parksy_actor/timeline_runner.py` + `parksy_actor/executors/*` + `parksy_actor/session_modes/studio_mode.py` |
| Editor | `parksy_actor/editor/editor.py` |
| Orchestrator | `parksy_actor/orchestrator.py::render_async` |
| MCP SSE | `mcp_server_sse.py` (port 8012) |

### 상세 일지

> `~/parksy-actor/docs/DEV_LOG.md` — v1.3~v3.1 풀 이력, 의사결정, 교훈, 재구축 힌트

> `~/parksy-actor/docs/WHITEPAPER.md` — v1.2 17 섹션 풀 기술 명세

---

## 5. 세션 로그

---
### 2026-05-04 ~ 05-05 | parksy-actor v1.3 → v3.1 통합 — 4 레이어 분리 + Editor 신설 + 박씨 비전 풀 실현

**작업:**
- 9 커밋 박음 (v1.3 → v3.1, 5afee3e 등)
- `parksy_actor/compile/lecture_compiler.py` 신설 (변수화 컴파일러, DurationAllocator, per-slide vision 통합)
- `parksy_actor/scout/claude_in_chrome.py` 풀 갈아엎음 (subprocess claude --print + Playwright screenshot)
- `parksy_actor/editor/editor.py` 신설 (Layer 4 Editor — target duration cap)
- `parksy_actor/timeline_runner.py` plan-aware 패치 (section.duration_sec 우선)
- `parksy_actor/orchestrator.py` Editor wire
- `parksy_actor/session_modes/__init__.py` 3단계 capability matrix + canonical default
- `mcp_server_sse.py` 5 MCP 툴 노출 (render/compile/scout/capability_matrix/list)

**결정:**
- 매직 넘버 7개 제거 → 1차 변수 4개 (박씨 비전 "15분 RPM 최적" 인코딩)
- Compiler/Performer/Editor 책임 분리 (시간축 충돌 해결)
- Claude vision scout wire up (Perplexity "scout 격하" 거부)
- final mux `-t target_duration` 강제 cap (Editor 진실 소스)

**결과 (수치):**
- v14: target 900s = actual 900s 정확 일치 ✅
- 51 actions / 0 fail / 6 chapters / 19MB
- Telegram msg 754~765 (12개 mp4 송출)
- 매직 넘버 7개 → 0개 (변수화 완성)

**교훈:**
- 박씨 1차 비전을 매 결정에 검증 필수. v2.0까지 7번 커밋 동안 잊은 게 Junior 패턴.
- Layer 분리 안 하면 시간축 충돌. v3.0 박씨 메타 진단 결정적.
- dead wire 격하 ≠ 솔루션. wire up이 박씨 의도.

**재구축 힌트:**
1. `git clone github.com/dtslib1979/parksy-actor` (HEAD = 751acb0)
2. `python3 -m playwright install chromium`
3. `which claude` 확인 (필수)
4. `python3 mcp_server_sse.py &` → :8012 LISTEN
5. compile_timeline + render_async 테스트 (target_duration 일치 확인)
6. 상세: `parksy-actor/docs/DEV_LOG.md`

---
