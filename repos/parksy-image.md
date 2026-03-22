# parksy-image 개발 일지

> **1인 출판사/방송국 이미지 프로덕션 시스템**
> 한국어 자연어 → 8단계 자동화 → 웹툰/방송/도면/번들

---

## 1. 프로젝트 정체성

**parksy-image**는 이미지를 만드는 시스템이 아니다. 이미지를 **산업화**하는 시스템이다.
사용자가 Gemini + Samsung Drawing으로 원형(유닛)을 만들면, 이 파이프라인이 조합/출판/배포를 자동화한다.

### 핵심 철학

- **"생각 → 말 → 끝"** — 사용자는 의도만 말하고, Claude가 노동한다
- **작가 주권 (Author Sovereignty)** — AI는 마감 도구, 감정/IP는 사용자 고유
- **유닛 퍼스트** — 독립 생성(bleed 15% 여백) → 앵커 기반 조합 → 트림 경계 융합
- 시스템은 **창작을 자동화하지 않는다**. 창작물을 **산업화**할 뿐이다.

### 레포 줄거리 (소설 구조)

```
1장  이미 달리고 있었다 (Phase 19~20)
2장  남의 도구를 믿었다가 버렸다 (DALL-E → Gemini)
3장  혼자서 공장을 지었다 (파이프라인 + 인프라)
4장  공장에 이름표를 붙였다 (계정, 토큰, 보안)
5장  공장을 가동했다 (E2E 검증)
6장  깨달았다 — "내 글씨가 없다" (PSE 탄생)
7장  공장에 내 서명을 새겼다 (PSE + 렉시콘)
```

---

## 2. 현재 상태 (2026-02-28)

| 항목 | 값 |
|------|-----|
| Branch | `main` |
| Last Commit | `c1dadcf` — docs: 세션 종료 프로토콜 추가 |
| PSE Glyphs | 86개 built OK |
| PSE Tests | 33/33 passing |
| Pipeline Version | v3 (8-stage automation) |
| Queue | `_queue/` 대기 작업 존재 |
| 로컬 경로 | `D:\parksy-image` |

### 블로커

- **PSE Phase 2 진입 블로커**: 사용자 태블릿 손글씨 SVG 미수집
- PC 세션: `python -m tools.pse.build --validate` 미실행
- YouTube 인증: 토큰 복사 필요 (parksy-audio 마스터)

---

## 3. 파이프라인 v3 — 8단계 자동화

```
한국어 자연어 → 8단계 자동화 → 웹툰/방송/도면/번들

[1] Script    node cli.js produce "주제"
[2] Assemble  관상학 감정블렌딩 + 동작합성 → 20+ 레이어
[3] Webtoon   4컷 웹툰 PNG
[4] Broadcast 방송 프레임 (1920x1080)
[5] SVG       조립 블루프린트
[6] DXF       CAD 도면 (R12)
[7] Drawing   사진 → 제조용 2D 도면 (DXF/SVG)
[8] Bundle    마켓 패키지
```

### CLI 명령어 (Termux — Node.js)

```bash
node cli.js produce "오늘 레스토랑에서 손님이 화를 냈다"   # 에피소드 7단계
node cli.js produce-all                                     # 전체 일괄
node cli.js parse "슬프게 걸어가는 박씨"                    # 파서 테스트
node cli.js face parksy anger                               # 유닛 퍼스트 얼굴 조합
node cli.js prompts -c parksy                               # AI 프롬프트 27장 생성
node cli.js test                                            # 31개 통합 테스트
node cli.js status                                          # 시스템 상태
node cli.js svg/dxf/bundle [assembly_plan.json]             # 개별 도면/번들
```

### PC 조합 (Python + Pillow)

```bash
python scripts/assemble/full_pipeline.py --character parksy --emotion anger --yaw 30
python scripts/assemble/trim_pipeline.py input.png
python scripts/assemble/bd_style.py input.png
python scripts/assemble/face_assembler.py plan.json
```

