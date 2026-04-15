-- TASK 1: TrackFX_Show 자동초기화 검증 (2026-03-31)
-- 목표: Lua로 FX 창을 열었을 때 샘플 엔진 초기화 여부 테스트
-- 결과: RMS > 0.001 이면 성공 (FX 창 자동화 가능), 아니면 수작업 필수

function log(msg)
  reaper.ShowConsoleMsg(msg .. "\n")
end

log("===== TASK 1: TrackFX_Show 초기화 검증 시작 =====\n")

-- Step 1: 새 트랙 생성
log("[1/7] 새 트랙 생성...")
reaper.InsertTrackAtIndex(0, false)
local track = reaper.GetTrack(0, 0)
if not track then
  log("❌ 트랙 생성 실패")
  return
end
log("✅ 트랙 0 생성됨")

-- Step 2: Ample Guitar M II Lite 플러그인 추가
log("\n[2/7] Ample Guitar M II Lite 추가...")
local ret = reaper.TrackFX_AddByName(track, "VSTi: Ample Guitar M II Lite (Ample Sound)", false, -1)
if ret < 0 then
  log("❌ 플러그인 추가 실패. 설치 확인: D:\\VST\\AGML2.dll")
  return
end
log("✅ FX슬롯: " .. tostring(ret))

-- Step 3: FX 창 열기 (ShowType=3 = dockable)
log("\n[3/7] FX 창 자동 열기 (TrackFX_Show)...")
reaper.TrackFX_Show(track, ret, 3)
log("✅ FX 창 열림 (10초 대기 중...)")

-- Step 4: 초기화 대기
log("\n[4/7] 샘플 엔진 초기화 대기...")
local wait_cycles = 0
repeat
  reaper.Sleep(100)
  wait_cycles = wait_cycles + 1
  if wait_cycles % 10 == 0 then
    log("  → " .. tostring(wait_cycles * 100) .. "ms...")
  end
until wait_cycles >= 100  -- 10초

log("✅ 초기화 완료 (10초)")

-- Step 5: MIDI 아이템 생성 (인라인 HASDATA 방식)
log("\n[5/7] MIDI 아이템 생성 (C4 1초 노트)...")
local item = reaper.AddMediaItemToTrack(track)
if not item then
  log("❌ 아이템 생성 실패")
  return
end

reaper.SetMediaItemInfo_Value(item, "D_LENGTH", 1.0)  -- 1초
local take = reaper.AddTakesToMediaItem(item, 1)[1]
if not take then
  take = reaper.GetActiveTake(item)
end

-- MIDI 데이터 직접 입력 (C4 1초 노트)
-- Note On: 144 (0x90), pitch 60 (C4), velocity 100 (0x64)
-- Note Off: 128 (0x80), pitch 60, velocity 0
reaper.MIDI_InsertNote(take, false, false, 0, 60, 100, 960, 0)     -- Note On at 0
reaper.MIDI_InsertNote(take, false, false, 0, 60, 0, 960, 0)       -- Note Off at 960 ticks

log("✅ MIDI 아이템: C4 1초 노트 삽입")

-- Step 6: 렌더 설정 (recmode=5 필수!)
log("\n[6/7] 렌더 설정...")
-- recmode를 5로 설정 (Record: output stereo)
reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", 5)
reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)  -- armed

log("✅ recmode=5, record armed")

-- Step 7: Play+Record 실행 (action 1013)
log("\n[7/7] Play+Record 실행 (action 1013)...")
log("  → Rewind (action 40042)")
reaper.Main_OnCommand(40042, 0)  -- Rewind

reaper.Sleep(500)

log("  → Record (action 1013) 시작...")
reaper.Main_OnCommand(1013, 0)   -- Play+Record

-- 재생 대기 (1초 + 안전마진 2초)
reaper.Sleep(3000)

log("  → Stop (action 1016)")
reaper.Main_OnCommand(1016, 0)   -- Stop

reaper.Sleep(1000)

-- Step 8: 결과 파일 확인
log("\n===== 결과 검증 =====")
local mediapath = reaper.GetProjectPath("", "")
local rendpath = mediapath .. "\\Media\\"

log("렌더 경로: " .. rendpath)
log("\n[⚠️ PC에서 수동 확인 필요]")
log("1. 위 경로에서 *.wav 파일 생성 확인")
log("2. sox RMS 검증:")
log("   sox \"파일.wav\" -n stat 2>&1 | grep RMS")
log("3. RMS > 0.001 이면 ✅ FX 자동화 가능")
log("   RMS ≈ 0 이면 ❌ 수작업 필수")
log("\n===== TASK 1 종료 =====")
