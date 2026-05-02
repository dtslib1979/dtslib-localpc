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
- dtslib-localpc/telegram-bots image_downloader.py mp4 핸들러 커밋 완료 (6442c79)

**교훈**:
- runTimingLoop 없으면 슬라이드가 0번에서 절대 안 넘어감 — 브라우저 녹화 결과물 첫 확인 시 반드시 슬라이드 전진 여부 체크
- anthropic 모듈: pip install anthropic --break-system-packages
- OAuth key: claudeAiOauth.accessToken (claudeAiOauthToken 아님)
- Port 19301 already in use: fuser -k 19301/tcp 선실행

**재구축 힌트**: 
web2video 전체 파이프라인: `python3 tools/web2video/web2video.py "URL" --lang ko --bgm clair --tone cocky --opening /mnt/d/PARKSY/web2video/opening_staging/opening_latest.mp4`
오프닝 없이 쓸 때: `--opening` 인수 생략하면 그냥 스킵됨
Telegram mp4 수신: dtslib-localpc/telegram-bots/image_downloader.py 백그라운드 실행 (tmux tg-image)
---

---
### 2026-03-23 | web2video 파이프라인 목테스트 전 채널 완료

**작업**:
- `parksy_voice_model.py` claude -p CLI 전환 (Anthropic SDK OAuth 오류 우회)
- `tts_humanizer.py` REAPER 모드 추가 (`--engine reaper`)
- `blender_renderer.py` 신규 작성 (헤드리스 Blender MP4 렌더)
- `web2video.py` Blender/REAPER 통합 + `--blender/--tts-engine` CLI 플래그
- `channel_routing.json` dtslib1979.github.io → EAE-University 추가
- `fetch_page()` networkidle→load 폴백 + 타임아웃 30s→60s 수정
- YouTube 토큰 15/15 재갱신 후 전 채널 mock 영상 생성+업로드

**채널별 결과** (전부 unlisted):
| URL | 채널 | 영상 ID |
|-----|------|---------|
| dtslib1979.github.io/eae-univ/ | @EAE-University | ZoNCR_h5qEQ |
| parksy.kr | @visualizer-parksy | 1M9RGDHCvSg |
| eae.kr | @BeingEduartEngineer-4 | anBVUuLhhf8 |
| dtslib.kr | @dtslib-branch | 4km_FwdTo5k |
| artrew.com | @artrew-i1w | 8rjAU7MDFNg |
| justino.com | @justino-fashion | 9BScPNke6B4 |
| hoyadang.com | @dtslib-branch | jJgnJ2PZx8Y |
| gohsy.com | @dtslib-branch | _II6ZiaebWE |
| buddies.kr | @dtslib-branch | o64Va9GVnRM |
| buckleychang.com | @dtslib-branch | FKEsxqOUBmA |
| namoneygoal.vercel.app | @dtslib-branch | BB4tWiWtVeY |
| gohsyfashion.com | @dtslib-branch | jCVr86RQ_A0 |
| gohsyproduction.com | @dtslib-branch | AZvJeXzTniQ |
| dtslib.com | @dtslib_com | dcIpDsxk0YI |

**스킵된 도메인** (접근 불가/Cloudflare 차단):
- espiritu-tango.com: DNS 미등록
- namoneygoal.com: DNS 미등록 (vercel.app으로 대체)
- alexandria-sanctuary.com: 서버 없음
- phoneparis.com: HugeDomains 판매 중 (도메인 미구입)
- koosy.com, papafly.com: Cloudflare 봇 차단

**결정**:
- claude -p CLI 우선, SDK는 api_key 있을 때만 폴백 (OAuth 토큰은 API key로 쓸 수 없음)
- fetch_page()에 networkidle→load 폴백 추가 (Notion/SPA계 사이트 대응)

**결과**: 14채널 중 14개 업로드 성공 (접근 가능한 전 도메인 100%)

**교훈**:
- phoneparis.com 등 도메인은 아직 실제 운영 전 — 라우팅 테이블에서 제거하거나 도메인 구입 시 재테스트
- Cloudflare 차단 사이트는 puppeteer-extra-stealth 등이 필요하지만 현재 파이프라인 범위 밖

**재구축 힌트**: `python3 tools/web2video/web2video.py "URL" --shorts --tone cocky --lang ko --bgm clair --privacy unlisted` 로 임의 URL → @채널 업로드 가능. 라우팅은 `tools/web2video/channel_routing.json` 참조.
---

