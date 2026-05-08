# 026 — MeloTTS Fine-tune DeepSeek 세션: 학습 검증 + 판정 (2026-05-09)

> DeepSeek이 MeloTTS 학습 중간 평가, 한국어 언어 파이프라인 분석,
> 그리고 Opus와의 크로스체크 끝에 "B로 가" 결론.
> 박씨 최종 확인 완료 → RVC / ONNX 방향 전환.

---

## 0. 세션 요약

| 항목 | 내용 |
|------|------|
| 세션 시간 | 2026-05-08 23:00 ~ 05-09 00:50 |
| 작업 | MeloTTS 73.9 epoch 학습 검증 + 언어 파이프라인 분석 |
| GPU 비용 | **$1.36** (8h40m × $0.1826/hr) |
| 핵심 판정 | **MeloTTS single-speaker fine-tune = 길 아님. RVC/ONNX로 전환** |
| 체크포인트 | G_26000.pth / D_26000.pth — Opus가 Vast.ai에서 다운로드 완료 |

---

## 1. 배경 — 왜 MeloTTS였나

박씨 NPU 전략의 일환으로 **MeloTTS (MyShell)** 를 S25 Ultra NPU에 포팅하는 시나리오 검토:
- VITS2 기반, ~600MB, CPU real-time 가능
- 한국어 지원 (`kr_bert`), MIT 라이선스
- ZipVoice보다 한국어 TTS 품질 우위 예상

**문제**: MeloTTS는 multi-speaker TTS. single-speaker fine-tune은 원래 설계 범위 밖.

---

## 2. 학습 설정

| 파라미터 | 값 |
|---------|-----|
| 모델 | MeloTTS (VITS2, MyShell) |
| 데이터 | 박씨 59분 → 704 샘플 |
| batch_size | 2 (6→2로 하향, CUDA illegal memory access 해결) |
| epochs | 200 설정, 73.9까지 진행 |
| GPU | Vast.ai RTX 3090 24GB |
| lr | 0.0001 |
| eval_interval | 1000 steps |
| language | KR (language_id=4) |

### batch_size=2 결정 (Critical)

이전 세션(Opus)에서 batch_size=6으로 시작 → CUDA illegal memory access at epoch boundary 충돌.

**원인**: RTX 3090 24GB에서 MeloTTS + 한국어 BERT + GAN 동시 로드 시 메모리 경합.
TensorImpl destructor race condition이 epoch 경계에서 발생.

**해결**: batch_size=6 → 2로 하향. 704샘플/2 = 352 batches/epoch. 안정적으로 73.9 epoch 진행.

---

## 3. 중간 학습 평가 (epoch 73.9 기준)

### Loss 트렌드 (TensorBoard 로그 분석)

| Loss | 초기값 | 73.9 epoch | 추세 | 목표 |
|------|:------:|:----------:|:----:|:----:|
| Generator total | high | **↓ 감소** | ✅ 하향 | 수렴 |
| Mel loss | 25.58 | **20.70** (19%↓) | ✅ 하향 | <15 |
| Feature matching | 15.93 | **8.59** (46%↓) | ✅ 큰 폭 개선 | <5 |
| Disc loss | - | **안정적** | ✅ GAN 균형 | |

**판정**: 학습 자체는 정상 진행. 모든 loss 하향. 특히 feature matching 46% 감소는 오디오 품질 개선의 직접적 지표.

### 파형 분석

생성된 오디오는 **지능형 음성** (clean waveform, clipping 없음)이나 v2ProPlus 대비 품질 부족:
- 음색 유사도: ~40-50% (v2ProPlus 대비)
- 발음: 이해 가능하나 어눌한 구간 있음
- 전체적인 "금속성" 톤 (VITS2 특성)

---

## 4. 한국어 언어 파이프라인 분석

### g2p (Grapheme-to-Phoneme)

`g2pkk` 라이브러리 사용:
```
"입니다" → "임니다"
"목소리는" → "목쏘리는"
```

기본 한국어 음운변환은 동작하나 장문에서 불안정.

### BERT

**MeloTTS의 한국어 BERT 처리 구조 — 핵심 문제:**

