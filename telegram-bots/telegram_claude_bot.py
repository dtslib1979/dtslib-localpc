"""
Telegram Claude Bot
텔레그램에서 메시지 보내면 Claude Code CLI 실행, 결과 반환

사용법:
  python3 telegram_claude_bot.py --config claude_image_config.json
  python3 telegram_claude_bot.py --config claude_audio_config.json
"""

import requests
import subprocess
import os
import sys
import json
import time
import argparse
import shutil as _shutil
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Claude Code CLI 경로
def _find_claude():
    """claude 바이너리 동적 탐색."""
    # 1) 환경변수 우선
    if os.environ.get("CLAUDE_BIN"):
        return os.environ["CLAUDE_BIN"]
    # 2) PATH에서 찾기
    found = _shutil.which("claude")
    if found:
        return found
    # 3) NVM 패턴 fallback
    nvm_root = os.path.expanduser("~/.nvm/versions/node")
    if os.path.isdir(nvm_root):
        for ver_dir in sorted(os.listdir(nvm_root), reverse=True):
            candidate = os.path.join(nvm_root, ver_dir, "bin", "claude")
            if os.path.isfile(candidate):
                return candidate
    return "claude"  # 마지막 fallback — PATH에 있길 기대

def _find_node_path():
    """node bin 디렉토리 탐색."""
    if os.environ.get("NODE_PATH"):
        return os.environ["NODE_PATH"]
    node_bin = _shutil.which("node")
    if node_bin:
        return os.path.dirname(node_bin)
    nvm_root = os.path.expanduser("~/.nvm/versions/node")
    if os.path.isdir(nvm_root):
        for ver_dir in sorted(os.listdir(nvm_root), reverse=True):
            candidate = os.path.join(nvm_root, ver_dir, "bin")
            if os.path.isdir(candidate):
                return candidate
    return "/usr/local/bin"

CLAUDE_BIN = _find_claude()
NODE_PATH = _find_node_path()

def load_config(config_path):
    with open(config_path, "r") as f:
        return json.load(f)

# ====================================
# Telegram API
# ====================================

class TelegramBot:
    def __init__(self, token, chat_id):
        self.token = token
        self.chat_id = chat_id
        self.base_url = f"https://api.telegram.org/bot{token}"

    def send_message(self, text, parse_mode=None):
        """메시지 전송 (4096자 제한 자동 분할)"""
        MAX_LEN = 4000
        chunks = []
        while text:
            if len(text) <= MAX_LEN:
                chunks.append(text)
                break
            # 줄바꿈 기준으로 분할
            cut = text[:MAX_LEN].rfind("\n")
            if cut < 100:
                cut = MAX_LEN
            chunks.append(text[:cut])
            text = text[cut:].lstrip("\n")

        for chunk in chunks:
            data = {"chat_id": self.chat_id, "text": chunk}
            if parse_mode:
                data["parse_mode"] = parse_mode
            try:
                requests.post(f"{self.base_url}/sendMessage", data=data, timeout=30)
            except Exception as e:
                print(f"  [ERROR] sendMessage: {e}")

    def send_document(self, filepath, caption=""):
        """파일 전송"""
        try:
            with open(filepath, "rb") as f:
                requests.post(
                    f"{self.base_url}/sendDocument",
                    data={"chat_id": self.chat_id, "caption": caption[:1024]},
                    files={"document": (os.path.basename(filepath), f)},
                    timeout=120
                )
        except Exception as e:
            print(f"  [ERROR] sendDocument: {e}")

# ====================================
# Offset 추적
# ====================================

class OffsetTracker:
    def __init__(self, filepath):
        self.filepath = filepath

    def get(self):
        if os.path.exists(self.filepath):
            with open(self.filepath, "r") as f:
                return int(f.read().strip()) + 1
        return 0

    def save(self, offset):
        with open(self.filepath, "w") as f:
            f.write(str(offset))

# ====================================
# Claude Code 실행
# ====================================

