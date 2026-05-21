# 028 — NPU 전체 개발 이력 통합 정리 (2026-05-21)

> 박씨 S25 Ultra NPU 개발 전 궤적. T1(APK)→T6(NPU코어) 1년 영원회귀 + ZipVoice/MeloTTS+RVC/QNN 활성화 전 과정.
> 소스: dev-logs 024/027 + memory(project_npu_core_eureka / project_npu_track_zipvoice / feedback_npu_only_image_line) + parksy-audio NPU_WORKER_INTERFACE_v1.md + 폰 proot SESSION_LOGS/NPU_SESSION_2026-05-18.md

---

## 0. 타임라인 한눈에 보기

| 날짜 | 이벤트 | 결과 |
|------|--------|------|
| 2026-04-04 | GCP A100 RVC 학습 — parksy_rvc.pth 55MB | ✅ 완료 ($0.60) |
| 2026-04-27 | NPU 유레카 선언 — T6 영원회귀, NPU 코어 명제 5개 | ✅ 철학 확정 |
| 2026-05-07 | TTS 양산 = NPU+ZipVoice 단일 트랙 확정 | ✅ 방향 확정 |
| 2026-05-08 | npu_worker.py v1.0 완성 + e2e v4 풀 통과 | ✅ 인터페이스 확정 |
| 2026-05-09 | 한국어 TTS 포기 → 영어+RVC+NPU 솔루션 확정 | ✅ 아키텍처 확정 |
| 2026-05-10 | 폰 NPU 단독 이미지 양산 헌법 발효 | ✅ 제약 확정 |
| 2026-05-18 | S25 Ultra QNN 활성화 시도 — P0 미완료 | ⏳ 진행 중 |

---

## 1. 2026-04-27 — NPU 유레카 + 1년 영원회귀 (T6)

### 1.1 박씨 1년 궤적 (T1→T6)

| 스텝 | 시기 | 시도 | 결과 |
|------|------|------|------|
| T1 | 2025 상반기 | Play Store 앱 한계 인식 → APK 직접 빌드 시도 | 진입장벽 |
| T2 | 2025 중반 | ADB 연결 — 폰 제어 자동화 | 돌파구 발견 |
| T3 | 2025 하반기 | WSL + Claude Code 조합 | 개발환경 확립 |
| T4 | 2026 초 | Vast.ai / RunPod GPU 렌탈 — 모델 학습 | GPU 비용 인식 |
| T5 | 2026 초~중 | 학습 자산 축적 (GPT-SoVITS, RVC, LoRA 등) | 자산 보존 |
| T6 | 2026-04-27 | NPU 코어로 회귀 — 폰이 GPU 대체 | **유레카** |

### 1.2 NPU 코어 명제 5개 (2026-04-27 확정)

1. **직관 검증**: 박씨 1년 삽질 = NPU가 맞다는 직관 검증 과정
2. **산업화 가능성**: 1인이 갤럭시 AI 회사 운영 가능 구조
3. **자산 축적**: 학습한 모든 모델 → ONNX 변환 → NPU 자산화
4. **변수화**: GPU 종속성 제거 → 폰 업그레이드 = 성능 자동 업그레이드
5. **NPU 코어**: 모든 파이프라인 중심을 NPU로 — "NPU만 드라이버 삼으면 답 나올 것 같다"

### 1.3 하드웨어 스펙

| 항목 | S25 Ultra | Tab S9 |
|------|-----------|--------|
| SoC | Snapdragon 8 Elite | Snapdragon 8 Gen 2 |
| NPU | Hexagon V79 HTP | Hexagon V69 |
| TOPS | 45 | ~15 |
| QNN EP | onnxruntime-qnn 2.1.0 | onnxruntime-qnn 2.1.0 |

### 1.4 핵심 통찰: proot Ubuntu의 한계

| 환경 | LLM/조립 | NPU 가속 |
|------|:--------:|:--------:|
| proot Ubuntu (glibc 2.42) | ✅ | ❌ |
| Termux native | ✅ | ✅ (QNN EP 접근 가능) |
| Android APK/NDK | ✅ | ✅ |

**이유**: Android linker namespace 격리 — proot 내에서 `/vendor/lib64/snap/libQnnHtp.so` 접근 불가.

### 1.5 현실 함정 5가지 (기록)