### 유닛 퍼스트 조합 원리

```
유닛 독립 생성 (bleed 15% 여백) → 앵커 기반 조합 → 트림 경계 융합 → BD 후처리
27장 유닛 → 512종 조합 (박씨 캐릭터)
```

---

## 4. Script Engine — 한국어 자연어 처리

파이프라인의 1단계. 한국어 문장을 파싱하여 감정/동작/캐릭터를 추출한다.

- **100+ 한국어 키워드 규칙**
- **30+ 감정** (anger, sadness, joy, fear, surprise, disgust, contempt 등)
- **24 동사** (걸어가다, 뛰다, 앉다 등 → 포즈 매핑)
- **14 부사** (천천히, 빠르게, 슬프게 등 → 감정 강도 조절)

```bash
node cli.js parse "슬프게 걸어가는 박씨"
# → { character: "parksy", emotion: "sadness", pose: "walking", intensity: 0.7 }
```

---

## 5. PSE (Parksy Signature Engine) — 손글씨 폰트 엔진

### 아키텍처

```
tools/pse/glyphs/*.svg → python -m tools.pse.build → tools/pse/output/parksy-hand.ttf
                                                      → 전 파이프라인 자동 적용
```

### 폰트 사양

| 항목 | 값 |
|------|-----|
| UPM | 1000 |
| Ascender | 800 |
| Descender | -200 |
| 현재 글리프 | 86개 |
| 테스트 | 33/33 passing |
| 출력 파일 | `tools/pse/output/parksy-hand.ttf` |
| 의존성 | fonttools (필수), Pillow (렌더링 시) |

### Phase 1 (Complete — 2026-02-23)

- 86개 글리프 빌드 완료 (영문 대소문자 + 숫자 + 기본 특수문자 + 한글 기본)
- `mapping.yaml` → SVG 스캔 → Bézier 추출 → TTF 빌드
- 4개 compose 스크립트 `draw.text(font=parksy-hand.ttf)` 통합
- Placeholder SVG → 사용자 태블릿 손글씨로 교체 필요
- Pretendard 베이스 폰트 메트릭 상속 구조 설계

### Phase 2 (대기 — 블로커: 사용자 손글씨 SVG)

- 한글 확장 (300~500자)
- `python tools/pse/download_base.py` → Pretendard 다운로드
- `python -m tools.pse.build` → 메트릭 상속 검증
- 사용자 태블릿 손글씨 SVG 입고 → `tools/pse/glyphs/` 교체

### 빌드 명령

```bash
python -m tools.pse.build                  # 전체 빌드 (SVG → TTF)
python -m tools.pse.build --only A,B,ga    # 특정 글리프만
python -m tools.pse.build --validate       # 검증
python -m tools.pse.build --inspect A      # 글리프 정보
python -m tools.pse.build --stem-info      # 획 굵기 정보
python tools/pse/gen_placeholder_glyphs.py # Phase 1 플레이스홀더 생성
python tools/pse/download_base.py          # Pretendard 다운로드
python tools/pse/tests/test_pse.py         # 33개 테스트
```

---

## 6. Face Disassembler — 얼굴 분해 엔진

### 기술 스택

- **MediaPipe** v0.10.32 (Tasks API 마이그레이션 완료)
- **468 랜드마크** → 7 파츠 분해

### 7 파츠

얼굴을 7개 독립 부품으로 분해하여 유닛화한다:
- 눈 (좌/우), 코, 입, 눈썹 (좌/우), 얼굴 윤곽

### 감정 믹싱 매트릭스

- 감정 조합이 **비가환적(non-commutative)** — anger+sadness ≠ sadness+anger
- 관상학 앵커 기반 조합이 하드코딩보다 자연스러움
- bleed margin으로 경계 아티팩트 방지

### 검증 (2026-02-23 PC 세션)

