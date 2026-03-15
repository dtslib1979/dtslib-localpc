# 작업일지: 텔레그램 Claude 봇 시스템 디버깅

> 2026-03-08 | 이전 세션 이어서 작업 (세션 2회 — 컨텍스트 소진으로 전환)

## 목적

이전 세션(03-07~08)에서 구축한 텔레그램 원격 자동화 시스템의 **실제 작동 테스트 및 디버깅**.
핸드폰에서 텔레그램 메시지 → WSL Claude Code CLI 실행 → 응답 반환 파이프라인 검증.

## 이전 세션 성과물 (세션 1)

이전 세션에서 다음이 완성됨:

| 항목 | 상태 | 파일 |
|------|------|------|
| telegram_claude_bot.py | ✅ 배포 완료 | /home/dtsli/telegram-bridges/ |
| Claude 이미지 봇 config | ✅ 생성 | claude_image_config.json |
| Claude 오디오 봇 config | ✅ 생성 | claude_audio_config.json |
| REMOTE_WORK_MANUAL.md | ✅ 작성 | D:\PARKSY\parksy-audio\docs\ |
| 2개 Claude 봇 프로세스 | ✅ 실행 중 | PID 1242, 1244 |

### 신규 텔레그램 봇 구조

| 봇 | 용도 | 동작 |
|----|------|------|
| @parksy_bridge_bot | 이미지 파일 전송 (기존) | Phone → PC 파일 수신 |
| @parksy_bridges_bot | 오디오 파일 전송 (기존) | Phone ↔ PC 양방향 |
| @Parksy_Image_Claude_bot | **이미지 프로젝트 AI 제어** (신규) | 메시지 → Claude CLI → 응답 |
| @Parksy_Audio_Claude_bot | **오디오 프로젝트 AI 제어** (신규) | 메시지 → Claude CLI → 응답 |

## 금일 세션 (세션 2) — 디버깅 작업

### ✅ 완료된 검증 항목

#### 1. WSL 인프라 상태 점검
- tmux 4세션 정상: claude-main, tg-image, tg-audio, watchdog
- Python 프로세스 4개 정상 실행 (PID 1241~1244)
- Tailscale VPN 동작 중

#### 2. Telegram API 통신 테스트
- 이미지 Claude 봇 (`getMe`) → ✅ 응답 정상
- 오디오 Claude 봇 (`getMe`) → ✅ 응답 정상
- 이미지 Claude 봇 (`sendMessage`) → ✅ msg_id:6 전송 성공
- 오디오 Claude 봇 (`sendMessage`) → ✅ msg_id:6 전송 성공

#### 3. watchdog.sh 버그 수정
**증상**: watchdog가 tailscaled를 60초마다 재시작하는 무한루프
**원인**: `sudo bash -c "nohup tailscaled ... > /tmp/tailscaled.log"` → Permission denied
**수정**:
```bash
# Before (broken)
sudo bash -c "nohup tailscaled --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscaled.log 2>&1 &"

# After (fixed)
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock > /dev/null 2>&1 &
```
watchdog 재시작 후 안정적 동작 확인 (PID 2570).

### ❌ 미해결: WSL Claude Code CLI 인증

#### 문제
```
$ claude -p 'echo hello' --dangerously-skip-permissions --output-format text
→ 401 Unauthorized: OAuth token has expired
```
`~/.claude/.credentials.json` 토큰 만료 (2025-09-10 발급).

#### 시도한 방법과 실패 원인