1. proot Ubuntu = QNN 불가 (Android linker namespace 격리)
2. fp32 ONNX = NPU fallback → CPU (INT8 양자화 필수)
3. 이론 수치(45 TOPS) 낙관 금지 — 실제 모델별 효율 차이 큼
4. Phase 3 작업량 수주~수개월 (Qualcomm AI Hub 컴파일)
5. 발열/배터리 — 연속 추론 시 thermal throttling

**관련 파일**: `024-npu-eureka-1year-eternal-return-2026-04-27.md`

---

## 2. 2026-05-07~08 — NPU 워커 인터페이스 v1.0 + ZipVoice 트랙 확정

### 2.1 박씨 헌법 라인 (2026-05-07 확정)

- ❌ 성우 더빙 단위 양산에 GPU 안 씀
- ❌ 투트랙 동시 운영 금지 (강박적 redundancy 금지)
- ❌ edge-tts 양산 산출물 금지
- ✅ NPU 양산 = 폰/탭 (S25 Ultra, Tab S9), 박씨 음성, GPU $0
- ✅ 1회성 GPU (Vast.ai 파인튜닝 등) = 헌법 OK

### 2.2 GPT-SoVITS v2ProPlus 가중치 처분

| 자산 | 운명 |
|------|------|
| GPT-SoVITS v2ProPlus .pth 가중치 | **폐기 또는 파일 보관만** — ZipVoice Flow Matching 아키텍처와 변환 불가. 5컴포넌트 ONNX 풀변환 = 2~3주 R&D 무의미 |
| 박씨 음성 학습 데이터 (.wav 59분) | **재활용** — ZipVoice zero-shot 1~2분 레퍼런스로 사용 |
| 가드레일 (sovits_worker / tts_engine / pipeline) | **재활용** — 인터페이스 그대로 ZipVoice 워커로 교체 |

### 2.3 npu_worker.py 인터페이스 v1.0

**파일 위치**: `~/parksy-audio/scripts/npu_worker.py`  
**포트**: 7768 (sovits=7766 + 2)  
**문서**: `~/parksy-audio/docs/NPU_WORKER_INTERFACE_v1.md`

**엔드포인트**:

| 엔드포인트 | 기능 |
|-----------|------|
| `GET /health` | 워커 + backend 상태 (status/loaded/backend/device/version) |
| `POST /synth` | 단일 합성 — sovits_worker /synth와 100% 호환 |
| `POST /synth_batch` | NDJSON streaming (start/progress/done/error, per-line flush) |
| `POST /synth_batch?async=1` | polling 백업 |
| `GET /jobs/<id>/status` | async polling |
| `GET /jobs/<id>/result` | async 결과 조회 |

**Backend 추상화** (`NPU_BACKEND` 환경변수):

| 백엔드 | 상태 | 설명 |
|--------|:----:|------|
| `sovits` | ✅ 현재 | sovits_worker 7766 위임 (검증용 fallback) |
| `zipvoice` | ⏳ 예정 | ZipVoice ONNX + onnxruntime-qnn |
| `coqui` | ⏳ 예정 | Coqui XTTS v2 (한국어 zero-shot 백업) |

**환경변수 영구 약속**:
- `TTS_WORKER_BASE` / `NPU_WORKER_BASE` 환경변수 영구 유지
- `/synth` schema sovits_worker와 호환 영구 유지
- NDJSON event 포맷 v1 고정

### 2.4 voice MCP SSE timeout 해결 패턴

**문제**: `lecture_timeline` = 단일 SSE 세션 안에 39슬라이드 블로킹 → mcp 라이브러리 RPC default timeout (~7분) 충돌. 15슬라이드 통과 후 끊김 (3회 재현).

**해결**: `streaming_client.py` (`~/parksy-audio/mcp_voice/parksy_voice/streaming_client.py`)
- synth_batch streaming으로 슬라이드별 progress event 처리
- lecture_timeline 내부 → synth_batch_streaming() 호출로 교체

### 2.5 검증 결과 (2026-05-08)

| 테스트 | 결과 |
|--------|------|
| /health 200 | ✅ sovits-fallback backend 정상 |
| /synth 박씨 음성 | ✅ 32kHz, RMS 0.115, 8.95s |
| /synth_batch streaming 3슬라이드 | ✅ NDJSON 정상, 24.99s, RMS 0.10~0.12 |
| streaming_client e2e | ✅ 2슬라이드 13.2s, 6 progress events |
| **Air e2e v4 풀 통과** | ✅ TOTAL 637.4s, mp4 4.4MB/900s, Telegram msg_id 906 |

