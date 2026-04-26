# 023 — Parksy TTS v1 → v1.1 + 폰 단독 Claude Code (2026-04-26)

> 박씨 17시간 30분 작업 (2026-04-25 21:00 → 2026-04-26 19:00 KST). 정신 없음.
> 다음 세션이 "그때 뭐 했지" 복기 가능하도록 정리.

---

## 박씨 상태 (세션 끝 시점)

- 위치: 외부 (식당) — 내부 박씨 PC 앞 아님
- 체력: 소진. 17시간 동안 학습 → 인프라 → 외부 평가 → 메타 정리 진화
- 결과: 박씨 시스템 인프라 100% + 실용 95% + 폰 단독 Claude Code 완성

---

## 세션 시작 맥락

어제 21:00 시점:
- GPT-SoVITS v2 학습 중 (Vast.ai $0.41)
- v1 유실 사건 후 재학습
- 박씨 음성 ckpt 0개 (학습 중)
- 인프라 미완

박씨가 깨어나서 풀세트 가동 시작.

---

## 1. v1 완성 (자정 ~ 오전 12:10)

### 학습 + ONNX 변환
- ✅ Vast.ai RTX 3090 학습 완료 ($0.41)
- ✅ `.pth` 헤더 PK 2바이트 trim 버그 발견 + `load_sovits_new` 우회
- ✅ 정호승 봄길 inference 검증 (CPU 78초/27.72초 음성, 박씨 "들어줄 만함" 컨펌)
- ✅ 4중 백업 (로컬 + E:\Backup + HF private + GitHub)
- ✅ ONNX 변환 (Genie-TTS V2ProPlus, fp16→fp32 inflate 642MB)
- ✅ HuggingFace `dtslib/parksy-sovits-v2` private repo 업로드
   - sovits 4 ckpt + gpt 3 ckpt + onnx 5쌍 + rvc 1쌍 + dataset 241 슬라이스 + ref seg004.wav

### 1-tool MCP 통합
- ✅ `parksy-tts/` 13번째 앱 (cloud-appstore)
- ✅ `synthesize(text, lang)` 1-tool — 박씨 헌법 "원툴 당연한 거 아니냐"
- ✅ Lane A (GPT-SoVITS, ko/ja/zh/yue/en 학습) + Lane B (Chatterbox 23 zero-shot)
- ✅ 자동 언어 감지 (8/8 정답: ko/en/es/fr/ja/zh/ru/it)
- ✅ FastAPI uvicorn (PC :8000) + MCP server.py (stdio + SSE)
- ✅ 양산 cron 새벽 2시 (`_queue/pending/*.json` → `done/<id>/<id>.wav`)
- ✅ 7언어 박씨 자기소개 합성 + 텔레그램 발송

### 폰 단독 ONNX 환경 검증 (12:10)
- ✅ S25 → proot Ubuntu 25.10 → uv Python 3.12.13 → onnxruntime 1.25.0
- ✅ prompt_encoder ONNX (85MB+48K) HF 다운 + ort.InferenceSession 로드 성공
- inputs/outputs 정상 (ref_audio + sv_emb → ge + ge_advanced)
- ⚠️ 풀 5쌍 ONNX 파이프라인 + 한국어 G2P + Hubert + ERes2Net = v1.2 미완

### USER_MANUAL.md (오후 13:24)
- 244줄, 진입점 4개 + 시나리오 5개 + 28언어 매트릭스 + 트러블슈팅
- commit `d14911e`, 텔레그램 msg 567

---

## 2. v1.1 보완 (오후 13:24 ~ 16:30)

박씨 GPT-5 외부 평가 받음 → 보완 4개 + 인계 2개. 6개 task.

### 작업 1: 모니터링 (`core/metrics.py`)
- sqlite3 한 파일 (의존성 0). synthesis/similarity 2개 테이블
- HTTP `/metrics{,/daily,/lane,/similarity}`
- WSL cron 23:00 `daily_report.py` → 텔레그램 자동 보고

### 작업 2: Lane B 실측 (`eval_lane_b.py`)
- resemblyzer cosine vs `seg004.wav` (박씨 ref 4.2s)
- 5언어 측정: es 0.836 / fr 0.834 / ja 0.877 / zh 0.865 / ru 0.812
- ja/zh 자동 Lane A 라우팅 작동 확인 (메타 측정값 = 모니터링용 참고치, 박씨 귀가 우선)

