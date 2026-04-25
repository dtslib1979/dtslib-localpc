# 박씨 5개월 발전 회고 (2025-12 ~ 2026-04)

> 작성일: 2026-04-25 KST
> 작성자: Claude Code (Opus 4.7)
> 데이터 소스: 메모리 99파일 + 28레포 git log 5,800+ 커밋
> 요청사항: 솔직 평가, 칭찬 금지

---

## 요약 한 줄 평가 (정직)

**인프라/방송국/물성화 레포 5,800커밋으로 "텅 빈 GitHub → 28레포 운영 체제"는 진짜 만들었지만, GPU/AI 학습 영역에서는 같은 패턴(시도→데이터부족→폐기→피벗)을 6회 반복하면서 약 $50~$100과 12+ 세션을 태웠다. 절반 발전, 절반 삽질의 혼합이다.**

---

## 월별 시계열

### 2025-12 (시작점 — 거의 텅 비어있음)

**출발 상태**
- GitHub 레포 단 4개: parksy.kr(8월), eae.kr(10월), OrbitPrompt(12-02), dtslib.kr(12-02)
- 12월에 새로 만든 레포: dtslib-apk-lab(12-13), parksy-logs(12-14), parksy-image(12-19), dtslib-papyrus(12-24)
- 박씨가 비개발자 1인 출판사/방송국 컨셉을 처음 정리하기 시작한 시기

**핵심 시도**
- ParksyLog 로그 양산 (12-30~31, parksy-logs 143 커밋 — 거의 다 STT 대화 로그 자동 처리)
- dtslib-papyrus는 12-24 생성 후 12월에 단 2 커밋 (vercel.json만 추가)

**성공한 것**
- 로그 적재 자동화(`chore: process logs for RAG [skip ci]`) 가동 — 박씨 STT 발화가 RAG 데이터로 흐르기 시작
- 7패키지 맵의 "씨앗" 단계: GitHub Pages용 도메인 레포 4개 확보

**실패/폐기**
- 없음 (아직 시도 자체가 적음)

**펜딩**
- 7패키지 중 5개는 12월에는 존재조차 안 함

---

### 2026-01 (대폭발 — 인프라 일제 시작)

**핵심 시도 (커밋 폭주)**
- dtslib-papyrus: 119 커밋. WordPress 테마, 컨트롤 센터, 28레포 매핑 시작
- dtslib-apk-lab: **349 커밋** (가장 많음) — APK 실험 본격화
- parksy-logs: 150 커밋 (RAG 로그 계속)
- hoyadang.com: 260 커밋, phoneparis: 193 커밋, eae-univ: 120 커밋
- 1월에 새로 만든 레포: papafly(1-8), phoneparis(1-8), koosy(1-14), parksy-audio(1-18), eae-univ(1-20), dtslib-localpc(1-20), artrew(1-22), hoyadang(1-26)

**성공한 것**
- 7패키지의 ~80% 레포 골격 완성 (BROADCAST/KNOWLEDGE/PHYSICAL/DIRECT/BRANCH 전부 1월에 셋업)
- WordPress dtslib.com 컨트롤 (dev-log 009 — "100/100 점수")
- Tasker 자동화 아키텍처
- GitHub repos × Tistory 15블로그 × YouTube 8채널 컨트롤 센터

**실패/폐기**
- (이 시기는 거의 다 셋업이라 폐기랄 게 없음)

**펜딩**
- APK 빌드 라인 — 1월에 349커밋 시작했으나 4월 현재 0 커밋 (완전 정지)

---

### 2026-02 (콘텐츠 파이프라인 + Lyria + 텔레그램 봇)

**핵심 시도**
- dtslib-papyrus: 177 커밋 — Telegram dispatcher + ADB 자동재생 + PersistentClaudeSession + WAN2.1 I2V 파이프라인
- parksy-image: **111 커밋** — 4플랫폼 배포 파이프라인(네이버/티스토리/인스타/유튜브) + compose 10/10 + 서사 추출 엔진
- parksy-audio: **106 커밋** — Lyria 3 워크플로우 + Musician TV 5-Program + faure/franck 풀 사이클 클래식 렌더
- dtslib-apk-lab: 253 커밋 (계속 활발)

