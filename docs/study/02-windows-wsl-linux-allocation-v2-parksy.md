# Windows / WSL2 / 순정 Linux 작업 배치 백서 v2 — Parksy 전용 (dtslib 5-Lane 기준)

> v1(범용 사용자 기준)을 dtslib 실제 인프라로 재배치. 일반론 → 박씨 시스템 문서로 전환.
> 평가: v1 종합 6.5/10 (구조 9 / 사실정확성 7 / 박씨 적합도 0)

---

## 0. v1 대비 변경점

| 항목 | v1 (범용) | v2 (박씨 전용) |
|------|-----------|----------------|
| Codomain | {Windows, WSL2, Linux} 3원소 | {Windows(REAPER 성역), WSL2 5-Lane(본진), Dell XPS 상시서버, OUKITEL/Termux 센서노드} 4원소 |
| USB/시리얼 | "구조적 제약" | usbipd-win으로 조건부 가능. 단 OUKITEL은 Termux 직결이라 무관 — RTL-SDR은 애초에 별도 노드 |
| 음악 작업 | "DAW = GUI 성역" | REAPER = GUI 성역이지만 RPP 텍스트 템플릿 생성으로 이미 포위됨 (parksy-audio) |
| AI 자동화 | 일반론 | DiffSinger/RVC/Park-LoRA/Vast.ai 파이프라인 구체 반영 |
| 자동화 본진 | "WSL2" 단일체 | tmux 4세션(tab_claude/tab_aider/phone_claude/phone_aider) + Tailscale 메쉬로 위치 무관 접속 |
| 철학 | 클릭 최소화 (일반 선호) | 클릭 최소화 = Foucault적 권력 재배치(벤더 GUI→자기 스크립트), 기능인 정체성과 직결 |

---

## 1. 핵심 가설 (박씨 버전)

원래 가설: "STT+AI 에이전트 시대엔 일부 작업이 GUI에서 텍스트/터미널로 회귀한다."

박씨 사례는 이 가설의 **검증된 사례**다. 일반 사용자는 여전히 가설 단계지만, dtslib는 이미 실증 완료:

- **REAPER(DAW, 본질적으로 GUI 영역)** → `.RTrackTemplate` 1회 수동 등록 후, RPP 텍스트 직접 생성으로 매 렌더마다 GUI 클릭 없이 트랙/VSTi/이펙트 삽입. recmode=5 → Play+Record(action 1013) → sox RMS 검증 → Telegram 자동 배달까지 완전 무클릭 파이프라인.
- **보컬 합성(원래 인간 가수가 필요한 영역)** → DiffSinger+RVC(index_rate=0.75)+postchain.sh로 텍스트/MIDI 입력만으로 완성.
- **바순 가상악기(샘플 라이브러리+인간 연주가 필요한 영역)** → DDSP 학습 시도 후 VSCO-2-CE sfz 직접 파싱으로 귀결 — 단, 이 경우는 **회귀 실패 사례**: kill rule(3축 점수 <6.0) 적용해 GUI/샘플 기반으로 후퇴. 모든 GUI 영역이 텍스트화되는 건 아니라는 v1의 경고가 여기서 실증됨.

**결론**: 가설은 "조건부 참"이다. 자동화 가능 여부는 ROI와 반복 횟수에 달림 — REAPER 렌더는 수백 번 반복되니 텍스트화할 가치가 있었고, 바순 합성은 1회성 비교 실험이라 GUI/샘플 직행이 효율적이었다.

---

## 2. Codomain 재정의 — dtslib 4노드 구조

### Windows (성역, 최소화 대상)

- REAPER GUI 자체 조작 (플러그인 UI, 믹서) — RPP 자동생성으로 이미 70% 이상 우회됨
- RustDesk 필요한 GUI 전용 작업 (Dell XPS 9370 원격 제어시)

### WSL2 5-Lane (본진)

- tmux 세션: tab_claude / tab_aider / phone_claude / phone_aider + win_admin
- DeepSeek Aider 실행 (ANTHROPIC_BASE_URL 리다이렉트로 비용 절감)
- parksy-audio 파이프라인 오케스트레이션 (RPP 생성, sox 검증, Telegram 배달)
- Park-LoRA 데이터 전처리, MCP(parksy-scm) 구동
- Instagram 자동화(instagrapi) 등 Python 스크립트 본진

### Dell XPS 13 9370 (상시 서버)