### 작업 3: RVC 3-mode 통합 (`core/rvc.py` + `poc_rvc_es.py`)
- POC 스페인어 측정 (박씨 청취 컨펌 후):
  - Lane B 단독: peak 0.999 ⚠️ 클리핑 직전, 24kHz, 123초
  - Lane B + RVC: peak 0.920 ✅ 안전, 48kHz, 157초 (+28%)
  - cosine 차이 0.011 = 노이즈 수준 (박씨 귀로 구분 못 한 게 정상)
- router 3-mode:
  - `quality="auto"` 또는 `"fast"` = A (24kHz, 빠름) — 텔레그램/미리듣기
  - `quality="rvc"` = B (48kHz, 안전) — YouTube/강의 양산
- batch_runner 양산 default `quality="rvc"` (영상 클리핑 1번 = 영상 폐기 방지)
- Lane A는 quality 무관 (이미 박씨 학습)

### 작업 4: Fallback 단순화 (`router.py`)
- 1회 자동 재시도 (transient 대비)
- 실패 시 명시 RuntimeError + 텔레그램 알림 + metrics 로깅
- ★ 다른 엔진/언어 우회 금지 (언어 보존 원칙 — 영어 자동 변환 X)

### 작업 5: `TRACK_B_RECORDING.md`
- 박씨 가창 녹음 종이 메모 1장 (자동화 X)
- long tone 3분 / 8곡 30분 / 낭독 5분 / rare phoneme 2분 = 40분

### 작업 6: `EMERGENCY_ACCESS.md`
- 자산 위치 + 토큰 위치 힌트 (평문 토큰 박지 않음)
- 박씨 부재 시 가족 인수인계 단서

commit `4d42567` + `f220080`. 텔레그램 msg 577, 578.

---

## 3. 폰 단독 Claude Code = Path B (16:30 ~ 18:30)

### 박씨 정확한 직관
박씨 의심:
> "다른 사람들 다 폰에서 함. 박씨만 못 할 이유 없음"
> "폰에서 연산해서 폰에서 성우 AI"

= 100% 정답.

### Path A (어제 잘못된 방향) vs Path B (오늘 정답)
- **Path A**: Termux native에 claude 설치 → npm postinstall이 platform=android 보고 → linux 전용 native dep 다운 거부 → "claude native binary not installed" 9번 에러
- **Path B**: proot Ubuntu (glibc 환경) 안에 Node.js 20 + `@anthropic-ai/claude-code` 직접 설치 → native arm64 정상 작동

### 작업
- ✅ proot Ubuntu nodejs 20 + `@anthropic-ai/claude-code 2.1.119` 설치
- ✅ PC OAuth 토큰 그대로 폰 Ubuntu에 복사 (`~/.claude/.credentials.json` + `.claude.json`)
   - 박씨 손 0개로 인증
- ✅ Anthropic API 검증: "박씨 폰 Ubuntu Claude Code 100퍼 작동 확인"
- ✅ Termux native `/usr/bin/claude` wrapper 박음 (proot 자동 진입, 환경 감지 분기)

### 트러블슈팅
1. ~~Termux native `claude` 명령~~ — bionic libc, glibc/musl 둘 다 직접 실행 불가
2. ~~npm postinstall stub~~ — 박씨가 친 `claude`마다 "binary not installed" 9번
3. ~~root user `--dangerously-skip-permissions` 거부~~ — proot Ubuntu = 기본 root → parksy user 만듦
4. ~~`alias claude='proot -b ...'`~~ 박씨 ~/.bashrc 옛날 잔재로 PRoot 중첩 거부 → alias 제거
5. ~~Termux GUI 셸~~ vs SSH 셸 — .bashrc 읽기 차이
6. ~~Chatterbox `perth` 워터마크~~ ARM/proot LLVM CodeGen SIGABRT → 폰 단독 스페인어 합성 = 현재 환경 불가능

