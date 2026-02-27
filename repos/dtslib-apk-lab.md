# dtslib-apk-lab 현황

> **5개 앱 운영 중** — ChronoCall 빌드 대기, Wavesy 충돌 해결 완료

## 앱 포트폴리오

| 앱 | 폴더 | 상태 | 설명 |
|----|-------|------|------|
| Parksy Capture | capture-pipeline | Production | 공유 텍스트 캡처 |
| Parksy Pen | laser-pen-overlay | Production | S Pen 오버레이 |
| Parksy Wavesy | parksy-wavesy | Production | MP3/MIDI 오디오 에디터 |
| Parksy TTS | tts-factory | Production | TTS 변환 |
| Parksy ChronoCall | chrono-call | Code Complete | 통화 녹음 + STT |

## Store

- **URL**: https://dtslib-apk-lab.vercel.app/
- **Dashboard**: `dashboard/apps.json` + `dashboard/index.html`
- **Source of truth**: 각 앱 `pubspec.yaml`

## ChronoCall (활발한 개발 중)

### Phase 1 (Code Complete)
- FFmpeg 전처리 + Whisper API STT
- Samsung 통화 녹음 폴더 자동 감지
- 결과 뷰어 (타임스탬프 세그먼트 + 오디오 재생)
- Share Intent 수신, Markdown 내보내기
- Parksy Capture 자동 공유 토글

### Build 필요
```
flutter create . --org com.parksy
flutter pub get
flutter build apk --debug
```

### Phase 2 로드맵
- 배치 처리, 히스토리 검색, 날짜 필터
- Samsung 파일명 파싱 (전화번호 + 날짜)
- 다국어 (ko/en/ja/zh)

### Phase 3 (장기)
- Speaker diarization, On-device Whisper
- GPT 요약, 연락처 매칭

## 빌드 환경

| 항목 | 값 |
|------|-----|
| compileSdk | 34 |
| minSdk | 26 (Android 8.0) |
| targetSdk | 34 (Android 14) |
| NDK | 25.1.8937393 |
| AGP | 7.3.0 |
| Flutter | 필요 (현재 PATH에 없음) |

## 로컬 경로

| 파일 | 경로 |
|------|------|
| 레포 (canonical) | `D:\1_GITHUB\dtslib-apk-lab` |
| 레포 (C 드라이브 클론) | `C:\Users\dtsli\dtslib-apk-lab` |

**참고**: C 드라이브 클론은 `D:\1_GITHUB\`로 통합 권고

## 대기 작업

- [ ] ChronoCall: flutter create + build + 디바이스 테스트
- [ ] ChronoCall: APK 서명 + release 빌드
- [ ] Wavesy: libc++_shared.so 충돌 해결 완료, rebuild 필요
- [ ] Store listing 업데이트

## Git 상태

- Branch: `main`
- Last commit: `c8b7e3d` — fix(wavesy): resolve libc++_shared.so conflict
- Dirty: 0 files (clean)
