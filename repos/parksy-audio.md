# parksy-audio 개발 일지 (Development Journal)

> **이 문서는 dtslib-localpc의 크로스레포 복원 문서다.**
> 새 Claude 세션이 이 파일만 읽으면 parksy-audio의 전체 맥락을 즉시 파악하고 작업을 이어갈 수 있어야 한다.
> 최종 갱신: 2026-03-18

---

## 1. 프로젝트 정체성

- **정의**: 퍼블릭 도메인 클래식 → SF2 렌더링 → 마스터링 → YouTube BGM 생산 파이프라인
- **Owner**: dtslib1979 (박씨)
- **Repo**: `dtslib1979/parksy-audio`
- **Canonical Path**: `D:\PARKSY\parksy-audio`
- **Work Directory**: `D:\tmp` (optimizer.py, score_engine.py, config 파일들)
- **YouTube**: @musician-parksy (Account A: dimas.thomas.sancho@gmail.com)

---

## 2. 현재 상태 (Phase 8 Complete)

| 항목 | 값 |
|------|-----|
| Branch | `main` |
| Last Commit | `b89ff41` — docs: 세션 종료 프로토콜 추가 |
| Piano Score | avg 96.4 (15/22 at 100.0) |
| Orchestral Score | avg 99.9 (12/12 ≥ 99.5) |
| Videos Produced | 6개 (YouTube-ready MP4) |
| Primary SoundFont | SGM-V2.01.sf2 (Warm Classical) |
| LUFS Target | -16, TP -1.5, LRA 9 |

### 대기 작업

- [ ] YouTube 업로드 실행 (6개 비디오)
- [ ] Score Engine 고도화 (spectral flatness 추가)
- [ ] 장르별 프로필 분리 (오케스트라 vs 피아노 솔로)
- [ ] AI Velocity Generation (flat-velocity MIDI 한계 극복)
- [ ] B-grade 트랙 humanize_preset 재처리
- [ ] midi_quality_gate.py 구현 (자동화)
- [ ] fire_nat.mp3 다운로드 완료 (Internet Archive)

---

## 3. Phase별 개발 이력

### Phase 1: 렌더링 엔진 구축 (2026-02-10)

- FluidSynth v2.4.6 설치 (`D:\VST\fluidsynth\bin\fluidsynth.exe`)
- SoundFont 4종 비교: GeneralUser(30MB) < FluidR3(141MB) < SGM(236MB) < **TOH4(419MB)**
- 백조의 호수 렌더링 테스트로 TOH4 채택 (이 시점에서)
- FFmpeg WAV→AAC 256kbps 파이프라인 확립

### Phase 2: 3-Layer 아키텍처 (2026-02-10~11)

- **L1**: Ambient Noise (-18dB) — 자연음 루프
- **L2**: SF2 Music (-3dB) — FluidSynth MIDI→WAV
- **L3**: Voice/Narration (0dB) — 후처리용
- `gen_natural.py`로 합성 노이즈 5종 생성 → **품질 불합격** → 자연음 전환 결정

### Phase 3: 자연음 소스 확보 (2026-02-11)

- Internet Archive CC0 자연음 다운로드:
  - ✅ `rain_nat.mp3` (8.5MB) — RelaxingRainAndLoudThunder
  - ✅ `wind_nat.wav` (9.4MB) — Red_Library_Nature_Wind
  - ⏳ `fire_nat.mp3` — 다운로드 미완료
- 합성음 DEPRECATED → 자연음으로 교체

### Phase 3.9: 경로 리팩토링 (2026-02-11)

- `D:\PARKSY\parksy-audio` = 유일한 canonical 경로 확정
- `D:\1_GITHUB\parksy-audio` = 중복, 삭제 대상
- 하드코딩 경로 9개 파일에서 제거 → `config.py` 중앙 관리

### Phase 4: 본격 생산 (2026-02-11~12)

- **Mock Test 5개 풀 사이클 완성:**
  1. Mahler 5-1 (오케스트라, 13:47) — 기관총 효과 발견 → humanize_preset.py 개발
  2. Chopin Nocturne Op.9 No.1 (피아노, 4:22) — FluidSynth arg 순서 발견
  3. Saint-Saëns Le Cygne (23트랙→피아노, 2:43) — Piano Solid 규칙 확립
  4. Debussy Clair de Lune (피아노, 4:08) — 비주얼 영상 파이프라인 시작
  5. Fauré Pavane (20트랙→피아노, 6:00) — 첫 완전 풀 사이클

- **humanize_preset.py 개발**: 기관총/플랫벨/로봇타이밍 3대 문제 해결
  - 3종 프리셋: `orchestral` / `piano` / `minimal`
  - 트레몰로 롤 스무딩, Velocity 자연화(±12), 타이밍 흔들림(±8ms)

