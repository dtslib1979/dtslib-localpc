"""
Telegram → PC 자동 다운로더
parksy-image 유닛 이미지 브릿지 + parksy-audio MIDI 브릿지

사용법:
  python downloader.py

PC에서 백그라운드로 돌려놓으면
텔레그램 채널에 보낸 이미지가 자동으로 00_inbox/에,
MIDI 파일은 parksy-audio sources/에 착지한다.
"""

import requests
import os
import json
import time
import sys
from datetime import datetime

# ── 설정 로드 ──
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")

def load_config():
    if not os.path.exists(CONFIG_PATH):
        print(f"[ERROR] config.json 없음. config.example.json 복사해서 만들어.")
        print(f"  cp config.example.json config.json")
        print(f"  → bot_token 넣기")
        sys.exit(1)
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

config = load_config()
BOT_TOKEN = config["bot_token"]
DOWNLOAD_DIR = config.get("download_dir", os.path.join(SCRIPT_DIR, "..", "..", "00_inbox"))
_DEFAULT_MIDI_DIR = os.environ.get(
    "PARKSY_MIDI_DIR",
    os.path.join(os.path.expanduser("~"), "parksy-audio", "local-agent", "sources")
)
MIDI_DIR = config.get("midi_dir", _DEFAULT_MIDI_DIR)
POLL_INTERVAL = config.get("poll_interval", 30)
BASE_URL = f"https://api.telegram.org/bot{BOT_TOKEN}"

# ── 오프셋 추적 (중복 다운로드 방지) ──
OFFSET_FILE = os.path.join(SCRIPT_DIR, ".last_update_id")

def get_offset():
    if os.path.exists(OFFSET_FILE):
        with open(OFFSET_FILE, "r") as f:
            return int(f.read().strip()) + 1
    return 0

def save_offset(offset):
    with open(OFFSET_FILE, "w") as f:
        f.write(str(offset))

# ── 다운로드 ──
def download_file(file_id, filename=None, dest_dir=None):
    if dest_dir is None:
        dest_dir = DOWNLOAD_DIR

    resp = requests.get(f"{BASE_URL}/getFile", params={"file_id": file_id})
    data = resp.json()

    if not data.get("ok"):
        print(f"  [FAIL] getFile 실패: {data}")
        return False

    file_path = data["result"]["file_path"]
    url = f"https://api.telegram.org/file/bot{BOT_TOKEN}/{file_path}"

    content = requests.get(url).content

    # 파일명 결정
    if not filename:
        filename = os.path.basename(file_path)

    # 대상 폴더 자동 생성
    os.makedirs(dest_dir, exist_ok=True)

    # 중복 방지: 같은 이름 있으면 타임스탬프 붙임
    dest = os.path.join(dest_dir, filename)
    if os.path.exists(dest):
        name, ext = os.path.splitext(filename)
        timestamp = datetime.now().strftime("%H%M%S")
        filename = f"{name}_{timestamp}{ext}"
        dest = os.path.join(dest_dir, filename)

    with open(dest, "wb") as f:
        f.write(content)

    size_kb = len(content) / 1024
    print(f"  [OK] {filename} ({size_kb:.0f}KB) → {dest_dir}")
    return True

# ── 확장자 필터 ──
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".svg"}
MIDI_EXTS  = {".mid", ".midi"}
VIDEO_EXTS = {".mp4", ".mov", ".webm", ".mkv"}

# 오프닝 영상 스테이징 폴더 (web2video --opening 인수로 전달)
_DEFAULT_VIDEO_DIR = os.environ.get(
    "PARKSY_OPENING_DIR",
    "/mnt/d/PARKSY/web2video/opening_staging"
)
VIDEO_DIR = config.get("video_dir", _DEFAULT_VIDEO_DIR)

def file_type(filename):
    """파일 타입 판별: 'image' | 'midi' | 'video' | None"""
    if not filename:
        return "image"  # 확장자 모르면 이미지로 간주
    _, ext = os.path.splitext(filename.lower())
    if ext in IMAGE_EXTS:
        return "image"
    if ext in MIDI_EXTS:
        return "midi"
    if ext in VIDEO_EXTS:
        return "video"
    return None

# ── 메시지 처리 ──
def process_message(msg):
    # Document (원본 화질 / MIDI / 영상 파일)
    doc = msg.get("document")
    if doc:
        fname = doc.get("file_name", "unknown")
        ftype = file_type(fname)
        if ftype == "midi":
            print(f"  MIDI: {fname} → {MIDI_DIR}")
            download_file(doc["file_id"], fname, dest_dir=MIDI_DIR)
        elif ftype == "image":
            print(f"  Document: {fname}")
            download_file(doc["file_id"], fname)
        elif ftype == "video":
            # 오프닝 영상 → 스테이징 폴더에 opening_latest.mp4 로 저장
            os.makedirs(VIDEO_DIR, exist_ok=True)
            print(f"  Video(오프닝): {fname} → {VIDEO_DIR}/opening_latest.mp4")
            download_file(doc["file_id"], fname, dest_dir=VIDEO_DIR)
            # 항상 opening_latest.mp4 심링크/복사로 고정 이름 제공
            latest = os.path.join(VIDEO_DIR, "opening_latest.mp4")
            saved  = os.path.join(VIDEO_DIR, fname)
            if os.path.exists(latest) and os.path.realpath(latest) != os.path.realpath(saved):
                os.remove(latest)
            if not os.path.exists(latest):
                try:
                    os.symlink(saved, latest)
                except OSError:
                    import shutil as _s; _s.copy2(saved, latest)
            print(f"  → opening_latest.mp4 갱신됨")
            print(f"  사용법: python3 web2video.py URL --opening '{latest}'")
        else:
            print(f"  [SKIP] 지원 안 하는 파일: {fname}")
        return

    # Photo (압축됨 — 최대 해상도 선택)
    photos = msg.get("photo")
    if photos:
        best = photos[-1]  # 마지막 = 최대 해상도
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        fname = f"photo_{timestamp}.jpg"
        print(f"  Photo: {fname} (압축됨 — 원본은 '파일'로 보내세요)")
        download_file(best["file_id"], fname)
        return

# ── 폴링 루프 ──
def poll():
    offset = get_offset()
    try:
        resp = requests.get(f"{BASE_URL}/getUpdates", params={
            "offset": offset,
            "timeout": POLL_INTERVAL
        }, timeout=POLL_INTERVAL + 10)
        updates = resp.json().get("result", [])
    except requests.exceptions.Timeout:
        return 0
    except Exception as e:
        print(f"  [ERROR] {e}")
        time.sleep(5)
        return 0

    count = 0
    for update in updates:
        save_offset(update["update_id"])
        msg = update.get("message") or update.get("channel_post")
        if msg:
            process_message(msg)
            count += 1

    return count

def main():
    # 다운로드 폴더 생성
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)

    print("=" * 50)
    print("  Telegram → parksy 통합 브릿지")
    print("=" * 50)
    print(f"  이미지 → {os.path.abspath(DOWNLOAD_DIR)}")
    print(f"  MIDI   → {os.path.abspath(MIDI_DIR)}")
    print(f"  영상   → {os.path.abspath(VIDEO_DIR)}  (opening_latest.mp4)")
    print(f"  폴링: {POLL_INTERVAL}초 간격")
    print(f"  Ctrl+C로 종료")
    print("=" * 50)
    print()

    while True:
        try:
            count = poll()
            if count > 0:
                print(f"  --- {count}개 수신 완료 ---\n")
        except KeyboardInterrupt:
            print("\n종료.")
            break

if __name__ == "__main__":
    main()