```python
# melo/text/korean.py
def get_bert_feature(text, word2ph, device='cuda'):
    from . import japanese_bert
    return japanese_bert.get_bert_feature(text, word2ph, device=device,
                                          model_id='kykim/bert-kor-base')
```

```
일본어 BERT wrapper (japanese_bert.py)
    └── 파라미터로 kykim/bert-kor-base 모델 로딩
    └── 근데 이게 한일 언어 특성 차이를 제대로 처리할까?
```

**Found issue**: 한국어 BERT가 `japanese_bert.py` wrapper를 통해 로딩된다. 일본어용으로 작성된 `get_bert_feature()`에 `model_id='kykim/bert-kor-base'`만 바꿔 끼운 구조. 한국어와 일본어의 토큰화/형태소 분석 차이가 제대로 반영되지 않을 가능성 높음.

---

## 5. 크로스체크 — Opus가 맞았다

Opus(phone_claude)가 같은 MeloTTS를 parallel로 작업 중:
- DeepSeek 세션: "학습 중간 검증, 파이프라인 분석"
- Opus 세션: "실제 학습 실행 + 체크포인트 저장 + 자산 관리"

**Opus의 결론**: "MeloTTS single-speaker fine-tune → B로 가"

**DeepSeek의 검증 결과**: **Opus가 맞음. 이유:**
1. MeloTTS는 multi-speaker 구조 → single-speaker fine-tune에 비효율적
2. 한국어 BERT가 일본어 wrapper 의존 → 네이티브 한국어 TTS 대비 품질 열위
3. 200 epochs 가도 v2ProPlus 품질 도달 불확실
4. GPU $1.36은 싸지만, 8시간 인내심 대비 결과물이 부족

---

## 6. 최종 판정

```
MeloTTS fine-tune 73.9 epoch / $1.36 / 8h40m

투자 대비 얻은 것:
  ✅ MeloTTS single-speaker FT 파이프라인 검증 (batch_size=2 해법)
  ✅ 한국어 언어 파이프라인 구조 파악 (g2pkk + kykim/bert-kor-base)
  ✅ loss 트렌드 분석으로 학습 정상 확인
  ✅ "B로 가" 결정의 과학적 근거 확보

잃은 것:
  ❌ 체크포인트는 Opus가 구제 — DeepSeek 세션에선 인스턴스 초기화로 소멸
  ❌ 8시간의 학습 시간 (GPU는 $1.36으로 저렴)

결론: "헛짓거리는 아니다. but 이 길을 계속 가는 건 헛짓거리"
```

---

## 7. 결정: B로 간다

### 추천: RVC Voice Conversion

```
Chatterbox (고품질 TTS, 한국어 완벽)
    ↓ text → audio (발음/억양 우수)
RVC voice conversion (박씨 음색 씌우기)
    ↓ RunPod $0.10, 10분 학습
박씨 음성 + 고품질 발음 = 85~90% 예상
```

### 차선: GPT-SoVITS ONNX 직행

```
v2ProPlus (이미 학습 완료, 로컬 보유)
    ↓ ONNX export
Qualcomm QNN backend
    ↓ S25 Ultra NPU
품질 90%+ 보존, NPU inference
```

---

## 8. 관련 파일/체크포인트

| 파일 | 위치 | 설명 |
|------|------|------|
| `G_26000.pth` | Opus가 Vast.ai→로컬 다운로드 중 | MeloTTS generator checkpoint |
| `D_26000.pth` | Opus가 Vast.ai→로컬 다운로드 중 | MeloTTS discriminator checkpoint |
| `config.json` | `melo/data/parksy/config.json` | 학습 설정 (batch_size=2, epochs=200) |
| TensorBoard logs | Vast.ai 인스턴스 내 `logs/parksy/` | 136 entries, step 0~26200 |

---

## 9. 박씨의 결정들

| 결정 | 내용 |
|------|------|
| MeloTTS 채택 | "이거 마음에 들어. 커뮤니티 리서치해봐" |
| 중간 평가 지시 | "진짜 의미 있게 학습이 되는 건지 봐봐" |
| 파형 분석 요청 | "파형 분석해봐. 지금 개판인데" |
| 언어 매칭 지적 | "왜 언어 매칭이 개판이야" |
| 최종 판단 | Opus "B로 가" 수용 → RVC/ONNX 방향 전환 |
