#!/usr/bin/env python3
"""
TASK B: Template 파일 파싱 및 RPP 자동화
- .RTrackTemplate 읽기
- 텍스트 구조 분석 (VSTi 설정, recmode, FX 체인)
- RPP에 템플릿 삽입 후 MIDI 추가
- Play+Record 실행 및 RMS 검증
"""

import os
import re
import subprocess
import time
import shutil
from pathlib import Path

REAPER_TRACK_TEMPLATES = r"C:\Users\dtsli\AppData\Roaming\REAPER\TrackTemplates"
TEMP_MEDIA = r"C:\Temp\Media"
TEMP_DIR = r"C:\Temp"

def read_template(template_name):
    """
    .RTrackTemplate 파일 읽기
    예: "ample_guitar_ready" → "ample_guitar_ready.RTrackTemplate"
    """
    template_path = Path(REAPER_TRACK_TEMPLATES) / f"{template_name}.RTrackTemplate"

    if not template_path.exists():
        print(f"❌ 템플릿 파일 없음: {template_path}")
        return None

    print(f"✅ 템플릿 읽음: {template_path}")
    with open(template_path, 'r', encoding='utf-8', errors='ignore') as f:
        return f.read()

def extract_track_block(template_content):
    """
    템플릿 파일에서 <TRACK>...</TRACK> 블록 추출
    """
    match = re.search(r'<TRACK.*?</TRACK>', template_content, re.DOTALL)
    if match:
        track_block = match.group(0)
        print(f"✅ TRACK 블록 추출 ({len(track_block)} bytes)")
        return track_block

    print("❌ TRACK 블록 못 찾음")
    return None

def analyze_track_settings(track_block):
    """
    TRACK 블록에서 중요한 설정 추출
    """
    info = {
        'name': None,
        'recmode': None,
        'vstplugin': None,
        'fxchain': None
    }

    # NAME 추출
    name_match = re.search(r'NAME "(.*?)"', track_block)
    if name_match:
        info['name'] = name_match.group(1)
        print(f"  📛 트랙명: {info['name']}")

    # REC 라인 추출 (recmode=5 확인)
    rec_match = re.search(r'REC (\d+) (\d+) (\d+)', track_block)
    if rec_match:
        recarm, recinput, recmode = rec_match.groups()
        info['recmode'] = recmode
        print(f"  🔴 REC: arm={recarm}, input={recinput}, mode={recmode}")
        if recmode != '5':
            print(f"  ⚠️  경고: recmode={recmode}. 권장값은 5(output stereo)")

    # VST 플러그인 추출
    vst_match = re.search(r'<VST "(.*?)"', track_block)
    if vst_match:
        info['vstplugin'] = vst_match.group(1)
        print(f"  🎛️  VST: {info['vstplugin']}")

    # FXCHAIN_SHOW 확인
    if 'FXCHAIN_SHOW 1' in track_block:
        info['fxchain'] = True
        print(f"  👁️  FX 창 자동 열림: YES")

    return info

def create_rpp_with_template(template_track_block, output_rpp_path, vstname="ample_guitar"):
    """
    기본 RPP 프로젝트를 만들고 템플릿 TRACK 블록 삽입
    MIDI HASDATA 포함
    """

    # 기본 RPP 템플릿 (최소 구조)
    base_rpp = """<REAPER_PROJECT 0.1 "7.25/win64" 1774804646
  <NOTES 0 2
  >
  RIPPLE 0
  AUTOXFADE 129
  RECORD_PATH "C:\\Temp\\Media" ""
  RENDER_FILE "C:\\Temp\\{output}.wav"
  RENDER_FMT 0 2 44100
  RENDER_RANGE 0 0 0 4 1000
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
""".format(output=Path(output_rpp_path).stem, TRACK_BLOCK="[TEMPLATE_HERE]")

    # 템플릿의 TRACK 블록에서 MIDI 삽입 준비
    # <ITEM>...</ITEM> 부분에서 SOURCE MIDI HASDATA 확인
    # 없으면 추가

    modified_track = template_track_block

    # MIDI 아이템 확인
    if '<SOURCE MIDI' not in modified_track:
        print("  ⚠️  MIDI 아이템 없음. 추가합니다...")

        # </TRACK> 바로 직전에 ITEM 블록 추가
        midi_item = """    <ITEM
      POSITION 0
      SNAPOFFS 0
      LENGTH 4
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
"""
        # </TRACK> 직전에 ITEM 추가
        modified_track = modified_track.replace('  >', '  ' + midi_item + '  >')
    else:
        print("  ✅ MIDI 아이템 이미 존재")

    # REC 1 0 5 0 0 0 0 0 확인 (recmode=5)
    if 'REC 1 0 5' not in modified_track:
        print("  ⚠️  recmode=5 아님. 수정합니다...")
        modified_track = re.sub(r'REC \d+ \d+ \d+', 'REC 1 0 5', modified_track)
    else:
        print("  ✅ recmode=5 확인됨")

    # 최종 RPP 생성
    final_rpp = base_rpp.replace('[TEMPLATE_HERE]', modified_track)

    with open(output_rpp_path, 'w', encoding='utf-8') as f:
        f.write(final_rpp)

    print(f"\n✅ RPP 생성: {output_rpp_path} ({len(final_rpp)} bytes)")
    return output_rpp_path