**성공한 것**
- ParksyComposer 모듈러 시스템 v2.0
- Telegram book_bot dispatcher 초안 (28레포 ↔ 28봇 매핑 컨셉 구체화)
- Lyria 3 Gemini 통합 (BGM/소재 5종 입고)
- WAN 2.1 I2V — 정공법 파이프라인 코드 작성

**실패/폐기 (시작됨)**
- BotFather 밴 — 23개 book_bot 생성 중 차단 (2026-04-01까지 펜딩으로 끌림)

**펜딩**
- WAN 2.1 워크플로우 — 코드는 됐지만 RunPod 가입 미완료로 실행 못 함

---

### 2026-03 (GPU/AI 학습 본격화 + 첫 폐기 사이클)

**핵심 시도**
- dtslib-papyrus: 195 커밋 — RunPod GPU Factory v3.0, A100 80GB + 70B 베이스 모델, P1-LLM/P1-RVC/P2-ComfyUI 3프로젝트
- dtslib-apk-lab: 206 커밋 — ComfyUI Colab 배치 파이프라인 (3-28에서 멈춤, 그 후 0)
- parksy-audio: 82 커밋 — REAPER+VSTi 본격, BBC SO 삽질, Salamander Grand Piano V3, Musician TV 풀 인터랙티브
- dtslib-localpc: 96 커밋 — Control Tower v2.0, win-gui MCP, 헌법 v6.0 PC 메인 패러다임 전환

**성공한 것**
- YouTube OAuth 4계정 + Tistory 5계정 자동화 완성
- channel-repo-map.json SSOT 확정 (15채널 × 담당레포)
- 헌법 v6.0 + 7패키지 맵 광역 적용
- win-gui MCP TCP 데몬 (REAPER GUI 자동화 진입로)
- Treasure Map v2 (Obsidian-style force-directed 노드)

**실패/폐기 (이 시기에 본격적으로 시작)**
- BBC SO 오프라인 렌더 action 42230 → -91dB 무음 확정 → "해결 불가, 시도 금지" 결론
- BBC SO 헤드리스 렌더 → 불가 확정 → loopMIDI + Play+Record로 전환
- BASSOON_DS DiffSinger → DiffSinger 악기 사례 0건 확증 → DDSP로 피벗 (3-30 메모리)
- VSTi 좌표 기반 자동화 → 폐기 → .RTrackTemplate 템플릿 기반으로 전환 (4-01)

**펜딩**
- p1b 성우 학습 — RunPod 계정 네트워크 차단 발견 (3-31~4-02)

---

### 2026-04 (현재 — 인프라 안정화 + GPU 영역 대수술)

**핵심 시도 (4-01~4-25)**
- dtslib-papyrus: 176 커밋 — 후반부엔 1커밋만 push됨, 대부분 push 아닌 로컬일 가능성
- parksy-logs: 98 커밋, parksy-image: 48 커밋, OrbitPrompt: 23 커밋 (재정의), phoneparis: 24 커밋, papafly: 67 커밋
- dtslib-branch: 29 커밋 (인큐베이터 사용법 추가)
- alexandria-sanctuary: 19 커밋 (MCP Railway 배포 — "헌법 예외" 선언)

**성공한 것 (4월 라이브로 돌아가는 것)**
- p1b 성우 AI v1 완성 (4-03): GPT-SoVITS S1+S2 학습, inference 4.9초 WAV, RMS 0.067, 박씨 컨펌 OK ($0.50)
- DDSP PyTorch 자작 트레이너 (TF 전부 실패, torch 2.1+cu121로 우회) — step ~1900에서 중단했지만 작동
- PARKSY_EN v3 학습 (step 14000/20000, 노래 30분 포함)
- alexandria-therapy MCP Railway 배포 (4-24)
- phoneparis STEP 3 완료 (BBC SO 7곡 + AI 성우 2개 + Paris Edition 3-product, git push 대기)
- 5-Lane MCP+DeepSeek 아키텍처 가동 (phone_claude/phone_aider/tab_claude/tab_aider)
- mcp-semicon 21파일 EAE MCP 시리즈 (4-17)

