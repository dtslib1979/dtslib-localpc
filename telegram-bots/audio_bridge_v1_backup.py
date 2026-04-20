"""
PC → 핸드폰 오디오/비디오 전송 브릿지
@parksy_bridges_bot 전용 (오디오/비디오 ONLY)

사용법:
  python3 audio_bridge.py              # 감시 모드 (자동)
  python3 audio_bridge.py send file.mp4  # 수동 전송

outbox/ 폴더에 파일 넣으면 자동으로 텔레그램 전송 후 sent/로 이동
"""

import requests
import os
import sys
import json
import time
import shutil
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "audio_config.json")

# 지원 확장자
AUDIO_EXTS = {".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac"}
VIDEO_EXTS = {".mp4", ".mkv", ".avi", ".mov", ".webm"}
MIDI_EXTS = {".mid", ".midi"}
ALL_EXTS = AUDIO_EXTS | VIDEO_EXTS | MIDI_EXTS

def load_config():
    if not os.path.exists(CONFIG_PATH):
        print(f"[ERROR] audio_config.json 없음")
        sys.exit(1)
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

config = load_config()
BOT_TOKEN = config["bot_token"]
CHAT_ID = config["chat_id"]
OUTBOX_DIR = config.get("outbox_dir", os.path.join(SCRIPT_DIR, "outbox"))
SENT_DIR = config.get("sent_dir", os.path.join(SCRIPT_DIR, "sent"))
WATCH_DIRS = config.get("watch_dirs", [])
POLL_INTERVAL = config.get("poll_interval", 10)
BASE_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"

def send_file(filepath):
    """파일을 텔레그램으로 전송"""
    filename = os.path.basename(filepath)
    ext = os.path.splitext(filename.lower())[1]
    size_mb = os.path.getsize(filepath) / (1024 * 1024)

    if size_mb > 50:
        print(f"  [SKIP] {filename} ({size_mb:.1f}MB) - 50MB 초과")
        return False

    # 전송 방식 결정
    if ext in VIDEO_EXTS:
        method = "sendVideo"
        field = "video"
    elif ext in AUDIO_EXTS:
        method = "sendAudio"
        field = "audio"
    else:
        method = "sendDocument"
        field = "document"

    try:
        with open(filepath, "rb") as f:
            resp = requests.post(
                f"{BASE_URL}/{method}",
                data={"chat_id": CHAT_ID, "caption": f"[PC→Phone] {filename}"},
                files={field: (filename, f)},
                timeout=120
            )
        result = resp.json()
        if result.get("ok"):
            print(f"  [SENT] {filename} ({size_mb:.1f}MB) via {method}")
            return True
        else:
            print(f"  [FAIL] {filename}: {result.get('description', 'unknown error')}")
            return False
    except Exception as e:
        print(f"  [ERROR] {filename}: {e}")
        return False

def move_to_sent(filepath):
    """전송 완료된 파일을 sent/로 이동"""
    os.makedirs(SENT_DIR, exist_ok=True)
    dest = os.path.join(SENT_DIR, os.path.basename(filepath))
    if os.path.exists(dest):
        name, ext = os.path.splitext(os.path.basename(filepath))
        ts = datetime.now().strftime("%H%M%S")
        dest = os.path.join(SENT_DIR, f"{name}_{ts}{ext}")
    shutil.move(filepath, dest)

def scan_outbox():
    """outbox/ 폴더 스캔 → 전송"""
    os.makedirs(OUTBOX_DIR, exist_ok=True)
    count = 0
    for fname in os.listdir(OUTBOX_DIR):
        ext = os.path.splitext(fname.lower())[1]
        if ext not in ALL_EXTS:
            continue
        filepath = os.path.join(OUTBOX_DIR, fname)
        if os.path.isfile(filepath):
            if send_file(filepath):
                move_to_sent(filepath)
                count += 1
    return count

def scan_watch_dirs():
    """추가 감시 폴더들 스캔 (복사 전송, 원본 유지)"""
    count = 0
    for watch in WATCH_DIRS:
        wdir = watch.get("dir", "")
        pattern = watch.get("pattern", "*_final.*")
        if not os.path.isdir(wdir):
            continue
        for fname in os.listdir(wdir):
            ext = os.path.splitext(fname.lower())[1]
            if ext not in ALL_EXTS:
                continue
            # _final 패턴 매칭 (간단하게)
            if "_final" in fname.lower() or pattern == "*":
                filepath = os.path.join(wdir, fname)
                # 이미 전송했는지 체크
                marker = filepath + ".sent"
                if os.path.exists(marker):
                    continue
                if send_file(filepath):
                    # 마커 파일 생성 (원본은 유지)
                    with open(marker, "w") as f:
                        f.write(datetime.now().isoformat())
                    count += 1
    return count

def manual_send(filepath):
    """수동 전송"""
    if not os.path.exists(filepath):
        print(f"[ERROR] 파일 없음: {filepath}")
        return
    send_file(filepath)

def main():
    if len(sys.argv) > 2 and sys.argv[1] == "send":
        manual_send(sys.argv[2])
        return

    print("=" * 50)
    print("  PC → Phone 오디오/비디오 브릿지")
    print("  @parksy_bridges_bot")
    print("=" * 50)
    print(f"  Outbox: {os.path.abspath(OUTBOX_DIR)}")
    print(f"  Sent:   {os.path.abspath(SENT_DIR)}")
    for w in WATCH_DIRS:
        print(f"  Watch:  {w.get('dir', '?')}")
    print(f"  폴링:   {POLL_INTERVAL}초 간격")
    print(f"  Ctrl+C로 종료")
    print("=" * 50)
    print()

    while True:
        try:
            c1 = scan_outbox()
            c2 = scan_watch_dirs()
            total = c1 + c2
            if total > 0:
                print(f"  --- {total}개 전송 완료 ---\n")
            time.sleep(POLL_INTERVAL)
        except KeyboardInterrupt:
            print("\n종료.")
            break

if __name__ == "__main__":
    main()
