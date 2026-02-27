# dtslib-apk-lab 개발 일지

> **Parksy 브랜드 Android 앱 포트폴리오**
> 5개 앱 운영 중 — Vercel 스토어 배포, ChronoCall 빌드 대기

---

## 1. 프로젝트 정체성

**dtslib-apk-lab**은 개인용 Android 앱 모음 프로젝트다. 모든 앱은 **Parksy** 브랜드를 사용하며, Flutter + Dart로 개발된다.

### 스토어

- **URL**: https://dtslib-apk-lab.vercel.app/
- **Dashboard**: `dashboard/apps.json` + `dashboard/index.html`
- **Source of truth**: 각 앱 `pubspec.yaml`

---

## 2. 현재 상태 (2026-02-28)

| 항목 | 값 |
|------|-----|
| Branch | `main` |
| Last Commit | `dd4b102` — docs: 세션 종료 프로토콜 추가 |
| 앱 수 | 5개 (4 Production + 1 Code Complete) |
| 활발한 개발 | ChronoCall (빌드 대기) |
| 로컬 경로 (canonical) | `D:\1_GITHUB\dtslib-apk-lab` |
| C 드라이브 클론 | `C:\Users\dtsli\dtslib-apk-lab` (통합 권고) |

---

## 3. 앱 포트폴리오

| 앱 | 폴더 | 상태 | 설명 |
|----|-------|------|------|
| **Parksy Capture** | `apps/capture-pipeline` | Production | 공유 텍스트 캡처 |
| **Parksy Pen** | `apps/laser-pen-overlay` | Production | S Pen 오버레이 |
| **Parksy Wavesy** | `apps/parksy-wavesy` | Production | MP3/MIDI 오디오 에디터 |
| **Parksy TTS** | `apps/tts-factory` | Production | TTS 변환 |
| **Parksy ChronoCall** | `apps/chrono-call` | Code Complete | 통화 녹음 + STT |

### 프로젝트 구조

```
apps/
├── capture-pipeline/    # 공유 텍스트 캡처 앱
├── laser-pen-overlay/   # S Pen 오버레이 앱
├── parksy-wavesy/       # 음원 편집 가위 (MP3/MIDI)
├── tts-factory/         # TTS 변환 앱
└── chrono-call/         # 통화 녹음 STT 변환 앱

dashboard/
├── apps.json            # 스토어 표시용 앱 목록
└── index.html           # 스토어 페이지
```

---

## 4. ChronoCall — 상세 개발 기록

> **코드 100% 완성, flutter create + build 필요**

### 4.1 스펙 요약

| 항목 | 값 |
|------|-----|
| 앱 이름 | Parksy ChronoCall |
| 패키지명 | com.parksy.chronocall |
| 버전 | 1.0.0+1 |
| 개발 브랜치 | `claude/voice-content-pipeline-epaN1` |
| Dart 파일 | 9개, 2,161줄 |
| Kotlin 파일 | 1개, 145줄 |
| 런타임 의존성 | 9개 |

### 4.2 파일 구조 & 역할

```
apps/chrono-call/
├── pubspec.yaml                         # Flutter 의존성 (9개 runtime)
├── app-meta.json                        # 스토어 메타데이터
├── analysis_options.yaml                # 린터 설정
│
├── lib/
│   ├── main.dart                        # (259줄) 앱 진입점
│   │   ├── ChronoCallApp               #   MaterialApp (다크 테마)
│   │   ├── PermissionGate              #   권한 게이트 (audio/storage/manage)
│   │   └── IntentChannel               #   Platform Channel 헬퍼
│   │
│   ├── core/
│   │   └── constants.dart               # (29줄) 11개 static 필드
│   │
│   ├── models/
│   │   └── transcript.dart              # (143줄) TranscriptSegment + Transcript
│   │       └── toMarkdown(), toShareText()
│   │
│   ├── services/
│   │   ├── audio_preprocessor.dart      # (104줄) FFmpeg 전처리
│   │   ├── whisper_service.dart         # (141줄) OpenAI Whisper API
│   │   └── storage_service.dart         # (84줄) SharedPreferences + 파일 내보내기
│   │
│   └── screens/
│       ├── home_screen.dart             # (748줄) 메인 화면 ★ 가장 큰 파일
│       ├── transcript_screen.dart       # (437줄) 결과 화면 (오디오 재생 + seek)
│       └── settings_screen.dart         # (216줄) 설정 화면
│
└── android/
    ├── build.gradle                     # AGP 7.3.0
    ├── app/build.gradle                 # compileSdk 34, minSdk 26, targetSdk 34
    └── src/main/
        ├── AndroidManifest.xml          # 권한 6개, intent-filter (audio/* 공유 수신)
        └── kotlin/.../MainActivity.kt   # (145줄) content:// URI 복사, Platform Channel
```