**실패/폐기 (이 시기 가장 많음)**
- LLM 파인튜닝: ep1/ep3 완료했지만 **Together Tier 1 차단**, **Vast.ai 베이스 미스매치**, **$46 정산** → 4-13 "LLM 파인튜닝 피벗 확정 — 메인은 박씨 라이브"로 사실상 보류
- RunPod On-Demand Pod runtime null 반복 (3090/4090/A40 전부 실패 4-04)
- 바순 AI 폐기 확정 (4-11): RAVE 데이터 부족(35분<1시간) + 변환 한계 → VSCO-2-CE 모노포닉 SFZ로 후퇴
- 클라우드 서버 영구 포기 (4-18 feedback): Oracle/GCP/AWS 전부 접음. PC→서버 전환도 금지
- PWA/APK 폐기 근거 확립 (4-18 FAB 컴퓨트 아키텍처): 저장=GitHub/CDN, 연산=Railway MCP, GPU=Vast.ai만
- WTG (Windows To Go) 응급 부팅 환경: KB5083769로 INACCESSIBLE_BOOT_DEVICE 재발 (4-17 펜딩, 4-20까지 미해결)

**펜딩 (4월 끝나가는데 안 끝난 것)**
- 성우 모델 HF 업로드 (4-18): parksy_ko_v1.onnx + ddsp_bassoon.pt 로컬 확인, 블로커 = `huggingface-cli login`
- Railway 502 외부 접근 미해결 (4-18): EXPOSE/ASGI/host 전부 시도, Deploy Logs 스크린샷 대기
- Vertex AI A100 DiffSinger (4-06): gcloud auth 비번 미확인으로 중단
- 5번 위젯 = 경량 윈도우 SSD 환경 연결로 교체 예정
- p1b v2 재학습 (Phase 2 — 데이터 정제 후 재학습 $0.50, 미실행)
- BotFather 밴은 4-01 해제 후 어떻게 됐는지 추적 불명

---

## 패키지별 5개월 누적 발전

| 패키지 | 12월 상태 | 4월 상태 | 발전 (1~10) | 이유 |
|---|---|---|:--:|---|
| P1 INFRA (termux+localpc+image+audio+phoneparis) | 4개 중 1개만 존재(image) | 5개 전부 운영, 5-Lane 가동, MCP 골격 | **8** | 진짜 인프라 완성. 4월에도 활발 |
| P2 YOUTUBE (15채널) | 채널 매핑 0% | OAuth 4계정+playlist 26/48+channel-repo-map.json SSOT | **7** | SSOT/자동화 완성, 콘텐츠 양산은 검증 안 됨 |
| P3 BROADCAST (parksy.kr+eae.kr+dtslib.kr) | 도메인만 | 4월에도 youtube-cache 루프백 등 살아있음 | **6** | 라이브 사이트 3개. 단 4월 커밋 4개에 불과 |
| P4 KNOWLEDGE (OrbitPrompt+eae-univ+parksy-logs) | OrbitPrompt 12-02만 | 4-22 "스튜디오/과정저널" 재정의 — 정체성 흔들림 | **6** | 인프라는 됐는데 "정의 자체"가 4월에 또 바뀜 |
| P5 PHYSICAL (hoyadang+gohsy계열) | 0 | hoyadang 라이브, gohsy 75 커밋 | **5** | 사이트는 있는데 4월 활동 없음 |
| P6 DIRECT (artrew+justino+espiritu+alexandria+phoneparis) | 0 | 5개 다 만들어짐. alexandria만 4월에 활발(MCP) | **6** | 만들어졌지만 매장 가동 검증은 별개 |
| P7 BRANCH (branch+koosy+papafly+namoneygoal+gohsy+buckleychang) | 0 | 5개 다 있음. dtslib-branch 4월 29커밋 — 인큐베이터 사용법 | **6** | 골격 OK, "친구 육성" 실제 작동은 미증명 |

**가중평균: 약 6.3/10 — "골격은 다 짰는데 운영 검증은 절반"**

---

## 진짜 완성된 것 (라이브) — 자랑할 수 있는 것

