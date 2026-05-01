# 스토리지 아키텍처 확정

> 2026-04-11 확정

## 드라이브 역할 분리

| 드라이브 | 기기 | 타입 | 역할 |
|----------|------|------|------|
| C: (내장) | PC | NVMe SSD | Windows OS + 활성 작업 |
| T7 (외장) | Samsung T7 포터블 SSD | USB 3.2 Gen 2 SSD | **WSL vhdx** + 연산 작업 |
| D: (외장) | WD Passport 1.9TB | USB 3.0 HDD | **데이터 창고** — samples/backups 대용량 순차 파일만 |

## 원칙

- **T7 = WSL + 연산**: 랜덤 I/O ~500 MB/s, Python/git/pip 전부 여기서
- **WD = 데이터 창고**: 랜덤 I/O 2~3 MB/s (HDD 한계), 순차 읽기 파일만
  - `/mnt/d/wsl_migrate/parksy-audio-samples` (17G, symlink)
  - `/mnt/d/wsl_migrate/backups` (3G, symlink)
  - `/mnt/d/wsl_migrate/uploads` (3G, symlink)
- **WD에 절대 올리면 안 되는 것**: WSL vhdx, Python venv, git repos, 빌드 캐시

## WSL vhdx T7 이전 절차

> T7 PC에 연결 후 PowerShell 관리자 권한으로 실행

```powershell
# 1. WSL 완전 종료
wsl --shutdown

# 2. export (30~60분, 현재 vhdx ~100G 예상)
wsl --export Ubuntu E:\wsl_backup.tar

# 3. 기존 등록 해제
wsl --unregister Ubuntu

# 4. T7에 import (E: = T7 드라이브 레터, 실제 확인 필요)
mkdir E:\wsl
wsl --import Ubuntu E:\wsl E:\wsl_backup.tar --version 2

# 5. 기본 유저 복원
ubuntu config --default-user dtsli
```

> export/import 완료 후 `wsl_backup.tar` 삭제해서 T7 공간 회수

## 현재 C드라이브 상태 (2026-04-11 정리 후)

- 419G → 403G (16G 회수)
- WSL vhdx: `AppData/Local/wsl/` 185G → T7 이전 예정
- T7 이전 완료 시 C드라이브 ~220G 예상 (약 50% 사용)