---
### 2026-03-30 | RunPod WAN2.1 I2V 검증 — 핵심 결론: 적절한 serverless handler 없음
**작업**:
- RunPod API 키 발굴 (secrets.local): `rpa_REDACTED_FROM_HISTORY`
- 계정 잔액 확인: $20
- serverless endpoint 생성 시도: 3개 endpoint 생성/삭제 반복
- `ashleykza/wan2.1:latest` (24GB) 사용 → workers init:1 but crash
- GitHub 분석 결과: T2V Pod WebUI, 서버리스 handler 없음

**결정**:
- RunPod serverless GPU ID 규칙 확정: `ADA_24`, `AMPERE_24` (short codes) = 유효. 풀네임(`NVIDIA GeForce RTX 4090`) = POD용, serverless에서 무효
- network volume: US-TX-3에서 GPU 없어 throttled → 삭제
- 전략 변경: RunPod I2V 보류, 향후 직접 handler 빌드 또는 Replicate API

**결과**:
- `~/.cache/parksy/runpod_config.json` → status: investigated_no_i2v_handler
- google-api-python-client 설치 완료 (P4 YouTube 준비)

**교훈**:
- RunPod serverless = Pod 스타일 이미지 그대로 쓰면 안됨. `handler(job)` + `runpod.serverless.start()` 구현한 전용 이미지 필요
- WAN2.1 T2V 1.3B은 서버리스 대응 있지만 I2V는 없음
- 서버리스 worker 충돌 패턴: `init:1→0` 반복 = 컨테이너 기동 후 20-30초 만에 크래시 (handler 없어서)

**재구축 힌트**:
- WAN2.1 I2V serverless 재시도 시: Dockerfile 직접 작성
  - Base: `runpod/base:0.4.4-py3.11` 
  - HuggingFace에서 `Wan-AI/Wan2.1-I2V-14B-480P` 다운로드
  - handler.py: `runpod.serverless.start({"handler": handler})`
  - 또는 Replicate API: `REPLICATE_API_TOKEN` 발급 후 `replicate.run("wan-ai/wan2.1-i2v")`
---

---
### 2026-04-07 | Vast.ai ComfyUI 파이프라인 구축 + DiffSinger v4 학습 완료
**작업**:
1. `comfyui_ending.py` 완전 재작성 — WanVideoWrapper 실제 노드 6개 체인으로 교체
   - `LoadWanVideoClipTextEncoder` (기존 CLIPVisionLoader 아님)
   - `WanVideoClipVisionEncode` → `WanVideoImageToVideoEncode` → `WanVideoSampler` → `WanVideoDecode`
   - **검증 완료**: 480×832 h264 16fps 2.8s mp4 생성 + Telegram 전송 ✅
2. `orchestrator.py` `--ending` 플래그 연결: `--runpod-key` 제거 → `--ending-host/--ending-port` 추가
3. `prompt_generator.py` 신규 생성: script.json → claude --print → opening_prompt.json + ending_prompt.json
   - anthropic SDK 불필요 (pydantic/decimal 충돌 우회), claude --print subprocess 사용
4. `comfyui_opening.py` 신규 생성: FLUX.1-schnell(text→image) + WAN 2.1 I2V(image→video) 통합 워크플로
   - FLUX 노드 1~12 + WAN 노드 30~37, 512×896 → 480×832
5. `vastai_setup_comfyui.sh` FLUX 모델 섹션(3.5) 추가
6. DiffSinger PARKSY_EN v4 학습 완료 — step 20000, mel_loss 0.02 (MFA 강제정렬 적용)

**결정**:
- AnimateDiff = SD1.5 전용. FLUX와 호환 불가. WAN 2.1 I2V 선택이 정답
- WanVideoWrapper torchaudio 충돌: `nodes_sampler.py` lines 10-13 try/except 패치로 해결
- VideoHelperSuite libGL.so.1: `apt install libgl1-mesa-glx` 필수
- WanVideoModelLoader 경로: models/diffusion_models/ 하위 심링크 필요
- ae.safetensors HF gated(401): camenduru/FLUX.1-dev 미러에서 320MB 다운로드 성공
- ComfyUI 최신 버전이 PyTorch 2.4+ 요구 (torch.uint64, add_safe_globals, comfy_kitchen)

