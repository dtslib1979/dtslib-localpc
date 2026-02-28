"""
PC CCTV — Claude Code 작업 화면 자동 캡처 + Claude.ai 실시간 해설

사용법:
    python cctv.py                  # 기본 설정으로 실행
    python cctv.py --interval 60    # 60초 간격
    python cctv.py --dry-run        # 스크린샷만 (Claude.ai 연동 없이)

필요 패키지:
    pip install mss playwright
    playwright install chromium
"""

import json
import time
import argparse
import hashlib
import logging
from datetime import datetime
from pathlib import Path

try:
    import mss
    import mss.tools
except ImportError:
    mss = None
    print("[WARN] mss 미설치 — pip install mss")

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    sync_playwright = None
    print("[WARN] playwright 미설치 — pip install playwright && playwright install chromium")

# ---------------------------------------------------------------------------
# 설정 로드
# ---------------------------------------------------------------------------

CONFIG_PATH = Path(__file__).parent / "cctv-config.json"

def load_config() -> dict:
    """cctv-config.json 로드. 없으면 기본값 반환."""
    if CONFIG_PATH.exists():
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    return {
        "capture": {
            "monitor_number": 1,
            "interval_seconds": 120,
            "screenshot_dir": "D:/5_YOUTUBE/raw/shots"
        },
        "claude_ai": {
            "chrome_user_data": "",
            "url": "https://claude.ai/new",
            "prompt": (
                "이 터미널 스크린샷을 봐. "
                "지금 Claude Code가 무슨 작업을 하고 있는지 한국어로 설명해줘. "
                "IT 비전문가도 이해할 수 있게 쉬운 말로, "
                "기술 용어가 나오면 괄호 안에 쉬운 설명 추가, "
                "3~5문장으로 간결하게."
            ),
            "read_aloud": True,
            "read_aloud_wait_seconds": 30
        },
        "youtube": {
            "channel": "https://www.youtube.com/@technician-parksy",
            "live_enabled": False,
            "live_stream_key": ""
        }
    }

# ---------------------------------------------------------------------------
# 로깅
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [CCTV] %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger("cctv")

# ---------------------------------------------------------------------------
# 스크린샷 캡처
# ---------------------------------------------------------------------------

def capture_screen(monitor_number: int, output_dir: Path) -> Path:
    """지정 모니터의 스크린샷을 캡처하고 파일 경로 반환."""
    if mss is None:
        raise RuntimeError("mss 패키지 필요: pip install mss")

    output_dir.mkdir(parents=True, exist_ok=True)
    filename = output_dir / f"{datetime.now():%Y%m%d_%H%M%S}.png"

    with mss.mss() as sct:
        monitor = sct.monitors[monitor_number]
        screenshot = sct.grab(monitor)
        mss.tools.to_png(screenshot.rgb, screenshot.size, output=str(filename))

    log.info(f"캡처: {filename.name} ({screenshot.size.width}x{screenshot.size.height})")
    return filename


def image_hash(filepath: Path) -> str:
    """이미지 파일의 MD5 해시 (변화 감지용)."""
    return hashlib.md5(filepath.read_bytes()).hexdigest()

# ---------------------------------------------------------------------------
# Claude.ai 브라우저 자동화
# ---------------------------------------------------------------------------