class ClaudeRunner:
    def __init__(self, work_dir, timeout=300):
        self.work_dir = work_dir
        self.timeout = timeout
        self.busy = False
        self.env = os.environ.copy()
        self.env["PATH"] = f"{NODE_PATH}:/home/dtsli/.local/bin:{self.env.get('PATH', '')}"
        self.env["HOME"] = "/home/dtsli"

    def run(self, prompt, continue_session=False):
        if self.busy:
            return "[BUSY] 이전 작업 진행 중. 잠시 후 다시 보내세요."

        self.busy = True
        try:
            cmd = [
                CLAUDE_BIN, "-p", prompt,
                "--dangerously-skip-permissions",
                "--output-format", "text"
            ]
            if continue_session:
                cmd.append("--continue")

            print(f"  [RUN] claude -p \"{prompt[:50]}...\"")
            start = time.time()

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                cwd=self.work_dir,
                env=self.env
            )

            elapsed = time.time() - start
            output = result.stdout.strip()
            stderr = result.stderr.strip()

            if not output and stderr:
                output = f"[stderr]\n{stderr}"
            elif not output:
                output = "(응답 없음)"

            print(f"  [DONE] {elapsed:.1f}초, {len(output)}자")
            return output

        except subprocess.TimeoutExpired:
            return f"[TIMEOUT] {self.timeout}초 초과. 작업이 너무 오래 걸립니다."
        except Exception as e:
            return f"[ERROR] {e}"
        finally:
            self.busy = False

# ====================================
# 메시지 처리
# ====================================

def process_message(msg, bot, runner):
    chat_id = msg.get("chat", {}).get("id")
    if chat_id != bot.chat_id:
        return

    text = msg.get("text", "").strip()
    if not text:
        return

    # /start 명령
    if text == "/start":
        bot.send_message(
            f"Claude Code 연동 봇\n"
            f"작업 디렉토리: {runner.work_dir}\n\n"
            f"메시지를 보내면 Claude가 작업합니다.\n"
            f"/c 이어서 작업 — 이전 대화 이어가기\n"
            f"/status — 상태 확인"
        )
        return

    # /status 명령
    if text == "/status":
        bot.send_message(
            f"작업 디렉토리: {runner.work_dir}\n"
            f"Claude: {CLAUDE_BIN}\n"
            f"상태: {'작업 중' if runner.busy else '대기'}\n"
            f"시각: {datetime.now().strftime('%H:%M:%S')}"
        )
        return

    # /c 이전 대화 이어가기
    continue_session = False
    if text.startswith("/c "):
        text = text[3:].strip()
        continue_session = True

    # 작업 시작 알림
    bot.send_message(f"작업 시작...")

    # Claude 실행
    result = runner.run(text, continue_session)

    # 결과가 너무 길면 파일로 전송
    if len(result) > 10000:
        tmpfile = f"/tmp/claude_result_{datetime.now().strftime('%H%M%S')}.txt"
        with open(tmpfile, "w") as f:
            f.write(result)
        bot.send_document(tmpfile, caption=f"결과 ({len(result)}자)")
        # 앞부분 미리보기
        bot.send_message(result[:2000] + "\n\n... (전체 결과는 파일 참조)")
        os.remove(tmpfile)
    else:
        bot.send_message(result)

# ====================================
# 메인 루프
# ====================================

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, help="Config JSON 파일 경로")
    args = parser.parse_args()

    config = load_config(args.config)

    bot_token = config["bot_token"]
    chat_id = config["chat_id"]
    work_dir = config["work_dir"]
    bot_name = config.get("bot_name", "Claude Bot")
    timeout = config.get("timeout", 300)

    bot = TelegramBot(bot_token, chat_id)
    runner = ClaudeRunner(work_dir, timeout)
    offset_file = os.path.join(SCRIPT_DIR, f".{config.get('offset_file', 'claude_bot')}_last_update_id")
    tracker = OffsetTracker(offset_file)

    print("=" * 50)
    print(f"  {bot_name}")
    print(f"  작업 디렉토리: {work_dir}")
    print(f"  타임아웃: {timeout}초")
    print(f"  Ctrl+C로 종료")
    print("=" * 50)

    while True:
        try:
            offset = tracker.get()
            resp = requests.get(
                f"https://api.telegram.org/bot{bot_token}/getUpdates",
                params={"offset": offset, "timeout": 30},
                timeout=40
            )
            updates = resp.json().get("result", [])

            for update in updates:
                tracker.save(update["update_id"])
                msg = update.get("message")
                if msg:
                    process_message(msg, bot, runner)

        except KeyboardInterrupt:
            print("\n종료.")
            break
        except Exception as e:
            print(f"  [ERROR] {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