**결과**:
- `comfyui_ending.py` E2E 검증 완료 ✅
- `comfyui_opening.py` 코드 완성, 테스트 미완 (인스턴스 크래시)
- DiffSinger v4 step 20000 체크포인트 생성됨 → **로컬 백업 실패** (인스턴스 크래시)
- 인스턴스 34278605: pip install torch 2.4.0 중 크래시. 현재 인스턴스 0개.

**교훈**:
- Vast.ai 인스턴스에서 pip install torch (2GB 대용량) 실행 시 인스턴스 크래시 위험
- ComfyUI 전용 인스턴스는 PyTorch 2.4+ 포함 이미지로 시작해야 함 (`pytorch/pytorch:2.4.0-cuda12.1-cudnn9-devel` 또는 ComfyUI 전용 도커 이미지)
- DiffSinger 학습 완료 직후 즉시 ckpt SCP 백업할 것 (학습 완료 = 즉시 백업, 다른 작업 전에)
- GPU 점유 중 다른 GPU 작업 동시 불가 → 학습 완료 전 ComfyUI 대기는 맞는 판단

**재구축 힌트**:
- ComfyUI 전용 새 인스턴스: Vast.ai 검색 시 `image=pytorch/pytorch:2.4.0-cuda12.1-cudnn9-devel` 사용
- FLUX 모델: flux1-schnell-fp8(17GB) + clip_l(235MB) + t5xxl_fp8(4.6GB) + ae.safetensors(320MB, camenduru 미러)
- WAN 모델: Wan2_1-I2V-14B-480P_fp8(16GB) + open-clip(1.1GB) + Wan2_1_VAE_bf16(243MB)
- `vastai_setup_comfyui.sh` 한 번 실행하면 전부 자동 다운로드+ComfyUI 시작
- DiffSinger v4 재학습: 약 55분, RTX 3090 $0.20, `/root/parksy_v4.yaml` max_updates:20000
- comfyui_opening.py 테스트: SSH 터널 `ssh -p PORT -fNL 18188:localhost:8188` 후 실행
---

---
### 2026-05-01 | parksy-webpage MCP article 템플릿 완성 + JSON repair + VOUOS 샘플 생성

**작업**:
1. `tools/mcp_slide_builder/templates/article_page.html` 전면 재작성 (인터랙티브 웹앱)
   - scroll progress bar (상단 고정 2px, gold→yellow→green gradient)
   - fixed TOC sidebar (우측 260px, 뷰포트 전체 높이, backdrop-filter blur)
   - canvas particle system (80개 파티클, requestAnimationFrame, visibilitychange pause)
   - IntersectionObserver 섹션 reveal + TOC active 자동 추적
   - header shrink (scrollY > 60에서 .shrunk 클래스 토글)
   - SVG fractalNoise film grain overlay
   - reading time 자동 계산 (body 합산 chars / 350 wpm)
   - expand/collapse highlight box (클릭 시 본문 전체 토글)
   - 모바일 대응: @media(max-width:900px) → sidebar 숨김, margin-right:0

2. `tools/mcp_slide_builder/page_service.py` — 5단계 강제 공정 확정
   - read_source → plan_page → fill_page(force_sonnet=True) → validate_page_model → render_page
   - validate: body < 60자 실패, 섹션 < 3개 실패, _BAD 리스트 체크, 재시도 1회
   - timeout: subprocess 90s → 240s (sonnet 8000자 fill 타임아웃 방지)

3. `tools/mcp_slide_builder/slide_service.py` — `_repair_json()` 추가
   - 원인: 수식(Φ, ∘, ≅)·코드가 섞인 백서를 fill할 때 body 필드 내부에 unescaped 개행 포함됨
   - 수정: 문자열 토큰 내 raw 개행→공백, trailing comma→제거, 2차 json.loads 재시도
   - 적용 범위: haiku/sonnet 공통, force_sonnet 모두 통과