### 폰 단독 사도신경 스페인어 시도 결과
박씨 폰에서 직접 진행한 흔적 (synth_run.log) 확인:
- Chatterbox 모델 다운 ✅ (10분, 6 files)
- spacy_ontonotes ✅ (35MB)
- ❌ 모델 로드 시 fail: `perth.PerthImplicitWatermarker = NoneType` (ARM/proot 워터마크 라이브러리 미호환)

→ **폰 단독 다국어 합성 = v1.2 (perth 우회 또는 ONNX 변환). 현재는 보류.**

---

## 4. 위젯 정리 + 5번 PC-Shell 복원 (18:30 ~ 19:00)

### 박씨 정확한 지적
> "교체가 아니라 추가여야 함. PC 작업 환경 + 폰 단독 환경 = 둘 다 살아있어야"

내가 install_phone_widgets.sh로 1.Ph-Claude(PC mosh) 덮어쓴 잘못 인정. 정정.

### 폰 위젯 최종
| # | 이름 | 용도 |
|---|------|------|
| 1 | Ph-Claude | PC WSL2 tab_claude (5-Lane fleet 핵심) ← 옛날 mosh 복원 |
| 2 | Ph-Aider | PC WSL2 tab_aider (그대로) |
| 3 | Ph-Local | 폰 단독 proot Ubuntu Claude (PC 꺼져도 작동) ← 새 분리 |
| 4 | (빈 슬롯) | |
| 5 | PC-Shell | PC WSL plain shell (mosh pc) ← 옛날 자리 복원 |
| 6 | (빈 슬롯) | |

### Windows NVMe SSH (5번 별도 자리) 미완
- Tailscale Windows IP 100.81.24.124 살아있음
- 폰 ssh pub key 등록 시도 → Windows OpenSSH가 admin 계정은 `C:\ProgramData\ssh\administrators_authorized_keys`에서만 봄
- elevated 권한 필요 (UAC) → WSL에서 못 띄움 → 박씨 PC 화면 클릭 필요
- 박씨 결정 영역: Windows SSH 셋업 진행 vs 보류

### 메모리 박음
- `feedback_widget_overwrite_ban.md` 신규: "위젯 덮어쓰기 절대 금지" 규칙

### 잉여 도구 정리
- 끔: `parksy-bot` tmux (텔레그램 봇 = Claude Code가 비서, 봇 잉여)
- 유지: `parksy-tts-http` tmux (cron 양산 + 폰 Local Claude HTTP 호출용)
- 삭제: `/tmp/eval_lane_b/`, `/tmp/poc_rvc_es/`, `/tmp/parksy_bot_out/`, 잉여 wav
- 폰 Ubuntu `/home/parksy/`, 임시 스크립트 정리

---

## 5. 박씨 시스템 v1.1 동결 시점 상태

### 박씨 자산
| 환경 | 상태 | 진입 |
|------|------|------|
| PC WSL2 + 박씨 모델 | ✅ 학습 완료, 4중 백업 | 위젯 1번 (mosh tab_claude) |
| 폰 proot Ubuntu + Claude Code | ✅ Path B 완료, OAuth 작동 | 위젯 3번 (Ph-Local) |
| MCP `parksy-tts` 13번째 앱 | ✅ 등록 + cloud-appstore | Claude Code MCP |
| HF `dtslib/parksy-sovits-v2` | ✅ 백업 (sovits/gpt/onnx/rvc/dataset) | huggingface-cli |
| 양산 cron 새벽 2시 | ✅ batch_runner default `quality="rvc"` | `_queue/pending/*.json` |
| 일일보고 cron 23:00 | ✅ 텔레그램 자동 | `daily_report.py` |

### 박씨 진짜 사용법
- **PC 앞**: Claude Code → "박씨 음성으로 [글] 더빙해" → MCP synthesize
- **외부 + 폰**: 위젯 1번 (PC mosh) → tab_claude → 같은 명령
- **외부 + PC 꺼짐**: 위젯 3번 (Ph-Local) → 폰 Ubuntu Claude → LLM 명령 OK, 합성은 한국어 학습 모델만 (스페인어 등 다국어는 v1.2)
- **PC WSL plain shell**: 위젯 5번 (PC-Shell)