1. **5-Lane MCP+DeepSeek 아키텍처** — phone_claude / phone_aider / tab_claude / tab_aider 4세션 가동 중
2. **GPT-SoVITS 박씨 성우 v1** — inference 작동, $0.50 비용으로 v1 확보, 박씨 청취 컨펌
3. **win-gui MCP + REAPER 자동화** — BBC SO Play+Record 파이프라인 (오프라인 렌더는 포기, 정공법 채택)
4. **YouTube OAuth 4계정 + Tistory 5계정 자동화** — 실제 작동 확인
5. **channel-repo-map.json SSOT** — 15채널 × 담당레포 매핑 완결
6. **alexandria-therapy MCP Railway 배포** — 멀티 디바이스 접근 가능
7. **헌법 v6.0 + 7패키지 맵** — 작업 분류 체계로 작동 중
8. **3-Layer MCP 개발법** (4-24) — UUID/FileLock/서비스분리 동시성 방어 합의
9. **Control Tower v2.0 (dtslib-localpc)** — 크로스레포 관제탑 운영
10. **Treasure Map v2** — force-directed 노드 랜딩 페이지

---

## 폐기/전환된 것 — 삽질 또는 학습

| 시도 | 결과 | 비용/시간 | 학습 가치 |
|---|---|---|---|
| BBC SO 오프라인 렌더 (action 42230) | -91dB 무음. 해결 불가 확정 | 3월 다수 세션 | "시도 금지" 룰로 박제됨 ✅ |
| BBC SO 헤드리스 렌더 | 불가 확정 → loopMIDI + Play+Record 전환 | 3월 | 정공법 확보 ✅ |
| VSTi 좌표 기반 자동화 | 폐기 → .RTrackTemplate으로 전환 | 3월 후반 | 템플릿 기반이 정답 ✅ |
| BASSOON_DS DiffSinger 학습 | DiffSinger 악기 사례 0건 → DDSP 피벗 | Vast.ai $0.21/hr | "보컬 전용/악기 전용" 룰 ✅ |
| 바순 AI (RAVE) | 데이터 부족(35분<1시간) → VSCO-2-CE SFZ | 4-11 폐기 | "1시간 미만 학습 금지" 학습 |
| LLM 파인튜닝 | Together Tier 1 차단, Vast.ai 베이스 미스매치 | **$46** | 박씨 라이브로 피벗 |
| RunPod On-Demand Pod | 3090/4090/A40 전부 runtime null | 4-04 다수 | Vast.ai로 전향 ✅ |
| 클라우드 서버 (Oracle/GCP/AWS) | 영구 포기 선언 | 누적 다수 세션 | "FAB 컴퓨트 아키텍처" 확립 ✅ |
| PWA/APK 마이그레이션 | 폐기 근거 확립 | 1~3월 dtslib-apk-lab 800+커밋 후 정지 | 가장 큰 매몰 비용 — APK 4월 0커밋 |
| Vertex AI A100 DiffSinger | gcloud auth 미해결로 중단 | 4-06 | 펜딩 |

**총 폐기 비용 추정: $50~$100 + 12세션 이상 + APK 빌드 800+ 커밋 매몰**

---

## 같은 실수 반복 패턴 (가장 솔직한 부분)

### 패턴 1 — "GPU 학습 시도 → 데이터 부족 또는 인프라 차단 → 폐기/피벗" (6회 반복)

1. BASSOON_DS DiffSinger → 사례 0건 → DDSP로 피벗
2. RAVE 바순 → 35분 데이터 부족 → SFZ로 후퇴
3. LLM 파인튜닝 ep1/ep3 → Tier 차단 → 보류
4. RunPod On-Demand → runtime null → Vast.ai로 전향
5. Vertex AI A100 → auth 미해결 → 펜딩
6. p1b v2 재학습 → 데이터 정제 후 재학습 인지했지만 미실행

**근본 원인**: 코드 작성 능력 vs 데이터 수집/정제 능력 불균형. 박씨 메모리에도 `feedback_community_first_baseline.md` (2026-04-02 — $5 낭비 계기로 "커뮤니티 리서치 우선"이 1조)로 박혀 있는데, 그 후로도 비슷한 패턴 4번 더 반복.

### 패턴 2 — "정의/아키텍처 재정의" 반복