### 4.3 의존성 목록

```yaml
file_picker: ^8.0.0              # 파일 선택 UI
just_audio: ^0.9.36              # 오디오 재생
ffmpeg_kit_flutter_audio: ^6.0.3 # 오디오 전처리 (mono 16kHz 64kbps)
path_provider: ^2.1.1            # 앱 디렉토리 접근
share_plus: ^10.0.0              # 공유 인텐트 (→ Parksy Capture)
dio: ^5.4.0                      # HTTP 클라이언트 (Whisper API)
shared_preferences: ^2.2.2       # 로컬 저장소
intl: ^0.19.0                    # 날짜 포맷
permission_handler: ^11.3.0      # 런타임 권한
```

### 4.4 Android 설정

```
compileSdk: 34
minSdk: 26 (Android 8.0 Oreo)
targetSdk: 34 (Android 14)
NDK: 25.1.8937393
Java: 1.8
AGP: 7.3.0
```

#### 매니페스트 권한

| 권한 | 용도 |
|------|------|
| INTERNET | Whisper API 호출 |
| READ_EXTERNAL_STORAGE (max SDK 32) | Android 12 이하 |
| WRITE_EXTERNAL_STORAGE (max SDK 28) | Android 9 이하 |
| MANAGE_EXTERNAL_STORAGE | 전체 저장소 접근 (최후 수단) |
| READ_MEDIA_AUDIO | Android 13+ |
| POST_NOTIFICATIONS | 알림 (향후) |

#### Intent Filter

```xml
<!-- 다른 앱에서 오디오 공유받기 -->
<action android:name="android.intent.action.SEND" />
<data android:mimeType="audio/*" />
```

### 4.5 STT 파이프라인 상세

```
Step 1: 파일 존재 확인
Step 2: FFmpeg getDuration() → Duration 표시
Step 3: FFmpeg preprocess() → mono 16kHz 64kbps m4a
         입력: 삼성 기본 녹음 (stereo, 44.1kHz, ~5MB/분)
         출력: Whisper 최적화 (mono, 16kHz, 64kbps, ~0.5MB/분)
Step 4: 파일 사이즈 체크 (≤25MB = Whisper 제한)
Step 5: Whisper API 호출 (verbose_json + segment timestamps)
Step 6: Transcript 객체 생성 + SharedPreferences 저장
Step 7: auto-share 켜져있으면 → Share.share() → Parksy Capture
Step 8: TranscriptScreen 으로 네비게이션
```

### 4.6 삼성 녹음 폴더 탐지

시도 순서 (자동):
1. `/storage/emulated/0/Recordings/Call` ← One UI 4+
2. `/storage/emulated/0/DCIM/.Recordings/Call` ← One UI 3
3. `/storage/emulated/0/Call` ← 일부 구형
4. `/storage/emulated/0/Record/Call` ← 일부 통신사 커스텀

### 4.7 Share Intent 수신

```
다른 앱 → "공유" → ChronoCall 선택
→ Kotlin: content:// URI → /cache/chrono_imports/filename 복사
→ Dart: IntentChannel.getSharedAudio() → 확인 다이얼로그 → _transcribeFile()
```

### 4.8 Transcript 뷰어

- 상단: 메타 바 (duration, language, segment 수, 글자 수)
- 중단: just_audio 재생기 (play/pause, seek bar)
- 하단: 세그먼트 목록 (탭하면 해당 위치로 seek, AnimatedContainer 하이라이트)
- 액션: Copy, Share (→ Capture), Export Markdown, Copy with timestamps

### 4.9 색상 팔레트 (다크 테마)

