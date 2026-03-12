# PC 퀵스타트 — 집에 가서 이것만 읽어

> 이 문서는 PC에서 Claude Code 세션 시작하면 자동으로 안내되는 인스트럭션.
> 작성: 2026-03-12

---

## 0. 상황 파악

2026-03-12 claude.ai 대화에서 도출된 CLI 통합 전환 솔루션이 코드로 전부 준비됨.
**실행만 하면 됨.**

---

## 1. 원클릭 설치 (38분)

```powershell
# 관리자 PowerShell 열기 (시작 → "PowerShell" 검색 → 관리자로 실행)
cd D:\PARKSY\dtslib-localpc

# 전체 설치 (SSH + CLI + WSL + 검증)
powershell -ExecutionPolicy Bypass -File scripts/setup-all.ps1

# 또는 DryRun으로 먼저 확인
powershell -ExecutionPolicy Bypass -File scripts/setup-all.ps1 -DryRun
```

이게 하는 일:
1. Claude Code CLI 설치 + MCP 3개 연결
2. SSH 서버 활성화 + 방화벽 설정
3. WSL Ubuntu + tmux + Telegram Bot 환경 구성
4. 전체 검증 실행

---

## 2. 설치 후 확인

```powershell
# 검증만 따로 실행
powershell -ExecutionPolicy Bypass -File scripts/verify-infra.ps1
```

80% 이상이면 성공. 실패 항목은 개별 스크립트로 재실행:
```powershell
scripts/setup-cli.ps1     # CLI 관련 문제
scripts/setup-ssh.ps1     # SSH 관련 문제
scripts/setup-wsl.ps1     # WSL 관련 문제
```

---

## 3. 폰에서 접속 테스트

```bash
# 폰 Termux에서
ssh 사용자이름@PC_IP

# 접속되면 성공!
# tmux 시작
bash /mnt/d/PARKSY/dtslib-localpc/scripts/tmux-workspace.sh
```

---

## 4. Telegram Bot (선택)

```bash
# WSL에서
cd ~/telegram-bot
source venv/bin/activate
export BOT_TOKEN="@BotFather에서 받은 토큰"
python bot.py
```

---

## 5. GitHub Issues 등록

```bash
# PC에서 (gh CLI 로그인 상태)
gh issue create --title "Phase 1-3: CLI 통합 인프라 설치 실행" --body "상세: docs/ISSUES.md #1"
gh issue create --title "Telegram Bot 토큰 발급 + 실서비스 테스트" --body "상세: docs/ISSUES.md #2"
gh issue create --title "Termux remote-connect.sh 배포 + 외부 접속" --body "상세: docs/ISSUES.md #3"
gh issue create --title "실환경 테스트 후 점수 채우기" --body "상세: docs/ISSUES.md #4"
```

---

## 6. 작업 순서 요약

```
[1] setup-all.ps1 실행 (38분)
[2] verify-infra.ps1 확인 (5분)
[3] 폰 Termux에서 SSH 접속 (5분)
[4] Telegram Bot 토큰 + 실행 (10분)
[5] GitHub Issues 등록 (2분)
[6] 결과 커밋 + 푸시
```

총 ~60분. 이후 SSH+tmux로 원격 작업 가능.

---

## 참고 문서

| 문서 | 내용 |
|------|------|
| docs/INFRA_WHITEPAPER.md | 전체 백서 (문제 분석 + 솔루션) |
| docs/ISSUES.md | 이슈 목록 + 체크리스트 |
| env/CLI_MIGRATION.md | Desktop→CLI 전환 체크리스트 |
| env/SSH_SETUP.md | SSH 상세 가이드 + 보안 |
| CLAUDE.md 섹션 7.5 | SSH+CLI 아키텍처 요약 |