- face_disassembler.py: Tasks API 마이그레이션 완료, 7파츠 분해 검증
- photo2drawing.py: DXF 4프리셋 + SVG 전부 검증
- full_pipeline.py: 분해→재조합→트림→BD스타일 E2E 통과

---

## 7. photo2drawing — 사진 → 제조용 도면

사진을 DXF/SVG 제조용 2D 도면으로 변환하는 파이프라인.

### 4 프리셋

| 프리셋 | 용도 | 특이사항 |
|--------|------|----------|
| default | 범용 | 기본 설정 |
| clothing | 의류 패턴 | 시접 10mm |
| furniture | 가구 | 직각 스냅 |
| accessory | 악세사리 | 시접 5mm |

### 3 캘리브레이션 모드

- `--ruler` — 자 감지 (자동)
- `--ref a4_long` — A4 기준
- `--manual-px N --manual-mm M` — 수동

### 8 DXF 레이어

각 도면 요소가 별도 레이어에 분리됨

### 의존성

opencv-python, numpy, scipy, ezdxf, svgwrite

### 명령어

```bash
python scripts/drawing/photo2drawing.py input.jpg --ruler -o output.dxf        # 기본
python scripts/drawing/photo2drawing.py shirt.jpg --preset clothing --ruler     # 의류
python scripts/drawing/photo2drawing.py table.jpg --preset furniture --ref a4_long  # 가구
python scripts/drawing/photo2drawing.py input.jpg --format svg -o output.svg   # SVG
python scripts/drawing/photo2drawing.py input.jpg --preview                    # 미리보기
```

---

## 8. 배포 채널 & 브릿지

### 6채널 배포 시스템

| 채널 | 용도 | 상태 |
|------|------|------|
| **YouTube** | @visualizer-parksy 영상/이미지 | 인증 펜딩 (토큰 복사 필요) |
| **Google Drive** | rclone `gdrive:parksy-image/` 결과물 공유 | 작동 중 |
| **Telegram** | @parksy_bridge_bot (SVG만, DXF 금지) | 봇+채널 완료, PC 실행 펜딩 |
| **네이버 블로그** | 3채널 웹툰 포맷 배포 | 규격 완료, 배포 대기 |
| **Git (GitHub)** | 코드/스펙 동기화 | 작동 중 |
| **_queue/ 잡 시스템** | 핸드폰→PC 작업 요청 큐 (Git 위) | 작동 중 |

### YouTube Studio (@visualizer-parksy)

```bash
node tools/youtube/youtube-studio.js status
node tools/youtube/youtube-studio.js upload video.mp4 --title "제목" --privacy unlisted
node tools/youtube/youtube-studio.js thumbnail <videoId> thumb.png
node tools/youtube/youtube-studio.js list 10
node tools/youtube/youtube-studio.js analytics 7
node tools/youtube/youtube-studio.js playlist create "시리즈명"
```

### Google Drive 동기화

```bash
./tools/gdrive-sync.sh up        # output/ 전체
./tools/gdrive-sync.sh drawings  # 도면만
./tools/gdrive-sync.sh parts     # 파츠만
./tools/gdrive-sync.sh down      # 내려받기
./tools/gdrive-sync.sh status    # 상태
```

### 텔레그램 브릿지

- Bot: @parksy_bridge_bot (이미지/도면 전용)
- chat_id: 6858098283
- config: `tools/telegram-bridge/config.json` (.gitignore)
- **DXF 텔레그램 전송 금지** — 핸드폰에서 못 열음
- 도면 생성 시 DXF + SVG 동시 출력, 텔레그램에는 SVG만 sendDocument

### 네이버 블로그 3채널

| 블로그 | 역할 | 도메인 | YouTube 연동 |
|--------|------|--------|-------------|
| **parksy_kr** | 세계관/감성 웹툰 | parksy.kr | @blogger-parksy, @visualizer-parksy |
| **eae_kr** | 교육/튜토리얼 | eae.kr | @EAE-University, @technician-parksy |
| **dtslib** | 비즈니스/데이터 | dtslib.com | @dtslib1979, @musician-parksy |

