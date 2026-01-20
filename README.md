# Tchaikovsky Sampler Library

Pyotr Ilyich Tchaikovsky의 주요 협주곡 테마를 담은 오디오 샘플러 라이브러리입니다.

## Contents

### Piano Concerto No.1 in B-flat minor, Op.23
- **Opening Theme** (90s) - 그 유명한 도입부
- Source: Martha Argerich 연주

### Violin Concerto in D major, Op.35
- **Opening Theme** (120s) - 1악장 주제
- Source: Jascha Heifetz 연주

### Piano Concerto No.2 in G major, Op.44
- **Opening Theme** (90s) - 1악장 시작부
- Source: Orchestral Recording

### Rococo Variations, Op.33
- **Main Theme** (60s) - 첼로와 오케스트라
- Source: Cello Performance

## Folder Structure

```
tchaikovsky-sampler-library/
├── samples/           # 원본 오디오 (full recordings)
│   ├── piano-concerto-1/
│   ├── piano-concerto-2/
│   ├── violin-concerto/
│   └── rococo-variations/
├── trimmed/           # 트림된 테마 (MP3)
│   ├── pc1-opening-theme-90s.mp3
│   ├── vc1-opening-theme-120s.mp3
│   ├── pc2-opening-theme-90s.mp3
│   └── rococo-main-theme-60s.mp3
├── midi/              # MIDI 변환본
│   ├── pc1-opening-theme.mid
│   ├── vc1-opening-theme.mid
│   ├── pc2-opening-theme.mid
│   └── rococo-main-theme.mid
└── metadata/          # 메타데이터
```

## Usage

### AIVA 작곡용
1. `trimmed/` 폴더의 MP3 파일을 AIVA에 업로드
2. 스타일 참조로 사용하여 새 곡 생성

### DAW 샘플링용
1. `midi/` 폴더의 MIDI 파일을 DAW에 임포트
2. 원하는 악기로 재생/편집

### Parksy Audio 연동
```bash
# Local Engine으로 추가 트림
parksy trim "samples/piano-concerto-1/pc1-argerich.mp3" -d 60 -s 30

# MIDI 변환 (온라인)
parksy convert "trimmed/pc1-opening-theme-90s.mp3" --online
```

## Technical Details

| File | Duration | Size | Format |
|------|----------|------|--------|
| pc1-opening-theme | 90s | ~1.9MB | MP3 192kbps |
| vc1-opening-theme | 120s | ~2.6MB | MP3 192kbps |
| pc2-opening-theme | 90s | ~2.1MB | MP3 192kbps |
| rococo-main-theme | 60s | ~1.2MB | MP3 192kbps |

## MIDI Files

| File | Size | Notes |
|------|------|-------|
| pc1-opening-theme.mid | 5.8KB | Piano + Orchestra |
| vc1-opening-theme.mid | 12.1KB | Violin + Orchestra |
| pc2-opening-theme.mid | 6.5KB | Piano + Orchestra |
| rococo-main-theme.mid | 2.1KB | Cello + Orchestra |

## Credits

- Audio Source: Public Domain Recordings
- MIDI Conversion: Parksy Audio Cloud API (basic-pitch)
- Curator: Parksy

## License

Educational and personal use only.
Original compositions by P.I. Tchaikovsky (1840-1893) are in Public Domain.

---

*Part of the Parksy Audio ecosystem*
*https://dtslib1979.github.io/parksy-audio/*
