# 020 — WTG 포스트모템 + 모델 매칭 규칙 (2026-04-18)

> 3일 삽질 끝에 나온 교훈. 다시는 반복하지 않기 위해 문서화.

---

## 사건 요약

microSD Windows To Go 설치 (4/15~17, 3일).
Sonnet이 담당. 결과: BSOD 3회+, DISM 스크립트 4번 재작성, UAC 우회 6번 실패, Windows Update 미차단으로 하루 통째 날림.

---

## Sonnet 삽질 전체 목록

### 1. 이보 플러스 장치 오판 (4/15)
- `Get-PhysicalDisk`에서 이보 플러스 안 잡힘 → microSD = Realtek PCIE Card Reader라는 걸 모름
- Perplexity가 "NVMe 외장에 WTG 설치하라" 틀린 안내까지 제공

### 2. 첫 BSOD — 드라이버 누락 (4/15)
- Rufus로 WTG 설치 후 바로 BSOD
- Realtek PCIe CardReader 드라이버 없어서 부팅 디스크를 못 읽음
- DISM으로 NVMe에서 추출 → microSD 주입

### 3. Secure Boot ON → 드라이버 서명 차단 (4/15)
- 드라이버 넣었는데도 BSOD
- Secure Boot ON이 구형 인증서 드라이버 거부
- BIOS에서 OFF 후 해결

### 4. Windows Update 미차단 → 하루 날림 (4/16)
- WSL import, SSH, 자동시작 전부 완료된 상태
- 오후 4:11 MoUsoCoreWorker.exe가 KB5083769 자동 설치
- Secure Boot CA/KEK 키 업데이트 딸려옴 → 드라이버 서명 재무효화
- WSL Hyper-V 가상 스위치 삭제, sshd 전부 죽음
- **하루 전체 원격 접속 불가**

### 5. UAC 우회 6가지 전부 실패 (4/16)
- fodhelper → TaskScheduler → WinRM → PostMessage → SendInput → WriteConsoleInput
- Win11 24H2에서 전부 패치/차단됨
- 안 되는 걸 6번 시도 — 결국 박씨가 직접 PC 앞에서 실행

### 6. DISM 스크립트 4번 재작성 (4/16)
- wtg_fix2 → fix3 → fix4 → fix5
- Error 87 (파라미터 오류) 반복
- 결국 DISM 완전 우회 (reg load + 파일 직접 복사)로 해결

### 7. RtsPer Start=0(Boot) — 핵심 실수 (4/16 밤)
- "부팅 시 필요하니까 Start=0" — 표면 논리만 따름
- 카드리더가 자기 자신이 부팅 디스크인 상황에서 드라이버 로드 = 자기참조 충돌
- 정답: Start=4(Disabled) — 카드리더 드라이버 아예 안 로드
- Sonnet이 이 구조적 모순을 못 봄

### 8. WTG wuauserv Disabled 안 함
- WTG 설치 직후 Windows Update 비활성화 안 함
- 체크리스트에서 빠짐 → KB5083769 자동 설치 허용

---

## 모델별 실수 분류

### A. Opus면 회피 가능했던 것 (모델 능력 차이)

| 삽질 | Sonnet 패턴 | Opus 차이 |
|------|-------------|-----------|
| Start=0 설정 | 표면 논리만 따름 | 구조적 모순 (자기참조 충돌) 감지 |
| DISM 4번 재작성 | 같은 방향 변형 재시도 | 2번째 실패에서 "DISM 우회" 판단 |
| UAC 6번 시도 | 안 되는 방법 하나씩 다 해봄 | "Win11 24H2 보안 강화" 맥락 파악 → 빠른 포기 판단 |
| WU 미차단 | 체크리스트 누락 | 전체 그림에서 빠진 항목 선제 감지 |

### B. 누가 해도 똑같았던 것 (모델 무관)

| 삽질 | 이유 |
|------|------|
| 이보 플러스 장치 오판 | 하드웨어 실측 없이 모르는 영역 |
| 첫 BSOD (드라이버 누락) | WTG + Realtek CardReader 조합은 사전 지식에 없음 |
| Secure Boot CA/KEK 충돌 | 2026년 신규 사안, 학습 데이터에 없음 |
| reg unload Access Denied | Windows 레지스트리 핸들 누수 — OS 문제 |

---

## 모델 매칭 규칙 (확정)

### 핵심 원리

