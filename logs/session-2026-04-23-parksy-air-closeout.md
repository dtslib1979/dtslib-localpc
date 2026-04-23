# Parksy Air 영상 자동화 파이프라인 마감 세션 — 2026-04-23

> **목적**: 어제~오늘 작업 전수 파싱 + 영상 자동화 현재 상태 판정 + 오늘 마감 범위 결정
> **박씨 지시**: "오늘 동영상 자동화 관련된 거 다 마감하고 파이프라인 확정 지을 거야. 테스트도 할 거고"

---

## 1. parksy-image 영상 자동화 전수 스캔 결과

### tools/web2video/ 파일 현황 (24개 파일)

| 카테고리 | 파일 | 상태 |
|---|---|---|
| **오케스트레이션** | orchestrator.py (560줄) | ✅ 완성, 2026-03-30 마지막 성공 실행 |
| **P0 스크립트** | script_generator.py | ✅ 완성 (claude 모드 + simple fallback) |
| **P1 추출** | extractor.py | ✅ 완성 (Playwright CDP 녹화) |
| **P2 TTS** | tts_humanizer.py | ✅ 완성 (edge-tts + pedalboard) |
| **P3 렌더** | renderer.py | ✅ 완성 (ffmpeg 합성) |
| **P3.5 오프닝** | comfyui_opening.py | ⚠️ 코드 완성, 테스트 미완 |
| **P3.5 엔딩** | comfyui_ending.py | ✅ E2E 검증 완료 (2026-04-07) |
| **P4 업로드** | upload_youtube.py | ✅ 완성 (dtslib-papyrus subprocess) |
| **Vast.ai** | vastai_setup_comfyui.sh | ✅ 스크립트 완성, 인스턴스 재생성 필요 |
| **RunPod** | runpod_setup.py | ✅ 완성 |
| **프롬프트** | prompt_generator.py | ✅ 완성 (script.json → opening/ending 프롬프트) |
| **v2.1 버전** | web2video.py | ✅ 다중 URL + chapter_break 지원 |
| **엔딩 생성** | ending_generator.py | ✅ 완성 |
| **Blender** | blender_renderer.py | ✅ 완성 |
| **설정** | presets.json, channel_routing.json, weight.json | ✅ |
| **템플릿** | lecture_template.html | ✅ |
| **설치** | install_air.sh | ✅ |

### dist/ 실제 생성 이력

| 파일 | 크기 | 날짜 |
|---|---|---|
| parksy_air_with_opening_20260330_151757.mp4 | 1.87MB | 2026-03-30 |
| parksy_air_20260330_151757.mp4 | 556KB | 2026-03-30 |
| parksy_air_with_opening.mp4 | 4.8MB | 2026-03-26 (39슬라이드 풀런) |

### build/ 테스트 이력

24개 빌드 폴더 있음 (2026-03-24 ~ 2026-04-16).

---

## 2. 로컬 환경 검증

### 의존성 (2026-04-23 현재)
```
✅ playwright     설치됨
✅ edge_tts       설치됨
✅ pedalboard     설치됨
✅ ffmpeg         설치됨
❌ Vast.ai 인스턴스 없음 (2026-04-07 크래시 후 미복구)
❌ ANTHROPIC_API_KEY 미설정 (simple 모드 fallback 작동)
```

### 즉시 실행 가능 여부
- **본편 생성 (P0~P3)**: ✅ 로컬에서 바로 가능 (GPU 불필요)
- **오프닝 생성 (comfyui_opening)**: ❌ Vast.ai 인스턴스 필요
- **엔딩 생성 (comfyui_ending)**: ❌ Vast.ai 인스턴스 필요
- **YouTube 업로드 (P4)**: ✅ token.json 있으면 가능

---

## 3. style_engine Phase 1 상태 (별도 트랙)

> **주의**: style_engine은 영상 자동화 파이프라인과 **별개 트랙**. 오늘 마감 대상 아님.

- ✅ Phase 1 31/31 테스트 통과, PR #33 main 머지 완료
- ⏸️ Phase 2 (ComfyUI 브릿지) 대기 중
- 다음 세션용 인스트럭션: `docs/style-engine/NEXT_SESSION_OPUS.md`

---

## 4. "오늘 마감" 범위 판정 — 2개 Path

### Path A: 본편만 E2E 마감 (GPU 없이, 1시간 내)

```
현재 → [1] 스모크 테스트 (3슬라이드, 10분)
      → [2] 풀런 (39슬라이드, 30-40분)
      → [3] Telegram 전송 + 박씨 확인
      → 마감 ✅
```

**실행 명령:**
```bash
cd /home/dtsli/parksy-image/tools/web2video

# 스모크 (필수)
python3 orchestrator.py \
  --url "https://dtslib1979.github.io/termux-bridge/slides/" \
  --test --script-mode simple --tts-preset natural

# 스모크 통과 후 풀런
python3 orchestrator.py \
  --url "https://dtslib1979.github.io/termux-bridge/slides/" \
  --script-mode simple --tts-preset natural
```

**장점**: GPU 비용 0, 로컬 완결, 1시간 내 마감
**단점**: 오프닝/엔딩 없는 "강의 본편"만

---

### Path B: 풀 파이프라인 마감 (Vast.ai 필요, 3-4시간)

```
현재 → [1] Vast.ai RTX 4090 인스턴스 생성 (PyTorch 2.4+ 이미지, 20분)
      → [2] vastai_setup_comfyui.sh 실행 (WAN 14GB + FLUX 8.4GB 다운로드, 30분)
      → [3] comfyui_opening.py 단독 테스트 (15분)
      → [4] orchestrator.py 풀 파이프라인 (--ending 포함, 1시간)
      → [5] Telegram 전송 + 박씨 확인
      → 마감 ✅
```

**비용**: Vast.ai RTX 4090 약 $0.50~1.00 (3-4시간 기준)

**장점**: 오프닝+본편+엔딩 완전체
**단점**: GPU 세팅 삽질 리스크 (2026-04-07 크래시 재발 가능)

---

## 5. 블로커 / 리스크

| 항목 | 심각도 | 조치 |
|---|---|---|
| clip_10, clip_21 간헐적 손상 (2026-03-26) | 🟡 | 풀런 재실행 후 재현 여부 확인 |
| Vast.ai PyTorch 2.4 OOM 크래시 (2026-04-07) | 🟡 | 이번엔 RAM 32GB+ 인스턴스로 |
| ANTHROPIC_API_KEY 없음 | 🟢 | simple 모드로 우회 가능 |
| style_engine → ComfyUI 브릿지 없음 | 🟢 | 별도 트랙, 오늘 마감과 무관 |

---

## 6. 박씨 결정 대기 사항

**박씨가 답해야 할 것 하나:**

- **Path A** (GPU 없이 본편만, 1시간) — **지금 바로 시작 가능**
- **Path B** (Vast.ai 풀 파이프라인, 3-4시간) — **GPU 예산 OK 하면 시작**

**내 추천: Path A 먼저 → 성공하면 Path B로 오프닝/엔딩 추가.**

이유:
1. Path A는 GPU 없이 로컬 완결 → 파이프라인 **코어** 작동 먼저 락인
2. Path A 성공 = 오늘 마감 최소 조건 충족
3. Path B는 Path A 성공 이후 "업그레이드"로 접근하면 리스크 낮음
4. 4-07 Vast.ai 크래시 전례 있어서 **코어부터 먼저 박아두는 게 안전**
