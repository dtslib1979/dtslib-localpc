# PC CCTV — 개발 인스트럭션

> **이 문서는 Termux Claude Code가 읽고 개발을 진행하기 위한 완전한 인스트럭션이다.**
> **대화 전문에서 추출한 모든 맥락, 결정, 기술 스펙을 포함한다.**

---

## 1. 프로젝트 개요

### 한 줄 요약
> 집 PC에서 Claude Code가 자율 작업하는 화면을 자동 녹화하고, 다른 LLM이 실시간 해설하는 무인 이원 방송 시스템

### 배경 (왜 만드는가)

박씨는 밖에서(식당 등) 폰으로 원격으로 Claude Code에 작업을 시켜놓는다.
집 PC에서 Claude Code가 혼자 음악 작업(parksy-audio), 만화 작업(parksy-image), 앱 작업(dtslib-apk-lab)을 한다.
그런데:
- Claude Code 터미널에 나오는 내용이 무슨 뜻인지 모를 때가 많다
- IT 용어, 기술적 과정을 이해하고 싶다
- 가끔 스크린샷 찍어서 ChatGPT에 물어보는 걸 수동으로 하고 있다
- 이 과정 자체를 자동화하고, 동시에 YouTube 콘텐츠로 만들고 싶다

### 3가지 목적 (동시 달성)
1. **원격 모니터링** — 밖에서 "지금 내 PC가 뭐 하고 있지?" 확인
2. **YouTube 콘텐츠** — "AI가 AI를 해설하는" 무인 방송 (차별화된 포맷)
3. **개발 이력 보존** — 세션 로그(텍스트)보다 영상이 정보량 압도적

---

## 2. 시스템 아키텍처

### 물리 구성
```
집 PC (Windows, 무인 가동)
├── 화면 1: Claude Code 터미널 (자율 작업 중)
├── 화면 2: Chrome — Claude.ai (자동 해설 중)
├── Python cctv.py: 스크린샷 → Claude.ai 업로드 → 프롬프트 → 해설 (자동)
└── OBS: 두 화면 합성 녹화 (또는 YouTube Live 스트리밍)

박씨: 밖에서 폰으로 YouTube Live 시청 (또는 나중에 VOD)
```

### 데이터 흐름
```
[매 1~2분 루프]
1. Python (mss) → Claude Code 터미널 스크린샷 캡처
2. Python (Playwright) → Chrome의 Claude.ai에 이미지 업로드
3. Python (Playwright) → 해설 프롬프트 자동 입력 + 전송
4. Claude.ai → 한국어 해설 응답
5. Python (Playwright) → "읽어주기" 버튼 클릭 (TTS 재생)
6. OBS → 화면 1 + 화면 2 합성 녹화/스트리밍
7. 1번으로 돌아감
```

### 최종 형태 (YouTube Live)
```
현재 (테스트): OBS 녹화 → 로컬 저장 → 나중에 업로드
목표 (구독자 50명 이후): OBS → YouTube Live → 자동 VOD 아카이브

YouTube Live 장점:
- 저장 강박 해소: YouTube가 보관 (무제한, 무료)
- 용량 강박 해소: 로컬 HDD에 저장 안 함
- 백업 불필요: YouTube 인프라가 관리
- 실시간 모니터링: 폰에서 내 라이브 시청
```

---

## 3. 기술 결정 사항 (확정)

### 왜 Claude.ai in Chrome인가 (ChatGPT Desktop이 아닌 이유)

| 항목 | ChatGPT Desktop + PyAutoGUI | Claude.ai Chrome + Playwright |
|---|---|---|
| 자동화 방식 | 픽셀 좌표 클릭 (불안정) | **DOM 요소 선택 (안정)** |
| UI 변경 시 | 좌표 깨짐 | **셀렉터만 수정** |
| 파일 업로드 | 파일 다이얼로그 조작 (복잡) | **`input[type=file]`에 직접 주입** |
| 응답 대기 | 화면 변화 감지 (불안정) | **DOM 변화 감지 (정확)** |
| 비용 | ChatGPT 무료 | **이미 Max 요금제 결제 중** |
| 로그인 | 별도 처리 필요 | **기존 Chrome 프로필 재사용** |

**결론: Claude.ai + Playwright 확정**

### 왜 OBS인가 (Windows 기본 녹화가 아닌 이유)