| # | 방법 | 실패 원인 |
|---|------|-----------|
| 1 | tmux에서 `claude` TUI → `/login` → 코드 입력 | TUI raw mode에서 tmux send-keys 입력 불안정 |
| 2 | code#state 전체 입력 | `#` 이후 state 부분이 불필요했을 가능성 |
| 3 | code만 입력 (# 앞부분) | 이미 1회용 코드 소진/만료 |
| 4 | `claude auth login` 직접 실행 + 브라우저 인증 | 코드 발급 → tmux 입력 시 TUI stdin 문제 |
| 5 | FIFO named pipe로 stdin 연결 | `claude auth login`이 TTY 필수 — pipe 거부 |
| 6 | Chrome MCP로 OAuth 페이지 자동 승인 + 코드 획득 | 코드는 성공적으로 획득했으나 tmux 입력 전달 실패 |

#### 근본 원인 분석

```
claude auth login 실행
  → OAuth URL 출력 (브라우저 필요)
  → WSL에 브라우저 없음
  → 수동으로 Windows 브라우저에서 인증
  → platform.claude.com에서 code#state 표시
  → CLI에 코드 입력 필요
  → BUT: CLI가 TUI raw terminal mode로 stdin 읽음
  → tmux send-keys로는 정상 전달 불가
```

**핵심**: WSL은 headless 환경인데, `claude auth login`은 interactive browser + TTY를 요구함.

#### 찾은 해결책

커뮤니티 검색 결과 ([참고](https://gist.github.com/coenjacobs/d37adc34149d8c30034cd1f20a89cce9)):

```bash
# 1. Windows에서 (브라우저 있는 환경) 1년짜리 장기 토큰 발급
claude setup-token

# 2. WSL 환경변수에 설정
export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."

# 3. ~/.bashrc에 영구 등록
echo 'export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."' >> ~/.bashrc
```

**미실행 이유**: 현재 Claude Code 세션 내부에서 `claude setup-token` 실행 시 nested session 에러 발생. 사용자가 별도 터미널에서 수동 실행 필요.

## 현재 시스템 상태

| 컴포넌트 | 상태 | 비고 |
|----------|------|------|
| tmux 4세션 | ✅ 정상 | claude-main, tg-image, tg-audio, watchdog |
| SSH (port 2222) | ✅ 정상 | keepalive 6hr |
| Tailscale VPN | ✅ 정상 | 100.90.83.128 |
| watchdog.sh | ✅ 수정 완료 | tailscale 루프 버그 해결 |
| 이미지 브릿지 (image_downloader.py) | ✅ 실행 중 | @parksy_bridge_bot |
| 오디오 브릿지 (audio_bridge.py) | ✅ 실행 중 | @parksy_bridges_bot |
| Claude 이미지 봇 (telegram_claude_bot.py) | ✅ 정상 | 2026-03-16 인증 갱신 완료, E2E 테스트 통과 |
| Claude 오디오 봇 (telegram_claude_bot.py) | ✅ 정상 | 2026-03-16 인증 갱신 완료 |
| WSL Claude Code CLI | ✅ 정상 | Windows credentials.json 복사 방식으로 해결 |

## ✅ 완료된 작업 (2026-03-16)

1. **[완료] Claude Code CLI 인증 갱신**
   - Windows `~/.claude/.credentials.json` → WSL 복사
   - refreshToken 포함으로 자동 갱신 가능
   - `claude -p 'echo hello'` 동작 확인 ✅

2. **[완료] 엔드투엔드 테스트**
   - ClaudeRunner 직접 호출 테스트 통과 (30.8초, 텔레그램 전송 확인)
   - 긴 응답(>10000자) 파일 첨부 전송 경로 검증
   - work_dir(/mnt/d/parksy-image) 내 Claude 실행 확인

3. **[완료] 시스템 안정화**
   - watchdog.sh에 `refresh_claude_creds()` 추가
   - 매 60초 만료 1시간 미만 시 Windows credentials 자동 동기화
   - server.log에 sync 이벤트 기록

## 연관 파일

| 파일 | 위치 |
|------|------|
| telegram_claude_bot.py | /home/dtsli/telegram-bridges/ |
| watchdog.sh (수정됨) | /home/dtsli/telegram-bridges/ |
| claude_image_config.json | /home/dtsli/telegram-bridges/ |
| claude_audio_config.json | /home/dtsli/telegram-bridges/ |
| REMOTE_WORK_MANUAL.md | D:\PARKSY\parksy-audio\docs\ |
| devlog-wsl-server-2026-03.md | dtslib-localpc/docs/ (이전 인프라 구축 로그) |

## 교훈

- WSL headless 환경에서 OAuth 인증은 `setup-token` 방식이 정석
- `claude auth login`의 TUI raw mode는 tmux send-keys와 호환 안 됨
- 1회용 OAuth 코드는 수초 내 만료되므로 자동화 파이프라인 필수
- watchdog의 로그 리다이렉트는 권한 문제 발생 가능 → `/dev/null` 권장
