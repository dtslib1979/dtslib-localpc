# dtslib-papyrus — 세션 로그

---

### 2026-03-18 | 전 플랫폼 자동화 완료 + 전략 확정

**작업**:
- Playwright MCP symlink 수정 (snap stub → ms-playwright chromium)
- 네이버 login.cjs v2.0: channel:'chrome' → executablePath 직접 지정
- 네이버 dtslib ✅ NID_AUT/NID_SES 추출 (persistent context 기존 세션)
- 네이버 eae_kr ✅ NID_AUT/NID_SES 추출 (persistent context 기존 세션)
- 네이버 parksy_kr ❌ 기기 신뢰 차단 → 태블릿 직접 사용으로 결정
- 티스토리 5계정 ✅ _state.json 전부 저장 (parksy_kr/eae_kr/dtslib/dtslib1k/dtslib2k)
- YouTube OAuth 4계정 ✅ token_a/b/c/d.json refresh_token 확보
- dev-log 020, 021 작성

**결정**:
- parksy_kr 네이버: 자동화 포기 → 태블릿 직접 (기기 신뢰 이슈)
- 네이버는 카페 확장성 목적, 우선순위 낮음 (HTML 미지원 → 텍스트 포스팅만)
- 티스토리 25개 블로그: parksy-image 웹툰 뷰어 SCM 연동 (이미지 레포 중심)
- YouTube 최우선 ✅

**결과**:
- 쿠키 추출: 네이버 2/3, 티스토리 5/5
- YouTube OAuth: 4/4
- 플랫폼 자동화 준비 완료율: ~80%

**교훈**:
- 네이버 persistent context: 기존 세션 있는 계정만 자동 통과. 신규는 기기 신뢰 차단.
- Playwright MCP snap chromium stub 문제: `/usr/bin/chromium-browser`를 ms-playwright로 symlink 교체 필요 (2순위 도구 사용 전 확인)
- 자동화 안 되면 막히지 말고 대안(태블릿 직접) 바로 선택

**재구축 힌트**:
- 네이버 쿠키: `node tools/naver/login.cjs dtslib` → `tools/naver/accounts/cookies/dtslib.json`
- 티스토리 세션: `python3 tools/tistory/login.py` → `tools/tistory/cookies/*_state.json`
- YouTube token: `node tools/youtube/yt_oauth_auto.cjs` (a/b/c/d 각각)

---