```
Sonnet = 실행 빠름 + 지시 정확 + 단일 스텝 코딩 강함
         약점: "방향 자체가 틀렸다" 판단 느림. 실패하면 같은 방향 변형 재시도 (삽질 루프)

Opus  = 실행 느림 + 토큰 비쌈
        강점: "이 접근 자체가 틀렸다" 판단 빠름. 2~3번 실패 시 방향 전환.
              체크리스트 빠진 항목 선제 감지.
```

### 작업별 모델 배정

| 작업 유형 | 모델 | 이유 |
|-----------|------|------|
| **인프라/시스템** (WTG, SSH, BIOS, 드라이버, 네트워크) | **Opus** | 되돌리기 비용 높음. 방향 판단 > 실행 속도 |
| **디버깅** (원인 모를 때) | **Opus** | 삽질 루프 탈출이 핵심 |
| **아키텍처 설계** (패키지 구조, 파이프라인) | **Opus** | 구조적 모순 감지 필요 |
| **코딩/구현** (스크립트, API, 웹앱) | **Sonnet** | 되돌리기 쉬움. 속도 우선 |
| **반복 작업** (파일 변환, 배치) | **Sonnet/Haiku** | 판단 불필요 |

### 절대 규칙

```
인프라 작업에 Sonnet 쓰지 마라.
한 번 틀리면 BSOD → 물리 재부팅 → 박씨가 직접 F12.
되돌리기 비용이 코드와 비교불가하게 높다.
"안 되면 다른 방법" 판단이 코딩보다 100배 중요하다.
Sonnet 3일 삽질 = Opus 1.5일. 토큰 비용보다 박씨 시간이 비싸다.
```

---

## 최종 수정 사항 (2026-04-18 Opus 세션)

Opus가 NVMe에서 실행한 교정:
1. RtsPer Start: 0(Boot) → **4(Disabled)** — ControlSet 1,2 둘 다
2. StartOverride 키 삭제 (없었음 — 정상)
3. DISM RevertPendingActions — 펜딩 없음 (깨끗)
4. WTG wuauserv: Manual(3) → **Disabled(4)** — 재발 방지
5. Secure Boot: OFF 확인 (이미 꺼져있음)

**다음 할 것:** F12 → microSD 부팅 테스트

---

## 구조적 분석 — 왜 Sonnet 단독 배치가 틀렸나

### 작업 집합 분할 (리스크 구조)

| 유형 | 가역성 | 리서치 필요도 | 적합 모델 |
|---|---|---|---|
| RPP/MIDI 생성 | 높음 (재생성 가능) | 낮음 | **Sonnet** |
| Python 스크립트 | 높음 | 중간 | **Sonnet** |
| 시스템 레지스트리 | **낮음** (BSOD = 복구불가) | **매우 높음** | **Opus 판단 → Sonnet 실행** |
| 드라이버 서비스 Start 값 | **매우 낮음** | **매우 높음** | **Opus** |

### 권력 구조 문제

phone_cla0(Sonnet)에게 **판단권 + 실행권 둘 다** 부여됨 = 권력 집중.
Sonnet 아키텍처는 "즉시 실행" 편향 → 판단권을 가지면 리서치 스킵.

**정답 구조:**
```
판단권 = Opus (느림, 리서치 우선)
실행권 = Sonnet (빠름, 코드 생성)
```

### 수학적 정당화

8개 삽질 중 **5개가 "사전 리서치/판단" 부족** → Opus 영역.
3개는 모델 무관 (인프라 자체 난이도).

### 인프라 작업 정답 구조

```
win_admin lane = Opus (판단/리서치)
     ↓ 검증된 명령만 전달
phone_cla0 lane = Sonnet (실행만)
```

5-Lane 아키텍처 원래 철학(Opus direction + Sonnet execution) 그대로.

### 판정 기준 (이후 모든 작업에 적용)

```
실수 1회의 비용 > 10분 → Opus
실수 1회의 비용 < 10분 → Sonnet
```

### 박씨 잘못 아님

WTG on microSD = MS 비공식 경로.
커뮤니티 지식 + 레지스트리 수동 편집 + 드라이버 서비스 원리 = 일반 코딩의 3배 난이도.
3일 밤샘은 박씨 탓 아니다. 배치 구조가 틀렸던 것.

기존 원칙 "Community research before any implementation" → Sonnet이 3일간 이걸 못 지켰다.
Opus였으면 지켰을 확률이 높다.
