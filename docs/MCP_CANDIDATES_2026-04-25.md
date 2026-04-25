# 박씨 MCP 후보 리스트 — Railway/HF 업로드 가능 (2026-04-25)

## 한 줄 평가
박씨 자산으로 진짜 만들 수 있는 MCP 9개 발견. P0 3개는 코드 80%+ 완성 상태로, 1주 내 Railway/HF 라이브 가능.

## 우선순위 매트릭스

| 순위 | MCP 이름 | 종류 | 호스팅 | 활용도 | 난이도 | 박씨 일상 활용 |
|:--:|---|---|:--:|:--:|:--:|---|
| P0-1 | papyrus-publish-mcp | 멀티 플랫폼 출판 래퍼 | Railway | 10/10 | 낮음 | 매일 — 4계정 YT/3계정 Naver/Tistory/Telegram 자동 출판 |
| P0-2 | alexandria-therapy-mcp | 정신분석 엔진 SSE | Railway | 9/10 | 낮음 | 매일 — 5-Lane 어디서든 박씨 셀프 코칭 호출 |
| P0-3 | parksy-ko-diffsinger-v1 | 성우 모델 저장소 | HF | 9/10 | 매우 낮음 | 모델 영구 백업 + Vast.ai pull 출처 |
| P1-1 | eae-mcp-writer-railway | 박씨 스타일 텍스트 필터 | Railway | 9/10 | 중 | 매일 — 모든 글 톤 변환, EAE FAB 라이트 |
| P1-2 | parksy-logs-search-mcp | 99 메모리 + 대화 로그 검색 | Railway | 9/10 | 낮음 | 매 세션 — 메모리 SSOT, 펜딩 16건 추적 |
| P1-3 | perplexity-episode-mcp | Body/Butterfly 리서치 호출 | Railway | 8/10 | 중 | 주 5회 — 리서치 자동화, papyrus-publish 연결 |
| P1-4 | vastai-control-mcp | 인스턴스 launch/terminate | Railway | 8/10 | 중 | 주 2~3회 — 폰/탭에서 GPU 토글 |
| P2-1 | parksy-ddsp-bassoon | DDSP 바순 모델 저장소 | HF | 6/10 | 매우 낮음 | 음악 작업 시 — VSCO-2 보조 |
| P2-2 | orbitprompt-phl-mcp | PHL 인터랙티브 제너레이터 | Railway | 7/10 | 중 | 주 2회 — 메타 프롬프트 생성 |

## P0 후보 (즉시 착수, 1주 내)

### 1. papyrus-publish-mcp (P0-1)
- **무엇**: article JSON을 받아서 Naver(3계정)/Tistory/Telegram(2봇)/YouTube desc(4계정)에 자동 출판하는 MCP. 박씨 6단계 진화의 핵심 — "원자재 → 워크센터 통과 → 자동 출하"의 마지막 워크센터.
- **재사용 자산**:
  - `~/dtslib-papyrus/tools/youtube/auth.cjs, export.cjs` (OAuth 완성)
  - `~/dtslib-papyrus/tools/naver/login.cjs, post.cjs` (ncaptcha 완성)
  - `~/dtslib-papyrus/tools/tistory/login.py, post.py` (완성)
  - `~/parksy-audio/local-agent/telegram_notify.py` (운영 중)
  - `~/dtslib-papyrus/eae_mcp_platform.py` (현존 — 리팩 대상)
- **호스팅**: Railway (CPU only — subprocess로 기존 도구 호출). YouTube/Naver Playwright는 stdio 로컬 fallback 유지 (헌법 제3분류).
- **3레이어**: tools=`publish_naver/publish_tistory/publish_telegram/publish_youtube_desc` / handlers=`subprocess.run(tools/...)` / services=Alexandria 동시성 헬퍼 복제 (UUID + FileLock)
- **박씨 일상 활용**: 매일 — perplexity-episode-mcp + eae-mcp-writer 결과를 한 번에 멀티 출판
- **헌법 위반 검증**: 0건 (CPU only, sklearn tier 미만, $5 한도 안)
- **개발 시간**: 6~8시간 (OPS 자율 + 박씨 게이트 2회: API 키 주입, 첫 게시 검증)
- **메모리 출처**: `project_perplexity_publish_mcp.md` (이 작업 다음 세션 착수 명시), `feedback_mcp_development_law.md` 로드맵 #2~#4 흡수
- **블로커 해소**: project_railway_502_pending.md 교훈 적용 → uvicorn host 0.0.0.0 + EXPOSE 명시 + /health 라우트 + Dockerfile 간결