- OrbitPrompt: 12월 생성 → 4-22 "스튜디오/과정저널" 근본 재정의
- VSTi 아키텍처 v1(좌표) → v2(템플릿) → v3(BBC SO 폐기, SWAM 나중)
- 헌법 v6.0 (3월) → FAB 컴퓨트 아키텍처(4-18) → 사실상 헌법 일부 갈아엎음
- "PC 메인" (3월) → "PC 다운그레이드, 클라우드 앱스토어" (4월)

**원인**: 박씨 자기 정의 = "만트라/고스트" 구조 + "나선형 확장" — 산만해 보여도 다 연결된다는 박씨 신념. 다만 외부에서 보면 "또 갈아엎음".

### 패턴 3 — "착수만 하고 닫지 않음"

- 시작만 한 펜딩이 메모리 인덱스에 16건 (2026-04 시점):
  - BotFather 밴 (4-01 해제 후 추적 불명)
  - HF 모델 업로드 (블로커: login 명령어 한 줄)
  - Railway 502 (스크린샷 대기)
  - Vertex AI gcloud auth 비번
  - APK→PWA 마이그레이션 (1월 시작, 4월 0커밋)
  - WTG INACCESSIBLE_BOOT_DEVICE 재발
  - 5번 위젯 교체
  - dtslib-papyrus 4-22 amazing_grace .ustx 7항목 튜닝 (OAuth 401로 중단)

**원인**: 1단계 블로커 발생 시 우회 안 하고 다른 트랙으로 이동. STT 입력 특성상 "다음 주제"로 빠르게 넘어감.

### 패턴 4 — "인프라 작업 모델 미스매치"

`feedback_infra_model_matching.md` (4-18)에 본인이 적음: **"인프라 작업 Sonnet 단독 금지. 실수 비용>10분→Opus. WTG 3일 삽질 교훈."**
→ 그런데 4-20 `feedback_server_log_first.md`에 다시 "외부 리서치 전 server.log 먼저"가 또 등장. 같은 교훈 다른 표현.

---

## 펜딩 누적 (시작만 하고 못 끝낸 것 — 16건)

1. APK→PWA 마이그레이션 (1월 349커밋 → 4월 0커밋)
2. BotFather 밴 후 23개 book_bot 재개 (4-01 해제 후 미확인)
3. 성우 모델 HF 업로드 (블로커: login 한 줄)
4. Railway 502 외부 접근 (Deploy Logs 스크린샷 대기)
5. Vertex AI A100 DiffSinger (gcloud 비번)
6. WTG KB5083769 재발 (DISM 드라이버 재주입)
7. 5번 위젯 교체 (경량 윈도우 SSD 환경)
8. p1b v2 재학습 ($0.50, Phase 2)
9. amazing_grace .ustx 7항목 튜닝 (OAuth 401)
10. BASSOON 후속 RAVE 1시간+ 데이터 수집
11. REAPER default.rpp 생성 (Keyzone Piano)
12. 펜딩 — 화면 분할 + ADB 동시 사용 스터디
13. parksy.kr/eae.kr 4월 커밋 2개씩만 — 콘텐츠 운영 멈춤
14. hoyadang.com 4월 0커밋 — 운영 정지
15. dtslib-apk-lab 4월 0커밋 — 800+ 커밋 후 매몰
16. Together Tier 2 ($50) 대기 — LLM 학습 재개 조건

---

## 박씨 인프라 진화 6단계 매핑

(박씨 6단계: 모바일버스 → ADB → GPU 클라우드화 → MCP래퍼 → PC 다운그레이드 → 클라우드 앱스토어)

| 월 | 단계 | 근거 |
|---|---|---|
| **2025-12** | **1단계 (모바일버스)** | parksy-logs RAG 적재 시작, STT 입력 흐름 확립 |
| **2026-01** | **1→2단계 (ADB 진입)** | dtslib-apk-lab 349커밋, Tasker 자동화, 28레포 컨트롤 센터 |
| **2026-02** | **2단계 (ADB) 완성기** | Telegram dispatcher 28봇, ADB 자동재생, PersistentClaudeSession |
| **2026-03** | **3단계 (GPU 클라우드화)** | RunPod GPU Factory v3.0, A100 70B, P1-LLM/P1-RVC/P2-ComfyUI 3프로젝트 |
| **2026-04 전반** | **3→4단계 (MCP 래퍼)** | mcp-semicon 21파일, alexandria-therapy MCP Railway, 5-Lane MCP+DeepSeek |
| **2026-04 후반** | **4→5단계 (PC 다운그레이드 선언)** | "FAB 컴퓨트 아키텍처" — CapEx 제로, PWA/APK 폐기, "클라우드 서버 영구 포기" |