class ClaudeAIController:
    """Playwright로 Claude.ai 브라우저를 제어."""

    def __init__(self, config: dict):
        self.config = config
        self.playwright = None
        self.browser = None
        self.page = None
        self.message_count = 0
        self.max_messages_per_chat = 20  # 대화 길어지면 새로 시작

        # --- DOM 셀렉터 (Claude.ai 업데이트 시 여기만 수정) ---
        # TODO: Windows PC에서 실제 DOM 조사 후 확정
        self.selectors = {
            "file_input": 'input[type="file"]',
            "text_input": '[contenteditable="true"]',
            "send_button": 'button[aria-label="Send Message"]',
            "streaming_indicator": '[data-is-streaming="true"]',
            "read_aloud_button": 'button[aria-label="Read Aloud"]',
        }

    def start(self):
        """Chrome 브라우저를 기존 프로필로 시작."""
        if sync_playwright is None:
            raise RuntimeError("playwright 패키지 필요: pip install playwright")

        self.playwright = sync_playwright().start()

        chrome_user_data = self.config.get("chrome_user_data", "")
        if not chrome_user_data:
            raise ValueError(
                "cctv-config.json의 claude_ai.chrome_user_data를 설정해야 합니다.\n"
                "예: C:/Users/사용자명/AppData/Local/Google/Chrome/User Data"
            )

        self.browser = self.playwright.chromium.launch_persistent_context(
            user_data_dir=chrome_user_data,
            channel="chrome",
            headless=False,  # 화면에 보여야 OBS가 녹화 가능
            args=["--start-maximized"]
        )

        self.page = self.browser.pages[0] if self.browser.pages else self.browser.new_page()
        self._new_chat()
        log.info("Claude.ai 브라우저 시작 완료")

    def _new_chat(self):
        """새 대화 시작."""
        url = self.config.get("url", "https://claude.ai/new")
        self.page.goto(url)
        self.page.wait_for_load_state("networkidle")
        self.message_count = 0
        log.info("새 대화 시작")

    def upload_and_ask(self, screenshot_path: Path, prompt: str):
        """스크린샷 업로드 + 프롬프트 전송 + 응답 대기."""
        # 대화가 너무 길어지면 새로 시작
        if self.message_count >= self.max_messages_per_chat:
            self._new_chat()

        try:
            # 1. 파일 업로드
            file_input = self.page.locator(self.selectors["file_input"])
            file_input.set_input_files(str(screenshot_path))
            log.info("스크린샷 업로드 완료")

            # 2. 프롬프트 입력
            text_input = self.page.locator(self.selectors["text_input"]).last
            text_input.fill(prompt)

            # 3. 전송 (Enter 키)
            self.page.keyboard.press("Enter")
            log.info("프롬프트 전송")

            # 4. 스트리밍 시작 대기
            time.sleep(2)

            # 5. 스트리밍 완료 대기 (최대 2분)
            self.page.wait_for_function(
                """() => {
                    const indicators = document.querySelectorAll('[data-is-streaming="true"]');
                    return indicators.length === 0;
                }""",
                timeout=120000
            )
            log.info("응답 완료")

            self.message_count += 1

        except Exception as e:
            log.error(f"Claude.ai 통신 실패: {e}")
            # 실패 시 새 대화로 복구 시도
            try:
                self._new_chat()
            except Exception:
                pass

    def read_aloud(self, wait_seconds: int = 30):
        """마지막 응답의 읽어주기 버튼 클릭."""
        try:
            btn = self.page.locator(self.selectors["read_aloud_button"]).last
            btn.click()
            log.info(f"읽어주기 시작 (대기 {wait_seconds}초)")
            time.sleep(wait_seconds)
        except Exception as e:
            log.warning(f"읽어주기 실패 (무시): {e}")

    def stop(self):
        """브라우저 종료."""
        if self.browser:
            self.browser.close()
        if self.playwright:
            self.playwright.stop()
        log.info("브라우저 종료")

# ---------------------------------------------------------------------------
# 메인 루프
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="PC CCTV — Claude Code 화면 캡처 + AI 해설")
    parser.add_argument("--interval", type=int, help="캡처 간격 (초)")
    parser.add_argument("--monitor", type=int, help="캡처할 모니터 번호 (1부터)")
    parser.add_argument("--dry-run", action="store_true", help="스크린샷만 (Claude.ai 연동 없이)")
    parser.add_argument("--config", type=str, help="설정 파일 경로")
    args = parser.parse_args()

    # 설정 로드
    if args.config:
        with open(args.config, "r", encoding="utf-8") as f:
            config = json.load(f)
    else:
        config = load_config()

    capture_cfg = config["capture"]
    claude_cfg = config["claude_ai"]

    interval = args.interval or capture_cfg["interval_seconds"]
    monitor = args.monitor or capture_cfg["monitor_number"]
    screenshot_dir = Path(capture_cfg["screenshot_dir"])
    prompt = claude_cfg["prompt"]

    log.info(f"=== PC CCTV 시작 ===")
    log.info(f"모니터: {monitor}, 간격: {interval}초, 저장: {screenshot_dir}")
    log.info(f"YouTube: {config.get('youtube', {}).get('channel', 'N/A')}")

    # Claude.ai 컨트롤러 (dry-run이 아닐 때만)
    controller = None
    if not args.dry_run:
        controller = ClaudeAIController(claude_cfg)
        controller.start()
    else:
        log.info("DRY RUN 모드 — 스크린샷만 저장")

    last_hash = ""

    try:
        while True:
            # 1. 스크린샷 캡처
            shot_path = capture_screen(monitor, screenshot_dir)

            # 2. 변화 감지 — 이전과 동일하면 스킵
            current_hash = image_hash(shot_path)
            if current_hash == last_hash:
                log.info("화면 변화 없음 — 스킵")
                shot_path.unlink()  # 중복 파일 삭제
                time.sleep(interval)
                continue
            last_hash = current_hash

            # 3. Claude.ai에 업로드 + 해설 요청
            if controller:
                controller.upload_and_ask(shot_path, prompt)

                # 4. 읽어주기
                if claude_cfg.get("read_aloud", True):
                    controller.read_aloud(claude_cfg.get("read_aloud_wait_seconds", 30))

            # 5. 다음 주기까지 대기
            log.info(f"다음 캡처까지 {interval}초 대기...")
            time.sleep(interval)

    except KeyboardInterrupt:
        log.info("사용자 중단 (Ctrl+C)")
    finally:
        if controller:
            controller.stop()
        log.info("=== PC CCTV 종료 ===")


if __name__ == "__main__":
    main()