### 2. alexandria-therapy-mcp (P0-2)
- **무엇**: stdio 완성된 alex_mcp/server.py를 SSE로 전환해서 Railway 배포. 박씨가 폰/탭/외부 PC 어디서든 본인 정신분석 엔진 호출.
- **재사용 자산**:
  - `~/alexandria-sanctuary/alex_mcp/server.py` (stdio 완성)
  - `~/alexandria-sanctuary/alex_mcp/core/concurrency.py` (3종 세트 헬퍼, 다른 MCP의 템플릿)
  - plugs/, rules/, prompts/, llm/, safety/ 전부 운영 중
- **호스팅**: Railway. 헌법 예외 명시 — `feedback_no_cloud_server.md` 2026-04-24 개정에 "alexandria-therapy MCP는 Railway 허용"
- **3레이어**: 이미 alexandria가 표준 템플릿 그 자체 — server_http.py만 추가
- **박씨 일상 활용**: 매일. 5-Lane 멀티디바이스 접근 + 박씨 28레포 중 유일한 실제 앱 백업
- **헌법 위반 검증**: 0건 (예외 명시됨)
- **개발 시간**: 3~4시간 (server_http.py SSE 래퍼 + Railway 배포 + .mcp.json 발급)
- **메모리 출처**: `project_alexandria_mcp_railway.md`

### 3. parksy-ko-diffsinger-v1 (HF, P0-3)
- **무엇**: 박씨 한국어 성우 DiffSinger v1 모델 + DDSP 바순 모델을 HF에 영구 저장. PC가 죽어도 모델은 살아있고, 다음 Vast.ai Pod이 HF에서 pull.
- **재사용 자산**:
  - `~/parksy-audio/PARKSY_DS/export/parksy_ko_v1.onnx` (319MB)
  - `dsconfig.yaml`, `dictionary-ko.txt`, `parksy_ko_v1.phonemes.json`, `parksy_ko_v1.languages.json`
  - `~/parksy-audio/instrument_models/ddsp_bassoon/ddsp_bassoon_final.pt` (25MB)
- **호스팅**: HuggingFace (모델 창고, Inference 없음)
- **박씨 일상 활용**: 인프라 베이스. 이게 있어야 그 위에 inference MCP를 얹을 수 있음.
- **헌법 위반 검증**: 0건
- **개발 시간**: 30분 (huggingface-cli login + upload, 박씨 토큰 1회 입력 필요)
- **메모리 출처**: `project_voice_model_hf_upload_pending.md`
- **블로커**: huggingface-cli login (박씨 토큰 1회 입력)

## P1 후보 (이번 달 내)

### 4. eae-mcp-writer-railway (P1-1)
- **무엇**: 박씨 말투 필터 텍스트 변환 MCP. 입력 텍스트 + STYLE_PARAMS → 박씨 톤 출력.
- **재사용 자산**:
  - `~/dtslib-papyrus/eae_mcp_writer.py` (Railway 502 펜딩 중)
  - `~/parksy-logs/finetune/parksy_writer.py` (Claude CLI 엔진 운영 중)
  - `filters/parksy_voice_filter.md`, `filters/parksy_v3_300.jsonl`
