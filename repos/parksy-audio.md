# parksy-audio 현황

> **Phase 8 Complete** — 마스터링 파이프라인 최적화 완료, YouTube 배포 대기

## 핵심 지표

| 항목 | 값 |
|------|-----|
| Piano Score | avg 96.4 (15/22 at 100.0) |
| Orchestral Score | avg 99.9 (12/12 >= 99.5) |
| Videos Produced | 6개 (MP4, YouTube-ready) |
| SoundFont | SGM-V2.01.sf2 |
| LUFS Target | -16, TP -1.5, LRA 9 |

## 파이프라인 아키텍처

### Piano Pipeline (Phase 8)
- 6라운드 체계적 A/B 테스트로 최적화
- 핵심 발견: S-curve k=3.0 (23.2pt swing vs k=5.0)
- Config: `D:\tmp\optimal_config.json`

### Orchestral Pipeline (v5 Adaptive)
- 4개 config: STRING, WOODWIND, BRASS, ORCHESTRAL
- 자동 감지: `detect_families()` → `get_config_for_midi()`
- dynaudnorm(f=100,g=7) → 극단 LRA 해결
- Config: `D:\tmp\orchestral_optimal_config.json`

## 로컬 경로

| 파일 | 경로 |
|------|------|
| 레포 | `D:\PARKSY\parksy-audio` |
| 작업 디렉토리 | `D:\tmp` |
| optimizer.py | `D:\tmp\optimizer.py` |
| score_engine.py | `D:\tmp\score_engine.py` |
| quartet_pipeline.py | `D:\tmp\quartet_pipeline.py` |
| FluidSynth | `D:\VST\fluidsynth\bin\fluidsynth.exe` |
| SGM SF2 | `D:\VST\SGM-V2.01.sf2` |
| SSO SFZ | `D:\VST\SSO\Sonatina Symphonic Orchestra\` |

## 대기 작업

- [ ] YouTube 업로드 실행 (6개 비디오)
- [ ] Score Engine 고도화 (LUFS 가중치 조정, spectral flatness 추가)
- [ ] 장르별 프로필 분리 (오케스트라 vs 피아노 솔로)
- [ ] AI Velocity Generation (flat-velocity MIDI 한계 극복)

## Git 상태

- Branch: `main`
- Last commit: `76a3131` — docs: 마스터링 파이프라인 개발일지
- Dirty: 1 file (.gitignore)