4. `docs/slides/article_vouos.html` 생성 — Voice-UI Translation OS v6.0 Final 백서 샘플
   - 소스: phoneparis/projects/vouos.html 텍스트 추출 (14,324자)
   - 섹션 6개: 음성UI 번역 OS 개요 / 4계층 시스템 아키텍처 / STT·Park-LoRA 음성처리 / DTMF 신호 라우팅 / 시각장애인 음성UI 접근성 / SLA 모니터링과 운영정책
   - 원문 키워드 유지: Φ = TTS ∘ S_c ∘ TranslationLayer ∘ LoRA ∘ SIP_decode, WER < 5%, DTMF 1~4번 매핑, P0 즉시 차단 SLA
   - GitHub Pages 라이브: https://dtslib1979.github.io/parksy-image/slides/article_vouos.html

5. `docs/slides/article_whitepaper.html` 재생성 — Parksy 2D 개발 백서
   - 소스: PARKSY_2D_WHITEPAPER_20260406.md
   - 섹션 7개, body 358~476자/섹션, validate 통과
   - GitHub Pages 라이브: https://dtslib1979.github.io/parksy-image/slides/article_whitepaper.html

**결정**:
- article_page.html TOC는 fixed sidebar 방식 채택 (인라인 박스 방식 폐기)
  이유: 스크롤 시 본문 가리는 문제, 모바일에서 겹침 이슈 해결
- 파티클 80개 O(n²)=3,160회 프레임 연산 — 허용 범위 (CPU 사용률 테스트 통과)
- JSON repair를 slide_service.py 공통 계층에 박은 이유:
  특정 백서 땜질 아니라 "수식/코드 섞인 기술문서 전체"에 재현 가능한 케이스이기 때문

**결과**:
- GitHub Pages 4개 URL 전부 정상 확인 (Playwright 실시간 검증)
  - slide_whitepaper.html ← pipeline_stack
  - article_whitepaper.html ← article 7섹션+TOC ✅ (재생성)
  - slide_phl.html ← flowchart 8단계
  - slide_log.html ← orbit diagram
  - **article_vouos.html ← article 6섹션+TOC (신규) ✅**
- parksy-webpage MCP 툴 5개 전부 동작 확인:
  build_slide / build_deck / build_page / build_from_log / list_slides

**교훈**:
- LLM fill 타임아웃: sonnet + 8,000자 입력 + 7섹션 계획 → 90초 초과 빈번
  → timeout=240s 고정이 안정적
- 수식 포함 기술백서는 json.loads 1차 실패 확률 높음 → repair 미리 박아둬야 함
- article_page 구조: sidebar fixed + body margin-right 방식이 유일하게 겹침 없는 해법
  overflow 분리(body/sidebar 독립 스크롤)는 TOC active 추적 로직 복잡도 올림 → 채택 안 함

**재구축 힌트**:
- MCP 서버 재시작: Claude Code 재시작하면 ~/.claude.json에 등록된 parksy-webpage 자동 로드
- build_page 실행: `from page_service import build_page; html = build_page(text, page_type='article', title='...', source='whitepaper')`
- article_page.html 핵심 플레이스홀더: `{{SECTIONS_JSON}}`, `{{TITLE}}`, `{{uid}}`
- 섹션 구조: `[{"heading": "...", "body": "3~5문장", "highlight": "**키워드** — 강조"}]`
- 다음 작업: landing_page 타입 추가 테스트 / Railway HTTP 포팅 준비
---

### 2026-04-30 | Parksy Air 파이프라인 구조적 버그 3종 수정 + action_mapper 전면 재설계
**작업**:
- `extractor.py`: CSS 셀렉터 스코프 `.reveal .slides section.present` → `div.slide.active` (termux-bridge 실제 DOM 구조 대응)
- `action_mapper.py`: claude CLI subprocess 방식 전면 폐기 → playwright DOM query_selector 방식으로 재작성
- `orchestrator.py`: generate_tts_batch() audio_dir 절대경로 보장 (subprocess CWD 불일치 수정) + P0.6 asyncio.wait_for(120초) 타임아웃 추가
- 커밋: `b5afce4` (bug 3종 수정), `e6b917d` (action_mapper DOM 방식 전환)
- 브랜치: `claude/style-engine-phase1`

**결정**:
- claude CLI subprocess는 Claude Code 세션 내에서 실행하면 **전부 20초 타임아웃** (내부 인증 충돌). 병렬화(ThreadPoolExecutor), 타임아웃 조정 전부 무의미. 방식 자체를 버려야 함.
- DOM 직접 쿼리로 전환: `_SELECTOR_PRIORITY` 리스트 순서대로 `div.slide.active {sel}` 탐지. 슬라이드당 < 300ms.
- orchestrator에서 P0.6 전체를 120초 hard limit으로 감쌈 → P0.6 실패해도 파이프라인 계속.