#### 네이버 이미지 규격

| 항목 | 수치 |
|------|------|
| 업로드 제한 | 1장 10MB, 1회 50장/50MB |
| 서버 리사이즈 | ~1000px 강제 축소 |
| 레이아웃 폭 | 기본 693px / 확장 886px / 옆트임 966px |
| **납품 기준** | **폭 966px, JPG 92%, 72dpi** |
| 컷 최대 높이 | 2000px (스크롤 피로 방지) |
| 검색 썸네일 | 1300x885px |

```bash
# 네이버 납품
python scripts/naver/naver_cut_splitter.py input.png --channel parksy_kr
python scripts/naver/naver_post_builder.py --channel parksy_kr --title "제목" --series "시리즈"
```

---

## 9. 서사 추출 엔진

git log를 분석하여 레포의 줄거리를 자동 추출한다.

```bash
python tools/narrative/extract.py                     # 장별 + 전환점
python tools/narrative/extract.py -f synopsis          # 시놉시스 (3줄)
python tools/narrative/extract.py -f blog              # 네이버 블로그 원고
python tools/narrative/extract.py -f timeline          # 타임라인
python tools/narrative/extract.py --climax             # 전환점만
python tools/narrative/extract.py --all /parent/dir    # 28개 레포 연작 인덱스
```

**구조**: `git log` → 서사 분류(시도/삽질/전환/각성/성장/정리/보안/출판) → 아크 감지 → 포맷 출력

---

## 10. 물류 동선 (입고 → 검수 → 출고)

### 폴더 흐름

```
00_inbox/     → 새 이미지 (미검수)
     ↓ check_unit.py 검수 통과
웹툰/*/       → 검수된 유닛 (정식 자산)
강의/*/
     ↓ assemble.py 조합
output/       → 조합 결과물 (캐릭터, 씬, 클립)
```

### 파일명 규칙

```
{brand}_{type}-{subject}_{style}_{size}_v{ver}.{ext}
예: parksy_face-eyes-round_anime_400x200_v001.png
```

| 토큰 | 값 |
|------|-----|
| brand | parksy, koosy, verdi, custom |
| type | face, body, clothes, prop, bg, icon, overlay, char, scene |
| style | anime, line, flat, painterly, noir, sketch |

### 검수 체크리스트

| 항목 | 기준 | 스크립트 |
|------|------|----------|
| 사이즈 | UNIT_SPEC.yaml | check_unit.py |
| 파일명 | `{type}_{variant}_{emotion}.png` | 수동 |
| 투명배경 | PNG + RGBA | check_unit.py |
| 출처 기록 | prompt, source | 사용자 입력 |

### 메타 파일

모든 이미지 옆에 `.prompt.txt` 파일:
```
prompt: round happy eyes, anime style, transparent bg
tags: eyes, round, happy, anime
source: gemini, 2026-01-16
```

---

## 11. 큐 시스템 (_queue/)

핸드폰에서 작업 요청 → GitHub push → PC에서 실행

### 큐 파일 형식

```yaml
# _queue/job_20260116_001.yaml
id: job_20260116_001
created: 2026-01-16T10:30:00
status: pending
type: assemble
target: specs/characters/hero.yaml
```

### 작업 타입

| type | 설명 | 실행 스크립트 |
|------|------|---------------|
| produce | 에피소드 파이프라인 | `node cli.js produce` |
| face | 유닛 퍼스트 얼굴 | `full_pipeline.py` |
| assemble | 레이어 조립 | assemble_v3.js |
| validate | 규격 검증 | check_unit.py |
| trim | 경계 융합 | trim_pipeline.py |
| bd_style | BD 후처리 | bd_style.py |
| drawing | 사진 → 도면 | photo2drawing.py |
| naver | 네이버 컷 분할+템플릿 | naver_cut_splitter.py |
| batch | 일괄 작업 | produce_all.js |