```dart
const kBackground = Color(0xFF1A1A2E);  // 메인 배경
const kSurface    = Color(0xFF16213E);  // 카드, AppBar
const kAccent     = Color(0xFFE8D5B7);  // 골드 액센트
```

### 4.10 Platform Channel

```
Channel: "com.parksy.chronocall/intent"

Dart → Kotlin:
  getSharedAudio()       → Map{"path", "name"} | null
  copyUriToLocal(uri)    → Map{"path", "name"} | null
  getAudioMetadata(path) → Map{"exists", "sizeBytes", "sizeMB", "lastModified", "name"}
```

### 4.11 임포트 그래프

```
main.dart
  └→ screens/home_screen.dart
       ├→ core/constants.dart
       ├→ models/transcript.dart
       ├→ services/audio_preprocessor.dart
       ├→ services/whisper_service.dart
       ├→ services/storage_service.dart
       ├→ screens/settings_screen.dart
       └→ screens/transcript_screen.dart
            └→ services/storage_service.dart
```

---

## 5. Wavesy 이슈 기록

### libc++_shared.so 충돌

- **문제**: FFmpeg Kit과 다른 네이티브 라이브러리 간 libc++_shared.so 충돌
- **해결**: `c8b7e3d` — fix(wavesy): resolve libc++_shared.so conflict
- **상태**: 해결 완료, rebuild 필요

---

## 6. 빌드 환경

| 항목 | 값 |
|------|-----|
| compileSdk | 34 |
| minSdk | 26 (Android 8.0) |
| targetSdk | 34 (Android 14) |
| NDK | 25.1.8937393 |
| AGP | 7.3.0 |
| Flutter | 필요 (현재 PC PATH에 없음) |

### 빌드 명령 (ChronoCall)

```bash
cd apps/chrono-call
flutter create . --org com.parksy    # 보일러플레이트 생성 (최초 1회)
flutter pub get                       # 의존성 설치
flutter build apk --debug            # 디버그 빌드
```

### 빌드 실패 시 체크리스트

| 에러 | 원인 | 해결 |
|------|------|------|
| `NDK not found` | NDK 미설치 | `sdkmanager "ndk;25.1.8937393"` |
| `Gradle build failed` | AGP 버전 불일치 | android/build.gradle 확인 |
| `Namespace not specified` | Android Gradle 8+ | AGP 7.3 유지하면 OK |
| `ffmpeg_kit not found` | pub get 안됨 | `flutter pub get` 재실행 |
| `minSdk 26 conflict` | 의존성 충돌 | `flutter pub upgrade` |

---

## 7. 버전 관리 규칙

버전은 항상 `pubspec.yaml`이 source of truth:

| 파일 | 역할 |
|------|------|
| `apps/{app}/pubspec.yaml` | Flutter 앱 버전 (source of truth) |
| `apps/{app}/app-meta.json` | 앱 메타데이터 |
| `dashboard/apps.json` | 스토어 페이지 표시 |
| `AndroidManifest.xml` | Android 앱 라벨 |
| `strings.xml` | Android 문자열 리소스 |

### 버전 올릴 때 동기화

```
1. pubspec.yaml          → version: X.Y.Z+N
2. core/constants.dart   → version = 'X.Y.Z', versionCode = N
3. app-meta.json         → "version": "vX.Y.Z"
4. dashboard/apps.json   → 해당 앱 항목 version, lastUpdated
```

---

## 8. Phase 로드맵

### Phase 1 (v1.0.0) — ✅ 코드 완료

```
[✅] 기본 STT 파이프라인 (FFmpeg 전처리 + Whisper API)
[✅] 삼성 녹음 폴더 자동 탐지 + 바로가기
[✅] 파일 선택기 (시스템 FilePicker)
[✅] 결과 뷰어 (타임스탬프 세그먼트 + 오디오 재생)
[✅] Share Intent 수신 (content:// → local file copy)
[✅] 히스토리 (SharedPreferences, 최근 100건)
[✅] Parksy Capture 연동 (auto-share 토글)
[✅] 마크다운 내보내기
```

### Phase 2 (v1.1.0) — 다음 목표

