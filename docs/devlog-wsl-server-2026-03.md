# 개발일지: WSL Claude Code Server 인프라 구축

> 2026-03-04 | dtslib-localpc 인프라 확장

## 목적

PC(Windows 11)에서 실행되는 Claude Code를 핸드폰(Termux)에서 원격으로 제어.
3개 독립 레인으로 병렬 작업 가능한 서버 인프라 구축.

## 구현 스택

```
Phone (Termux + STT)
  ↓ SSH -p 2222 (Tailscale VPN)
PC WSL2 (Ubuntu 24.04)
  ├── claude-main    → 메인 개발 작업
  ├── tg-image       → 이미지/도면 작업 + Telegram bridge
  ├── tg-audio       → 오디오/음악 작업 + Telegram bridge
  └── watchdog       → 서비스 감시 + 자동복구
```

## 인프라 구성요소

### SSH Server
- Port: 2222
- ClientAliveInterval: 30s
- ClientAliveCountMax: 720 (6시간 유지)
- TCPKeepAlive: yes
- 키 인증 (ed25519)

### tmux 4-Session Parallel Architecture

| Session | Window 0 | Window 1 | Purpose |
|---------|----------|----------|---------|
| claude-main | work | — | 메인 Claude Code |
| tg-image | bridge (image_downloader) | work (claude) | 이미지 채널 |
| tg-audio | bridge (audio_bridge) | work (claude) | 오디오 채널 |
| watchdog | monitor (60s loop) | — | 서비스 감시 |

### Telegram Bridge 이중화

| Bot | Direction | 용도 |
|-----|-----------|------|
| @parksy_bridge_bot | Phone → PC | 이미지, MIDI 파일 수신 |
| @parksy_bridges_bot | PC → Phone | 오디오, 비디오 파일 전송 |

- 절대 혼용 금지 (각 봇 전용 용도)
- WSL config: `/mnt/d/` 경로 사용 (Windows `D:/` 아님)

### Termux 원터치 스크립트

```bash
pc          # SSH → tmux attach claude-main
pc-image    # SSH → tmux attach tg-image
pc-audio    # SSH → tmux attach tg-audio
```

- 안드로이드 키보드 마이크 버튼 = STT 음성입력
- 타이핑 없이 AI 에이전트에게 음성으로 작업 지시

### Boot Auto-Start

```
Windows 시작프로그램/wsl-autostart.vbs
  → wsl -d Ubuntu -u dtsli bash /home/dtsli/wsl-server-init.sh
    → SSH 시작
    → Tailscale 시작
    → 4 tmux 세션 생성
    → 2 Telegram 브릿지 시작
    → Watchdog 시작
```

### Watchdog
- 60초 간격 무한루프
- 감시 대상: sshd, image_downloader.py, audio_bridge.py
- 프로세스 죽으면 자동 재시작

## 네트워크

| 접속 방식 | 주소 | 사용 환경 |
|-----------|------|----------|
| 같은 WiFi | WSL IP:2222 | 집/사무실 |
| 외부 5G/LTE | Tailscale IP:2222 | 외부 어디서든 |

## 파일 경로 매핑

| Windows | WSL | 용도 |
|---------|-----|------|
| D:\parksy-image\00_inbox\ | /mnt/d/parksy-image/00_inbox/ | 이미지 수신 |
| D:\PARKSY\parksy-audio\local-agent\sources\ | /mnt/d/PARKSY/parksy-audio/local-agent/sources/ | MIDI 수신 |
| D:\tmp\ | /mnt/d/tmp/ | 작업 임시 폴더 |

## 해결한 문제

1. WSL 경로 호환: Windows `D:/` → `/mnt/d/` config 분리
2. NVM PATH: 비대화형 셸에서 node 못 찾음 → .bashrc 최상단 설정
3. SSH keepalive: 모바일 끊김 방지 (6시간 유지)
4. 채널 독립성: 이미지/오디오 tmux 세션 완전 분리
5. Bash PATH 깨짐: Windows `Program Files (x86)` 괄호 → 별도 PATH 구성

## 3-Lane 병렬 워크플로우

```
┌─ Lane 1: pc ──────────────┐
│  일반 개발, 코딩, 시스템   │
│  Claude Code 메인 인스턴스 │
└───────────────────────────┘

┌─ Lane 2: pc-image ────────┐
│  parksy-image 프로젝트     │
│  건축도면, CAD, 이미지     │
│  + Telegram 이미지 브릿지  │
└───────────────────────────┘

┌─ Lane 3: pc-audio ────────┐
│  parksy-audio 프로젝트     │
│  클래식 음악 MIDI→MP4      │
│  + Telegram 오디오 브릿지  │
└───────────────────────────┘
```

각 레인은 독립 tmux 세션 + 독립 Claude Code 인스턴스.
핸드폰에서 Termux 세션 3개 열어 동시 병렬 작업 가능.

## 검증 결과

- final_verify.py 전항목 통과
- 4 tmux 세션 정상
- 2 Telegram 봇 API 연결 확인
- SSH + watchdog 동작 확인
- 부팅 자동시작 확인
- Claude Code CLI 정상

## 연관 레포

- [dtslib-papyrus](https://github.com/dtslib1979/dtslib-papyrus) — 전체 프로젝트 관리
- [dtslib-localpc](https://github.com/dtslib1979/dtslib-localpc) — PC 로컬 인프라

## Status: OPERATIONAL

Tailscale VPN 로그인 완료 후 외부 5G 접속까지 풀 운용 예정.