처음에는 "Windows 기본(Win+Alt+R)이면 충분"이었다.
그러나 **두 화면을 하나로 합성**해야 하므로 OBS가 필요하다:
- 화면 1 (Claude Code 터미널) + 화면 2 (Claude.ai 해설) 나란히 배치
- 레이아웃 자유 (좌우 분할, PIP, 비율 조절)
- YouTube Live 스트리밍 직접 연결

### 왜 API를 안 쓰는가

- Claude API, GPT-4o Vision API 모두 유료
- 10초마다 호출 시 하루 $10~15
- **Claude.ai Max 요금제를 이미 결제 중** → 브라우저로 무료 사용 가능
- 비용: $0

### 스크린 구성

박씨는 모니터 3개를 사용하지만, 녹화 대상은 2개:
- **모니터 1: Claude Code 터미널** — 이것만 캡처하면 됨 (코드 작업 전부 여기)
- **모니터 2: Chrome Claude.ai** — 해설창 (자동 운영)
- 모니터 3: 기타 — 녹화 불필요 (노이즈)

---

## 4. 핵심 코드 설계

### 4.1 스크린샷 캡처 (mss)

```python
import mss
from datetime import datetime
from pathlib import Path

SCREENSHOT_DIR = Path("D:/5_YOUTUBE/raw/shots")
SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)

def capture_claude_code_screen(monitor_number: int = 1) -> Path:
    """Claude Code가 실행 중인 모니터의 스크린샷 캡처"""
    with mss.mss() as sct:
        monitor = sct.monitors[monitor_number]
        screenshot = sct.grab(monitor)
        filename = SCREENSHOT_DIR / f"{datetime.now():%Y%m%d_%H%M%S}.png"
        mss.tools.to_png(screenshot.rgb, screenshot.size, output=str(filename))
        return filename
```

### 4.2 Claude.ai 브라우저 자동화 (Playwright)

```python
from playwright.sync_api import sync_playwright

def init_browser():
    """이미 로그인된 Chrome 프로필로 Claude.ai 열기"""
    p = sync_playwright().start()
    # Windows Chrome User Data 경로
    browser = p.chromium.launch_persistent_context(
        user_data_dir="C:/Users/{사용자명}/AppData/Local/Google/Chrome/User Data",
        channel="chrome",
        headless=False  # 화면에 보여야 OBS가 녹화 가능
    )
    # Claude.ai 탭으로 이동
    page = browser.pages[0]
    page.goto("https://claude.ai/new")
    page.wait_for_load_state("networkidle")
    return p, browser, page

def upload_and_ask(page, screenshot_path: Path, prompt: str):
    """Claude.ai에 스크린샷 업로드 + 프롬프트 전송"""
    # 파일 업로드 (input[type=file]에 직접 주입)
    file_input = page.locator('input[type="file"]')
    file_input.set_input_files(str(screenshot_path))

    # 프롬프트 입력
    textarea = page.locator('[contenteditable="true"]')
    textarea.fill(prompt)

    # 전송
    page.keyboard.press("Enter")

    # 응답 완료 대기 (스트리밍 종료까지)
    # 셀렉터는 Claude.ai DOM 구조에 맞게 조정 필요
    page.wait_for_selector('[data-is-streaming="false"]', timeout=120000)

def click_read_aloud(page):
    """읽어주기 버튼 클릭"""
    # 마지막 응답의 읽어주기 버튼
    read_aloud_btn = page.locator('button[aria-label="Read aloud"]').last
    read_aloud_btn.click()
```

### 4.3 메인 루프

```python
import time
from pathlib import Path

PROMPT = """이 터미널 스크린샷을 봐.
지금 Claude Code가 무슨 작업을 하고 있는지 한국어로 설명해줘.
- IT 비전문가도 이해할 수 있게 쉬운 말로
- 기술 용어가 나오면 괄호 안에 쉬운 설명 추가
- 3~5문장으로 간결하게
- 이전 스크린샷과 비교해서 진행 상황 변화도 언급해줘"""

INTERVAL_SECONDS = 120  # 2분

def main():
    p, browser, page = init_browser()

    try:
        while True:
            # 1. 스크린샷
            shot = capture_claude_code_screen(monitor_number=1)

            # 2. Claude.ai에 업로드 + 프롬프트
            upload_and_ask(page, shot, PROMPT)

            # 3. 읽어주기
            click_read_aloud(page)

            # 4. 읽어주기 끝날 때까지 대기 (예: 30초)
            time.sleep(30)

            # 5. 다음 주기까지 대기
            time.sleep(INTERVAL_SECONDS)

    except KeyboardInterrupt:
        print("CCTV 종료")
    finally:
        browser.close()
        p.stop()

if __name__ == "__main__":
    main()
```

