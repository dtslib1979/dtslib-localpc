# 중복 클론 목록 + 정리 권고

> **주의**: 이 문서는 현황 파악용. 실제 삭제는 별도 세션에서 확인 후 진행.

## 확인된 중복

### parksy-audio (3개 클론)
| 경로 | 용도 | 권고 |
|------|------|------|
| `D:\PARKSY\parksy-audio` | Claude Code 워킹 카피 | **Canonical** (유지) |
| `D:\1_GITHUB\parksy-audio` | sync.bat 클론 | 삭제 권고 |
| `D:\parksy-audio` | 독립 클론 (이전) | 삭제 권고 |

### parksy-image (2개)
| 경로 | 용도 | 권고 |
|------|------|------|
| `D:\parksy-image` | Claude Code 워킹 카피 | **Canonical** (유지) |
| `D:\parksy-image-fresh` | 용도 불명 (fresh copy?) | 확인 후 삭제 |

### dtslib-apk-lab (2개)
| 경로 | 용도 | 권고 |
|------|------|------|
| `D:\1_GITHUB\dtslib-apk-lab` | sync.bat 클론 | **Canonical** (유지) |
| `C:\Users\dtsli\dtslib-apk-lab` | C드라이브 클론 | D로 통합 권고 |

### dtslib-localpc (2개)
| 경로 | 용도 | 권고 |
|------|------|------|
| `D:\PARKSY\dtslib-localpc` | Claude Code 워킹 카피 | **Canonical** (유지) |
| `D:\1_GITHUB\dtslib-localpc` | sync.bat 클론 | 자동 동기화 유지 |

## 정리 원칙

1. **Canonical = PARKSY/ 또는 루트** — Claude Code 세션이 직접 작업하는 경로
2. **1_GITHUB/ = 백업 미러** — sync.bat이 자동 관리, 직접 작업 금지
3. **C 드라이브 클론 = D로 통합** — WD Passport 이동성 유지

## 예상 절약 용량

| 삭제 대상 | 예상 크기 |
|-----------|----------|
| `D:\parksy-audio` | ~500MB |
| `D:\parksy-image-fresh` | ~200MB |
| `C:\Users\dtsli\dtslib-apk-lab` | ~300MB |
| **합계** | **~1GB** |

## 실행 시 체크리스트

- [ ] 각 삭제 대상에 uncommitted 변경 없는지 `git status` 확인
- [ ] 삭제 전 `git log -1` 비교하여 canonical과 동일 커밋인지 확인
- [ ] 삭제 후 1_GITHUB/ sync.bat 실행하여 정상 동작 확인
