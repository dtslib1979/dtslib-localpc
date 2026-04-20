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

### Tailscale VPN (외부 접속)
- IP: 100.90.83.128
- DERP: tok (Tokyo)
- 인증: GitHub (dtslib1979)
- 외부 5G/LTE에서 Tailscale IP:2222로 SSH 접속
- watchdog에서 자동 감시/재시작

### tmux 4-Session Parallel Architecture

| Session | Window 0 | Window 1 | Purpose |
|---------|----------|----------|---------|
| claude-main | work | — | 메인 Claude Code |
| tg-image | bridge (image_downloader) | work (claude) | 이미지 채널 |
| tg-audio | bridge (audio_bridge v2) | work (claude) | 오디오 채널 |
| watchdog | monitor (watchdog.sh) | — | 서비스 감시 |

### Telegram Bridge 이중화

| Bot | Direction | 용도 |
|-----|-----------|------|
| @parksy_bridge_bot | Phone → PC | 이미지, MIDI 파일 수신 |
| @parksy_bridges_bot | Phone ↔ PC (양방향) | 오디오/비디오/MIDI 수신 + 전송 |

- 절대 혼용 금지 (각 봇 전용 용도)
- WSL config: `/mnt/d/` 경로 사용 (Windows `D:/` 아님)
- 오디오 봇 v2: 양방향 지원 (수신: audio_inbox/, MIDI: sources/)

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
    → D: 드라이브 마운트
    → SSH 시작
    → Tailscale 시작
    → 4 tmux 세션 생성
    → 2 Telegram 브릿지 시작
    → Watchdog 시작 (watchdog.sh)
```

### Watchdog (watchdog.sh)
- 60초 간격 무한루프
- 감시 대상: sshd, image_downloader.py, audio_bridge.py, tailscaled
- 프로세스 죽으면 자동 재시작
- 별도 스크립트 파일로 관리 (/home/dtsli/dtslib-localpc/telegram-bots/watchdog.sh)

## 네트워크

| 접속 방식 | 주소 | 사용 환경 |
|-----------|------|-----------|
| 같은 WiFi | WSL IP:2222 | 집/사무실 |
| 외부 5G/LTE | 100.90.83.128:2222 | 외부 어디서든 |

## 파일 경로 매핑

| Windows | WSL | 용도 |
|---------|-----|------|
| D:\parksy-image\00_inbox\ | /mnt/d/parksy-image/00_inbox/ | 이미지 수신 |
| D:\PARKSY\parksy-audio\local-agent\sources\ | /mnt/d/PARKSY/parksy-audio/local-agent/sources/ | MIDI 수신 |
| D:\tmp\audio_inbox\ | /mnt/d/tmp/audio_inbox/ | 오디오/비디오 수신 |
| D:\tmp\ | /mnt/d/tmp/ | 작업 임시 폴더 |

## 해결한 문제

1. WSL 경로 호환: Windows `D:/` → `/mnt/d/` config 분리
2. NVM PATH: 비대화형 셸에서 node 못 찾음 → .bashrc 최상단 설정
3. SSH keepalive: 모바일 끊김 방지 (6시간 유지)
4. 채널 독립성: 이미지/오디오 tmux 세션 완전 분리
5. Bash PATH 깨짐: Windows `Program Files (x86)` 괄호 → 별도 PATH 구성
6. D: 드라이브 자동마운트: 재부팅 시 /mnt/d 미마운트 → init 스크립트에 mount 추가
7. 오디오 봇 단방향 → 양방향: v2로 업그레이드 (수신+전송 동시)
8. Tailscale VPN: 외부 5G 접속 구성 완료 (Tokyo DERP)

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

- 4 tmux 세션 정상 (재부팅 후 자동시작 확인)
- 2 Telegram 봇 API 연결 확인
- 이미지 브릿지: 핸드폰 → PC 사진 2장 수신 성공
- 오디오 브릿지 v2: 핸드폰 → PC MIDI 3개 수신 성공
- 오디오 브릿지 v2: PC → 핸드폰 테스트 메시지 전송 성공
- SSH + watchdog 동작 확인
- Tailscale VPN 접속 확인 (100.90.83.128, DERP tok)
- Claude Code CLI 정상
- 부팅 자동시작 확인

## 연관 레포

- [dtslib-papyrus](https://github.com/dtslib1979/dtslib-papyrus) — 전체 프로젝트 관리
- [dtslib-localpc](https://github.com/dtslib1979/dtslib-localpc) — PC 로컬 인프라

## Status: FULLY OPERATIONAL

Tailscale VPN 완료. 외부 5G/LTE 접속 가능.
오디오 봇 양방향 업그레이드 완료.
Watchdog에 Tailscale 감시 추가 완료.