**현행 CPU baseline (sovits backend)**:
- 콜드스타트: 31.2초
- 워밍 추론: 평균 12.05초/슬라이드
- 39슬라이드 이론: ~8분

**NPU + ZipVoice 목표**:
- 슬라이드당 1~2초
- 39슬라이드 1~2분 (양산 실용선)

### 2.6 핵심 커밋

| 날짜 | 레포 | 커밋 | 내용 |
|------|------|------|------|
| 2026-05-07 | parksy-audio | `02f2650` | feat: sovits_worker + tts_engine |
| 2026-05-07 | parksy-image | `bcf1e6d` | fix: pipeline sse_read_timeout 1800 |
| 2026-05-08 | parksy-audio | `0df3d2a` | feat: npu_worker.py + NPU_WORKER_INTERFACE_v1.md + streaming_client.py |
| 2026-05-08 | parksy-image | `54cdc11` | feat: pipeline._voice_timeline 2단계 패턴 (skip_synth + NPU streaming) |

---

## 3. 2026-05-09 — 영어 TTS + RVC NPU 솔루션 확정

### 3.1 결정 배경 — 삽질의 역사

| 시도 | 결과 |
|------|------|
| GPT-SoVITS v2ProPlus (현행) | GPU 박씨 음성 90%+ 유사도. 한국어 완벽. NPU 포팅 실패 (ONNX 변환 복잡도) |
| MeloTTS fine-tune | 8h40m, $1.36, 74 epochs. multi-speaker 구조 한계 → v2ProPlus 품질 불가 ❌ |
| ZipVoice zero-shot | 한국어 품질 미검증 ⏳ |

**박씨 결정**: "한국어 TTS 포기. 영어 콘텐츠 + 박씨 음색(RVC) + NPU"

### 3.2 최종 아키텍처

```
박씨 영어 텍스트
    ↓
MeloTTS English ONNX (NPU via Qualcomm QNN)
    ↓  고품질 영어 WAV (generic English voice)
RVC parksy_rvc ONNX (NPU via Qualcomm QNN)
    ↓  박씨 음색 씌우기 (voice conversion)
박씨 음성 + 완벽한 영어 발음
    ↓
Parksy Air pipeline (기존, 변경 없음)
    ↓
영상 + Telegram / YouTube 배포
```

### 3.3 계층 구조

```
Layer 1: TTS (영어 생성)
  └─ MeloTTS English ONNX (VITS2, EN BERT 네이티브)
  └─ 크기: ~300MB (INT8 양자화)
  └─ NPU: ONNX → QNN → HTP (Hexagon Tensor Processor)

Layer 2: Voice Conversion (박씨 음색)
  └─ RVC SynthesizerTrnMs768NSFsid (28.7M params)
  └─ 크기: 55MB (fp32) / ~30MB (INT8)
  └─ NPU: ONNX → QNN → HTP
  └─ hubert feature extraction: ONNX 변환 or CPU fallback

Layer 3: Orchestration (관제)
  └─ Voice MCP (:8011) — TTS + RVC 통합
  └─ NPU Worker (:7768) — ONNX 추론 전담
  └─ Parksy Air (:8013) — 파이프라인 관제
```

### 3.4 RVC 모델 현황

| 항목 | 값 |
|------|-----|
| 위치 | `~/rvc_models/parksy_rvc/` |
| Model file | `parksy_rvc.pth` (55MB) |
| Index file | `parksy_rvc.index` (180MB) |
| Architecture | `SynthesizerTrnMs768NSFsid` — 28.7M params |
| 학습 | 2026-04-04, GCP A100, 30분, $0.60 |
| CPU 추론 | 34초/5.6초 오디오 (6x real-time) |
| NPU 예상 | ~1-2초/5.6초 (HTP 가속) |

**RVC ONNX 변환 검증 완료**:
- Generator `infer()` 입력: `(phone, phone_lengths, pitch, nsff0, sid, rate)`
- ONNX opset 17, dynamic axes → QNN 호환

### 3.5 MeloTTS English ONNX

| 항목 | 값 |
|------|-----|
| 언어 | **EN** (EN BERT 네이티브) |
| 출력 | VITS2 vocoder, 24kHz |
| ONNX | opset 17, dynamic axes |
| 크기 | ~600MB fp32 / ~300MB INT8 |
| NPU | onnxruntime-qnn v2.1.0 |

