# 네이버 자동화 — 다음 세션 즉시 실행 인스트럭션

> 작성일: 2026-03-17
> 목적: 세션 재시작 후 컨텍스트 없이도 즉시 작업 가능

---

## 1. 현재 상태 요약

| 항목 | 상태 |
|------|------|
| WSL2 (Ubuntu 24.04) | ✅ 베이스라인 확정 |
| Claude Code (WSL) | ✅ 설치됨 |
| Playwright MCP | ✅ 설정됨 (세션 재시작 후 자동 연결) |
| 네이버 쿠키 | ❌ 아직 미추출 (3계정 전부) |
| Tistory 쿠키 | ❌ 미추출 |
| YouTube OAuth | ⚠️ token.json 있음 (유효성 확인 필요) |

---

## 2. Playwright MCP 확인 (세션 시작 직후)

새 Claude Code 세션 열면 MCP가 자동 연결됨. 툴 목록에 아래가 있어야 정상:
- `browser_navigate`
- `browser_screenshot`
- `browser_click`
- `browser_type`
- `browser_snapshot`

**MCP 설정 위치**: `/home/dtsli/.claude.json` → projects["/home/dtsli"].mcpServers.playwright

```json
{
  "type": "stdio",
  "command": "env",
  "args": ["DISPLAY=:0", "/usr/bin/playwright-mcp", "--browser", "chromium"]
}
```

---

## 3. 왜 Playwright MCP인가 (절대 잊지 말 것)

```
Playwright 스크립트 작성 금지 ← 이게 핵심
browser_navigate 등 MCP tool 직접 호출 = 사람이 Chrome 쓰는 것과 동일
```

- **Playwright headless 스크립트** → 봇 감지됨
- **requests / API 직접** → 네이버가 서버단에서 막음
- **Playwright headed 스크립트** → eccpw 암호화 안 됨 (React 입력 감지 실패)
- **MCP browser tool** → 진짜 Chrome에 Claude 눈 달기 = 봇 감지 원천 차단

---

## 4. 네이버 로그인 작업 — 순서

### 계정 정보
```
credentials: /mnt/d/1_GITHUB/dtslib-papyrus/tools/naver/accounts/credentials.json

parksy_kr → naver ID: parksy-kr
dtslib    → naver ID: dtslib79
eae_kr    → naver ID: eae-kr
PW: (credentials.json 참조)
```

### 쿠키 저장 경로
```
/mnt/d/1_GITHUB/dtslib-papyrus/tools/naver/accounts/cookies/
  parksy_kr.json
  parksy_kr_state.json
  dtslib.json
  dtslib_state.json
  eae_kr.json
  eae_kr_state.json
```

### Claude에게 내릴 지시 (그대로 복붙)

```
Playwright MCP browser tool 직접 써서 네이버 parksy-kr 계정 로그인해라.
스크립트 작성 금지. browser_navigate, browser_type, browser_click 직접 호출.

1. browser_navigate → https://nid.naver.com/nidlogin.login
2. browser_screenshot으로 페이지 확인
3. ID 필드(#id)에 browser_type으로 'parksy-kr' 입력
4. PW 필드(#pw)에 browser_type으로 패스워드 입력
5. 로그인 버튼 클릭
6. browser_screenshot으로 결과 확인
7. 캡차 뜨면 browser_screenshot 찍고 나한테 물어봐라
8. 로그인 성공하면 쿠키를 /mnt/d/1_GITHUB/dtslib-papyrus/tools/naver/accounts/cookies/parksy_kr.json 에 저장
```

### 캡차 처리 방법
- browser_screenshot으로 캡차 이미지 확인
- 이미지 보이면 Claude가 직접 답 입력 가능 (멀티모달)
- 또는 사용자에게 답 물어봄
- 답 입력 후 로그인 재시도

---

## 5. 다음 작업 순서 (네이버 완료 후)

### 5-1. Tistory 로그인 (5계정)
```
accounts: /mnt/d/1_GITHUB/dtslib-papyrus/tools/tistory/accounts.json
5개 Kakao 계정, 21개 블로그
방법: Playwright MCP → Kakao 로그인 → Tistory 쿠키 추출
```

### 5-2. YouTube OAuth 갱신 (4계정)
```
client_secret: /mnt/d/1_GITHUB/dtslib-papyrus/tools/youtube/client_secret.json
기존 token: /mnt/d/PARKSY/parksy-audio/tools/youtube/token.json
방법: Playwright MCP → Google 로그인 → OAuth 토큰 갱신
```

### 5-3. npm run auto 실행
```
위치: /mnt/d/1_GITHUB/dtslib-papyrus/
네이버 + Tistory + YouTube 쿠키 전부 준비된 후 실행
```

---

## 6. 레포지토리 경로 (광역 작업 기준)

| 레포 | 경로 | 역할 |
|------|------|------|
| **papyrus** (본사) | `/mnt/d/1_GITHUB/dtslib-papyrus/` | 자동화 도구, 인스트럭션, 쿠키 |
| **dtslib-localpc** | `/mnt/d/PARKSY/dtslib-localpc/` | PC 환경 설정, 인프라 문서 |
| **parksy-audio** | `/mnt/d/PARKSY/parksy-audio/` | YouTube 업로드 자동화 |
| **parksy-image** | `/mnt/d/PARKSY/parksy-image/` | 이미지 처리 |

### 자주 쓰는 경로
```bash
# 네이버 도구
/mnt/d/1_GITHUB/dtslib-papyrus/tools/naver/

# 쿠키
/mnt/d/1_GITHUB/dtslib-papyrus/tools/naver/accounts/cookies/

# 자격증명
/mnt/d/1_GITHUB/dtslib-papyrus/tools/naver/accounts/credentials.json

# 티스토리
/mnt/d/1_GITHUB/dtslib-papyrus/tools/tistory/

# YouTube
/mnt/d/1_GITHUB/dtslib-papyrus/tools/youtube/
```

---

## 7. WSL 환경 확인 명령

```bash
# X11 디스플레이 확인 (Playwright MCP 필수)
DISPLAY=:0 xset q

# Playwright MCP 바이너리 확인
ls -la /usr/bin/playwright-mcp

# chromium 확인
which chromium-browser

# Claude Code MCP 설정 확인
python3 -c "import json; d=json.load(open('/home/dtsli/.claude.json')); print(json.dumps(d['projects']['/home/dtsli']['mcpServers'], indent=2))"
```

---

## 8. 문제 발생 시

### MCP 툴 안 뜰 때
```bash
# Claude Code 완전 재시작 필요
# 기존 터미널 닫고 새 WSL 터미널에서 claude 실행
claude
```

### Playwright MCP 오류 시
```bash
# 재설치
sudo npm install -g @playwright/mcp

# 설정 재확인
cat /home/dtsli/.claude.json | python3 -m json.tool | grep -A 10 playwright
```

---

## 9. GitHub 토큰

```
dtslib1979 계정: ~/.netrc 또는 git credential 확인
레포: dtslib-papyrus, 기타 28개 레포
토큰은 보안상 문서에 저장 안 함
```

---

## 10. 관련 문서

- `docs/gui-automation-solution.md` (papyrus) — MCP 아키텍처 원칙
- `docs/dev-logs/017-wsl-baseline-mcp-setup-2026-03-17.md` — WSL 베이스라인 확정 기록
- `docs/dev-logs/015-naver-login-cookie-extraction-battle-2026-03-16.md` (papyrus) — 실패 이력 (참고용)
