# PC 복원 매뉴얼

> 새 PC에서 이것만 따라하면 개발환경 복원 완료.
> 최종 업데이트: 2026-02-28

## Phase 0: 기본 셋업 (10분)

### 0-1. Git 설치
```powershell
winget install Git.Git
```

### 0-2. 이 레포 클론
```powershell
git clone https://github.com/dtslib1979/dtslib-localpc.git D:\PARKSY\dtslib-localpc
```

### 0-3. Git 설정
```bash
git config --global user.name "dtslib1979"
git config --global user.email "dtslib1979@users.noreply.github.com"
git config --global core.autocrlf true
git config --global init.defaultBranch main
```

## Phase 1: 핵심 개발도구 (20분)

### 1-1. winget으로 일괄 설치
```powershell
# 필수
winget install OpenJS.NodeJS.22
winget install Python.Python.3.12
winget install Microsoft.VisualStudioCode
winget install GitHub.cli
winget install Microsoft.PowerShell

# 개발
winget install GoLang.Go
winget install Microsoft.OpenJDK.17
winget install Gyan.FFmpeg
winget install Rclone.Rclone

# 유틸
winget install Google.Chrome.EXE
winget install Obsidian.Obsidian
winget install RustDesk.RustDesk
winget install Cockos.REAPER
```

### 1-2. GitHub CLI 로그인
```bash
gh auth login
```

### 1-3. Claude Code 설치
```bash
npm install -g @anthropic-ai/claude-code
```

## Phase 2: 레포 클론 (15분)

### 2-1. 프로덕션 레포 (핵심 3개)
```bash
git clone https://github.com/dtslib1979/parksy-audio.git D:\PARKSY\parksy-audio
git clone https://github.com/dtslib1979/parksy-image.git D:\parksy-image
git clone https://github.com/dtslib1979/dtslib-apk-lab.git D:\1_GITHUB\dtslib-apk-lab
```

### 2-2. 전체 레포 (sync.bat 사용)
```powershell
# D:\_SYSTEM\sync.bat 실행 — 20개 레포 자동 클론
D:\_SYSTEM\sync.bat
```

### 2-3. 디렉토리 구조 생성
```powershell
mkdir D:\2_WORKSPACE
mkdir D:\3_APK
mkdir D:\4_ARCHIVE
mkdir D:\5_YOUTUBE
mkdir D:\_SYSTEM\logs
mkdir D:\_TOOLS
mkdir D:\tmp
```

## Phase 3: parksy-audio 환경 (30분)

### 3-1. VST/SoundFont 복원
WD Passport 또는 백업에서 복사:
```
D:\VST\SGM-V2.01.sf2           ← 핵심 SoundFont
D:\VST\fluidsynth\             ← FluidSynth 바이너리
D:\VST\SSO\                    ← Sonatina Symphonic Orchestra
D:\VST\VSCO2\                  ← VSCO-2-CE-SFZ
D:\VST\ambient\                ← rain/wind/fire WAV
```

### 3-2. Python 의존성
```bash
cd D:\PARKSY\parksy-audio
pip install -r requirements.txt  # 있으면
# 또는 수동:
pip install numpy scipy pydub mutagen pyloudnorm
```

### 3-3. 작업 디렉토리 복원
WD Passport에서 `D:\tmp\` 전체 복사 (optimizer.py, score_engine.py, configs 등)

## Phase 4: parksy-image 환경 (10분)

### 4-1. Python 의존성
```bash
cd D:\parksy-image
pip install mediapipe opencv-python pillow svgwrite
```

### 4-2. PSE 폰트 빌드 확인
```bash
python -m tools.pse.build --validate
```

### 4-3. Telegram Bridge 설정
```json
// D:\parksy-image\tools\telegram-bridge\config.json
{
  "bot_token": "[REDACTED - 재발급 필요]",
  "chat_id": "6858098283"
}
```

## Phase 5: dtslib-apk-lab 환경 (30분)

### 5-1. Flutter 설치
```powershell
# Flutter SDK 다운로드: https://flutter.dev/docs/get-started/install/windows
# 또는 chocolatey:
choco install flutter
```

### 5-2. Android SDK 확인
```bash
flutter doctor
```

### 5-3. 앱 빌드 테스트
```bash
cd D:\1_GITHUB\dtslib-apk-lab\apps\chrono-call
flutter create . --org com.parksy
flutter pub get
flutter build apk --debug
```

## Phase 6: 자동화 설정 (5분)

### 6-1. 스냅샷 테스트
```powershell
powershell -ExecutionPolicy Bypass -File D:\PARKSY\dtslib-localpc\scripts\snapshot.ps1
```

### 6-2. 스케줄러 등록 (선택)
```powershell
# 매일 자동 스냅샷
powershell -ExecutionPolicy Bypass -File D:\_SYSTEM\scripts\register-scheduler.ps1
```

## 검증 체크리스트

- [ ] `git --version` → 2.50+
- [ ] `node --version` → v22+
- [ ] `python --version` → 3.12+
- [ ] `gh auth status` → 로그인 확인
- [ ] `D:\PARKSY\parksy-audio` 존재
- [ ] `D:\parksy-image` 존재
- [ ] `D:\1_GITHUB\dtslib-apk-lab` 존재
- [ ] `D:\VST\SGM-V2.01.sf2` 존재
- [ ] `D:\VST\fluidsynth\bin\fluidsynth.exe` 존재
- [ ] `python -m tools.pse.build --validate` 통과
- [ ] `snapshot.ps1` 정상 실행

## 복원 불가 항목 (수동 필요)

| 항목 | 방법 |
|------|------|
| SSH 키 | `ssh-keygen` 후 GitHub에 등록 |
| Telegram Bot Token | @BotFather에서 재발급 |
| Whisper API Key | OpenAI 대시보드에서 재발급 |
| VST/SoundFont 파일 | WD Passport 백업에서 복사 |
| D:\tmp\ 작업 파일 | WD Passport 백업에서 복사 |
| REAPER 설정 | 재설정 필요 |