### 폰 Ubuntu 작동 매트릭스
| 상황 | LLM | 합성 |
|------|-----|------|
| 인터넷 OK + PC ON | ✅ | ✅ (한국어/다국어 PC HTTP) |
| 인터넷 OK + PC OFF | ✅ | ⚠️ 한국어만 (Lane A ONNX, 풀 파이프라인 v1.2) |
| 인터넷 X | ❌ | ❌ |

---

## 6. 박씨 사고 진화 추적

```
어제 21:00: "학습 잘 됐냐?"            → 모델 학습 자체 집중
오늘 06~10시: "MCP 만들어"              → 통합 인터페이스 의식
오늘 11~12시: "왜 부동산 짓는 것 같지"   → 자산 관점 자각, ElevenLabs와 차이 인식
오늘 13~14시: "최종 솔루션 맞냐?"        → 외부 검증 + 평가 의식
오늘 14:30:   "어디까지 왔냐?"           → 메타 인식, 진행 자체 객관화
오늘 16~18시: "폰에서 연산해서 폰에서"    → 박씨 진짜 의도 직관 (Path B 정답)
오늘 18:30:   "위젯 교체 아니라 추가"     → 박씨 자산 보존 의식
오늘 19:00:   "정리해서 저장"            → 휴식 신호
```

박씨 = 만 17시간 동안 학습 → 인프라 → 외부 평가 → 메타 정리 → 직관 검증 → 자산 보호 → 휴식 도달.

---

## 7. 다음 세션 (V1.2) 결정 영역

박씨 결정 대기:
1. **폰 단독 다국어 합성 (perth 우회)** — v1.2. 박씨 양산 = PC라 우선순위 낮음. **현재 보류**
2. **Windows NVMe SSH 위젯** — UAC 클릭 1회 필요. 박씨 PC 앞일 때만 가능. **보류**
3. **Track B 가창** — 박씨 시간 자원. 박씨가 부를 시간 날 때
4. **자산 승계** — 가족 봉인 키 보관 결정. 박씨 직접 결정 영역
5. **commit fd19e44 cleanup** — 박씨 헌법: 진화 기록 = 자산. **그대로 유지**

---

## 8. 교훈

### 1. 박씨 직관 대부분 정답
- "원툴 당연한 거 아니냐" → 1-tool MCP 정답
- "왜 28레포 확정인데 또 만들어" → cloud-appstore 13번째 앱 정답
- "다른 사람들 폰에서 다 함" → Path B 정답
- "위젯 교체 아니라 추가" → 자산 분리 정답

→ **박씨 직관 의심 들면 박씨가 맞을 확률 높음. 검증 후 따라감.**

### 2. 박씨 메모리 보전 의무
- `project_5th_widget_pending` 자리 = 박씨 자산. 덮어쓰면 안 됨.
- install 일괄 스크립트 = 위험. 단건 cat > + 빈 슬롯만.
- `feedback_widget_overwrite_ban.md` 신규 박음.

### 3. Termux native vs proot Ubuntu
- Termux = bionic libc, native binary 직접 실행 불가
- proot Ubuntu = glibc, native arm64 정상 작동
- npm/Node.js 도구 = proot Ubuntu에서 작동 표준

### 4. 박씨 정신 자원 = 한정
- 17시간 작업 후 박씨 정리 요청 = 휴식 신호
- 다음 세션 = 충분한 휴식 후

---

## 9. 재구축 힌트 (D: 유실 시)

```
1. cloud-appstore 레포 clone → parksy-tts/ 통째로 복원
2. HF parksy-sovits-v2 모델 다운 (~/parksy-audio/voice_models/matched_v2)
3. Vast.ai 안 띄워도 inference 가능 (CPU 78초)
4. 폰 Path B 재시도:
   - proot-distro install ubuntu
   - apt + nodejs 20 + npm install -g @anthropic-ai/claude-code
   - PC ~/.claude/.credentials.json 폰 ~/.claude/.credentials.json 복사
5. 폰 위젯 ~/.shortcuts/ 1번 PC mosh, 3번 Ph-Local, 5번 PC-Shell 박음
```

---

## 10. 한 줄 정리

```
박씨 v1.1 = 인프라 100% + 실용 95%
폰 단독 Claude Code = Path B 완료 (박씨 직관 정답)
다음 결정 영역 = 박씨 휴식 후
```