### 상태 흐름

`pending` (핸드폰 생성) → `running` (PC 처리 중) → `completed` / `failed`

---

## 12. 환경별 역할

| 환경 | 역할 | 가능한 작업 |
|------|------|-------------|
| **핸드폰 Claude** | 설계, 요청, 업로드 | 파일 생성, git push, 큐 등록 |
| **PC Claude** | 진짜 작업 | Python 실행, 대량 조합, 도면 생성, 네이버 납품 |
| **GitHub Actions** | 가벼운 자동화 | index.json, 검증, 작은 썸네일 |
| **Google Drive** | 결과물 공유 | output/ 양방향 동기화 |
| **네이버 3채널** | 발견 채널 | 웹툰 포맷 검색/추천/피드 유입 |

### PC 환경 감지

```
경로 D:\parksy-image\ 또는 /mnt/d/ → PC 환경 (Python 직접 실행)
경로 ~/storage/ 포함 → Termux 핸드폰
```

---

## 13. 계정 & 인증

### YouTube (@visualizer-parksy)

- Account A (dimas.thomas.sancho@gmail.com) 소유 브랜드 채널
- GCP 프로젝트: `parksy-youtube`
- OAuth Client ID: `390585643473-*` (desktop app)
- API: YouTube Data API v3, YouTube Analytics API v2
- **token.json 마스터: parksy-audio** → 이 레포로 복사

```bash
# 토큰 복사 (parksy-audio → parksy-image)
cp D:\PARKSY\parksy-audio\tools\youtube\token.json tools\youtube\token.json
```

### 텔레그램

- 이미지/도면 봇: @parksy_bridge_bot
- 오디오/비디오 봇: @parksy_bridges_bot (혼용 금지!)
- config: `tools/telegram-bridge/config.json` (.gitignore)

### Google Drive

- rclone remote: `gdrive:parksy-image/`

---

## 14. 로컬 경로 맵

| 대상 | 경로 |
|------|------|
| 레포 (canonical) | `D:\parksy-image` |
| PSE 엔진 | `D:\parksy-image\tools\pse\` |
| 글리프 SVG | `D:\parksy-image\tools\pse\glyphs\` |
| 폰트 출력 | `D:\parksy-image\tools\pse\output\parksy-hand.ttf` |
| Telegram config | `D:\parksy-image\tools\telegram-bridge\config.json` |
| YouTube tools | `D:\parksy-image\tools\youtube\` |
| Narrative engine | `D:\parksy-image\tools\narrative\` |
| Queue | `D:\parksy-image\_queue\` |
| Inbox | `D:\parksy-image\00_inbox\` |
| Output | `D:\parksy-image\output\` |

---

## 15. 핵심 교훈 & 실패 기록

### 검증된 원칙

1. **관상학 앵커 > 하드코딩** — 얼굴 조합 시 좌표 직접 입력보다 관상학적 비율 앵커가 훨씬 자연스러움
2. **bleed margin 필수** — 유닛 경계에 15% 여백 없으면 합성 시 아티팩트 발생
3. **감정 믹싱은 비가환** — anger+sadness ≠ sadness+anger. 순서가 결과에 영향
4. **DALL-E → Gemini 전환** — DALL-E의 스타일 일관성 부족으로 Gemini로 이전
5. **DXF 텔레그램 전송 불가** — 핸드폰에서 열리지 않음. SVG만 전송
6. **네이버 서버 리사이즈** — 원본 해상도 무의미, 966px 납품 기준 설정

### 아직 미검증

- PSE Phase 2 한글 확장 (300~500자) — 실제 빌드 미진행
- YouTube 자동 업로드 — 인증 토큰 복사 후 테스트 필요
- 네이버 블로그 실제 배포 — 규격은 완성, 포스팅 미실행

---

## 16. 대기 작업

- [ ] **사용자 태블릿 손글씨 SVG 수집** (PSE Phase 2 블로커)
- [ ] PC: `python tools/pse/download_base.py` → Pretendard 다운로드
- [ ] PC: `python -m tools.pse.build --validate` 검증
- [ ] YouTube: parksy-audio에서 token.json 복사 → 업로드 테스트
- [ ] 네이버 블로그: 첫 포스팅 실제 배포
- [ ] `_queue/` 대기 작업 처리

---

## 17. 이어받기 가이드 (Continuation Instructions)

### PSE Phase 2 진입 시

1. 사용자에게 태블릿 손글씨 SVG 수집 상태 확인
2. `python tools/pse/download_base.py` — Pretendard 다운로드
3. `python -m tools.pse.build` — 메트릭 상속 검증
4. 사용자 SVG → `tools/pse/glyphs/` 교체
5. `python -m tools.pse.build --validate` — 빌드 검증
6. `python tools/pse/tests/test_pse.py` — 33개 테스트 통과 확인

### 새 에피소드 생산 시

```bash
# Termux
node cli.js produce "주제"     # 파이프라인 실행
node cli.js test               # 테스트
git add -A && git commit && git push