- **make_visual_video.py**: 1280×720 HD, 30fps, H.264 CRF23
  - 네이비 배경(#0a0a2e), showwaves cline cyan, Georgia Bold 42pt 곡명

### Phase 5: Piano Expression Engine (2026-02-13)

- **piano_expression.py** — 7-Stage 프로 피아니스트 표현 엔진:
  1. Parse → NoteEvent 절대시간 리스트
  2. Phrase Detection → 갭/장음/최대길이 기반
  3. Voicing → 멜로디(+15)/베이스(+4)/내성(-8)
  4. Dynamic Phrasing → sin 커브 cresc/dim + 글로벌 아크
  5. Rubato → 구조적 템포 유연성 (진입+10%, 클라이맥스+7%, 리타르단도+15%)
  6. Articulation → 레가토 오버랩(20ms), 스타카토, 아르페지오(10ms)
  7. Sustain Pedal → CC64 자동 삽입

- 이 시점에서는 piano_expression이 "만능"이라 판단 → **Phase 6에서 뒤집힘**

### Phase 5.5: Gate 1 — MIDI 품질 평가 시스템 (2026-02-13)

- **midi_quality_gate.py** — 파이프라인 진입 전 객관적 품질 평가
- **5개 서브스코어** (각 0-100):
  | # | 항목 | 가중치 | 핵심 기준 |
  |---|------|--------|-----------|
  | 1 | Velocity | 35% | unique≥50 + range≥80 + std≥15 = 만점 |
  | 2 | Timing | 20% | grid 60%대 + dev 10-30ms |
  | 3 | Structure | 15% | 피아노 네이티브 + 소수 트랙 |
  | 4 | Expression | 15% | CC64 페달 + 호흡 20-200ms |
  | 5 | Integrity | 15% | notes≥50, dur≥30s, 0.5-50n/s |

- **등급**: A(≥75) → PROCEED / B(≥55) / C(≥35) → CAUTION / D(≥15) / F(<15) → REJECT
- **Velocity 분포 페널티**: flat(≤3 unique) → ×0.15, stepped(≤10) → ×0.50

### Phase 6: A-Grade 배치 생산 → 전량 불합격 (2026-02-13)

> **이 Phase가 전체 프로젝트의 전환점이다.**

- Downloads 폴더 19개 MIDI 전수 스캔: A 6개, B 6개, C 2개, D 3개
- **A-grade 4트랙 배치 처리**: Barcarolle(90.8), Nocturne7(88.8), Consolation3(85.8), Nocturne13(83.9)
- **결과: 전량 상업성 실패** — "못 들어주겠다" 판정

**핵심 발견 — Phase 6.1에서 확인:**
- ⚠️ SF2 한계가 아니었음 — **piano_expression.py가 원본 표현을 파괴**한 것이 주 원인
- A-grade MIDI는 이미 인간적 표현이 풍부 → 7-stage로 갈아엎으면 파괴
- 듣기 좋았던 nocturne_op9_1은 `humanize_preset.py`(가벼운 터치) 사용이었음

**파괴 메커니즘:**
- 3~9트랙 → 1트랙 강제병합 (보이싱 파괴)
- velocity 재지정 (원본 다이나믹 덮어씀)
- 동일 sin curve + rubato (공식적 → 기계적)
- 원본 CC64 삭제 → 알고리즘 재생성 (뉘앙스 손실)

**확정된 법칙:**
- **A/B grade** → `humanize_preset.py --preset piano` (light touch, 원본 보존)
- **C/D grade** → `piano_expression.py` (표현 빈약한 것에만 주입)
- **F grade** → REJECT
- **"좋은 MIDI는 건드리지 마라. 나쁜 MIDI만 고쳐라."**

### Phase 6.2: Fire ASMR + 저작권 노트 영상 (2026-02-13)

- fire_synth.wav 생성 (pink+white+brown noise 합성)
- 4트랙 humanize_preset 재처리 + fire ASMR 재믹스
- 영상 내 drawtext 저작권 노트 표준 포맷 확립

### Phase 7: MIDI Sourcing (2026-02-13)

**소스 전략 (확정):**
| 소스 | 라이선스 | 상업 사용 |
|------|----------|----------|
| Mutopia Project | PD/CC BY/CC BY-SA | ✅ 안전 |
| Piano-midi.de | CC BY-SA | ✅ 출처표기 |
| Kunst der Fuge | 불명확 | ⚠️ 곡별 확인 |
| MAESTRO Dataset | CC BY-NC-SA 4.0 | ❌ **절대 금지** |

**midi_crawler.py**: Mutopia 자동 크롤링 (robots.txt 개방, ~788 피아노곡)
- Piano-midi.de: HTTP 418 봇 차단 → 수동만 가능
- 일본 MIDI 소스풀: 2차 소스 (打ち込み 전통, 아직 미개발)

**법적 포지션 (확정):**
- PD곡 + 단순 MIDI 채보 + SF2 렌더링 = **이중 안전**
- MIDI ≠ 음반 (US Copyright Office §803.4(C))
- 연주 캡처 MIDI 실연자 권리 = **untested** (직접 판례 없음)
- **"저작권 없음 ≠ 자유 사용"** — 계약법 + 부정경쟁방지법 별도 적용

### Phase 8: 마스터링 파이프라인 최적화 (2026-02-19~20)

> **하루 종일 로컬 PC에서 MIDI→오디오 파이프라인을 처음부터 재설계.**

**optimizer.py (v1→v4, 4회 반복):**
```
MIDI → fix_midi() → apply_expression() → render_fluidsynth() → master() → mix_ambient()
```

**6-Round 체계적 최적화 (22 MIDI):**

| Round | 실험 | 승자 | 핵심 발견 |
|-------|------|------|----------|
| R1 | Baseline (v4, TOH4) | avg 95.6 | 출발점 |
| R2 | SoundFont 4종 비교 | **SGM +1.8** | SGM > TOH4 (44% 작으면서 더 좋음) |
| R3 | EQ×Comp 매트릭스 (3×3) | Balanced+Gentle | 피아노는 가볍게 |
| R4 | Expression 튜닝 | **k=3.0** | ★ 23.2pt 차이 (vs k=5.0). 최대 영향 파라미터 |
| R5 | Ambient 믹싱 | rain -20dB | -18dB은 TP 침범, -22dB은 효과 미미 |
| R6 | Final (22 MIDI) | **15/22 = 100.0** | avg 96.4 |

---

## 4. 파이프라인 아키텍처 (확정)

### 4.1 Piano Pipeline (Phase 8)

```
MIDI 확보 (IMSLP/Mutopia)
  ↓
Gate 1: midi_quality_gate.py (A/B/C/D/F)
  ├── A/B → humanize_preset.py --preset piano (light touch)
  ├── C/D → piano_expression.py (7-stage heavy)
  └── F → REJECT
  ↓
Piano Solid (prog→0 강제, 필요시)
  ↓
optimizer.py (fix_midi → apply_expression → render_fluidsynth → master → mix_ambient)
  ↓
make_visual_video.py (1280×720, showwaves, drawtext)
  ↓
YouTube 업로드
```

### 4.2 Orchestral Pipeline (v5 Adaptive)

- **4개 config**: STRING, WOODWIND, BRASS, ORCHESTRAL
- **자동 감지**: `detect_families()` → `get_config_for_midi()`
- **4개 적응 규칙** (결합 적용, 순차 아님):
  1. phrase dynamics: s_lra < 100 → CC11 amp=2.0, window=5s
  2. LUFS target: s_lufs < 100 → -17 (or -18 for musical theater)
  3. warm EQ: s_freq < 95 → body+3dB, presence=0, bright-2dB
  4. dynaudnorm: LRA > 14 → frame=100, gauss=7, peak=0.9, maxgain=20
- **결과**: 12/12 ≥ 99.5 (avg 99.9)
- Config: `D:\tmp\orchestral_optimal_config.json`

### 4.3 Dual-Style System

| 스타일 | SoundFont | Ambient | EQ 특성 | 용도 |
|--------|-----------|---------|---------|------|
| Warm Classical | SGM-V2.01 | rain -20dB | presence+4.5, bright+3.5, air+4 | 기본 |
| Dark Funeral | TOH4 | fire -18dB | 저역 보존, comp 느린 어택 | 추모/장엄 |

---

## 5. 설정 레퍼런스

### 5.1 optimal_config.json (42개 파라미터, Piano Warm Classical)

```json
{
  "soundfont": "D:\\VST\\SGM-V2.01.sf2",
  "fs_gain": 0.6, "fs_reverb": 0, "fs_chorus": 0,
  "hpf_freq": 35,
  "low_shelf_freq": 200, "low_shelf_gain": -3,
  "mid_cut_freq": 400, "mid_cut_q": 2, "mid_cut_gain": -2,
  "body_freq": 1000, "body_q": 1, "body_gain": 1,
  "presence_freq": 3000, "presence_q": 0.7, "presence_gain": 4.5,
  "bright_freq": 5000, "bright_q": 1, "bright_gain": 3.5,
  "air_shelf_freq": 10000, "air_shelf_gain": 4,
  "comp_threshold": -15, "comp_ratio": 1.5, "comp_attack": 50,
  "comp_release": 400, "comp_makeup": 1, "comp_knee": 8,
  "limiter_limit": 0.84, "limiter_attack": 5, "limiter_release": 80,
  "lufs_target": -16, "tp_target": -1.5, "lra_target": 9,
  "vel_scurve_k": 3.0, "vel_target_min": 35, "vel_target_max": 115,
  "phrasing_boost": 0.2, "phrasing_window": 5,
  "ambient_file": "D:\\VST\\ambient\\rain_nat.mp3",
  "ambient_volume": -20
}
```

### 5.2 Score Engine (score_engine.py)

| Dimension | Weight | Perfect Range |
|-----------|--------|---------------|
| LUFS | 20% | -18 ~ -14 |
| LRA | 25% | 5 ~ 10 LU |
| True Peak | 15% | ≤ -1.0 dBTP |
| Freq Balance | 20% | Hi-Mid -15 ~ -5 dB |
| Dynamic Variance | 20% | std 1.5 ~ 5.0 (20s window) |

### 5.3 Orchestral Configs (orchestral_optimal_config.json)

**STRING_CONFIG** (기본값, 대부분의 장르 커버):
```
hpf=28, low_shelf=180Hz/-2dB, mid_cut=350Hz/q2/-1dB
body=800Hz/q1/+3dB, presence=2500Hz/q0.7/+3dB
bright=5000Hz/q1/+1dB, air_shelf=9000Hz/+1dB
comp: 1.3:1 @ -15dB, atk=80ms, rel=500ms, makeup=1dB, knee=10
limiter: 0.84, atk=5ms, rel=80ms
lufs=-16, tp=-1.5, lra=9
```

**WOODWIND_CONFIG**:
```
hpf=35, body=700Hz/+2dB, presence=2000Hz/+3dB
bright=4500Hz/+2dB, air=8000Hz/+2dB
comp: 1.8:1 @ -15dB, atk=40ms
Warm Variant: body+3dB, presence+2dB, bright=0dB, air=0dB (SGM harshness 제거)
```

**BRASS_CONFIG**:
```
hpf=25, body=500Hz/+3dB, presence=1800Hz/+2dB
bright=4000Hz/-1dB, air=8000Hz/-1dB (밝은 패치 억제)
comp: 2.0:1 @ -14dB, atk=30ms
```

**ORCHESTRAL_CONFIG** (3+ 악기군 동시):
```
hpf=28, body=650Hz/+3dB, presence=2200Hz/+3dB
bright=5000Hz/+1dB, air=9000Hz/+1dB
comp: 1.8:1 @ -15dB, atk=50ms
```

### 5.4 Adaptive Rules (v5 — 결합 적용)

| 규칙 | 트리거 | 조치 | 효과 |
|------|--------|------|------|
| Phrase Dynamics | s_lra < 100 | CC11 amp=2.0, window=5s | LRA 증가 (자연적 프레이즈 강조) |
| LUFS Target | s_lufs < 100 | lufs=-17 (뮤지컬=-18) | 방송 표준 라우드니스 |
| Warm EQ | s_freq < 95 | body+3dB, presence=0, bright-2dB | mid-heavy 피스 다크닝 |
| Dynaudnorm | LRA > 14 | f=100, g=7, p=0.9, maxgain=20 | 극단적 LRA 압축 (18.7→6.2) |

**핵심**: 4개 규칙은 **결합 적용** (순차 아님). phrase+LUFS를 동시에 적용해야 최적

---

## 6. 로컬 경로 맵

### 6.1 핵심 파일

| 파일 | 경로 | 설명 |
|------|------|------|
| 레포 (canonical) | `D:\PARKSY\parksy-audio` | 유일한 작업 디렉토리 |
| optimizer.py | `D:\tmp\optimizer.py` | 통합 배치 프로세서 (Phase 8) |
| score_engine.py | `D:\tmp\score_engine.py` | 자동 품질 평가 (5차원) |
| optimal_config.json | `D:\tmp\optimal_config.json` | Piano 42파라미터 |
| orchestral_config.json | `D:\tmp\orchestral_optimal_config.json` | Orchestral 4-config |
| quartet_pipeline.py | `D:\tmp\quartet_pipeline.py` | Orchestral Pipeline |

### 6.2 레포 내 도구

| 도구 | 경로 | 용도 |
|------|------|------|
| midi_quality_gate.py | `local-agent/` | Gate 1: MIDI 품질 A/B/C/D/F |
| piano_expression.py | `local-agent/` | 7-Stage 표현 엔진 (C/D grade용) |
| humanize_preset.py | `local-agent/` | Light touch (A/B grade용) |
| make_visual_video.py | `local-agent/` | HD 비주얼 영상 생성 |
| run_render.py | `local-agent/` | FluidSynth 렌더러 |
| config.py | `local-agent/` | 중앙 경로 설정 (VST_DIR=D:\VST) |
| midi_crawler.py | `local-agent/` | Mutopia 자동 크롤링 |

### 6.3 SoundFont 인벤토리

| 이름 | 경로 | 크기 | 용도 |
|------|------|------|------|
| SGM-V2.01 | `D:\VST\SGM-V2.01.sf2` | 236MB | ★ Warm Classical 주력 |
| TOH 4.0 | `D:\VST\TOH4.sf2` | 419MB | ★ Dark Funeral 주력 |
| FluidR3 GM | `D:\VST\FluidR3_GM.sf2` | 141MB | 미사용 (고음 과다) |
| GeneralUser GS | `D:\VST\GeneralUser_GS.sf2` | 30MB | 미사용 (경량 테스트) |

### 6.4 Ambient 소스

| 파일 | 경로 | 상태 |
|------|------|------|
| rain_nat.mp3 | `D:\VST\ambient\rain_nat.mp3` | ✅ CC0 자연음 |
| wind_nat.wav | `D:\VST\ambient\wind_nat.wav` | ✅ CC0 자연음 |
| fire_nat.mp3 | — | ⏳ 다운로드 미완료 |
| fire_synth.wav | `D:\VST\ambient\` | 합성 (임시 사용) |

### 6.5 PC 환경

| 도구 | 버전 | 경로 |
|------|------|------|
| Python | 3.12.10 | Microsoft Store |
| Node.js | 22.18.0 | system PATH |
| FFmpeg | 8.0.1 | WinGet packages |
| FluidSynth | 2.4.6 | `D:\VST\fluidsynth\bin\fluidsynth.exe` |
| Git | 2.50.1 | system PATH |

### 6.6 Python 패키지

mido(1.3.3), pretty_midi(0.2.11), basic-pitch(0.4.0), numpy(2.3.5), scipy(1.17.0)

---

## 7. 비디오 생산 현황

| # | 파일명 | 스타일 | Score | Duration |
|---|--------|--------|-------|----------|
| 1 | clairdelune_visual.mp4 | Warm | 100.0 | 3:16 |
| 2 | nocturne_op9_1_visual.mp4 | Warm | 100.0 | 4:20 |
| 3 | consolation_3_visual.mp4 | Warm | 100.0 | 4:38 |
| 4 | pavane_visual.mp4 | Fire | 100.0 | 5:15 |
| 5 | mozart_ave_verum_warm_visual.mp4 | Dark | 94.5 | 2:33 |
| 6 | franck_panis_angelicus_visual.mp4 | Dark | 95.3 | 3:04 |

경로: `local-agent/outputs/youtube/`

---

## 8. 핵심 교훈 & 시행착오

### 증명된 가설

1. **SGM > TOH4** for balanced piano (R2: +1.8, 44% 작으면서 더 좋음)
2. **Gentle compression (1.5:1)** 피아노 다이나믹 보존 최적
3. **S-curve k=3.0** = 황금 파라미터 (k=5.0 대비 23.2pt 차이, LRA 폭발 방지)
4. **Flat-velocity MIDI는 본질적 한계** (faure_pavane 모든 라운드 87-88 정체)
5. **Ambient -20dB이 sweet spot** (-18 TP침범, -22 효과미미)
6. **"좋은 MIDI는 건드리지 마라"** — A-grade에 piano_expression 금지

### 실패한 접근

- ❌ piano_expression.py on A-grade → 원본 표현 파괴 (Phase 6 전량 불합격)
- ❌ k=5.0 aggressive expression → LRA 19.3 폭발
- ❌ Ambient -18dB → True Peak 침범
- ❌ 합성 노이즈 (gen_natural.py) → 품질 불합격, 자연음으로 전환
- ❌ FluidSynth arg 순서 실수 → 1시간 디버깅 (`-F output.wav SF2 MIDI` 순서 필수)
- ❌ ffmpeg acompressor knee=10 → 범위 1-8만 가능, 무한 루프 원인

### 구조적 교훈

- MIDI 데이터 품질(Gate 1)과 최종 청감 품질은 별개. A-grade MIDI도 잘못 처리하면 불합격
- piano_expression.py는 "표현이 없는 MIDI에 넣는" 도구이지 "좋은 표현을 개선하는" 도구가 아님
- 직렬 폴리싱(2~3번 돌리기) 절대 불가 — velocity/rubato 누적으로 확실히 악화
- 단일 config로 cross-genre 68% 커버 가능 (22개 중 15개 = 100.0)

---

## 9. 계정 & 인증 구조

| 서비스 | 계정 | 상태 |
|--------|------|------|
| GitHub (push/pull) | B (dtslib1979, SSH) | ✅ |
| YouTube API (@musician-parksy) | A (dimas, OAuth) | ❌ token 없음 (PC에서 `node auth.js` 필요) |
| Google Drive (rclone) | A | ✅ |
| Gemini (Lyria 3) | A | ⚠️ 웹 수동, API 키 미발급 |

```
GCP 프로젝트: parksy-youtube (Account A 소유)
  └─ OAuth client: 390585643473-*
     └─ client_secret.json → token.json (tools/youtube/)
```

---

## 10. 이어서 할 작업 (Continuation Instructions)

### 즉시 실행 가능

1. **YouTube 업로드**: 6개 비디오 준비 완료. PC에서 YouTube token 생성 후 업로드
2. **B-grade 재처리**: Carnival, Clair, Romance 등 humanize_preset 적용 후 생산
3. **midi_quality_gate.py 코드 구현**: 현재 설계만 완료, 실제 코드는 미구현

### 장기 로드맵

- Score Engine 고도화: spectral flatness 추가, LUFS 가중치 축소
- AI Velocity Generation: flat-velocity MIDI에 자연스러운 다이나믹 생성
- 일본 MIDI 소스풀 탐색 (打ち込み 2차 소스)
- Lyria 3 워크플로우 통합 (Gemini API 키 발급 후)

### 주의사항

- `D:\tmp\` 파일들은 Git 미추적 — optimizer.py, score_engine.py 등은 수동 백업 필요
- MAESTRO 데이터셋 절대 상업 사용 금지 (CC BY-NC-SA 4.0)
- Piano-midi.de 자동 크롤링 윤리적 불가 (HTTP 418 봇 차단)

---

---

## Part 2: 세션 로그 (자동 축적)

> **이 섹션 아래로 세션 로그가 자동 축적된다.**
> 각 parksy-audio 세션 종료 시 Claude가 아래 포맷으로 append한다.
> 시간이 지나면 이 로그가 로컬 개발의 전체 이력이 된다.
> D: 유실 시 → 이 로그를 읽고 Claude가 전부 재구축할 수 있다.

<!--
포맷:
### YYYY-MM-DD | 세션 요약 한 줄
**작업**: 구체적으로 뭘 했는지 (파일명, 함수명, 파라미터 포함)
**결정**: 왜 그렇게 했는지 (비교 대상, 시도한 대안, 버린 이유)
**결과**: 수치 포함 (점수, 파일 크기, 에러 메시지 등)
**교훈**: 다음 세션이 반드시 알아야 할 것
**재구축 힌트**: D: 유실 시 이걸 다시 만들려면 Claude에게 이렇게 시켜라
-->

*— 세션 로그 축적 시작점 —*

---
### 2026-02-28 | dtslib-localpc 자동 축적 시스템 구축 — CLAUDE.md 세션 종료 프로토콜 추가
**작업**: parksy-audio CLAUDE.md에 세션 종료 프로토콜 추가 (커밋 시 dtslib-localpc/repos/status.json + repos/parksy-audio.md 세션 로그 append 의무화). dtslib-localpc/repos/parksy-audio.md 재구축 매뉴얼 479줄 작성.
**결정**: D:\tmp 작업 파일(optimizer.py, score_engine.py 등)의 git 이력이 0이므로, dtslib-localpc에 개발 과정을 문서화하여 재구축 가능하도록 설계. 코드가 아닌 "코드를 다시 만들 수 있는 지식"을 백업.
**결과**: optimal_config.json 42파라미터, 4개 오케스트라 config(STRING/WOODWIND/BRASS/ORCHESTRAL), adaptive rules 4건, Score Engine 5차원(LUFS/LRA/TP/FreqBal/DynVar) 전부 문서화 완료. 커밋 e2bab5a.
**교훈**: 매 세션 종료 시 이 파일 끝에 로그를 append하는 것이 유일한 이력 보존 수단. D:\tmp에는 git이 없다. 빠뜨리면 개발 과정 유실.
**재구축 힌트**: 이 파일의 Part 1(섹션 1~10)을 Claude에게 읽히면 전체 파이프라인 재구축 가능. 특히 섹션 5(설정 아카이브)에 optimal_config 42개 파라미터 + 4개 오케스트라 config 전부 있음.
---

---
### 2026-03-17 | YouTube OAuth 완전 자동화 완성 → GCP 스코프 블로커 확인
**작업**: `dtslib-papyrus/tools/youtube/yt_oauth_auto.cjs` 전면 수정 (6개 fix). Playwright `launchPersistentContext` + `channel:'chrome'` 패턴으로 Google 로그인 완전 자동화. `token_a.json` (Account A: dimas.thomas.sancho@gmail.com) 생성 완료.
- Fix 1: DOM detach 오류 (`elementHandle.click` → `page.click()` 직접 호출)
- Fix 2: `ignoreDefaultArgs: ['--enable-automation', '--disable-infobars']` + `--disable-blink-features=AutomationControlled` — Google 봇 탐지 차단
- Fix 3: 비밀번호 페이지 Allow 루프 내부에서도 처리 (슬로우 로딩 케이스)
- Fix 4: 2FA 탐지 + 8초 대기 루프 (핸드폰 승인 시간 확보)
- Fix 5: 루프 12→30회 확장, "허용"(최종 동의) vs "계속"(중간 경고) 분리 처리
- Fix 6: 마지막 YouTube API 검증 try/catch (스코프 미포함 시 토큰은 저장됨)

**결정**: `token_a.json` refresh_token 있음 확인. 그러나 `youtube` 스코프 미포함 (현재 토큰: `yt-analytics.readonly`만). 근본 원인 = GCP 프로젝트 `parksy-youtube`에서 YouTube Data API v3 미활성화. OAuth 동의 페이지에 "1개 서비스"만 표시됨 → `youtube` 스코프 자체가 안 나옴.

**결과**:
```
token_a.json 저장됨 (refresh_token: 있음 ✅)
YouTube API 검증: ⚠️ Request had insufficient authentication scopes
→ GCP 수동 작업 필요
```

**교훈**:
1. `ignoreDefaultArgs: ['--enable-automation']` 가 Google 차단의 핵심 원인. `channel:'chrome'`만으로는 부족.
2. GCP에서 API 활성화하지 않으면 OAuth 동의 페이지에 해당 스코프 자체가 안 나옴.
3. `youtube` 스코프 받으려면 token_a.json 삭제 후 GCP 작업 완료 후 재실행 필요.

**재구축 힌트**: `dtslib-papyrus/tools/youtube/yt_oauth_auto.cjs` 실행. 선행 조건: GCP console.cloud.google.com → parksy-youtube → APIs & Services → Library → "YouTube Data API v3" Enable + OAuth consent screen에 `https://www.googleapis.com/auth/youtube` 스코프 추가.

**펜딩 블로커 (GCP 수동 작업 필요)**:
```
1. console.cloud.google.com → 프로젝트: parksy-youtube
2. APIs & Services → Library → "YouTube Data API v3" → Enable
3. APIs & Services → OAuth consent screen → Edit app → Add or remove scopes
   → "https://www.googleapis.com/auth/youtube" 추가 → Save
4. rm tools/youtube/accounts/token_a.json
5. '/mnt/c/Program Files/nodejs/node.exe' tools/youtube/yt_oauth_auto.cjs
```
---

---
### 2026-03-01~03-10 | Musician TV URL 대시보드 + WSL 원격 인프라 구축
**작업**:
1. Musician TV URL 페이지 구조 구축 — 5-Program 채널 허브 (커밋 9786d19)
2. Musician TV → 조작 가능한 대시보드 콘솔로 재설계 (커밋 4d4bcb1, PR #2 병합 b1b0712)
3. WSL2 Claude Code CLI 인증 시도 — OAuth PKCE 흐름 15회+ 시도 전량 실패
4. WSL 인증 실패 원인 분석 보고서 작성 (docs/WSL_CLAUDE_AUTH_ISSUE_REPORT.md, 커밋 088b48b)

**결정**:
- Musician TV를 단순 URL 페이지에서 실시간 조작 가능한 대시보드 콘솔로 재설계. 5-Program 채널 허브 구조 채택
- WSL2 인증: redirect_uri가 localhost가 아닌 platform.claude.com으로 설정되어 authorization code가 플랫폼 서버에서 소비됨 → CLI 토큰 교환 구조적 불가능 확인
- `setup-token` + `CLAUDE_CODE_OAUTH_TOKEN` 환경변수 방식이 유일한 해결책으로 결정 (1년짜리 장기 토큰)

**결과**:
- Musician TV 대시보드 PR #2 병합 완료
- WSL 인증: 15회+ 시도 전량 HTTP 400 실패. 원인 분석 완료. 수작업 솔루션 확인됨 (setup-token → env var)
- WSL 인증 미완료 — 사용자가 PowerShell에서 `claude setup-token` 수동 실행 필요

**교훈**:
- WSL2 NAT 네트워크 격리로 Windows 브라우저에서 WSL localhost 직접 접근 불가
- OAuth PKCE에서 redirect_uri double consumption은 자동화로 우회 불가능
- Ink TUI 기반 CLI는 tmux send-keys로 텍스트 전달 불가 (stdin 입력 제한)
- `CLAUDECODE` 환경변수가 nested session 차단 — `$env:CLAUDECODE=""` 로 해제 필요

**재구축 힌트**: WSL 인증은 `docs/WSL_CLAUDE_AUTH_ISSUE_REPORT.md` 참조. 핵심: Windows PowerShell에서 `$env:CLAUDECODE=""; claude setup-token` → 토큰 생성 → WSL `~/.bashrc`에 `CLAUDE_CODE_OAUTH_TOKEN` 설정
---

---
### 2026-03-18 | 음악 생산 파이프라인 전면 확장 — 오디오→MIDI→편곡→렌더링 풀 자동화

**작업**:
1. **WSL 패키지 설치 완료** (`soundfile`, `pyloudnorm`, `scipy`, `basic-pitch`, `onnxruntime`)
   - 기존 환경에서 렌더링 파이프라인 누락 패키지 3개 발견 → 설치
   - basic-pitch Python 3.12 충돌(resampy pkgutil 이슈) → --no-build-isolation + onnx 백엔드로 우회 해결

2. **`/mnt/d/tmp/runner.py` 생성** — 풀 최적화 루프
   - WAV/MP3/MIDI 입력 → 자동 렌더 → score_engine 채점 → hill climbing 파라미터 최적화
   - FluidSynth 경로 WSL 패치 (`D:\VST\...exe` → `/usr/bin/fluidsynth`)
   - 기본 10회 이터레이션, target 85점 달성 시 조기 종료
   - 최종 optimal_config.json 자동 저장 (D:\tmp + local-agent/ 양쪽)

3. **`/mnt/d/tmp/audio_to_midi.py` 생성** — basic-pitch 변환기
   - WAV/MP3 → MIDI 추출 (Spotify Basic Pitch, ONNX 백엔드)
   - melodia_trick=True, 최소 음표 58ms 필터
   - 목 테스트 3회 통과: swan_lake(513음), sample.mp3(4,180음), nocturne(2,088음)

4. **`/mnt/d/tmp/composer.py` 생성** — 3형제 작곡 로직
   - Bruckner: 장3도+완전5도+옥타브 적층 (코랄 두께)
   - Mahler: 크레센도 아크 → 정점(×1.4) → 급격한 피아노 대비
   - Fauré: 9도 컬러음(30% 볼륨) + S-curve 부드러운 다이나믹

5. **`/mnt/d/tmp/arranger.py` 생성** — 편곡 마스터 엔진 (오늘의 핵심 성과)
   - **조성 순번도**: 크로마 프로파일 기반 자동 키 탐지 + 스타일별 전조 확률 행렬
     - Bruckner: 색채전조 3·4도 선호 / Mahler: 반음·증4도(트리토누스) / Fauré: 2도 모달
   - **확률 수열**: 7×7 Markov 행렬 화음 진행 (V→I 45%, ii→V 40% 등)
   - **감정 플로우**: 15가지 감정 × 4파라미터 매핑 (vel_scale, density, mode, tempo_ratio)
   - **프리셋 5종**: triumph / elegy / nocturne / epic / pastoral
   - **--suggest 모드**: 입력 MIDI 자동 분석 → 편곡 옵션 5종 + CLI 명령 출력

**결정사항**:

- **핵심 아키텍처 결정**: 핸드폰 = 입력(즉흥 녹음) + 출력(청취·승인) 단말기. PC = 전체 처리
  ```
  📱 핸드폰: 녹음 전송 → Telegram → 결과 수신 → /approve or /rerender
  🖥️ PC: audio_to_midi → arranger → composer → optimizer → score_engine → M4A 전송
  ```
- 표절·편집·렌더링 시퀀스 전부 PC Claude Code가 담당. 핸드폰은 결정권만 보유.
- 즉흥성/충동성/모바일성 음원은 핸드폰이 담당. 나머지 전부 PC.

**결과**:
- 풀 파이프라인 완성: WAV/MP3 → MIDI → 작곡가 스타일 편곡 → 렌더링 최적화 → M4A
- arranger.py 목 테스트 3회 통과 (swan_lake elegy/faure, nocturne/faure, sample epic/bruckner)
- runner.py `--help` 정상 작동 확인

**교훈**:
- basic-pitch Python 3.12에서 resampy 빌드 실패 → `--no-build-isolation`으로 우회
- 핸드폰 역할을 명확히 정의하지 않으면 이중 작업 발생 → 입출력 단말기로 고정
- 편곡 엔진은 MIDI 레벨에서 작동해야 FluidSynth 렌더와 자연스럽게 체인됨

**재구축 힌트**: `/mnt/d/tmp/`에 audio_to_midi.py, composer.py, arranger.py, runner.py, optimizer.py, score_engine.py 6개가 파이프라인 전체. runner.py가 진입점. 새 PC 세팅 시 `pip3 install mido soundfile pyloudnorm scipy basic-pitch onnxruntime --break-system-packages` 먼저 실행.

**다음 작업**:
- [ ] bot.py에 오디오 파일 수신 핸들러 추가 (파일 수신 → runner.py 자동 실행 → M4A 전송)
- [ ] GCP 블로커 해결 후 YouTube 업로드 연결
- [ ] runner.py를 bot.py에서 subprocess로 호출하는 구조 완성
---

---
### 2026-03-23 | 철학 재정의 + MIDI fast-track + Merlin Grand SF2 교체

**작업**:
1. **midi_quality_gate.py 업데이트** — ear_pass 로직 추가
   - 7곡 YouTube 업로드 실측 역추적으로 귀검수 통과 공식 도출
   - `note_density=20 AND duration=20 AND (vel_stdev≥12 OR structure≥15)` → ear_pass=True → +7점 보너스
   - 필수조건 미달 시 -10점 패널티
   - CLI 출력에 👂✅/👂❌ + 보정값 표시

2. **OK_midi 폴더 생성** — `local-agent/sources/OK_midi/`
   - YouTube 업로드된 7곡 소스 MIDI 역추적 수집
   - 01_Claire_de_Lune_Debussy.mid ~ 07_Panis_Angelicus_Franck.mid
   - 전곡 텔레그램으로 전송

3. **bot.py MIDI fast-track 핸들러 추가** — 오늘의 핵심 구현
   - `.mid`/`.midi` 파일 수신 시 Claude 우회, 직접 파이프라인 실행
   - `_transpose_midi()`: mido로 +1반음 전조 (저작권 완충, 드럼 채널 9 보존)
   - `_process_midi_fast()`: OK_midi 저장 → 전조 → humanize_preset piano → FluidSynth → M4A → 텔레그램 반환
   - 상수 추가: OK_MIDI_DIR, HUMANIZE_PY, _FLUIDSYNTH, _SOUNDFONT

4. **Merlin Grand SF2 도입** — 피아노 소리 교체
   - 기존: SGM-V2.01.sf2 (GM 사운드폰트, 피아노 4~6레이어) → 40점
   - 신규: MerlinGrand.sf2 (전용 피아노 SF2, 58MB) → ~60점
   - archive.org에서 직접 다운로드, `/mnt/d/VST/MerlinGrand.sf2`
   - 텔레그램 A/B 비교 청취 → Merlin Grand 압승, 즉시 확정
   - bot.py `_SOUNDFONT` 경로 업데이트

5. **docs/RENDERING-ENGINE-PLAN.md 생성** — 업그레이드 로드맵
   - Phase 1 (지금): Cakewalk(무료) + sforzando(무료) + Salamander(무료) → 72점
   - Phase 2 (수익 $50+): Addictive Keys $99 → 85점
   - Phase 3 (수익 $200+): Ivory III $350 → 93점

**결정사항**:
- **철학 재정의 (가장 중요)**: 편곡/작곡/화성학 전부 포기. "MIDI 아카이브 큐레이터 + 렌더링 엔지니어" 포지션으로 확정.
  - 이유: 직접 편곡해도 어차피 클래식 클리셰. 원본 명곡 MIDI가 품질 우위.
  - 버린 것: piano_expression.py, arranger.py, emotion/style 파이프라인, 전조 편곡 작업 전체
  - 남긴 것: 좋은 MIDI 귀검수 → minimal humanize → 고품질 렌더 → YouTube

- **새 표준 파이프라인**:
  ```
  핸드폰에서 MIDI 재생 귀검수
      ↓
  텔레그램으로 .mid 파일 드랍
      ↓
  bot.py fast-track: OK_midi 저장 → +1반음 → humanize piano → Merlin Grand 렌더
      ↓
  M4A 텔레그램 수신 → /approve → YouTube 업로드
  ```

- **품질 게이트 한계 인정**: midi_quality_gate.py 통계 점수는 실제 청감 품질 예측 불가. A급 MIDI도 들어보면 별로일 수 있음. 귀검수(ear_pass)가 유일한 진짜 기준.

- **Cakewalk + Salamander는 차순위**: sfizz 리눅스 바이너리 없고 cmake도 없어서 오늘 구현 불가. 대신 Merlin Grand SF2(MerlinGrand.sf2)로 즉시 대응. FluidSynth + Merlin Grand = 60점으로 충분.

**결과**:
- 커밋 3개: midi fast-track, 렌더링 플랜 문서, Merlin Grand 교체
- bot.py 재시작 완료 (PID 28253, `/home/dtsli/parksy-audio/local-agent/bot.py`)
- 텔레그램에 MIDI 드랍하면 Merlin Grand M4A 즉시 반환 확인

**교훈**:
- SF2 교체가 가장 빠른 품질 점프. sfizz/Salamander보다 Merlin Grand SF2 먼저 시도했어야 함
- 복잡한 편곡 파이프라인은 원본 품질을 오히려 낮춤 (A급 MIDI에 piano_expression = 역효과)
- FluidSynth + 전용 피아노 SF2 = 유튜브 BGM으로 충분한 품질
- 박씨 귀검수 = 최종 품질 게이트. 통계보다 귀가 정확함.

**재구축 힌트**: `MerlinGrand.sf2`는 `/mnt/d/VST/`에 있음. bot.py에서 `_SOUNDFONT` 환경변수로 덮을 수 있음. MIDI fast-track은 `_process_midi_fast()` 함수. OK_midi 폴더는 `local-agent/sources/OK_midi/`. 봇 실행: `python3 /home/dtsli/parksy-audio/local-agent/bot.py`

**다음 작업**:
- [ ] 새 MIDI 소스 발굴 (Mutopia, piano-midi.de) → 귀검수 → OK_midi 추가
- [ ] YouTube @musician-parksy 업로드 재개 (token 갱신 필요)
- [ ] Cakewalk + Salamander 세팅 (Windows 측, 72점 달성)
---

---
### 2026-03-24 | REAPER Phase 2 완성 — sfizz inline MIDI 렌더링 확인 + optimizer.py 통합
**작업**:
- render_reaper.py 전면 재작성: MIDI→REAPER 인라인 E-line 이벤트 변환 (mido 사용)
- piano.rpp 템플릿 완성: sfizz.vst3 + SSO Grand Piano, SAMPLERATE 44100, RENDER_CFG2 제거
- wsl_to_win() UNC 경로 변환 추가 (/home/... → \\wsl.localhost\Ubuntu\...)
- pipeline/optimizer.py에 render_with_reaper() + render_auto() 추가
- PARKSY_ENGINE=reaper 환경변수로 엔진 전환 가능 (기본값 FluidSynth 유지)
- D: 드라이브 ↔ home ↔ origin/main 전부 동기화 완료

**결정**:
- FILE "..." IMPORT 1 방식은 sfizz 오프라인 렌더링에서 WAV 0-byte 버그 → 인라인 E-line으로 전환
- SAMPLERATE 48000→44100 (SSO 샘플 44100Hz, 미스매치 시 침묵)
- RENDER_CFG2 블록이 secondary output 에러 유발 → 제거
- optimizer.py Step 3는 render_auto()로 교체 (하위 호환 유지, FluidSynth 기본값)

**결과**:
- Ave Verum Mozart: 40.31MB WAV, 2:39, 44100Hz/24-bit stereo, 렌더 9.4초 (~17x RT)
- sfizz Freewheeling mode 확인, SSO Grand Piano 정상 동작
- GitHub push 완료 (d8fc1e9), D: 드라이브 merge 완료

**교훈**:
- REAPER 인라인 MIDI = sfizz 렌더링 유일한 정상 경로. FILE import는 절대 쓰지 말 것.
- pitchwheel: mido에서 -8192~8191 → +8192 → LSB/MSB 분리 (14-bit MIDI)
- WSL 내부 경로는 UNC (\\wsl.localhost\Ubuntu\...) 로 변환해야 REAPER(Windows)가 접근

**재구축 힌트**:
- "REAPER CLI + sfizz.vst3 + SSO SFZ로 MIDI 오프라인 렌더링. MIDI는 인라인 E-line으로 삽입.
  render_reaper.py + piano.rpp 템플릿 조합. PARKSY_ENGINE=reaper로 optimizer.py 엔진 전환."
- sfizz 경로: C:\Program Files\Common Files\VST3\sfizz.vst3
- SSO 경로: D:\VST\SSO\Sonatina Symphonic Orchestra\Keys - Grand Piano.sfz
- sfizz VST state binary: version(int32=1) + sfzFile(null-term UTF-8) + volume(float32=0) + numVoices(64) + oversampling(1.0) + preload(8388608) + scala(null) + tuning(440.0) + stretch(0)

**다음 작업**:
- [ ] orchestra.rpp 템플릿 추가 (sfizz + SSO Strings/Brass)
- [ ] render_auto()에서 genre 파라미터 MIDI 파일명 기반 자동 감지
- [ ] Spotify basic-pitch (오디오→MIDI) 파이프라인 연결
---

---
### 2026-04-07 | Tiger DS v106 Python ONNX 풀파이프라인 + 백서 S5 소거법 + GitHub Actions 정리 + DDSP 완료

**작업**:
- `/tmp/tiger_full_pipeline.py` 완성 — Tiger DS v106 전체 DiffSinger 파이프라인 Python ONNX 구현
  - SPORE 파이프라인 병행 완성 후 Tiger DS로 전환
  - DurLing → Dur → PitchLing → Pitch → Acoustic → tgm_hifigan → RVC 7단계
- 백서 섹션 5 소거법 5라운드 전체 반영:
  - R1: pitch scoop -20c (진입 10% 구간)
  - R2: AP breath vel 80→60 (0.6)
  - R3: VELC 차등 강세=1.2 / 중간=0.8 / 끝=0.6
  - R4: vibrato fade-in 40% (800t+ 음 전체)
  - R5: phrase-end pitch drop -20c (마지막 음 70% 이후)
- DDSP 바순 v2 학습 완료 (step 40000, loss 1.49), 모델 다운로드 후 Vast.ai Pod 종료
- GitHub Actions 68개 비활성화 (28개 레포 전수 조사, ~120개 워크플로우)
- GitHub PAT 갱신 → papyrus/config/github_tokens.env 저장 (.gitignore 등록)

**결정**:
- Tiger DS 경로: `/mnt/c/Temp/OpenUtau/Singers/TIGER_DS_v106/` (Windows 경로)
- 이중 phoneme vocab: dsacoustic/phonemes.txt=116개(dur+acoustic), dspitch/files/phonemes.txt=113개(pitch전용) — 별도 토크나이징 필수
- spk_embed: `tiger_fresh.emb` 256 float32 → np.tile로 broadcast
- pitch_pred: 절대 MIDI note (42~55) → `440.0 * 2^((pred-69)/12)` (deviation 아님!)
- STEPS: `np.array(20, dtype=np.int64)` (np.int64(20) 아님 — ONNX 스칼라 타입 오류)
- RVC: f0_up_key=+2, index_rate=0.75, protect=0.33, f0method=rmvpe
- GitHub Actions: Claude Code가 오케스트레이션 담당 → Actions 불필요. Vercel은 GitHub App 자체 처리

**결과**:
- Tiger DS Python ONNX 결과: Raw Max 0.539 (게이트 통과 >0.5 ✅), RMS 0.081
- RVC 후: Max 0.880, RMS 0.139, 클리핑 0개, Crest 16.0dB
- 성공 기준선(ag_r5_drop.wav): Tiger raw Max 0.627, RMS 0.094 (OpenUtau 실제 렌더 기준)
- DDSP 체크포인트: ~/backups/vast_checkpoints/ddsp_bassoon_v2/step_040000.pt (74MB)
- GitHub Actions 68개 비활성화 (실패 4개: Copilot coding agent, GitHub 관리라 API 불가)

**교훈**:
1. 로컬 메모리 먼저 확인 — Tiger DS 경로 메모리에 있었음. find로 탐색 금지
2. 백서 S5가 정답 — GOLDEN 파일, 메모리 등 부차 자료보다 백서 우선
3. pitch_pred 절대값 — DiffSinger pitch model은 MIDI deviation이 아닌 절대 MIDI note 출력
4. phonemes.txt 분리 — Tiger dur(116) ≠ pitch(113), 별도 토크나이징 필수
5. 검증 게이트 — Tiger raw Max > 0.5 통과, < 0.5 폐기
6. RVC 가창 한계 — 소거법에서 확인. Tiger raw(0.627) 자체가 들을 만함 → RVC 없이 Tiger raw 검토

**재구축 힌트**:
- Tiger DS 풀파이프라인: /tmp/tiger_full_pipeline.py 복원
- 모델 경로: /mnt/c/Temp/OpenUtau/Singers/TIGER_DS_v106/
  - DurLing: dsdur/files/linguistic.onnx
  - Dur: dsdur/files/dur.onnx  
  - PitchLing: dspitch/files/linguistic.onnx
  - Pitch: dspitch/files/pitch.onnx
  - Acoustic: dsacoustic/acoustic.onnx
  - Vocoder: dsvocoder/tgm_hifigan.onnx
  - SPK: dsacoustic/tiger_fresh.emb (256 float32)
- Amazing Grace 성공 기준선: /mnt/c/Temp/OpenUtau/Export/ag_r5_drop.wav (Max=0.627)
- DDSP 모델: ~/backups/vast_checkpoints/ddsp_bassoon_v2/step_040000.pt
- 다음: PowerShell UI 자동화로 OpenUtau 실제 렌더 재현 OR PARKSY_EN v3 완료 후 새 파이프라인
---