- **호스팅**: Railway (Claude API 호출만, GPU 불필요)
- **3레이어**: tools=`rewrite_parksy(text, mode)` / handlers=Claude API + filter / services=jsonl 인덱스
- **박씨 일상 활용**: 매일. perplexity-episode-mcp 출력 → 이거 통과 → papyrus-publish-mcp
- **헌법 위반 검증**: 0건. Claude API는 사용자 본인 키. Park-LoRA 언어층은 P3 이후 (RunPod GPU).
- **개발 시간**: 4~6시간 (502 진단 후 SSE 전환 + 필터 정합)
- **메모리 출처**: `project_author_as_mcp.md`, `project_eae_mcp_architecture.md`, `project_railway_502_pending.md` (블로커)

### 5. parksy-logs-search-mcp (P1-2)
- **무엇**: 99건 메모리 + parksy-logs 대화 + 펜딩 16건을 sentence-transformers로 인덱스해서 시맨틱 검색하는 MCP. 박씨 "어디 메모리에 있더라" 즉시 해소.
- **재사용 자산**:
  - `~/.claude/projects/-home-dtsli/memory/*.md` (99건)
  - `~/parksy-logs/` 대화 로그 원석
  - sentence-transformers (sklearn-tier, Railway OK)
- **호스팅**: Railway. PyTorch 미사용 (sentence-transformers는 ONNX 변환 가능 또는 CPU 추론).
- **3레이어**: tools=`search_memory(query, k=5)`, `list_pending()` / handlers=embedding + cosine / services=메모리 watcher (재인덱스 cron)
- **박씨 일상 활용**: 매 세션 — 헬스체크 후 자동 호출해서 "오늘 펜딩 뭐?" 답변
- **헌법 위반 검증**: 0건. PyTorch 무거우면 onnxruntime-cpu로 변환.
- **개발 시간**: 5~7시간
- **메모리 출처**: `project_author_as_mcp.md` Layer 1 지식층 청사진과 정확히 일치

### 6. perplexity-episode-mcp (P1-3)
- **무엇**: Body/Butterfly 16-Space 파이프라인을 MCP tool로 노출. `run_episode(domain, thesis, ticker)` → article artifact 반환.
- **재사용 자산**:
  - `~/parksy-logs/perplexity/episode_runner.py` (✅ demo 검증)
  - `~/parksy-logs/perplexity/call_space.py` (Playwright + 쿠키 세션)
  - `spaces_config.json` (16 Space slug)
- **호스팅**: Railway는 Playwright headful 불가 → **로컬 stdio MCP** (헌법 제3분류). MCP 클라이언트 호출 시 로컬 PC에서 실행. Railway에는 article_writer.py만 (DB 쿼리).
- **3레이어**: tools=`run_episode/get_episode/list_episodes` / handlers=episode_runner.py wrap / services=SQLite (D드라이브 symlink)
- **박씨 일상 활용**: 주 5회. 출력 → eae-mcp-writer → papyrus-publish-mcp 체인
- **헌법 위반 검증**: 0건. Playwright 부분만 로컬 stdio (이미 헌법 분류됨)
- **개발 시간**: 4~5시간 (episode_runner를 MCP로 래핑 + DB 쿼리 tool)
- **메모리 출처**: `project_perplexity_mcp_reminder.md`, `project_perplexity_publish_mcp.md`

### 7. vastai-control-mcp (P1-4)
- **무엇**: 폰/탭에서 Vast.ai 인스턴스 launch/terminate/status 호출. GPU 작업 시작/종료를 자연어 한 줄로.
- **재사용 자산**: `vastai` CLI + `~/.config/vastai/vast_api_key`
- **호스팅**: Railway. CPU only, vastai CLI subprocess만.
- **3레이어**: tools=`launch_template/terminate/list_instances/get_logs` / handlers=vastai subprocess / services=FileLock per-instance
- **박씨 일상 활용**: 주 2~3회 (DiffSinger 학습, FLUX 배치 등)
- **헌법 위반 검증**: 0건. 과금 호출이지만 GPU는 헌법 자율 실행 범위 명시.
- **개발 시간**: 3~4시간
- **메모리 출처**: `feedback_mcp_development_law.md` 로드맵 #5

## P2 후보 (다음 달 이후)