---

## 5. 설정 파일 (cctv-config.json)

```json
{
  "capture": {
    "monitor_number": 1,
    "interval_seconds": 120,
    "screenshot_dir": "D:/5_YOUTUBE/raw/shots"
  },
  "claude_ai": {
    "chrome_user_data": "C:/Users/{사용자명}/AppData/Local/Google/Chrome/User Data",
    "url": "https://claude.ai/new",
    "prompt": "이 터미널 스크린샷을 봐. 지금 Claude Code가 무슨 작업을 하고 있는지 한국어로 설명해줘. IT 비전문가도 이해할 수 있게 쉬운 말로, 기술 용어가 나오면 괄호 안에 쉬운 설명 추가, 3~5문장으로 간결하게.",
    "read_aloud": true,
    "read_aloud_wait_seconds": 30
  },
  "youtube": {
    "channel": "https://www.youtube.com/@technician-parksy",
    "live_enabled": false,
    "live_stream_key": ""
  },
  "obs": {
    "scene_name": "CCTV",
    "source_1": "Claude Code Terminal (Monitor 1)",
    "source_2": "Chrome Claude.ai (Monitor 2)",
    "layout": "side_by_side",
    "output_dir": "D:/5_YOUTUBE/raw/recordings"
  }
}
```

---

## 6. 필요한 패키지

```
pip install mss playwright
playwright install chromium
```

| 패키지 | 용도 | 비고 |
|---|---|---|
| `mss` | 스크린샷 캡처 | 경량, 빠름 |
| `playwright` | Chrome 브라우저 자동화 | DOM 기반, 안정적 |
| OBS Studio | 화면 합성 녹화/스트리밍 | 별도 설치 |

---

## 7. OBS 설정 가이드

### 씬 구성
```
씬: "CCTV"
├── 소스 1: Window Capture — Claude Code 터미널
│   └── 위치: 좌측 50%
├── 소스 2: Window Capture — Chrome (Claude.ai)
│   └── 위치: 우측 50%
└── (선택) 소스 3: Audio — 데스크탑 오디오 (읽어주기 소리 포함)
```

### YouTube Live 설정 (구독자 50명 이후)
1. OBS → 설정 → 방송 → 서비스: YouTube - RTMPS
2. 스트림 키: YouTube Studio에서 발급
3. 방송 시작 → 자동 아카이브 (VOD)

### 녹화 설정 (현재 단계)
- 출력 → 녹화 경로: `D:\5_YOUTUBE\raw\recordings`
- 녹화 포맷: mp4
- 인코더: NVENC (GPU) 또는 x264
- 해상도: 1920x1080 (두 화면 합치면 충분)

---

## 8. 개발 단계 (Termux Claude Code용)

### Phase 1: 기본 동작 (MVP)
- [ ] `cctv.py` — 스크린샷 캡처 + Claude.ai 자동화 메인 루프
- [ ] `cctv-config.json` — 설정 파일 로드
- [ ] Claude.ai DOM 셀렉터 조사 + 안정화
  - `input[type="file"]` 위치 확인
  - `[contenteditable]` 위치 확인
  - 응답 완료 감지 셀렉터 확인
  - 읽어주기 버튼 셀렉터 확인
- [ ] 에러 핸들링 (Claude.ai 응답 타임아웃, 네트워크 끊김)

### Phase 2: 안정화
- [ ] 화면 변화 감지 — 스크린샷이 이전과 동일하면 API 호출 스킵
- [ ] Claude.ai 대화 길어지면 새 대화 시작 (자동)
- [ ] 로그 저장 (해설 텍스트를 파일로도 기록)
- [ ] 이전 스크린샷과 비교해서 "변화 없음" 감지

### Phase 3: YouTube Live 연동
- [ ] OBS WebSocket 연동 (Python에서 녹화 시작/중지 제어)
- [ ] YouTube Live 자동 시작/종료
- [ ] 라이브 제목 자동 생성 (날짜 + 작업 레포명)

