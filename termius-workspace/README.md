# Termius Workspace

폰/탭에서 Termius SSH 클라이언트로 접속하여 WSL/Windows 인프라를 제어하기 위한 워크스페이스.

## Quick Start

```bash
# 1. 환경 상태 확인
bash healthcheck.sh

# 2. 연결
# Termius에서 아래 세션 프리셋 사용:
#   - WSL Claude:   ssh dtsli@100.81.24.124 -p 2222 → tmux attach
#   - WSL Aider:    ssh dtsli@100.81.24.124 -p 2222 → tmux attach -t phone_aider
#   - Windows Shell: ssh dtsli@100.81.24.124 -p 22

# 3. 위젯에서 자동 기동 안 되면:
#   ssh dtsli@100.81.24.124 -p 22 \
#     "wsl -d Ubuntu -u root -- bash -c 'service ssh start; systemctl start wsl-reverse-tunnel.service'"
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md)

## Files

| File | Purpose |
|------|---------|
| ARCHITECTURE.md | 전체 아키텍처 + 연결맵 |
| healthcheck.sh | 현재 환경 상태 진단 |
| env-snapshot-2026-06-18.json | 환경 스냅샷 (기계판독) |

## Canon Sync

이 워크스페이스의 canon은 WSL `~/dtslib-localpc/termius-workspace/` (<https://github.com/dtslib/dtslib-localpc>).
수정은 반드시 repo에서 → git push → 배포.