# PC (조합/도면 필요 시)
python scripts/assemble/full_pipeline.py --character parksy --emotion [감정]
python scripts/drawing/photo2drawing.py [사진] --ruler -o output.dxf
```

### YouTube 배포 시

1. `cp D:\PARKSY\parksy-audio\tools\youtube\token.json tools\youtube\token.json`
2. `node tools/youtube/youtube-studio.js status` — 인증 확인
3. `node tools/youtube/youtube-studio.js upload video.mp4 --title "제목"`

### 큐 처리 시 (PC 세션)

1. `_queue/` 확인 → `status: pending` 파일 찾기
2. 작업 실행
3. `status: completed` 로 변경
4. 결과 push

---

---

## Part 2: 세션 로그 (자동 축적)

> **이 섹션 아래로 세션 로그가 자동 축적된다.**
> 각 parksy-image 세션 종료 시 Claude가 아래 포맷으로 append한다.
> 시간이 지나면 이 로그가 로컬 개발의 전체 이력이 된다.
> D: 유실 시 → 이 로그를 읽고 Claude가 전부 재구축할 수 있다.

<!--
포맷:
### YYYY-MM-DD | 세션 요약 한 줄
**작업**: 구체적으로 뭘 했는지 (파일명, 함수명, 파라미터 포함)
**결정**: 왜 그렇게 했는지 (비교 대상, 시도한 대안, 버린 이유)
**결과**: 수치 포함 (점수, 파일 크기, 에러 메시지 등)
**교훈**: 다음 세션이 반드시 알아야 할 것
**재구축 힌트**: D: 유실 시 이걸 다시 만들려면 Claude에게 이렇게 시켜라
-->

*— 세션 로그 축적 시작점 —*

---
### 2026-02-28 | dtslib-localpc 자동 축적 시스템 구축 — CLAUDE.md 세션 종료 프로토콜 추가
**작업**: parksy-image CLAUDE.md에 세션 종료 프로토콜 추가. dtslib-localpc/repos/parksy-image.md 재구축 매뉴얼 551줄 작성 (8-stage pipeline v3, PSE 86글리프 사양, face disassembler 6단계, photo2drawing, 6개 배포채널).
**결정**: parksy-image는 코드가 Git에 있으므로 코드 백업 불필요. 대신 파이프라인 설계 의도, PSE 사양, 배포 채널 설정, 큐 시스템 등 "왜 이렇게 만들었는가"를 문서화.
**결과**: 17개 섹션 완성. Telegram bridge SVG 전용 규칙, YouTube/GDrive/Naver 4채널 설정 전부 기록. 커밋 1501f98.
**교훈**: parksy-image는 PC 세션에서만 동작 (Python + 로컬 파일). 매 PC 세션 종료 시 반드시 이 로그를 갱신할 것. PSE Phase 2 진입 시 태블릿 손글씨 SVG 수집이 블로커.
**재구축 힌트**: 이 파일 전체를 Claude에게 읽히면 파이프라인, PSE, 배포 시스템 전부 재구축 가능. 섹션 3(pipeline v3)이 핵심.
---

---
### 2026-03-22 | web2video E2E 완성 + 15채널 OAuth Production 전환 + 채널 자동 라우팅
**작업**:
1. 15채널 OAuth Production 전환: tools/youtube/accounts/token_*.json 15개 전부 Testing→Production 재인증 (Playwright MCP + auth_one.js). Error 500 패턴: back→retry, 연속 500 시 lsof -ti:8787 | xargs kill -9 후 재시작.
2. youtube-studio.js update 버그 수정: `part: 'snippet'` 만 보내던 것 → privacy 변경 시 `status` part도 추가.
3. web2video.py E2E 테스트: python3 web2video.py "https://dtslib.com/" --channel dtslib_com --privacy private → 42초 영상, Video ID WHCLa94lYtc, 1.9MB.
4. channel_routing.json 생성: 21개 도메인→레포→채널 라우팅 테이블 (tools/web2video/channel_routing.json). resolve_channel() 함수 추가.
5. notify_telegram() 추가: 업로드 완료 → Telegram admin 알림 (telegram-bridge/config.json의 admin_id 필요).
**결정**:
- dtslib.com → @dtslib_com (Account D, dimas@dtslib.com)
- dtslib.kr → @dtslib-branch (Account B, 경제방송국)
- parksy.kr → @visualizer-parksy 기본, /persona 경로로 오버라이드
- --channel 기본값을 None → "auto"로 변경 (이제 URL만 넣으면 채널 자동)
**결과**: 15/15 채널 갱신 성공 (node token_refresh_all.js 확인). 라우팅 6개 URL 전수 검증 OK. Telegram 알림은 config.json 없어서 비활성 (graceful skip).
**교훈**:
- Brand account OAuth: Google 첫 클릭 Error 500은 흔함. back→retry 먼저, 2회 이상 실패 시 포트 kill 후 새 AUTH_URL 받을 것.
- web2video 결과물 경로: /mnt/d/PARKSY/web2video/outputs/w2v_*.mp4
- Telegram 알림 활성화: tools/telegram-bridge/config.json에 "admin_id": "박씨_chat_id" 추가.
**재구축 힌트**: tools/web2video/ 디렉토리에 web2video.py, tts_humanizer.py, lecture_template.html, presets.json, channel_routing.json 전부 있음. pip install edge-tts pedalboard soundfile playwright + playwright install chromium 하면 돌아감.
---

---
### 2026-03-22 | phoneparis.kr R1→R10 강화학습 루프 수렴 + 업로드 완료
**작업**: web2video.py + lecture_template.html — 10회 반복 품질 개선 루프
**결정**:
- R4: Promise.all() 타이밍 수정 (10-15s 슬라이드 오프셋 제거)
- R5: 3-8gram greedy phrase dedup (문장 경계 없는 중복 제거)
- R6: heading subphrase removal from body, CSS word-break:keep-all
- R7: 동적 인트로 폰트 크기 (30자↑→62px, 22자↑→72px)
- R8: ALL_CAPS normalization (SAMSUNG→Samsung, _ABBR_KEEP 화이트리스트)
- R9: normalization을 dedup 앞으로 이동
- R10: display_limit(25) vs narr_limit(40) 분리 + 2-window 5글자↑ dedup
**결과**: R1 6.5점 → R10 9.2점. YouTube 업로드 완료 https://youtu.be/jt6nmfAHbBM
**교훈**: 3-window 인접 dedup은 "Lock Good Lock" 같은 합성어를 파괴함 → 2-window + 5글자 임계값으로 제한
**재구축 힌트**: `_clean_body()`는 display_limit/narr_limit 이중 반환 구조. narration은 symbol 변환(/ → space, · → , ) 적용 후 마침표 보장.
---

---
### 2026-03-22 | web2video R11~Telegram오프닝파이프라인 — 음질/템플릿/영상효과 전면 개선

**작업**:
1. tts_humanizer.py R11 브로드캐스트 프리셋: Distortion(drive_db=2.5) 완전 제거(saturation_drive=0.0), comp_ratio=2.2, limiter_db=-1.5
2. BGM 교체: lyria3 AI 생성음 → Musician-Parksy 자작 클래식 피아노 7트랙 (parksy-audio/lyria3/material/parksy_original/)
3. 보이스 교체: ko-KR-HyunsuMultilingualNeural +30% (1.3배속 남성)
4. 기호 제거 적용 범위 확장: narration 전용 → display(화면 텍스트)까지 동일 regex 적용
5. --tone cocky: Claude Haiku API로 나레이션 재작성 (익살/잘난척 톤). OAuth: ~/.claude/.credentials.json → claudeAiOauth.accessToken
6. lecture_template.html R13→R15 전면 재작성: Oswald condensed 폰트, wrapWords()/wordReveal() 단어별 stagger 애니메이션, runTimingLoop()로 window.__TIMINGS__ 읽어서 슬라이드 전진 (핵심버그: 기존 showSlide(0) 하드코딩으로 슬라이드 고정됨)
7. FFmpeg zoompan Ken Burns 배경: fetch_page()에서 Playwright 스크린샷 촬영, assemble_final()에서 zoompan_bg.mp4 생성, blend=all_mode=screen:all_opacity=0.28으로 텍스트 webm 뒤에 합성
8. Telegram 오프닝 파이프라인: image_downloader.py에 VIDEO_EXTS 추가, mp4 수신 → opening_staging/opening_latest.mp4 심링크. web2video.py에 --opening PATH 추가 → assemble_final()에서 opening 정규화 후 FFmpeg concat demuxer로 앞에 붙임

**결정**:
- Distortion 제거: pedalboard Distortion이 TTS에 기타 찌그러짐 유발 → 완전 제거
- BGM: "내 게 아닌" AI 생성음 문제 → 박씨 자작 Musician-Parksy 연주곡으로 교체
- HyunsuMultilingual: 한국어 남성 목소리 중 가장 자연스러운 인토네이션
- lecture_template R15: "PPT 수준"이라는 피드백 → Oswald + 단어별 stagger + diagonal line으로 AE 느낌
- zoompan 배경: 소스 페이지 스크린샷을 배경으로 써서 "footage+텍스트" 합성 AE 스타일 구현
- Grok 오프닝: SuperGrok 버스 요금제 한도 이슈 → 수작업 큐레이션 후 Telegram 전송 → 자동 붙이기 (히트작 후보 전용)

**결과**: 
- R10→R15 강화학습 루프, Telegram 오프닝 파이프라인 코드 완성 (커밋 2d09922)
- tts_humanizer.py R11, lecture_template.html R15 커밋 완료
- telegram-bridges image_downloader.py mp4 핸들러 커밋 완료 (6442c79)

**교훈**:
- runTimingLoop 없으면 슬라이드가 0번에서 절대 안 넘어감 — 브라우저 녹화 결과물 첫 확인 시 반드시 슬라이드 전진 여부 체크
- anthropic 모듈: pip install anthropic --break-system-packages
- OAuth key: claudeAiOauth.accessToken (claudeAiOauthToken 아님)
- Port 19301 already in use: fuser -k 19301/tcp 선실행

**재구축 힌트**: 
web2video 전체 파이프라인: `python3 tools/web2video/web2video.py "URL" --lang ko --bgm clair --tone cocky --opening /mnt/d/PARKSY/web2video/opening_staging/opening_latest.mp4`
오프닝 없이 쓸 때: `--opening` 인수 생략하면 그냥 스킵됨
Telegram mp4 수신: telegram-bridges/image_downloader.py 백그라운드 실행 (tmux tg-image)
---
