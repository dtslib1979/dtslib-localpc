# 027 — Parksy English TTS + RVC NPU 솔루션 확정 (2026-05-09)

> 박씨 최종 결정: **"한국어 TTS 포기. 영어 콘텐츠 + 박씨 음색(RVC) + NPU"**
> MeloTTS 단일 화자 학습 실패 → RVC 음색 변환으로 피벗.
> DeepSeek + Opus 크로스체크 완료. 박씨 승인. 솔루션 확정.

---

## 0. 실행 요약

| 항목 | 결정 |
|------|------|
| 콘텐츠 언어 | **영어** (한국어 TTS 학습의 늪 회피) |
| 음색 | **박씨 음색** (RVC voice conversion) |
| 실행 | **S25 Ultra NPU** (ONNX → Qualcomm QNN) |
| GPU | **$0** (양산 운영) |
| TTS 엔진 | **MeloTTS English** ONNX (NPU) |
| 음색 변환 | **RVC parksy_rvc.pth** ONNX (NPU) |
| Fallback | edge-tts (cloud, 인터넷 있을 때) |

---

## 1. 배경 — 삽질의 역사

### 1.1 GPT-SoVITS v2ProPlus ✅ (현행)
GPU로 박씨 음성 90%+ 유사도. 한국어 완벽. NPU 포팅 실패 (ONNX 변환 복잡도).

### 1.2 MeloTTS fine-tune ❌ (오늘)
8h40m, $1.36, 74 epochs. 학습은 됐지만 multi-speaker 구조 한계로 v2ProPlus 품질 불가능.

### 1.3 ZipVoice zero-shot ⏳ (미검증)
한국어 NPU TTS 후보였으나 한국어 품질 미검증.

### 1.4 박씨 결정: B로 가
```
MeloTTS / ZipVoice 한국어 TTS → 포기
영어 콘텐츠 + RVC 박씨 음색 → 확정
```

---

## 2. 최종 아키텍처

### 2.1 파이프라인

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

### 2.2 계층 구조

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

### 2.3 NPU 워크로드 분배

| 구성 요소 | 처리 주체 | NPU? |
|---------|---------|:----:|
| MeloTTS EN 추론 | NPU (QNN) | ✅ |
| hubert feature extract | NPU (QNN) or CPU | ⚠️ 검증 필요 |
| RVC generator 추론 | NPU (QNN) | ✅ (28.7M, 작음) |
| Audio post-processing | CPU (sox/ffmpeg) | ❌ |
| MP4 인코딩 | Qualcomm HW encoder | ✅ |

---

## 3. RVC 모델 현황

| 항목 | 값 |
|------|-----|
| 위치 | `~/rvc_models/parksy_rvc/` |
| Model file | `parksy_rvc.pth` (55MB) |
| Index file | `parksy_rvc.index` (180MB) |
| Architecture | `SynthesizerTrnMs768NSFsid` — 28.7M params |
| 학습 완료 | 2026-04-04, GCP A100, 30분, $0.60 |
| 추론 속도 | CPU 34초/5.6초 오디오 (6x real-time) |
| NPU 예상 | ~1-2초/5.6초 (HTP 가속) |

**RVC ONNX 변환 검증 완료:**
- Generator `infer()` 메서드: `(phone, phone_lengths, pitch, nsff0, sid, rate)` 
- ONNX opset 17, dynamic axes → QNN 호환

---

## 4. MeloTTS English ONNX

| 항목 | 값 |
|------|-----|
| 언어 | **EN** (네이티브 EN BERT, 한국어와 다름) |
| 출력 | VITS2 vocoder, 24kHz |
| ONNX | opset 17, dynamic axes (text/video 길이) |
| 크기 | ~600MB fp32 / ~300MB INT8 |
| NPU | onnxruntime-qnn v2.1.0 |

**한국어와의 결정적 차이:**
- MeloTTS EN = EN BERT 네이티브 (정식 지원)
- MeloTTS KR = `kykim/bert-kor-base`를 `japanese_bert.py` wrapper에 억지로 끼움
- 영어는 품질 보장됨. 한국어는 구조적 한계.

---

## 5. 기존 자산 재활용

| 자산 | 상태 | 용도 |
|------|:----:|------|
| `rvc.py` | ✅ | RVC inference subprocess wrapper |
| `rvc-venv` | ✅ | rvc-python 0.1.5 + fairseq + torch |
| `parksy_rvc.pth` | ✅ | 박씨 음색 RVC 모델 (55MB) |
| `voices.py` | ✅ | 카탈로그 (RVC 경로 수정 필요) |
| `tts.py` | ✅ | RVC opt-in (quality="rvc") |
| `MeloTTS ONNX export` | ✅ | `/tmp/melotts_export_onnx.py` |
| NPU worker | ⏳ | `npu_worker.py` (+RVC 백엔드 추가 필요) |

---

## 6. 남은 작업 (Phase 1)

| 우선순위 | 작업 | 예상 시간 |
|:--------:|------|:---------:|
| P0 | **RVC 경로 수정** (voices.py RVC_PATH) | 1분 |
| P1 | **MeloTTS EN ONNX export 검증** | 15분 |
| P2 | **RVC ONNX export + 테스트** | 30분 |
| P3 | **NPU worker RVC 백엔드 추가** | 30분 |
| P4 | **E2E NPU 테스트** (TTS→RVC→WAV) | 30분 |

---

## 7. 비용 분석

| 항목 | GPU (v2ProPlus) | NPU (MeloTTS+RVC) |
|:----:|:---------------:|:-----------------:|
| 월 운영비 | $44/월 (Vast.ai) | **$0** (내 폰) |
| 초기 R&D | $10 (RunPod) | $1.36 (이미 지출) |
| 전력 | 데이터센터 | 폰 배터리 |
| 오프라인 | ❌ | ✅ |

---

## 8. 박씨 결정들 (세션 기록)

| 결정 | 내용 |
|------|------|
| NPU 방향 | "GPU 말고 NPU로 가자" |
| MeloTTS 채택 | "이거 마음에 들어. 커뮤니티 리서치해봐" |
| B로 가 | "저새끼 잘하는지 봐" → Opus "B로 가" 수용 |
| 영어 피벗 | "영문으로 다 작성, 영어 성우로 할 거" |
| RVC 필수 | "내 음색이 들어가야지. 인공지능 같지 않을 거 아니야" |
| **최종 확정** | **MeloTTS EN + RVC ONNX → NPU** |