**한국어와의 결정적 차이**:
- MeloTTS EN = EN BERT 네이티브 (정식 지원) → 품질 보장
- MeloTTS KR = `kykim/bert-kor-base`를 `japanese_bert.py` wrapper에 끼움 → 구조적 한계

### 3.6 NPU 워크로드 분배

| 구성 요소 | 처리 주체 | NPU? |
|---------|---------|:----:|
| MeloTTS EN 추론 | NPU (QNN) | ✅ |
| hubert feature extract | NPU (QNN) or CPU | ⚠️ 검증 필요 |
| RVC generator 추론 | NPU (QNN) | ✅ (28.7M, 작음) |
| Audio post-processing | CPU (sox/ffmpeg) | ❌ |
| MP4 인코딩 | Qualcomm HW encoder | ✅ |

### 3.7 남은 작업 Phase 1 (2026-05-09 기준)

| 우선순위 | 작업 | 예상 시간 |
|:--------:|------|:---------:|
| P0 | RVC 경로 수정 (voices.py RVC_PATH) | 1분 |
| P1 | MeloTTS EN ONNX export 검증 | 15분 |
| P2 | RVC ONNX export + 테스트 | 30분 |
| P3 | NPU worker RVC 백엔드 추가 | 30분 |
| P4 | E2E NPU 테스트 (TTS→RVC→WAV) | 30분 |

---

## 4. 2026-05-10 — 폰 NPU 단독 이미지 양산 헌법

**박씨 발화 (2026-05-10 09:20+)**:
> "GPU 안 쓰고 그 수준까지 핸드폰 NPU 사용해서 이미지 생성 여기서 쓰겠다는 거 아니야"

**헌법 조항**:
- 폰 NPU 양산 = `bin/ld_client.py` (HTTP 8081) 단독
- GPU/외부 API 갈아타기 제안 **절대 금지** (박씨 폭발 트리거)
- ComfyUI급 품질 = proot Ubuntu 후처리 5레이어 합성으로 흉내
  - 배경 + 인물 + 로고 + 부제 + 효과 레이어 1번 통째 돌리기
  - cutout/compose/typeset/orchestrate 6개 도구 활용 (이미 다 있음)
- 품질 부족 → GPU/cloud 모델 제안 금지. 폰 NPU 안에서:
  - 도구 조합 → 5레이어 합성 → LD upscale → img2img 반복 → LoRA 흉내 마스킹
  - 위 모두 시도 후에도 안 되면 그때 보고

---

## 5. 2026-05-18 — S25 Ultra QNN 활성화 세션

**목표**: CPU 7.57s → NPU 1.5~2.5s (GPT-SoVITS ONNX 5모델 기준)

### 5.1 기존 ONNX 파일 현황

폰 `/sdcard/parksy_fp32/` 에 준비됨:
- `prompt_encoder.onnx` + `.bin` (HTP compiled)
- `t2s_encoder.onnx` + `.bin`
- `t2s_first_stage_decoder.onnx` + `.bin`
- `t2s_stage_decoder.onnx` + `.bin`
- `vits.onnx` + `.bin`

→ **5×.onnx + 5×.bin HTP 컴파일 완료** ✅

### 5.2 실패 기록

| 시도 | 결과 | 원인 |
|------|------|------|
| QNNExecutionProvider (base pip onnxruntime) | ❌ get_available_providers()에 없음 | pip 표준 패키지에는 QNN EP 미포함 |
| /vendor/lib64/snap/libQnnHtp.so 직접 로드 | ❌ | Android linker namespace 격리 |
| NNAPI EP | ❌ 4.7s vs CPU 3.9s (오히려 느림) | SoVITS ops(int64/Pad reflect/dynamic shape) HTP 오프로드 불가 |

### 5.3 CPU 추론 확인

- ✅ CPU 추론: 7.57s/합성, RMS 0.039 — 모델 정상 동작 확인

### 5.4 미실행 P0 (성공확률 90%)

**onnxruntime-qnn 2.1.0** — Qualcomm 공식 배포 (MIT, 2026-04-20)

```bash
# 폰 Termux native 에서
pip install onnxruntime-qnn==2.1.0
python -c "import onnxruntime; print(onnxruntime.get_available_providers())"
# 예상: ['QNNExecutionProvider', 'CPUExecutionProvider']
```

