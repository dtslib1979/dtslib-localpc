# Git Global Config

> 최종 확인: 2026-02-28

## 현재 설정

| 키 | 값 | 비고 |
|----|-----|------|
| user.name | `dimas-40` | GitHub 커밋 표시명 |
| user.email | `thomas.tj.park@gmail.com` | GitHub 커밋 이메일 |
| core.autocrlf | (미설정) | RESTORE.md 권고: `true` |
| init.defaultBranch | (미설정) | RESTORE.md 권고: `main` |

## RESTORE.md 권고값과의 차이

RESTORE.md Phase 0-3에서는 다른 값을 권고:

```bash
git config --global user.name "dtslib1979"
git config --global user.email "dtslib1979@users.noreply.github.com"
git config --global core.autocrlf true
git config --global init.defaultBranch main
```

현재 PC에서는 `dimas-40` / `thomas.tj.park@gmail.com`을 사용 중.
새 PC 복원 시 어떤 값을 쓸지는 사용자가 결정.

## safe.directory (20개)

외장 드라이브(D:)의 레포에 접근하려면 `safe.directory` 등록 필요.
`sync.bat` 실행 시 자동 등록됨.

```
D:/ObsidianV/dtslib
D:/ObsidianV/dtslib/_pc_only/temp_clone
D:/PARKSY/parksy.kr
D:/PARKSY/eae.kr
D:/PARKSY/dtslib.kr
D:/PARKSY/dtslib-apk-lab
D:/PARKSY/buddies.kr
D:/PARKSY/dtslib-cloud-appstore
D:/PARKSY/koosy
D:/PARKSY/parksy-logs
D:/PARKSY/dtslib-branch
D:/PARKSY/phoneparis
D:/PARKSY/papafly
D:/PARKSY/OrbitPrompt
D:/PARKSY/parksy-image
D:/PARKSY/gohsy
D:/PARKSY/mobile-baptism
D:/PARKSY/dtslib-papyrus
```

## SSH 키

현재 없음 (`~/.ssh/*.pub` 미발견). 필요 시:

```bash
ssh-keygen -t ed25519 -C "thomas.tj.park@gmail.com"
# GitHub > Settings > SSH Keys에 등록
```
