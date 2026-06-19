# WSL D드라이브 이주 — DeepSeek Aider 실행 명령서

> 이 파일은 Windows DeepSeek Aider가 읽고 실행해야 함.
> Claude Code(WSL)는 실행 못 함. WSL terminate 시 세션 사망.

---

## 미션

C 드라이브(82%)의 WSL ext4.vhdx(148G)를 D 드라이브(1.6T 여유)로 이주.

---

## 실행 조건

- Windows PowerShell(관리자)에서 실행
- WSL 2.6.3 이상 → `wsl --manage --move` 사용 가능 (확인됨)
- MSYS2 Aider가 PowerShell 호출 가능해야 함

---

## 실행 순서

### Step 0 — 사전 확인

```powershell
# C 드라이브 상태
Get-Volume -DriveLetter C | Select Size, SizeRemaining

# WSL 등록 상태
wsl --list -v

# WSL 이미지 현재 위치
(Get-ChildItem Env:LOCALAPPDATA).Value + '\wsl'
```

### Step 1 — WSL 내부 청소 (vhdx 크기 최소화)

```powershell
# WSL 내부 temp 파일 삭제
wsl -d Ubuntu -e bash -c "rm -rf ~/parksy-audio/local-agent/outputs/work/loop_60s/"
wsl -d Ubuntu -e bash -c "rm -rf ~/parksy-audio/local-agent/outputs/work/loop_opt/"
wsl -d Ubuntu -e bash -c "rm -rf ~/parksy-audio/local-agent/outputs/work/bruckner_*/"
wsl -d Ubuntu -e bash -c "rm -rf ~/parksy-audio/xtts-venv/"
wsl -d Ubuntu -e bash -c "pip cache purge && apt-get clean -y && npm cache clean --force"
```

### Step 2 — D 드라이브 대상 폴더 생성

```powershell
New-Item -ItemType Directory -Force -Path D:\WSL
```

### Step 3 — WSL 이주 (핵심, 15~30분 소요)

```powershell
# WSL 종료
wsl --terminate Ubuntu

# 이주 실행
wsl --manage Ubuntu --move D:\WSL

# wsl-min도 이주
wsl --manage wsl-min --move D:\WSL
```

### Step 4 — 검증

```powershell
# WSL 재시작
wsl -d Ubuntu

# C 드라이브 변화 확인
Get-Volume -DriveLetter C | Select Size, SizeRemaining

# WSL 마운트 확인
wsl -d Ubuntu -e df -h /
```

---

## 예상 결과

| 항목 | 이전 | 이후 |
|------|------|------|
| C 드라이브 사용률 | 82% (378GB) | ~50% (230GB) |
| WSL vhdx 위치 | C:\Users\dtsli\... | D:\WSL\Ubuntu\ |
| WSL 동작 | 정상 | 정상 (완전 동일) |

---

## 실패 시 복구

```powershell
# 이주 실패 시 기존 유지됨 (move는 원본 삭제 후 복사)
# 복구: 아무것도 안 해도 됨. WSL 이미지가 C에 그대로 남음

# WSL 재등록이 필요하면:
wsl --register Ubuntu
```