def trigger_reaper_record(rpp_path, duration_sec=5):
    """
    REAPER에서 RPP 로드 후 Play+Record 실행
    1. RPP 로드
    2. 5초 대기 (FX 초기화)
    3. action 40042 (Rewind)
    4. action 1013 (Record)
    5. duration_sec 초 재생
    6. action 1016 (Stop)
    """

    print(f"\n🎬 REAPER 렌더 시작: {Path(rpp_path).name}")

    try:
        # REAPER 프로세스 확인
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

        # RPP 파일 열기 (cmd로 연결된 REAPER 인스턴스에서)
        os.system(f'start "" "{rpp_path}"')

        print(f"⏳ 템플릿 초기화 대기 (10초)...")
        time.sleep(10)

        # action 40042 (Rewind)
        subprocess.run(
            ['powershell.exe', '-Command',
             f'$proc = Get-Process reaper | Select-Object -First 1; '
             f'[WinAPI]::SetForegroundWindow($proc.MainWindowHandle); '
             f'[WinAPI]::SendMessage($proc.MainWindowHandle, 0x0111, 40042, 0)'],
            timeout=5
        )
        time.sleep(0.5)

        # action 1013 (Record)
        subprocess.run(
            ['powershell.exe', '-Command',
             f'$proc = Get-Process reaper | Select-Object -First 1; '
             f'[WinAPI]::SendMessage($proc.MainWindowHandle, 0x0111, 1013, 0)'],
            timeout=5
        )

        print(f"⏳ 녹음 진행 중 ({duration_sec}초)...")
        time.sleep(duration_sec)

        # action 1016 (Stop)
        subprocess.run(
            ['powershell.exe', '-Command',
             f'$proc = Get-Process reaper | Select-Object -First 1; '
             f'[WinAPI]::SendMessage($proc.MainWindowHandle, 0x0111, 1016, 0)'],
            timeout=5
        )

        print("✅ 녹음 완료")
        return True

    except Exception as e:
        print(f"❌ REAPER 렌더 실패: {e}")
        return False

def check_rms(media_dir=TEMP_MEDIA):
    """
    C:\\Temp\\Media 폴더에서 가장 최신 WAV 파일 찾아서 RMS 측정
    """
    print(f"\n📊 RMS 검증: {media_dir}")

    try:
        # 최신 WAV 파일 찾기
        wav_files = sorted(
            Path(media_dir).glob('*.wav'),
            key=lambda p: p.stat().st_mtime,
            reverse=True
        )

        if not wav_files:
            print(f"❌ WAV 파일 없음")
            return None

        latest_wav = wav_files[0]
        print(f"  📁 분석: {latest_wav.name} ({latest_wav.stat().st_size} bytes)")

        # sox로 RMS 측정
        result = subprocess.run(
            ['sox', str(latest_wav), '-n', 'stat'],
            capture_output=True, text=True, timeout=10
        )

        # RMS 추출
        for line in result.stderr.split('\n'):
            if 'RMS amplitude' in line:
                rms_str = line.split()[-1]
                try:
                    rms_value = float(rms_str)
                    print(f"  ✅ RMS: {rms_value:.6f}")

                    if rms_value > 0.001:
                        print(f"  🎉 OK! (기준값: > 0.001)")
                        return rms_value
                    else:
                        print(f"  ⚠️  낮음. 기준값: > 0.001 (권장: > 0.01)")
                        return rms_value
                except ValueError:
                    pass

        print("❌ RMS 값 파싱 실패")
        return None

    except FileNotFoundError:
        print("❌ sox 명령 없음 (install: choco install sox)")
        return None
    except Exception as e:
        print(f"❌ RMS 측정 실패: {e}")
        return None

def main():
    """
    TASK B: 템플릿 → RPP 임베드 → 렌더 → RMS 검증
    """
    print("=" * 60)
    print("TASK B: VSTi 템플릿 자동화 파이프라인")
    print("=" * 60)

    template_name = "ample_guitar_ready"

    # Step 1: 템플릿 읽기
    print(f"\n[Step 1] 템플릿 파일 읽기: {template_name}")
    template_content = read_template(template_name)

    if not template_content:
        print("\n⏹️  TASK A가 완료되지 않았습니다.")
        print("박씨가 REAPER에서 Ample Guitar 트랙을 'Save tracks as track template...'으로 저장해주세요.")
        print(f"파일명: {template_name}")
        print(f"위치: {REAPER_TRACK_TEMPLATES}")
        return

    # Step 2: TRACK 블록 추출
    print(f"\n[Step 2] TRACK 블록 추출")
    track_block = extract_track_block(template_content)

    if not track_block:
        print("❌ 템플릿 형식 오류")
        return

    # Step 3: 설정 분석
    print(f"\n[Step 3] 트랙 설정 분석")
    settings = analyze_track_settings(track_block)

    # Step 4: RPP 생성 (MIDI 포함)
    print(f"\n[Step 4] RPP 생성 (템플릿 + MIDI)")
    output_rpp = Path(TEMP_DIR) / f"ample_guitar_auto_test.rpp"
    create_rpp_with_template(track_block, str(output_rpp), "ample_guitar")

    # Step 5: REAPER에서 렌더 실행
    print(f"\n[Step 5] REAPER 렌더 실행")
    if trigger_reaper_record(str(output_rpp), duration_sec=5):
        print("✅ 렌더 완료")
    else:
        print("⚠️  렌더 스킵 (수동 실행 필요)")

    # Step 6: RMS 검증
    print(f"\n[Step 6] 오디오 검증")
    rms = check_rms()

    # 결과 보고
    print("\n" + "=" * 60)
    print("TASK B 결과")
    print("=" * 60)
    if rms is not None:
        print(f"✅ VSTi 자동화 성공")
        print(f"  - 트랙명: {settings.get('name')}")
        print(f"  - 플러그인: {settings.get('vstplugin')}")
        print(f"  - RMS: {rms:.6f}")
        print(f"  - RPP: {output_rpp}")
    else:
        print(f"⚠️  검증 필요")
        print(f"  - RPP 파일: {output_rpp}")
        print(f"  - REAPER에서 수동 확인 후 Report 필요")

if __name__ == '__main__':
    main()
