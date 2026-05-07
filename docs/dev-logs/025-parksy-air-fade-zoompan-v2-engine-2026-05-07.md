# 025 — Parksy Air P3 엔진 v2: fade + Ken Burns (2026-05-07)

> ⭐ Pictory/Synthesia 벤치마킹 결과, fade transition + B-roll zoompan이
> 가장 즉시 적용 가능한 품질 개선으로 판명. 하루 만에 구현 완료.
> 박씨 + phone_claude(Sonnet) + DeepSeek 3자 크로스 체크로 검증.

---

## 0. 왜 별도 일지인가

```
오늘 = Parksy Air 품질이 "허접" 평가받은 날
      → Pictory/Synthesia 비교 분석
      → fade + Ken Burns = 즉시 가능한 개선
      → 하루 만에 엔진 v2 완성
      → smoke test 통과

의미: AI Functioner Whitepaper 영상에서 "인터랙티브한 요소 없음" 지적
      → Pictory(월 $60)의 fade/B-roll을 ffmpeg 2줄로 대체
      → 비용 0, 종속성 0
```

---

## 1. 오늘의 커밋

| # | 시간 | 태그 | 내용 |
|---|------|------|------|
| 1 | 05-07 | `feat` | concat에 fade transition 추가 (0.3s) |
| 2 | 05-07 | `feat` | zoompan Ken Burns 효과 추가 (Pictory B-roll 대체) |
| 3 | 05-07 | `perf` | zoompan → scale eval=frame + crop (145배 빠름) |
| 4 | 05-07 | `fix` | concat_fade 오디오 드롭 (Critical) |
| 5 | 05-07 | `fix` | Ken Burns crop 오프셋 (Minor) |

**총 5커밋, +239 lines, -25 lines**

---

## 2. 핵심 결정과 이유

### 2.1 fade transition — filter_complex 방식

**결정**: concat demuxer(`-c copy`) 폐기 → filter_complex fade in/out + 재인코딩

**이유**:
- concat demuxer는 hardcut만 가능 (스트림 복사)
- fade는 각 클립 재인코딩 필수
- tradeoff: 속도 ↓ (인코딩 1회 추가) vs 품질 ↑ (씬 전환 부드러움)
- 9:16 쇼츠에서 hardcut은 정적 슬라이드 전환 시 깜빡임으로 인지

**ffmpeg 필터 체인**:
```
[i:v]fade=t=in:st=0:d=0.3,fade=t=out:st={dur-0.3}:d=0.3[vi]
[vi][ai]...concat=n=N:v=1:a=1[v][a]
```

### 2.2 Ken Burns B-roll — zoompan 폐기, scale eval=frame 채택

**결정 과정**:
1. 첫 구현: ffmpeg `zoompan` 필터 → **290초** (5초 클립 1080p)
2. 차선: zoompan 540x960 (quarter res) → **85초** (여전히 느림)
3. 최종: `scale=eval=frame` + `crop` → **1.6초** (baseline + 0.5초)

**180배 성능 차이 원인**:
```
zoompan:  per-frame 픽셀 변환 (sws_scale 개별 호출)
scale:    libswscale SIMD 최적화 경로 (벡터화된 bilinear)
crop:     메모리 오프셋 변경만 (픽셀 연산 없음)

결론: zoompan은 ffmpeg에서 가장 느린 필터 중 하나.
      scale + crop 조합이 Ken Burns 효과의 정해.
```

### 2.3 concat_fade 오디오 드롭 (Critical 버그)

**원인**: `concat=n=N:v=1:a=0` — 의도치 않게 `a=0` 설정

**수정**:
- `_has_audio_stream()` 추가: 각 클립 오디오 유무 탐지
- 오디오 있음 → `[i]:a` 패스스루
- 오디오 없음 → `anullsrc+atrim` 무음 생성
- `concat=v=1:a=1` + `-map [v] -map [a]`

**교훈**: filter_complex에서 concat 사용 시 `v=1:a=0` 기본값 조심. 명시적으로 `v=1:a=1` 써야 함.

---

## 3. smoke test 결과

| 항목 | 결과 |
|------|------|
| URL | termux-bridge/slides/ (3슬라이드) |
| script-mode | simple |
| fade | 0.3s |
| zoompan | auto (짝수in/홀수out) |
| 최종 포맷 | h264 + aac, 1080×1920, 30fps |
| 파일 크기 | 2.2MB (with opening) |
| 길이 | 19초 |
| 오디오 | ✅ 스트림 확인 |
| Telegram | ✅ 전송 완료 |

---

## 4. 파일 변경

### renderer.py (+104, -25)

```
- _has_audio_stream()       # 오디오 유무 탐지 (concat fallback용)
- apply_zoompan()           # Ken Burns 효과 (scale eval=frame + crop)
- concat_clips() ★수정★    # fade + 오디오 concat (v=1:a=1)
- render() ★수정★          # zoompan 파라미터 추가
- encode_shorts()           # 변경 없음
# 상수: ZOOM_RANGE=0.05, ZOOM_MIN_DUR=3.0
```

### orchestrator.py (+14, -1)

```
- run_pipeline() ★수정★    # fade_dur, zoompan 파라미터
- render() 호출 ★수정★     # fade_dur, zoompan 전달
- CLI: --fade, --zoompan    # argparse 옵션 추가
```

---

## 5. 남은 과제 (다음 세션)

| 우선순위 | 과제 | 예상 시간 |
|----------|------|-----------|
| P0 | **Actor MCP** editor.py concat에도 fade+zoompan 적용 | 15분 |
| P1 | **parksy_writer.py** orchestrator 통합 (simple 모드 폐기) | 2시간 |
| P2 | **zoompan randomization** (클립별 랜덤 zoom 방향/속도) | 30분 |
| P3 | **audio cross-fade** (concat 시 오디오도 fade 전환) | 30분 |
| P4 | **zoompan + pointer 연동** (판서 위치와 zoom 중심 정렬) | 1시간 |