### 8. parksy-ddsp-bassoon (HF, P2-1)
- **무엇**: ddsp_bassoon_final.pt 25MB 단독 HF 저장. P0-3과 묶어 동시 업로드 가능.
- **호스팅**: HF
- **개발 시간**: 10분 (P0-3 작업에 합칠 수 있음)
- **메모리 출처**: `project_voice_model_hf_upload_pending.md`

### 9. orbitprompt-phl-mcp (P2-2)
- **무엇**: PHL 페이지를 인터랙티브 프롬프트 제너레이터로 전환 — 모듈/상황 입력 → Claude Code 붙여넣기 프롬프트 출력
- **재사용 자산**: `~/OrbitPrompt/` PHL 페이지 + 박씨 메타 프롬프트 라이브러리
- **호스팅**: Railway (또는 GitHub Pages 정적 + Railway MCP 백엔드)
- **개발 시간**: 6~8시간 (재정의 직후 작업, 우선순위 낮음)
- **메모리 출처**: `project_orbitprompt_redefinition.md`

## 폐기 (왜 안 만드는지 명시)

- **TTS narration MCP (Edge TTS 래퍼)**: TTS 기능은 dispatcher.py 안에서 작동 중. 별도 MCP화 가치 낮음. parksy-audio 내부 함수로 충분.
- **GPT-SoVITS inference MCP**: 박씨 v1 발음 어눌 — 현재 라이브 운영 안 함. v3 재학습 후 P3 이상으로.
- **Park-LoRA 언어층 MCP**: PyTorch 7B = Railway 한도 초과. RunPod Serverless 필요. v3 모델 미완성으로 펜딩.
- **15채널 YouTube 업로드 MCP**: papyrus-publish-mcp(P0-1)에 youtube_desc tool로 흡수. 별개 MCP 불필요.
- **DiffSinger inference Railway MCP**: 319MB ONNX 추론도 Railway $5 한도 위험. HF Inference Endpoint(유료) 또는 Vast.ai 전환 필요. 현 시점 펜딩.
- **Discord MCP**: `project_orbitprompt_redefinition.md`에서 "지금은 불필요" 명시.
- **APK/PWA MCP**: `project_fab_compute_architecture.md`에서 폐기 결정. Railway MCP가 대체.

## Railway vs HF 분배

| Railway (MCP 서버) | HuggingFace (모델 창고) |
|---|---|
| **P0-1 papyrus-publish-mcp** (subprocess + Playwright stdio fallback) | **P0-3 parksy-ko-diffsinger-v1** (319MB ONNX) |
| **P0-2 alexandria-therapy-mcp** (rules engine, Claude API 사용자 키) | **P2-1 parksy-ddsp-bassoon** (25MB pt) |
| **P1-1 eae-mcp-writer** (Claude API 호출) | (장래) Park-LoRA Qwen2.5-7B (Vast.ai/RunPod 학습 → HF 저장 → RunPod Serverless 추론) |
| **P1-2 parksy-logs-search** (sentence-transformers ONNX-CPU) | |
| **P1-3 perplexity-episode** (DB 쿼리만, Playwright는 로컬 stdio) | |
| **P1-4 vastai-control** (CLI subprocess) | |
| **P2-2 orbitprompt-phl** (정적 + 백엔드) | |

**Railway 한도 정합**:
- 전부 sklearn-tier 이하 또는 외부 API 호출 (Claude API 키는 사용자 본인 부담)
- PyTorch GPU 의존 작업은 Vast.ai/RunPod 일회성 호출로 우회 (vastai-control-mcp가 매개)
- $5 Hobby 안에서 7개 MCP 동시 호스팅 가능 (idle 0 과금)

## 박씨 첫 액션 1줄

"AD 모드 발동. P0-3 (HF 업로드 30분) → P0-2 (Alexandria SSE 4시간) → P0-1 (papyrus-publish-mcp 8시간) 순서로 1주 스프린트 시작. huggingface-cli login 토큰 1회 입력해줘."
