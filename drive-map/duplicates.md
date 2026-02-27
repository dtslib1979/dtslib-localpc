# 중복 클론 정리 기록

> 정리 완료: 2026-02-28

## 정리 결과

### 삭제 완료

| 경로 | 상태 | 조치 |
|------|------|------|
| `D:\parksy-audio` | divergent commit `3b50d25` 발견 | canonical에 cherry-pick 후 삭제 |
| `D:\1_GITHUB\parksy-audio` | 빈 레포 (git init만) | 즉시 삭제 |
| `D:\parksy-image-fresh` | behind canonical + untracked 4파일 | 파일 구출 후 삭제 |
| `D:\1_GITHUB\parksy-image` | canonical과 HEAD 동일 | 즉시 삭제 |

### 구출된 작업물

**D:\parksy-audio → D:\PARKSY\parksy-audio:**
- commit `3b50d25` (원클릭 풀 파이프라인 v2, 10개 모듈) cherry-pick
- dirty files: `full_pipeline.py`, `humanize_preset.py`
- untracked: `session-logs/` (3건)

**D:\parksy-image-fresh → D:\parksy-image:**
- `scripts/telegram/__init__.py`, `bot.py`, `config.py`
- `start_bot.bat`

### 미정리 (별도 확인 필요)

| 경로 | 상태 | 비고 |
|------|------|------|
| `C:\Users\dtsli\dtslib-apk-lab` | C드라이브 클론 | D로 통합 권고, 사용자 확인 필요 |

## Canonical 경로 (최종)

| 레포 | Canonical 경로 |
|------|---------------|
| parksy-audio | `D:\PARKSY\parksy-audio` |
| parksy-image | `D:\parksy-image` |
| dtslib-apk-lab | `D:\1_GITHUB\dtslib-apk-lab` |
| dtslib-localpc | `D:\PARKSY\dtslib-localpc` |