**결과**:
- 풀런 339초(5분 40초) 완료. P0.6: 29/29 매핑 성공. 텔레그램 전송 완료.
- 기존: P0.6에서 매번 20초×39회 타임아웃 → 5분 후 프로세스 전체 kill.
- 현재 확정 실행 명령: `python3 orchestrator.py --url "https://dtslib1979.github.io/termux-bridge/slides/" --script-mode simple --skip-tts`

**교훈**:
- Claude Code 세션 안에서 `subprocess.run([claude, '--print', ...])` 호출 금지. 항상 타임아웃.
- termux-bridge 슬라이드는 reveal.js 아님. DOM 구조: `div.slide.active` 내부.
- GPT-SoVITS subprocess: CWD 상속 보장 안 됨 → `Path.resolve()` 절대경로 필수.

**재구축 힌트**:
- `tools/web2video/orchestrator.py --script-mode simple --skip-tts` 로 풀런 (~6분)
- action_mapper.py는 playwright DOM 방식. claude CLI 의존성 없음.
- 슬라이드 URL: `https://dtslib1979.github.io/termux-bridge/slides/`
- P4 YouTube 업로드 미제작 상태 (upload_youtube.py 완성 필요)
---

---
### 2026-04-30 | Parksy Air 파이프라인 프로세스 순서 변경: P1↔P2 스왑
**작업**: orchestrator.py의 P1(영상 녹화)↔P2(TTS 생성) 순서를 뒤집음.
- Before: P0→P0.6→**P1(녹화)**→**P2(TTS)**→P3 (역순, A/V 싱크 불가)
- After: P0→P0.6→**P2(TTS)**→**P2.5(durationSec 업데이트)**→**P1(녹화)**→P3 (정순, 싱크 보장)
- P2.5 추가: ffprobe로 TTS 오디오 실측 길이 측정 → script[i]["durationSec"] = tts_dur + 0.4 → script.json 업데이트 → P1이 그 값으로 슬라이드 녹화 시간 결정

**결정**:
- 커뮤니티 리서치 선행 (PurpleOwl 사례 검증): "The video and audio tracks are the same length because they're both derived from the same timing data." — 이 패턴이 업계 표준.
- narractive(PyPI) 라이브러리보다 기존 파이프라인에 순서 변경이 더 빠름.
- 0.4초 여유: 슬라이드 전환 애니메이션 시간 보정.

**결과**:
- 구조적 A/V 싱크 보장. renderer.py의 tpad freeze frame 패치 불필요.
- skip_tts 모드에서는 기존 4.6초 기본값 유지 (하위 호환).
- 최종 목표: 기업 IT 튜토리얼 영상 자동 생성기 (화면 클릭 + 성우 완전 싱크).

**교훈**:
- P2를 P1보다 먼저 실행해야 한다는 원칙은 커뮤니티에서 검증된 패턴 (PurpleOwl, narractive).
- TTS 길이 = 단일 진실 소스(Single Source of Truth). 영상이 오디오에 맞춰야지, 오디오가 영상에 맞추면 안 됨.

**재구축 힌트**:
- orchestrator.py: P2 블록이 P1 블록보다 먼저 나와야 함.
- P2.5: `ffprobe -v quiet -show_entries format=duration -of csv=p=0 step_NN.wav` → float → +0.4 → durationSec
- P1 Extractor는 script의 durationSec을 읽어 슬라이드당 녹화 시간 결정.
---

---
### 2026-04-30 | scene JSON 강화 — teaching_goal + pause_after
**작업**: script_generator.py에 _teaching_goal() + _pause_after_ms() 추가. extractor.py에서 pause_after 처리.
**결정**: Perplexity 백서 권고 중 즉시 적용 가능한 2개 필드만 선별. 나머지(selector fallback, 다국어) 보류.
**결과**: 스모크 테스트 통과. 4.4s TTS + 1.0s pause → 슬라이드당 학습 리듬 확보. 텔레그램 전송 확인.
**교훈**: pause_after는 ms로 저장, extractor에서 /1000으로 초 변환. TTS 길이와 별개로 화면 정지 시간 독립 제어.
---

