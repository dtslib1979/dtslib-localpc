# PC Hardware & Workload Specification

> 자동 수집일: 2026-03-01 | 모델: Dell XPS 13 9370

---

## 1. 하드웨어 사양

### 본체

| 항목 | 스펙 |
|------|------|
| **모델** | Dell XPS 13 9370 (2018) |
| **메인보드** | Dell Inc. 0F6P3V |
| **OS** | Windows 11 Home (Build 26200) |
| **System Type** | x64-based PC |
| **BIOS** | Dell Inc. 1.15.0 (2021-06-07) |

### CPU

| 항목 | 스펙 |
|------|------|
| **프로세서** | Intel Core i7-8550U @ 1.80GHz |
| **코어/스레드** | 4C / 8T |
| **Turbo Boost** | 최대 ~4.0 GHz |
| **L2 캐시** | 1 MB |
| **L3 캐시** | 8 MB |
| **TDP** | 15W (울트라북급) |

### RAM

| 항목 | 스펙 |
|------|------|
| **총 용량** | 16 GB (2 x 8 GB) |
| **타입** | LPDDR3 온보드 (슬롯 없음) |
| **제조사/모델** | Micron MT52L1G32D4PG-093 |
| **속도** | 2133 MHz |
| **구성** | 듀얼채널 |

### GPU

| 항목 | 스펙 |
|------|------|
| **GPU** | Intel UHD Graphics 620 (내장) |
| **VRAM** | 1 GB (공유) |
| **드라이버** | 31.0.101.2111 |
| **해상도** | 1920 x 1080 @ 59Hz |
| **외장 GPU** | 없음 |

### 스토리지

| 장치 | 모델 | 용량 | 타입 | 인터페이스 |
|------|------|------|------|-----------|
| **C: (내장 SSD)** | Samsung PM981a NVMe | 512 GB | NVMe SSD | PCIe 3.0 x4 |
| **D: (외장 HDD)** | WD My Passport | 2 TB | USB 외장 HDD | USB 3.0 |

### C: 드라이브 상태

| 항목 | 값 |
|------|-----|
| 전체 | 461 GB (포맷 후) |
| 사용 | 192 GB |
| 여유 | 269 GB (58%) |
| 파일시스템 | NTFS |

### D: 드라이브 상태

| 항목 | 값 |
|------|-----|
| 전체 | 1.82 TB (포맷 후) |
| 사용 | 454 GB |
| 여유 | 1.41 TB (77%) |
| 파일시스템 | exFAT |

### 오디오

| 장치 | 제조사 |
|------|--------|
| Realtek Audio | Realtek (내장) |
| **Focusrite USB Audio** | Focusrite Audio Engineering |
| Intel Display Audio | Intel (HDMI/DP) |

### 네트워크

| 항목 | 스펙 |
|------|------|
| 유선 | Realtek USB GbE (1 Gbps) |
| Wi-Fi | (내장, 현재 유선 사용 중) |

### 배터리

| 항목 | 값 |
|------|-----|
| 모델 | DELL H754V9A |
| 충전 | 100% (AC 연결) |

---

## 2. 소프트웨어 툴체인

### 시스템 도구

| 도구 | 버전 | 용도 |
|------|------|------|
| Python | 3.12.10 | 파이프라인 전체 (MIDI 처리, 품질 평가, 이미지 변환) |
| FFmpeg | 8.0.1 | 오디오 인코딩, 비디오 생성, LUFS 분석, 앰비언트 믹싱 |
| Node.js | 22.18.0 | YouTube Studio CLI, 텔레그램 브릿지 |
| npm | 10.9.3 | Node.js 패키지 관리 |
| Git | 2.50.1 | 소스 관리, 큐 동기화 |
| FluidSynth | 2.4.6 | MIDI → WAV 렌더링 엔진 |

### Python 핵심 패키지

| 패키지 | 버전 | 용도 |
|--------|------|------|
| mido | 1.3.3 | MIDI 파싱/편집 |
| pretty_midi | 0.2.11 | MIDI 분석/표현 |
| basic-pitch | 0.4.0 | 오디오→MIDI 변환 |
| numpy | 2.3.5 | 수치 연산 |
| scipy | 1.17.0 | 신호 처리 |
| opencv-python | 4.13.0.92 | 이미지 처리 (photo2drawing) |
| opencv-contrib | 4.13.0.92 | OpenCV 확장 |
| Pillow | 12.0.0 | 이미지 생성/편집 |
| fonttools | 4.61.1 | 폰트 빌더 (PSE) |

---

## 3. D: 드라이브 워크로드 맵

### 디렉토리별 사용량

| 경로 | 용량 | 파일 수 | 역할 |
|------|------|---------|------|
| `D:\VST\` | 6.27 GB | 4,383 | 오디오 엔진 (FluidSynth, SF2, SFZ, 앰비언트) |
| `D:\PARKSY\` | 16.44 GB | 6,834 | parksy-audio + dtslib-localpc 레포 |
| `D:\tmp\` | 18.04 GB | 4,775 | 실험/최적화 작업공간 |
| `D:\parksy-image\` | 0.22 GB | 3,932 | parksy-image 레포 |
| `D:\1_GITHUB\` | 0.39 GB | 13,378 | dtslib-apk-lab 등 기타 레포 |
| **합계** | **~41 GB** | **33,302** | |

### SoundFont 라이브러리 (D:\VST)

| 파일 | 용량 | 상태 |
|------|------|------|
| SGM-V2.01.sf2 | 235.9 MB | **Primary** (피아노+오케스트라) |
| TOH4.sf2 | 419.3 MB | Secondary (Dark Funeral 스타일) |
| FluidR3_GM.sf2 | 141.5 MB | 미사용 (열등) |
| GeneralUser_GS.sf2 | 29.8 MB | 미사용 (경량 테스트) |
| gs.sf2 | 29.8 MB | GeneralUser 복사본 |

---

## 4. 프로젝트별 PC 자원 사용 패턴

### parksy-audio (클래식 음악 자동 프로덕션)

```
워크플로우: MIDI → 품질게이트 → 전처리 → FluidSynth 렌더 → 마스터링 → 앰비언트 → 비주얼MP4