**진단**: 5개월 안에 1→4.5단계까지 갔다. 단계 진행은 **빠르지만**, 각 단계의 매몰 비용을 정리 안 하고 다음 단계로 점프함 (APK 800커밋, LLM $46, BBC SO 다수 세션). 6단계(클라우드 앱스토어)는 아직 컨셉 단계.

---

## 5개월 결론 (Claude의 솔직 평가)

### 돈값 했는지

**Max 5x 요금제 5개월 ≈ $1,000 (추정)**. 그 대신 받은 것:
- GitHub 28레포 운영 체제 (12월 4개 → 4월 28개)
- 5,800+ 커밋 (대부분 박씨 STT + Claude 협업 산물)
- p1b 박씨 음성 모델 v1 (실제 작동, $0.50)
- 5-Lane 모바일 작업 환경 (이동 중에도 코딩 가능)
- 박씨 자체 헌법/7패키지 맵 (작업 분류 SSOT)
- 폐기 학습 10건 — 비싼 수업료지만 박제됨

**돈값 측면: 가성비 6/10.** "혼자 할 때보다 5배 빠름"은 사실이지만, "10x" 또는 "방송국 수익 시작"까지는 아직.

### 어디가 부족했는지

1. **데이터 수집 일을 코드보다 뒤에 둠** — DiffSinger/RAVE/LLM 전부 데이터 부족이 폐기 원인. 코드 짜기 전에 1시간 데이터 모으기를 안 함.

2. **블로커 1개 = 전체 정지** — `huggingface-cli login` 한 줄, gcloud 비번, Deploy Logs 스크린샷 같은 30초 작업이 며칠~몇 주 펜딩.

3. **착수 비율 vs 마감 비율 = 약 3:1** — 5개월간 "새 컨셉 시작"이 마감보다 3배 많음.

4. **Sonnet 단독 인프라 금지 룰 위반 반복** — 본인이 적은 룰을 본인이 1주 후에 또 어김 (4-18 → 4-20 같은 패턴).

5. **방송국 수익화는 0** — YouTube 15채널 인프라는 됐는데 실제 업로드/수익 데이터가 메모리에 없음. parksy.kr/eae.kr 4월 커밋 2개씩.

### 다음 5개월 어디 집중해야 하는지 (Claude의 직설)

**우선순위 1 — 펜딩 16건 중 30분짜리 것 6개 정리** (HF login, Railway 로그 확인, gcloud 비번, BotFather 상태 확인 등). 각각 30분이면 끝나는 것이 1~3주 펜딩.

**우선순위 2 — "새 시도 시작 금지" 1개월** (5월). 이미 시작한 것 마감만. 매몰 비용 회수 모드.

**우선순위 3 — 방송국 콘텐츠 실제 업로드 검증**. 인프라(OAuth 4계정, channel-repo-map.json)는 됐는데 그걸로 실제 영상이 올라가는지 데이터가 없음. 4월에 parksy.kr/eae.kr 거의 멈춤 = 위험 신호.

**우선순위 4 — GPU 학습은 "데이터 1시간 이상 + 커뮤니티 사례 1건 이상" 게이트 통과 후만**. 본인이 4-02에 적은 community-first baseline 룰을 진짜로 지킬 것.

**우선순위 5 — APK 빌드 라인 명시적으로 닫기**. 1월 349커밋 후 정지 상태인데 "폐기" 선언이 없음. dtslib-apk-lab 레포에 ARCHIVED 표시 필요.

### 한 줄 회고

**박씨는 "발산"은 90점, "수렴"은 30점이다. 5개월간 30개 트랙을 동시에 열어서 6개를 끝까지 갔고, 16개는 펜딩, 8개는 폐기했다. 다음 5개월은 발산을 멈추고 펜딩 16개를 닫는 데 써야 한다.**
