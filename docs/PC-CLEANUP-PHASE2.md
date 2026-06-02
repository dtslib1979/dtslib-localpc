# PC 정리 Phase 2 — C드라이브 → D드라이브 개발환경 이전

> 작성: 2026-05-30  
> 목적: C드라이브 85% 위기 항구적 해결

---

## 현재 상황

| 드라이브 | 사용 | 전체 | 사용률 |
|---------|------|------|------|
| C: | 391GB | 461GB | **85% ⚠️** |
| D: | 220GB | 1.8TB | 12% ✅ |
| E: | 47GB | 477GB | 10% ✅ |
| W: | 51GB | 100GB | 51% |

---

## 범인 분석

| 항목 | 크기 | 위치 |
|------|------|------|
| WSL ext4.vhdx | **202GB** | C:\Users\dtsli\AppData\Local\wsl\ |
| Claude Desktop VM | 11GB | C:\Users\dtsli\AppData\Roaming\Claude\vm_bundles\ |
| Temp (User) | 8GB | C:\Users\dtsli\AppData\Local\Temp |
| .android (AVD) | 4.5GB | C:\Users\dtsli\.android |
| .gradle | 4.2GB | C:\Users\dtsli\.gradle |
| AppData\Local (총) | 229GB | ← WSL이 대부분 |
| REAPER CrashDumps | 1.2GB | C:\Users\dtsli\AppData\Local\CrashDumps |
| Opera 구버전 | 1.3GB | C:\Users\dtsli\AppData\Local\Programs\Opera |
| Puppeteer Chrome 구버전 | ~740MB | C:\Users\dtsli\.cache\puppeteer |
| .cargo | 1.1GB | C:\Users\dtsli\.cargo |

---

## 실행 플랜

### ⚠️ 중요: WSL 이전은 WSL 외부(Windows)에서 실행해야 함
`wsl --terminate Ubuntu` 실행 시 WSL 세션 자체가 종료됨 → **Windows Claude Code 또는 박씨 직접 PowerShell(관리자) 실행**

---

### Step 1 — WSL Ubuntu D드라이브 이전 (202GB 확보)

**WSL 버전: 2.6.3 확인됨** → `--manage --move` 명령 사용 가능

```powershell
# PowerShell (관리자) 에서 실행
wsl --terminate Ubuntu
wsl --manage Ubuntu --move D:\WSL
```

- 소요 시간: 30분~1시간 (202GB 복사)
- 완료 후 검증:
```powershell
wsl -d Ubuntu -e df -h
```
- wsl-min도 이전:
```powershell
wsl --terminate wsl-min
wsl --manage wsl-min --move D:\WSL
```

---

### Step 2 — 개발 캐시 환경변수 D드라이브 리디렉션 (+9GB)

```powershell
# PowerShell (관리자) 에서 실행

# 1. 폴더 생성
New-Item -ItemType Directory -Force -Path D:\dev-cache\gradle
New-Item -ItemType Directory -Force -Path D:\dev-cache\cargo
New-Item -ItemType Directory -Force -Path D:\dev-cache\android

# 2. 환경변수 설정
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "D:\dev-cache\gradle", "User")
[Environment]::SetEnvironmentVariable("CARGO_HOME", "D:\dev-cache\cargo", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "D:\dev-cache\android", "User")

# 3. 기존 캐시 복사
robocopy "$env:USERPROFILE\.gradle" "D:\dev-cache\gradle" /mir /r:1 /w:1
robocopy "$env:USERPROFILE\.cargo" "D:\dev-cache\cargo" /mir /r:1 /w:1
robocopy "$env:USERPROFILE\.android" "D:\dev-cache\android" /mir /r:1 /w:1

# 4. 복사 완료 확인 후 기존 폴더 삭제
Remove-Item "$env:USERPROFILE\.gradle" -Recurse -Force
Remove-Item "$env:USERPROFILE\.cargo" -Recurse -Force
Remove-Item "$env:USERPROFILE\.android" -Recurse -Force
```

---

### Step 3 — 즉시 삭제 가능 항목 (9GB)

```powershell
# REAPER CrashDumps (1.2GB) — 안전 삭제
Remove-Item "$env:LOCALAPPDATA\CrashDumps\reaper.exe.*.dmp" -Force

# Temp 정리 (8GB)
Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Puppeteer 구버전 Chrome (win64-131, win64-143 → win64-146만 남기기)
Remove-Item "$env:USERPROFILE\.cache\puppeteer\chrome\win64-131.0.6778.204" -Recurse -Force
Remove-Item "$env:USERPROFILE\.cache\puppeteer\chrome\win64-143.0.7499.42" -Recurse -Force

# Opera 구버전 (130, 131 → 최신만 남기기)
Remove-Item "$env:LOCALAPPDATA\Programs\Opera\130.0.5847.92" -Recurse -Force
Remove-Item "$env:LOCALAPPDATA\Programs\Opera\131.0.5877.55" -Recurse -Force

# Claude 구버전 (최신만 남기기)
Remove-Item "$env:LOCALAPPDATA\claude-updater\installer.exe" -Force -ErrorAction SilentlyContinue
```

