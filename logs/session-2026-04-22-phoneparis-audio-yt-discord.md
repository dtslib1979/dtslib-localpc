# phoneparis 개발 세션 — 2026-04-22

## 작업 범위
P6 DIRECT 패키지 / phoneparis 레포

## 완료 항목

### 1. YouTube RSS 피드 교체
- `#discord-feed` 섹션 → `#yt-feed` 로 교체
- 채널 ID: `UCOvHKAfWYYUQKPunZIjOQbg` (@phoneparis-r6q)
- api.rss2json.com CORS 프록시 → 최신 영상 6개 카드 렌더링
- 현재 업로드 영상 없음 → "아직 업로드된 영상이 없습니다" fallback 표시

### 2. 오디오 플레이리스트 전면 교체
**Before:** 기도문 계열 7곡 (SF2 샐러맨더/Samsung 녹취 혼합)
**After:** 5트랙으로 단일화
```
01 — Chopin Nocturne Op.9 No.1   (BBC SO · REAPER 렌더)
02 — Debussy — Clair de Lune     (BBC SO · REAPER 렌더)
03 — Liszt — Consolation No.3    (BBC SO · REAPER 렌더)
04 — Lord's Prayer (EN)          (AI 성우 · Chatterbox 음성 클론)
05 — 주기도문 (KO)                (AI 성우 · broadcast 모드)
```

### 3. AI 성우 샘플 파일 추가
- 폰 `/sdcard/Music/Telegram/` 에서 ADB pull
- `pater_raw.wav` (RMS 0.094972, 24.7s) → `ai-narration-en.m4a` 변환
- `pater_broadcast.wav` (RMS 0.171605, 24.7s) → `ai-narration-ko.m4a` 변환
- assets/audio/ 에 배치

### 4. 052 설계도 파트 구성 원위치
- 문의(discord-contact) 섹션이 Footer로 밀려난 것 발견
- 052 가드레일 (커밋 24a4327) 기준: PART5 직후 → EPILOGUE 앞
- 원위치 복원 완료

### 5. Discord 위젯 확인
- WidgetBot 서버 입장 확인 (2026-04-21 착륙)
- embed: `https://e.widgetbot.io/channels/1493490911278272655/1493491698838536202`
- 공식 Discord Widget 설정 불필요 — WidgetBot은 bot 초대만으로 작동

## 진행률
65% 완료

### 완료된 섹션
- HERO (랜딩 + 슬로건) ✅
- PART1 그래프 지도 (파리 구역 인터랙티브) ✅
- PART2 제품 3종 (Music/Page/Phone) — 카드 구조 ✅
- PART3 오디오 플레이어 (BBC SO 3곡 + AI 성우 2개) ✅
- PART4 YouTube RSS 피드 (채널 영상 대기 중) ✅
- PART5 실시간 Discord 채팅 (WidgetBot) ✅
- 문의 섹션 (Discord Webhook) ✅
- EPILOGUE (여정·구역·팀) ✅

### 미완료
- PART3 이미지 갤러리 — manifest.json 실제 이미지 미입력
- YouTube 채널 첫 영상 업로드 (외부 작업)
- Paris Edition 결제 플로우 (문의 앵커 연결)
- PWA service worker 검증

## 스캐폴드 판정 (세션 말미 대화)

**Q: 스캐폴드 역할 했냐? Discord + GitHub Pages + YouTube 연결된 홈페이지 생태계 맞냐?**

맞다. 85% 완성.

| 채널 | 상태 |
|------|------|
| GitHub Pages (phoneparis.kr) | ✅ 라이브 |
| Discord 실시간 채팅 (WidgetBot) | ✅ 작동 — 실제 문의 수신 확인 |
| Discord Webhook 문의폼 | ✅ 작동 |
| YouTube RSS 피드 | ✅ 파이프 연결, 영상 0개 대기 |
| 오디오 플레이어 | ✅ 5트랙 |
| 파리 구역 인터랙티브 맵 | ✅ |

파이프는 다 연결됐다. YouTube 채널에 영상 올라오면 RSS 섹션 자동 채워짐.
나머지 15% = 이미지 갤러리 콘텐츠 + 결제 앵커.

**Q: 이 설정 다른 사이트에도 재사용 가능하도록 설정집 만들어놨냐?**

아니다. phoneparis = 레퍼런스 구현체. 설정집은 없음.
다음 사이트 착수할 때 동시에 만드는 게 낫다 — 그때 실제로 뭐가 필요한지 정확히 보임.
변수는 4개: GUILD_ID / CHANNEL_ID / YT_CHANNEL_ID / WEBHOOK_URL.
justino 레포에 보일러플레이트로 박을 것 (다음 사이트 착수 시).

---

## 커밋 이력 (이번 세션)
```
fa0eeac fix: 문의 섹션 052 설계도 원위치 복원 — PART5 직후, EPILOGUE 앞
40559ce fix: 구 7곡 정적 플레이어 제거, BBC SO 3곡+AI 성우 2개로 단일화
62b5620 feat: 오디오 플레이리스트 교체 — BBC SO 3곡 + AI 더빙 2개
0e3babf feat: Discord 공지 피드 → YouTube RSS 피드 교체
93425e6 style: 바텀 시트 다크 테마 + 문의 섹션 실시간 채팅 하단 이동
```

---

## 2차 작업 — OrbitPrompt 일괄 작업 (2026-04-22 후반)

### 완료 커밋: fdf9a94

### 1. PHL 인터랙티브 제너레이터 3개
- `phl/PHL-Expansion.html` — 모듈 확장/견고화 (적용 범위 체크박스, 프롬프트 생성, 복사)
- `phl/PHL-Hardening.html` — 보안 하드닝 (6개 점검 항목 선택형)
- `phl/PHL-Reverse.html` — 역방향 검증 (정역 일관성 테스트 포커스)
- 각 페이지: [복사] 버튼 + 스펙 접이식 하단 표시

### 2. philosopher-parksy RSS 섹션 신설
- 채널 ID: `UCJaGuXjxoNjFMqfYUSFjZVg`
- api.rss2json.com CORS 프록시 → 최신 영상 6개 카드
- fallback: "아직 업로드된 영상이 없습니다"

### 3. index.html 스튜디오 저널 표지 개편
- HERO: "도구 쇼케이스" → "철학자가 되어가는 과정"
- 스튜디오 저널 섹션 신설 (최근 세션 로그 3개 인라인)
- PHL 섹션: PHL-1/2/3 카드 → Expansion/Hardening/Reverse Generator 링크로 교체
- NAV에 "저널" 링크 추가

### 라이브 URL
- https://dtslib1979.github.io/OrbitPrompt/
- https://dtslib1979.github.io/OrbitPrompt/phl/PHL-Expansion.html
- https://dtslib1979.github.io/OrbitPrompt/phl/PHL-Hardening.html
- https://dtslib1979.github.io/OrbitPrompt/phl/PHL-Reverse.html