---
### 2026-04-30 | BUG-008 CONCAT 경로 버그 + BUG-009 test mode 판서 스킵 수정 — 파이프라인 완전 작동

**작업**:
1. CONCAT 버그(BUG-008) 근본 원인 추적 및 수정 (`orchestrator.py`)
   - 증거 수집: `dist/` 파일 전부 1874457B 동일 → 오프닝만 재인코딩되고 있었음
   - `ffprobe`: 최종 파일 10.083s = opening(10.042s)과 동일 → 강의 클립(8.044s) 누락 확정
   - 원인 분석: `concat_list.txt`가 `build/{ts}/` 안에 생성되는데 강의 경로가 `dist/parksy_air_...mp4` (상대경로)
     → ffmpeg가 `build/{ts}/dist/...`로 해석 → 파일 없음 → opening만 출력 → returncode 0 (무음 처리)
   - 1차 수정: `Path.resolve()`로 모든 경로 절대경로 변환
   - 2차 문제 발견: opening(1168×784 landscape, 24fps) vs lecture(1080×1920 portrait, 30fps) 해상도+fps 불일치
     → `filter_complex concat` 실패 ("Error reinitializing filters!")
   - 최종 수정: 2단계 방식
     - Step1: 각 클립 1080×1920/30fps/AAC44100Hz 정규화 (`-vf scale+pad+fps+setsar`)
     - Step2: `concat demuxer -c copy` (동일 스펙이므로 재인코딩 없음)
   - CONCAT 실패 시 stderr[-800:] 출력 추가 (디버깅 용이)

2. test mode P0.6 스킵(BUG-009) 수정 (`orchestrator.py`)
   - 원인: `if not test_mode:` 블록으로 P0.6 완전 스킵 → pointer_target 없음 → 판서 없음
   - 수정: test mode에서도 실행, timeout만 120초→45초로 단축

**결정**:
- concat demuxer vs filter_complex: filter_complex가 더 "우아"하지만 해상도 불일치에서 실패.
  2단계(정규화 → copy) 방식이 더 견고. opening이 ComfyUI에서 생성되어 항상 다른 스펙일 수 있음.
- opening_latest.mp4: 1168×784 landscape (2026-03-25 생성). 세로 포맷 재생성 필요하지만 지금은 정규화로 우회.
- concat 실패 시 fallback: 강의 영상만 전송 (opening 없이). 이전에는 opening만 전송되던 것보다 낫다.

**결과**:
- 최종 검증: 18.19s (opening 10s + lecture 8s) / 1080×1920 / 30fps / stereo AAC 44100Hz / 1.8MB
- Telegram 전송 완료 ✅
- P0.6: pointer_target 2/2개 매핑 (test mode에서도 판서 작동) ✅
- P2: GPT-SoVITS 박씨 AI 성우 2/2개 생성 ✅
- 총 소요: 108초

**교훈**:
- `concat_list.txt` 경로는 항상 절대경로 사용. concat 파일 위치 기준 상대경로가 되면 함정.
- opening 파일은 포맷 보장 안 됨 → 정규화 단계 필수 (해상도, fps, 샘플레이트 통일).
- ffmpeg concat 실패 시 returncode가 항상 non-zero가 아님 → 출력 파일 크기/duration도 검증 필요.
- test mode에서도 판서(P0.6) 실행해야 QC가 의미 있음.

**재구축 힌트**:
```bash
# 스모크 테스트 (항상 이걸 먼저)
cd /home/dtsli/parksy-image/tools/web2video
python3 orchestrator.py --url "https://dtslib1979.github.io/termux-bridge/slides/" \
  --test --script-mode simple --tts-preset natural

# 풀런 (스모크 통과 후)
python3 orchestrator.py --url "https://dtslib1979.github.io/termux-bridge/slides/" \
  --script-mode simple --tts-preset natural
```
- CONCAT: orchestrator.py `_abs()` 함수로 모든 경로 절대화, norm_dir에 정규화 후 copy concat
- P0.6: test mode timeout=45, full mode timeout=120
- 브랜치: `claude/style-engine-phase1`

**현재 파이프라인 확정 순서**:
P0(스크립트) → P0.6(Claude Vision 판서 싱크, 45/120s) → P2(GPT-SoVITS TTS) → P2.5(durationSec sync) → P1(Playwright CDP 녹화) → P3(렌더링) → CONCAT(정규화+copy) → Telegram