---

### Step 4 — Desktop 파일 D드라이브 이동 (선택, +3GB)

```powershell
# VSCO2_CE_SFZ.zip (1.7GB) — D드라이브로 이동
Move-Item "C:\Users\dtsli\Desktop\01_PARKSY\VSCO2_CE_SFZ.zip" "D:\PARKSY\VSCO2_CE_SFZ.zip"

# SalamanderGrandPiano tar (297MB) — SF2 이미 있으니 삭제
Remove-Item "C:\Users\dtsli\Desktop\01_PARKSY\fluidsynth\SalamanderGrandPiano-SF2-V3.tar.xz" -Force
```

---

## 예상 결과

| 단계 | C드라이브 확보 | 누적 사용률 |
|------|------|------|
| Step 1 (WSL 이전) | 202GB | ~40% |
| Step 2 (캐시 이전) | +9GB | ~38% |
| Step 3 (즉시 삭제) | +9GB | ~36% |
| Step 4 (Desktop 이동) | +3GB | ~35% |
| **최종 합계** | **~223GB 확보** | **~35%** |

**C드라이브: 391GB → ~168GB (85% → 35%)**

---

## 주의사항

- Step 1은 반드시 **WSL 외부(Windows PowerShell 관리자)** 에서 실행
- WSL 이전 중 PC 절대 끄지 말 것 (202GB 복사 중)
- Step 2에서 robocopy 완료 확인 후 기존 폴더 삭제
- Claude Desktop VM(11GB)은 공식 이전 방법 없음 → 현재 보류

---

## Step 5 — WSL 내부 오디오 작업 temp 파일 삭제 (~20GB, 박씨 확인 후 실행)

> **2026-06-02 분석 결과**: `local-agent/outputs/work/` 에 중간 계산 WAV 32GB 적체.
> 완성본은 `outputs/youtube/` 에 MP4로 이미 보존됨. work/ 는 재생성 가능한 temp.

```bash
# WSL 내부에서 실행 (박씨 확인 후)

# 1. loop_60s — 루프 최적화 중간 WAV (15GB, 108개 파일)
rm -rf ~/parksy-audio/local-agent/outputs/work/loop_60s/

# 2. loop_opt — 루프 최적화 최종 후보군 (2.5GB)
rm -rf ~/parksy-audio/local-agent/outputs/work/loop_opt/

# 3. 비교 렌더 3종 — SGM/FluidR3/GeneralUser (870MB, Salamander 확정 후 불필요)
rm -rf ~/parksy-audio/local-agent/outputs/work/r2_nocturne_13_SGM/
rm -rf ~/parksy-audio/local-agent/outputs/work/r2_nocturne_13_FluidR3/
rm -rf ~/parksy-audio/local-agent/outputs/work/r2_nocturne_13_GeneralUser/

# 4. bruckner 중간 렌더 (2.3GB)
rm -rf ~/parksy-audio/local-agent/outputs/work/bruckner_180/
rm -rf ~/parksy-audio/local-agent/outputs/work/bruckner_direct/

# 5. xtts-venv — XTTS 더 이상 사용 안 함 (1.7GB)
rm -rf ~/parksy-audio/xtts-venv/
```

**예상 확보량: ~22GB** (WSL vhdx가 그만큼 줄어듦 → C: 에서 회수)

---

## 2026-06-02 실행 완료 항목 (Claude Code 자동)

| 항목 | 확보량 | 방법 |
|------|--------|------|
| pip cache | 214MB | `pip cache purge` |
| apt cache | 1.1GB | `apt-get clean` |
| npm cache | ~100MB | `npm cache clean --force` |
| bot.log 초기화 | 64MB | `truncate -s 0` |
| **소계** | **~1.5GB** | |

---

## WSL 이전 완료 후 검증 체크리스트

```bash
# WSL 내부에서 확인
df -h          # /dev/sdc가 D드라이브 경로 가리키는지 확인
which python3  # 기존 명령 정상 작동 확인
ls ~/          # 홈 디렉토리 파일 정상 확인
```

```powershell
# Windows에서 확인
Get-Volume -DriveLetter C  # 사용량 감소 확인
Get-Volume -DriveLetter D  # D드라이브 증가 확인
wsl --list -v              # Ubuntu Running 확인
```
