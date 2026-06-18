# Infra Plan v6.0 — 실계통 대조 평가

> 평가일: 2026-06-18 / 평가자: Claude Code (Windows CC)

---

## ✅ 검증 통과

| Plan 주장 | 실계통 확인 | 근거 |
|-----------|-----------|------|
| `~/.config/deepseek/api_key` | ✅ 존재 (36 bytes) | WSL 파일 직접 확인 |
| `~/.config/canon/ssh_cmd.txt` | ✅ 존재, systemd autossh cmdline과 일치 | `/proc/1176/cmdline` 대조 |
| Termux:Boot 설치 | ✅ `package:com.termux.boot` | 폰 `pm list packages` |
| T6 md5 3곳 일치 | ✅ 완료 (2026-06-18) | `t6_verified.txt` 확인 |
| 폰 `widget_master` 존재 | ✅ `~/.config/widget_master/`에 2개 파일 | SSH 직접 확인 |
| 폰 부팅 스크립트 배포 | ✅ `~/.termux/boot/startup.sh` 존재 | SSH 직접 확인 |

---

## ❌ 오류/불일치

### 1. repo 경로 오류: `widgets/phone/widget_master/` → `widgets/phone/`

```
Plan:   cp ~/termux-bridge/widgets/phone/widget_master/* ~/.config/widget_master/
Actual: repo 내 widget 파일은 widgets/phone/ 에 직접 위치
```

**수정**: `widget_master` 서브디렉토리가 repo에 없음. `cp` 대상 경로를 `widgets/phone/*`로 정정해야 함.
혹은 repo에 `widgets/phone/widget_master/` 디렉토리를 만들어 파일을 그쪽으로 이관해야 함.

### 2. `startup.sh` `git pull` 충돌 처리 없음

```bash
cd ~/termux-bridge 2>/dev/null && git pull --quiet
```

폰에서 `~/termux-bridge`에 local modification이 있으면 pull 실패.
필요: `git stash` → `git pull` → `git stash pop` 또는 `git reset --hard @{u}`

### 3. `recover.sh` vs systemd 중복 구조

plan의 `dedup_autossh`는 systemd 서비스의 autossh PID를 kill 하면 systemd가 즉시 재기동.
race condition: `for p in $(pgrep -f "autossh.*2222"); do [ "$p" != "$keep" ] && kill -9 "$p"; done`
→ systemd 서비스가 재기동한 새 PID가 `for` loop 이후에 살아남아 중복 발생 가능

**해결방안**: 
- (A) dedup_autossh를 recover.sh에서 제거하고 systemd에 위임
- (B) systemd 서비스의 `ExecStartPre`로 dedup 로직 포함

### 4. Plan에 `recover.sh`와 `wsl-server-init.sh` 관계 명시 부재

현재 `wsl-server-init.sh`는 `wsl.conf` `command=`로 부팅 시 실행.
plan의 `recover.sh`는 기존 init script를 완전 대체? 섹션으로 포함? 미정의.

---

## ⚠️ Plan 미포함 항목 (누락)

### A. 오디오 봇 60초 재시작 루프 (운영중단급)

`server.log`:
```
[18:19:13] audio bot restarted
[18:20:13] audio bot restarted
... (60s 간격 24시간 이상 지속)
```

watchdog이 `pgrep -f "local-agent/bot.py"`로 체크하지만 봇이 실행 즉시 종료됨.
원인 미파악 (Python import 실패? 경로 문제? 봇 자체 crash?).

### B. 이미지 봇(tg-image) 프로세스 미실행

`BOT_COUNT=1` (image bot도 안 돌고 있음).

### C. WSL `~/.shortcuts/` vs 폰 `~/.shortcuts/` 미분리

WSL의 `~/.shortcuts/`에는 `start_aider.sh`, `0.rescue.sh`만 있고
`1.wsl_claude.sh`, `2.wsl_aider.sh`는 없음.
위젯 스크립트는 폰 전용이므로 WSL의 `~/.shortcuts/`는 다른 용도 — 문서화 필요.

### D. `startup.sh`에 `sshd`만 있고 `termux-wake-lock` 없음

현재 폰의 `~/.termux/boot/startup.sh`에는 `termux-wake-lock` + `sshd` + `tmux` + `widget restore`가 있음.
plan의 startup.sh는 `sshd`만 있음 — wake-lock 누락 시 Doze 모드에서 SSH 연결 불안정.

---

## 종합 평가

| 항목 | 판정 |
|------|------|
| 논리 구조 (4-tier, 단방향 동기화) | ✅ 타당 |
| 경로 정확성 | ❌ 1건 오류 (widgets/phone/widget_master/) |
| 시스템 경합 고려 | ❌ dedup_autossh vs systemd race |
| 에러 처리 | ❌ git pull 충돌, wait_net 타임아웃 |
| 운영 현황 반영 | ❌ bot restart loop 미포함 |
| 폰 부팅 스크립트 일치성 | ❌ wake-lock 누락 |

**수정 권장**: 상기 4건 오류/누락 수정 후 v6.1 배포.
**T6 완료 조건**: 오디오 봇 루프 해결 + repo 경로 정정 + recover.sh 배포 전 systemd 통합 검증.