**미완 아키텍처 (다음 세션 착수 순서)**:
1. 인터랙티브 버튼 클릭: Claude in Chrome → 시나리오 JSON → Playwright 매크로 재생
2. 풀런 39슬라이드 테스트
3. P4 YouTube 업로드 (upload_youtube.py)
4. Video QC: Gemini 2.0 Flash로 A/V 싱크 자동 검증
---

---
### 2026-05-02 | Parksy Air 양산 라인 1라인 완성 — M0 + M1 통과
**작업**: 12시간 자율실행 — 4개 트랙 진단 + 리팩토링 마스터 플랜 + P0~P4 응급수술 + E2E 풀런 + YouTube 자동 업로드
**결정**: 진단 결과 절반은 잘못된 정보였음 — action_mapper, GPT-SoVITS 디폴트, voice_filter v2 모두 이미 작동 중. 새 컴포넌트 작성보다 "연결" 정리가 본질이었음. SoVITS=박씨 본인 더빙 / Chatterbox=다국어 성우 / DiffSinger=가창·가상악기 (박씨 직접 정정). 영어 부분은 Whisper가 못 잡음 → Chatterbox 통합이 다음 단계.
**결과**:
- M0 (12:00): https://youtu.be/XBjdwZ00YRg — 베이스라인 1.9MB / 18.56s
- M1 (12:15): https://youtu.be/7rLw67cfB_o — 풀런 4.8MB / 2분 10초 / 25분 13초 빌드
- Layer2 한국어 CER 평균 22% (매우양호 38% / 양호 28%)
- step 24 CER 0% (완벽 — "PC를 서버로 만든다 이게 다야")
- 판서 29/29 매핑 (.cover-title, h2.slide-title, .card-title)
- 커밋: f3061e6 → efbf1ac → f807d71
**교훈**: 코드 직접 보기 전엔 외부 LLM 평가(Perplexity 포함)도 60% 신뢰도. 기존 시스템이 이미 거의 다 작동 중일 때는 베이스라인 빌드 1회로 검증 우선. tts_engine.py가 ~/parksy-audio/scripts/에 있고 orchestrator가 자동 import (실패 시 edge-tts fallback) — 이미 작동 중인 디폴트를 바꾸려고 시간 쓰지 말 것.
**재구축 힌트**: 양산 라인 1라인 흐름 = (1) mcp_slide_builder build_page() → docs/slides/article_xxx.html → (2) orchestrator --url ".../article_xxx.html?mode=slide" → P0/P0.5/P2/P2.5/P1/P3/P3.7/P4 → (3) Telegram + YouTube. article_page.html에 ?mode=slide URL 파라미터 처리 추가 (헤더/TOC/푸터 자동 숨김), action_mapper 셀렉터에 양쪽 형식 지원 (.art-hero-title, h2.art-heading 등). upload_youtube.py는 youtube-studio.js subprocess 래퍼이며 channels.json에서 채널별 토큰 자동 갱신.

**신규 파일**:
- tools/youtube/upload_youtube.py (Python 래퍼)
- tools/web2video/subtitle_generator.py (script.json → SRT)
- _queue/REFACTORING_MASTER_PLAN.md (5 Phase 로드맵)
- samples/test_numbers_squared_cubed.py (numbers.py stdlib 충돌 해결)
- (termux-bridge) ParksyLog_20260502_ParksyAir_양산라인_M1통과.md

**수정 파일**:
- tools/web2video/orchestrator.py (P3.7 자막 통합, P4 import path)
- tools/web2video/audio_qc.py (한국어 _cer + _detect_lang + run_layer2 다국어)
- tools/web2video/action_mapper.py (양쪽 슬라이드 셀렉터 + h1/h2/p fallback)
- tools/mcp_slide_builder/templates/article_page.html (?mode=slide 처리)

**다음 펜딩**:
- Chatterbox 다국어 통합 (영어 부분 박씨 한국식 발음 못 잡힘)
- step_15, 16 CER 60%+ 음성 디그레이드 원인 분석
- step_27 길이 비율 3.03 — Layer1 fail 케이스 처리
- Phase 2 인터랙티브 깊이 (코드 실행 영역, 다음 단계 CTA, 변수 입력)
- Phase 3 28레포 manifest.yaml + 배치 빌드
---
