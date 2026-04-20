"""
오디오/비디오 양방향 브릿지
@parksy_bridges_bot 전용 (오디오/비디오 ONLY)

양방향:
  Phone -> PC: 텔레그램에 오디오/비디오 보내면 자동 다운로드
  PC -> Phone: outbox/ 폴더에 넣으면 자동 전송

사용법:
  python3 audio_bridge.py              # 감시 모드 (자동)
  python3 audio_bridge.py send file.mp4  # 수동 전송
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
        print("[ERROR] audio_config.json 없음")
        sys.exit(1)
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

config = load_config()
BOT_TOKEN = config["bot_token"]
CHAT_ID = config["chat_id"]
OUTBOX_DIR = config.get("outbox_dir", os.path.join(SCRIPT_DIR, "outbox"))
SENT_DIR = config.get("sent_dir", os.path.join(SCRIPT_DIR, "sent"))
_DEFAULT_INBOX_DIR = os.environ.get(
    "PARKSY_AUDIO_INBOX",
    os.path.join(os.path.expanduser("~"), "parksy-audio", "local-agent", "inbox")
)
INBOX_DIR = config.get("inbox_dir", _DEFAULT_INBOX_DIR)
_DEFAULT_MIDI_DIR = os.environ.get(
    "PARKSY_MIDI_DIR",
    os.path.join(os.path.expanduser("~"), "parksy-audio", "local-agent", "sources")
)
MIDI_DIR = config.get("midi_dir", _DEFAULT_MIDI_DIR)
WATCH_DIRS = config.get("watch_dirs", [])
POLL_INTERVAL = config.get("poll_interval", 10)
BASE_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"

# -- 오프셋 추적 (중복 수신 방지) --
OFFSET_FILE = os.path.join(SCRIPT_DIR, ".audio_last_update_id")

def get_offset():
    if os.path.exists(OFFSET_FILE):
        with open(OFFSET_FILE, "r") as f:
            return int(f.read().strip()) + 1
    return 0

def save_offset(offset):
    with open(OFFSET_FILE, "w") as f:
        f.write(str(offset))

# ====================================
# Phone -> PC 수신
# ====================================

def download_file(file_id, filename, dest_dir):
    resp = requests.get(f"{BASE_URL}/getFile", params={"file_id": file_id})
    data = resp.json()
    if not data.get("ok"):
        print(f"  [FAIL] getFile 실패: {data}")
        return False

    file_path = data["result"]["file_path"]
    url = f"https://api.telegram.org/file/bot{BOT_TOKEN}/{file_path}"
    content = requests.get(url).content

    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, filename)
    if os.path.exists(dest):
        name, ext = os.path.splitext(filename)
        ts = datetime.now().strftime("%H%M%S")
        dest = os.path.join(dest_dir, f"{name}_{ts}{ext}")

    with open(dest, "wb") as f:
        f.write(content)

    size_kb = len(content) / 1024
    print(f"  [DOWN] {os.path.basename(dest)} ({size_kb:.0f}KB) -> {dest_dir}")
    return True

def process_incoming(msg):
    # Document (원본 파일)
    doc = msg.get("document")
    if doc:
        fname = doc.get("file_name", "unknown")
        _, ext = os.path.splitext(fname.lower())
        if ext in MIDI_EXTS:
            print(f"  MIDI 수신: {fname}")
            download_file(doc["file_id"], fname, MIDI_DIR)
        elif ext in ALL_EXTS:
            print(f"  오디오/비디오 수신: {fname}")
            download_file(doc["file_id"], fname, INBOX_DIR)
        else:
            print(f"  [SKIP] 지원 안 하는 파일: {fname}")
        return

    # Audio
    audio = msg.get("audio")
    if audio:
        fname = audio.get("file_name") or f"audio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp3"
        print(f"  오디오 수신: {fname}")
        download_file(audio["file_id"], fname, INBOX_DIR)
        return

    # Voice
    voice = msg.get("voice")
    if voice:
        fname = f"voice_{datetime.now().strftime('%Y%m%d_%H%M%S')}.ogg"
        print(f"  음성메시지 수신: {fname}")
        download_file(voice["file_id"], fname, INBOX_DIR)
        return

    # Video
    video = msg.get("video")
    if video:
        fname = video.get("file_name") or f"video_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp4"
        print(f"  비디오 수신: {fname}")
        download_file(video["file_id"], fname, INBOX_DIR)
        return

    # Video note (동그란 비디오)
    vnote = msg.get("video_note")
    if vnote:
        fname = f"videonote_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp4"
        print(f"  비디오노트 수신: {fname}")
        download_file(vnote["file_id"], fname, INBOX_DIR)
        return

def poll_incoming():
    offset = get_offset()
    try:
        resp = requests.get(f"{BASE_URL}/getUpdates", params={
            "offset": offset, "timeout": 5
        }, timeout=15)
        updates = resp.json().get("result", [])
    except requests.exceptions.Timeout:
        return 0
    except Exception as e:
        print(f"  [ERROR] 수신 폴링: {e}")
        return 0

    count = 0
    for update in updates:
        save_offset(update["update_id"])
        msg = update.get("message") or update.get("channel_post")
        if msg:
            process_incoming(msg)
            count += 1
    return count

# ====================================
# PC -> Phone 전송
# ====================================

def send_file(filepath):
    filename = os.path.basename(filepath)
    ext = os.path.splitext(filename.lower())[1]
    size_mb = os.path.getsize(filepath) / (1024 * 1024)

    if size_mb > 50:
        print(f"  [SKIP] {filename} ({size_mb:.1f}MB) - 50MB 초과")
        return False

    if ext in VIDEO_EXTS:
        method, field = "sendVideo", "video"
    elif ext in AUDIO_EXTS:
        method, field = "sendAudio", "audio"
    else:
        method, field = "sendDocument", "document"

    try:
        with open(filepath, "rb") as f:
            resp = requests.post(
                f"{BASE_URL}/{method}",
                data={"chat_id": CHAT_ID, "caption": f"[PC->Phone] {filename}"},
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
    os.makedirs(SENT_DIR, exist_ok=True)
    dest = os.path.join(SENT_DIR, os.path.basename(filepath))
    if os.path.exists(dest):
        name, ext = os.path.splitext(os.path.basename(filepath))
        ts = datetime.now().strftime("%H%M%S")
        dest = os.path.join(SENT_DIR, f"{name}_{ts}{ext}")
    shutil.move(filepath, dest)

def scan_outbox():
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
            if "_final" in fname.lower() or pattern == "*":
                filepath = os.path.join(wdir, fname)
                marker = filepath + ".sent"
                if os.path.exists(marker):
                    continue
                if send_file(filepath):
                    with open(marker, "w") as f:
                        f.write(datetime.now().isoformat())
                    count += 1
    return count

def manual_send(filepath):
    if not os.path.exists(filepath):
        print(f"[ERROR] 파일 없음: {filepath}")
        return
    send_file(filepath)

# ====================================
# 메인
# ====================================

def main():
    if len(sys.argv) > 2 and sys.argv[1] == "send":
        manual_send(sys.argv[2])
        return

    print("=" * 50)
    print("  오디오/비디오 양방향 브릿지")
    print("  @parksy_bridges_bot")
    print("=" * 50)
    print(f"  Phone->PC: {os.path.abspath(INBOX_DIR)}")
    print(f"  MIDI->PC:  {os.path.abspath(MIDI_DIR)}")
    print(f"  PC->Phone: {os.path.abspath(OUTBOX_DIR)}")
    print(f"  Sent:      {os.path.abspath(SENT_DIR)}")
    for w in WATCH_DIRS:
        print(f"  Watch:     {w.get('dir', '?')}")
    print(f"  폴링: {POLL_INTERVAL}초 간격")
    print(f"  Ctrl+C로 종료")
    print("=" * 50)
    print()

    while True:
        try:
            c_in = poll_incoming()
            c_out = scan_outbox()
            c_watch = scan_watch_dirs()
            total = c_in + c_out + c_watch
            if total > 0:
                parts = []
                if c_in:
                    parts.append(f"수신 {c_in}")
                if c_out + c_watch:
                    parts.append(f"전송 {c_out + c_watch}")
                print(f"  --- {', '.join(parts)} ---\n")
            time.sleep(POLL_INTERVAL)
        except KeyboardInterrupt:
            print("\n종료.")
            break

if __name__ == "__main__":
    main()
