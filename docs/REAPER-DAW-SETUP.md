# Reaper DAW + MIDI 키보드 원격 세팅 삽질 기록

## 날짜: 2026-03-23

## 목표
- Reaper DAW에서 Impact LX61+ 마스터 키보드로 소리 나게 하기
- 원격(핸드폰 Termux SSH)에서 PC Reaper 제어

## 장비 현황

| 장비 | 상태 |
|------|------|
| Reaper v7.25 | 설치됨 (C:\Program Files\REAPER (x64)) |
| Nektar Impact LX61+ | USB 인식 OK, MIDI 디바이스 등록됨 |
| Focusrite Scarlett 2i2 | USB 인식 OK, 오디오 인터페이스 |
| Focusrite USB ASIO 드라이버 | 설치됨 (레지스트리 확인) |

## 삽질 기록

### 1. Reaper 라이선스 팝업 (Still Evaluating)
- 42일째 평가판 사용 중
- 실행 시마다 "About REAPER" 팝업 → "Still Evaluating" 카운트다운 5초 후 버튼 나타남
- **문제**: 원격에서 버튼 클릭이 안 됨
  - DPI 150% 스케일링 → 스크린샷 좌표(1280x720)와 실제 클릭 좌표(1920x1080) 불일치
  - 좌표 ×1.5 보정해도 X 버튼(닫기)을 맞춰서 Reaper가 꺼짐 (3회)
  - reaper.fm 다운로드 페이지로 빠짐 (1회)
- **해결**: UI Automation으로 "Still Evaluating" 버튼을 이름으로 찾아서 좌표 획득 후 클릭
  ```powershell
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $cond = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::NameProperty, 'Still Evaluating')
  $btn = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
  $rect = $btn.Current.BoundingRectangle
  # → 정확한 좌표 획득 → 클릭 성공
  ```
- **교훈**: reaper.ini의 `verchk=0`, `lastabouttime=9999999999` 설정으로도 팝업 안 꺼짐. Reaper 평가판은 팝업 비활성화 불가.

### 2. 오디오 드라이버 지옥

| 시도 | 모드 | 결과 |
|------|------|------|
| 1차 | ASIO (asio_driver=1, Focusrite USB ASIO) | "Error initializing ASIO driver" |
| 2차 | ASIO + Focusrite 프로세스 kill | 같은 에러 |
| 3차 | WASAPI (mode=24) | "Error opening audio hardware" |
| 4차 | WaveOut (mode=2) | **성공** — 44.1kHz 24bit WAV 정상 |
| 5차 | Focusrite 드라이버 Unknown 디바이스 비활성화 시도 | **관리자 권한 없어서 실패 + SSH 끊김 + 오디오 전체 먹통** |
| 6차 | 재부팅 | Focusrite 복구, WaveOut 정상 |

- **ASIO 안 되는 원인 추정**: Focusrite USB Audio 디바이스가 2개 등록됨 (OK 1개 + Unknown 1개) → 드라이버 충돌
- **WASAPI 안 되는 원인 추정**: Focusrite가 독점 모드 상태
- **WaveOut은 됨**: 공유 모드라 충돌 없음. 레이턴시 187ms (DAW용으로는 높지만 작동은 함)
- **Focusrite 드라이버 비활성화 시도 → 시스템 먹통**: 관리자 권한 없이 PnpDevice 조작 → 오디오 전체 사망 → 재부팅으로 복구

### 3. GUI 원격 제어 삽질

| 방법 | 결과 |
|------|------|
| PowerShell SendKeys | 메뉴는 열리지만 Reaper 내부 포커스 불안정 |
| mouse_event 좌표 클릭 | DPI 150%로 좌표 불일치 → 엉뚱한 곳 클릭 |
| UI Automation FindWindow + MoveWindow | 팝업 창 리사이즈 성공 |
| UI Automation 버튼 이름 검색 | Still Evaluating 찾기 성공, Record Arm 못 찾음 (Reaper 자체 렌더링) |
| desktop-commander MCP | `--print` 모드에서 MCP 로드 안 됨. interactive 세션 필요 |
| Claude in Chrome | 브라우저만 제어 가능, 네이티브 앱 불가 |
| Playwright MCP | 브라우저만 제어 가능, 네이티브 앱 불가 |

### 4. 올바른 접근 (결론)
Reaper는 **ReaScript** (Lua/Python)로 내부 API 제어 가능:
```lua
-- Track 추가 + MIDI Input + Record Arm + Monitor + ReaSynth
local track = reaper.GetTrack(0, 0)
reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 4096)  -- MIDI All
reaper.SetMediaTrackInfo_Value(track, "I_RECMON", 1)       -- Monitor ON
reaper.TrackFX_AddByName(track, "ReaSynth", false, -1)     -- VSTi 추가
```

GUI 클릭 삽질할 필요 없이 **터미널에서 스크립트 실행**하면 됨.
아직 실행 안 함 — 다음 세션에서 완료 예정.

## 현재 상태 (세션 종료 시점)

| 항목 | 상태 |
|------|------|
| Reaper | 실행 중, WaveOut 모드, 오디오 정상 |
| 라이선스 팝업 | 해결됨 (UI Automation 클릭) |
| MIDI 키보드 | Windows 인식 OK, Reaper 트랙 미연결 |
| 마스터 키보드 소리 | **아직 안 남** |
| ReaScript midi_setup.lua | 생성됨, F12에 바인딩됨, 실행 안 함 |

## 다음 작업
1. Reaper에서 ReaScript 실행 (터미널)
2. Track 1 → MIDI Input Impact LX61+ → Record Arm → Monitor ON → ReaSynth
3. 키보드 누르면 소리 나는지 확인
4. ASIO 드라이버 재설치 검토 (WaveOut 레이턴시 187ms → ASIO면 ~10ms)

## 파일 위치
- Reaper 설정: `C:\Users\dtsli\AppData\Roaming\REAPER\REAPER.ini`
- MIDI 설정: `C:\Users\dtsli\AppData\Roaming\REAPER\reaper-midihw.ini`
- ReaScript: `C:\Users\dtsli\AppData\Roaming\REAPER\Scripts\midi_setup.lua`
- 키보드 바인딩: `C:\Users\dtsli\AppData\Roaming\REAPER\reaper-kb.ini` (F12 → midi_setup)