```
[ ] 배치 처리: 여러 파일 순차 STT
[ ] 검색: 히스토리 내 텍스트 검색
[ ] 날짜 필터: 기간별 히스토리 필터링
[ ] 삼성 녹음 파일명 파싱 (전화번호 + 날짜 추출)
[ ] 언어 선택: STT 언어 변경 (ko/en/ja/zh)
[ ] 히스토리 정렬: 날짜순/이름순/길이순
```

### Phase 3 (v2.0.0) — 장기

```
[ ] Speaker Diarization (pyannote 또는 서버사이드)
[ ] Whisper Large v3 로컬 추론 (whisper.cpp)
[ ] GPT 요약 (통화 내용 요약)
[ ] 연락처 연동 (전화번호 → 이름 매칭)
[ ] GitHub 아카이브 (Capture처럼 자동 push)
```

---

## 9. 알려진 제약사항

| 제약 | 상세 | 우회 방법 |
|------|------|-----------|
| Whisper 25MB 제한 | API 파일 크기 한도 | FFmpeg → ~0.5MB/분 → 50분 통화까지 OK |
| content:// URI | FFmpeg가 직접 못 읽음 | MainActivity에서 cache로 복사 |
| SharedPreferences 한도 | 큰 JSON 저장 시 느림 | 100건 제한, Phase 2에서 SQLite 고려 |
| Samsung 경로 하드코딩 | 기기별 다를 수 있음 | 4개 경로 시도 + fallback FilePicker |
| API 키 평문 저장 | SharedPreferences에 그냥 저장 | 개인용 OK, 필요 시 flutter_secure_storage |

---

## 10. 로컬 경로 맵

| 대상 | 경로 |
|------|------|
| 레포 (canonical) | `D:\1_GITHUB\dtslib-apk-lab` |
| C 드라이브 클론 | `C:\Users\dtsli\dtslib-apk-lab` (통합 권고) |
| Vercel 스토어 | https://dtslib-apk-lab.vercel.app/ |

---

## 11. 대기 작업

- [ ] ChronoCall: `flutter create . --org com.parksy` + `flutter pub get` + `flutter build apk --debug`
- [ ] ChronoCall: APK 서명 + release 빌드
- [ ] ChronoCall: 디바이스 테스트 (체크리스트 9항목)
- [ ] Wavesy: libc++_shared.so 해결 후 rebuild
- [ ] Store listing (dashboard/apps.json) 업데이트
- [ ] Flutter PATH 설정 (현재 PC에 없음)

---

## 12. 이어받기 가이드 (Continuation Instructions)

### ChronoCall 빌드 시

```bash
# 1. Flutter 설치/PATH 확인
flutter --version

# 2. 브랜치 체크아웃 (코드가 main이 아닐 수 있음)
cd D:\1_GITHUB\dtslib-apk-lab
git fetch origin claude/voice-content-pipeline-epaN1
git checkout claude/voice-content-pipeline-epaN1

# 3. 빌드
cd apps/chrono-call
flutter create . --org com.parksy    # 보일러플레이트 (최초 1회, 기존 파일 안 덮어씀)
flutter pub get
flutter build apk --debug

# 4. 테스트
ls -lh build/app/outputs/flutter-apk/app-debug.apk
```

### APK 디바이스 테스트 체크리스트

```
□ 앱 실행 → 권한 요청 화면
□ 권한 허용 → 메인 화면 (Samsung 바 표시 여부)
□ Settings → API 키 입력 → Save
□ 파일 선택 → STT 파이프라인 동작
□ 결과 화면 → 오디오 재생 + seek
□ 세그먼트 탭 → 해당 위치로 이동
□ Copy / Share / Export 동작
□ 다른 앱에서 음성 파일 공유 → ChronoCall에서 수신
□ Parksy Capture auto-share 토글
```

### Store 업데이트 시

```bash
# pubspec.yaml 기준으로 스토어 메타데이터 동기화
# /sync-store 명령 사용 가능
```

### Wavesy rebuild 시

- libc++_shared.so 충돌은 이미 해결됨 (`c8b7e3d`)
- `flutter clean && flutter pub get && flutter build apk --debug`

---

*최종 갱신: 2026-02-28 | 작성: dtslib-localpc Control Tower*