- BIOS AC 자동복구 + AutoAdminLogon, Windows Update 차단 — 24/7 운영 전용
- wsl-autostart.vbs로 WSL 자동기동 (기존 92/93 성공률)
- 모든 자동화 노드의 SSH 진입점 (포트 2222)

### OUKITEL WP35 Pro / Termux (센서 노드)

- RTL-SDR V4 + 단파 안테나, 화면 없는 가방 휴대 운용
- Termux + ADB + Tailscale + 센서 APK만 — USB/시리얼 직결이라 usbipd-win 논의 자체가 무관 (애초에 Windows를 거치지 않음)

---

## 3. 통합 배치표 (dtslib 실사용 기준)

| 작업 | Windows | WSL2 5-Lane | Dell XPS 서버 | OUKITEL/Termux |
|------|---------|-------------|---------------|----------------|
| **REAPER 렌더링** | GUI 1회 템플릿 등록만 | RPP 텍스트 생성·자동 트리거 본진 | 야간 배치 렌더 가능 | — |
| **DiffSinger/RVC 보컬합성** | — | 전처리·후처리 스크립트 | Vast.ai 트리거용 SSH 진입점 | — |
| **Park-LoRA 학습 데이터** | — | STT 수집·정제 (Interview mode) | — | 통화녹음 STT 수집 |
| **Instagram 자동화(instagrapi)** | — | 본진 (v2.0 개발 중) | 24/7 스케줄 실행 후보 | — |
| **RTL-SDR 단파 수신** | — | — | — | 메인 (화면 없이 백그라운드) |
| **Telegram 결과 배달** | — | 본진 | 무중단 대기 | — |
| **MCP(parksy-scm) 실행** | — | 본진, episode_runner.py | npu_gate 통합 후 상주 후보 | — |
| **GitHub OS 28레포 관리** | 보조 | 본진 | — | — |

---

## 4. 학자 매핑 (구조 해석)

- **Lévi-Strauss(구조-집합)**: v1의 터미널/GUI 이항대립은 dtslib에서 무너짐. REAPER는 형식상 GUI 집합 원소이지만 RPP 텍스트로 이미 침식됨 — "포위된 성역"이라는 4번째 범주 필요.
- **Foucault(권력-그래프)**: 클릭 최소화는 단순 선호가 아니라 권력 재배치. 벤더가 쥔 GUI 통제권을 자신의 스크립트·MCP 레이어로 회수하는 행위. parksy-scm을 "구조적 강제 메커니즘"으로 정의한 것과 동일 원리.
- **Nietzsche(의지-연산자)**: 박씨는 코드를 짜는 자가 아니라 의지를 연산자로 변환해 에이전트(Claude/DeepSeek/Aider)에 위임하는 자 — "기능인" 정체성의 수학적 정의.
- **Eco(기호-함수)**: 백서 자체, 그리고 OrbitPrompt의 "20년 판단력의 외재화" 같은 표현은 conscious plagiarism을 정당화하는 기호-함수로 작동.

---

## 5. 미해결 항목 (Issue #11 연동)

GitHub Issue #11에 남아있는 3개 물리 검증 항목은 이 배치표의 신뢰도에 직결됨:

1. **폰 리붓 체인 검증** — phone_claude/phone_aider 세션이 Dell XPS 재부팅 후에도 자동 복구되는지
2. **Termius MSYS2 경로 설정** — Windows lane 진입 안정성
3. **`--dangerously-skip-permissions` 플래그** — 자동생성 Claude Code 세션 보안/편의 트레이드오프 결정 필요

이 셋이 닫히기 전까지 "Dell XPS 상시서버" 노드의 가용성은 92/93(약 98.9%)이 상한선이며, 100% 무인 운영을 전제로 한 배치(예: 야간 배치 렌더, 24/7 Instagram 스케줄)는 보수적으로 잡아야 함.

---

## 6. 결론

v1의 구조 프레임(3층 분류, GUI vs 텍스트 회귀 가설)은 일반론으로서 타당하다. 그러나 dtslib는 이미 그 일반론의 "다음 단계" — 실증 사례이자, 동시에 일부 영역(바순 DDSP)에서는 가설의 한계를 보여주는 반례 보유자다. v2의 핵심은 단일 OS 비교가 아니라 4노드(Windows/WSL2/Dell서버/Termux) + ROI 기반 자동화 임계값으로 배치를 재정의하는 것이며, kill rule(<6.0 → GUI 후퇴)처럼 "회귀가 항상 정답은 아니다"를 명시적 판단 기준으로 갖고 있다는 점이 v1과의 근본적 차이다.
