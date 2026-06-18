# Termius Workspace — Architecture & Connection Map

> Generated: 2026-06-18
> Purpose: Single source of truth for Termius-based remote work environment

---

## 4-Tier Architecture

```
Termius (폰/탭)
  │
  ├── port 22 ──→ Windows (100.81.24.124)
  │                  └── wsl -d Ubuntu ──→ WSL sshd + systemd 서비스 기동
  │
  └── port 2222 ──→ Windows:2222 (리버스 터널)
                       └── WSL sshd:2222 (autossh systemd 서비스)
                            ├── phone_claude (tmux) — Claude Code
                            └── phone_aider (tmux) — DeepSeek Aider
```

---

## Tier Definitions

| Tier | 호스트 | 역할 | 상태관리 | 접속경로 |
|------|--------|------|---------|---------|
| **WSL** (Ubuntu) | 상시 주레인 | Claude Code + Aider + 텔레그램 봇 + watchdog | systemd + wsl-server-init.sh | Termius/WSL2 직접 |
| **Windows** (Native) | 보조 Audit | Windows Claude Code, REAPER, ADB, 파일관리 | Task Scheduler | Termius SSH :22 |
| **폰** (Termux) | 메인 콘솔 | 위젯 실행, ADB, MCP 서버 | Termux:Boot | 로컬 or WSL 경유 |
| **Termius** (SSH) | L3 비상 게이트 | 위 3계층 전부 접속 가능한 유일한 외부 게이트 | N/A (클라이언트) | Tailscale |

---

## Connection Map

### Termius Session Presets

```
1. WSL Claude Code
   Host: 100.81.24.124:2222 → tmux attach -t phone_claude

2. WSL Aider (DeepSeek)
   Host: 100.81.24.124:2222 → tmux attach -t phone_aider

3. WSL Shell (general)
   Host: 100.81.24.124:2222 → bash

4. Windows PowerShell
   Host: 100.81.24.124:22 → powershell.exe

5. Windows Native Claude
   Host: 100.81.24.124:22 → claude (Windows Claude Code)
```

### Key Ports

| Port | Service | Listening On |
|------|---------|-------------|
| 22 | Windows OpenSSH | 0.0.0.0:22 |
| 2222 | WSL SSH (리버스 터널) | Windows 0.0.0.0:2222 → WSL:2222 |
| 8022 | 폰 Termux SSH (Termux) | 폰 Tailscale IP:8022 |

---

## Infrastructure Components

### WSL Services

| Service | Type | Status (2026-06-18) |
|---------|------|---------------------|
| wsl-reverse-tunnel.service | systemd | ✅ active (running) 1d 7h |
| sshd | service | ✅ running |
| tailscaled | systemd | ✅ running |
| tmux: phone_claude | tmux | ✅ attached (claude running) |
| tmux: phone_aider | tmux | ✅ attached |
| tmux: tab_claude | tmux | ✅ running |
| tmux: tab_aider | tmux | ✅ running |
| tg-image (@parksy_bridge_bot) | watchdog | ✅ managed |
| tg-audio (@parksy_bridges_bot) | watchdog | ❌ 1min restart loop |
| watchdog | tmux | ✅ running |

### Windows Services

| Service | PID | Status |
|---------|-----|--------|
| sshd (OpenSSH) | 3196, 14340, 14812, 21168, 22268, 22316, 22400, 22600 | ✅ running |
| claude.exe (this session) | 23484 | ✅ active |

---

## File System Map

### WSL (~/)

```
~/.config/canon/ssh_cmd.txt        — autossh cmdline signature (dedup 기준)
~/.config/deepseek/api_key         — DeepSeek API key
~/.config/widget_master/           — 위젯 스크립트 마스터 사본
  ├── 1.wsl_claude.sh
  └── 2.wsl_aider.sh
~/.shortcuts/                      — WSL 로컬 위젯 스크립트
  ├── 0.rescue.sh
  ├── start_aider.sh
~/.termux/boot/startup.sh          — 폰 부팅 스크립트 (git pull + widget restore)
~/wsl-server-init.sh               — WSL 초기화 (5-Lane + 봇 + watchdog)
~/dtslib-localpc/                   — 로컬 PC 인프라 레포
~/termux-bridge/                    — 폰 브릿지 레포 (위젯 스크립트 canon)
```

### Windows (C:\Users\dtsli\)

```
canon-infra-plan-v6.0.md           — 인프라 리팩토링 계획서
termius-workspace/                  — 이 워크스페이스
canon-policy-win.md                 — Windows 현황 스냅샷
```

### 폰 (~/)

```
~/.shortcuts/                       — Termux Widget 실행 스크립트
  ├── 1.wsl_claude.sh              — Claude Code 위젯
  ├── 2.wsl_aider.sh               — DeepSeek Aider 위젯
  ├── 3-8.*.sh                     — 기타 위젯
  ├── boot_adb.sh                  — ADB 부트
~/.config/widget_master/            — 위젯 마스터 (canon → boot 복원)
  ├── 1.wsl_claude.sh
  └── 2.wsl_aider.sh
~/.termux/boot/startup.sh           — 부팅 스크립트
~/termux-bridge/                    — termux-bridge 레포
```

---

## Sync Flow (Canon → Devices)

```
WSL termux-bridge repo
  → git push → GitHub origin
    → (폰 Termux:Boot) git pull ~/termux-bridge
      → cp → ~/.config/widget_master/
        → (부팅시) cp → ~/.shortcuts/
          → (위젯 탭) 실행
```

**Key constraint**: 단방향만 허용. repo가 유일한 canon. 폰에서 직접 수정 금지.