### Phase 4: 후처리 자동화
- [ ] FFmpeg 배속 처리 (4x)
- [ ] 무음 구간 자동 컷
- [ ] 썸네일 자동 생성
- [ ] YouTube 업로드 자동화 (youtube-upload 또는 yt-dlp)

---

## 9. Claude.ai DOM 셀렉터 (조사 필요)

> **중요: Claude.ai의 DOM 구조는 업데이트로 바뀔 수 있다.**
> **Phase 1에서 실제 DOM을 조사하고 이 섹션을 갱신해야 한다.**

조사 대상:
```
1. 파일 업로드 input
   - 예상: input[type="file"] (숨겨진 요소일 수 있음)
   - 대안: 드래그앤드롭 시뮬레이션, 클립보드 paste

2. 텍스트 입력창
   - 예상: [contenteditable="true"] 또는 textarea
   - ProseMirror 에디터일 가능성 있음

3. 전송 버튼
   - 예상: button[aria-label="Send"] 또는 Enter 키

4. 응답 완료 감지
   - 예상: 스트리밍 중 표시 요소의 존재/부재
   - 대안: 일정 시간 동안 DOM 변화 없으면 완료로 판단

5. 읽어주기 버튼
   - 예상: button[aria-label="Read aloud"] 또는 스피커 아이콘
   - 마지막 메시지 블록 내에서 탐색
```

---

## 10. YouTube 채널 정보

| 항목 | 값 |
|---|---|
| 채널 | https://www.youtube.com/@technician-parksy |
| 용도 | PC CCTV 녹화/라이브 업로드 |
| 계정 | dtslib1979 (GitHub 동일) |
| 현재 구독자 | 50명 미만 (라이브 불가) |
| 라이브 목표 | 구독자 50명 달성 후 활성화 |

---

## 11. 저장 전략

```
Phase 1 (현재): OBS 로컬 녹화
  저장: D:\5_YOUTUBE\raw\recordings\
  문제: 용량 누적 → 주기적 정리 필요

Phase 2 (목표): YouTube Live
  저장: YouTube 자동 VOD
  장점: 로컬 저장 0, 용량 무제한, 백업 불필요
  = GitHub 수준의 영구 저장소
```

---

## 12. 콘텐츠 가치 분석

### 왜 이게 먹히는가
- "AI가 AI를 실시간 해설하는" 포맷은 현재 YouTube에 없다
- 대부분의 코딩 영상: 사람이 설명 → 준비 시간 오래 걸림
- 대부분의 타임랩스: 설명 없음 → 뭔지 모름
- **이건 다르다**: 무인 + 실시간 해설 + 준비 시간 0

### 타겟 시청자
- Claude Code 사용자 (실사용 영상 보고 싶은 사람)
- AI 도구에 관심 있지만 비개발자인 사람
- "AI가 진짜로 코딩하는 건 어떤 느낌?" 궁금한 사람

---

## 13. 주의사항

1. **Claude.ai 이용약관**: 브라우저 자동화가 ToS 위반인지 확인 필요
2. **API 키 노출**: 스크린샷에 .env, API 키 등 민감 정보가 찍히지 않도록 주의
3. **Claude.ai DOM 변경**: 업데이트 시 셀렉터 깨질 수 있음 → 셀렉터를 config로 분리
4. **Chrome 프로필 충돌**: Playwright가 Chrome을 열면 기존 Chrome 세션과 충돌 가능
   → 별도 프로필 또는 `--user-data-dir` 분리 고려
5. **OBS + Python 동시 실행**: CPU/메모리 부하 모니터링 필요

---

## 14. 파일 구조

```
dtslib-localpc/
├── cctv/                        ← NEW: PC CCTV 시스템
│   ├── INSTRUCTION.md           ← 이 문서 (개발 인스트럭션)
│   ├── cctv.py                  ← 메인 스크립트 (스크린샷 + Claude.ai 자동화)
│   ├── cctv-config.json         ← 설정 (간격, 프롬프트, 채널, OBS)
│   └── requirements.txt         ← Python 의존성
├── scripts/                     ← 기존 자동화
├── hooks/                       ← 기존 Claude Code 훅
└── ...
```

---

*이 문서를 읽은 Claude는 Phase 1부터 순서대로 개발을 진행한다.*
*Claude.ai DOM 셀렉터는 실제 Windows PC에서 조사해야 하므로, Termux에서는 코드 골격만 작성하고 셀렉터는 placeholder로 남긴다.*