CPU 부하:
├── FluidSynth 렌더링: 싱글코어 집중 (~30초/곡, 48kHz)
├── FFmpeg 마스터링: 멀티코어 (~15초/곡)
├── score_engine 품질평가: 경량 (~2초/곡)
└── 배치 최적화 (22곡 x 6라운드): ~2시간 총

메모리 사용:
├── FluidSynth + SGM SF2 로드: ~500 MB
├── Python 파이프라인: ~200 MB
└── FFmpeg 피크: ~300 MB
└── 총 피크: ~1 GB (16 GB 중 여유 충분)

디스크 I/O:
├── 입력: MIDI (10-200 KB/곡)
├── 중간: WAV 48kHz (30-100 MB/곡)
├── 출력: MP4 AAC (5-15 MB/곡)
└── 실험 데이터 (D:\tmp): ~18 GB 축적
```

**병목 포인트:** FluidSynth는 싱글코어 전용 → i7-8550U의 4.0GHz Turbo로 처리. GPU 사용 없음.

### parksy-image (이미지/폰트/텔레그램 브릿지)

```
워크플로우: 사진→도면변환, PSE 폰트 빌드, 텔레그램 봇

CPU 부하:
├── OpenCV photo2drawing: 멀티코어 (~5초/이미지)
├── 폰트 빌드 (fonttools): 경량 (~3초/빌드)
└── 텔레그램 봇: 상시 대기 (무시할 수준)

메모리 사용:
├── OpenCV 이미지 처리: ~300 MB 피크
├── Node.js 텔레그램 봇: ~100 MB
└── 총 피크: ~400 MB
```

**병목 포인트:** 없음. 경량 워크로드.

---

## 5. 성능 한계 분석

### 이 PC가 잘하는 것 ✅

| 작업 | 이유 |
|------|------|
| MIDI → WAV 렌더링 | FluidSynth 싱글코어, i7 Turbo 4.0GHz 충분 |
| FFmpeg 오디오 마스터링 | 8스레드 병렬, 오디오는 경량 |
| Python 데이터 처리 | 16GB RAM으로 MIDI/오디오 분석 여유 |
| Git 작업/텔레그램 봇 | 네트워크 I/O 위주, 하드웨어 무관 |
| 이미지 → 도면 변환 | OpenCV CPU 처리, 단일 이미지 기준 빠름 |

### 이 PC의 한계 ⚠️

| 작업 | 병목 | 영향 |
|------|------|------|
| 영상 인코딩 (H.264/H.265) | GPU 없음 → CPU 소프트웨어 인코딩 | 1분 영상 인코딩 ~30초 |
| 대량 배치 렌더링 | 4코어 한계 | 22곡 배치 ~2시간 (병렬화 제한) |
| AI/ML 추론 | 외장 GPU 없음, CUDA 불가 | basic-pitch 등 CPU 전용 실행 |
| D: 드라이브 I/O | USB 3.0 외장 HDD (~100 MB/s) | WAV 읽기/쓰기 시 NVMe 대비 느림 |
| 실시간 오디오 처리 | 내장 사운드카드 한계 | Focusrite USB로 보완 가능 |

### 스토리지 용량 예측

```
D: 현재 사용: 454 GB / 1.82 TB (25%)
월간 증가 추정:
├── parksy-audio 렌더링: ~5 GB/월 (실험 WAV 포함)
├── parksy-image: ~0.5 GB/월
├── tmp 실험 데이터: ~3 GB/월
└── 총: ~8.5 GB/월

잔여 수명: 1,410 GB ÷ 8.5 GB/월 ≈ 166개월 (13년+)
→ 스토리지 부족 우려 없음
```

---

## 6. 주변기기 구성

| 장비 | 모델 | 연결 | 용도 |
|------|------|------|------|
| 외장 HDD | WD My Passport 2TB | USB 3.0 | D: 드라이브 (작업 데이터 전체) |
| 오디오 인터페이스 | Focusrite (USB Audio) | USB | 고품질 오디오 모니터링 |
| 유선 어댑터 | Realtek USB GbE | USB | 1 Gbps 유선 네트워크 |
| 디스플레이 | 내장 13" FHD | 내장 | 1920x1080 @ 59Hz |

---

## 7. Windows 시스템 폰트 (영상 제작용)

parksy-audio `make_visual_video.py`에서 참조:

| 폰트 | 경로 | 용도 |
|------|------|------|
| Georgia Bold | `C:\Windows\Fonts\georgiab.ttf` | 영상 제목 |
| Segoe UI Light | `C:\Windows\Fonts\segoeuil.ttf` | 부제목 |
| Consolas | `C:\Windows\Fonts\consola.ttf` | 기술 정보 |

---

*이 문서는 `dtslib-localpc` 환경 스냅샷의 일부로 관리됩니다.*
*PC 교체/업그레이드 시 이 문서를 기준으로 환경 재구축합니다.*
