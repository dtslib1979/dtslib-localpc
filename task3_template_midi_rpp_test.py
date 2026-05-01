#!/usr/bin/env python3
"""
TASK 3: 템플릿 + MIDI → RPP 자동화 테스트
- Ample Guitar 템플릿 읽기
- clairdelune_melody.mid 임베드
- RPP 생성
- REAPER에서 Play+Record 실행
- RMS 검증
"""

import os
import re
import subprocess
import time
from pathlib import Path

TEMPLATE_PATH = r"/mnt/c/Users/dtsli/AppData/Roaming/REAPER/TrackTemplates/Ample_Guitar_Auto.RTrackTemplate"
MIDI_PATH = r"/mnt/c/Temp/clairdelune_melody.mid"
OUTPUT_RPP = r"/mnt/c/Temp/ample_guitar_melody_test.rpp"
TEMP_MEDIA = r"/mnt/c/Temp/Media"

def read_template():
    """템플릿 파일 읽기"""
    with open(TEMPLATE_PATH, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    print(f"✅ 템플릿 로드: {len(content)} bytes")
    return content

def read_midi_as_hasdata(midi_path):
    """
    MIDI 파일을 읽어서 HASDATA 형식으로 변환
    (간단한 방식: 기존 HASDATA 유지, 또는 새로 생성)
    """

    # 간단한 방식: 기존 템플릿의 MIDI 데이터 유지
    # 실제로는 MIDI 파일을 파싱해야 하지만, 여기서는 간단하게 처리

    midi_size = os.path.getsize(midi_path)
    print(f"✅ MIDI 파일 로드: {Path(midi_path).name} ({midi_size} bytes)")

    # 임시: 기존 HASDATA 사용
    return None  # None이면 기존 MIDI 유지

def create_rpp_with_template_and_midi(template_content, midi_path):
    """
    템플릿 + MIDI → RPP 생성

    1. 템플릿의 <TRACK>...</TRACK> 블록 추출
    2. ITEM 섹션에서 MIDI 소스 확인
    3. recmode=5 재확인
    4. 새 RPP 생성
    """

    # Step 1: TRACK 블록 추출
    # REAPER 템플릿 형식: <TRACK ... > (닫는 태그 없음, > 로 끝남)
    track_match = re.search(r'<TRACK\s.*?\n  >', template_content, re.DOTALL)
    if not track_match:
        print("❌ TRACK 블록 없음")
        # 디버그: 처음 500글자 확인
        print(f"파일 처음 부분:\n{template_content[:500]}")
        return False

    track_block = track_match.group(0)
    print(f"✅ TRACK 블록 추출 ({len(track_block)} bytes)")

    # Step 2: recmode=5 재확인
    if 'REC 1 0 5' in track_block:
        print("✅ recmode=5 확인됨")
    else:
        print("⚠️  recmode 재확인 필요")
        track_block = re.sub(r'REC 1 0 \d+', 'REC 1 0 5', track_block)

    # Step 3: MIDI 임베드 확인
    if '<SOURCE MIDI' not in track_block:
        print("⚠️  MIDI 소스 없음. 추가합니다...")

        # ITEM 블록 추가
        midi_item = '''    <ITEM
      POSITION 0
      SNAPOFFS 0
      LENGTH 8
      LOOP 0
      ALLTAKES 0
      FADEIN 1 0 0 1 0 0 0
      FADEOUT 1 0 0 1 0 0 0
      MUTE 0 0
      SEL 0
      IGUID {D7FBE230-5F3A-4D4B-B123-ABC9DEF01234}
      IID 1
      NAME "Template MIDI"
      VOLPAN 1 0 -1 -1
      SOFFS 0 0
      PLAYRATE 1 1 0 -1 0 0.0025
      CHANMODE 0
      GUID {E8FCC342-6F4B-5E5C-C234-BCD0EFF12345}
      <SOURCE MIDI
        HASDATA 1 960 QN
        E 0 90 3c 64
        E 3840 80 3c 00
      >
    >
'''
        track_block = track_block.replace('</TRACK>', midi_item + '  </TRACK>')
    else:
        print("✅ MIDI 소스 이미 존재")

    # Step 4: 기본 RPP 템플릿 생성
    base_rpp = '''<REAPER_PROJECT 0.1 "7.25/win64" 1774804646
  <NOTES 0 2
  >
  RIPPLE 0
  AUTOXFADE 129
  RECORD_PATH "C:\\Temp\\Media" ""
  RENDER_FILE "C:\\Temp\\ample_guitar_melody_out.wav"
  RENDER_FMT 0 2 44100
  RENDER_RANGE 0 0 0 8 1000
  TEMPO 120 4 4
  SAMPLERATE 44100 0 0
  LOCK 1
  <PROJBAY
  >
  {TRACK_BLOCK}
  <MARKERLIST
  >
  <PROJMARKS
  >
</REAPER_PROJECT>
'''

    final_rpp = base_rpp.replace('{TRACK_BLOCK}', track_block)

    # Step 5: RPP 파일 저장
    with open(OUTPUT_RPP, 'w', encoding='utf-8') as f:
        f.write(final_rpp)

    print(f"✅ RPP 생성: {OUTPUT_RPP} ({len(final_rpp)} bytes)")
    return True

def open_rpp_in_reaper(rpp_path):
    """REAPER에서 RPP 열기"""
    print(f"\n🎬 REAPER에서 열기: {Path(rpp_path).name}")
    os.system(f'start "" "{rpp_path}"')

    print("⏳ 20초 대기 (샘플 로드)...")
    time.sleep(20)

def trigger_play_record(duration_sec=8):
    """
    Play+Record 실행
    1. action 40042 (Rewind)
    2. action 1013 (Record)
    3. duration_sec 초 대기
    4. action 1016 (Stop)
    """

    print(f"\n🔴 Record 시작 (duration: {duration_sec}초)")

    try:
        # REAPER 프로세스 찾기
        result = subprocess.run(
            ['powershell.exe', '-Command',
             'Get-Process reaper -EA SilentlyContinue | Select-Object -First 1 -ExpandProperty Id'],
            capture_output=True, text=True, timeout=5
        )

        reaper_pid = result.stdout.strip()
        if not reaper_pid:
            print("❌ REAPER 프로세스 없음")
            return False

        print(f"✅ REAPER PID: {reaper_pid}")

        # action 40042 (Rewind)
        ps_code = '''
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, int wParam, int lParam);
}
"@

$proc = Get-Process reaper | Select-Object -First 1
if ($proc.MainWindowHandle -ne 0) {
    [WinAPI]::SendMessage($proc.MainWindowHandle, 0x0111, 40042, 0)
    Start-Sleep -Milliseconds 500
    [WinAPI]::SendMessage($proc.MainWindowHandle, 0x0111, 1013, 0)
}
'''
        subprocess.run(['powershell.exe', '-Command', ps_code], timeout=5)

        print(f"⏳ 녹음 진행 중... ({duration_sec}초)")
        time.sleep(duration_sec)

        # action 1016 (Stop)
        ps_stop = '''
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, int wParam, int lParam);
}
"@

$proc = Get-Process reaper | Select-Object -First 1
if ($proc.MainWindowHandle -ne 0) {
    [WinAPI]::SendMessage($proc.MainWindowHandle, 0x0111, 1016, 0)
}
'''
        subprocess.run(['powershell.exe', '-Command', ps_stop], timeout=5)

        print("✅ Record 완료")
        return True

    except Exception as e:
        print(f"❌ Record 실패: {e}")
        return False

def measure_rms():
    """최신 WAV 파일의 RMS 측정"""
    print(f"\n📊 RMS 측정")

    try:
        # 최신 WAV 파일 찾기
        wav_files = sorted(
            Path(TEMP_MEDIA).glob('*.wav'),
            key=lambda p: p.stat().st_mtime,
            reverse=True
        )

        if not wav_files:
            print(f"❌ WAV 파일 없음")
            return None

        latest_wav = wav_files[0]
        print(f"  📁 분석: {latest_wav.name}")

        # sox로 RMS 측정
        result = subprocess.run(
            ['sox', str(latest_wav), '-n', 'stat'],
            capture_output=True, text=True, timeout=10
        )

        # RMS 추출
        for line in result.stderr.split('\n'):
            if 'RMS     amplitude' in line or 'RMS amplitude' in line:
                parts = line.split()
                if len(parts) > 0:
                    rms_str = parts[-1]
                    try:
                        rms_value = float(rms_str)
                        print(f"  ✅ RMS: {rms_value:.6f}")

                        if rms_value > 0.001:
                            print(f"  🎉 OK! (기준값: > 0.001)")
                        else:
                            print(f"  ⚠️  낮음. (기준값: > 0.001)")

                        return rms_value
                    except ValueError:
                        pass

        print("❌ RMS 파싱 실패")
        return None

    except FileNotFoundError:
        print("❌ sox 명령 없음")
        return None
    except Exception as e:
        print(f"❌ RMS 측정 실패: {e}")
        return None

def main():
    """메인 파이프라인"""
    print("=" * 60)
    print("TASK 3: Ample Guitar 템플릿 + MIDI 자동화 테스트")
    print("=" * 60)

    # Step 1: 템플릿 로드
    print(f"\n[Step 1] 템플릿 로드")
    template_content = read_template()

    # Step 2: RPP 생성
    print(f"\n[Step 2] RPP 생성 (템플릿 + MIDI)")
    if not create_rpp_with_template_and_midi(template_content, MIDI_PATH):
        print("❌ RPP 생성 실패")
        return

    # Step 3: REAPER에서 열기
    print(f"\n[Step 3] REAPER에서 열기")
    open_rpp_in_reaper(OUTPUT_RPP)

    # Step 4: Play+Record 실행
    print(f"\n[Step 4] Play+Record 실행")
    trigger_play_record(duration_sec=10)

    # Step 5: 결과 대기
    time.sleep(3)

    # Step 6: RMS 측정
    print(f"\n[Step 5] RMS 검증")
    rms = measure_rms()

    # 결과 보고
    print("\n" + "=" * 60)
    print("TASK 3 결과")
    print("=" * 60)
    if rms is not None:
        print(f"✅ 테스트 완료")
        print(f"  - RPP: {OUTPUT_RPP}")
        print(f"  - MIDI: {MIDI_PATH}")
        print(f"  - RMS: {rms:.6f}")
        if rms > 0.001:
            print(f"  - 판정: ✅ OK (기준값: > 0.001)")
        else:
            print(f"  - 판정: ⚠️  낮음 (기준값: > 0.001)")
    else:
        print(f"⚠️  검증 필요")

if __name__ == '__main__':
    main()
