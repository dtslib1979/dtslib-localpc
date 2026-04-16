# 세션 개발일지 — 2026-04-16 (수)

## 작업 요약

### 1. 시스템 헬스체크
- Tailscale ✅ / ADB ✅ / 폰 SSH ✅ / 탭 SSH ✅
- Vast.ai 인스턴스 없음 (학습 완료 상태)
- 5-Lane: phone_claude/phone_aider만 실행 중 (tab_claude/tab_aider 미생성)

---

### 2. 폰 Termux → D드라이브 시즌제 이전

**목적:** 폰 로컬 Termux 자료를 PC로 백업, 이후 ADB 중심으로 전환

**완료:**
- 시즌제 아카이브 구조 생성: `/mnt/d/PARKSY/termux-archive/Season1_2026Q1/`
- Termux 홈 디렉토리 전체 SCP로 이전 (`.bashrc`, `.bash_history`, `projects/` 등)
- `SEASON1_README.md` 작성 (이력 기록)

**결과:** 폰 Termux 5.2GB → 19MB 슬림화 완료

**보존 항목 (삭제 금지):**
- `~/.ssh/` — SSH 키 (authorized_keys 포함)
- `~/.termux/` — Termux 설정
- `~/storage/` 심볼릭 링크
- adb-watchdog, start-*-claude 실행 스크립트

---

### 3. 폰 갤러리/오디오 정리

**삼성 갤러리 휴지통 삭제:**
- 경로: `~/storage/shared/Android/data/com.sec.android.gallery3d/files/.Trash/`
- ADB로 확인 후 SSH로 삭제 완료

**Screen recordings 삭제:**
- `~/storage/shared/DCIM/Screen recordings/` (공백 포함 경로)
- `rm -rf ~/storage/shared/DCIM/Screen\ recordings` 로 성공

**통화 녹음 정리:**
- 보존: 어머니/요양병원 관련 통화 (식별 후 제외)
- 삭제: 마이스터모터스(자동차부품) 관련 2개, 번호만 있는 짧은 파일

---

### 4. phoneparis 브랜치 분기 해결

**문제:** 폰에서 작업한 커밋 5개가 PC보다 앞서있어 push 실패

**해결:**
- 폰의 변경 파일 5개 SCP로 PC 직접 복사
- PC에서 병합 커밋: `sync: 폰 Termux 브랜치 병합`
- `git push origin master` 성공

**변경된 파일:**
- `app.js`, `index.html`, `package.json` 등 phoneparis 웹앱 파일

---

### 5. Perplexity API 설정 및 조사

**목적:** Perplexity를 코드에서 자동 호출 (리서치 자동화)

**계정:** dtslib1979@gmail.com (Perplexity Pro 구독 중, ₩29,000/월)

**완료:**
- `console.perplexity.ai` 로그인 (Google OAuth)
- API 그룹 생성: `parksy-main` (ID: `6d811e96-9f9d-45a8-b5db-a3a05140ac49`)
- 국가: South Korea / Tax ID: N/A

**결론:**
- Pro 구독 $5 크레딧 → **매월 구독 갱신일에 자동 충전됨**
- 현재 잔액 $0 → API 키 생성 버튼 비활성화 상태
- 별도 $50 충전 불필요 — 다음 갱신일까지 대기

**API 가격 참고:**
- `sonar` : $1/1M tokens (기본 검색)
- `sonar-pro` : $3/1M tokens (심층 검색)
- `sonar-reasoning` : $5/1M tokens (추론 포함)
- $5/월로 수백~수천 건 리서치 가능

---

### 6. 다음 작업 결정 (이번 세션 미완)

**방향: 2-Track 병행**

| Track | 방식 | 상태 |
|-------|------|------|
| A | Playwright 웹 자동화 (perplexity.ai UI 정찰) | 다음 진행 예정 |
| B | API 키 방식 (sonar 모델 직접 호출) | 다음 갱신일 후 키 발급 |

**Track A 계획:**
- perplexity.ai 주요 셀렉터 정찰 및 저장
- 반복 리서치용 Python 스크립트 생성
- 재사용 가능한 `perplexity_search.py` 작성

---

## 펜딩 이슈 (이월)

| # | 항목 | 레포 | 우선순위 |
|---|------|------|---------|
| 1 | termux-bridge 미커밋 로그 3개 | termux-bridge | 중 |
| 2 | papafly .gitignore 커밋 | papafly | 하 |
| 3 | REAPER default.rpp (Keyzone Piano) | 로컬 | 중 |
| 4 | tab_claude / tab_aider 세션 생성 | localpc | 중 |
| 5 | Perplexity Playwright 셀렉터 저장 | parksy-image | 상 |
| 6 | Perplexity API 키 발급 | console.perplexity.ai | 상 (갱신일 후) |

---

## 기술 메모

### Perplexity API 구조
```
perplexity.ai (구독) ≠ console.perplexity.ai (API)
- 웹앱: Pro 구독 → 무제한 검색 (웹브라우저 사용)
- API 콘솔: 별도 크레딧 (Pro 구독자 $5/월 자동 충전)
- perplexity.ai/settings/api → console.perplexity.ai 리다이렉트 (동일 시스템)
```

### 폰 Termux 최소 유지 목록
```
~/.ssh/           # 절대 삭제 금지
~/.termux/        # 폰 환경 설정
~/bin/            # adb-watchdog, start-*-claude 스크립트
~/.bashrc         # PATH, alias 설정
```
