# SSH 서버 세팅 가이드

> PC를 서버처럼 원격 제어하기 위한 OpenSSH 설정.
> 폰 Termux에서 SSH로 접속 → PC 터미널 → Claude Code CLI 실행.
> 최종 업데이트: 2026-03-12

---

## 1. Windows OpenSSH 서버 활성화 (5분, PC 앞에서 직접)

### 1-1. OpenSSH 서버 설치

```powershell
# PowerShell (관리자 권한으로 실행)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### 1-2. 서비스 시작 + 자동 시작

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

### 1-3. 방화벽 규칙 추가

```powershell
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' `
  -Enabled True -Direction Inbound -Protocol TCP `
  -Action Allow -LocalPort 22
```

### 1-4. 확인

```powershell
Get-Service sshd
# Status: Running이면 성공
```

---

## 2. 폰 Termux에서 접속 테스트

```bash
# PC의 로컬 IP 확인 (PC에서)
ipconfig
# → WiFi 또는 이더넷의 IPv4 주소 확인 (예: 192.168.0.10)

# 폰 Termux에서 접속
ssh 사용자이름@192.168.0.10

# 접속 성공하면 PC PowerShell 프롬프트 뜸
# Claude Code 실행
claude
```

---

## 3. tmux 설치 + 사용법

> Windows PowerShell에는 tmux가 없음. WSL에서 사용.

### 3-1. WSL Ubuntu에서 tmux 설치

```bash
# WSL 터미널에서
sudo apt update && sudo apt install -y tmux
```

### 3-2. 기본 사용법

```bash
# 새 세션
tmux new -s work

# 세션 분리 (detach) — 세션은 PC에서 계속 실행
Ctrl+b, d

# 세션 목록
tmux ls

# 세션 재접속 (attach) — 끊겼다가 다시 붙기
tmux attach -t work

# 새 창 (같은 세션 내)
Ctrl+b, c

# 창 전환
Ctrl+b, 0~9

# 창 목록
Ctrl+b, w
```

### 3-3. Park 워크플로우 예시

```bash
# SSH 접속 후
tmux new -s work

# 창 0: parksy-audio 작업
cd /mnt/d/PARKSY/parksy-audio && claude

# 새 창 (Ctrl+b, c)
# 창 1: parksy-image 작업
cd /mnt/d/parksy-image && claude

# 새 창 (Ctrl+b, c)
# 창 2: 배치 작업
python /mnt/d/scripts/batch.py

# 세션 분리 후 폰 덮기
Ctrl+b, d

# 나중에 다시 접속
tmux attach -t work
# → 3개 창 모두 그대로 살아있음
```

---

## 4. 보안 강화 (권장)

### 4-1. SSH 키 인증 설정 (비밀번호 대신)

```bash
# 폰 Termux에서 키 생성
ssh-keygen -t ed25519

# 공개키를 PC로 복사
ssh-copy-id 사용자이름@192.168.0.10
```

### 4-2. 비밀번호 인증 비활성화 (선택)

```powershell
# PC에서 C:\ProgramData\ssh\sshd_config 편집
# PasswordAuthentication no
# 변경 후 서비스 재시작
Restart-Service sshd
```

### 4-3. 포트 변경 (선택)

```powershell
# sshd_config에서 Port 22 → Port 2222 등으로 변경
# 방화벽 규칙도 함께 수정
```

---

## 5. 외부 접속 (LTE에서 집 PC)

> LAN 내 SSH는 바로 되지만, 밖에서 접속하려면 추가 설정 필요.

### 옵션 A: Tailscale (추천, 무료)
```bash
# PC와 폰 모두 Tailscale 설치
# 자동으로 VPN 터널 생성
# 폰에서 ssh 사용자이름@100.x.x.x (Tailscale IP)
```

### 옵션 B: 공유기 포트포워딩
```
공유기 관리자 → 포트포워딩 → 외부 22 → PC IP:22
# 보안 위험 있으므로 SSH 키 인증 필수
```

### 옵션 C: Cloudflare Tunnel (무료)
```bash
# cloudflared 설치 후 터널 생성
# 도메인으로 SSH 접속 가능
```

---

## 6. 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| Connection refused | sshd 안 돌아감 | `Start-Service sshd` |
| Permission denied | 비밀번호 틀림 | Windows 사용자 비밀번호 확인 |
| Network unreachable | IP 다름 | `ipconfig`로 IP 재확인 |
| 외부에서 안 됨 | 포트포워딩/VPN 없음 | Tailscale 설치 |
| tmux 없다고 뜸 | PowerShell임 | WSL에서 실행 |

---

*출처: docs/INFRA_WHITEPAPER.md Phase 3-4에서 추출*
*작성: 2026-03-12*