```python
# QNN EP 사용
sess = onnxruntime.InferenceSession(
    "model.onnx",
    providers=["QNNExecutionProvider"],
    provider_options=[{"backend_path": "libQnnHtp.so"}]
)
```

→ **아직 미실행. 다음 세션에서 P0 즉시 실행.**

### 5.5 P1 백업 (P0 실패 시)

EPContext ONNX 생성 (`gen_qnn_ctx_onnx_model.py`로 .bin → EPContext .onnx 변환)  
→ 이미 컴파일된 HTP .bin 파일에서 직접 QNN 추론 경로

### 5.6 세션 환경 정보

| 항목 | 값 |
|------|-----|
| WSL IP | 100.90.83.128 (Tailscale) |
| WSL 포트 | 2222 |
| npu_worker.py | `~/parksy-audio/scripts/npu_worker.py` |
| 폰 proot Ubuntu | glibc 2.42, Python 3.13.7 |
| 폰 Termux native | QNN EP 접근 경로 (proot 우회 필수) |

---

## 6. 현재 상태 정리 (2026-05-21 기준)

### 완료된 것

- [x] NPU 코어 명제 + 방향 확정 (2026-04-27)
- [x] GPT-SoVITS 5모델 ONNX export + HTP .bin 컴파일 완료
- [x] npu_worker.py HTTP 인터페이스 v1.0 완성 (port 7768)
- [x] sovits backend fallback으로 Air e2e v4 풀 통과
- [x] RVC parksy_rvc.pth 55MB (박씨 음색 자산 확보)
- [x] MeloTTS EN ONNX export 스크립트 (`/tmp/melotts_export_onnx.py`)
- [x] RVC ONNX 변환 검증 (generator infer, opset 17)

### 진행 중 / 미완료

- [ ] **P0: onnxruntime-qnn 2.1.0 설치 + QNN EP 활성화** (S25 Ultra Termux native)
- [ ] MeloTTS EN ONNX NPU 추론 검증
- [ ] RVC ONNX NPU 추론 검증
- [ ] E2E NPU 파이프라인 (MeloTTS → RVC → WAV)
- [ ] npu_worker.py에 MeloTTS+RVC 백엔드 추가

### 다음 세션 즉시 실행 순서

```
1. S25 Ultra Termux native 열기 (proot 아님)
2. pip install onnxruntime-qnn==2.1.0
3. get_available_providers() 확인 → QNNExecutionProvider 있으면 P0 성공
4. /sdcard/parksy_fp32/prompt_encoder.onnx QNN EP 추론 테스트
5. 7.57s → 1.5~2.5s 확인
6. 성공 시 npu_worker.py zipvoice 백엔드 구현
7. 실패 시 P1 (EPContext ONNX from .bin)
```

---

## 7. 비용 분석

| 항목 | GPU (v2ProPlus) | NPU (MeloTTS+RVC) |
|:----:|:---------------:|:-----------------:|
| 월 운영비 | $44/월 (Vast.ai) | **$0** (내 폰) |
| 초기 R&D | — | $1.36 (MeloTTS 학습) + $0.60 (RVC) |
| 전력 | 데이터센터 | 폰 배터리 |
| 오프라인 | ❌ | ✅ |

---

## 8. 관련 파일 위치

| 파일 | 경로 |
|------|------|
| NPU 워커 | `~/parksy-audio/scripts/npu_worker.py` |
| NPU 인터페이스 명세 | `~/parksy-audio/docs/NPU_WORKER_INTERFACE_v1.md` |
| streaming client | `~/parksy-audio/mcp_voice/parksy_voice/streaming_client.py` |
| RVC 모델 | `~/rvc_models/parksy_rvc/parksy_rvc.pth` (55MB) |
| RVC index | `~/rvc_models/parksy_rvc/parksy_rvc.index` (180MB) |
| MeloTTS ONNX export | `/tmp/melotts_export_onnx.py` |
| HTP .bin 파일들 | 폰 `/sdcard/parksy_fp32/*.bin` (5개) |
| proot NPU session log | 폰 `~/SESSION_LOGS/NPU_SESSION_2026-05-18.md` |
| 이전 dev-log | `024-npu-eureka-1year-eternal-return-2026-04-27.md` |
| 이전 dev-log | `027-parksy-english-rvc-npu-solution-2026-05-09.md` |
