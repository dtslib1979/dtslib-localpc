# xtract — 음원 하이라이트 멜로디 추출 시스템 개발 백서

> 작성: 2026-06-19 | 버전: v1.1 | 상태: 실험실 검증 완료 (Billie Jean)

---

## 1. 프로젝트 개요

**목표:** 상업 음원에서 "가장 유명한 하이라이트 테마(후렴구)"만 자동 추출 → MIDI → REAPER 편집

**원라이너:**
> "빌리진" 한 마디 → 검색 → 후렴구 탐지 → 보컬 분리 → 멜로디 MIDI → REAPER

---

## 2. 시스템 아키텍처

### 전체 파이프라인

```
Layer 1: 메타데이터 브릿지 (Spotify / YouTube API)
  → 곡 검색, BPM/키/ISRC/라이선스 확인

Layer 2: 오디오 분리 + 피치 트래킹 (Demucs + CREPE)
  → 보컬, 반주, 베이스, 드럼 분리
  → F0 피치 컨투어 (10ms 해상도)

Layer 3: 가사-노트 1:1 정렬 (Whisper + g2p + CREPE)
  → "가사 1음절 = MIDI 1노트" 리듬 역산
```

### 오케스트레이터 (`agent_pipe.py`)

290라인 단일 스크립트, 6단계 자동 실행:

| 단계 | 모듈 | 기능 | 소요 시간 |
|------|------|------|:--------:|
| 1 | `step_search()` | yt-dlp 검색 + WAV 다운로드 | ~10초 |
| 2 | `step_chorus()` | pychorus 후렴구 탐지 (fallback: 중간 30초) | ~30초 |
| 3 | `step_separate()` | Demucs htdemucs 보컬 분리 | ~60초 |
| 4 | `step_transcribe()` | basic-pitch MIDI 전사 | ~30초 |
| 5 | `step_f0_filter()` | CREPE F0 confidence 검증 (threshold=0.3) | ~30초 |
| 6 | `step_copy_to_reaper()` | MIDI → D 드라이브 REAPER Media 자동 복사 | 즉시 |

---

## 3. Phase 1→3 삽질 이력

### Phase 1: basic-pitch 단독 — 실패
- 접근: `yt-dlp → WAV → basic-pitch`
- 결과: **1421개 노트** (화음+반주+보컬 전부 기록)
- 실패 원인: basic-pitch는 polyphonic 모델. 믹스 상태에서 돌리면 모든 악기 전사

### Phase 2: A/B 교차검증 — 실패
- 접근: `basic-pitch vs pyin F0 대비`
- 결과: 42% 검출률
- 실패 원인: HPSS(harmonic-percussive separation)로는 보컬 완전 분리 안 됨

### Phase 3: Demucs + 보컬 분리 + basic-pitch — 성공 ✅
- 접근: `demucs mdx_extra → vocals → basic-pitch → F0 검증`
- 결과: **84.2% 매칭, 189개 clean 노트**
- 핵심: demucs로 반주 제거 후 basic-pitch = 1421→575노트 급감

---

## 4. AI 코어 오픈소스 리서치

### 설치 완료 (즉시 사용 가능)
| 패키지 | 용도 | 버전 |
|--------|------|:----:|
| Demucs | 음원 분리 (SOTA) | 4.0.1 |
| basic-pitch | 오디오→MIDI 전사 | 0.4.0 |
| CREPE/torchcrepe | F0 피치 추정 | 0.0.24 |
| pychorus | 후렴구 탐지 | 0.1 |
| msaf | 음악 구조 분석 | 0.1.80 |
| faster-whisper | 음성→텍스트 | 1.2.1 |
| g2p-en/g2pk | 음절 분할 (영/한) | 각 2.1.0 |

### 검토 완료 (향후 도입)
| 솔루션 | 별 | 용도 | 도입 우선순위 |
|--------|:---:|------|:-----------:|
| Omnizart | 1.9k | 보컬 멜로디 전사 전용 | ⭐⭐⭐ |
| WhisperX | 3.8k | ±50ms word alignment | ⭐⭐ |
| Transkun | 362 | 피아노 전사 경량 | ⭐ |
| hFT-Transformer | 117 | SONY SOTA 전사 | 장기 검토 |

---

## 5. 실테스트 결과 — Billie Jean

| 항목 | 결과 |
|------|------|
| 타겟 | Michael Jackson - Billie Jean |
| 검색/다운로드 | yt-dlp 자동 (공식 뮤비 4분 55초) |
| 후렴구 탐지 | pychorus: 엔딩(3:57) → 부정확, fallback: 중간 30초 |
| Demucs 분리 | htdemucs, 53초 소요 |
| basic-pitch 전사 | 60개 노트 |
| CREPE F0 검증 | 60→46노트 생존 (76%, threshold=0.3) |
| REAPER 복사 | `D:\PARKSY\REAPER\Projects\Media\...melody.mid` |

### pychorus 한계
저음역대 반복 베이스라인이 강한 곡(Billie Jean)은 Chroma 기반 후렴구 탐지가 부정확.
→ msaf 구조 분석 병행 또는 수동 위치 입력 필요.

---

## 6. WSL→D 드라이브 이주 계획

**이유:** C 드라이브 82% 사용 중, WSL vhdx가 202GB 차지

| 방법 | 도구 | 시간 | 특징 |
|------|------|:---:|------|
| `wsl --manage --move` | Windows PowerShell | 30분 | MS 공식, 안전, D 드라이브로 통째 이주 |
| DeepSeek Aider | Windows MSYS2 | 자동 | 박씨가 Aider에 명령만 주면 됨 |

**실행 파일:** `dtslib-localpc/docs/WSL-MIGRATION-TOOL.md`

---

## 7. 향후 개선

### 단기 (다음 세션)
- [ ] pychorus 정확도 개선 (msaf 병행 또는 수동 위치 지원)
- [ ] 가상환경(.venv-xtract)에 torch/pretty_midi 설치 → F0 검증 정상화
- [ ] 다중 곡 배치 처리 (플레이리스트 단위)
- [ ] REAPER ReaScript 자동 트랙 추가 (win-gui MCP)

### 중기
- [ ] Omnizart vocal 도입 (basic-pitch 대체, 예상 정확도 90%+)
- [ ] WhisperX ±50ms alignment → L3 가사-노트 정렬 완성
- [ ] WSL D 드라이브 이주 완료

### 장기
- [ ] hFT-Transformer SONY 전사 모델 도입
- [ ] YouTube Data API로 곡 검색 자동화
- [ ] Spotify API 메타데이터 BPM/키 자동 추출

---

## 8. 파일 구조

```
parksy-audio/xtract/
├── agent_pipe.py          # 오케스트레이터 (290라인)
├── agent_pipe.sh          # 가상환경 실행 래퍼
├── README.md              # xtract 설명
├── bridge.py              # 3레이어 브릿지 (구버전)
├── docs/
│   ├── 3LAYER-BRIDGE.md   # 3레이어 아키텍처 설계서
│   ├── API-RESEARCH.md    # Spotify API 공식 분석
│   ├── DEVLOG-2026-06-16.md  # Phase 1→3 개발일지
│   ├── FREE-ALTERNATIVES.md  # 무료 솔루션 총정리
│   ├── MELODYNE-OPENSOURCE.md  # 오픈소스 전사 도구 조사
│   └── SPOTIFY-VS-YOUTUBE.md  # 데이터 매트릭스 비교
├── outputs/               # 작업 결과물 (git ignore)
│   └── job_*/             # 곡별 작업 디렉토리
└── agent_pipe.sh          # 실행 래퍼
```
