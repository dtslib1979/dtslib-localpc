# Open Issues — PC에서 실행할 작업 목록

> 집에 가서 이 파일을 보고 순서대로 실행.
> GitHub Issues로 등록하려면: `gh issue create --title "제목" --body-file issue.md`
> 작성: 2026-03-12

---

## Issue #1: Phase 1-3 CLI 통합 인프라 설치 실행

**우선순위: 최상 (먼저 이것부터)**

### 실행 (관리자 PowerShell)
```powershell
cd D:\PARKSY\dtslib-localpc
powershell -ExecutionPolicy Bypass -File scripts/setup-all.ps1
```

### 체크리스트
- [ ] Phase 1: Claude Code CLI 설치 (`setup-cli.ps1`)
- [ ] Phase 2: SSH 서버 설정 (`setup-ssh.ps1`)
- [ ] Phase 3: WSL + tmux + Telegram Bot (`setup-wsl.ps1`)
- [ ] Phase 4: 검증 통과 (`verify-infra.ps1` — 80%+)
- [ ] Phase 5: 폰 Termux에서 SSH 접속 테스트
- [ ] Phase 6: tmux 워크스페이스 실행 확인

### 완료 조건
- `verify-infra.ps1` 80% 이상
- 폰에서 `ssh user@PC_IP` 접속 성공
- tmux 세션 생성 + detach + reattach 동작 확인

---

## Issue #2: Telegram Bot 토큰 발급 + 실서비스 테스트

**우선순위: 높음 (Issue #1 완료 후)**

### 실행 순서
1. Telegram에서 @BotFather에게 `/newbot`
2. 토큰 받기
3. WSL에서:
```bash
cd ~/telegram-bot
source venv/bin/activate
export BOT_TOKEN="발급받은토큰"
python bot.py
```
4. 봇에게 `/start` 보내서 chat_id 확인
5. `config.json`에 `allowed_chat_ids` 추가 (보안)

### 테스트 체크리스트
- [ ] Bot 토큰 발급
- [ ] `/start` 응답 확인
- [ ] `/status` — PC 상태 확인
- [ ] `/ls /mnt/d` — D: 드라이브 파일 목록
- [ ] `/get /mnt/d/path/file` — PC→폰 파일 전송
- [ ] 폰에서 파일 보내기 → PC 저장 확인
- [ ] `/disk` — 디스크 사용량

---

## Issue #3: Termux remote-connect.sh 배포 + 외부 접속

**우선순위: 높음 (Issue #1 완료 후)**

### Termux 배포
```bash
# Termux에서
git pull origin main  # 또는 clone
cp scripts/remote-connect.sh ~/bin/pc
chmod +x ~/bin/pc
pc setup
```

### 테스트 체크리스트
- [ ] `pc setup` — PC IP/사용자 설정
- [ ] `pc raw` — SSH 직접 접속
- [ ] `pc` — tmux 워크스페이스 자동 시작
- [ ] `pc audio` — audio 프리셋
- [ ] SSH 끊고 재접속 → tmux attach 세션 유지 확인

### 외부 접속 (LTE에서)
- [ ] Tailscale 설치 (PC + 폰)
- [ ] Tailscale IP로 SSH 접속 테스트
- [ ] `~/.pc-remote.conf`에 Tailscale IP 설정

---

## Issue #4: 실환경 테스트 후 점수 채우기

**우선순위: 중 (전체 실행 후)**

### 비개발자 점수 (92→95+)
- [ ] setup-all.ps1 실행 중 막힌 부분 기록
- [ ] "여기서 막혔다 → 이렇게 풀었다" 트러블슈팅 추가
- [ ] docs/logs/ 에 실행 과정 대화 로그 저장

### 개발자 점수 (78→85+)
- [ ] verify-infra.ps1 실행 결과 커밋 (`snapshots/infra-verify.json`)
- [ ] setup-ssh.ps1 Windows 실행 확인 + 버그 수정
- [ ] setup-wsl.ps1 WSL 실행 확인 + 버그 수정
- [ ] telegram-bot.py 실행 확인 + 에러 핸들링 보강
- [ ] tmux-workspace.sh WSL 경로 실동작 확인

### 문서 업데이트
- [ ] env/CLI_MIGRATION.md 체크리스트 실행 결과로 업데이트
- [ ] docs/VISION.md 축 6 상태를 "구현 완료"로 변경
- [ ] CLAUDE.md 섹션 7.5 Phase 상태 업데이트

---

## GitHub Issues 일괄 등록 (PC에서 gh CLI로)

```bash
# PC에서 gh CLI가 있으면 한 번에 등록:
gh issue create --title "Phase 1-3: CLI 통합 인프라 설치 실행" --body "setup-all.ps1 실행. 상세: docs/ISSUES.md #1"
gh issue create --title "Telegram Bot 토큰 발급 + 실서비스 테스트" --body "telegram-bot.py 실행. 상세: docs/ISSUES.md #2"
gh issue create --title "Termux remote-connect.sh 배포 + 외부 접속" --body "remote-connect.sh 배포. 상세: docs/ISSUES.md #3"
gh issue create --title "실환경 테스트 후 점수 채우기" --body "92/78 → 95/85 목표. 상세: docs/ISSUES.md #4"
```
