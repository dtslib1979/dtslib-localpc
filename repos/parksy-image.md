# parksy-image 현황

> **Phase 2 진행 중** — PSE 한글 확장, 배포 채널 구축 완료 대기

## 핵심 지표

| 항목 | 값 |
|------|-----|
| PSE Glyphs | 86개 built OK |
| PSE Tests | 33/33 passing |
| Pipeline | v3 (8-stage automation) |
| Queue | _queue/ 폴더 대기 작업 있음 |
| Distribution | YouTube, GDrive, Telegram, Naver Blog |

## PSE (Parksy Signature Engine)

### Phase 1 (Complete — 2026-02-23)
- 86개 글리프 빌드 완료
- 폰트 출력: `tools/pse/output/parksy-hand.ttf`
- Placeholder SVG → 사용자 태블릿 필기 교체 필요
- 4개 compose 스크립트 폰트 시스템 통합

### Phase 2 (In Progress)
- 한글 확장 (300-500자)
- 사용자 손글씨 SVG 입력 대기 중
- Pretendard 베이스 폰트 다운로드 필요

## 파이프라인 (v3)

8단계 자동화: Korean text → Webtoon/Broadcast/Drawing/Bundle
- Face disassembler: 7파트 분해 (MediaPipe 0.10.32)
- photo2drawing.py: 4 프리셋 (clothing, furniture, accessory) + SVG
- full_pipeline.py: decompose→reassemble→trim→BD style E2E

## 배포 채널

| 채널 | 상태 |
|------|------|
| YouTube | @visualizer-parksy configured, upload pending |
| Google Drive | rclone gdrive:parksy-image/ ready |
| Telegram | @parksy_bridge_bot (SVG only, DXF 금지) |
| Naver Blog | 3-channel format ready, distribution pending |

## 로컬 경로

| 파일 | 경로 |
|------|------|
| 레포 | `D:\parksy-image` |
| PSE 엔진 | `D:\parksy-image\tools\pse\` |
| 글리프 | `D:\parksy-image\tools\pse\glyphs\` |
| 폰트 출력 | `D:\parksy-image\tools\pse\output\` |
| Telegram config | `D:\parksy-image\tools\telegram-bridge\config.json` |
| Queue | `D:\parksy-image\_queue\` |

## 대기 작업

- [ ] 사용자 태블릿 손글씨 SVG 수집 (PSE Phase 2 블로커)
- [ ] PC 세션: `python -m tools.pse.build --validate`
- [ ] YouTube 업로드 자동화 테스트
- [ ] Naver Blog 배포 실행
- [ ] Phase 3: Speaker diarization, local whisper.cpp

## Git 상태

- Branch: `main`
- Last commit: `cfb5897` — chore: update image index
- Dirty: 28 files (PSE glyph SVGs modified)
