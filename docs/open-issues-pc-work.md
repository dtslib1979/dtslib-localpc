# PC 수작업 오픈 이슈 목록

> **작성**: 2026-03-09
> **용도**: 수요일 PC 작업 세션 리마인더
> **원칙**: 이 목록의 항목은 전부 핸드폰 불가 — PC 앞에서만 처리 가능

---

## 🔴 블로커 (이게 막혀야 다음이 진행됨)

### 1. WSL Claude Code 인증
**레포**: parksy-audio
**왜 막혀있나**: OAuth redirect_uri가 platform.claude.com으로 가버려서 WSL에서 자동 토큰 교환 구조적 불가. 15회 시도 전량 실패.
**왜 PC 필요**: Windows PowerShell + 브라우저 팝업 떠야 함
**실행 순서**:
```powershell
# 1. Windows PowerShell에서
$env:CLAUDECODE=""; claude setup-token

# 2. 브라우저 팝업 → 로그인 → 토큰 복사

# 3. WSL 터미널에서
echo 'export CLAUDE_CODE_OAUTH_TOKEN="복사한토큰"' >> ~/.bashrc
source ~/.bashrc

# 4. 확인
claude --version
```
**참조**: `docs/devlog-wsl-server-2026-03.md`

---

### 2. YouTube OAuth 토큰 생성 (parksy-audio 업로드용)
**레포**: parksy-audio
**왜 막혀있나**: YouTube API 업로드에 `token.json` 필요. 이게 없으면 6개 영상 업로드 불가.
**왜 PC 필요**: 브라우저 Google 로그인 팝업 필수 (Account A: dimas.thomas.sancho@gmail.com)
**실행 순서**:
```
# D:\PARKSY\parksy-audio\tools\youtube\ 에서
node auth.js
# 브라우저 팝업 → Google 로그인 (Account A) → 허용
# token.json 자동 생성 확인
```
**완료 후**: YouTube 업로드 6개 Claude가 대신 실행 가능해짐

---

## 🟠 쌓인 것 처리

### 3. parksy-image 미커밋 파일 30개 정리
**레포**: parksy-image (`D:\parksy-image`)
**상태**: dirty_files 30개 — 뭔지 확인 후 커밋 or 삭제 결정 필요
**실행 순서**:
```
cd D:\parksy-image
git status
git diff --stat
# 확인 후 Claude에게 "이거 커밋해줘" 하면 됨
```

---

## 🟡 환경 세팅

### 4. Flutter PATH 등록 (ChronoCall 빌드 필수)
**레포**: dtslib-apk-lab
**왜 막혀있나**: Flutter가 PATH에 없어서 `flutter build apk` 자체가 안 됨
**실행 순서**:
```powershell
# Flutter SDK 경로 확인 (보통 C:\flutter 또는 D:\flutter)
where flutter
# 없으면 환경변수 PATH에 추가
# 시스템 속성 → 환경 변수 → PATH → Flutter\bin 경로 추가
# PowerShell 재시작 후
flutter --version
```
**완료 후**: ChronoCall APK 빌드 + Wavesy 리빌드 Claude가 대신 실행 가능

### 5. Wavesy libc++_shared.so 충돌 리빌드
**레포**: dtslib-apk-lab
**왜 막혀있나**: so 충돌 해결됨 → 리빌드만 하면 됨, Flutter PATH 있으면 Claude가 실행 가능
**선행조건**: 4번 Flutter PATH 완료 후

---

## ✏️ 사용자 직접 작업 (Claude도 못 함)

### 6. 손글씨 SVG 제공 (PSE Phase 2 언블록)
**레포**: parksy-image
**왜 막혀있나**: 사용자 태블릿 손글씨 샘플 SVG 86글리프 — 본인이 직접 써야 함
**방법**: 태블릿으로 손글씨 → SVG로 변환 → `tools/pse/input/` 폴더에 넣기
**참조**: `repos/parksy-image.md`

---

## 📦 기타 (언젠가)

### 7. fire_nat.mp3 다운로드 완료
**레포**: parksy-audio
**상태**: Internet Archive에서 다운로드 미완료
**방법**: PC에서 직접 다운로드 → `D:\VST\ambient\fire_nat.mp3`
**참조**: `repos/parksy-audio.md` 섹션 6.4

---

## 체크리스트 (수요일 작업 순서 추천)

```
[ ] 1. WSL Claude Code 인증 (PowerShell + 브라우저) — 30분
[ ] 2. YouTube OAuth 토큰 생성 (node auth.js) — 10분
[ ] 3. parksy-image git status 확인 + 정리 — 15분
[ ] 4. Flutter PATH 등록 — 10분
[ ] 5. ChronoCall 빌드 + Wavesy 리빌드 (Claude에게 위임) — 대기
[ ] 6. 손글씨 SVG 작업 (태블릿) — 별도 시간
[ ] 7. fire_nat.mp3 다운로드 — 5분
```

> **1, 2번 완료하면** YouTube 업로드 6개는 Claude가 자동으로 돌림
> **4번 완료하면** ChronoCall/Wavesy 빌드는 Claude가 자동으로 돌림
> **나머지는** 사람 손이 필요한 본질적 작업

---

*최종 갱신: 2026-03-09*
