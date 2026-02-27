# 사용 매뉴얼 — Control Tower 일상 운용법

> 대상: 박씨 (dtslib1979)
> 최종 갱신: 2026-02-28

---

## 1. 한 줄 요약

**평소엔 아무것도 안 해도 된다.** 각 레포에서 Claude 세션을 열면, CLAUDE.md가 자동으로 관제탑 경로를 알려준다.

---

## 2. 일상 사용 — 레포별 세션 열기

### 그냥 평소처럼 쓰면 된다

```
parksy-audio 작업 → D:\PARKSY\parksy-audio 에서 Claude 세션 열기
parksy-image 작업 → D:\parksy-image 에서 Claude 세션 열기
dtslib-apk-lab 작업 → D:\1_GITHUB\dtslib-apk-lab 에서 Claude 세션 열기
```

각 레포의 CLAUDE.md에 이미 이런 섹션이 들어있다:

```
## 크로스레포 연동 (Control Tower)
> 이 세션은 독립적이지 않다. 3개 프로덕션 레포가 하나의 PC에서 협업한다.
```

Claude가 다른 레포 정보가 필요하면 **알아서** `D:\PARKSY\dtslib-localpc\repos\status.json`을 읽는다.

### 언제 크로스레포가 작동하나?

| 상황 | Claude가 하는 일 |
|------|-----------------|
| parksy-audio에서 "YouTube 썸네일 필요" | parksy-image 경로 + 현황 참조 |
| parksy-image에서 "앨범 아트 의뢰 들어옴" | parksy-audio의 Phase/스코어 확인 |
| dtslib-apk-lab에서 "앱에 사운드 넣고 싶어" | parksy-audio 작업 디렉토리 참조 |
| 아무 레포에서 "D드라이브 구조 알려줘" | dtslib-localpc/drive-map/ 참조 |

---

## 3. 스냅샷 갱신 — 언제, 어떻게

### 자동으로 안 돈다. 필요할 때 직접 실행.

```powershell
powershell -ExecutionPolicy Bypass -File D:\PARKSY\dtslib-localpc\scripts\snapshot.ps1
```

### 이걸 언제 돌려야 하나?

| 상황 | 갱신 필요? |
|------|:----------:|
| 새 소프트웨어 설치했을 때 | O |
| D드라이브 폴더 구조 바꿨을 때 | O |
| 레포 큰 Phase 끝났을 때 | O |
| 평소 작업할 때 | X |
| Claude 세션 열 때마다 | X (불필요) |

### 갱신 + 자동 커밋/푸시까지 한번에

```powershell
powershell -ExecutionPolicy Bypass -File D:\PARKSY\dtslib-localpc\scripts\snapshot.ps1 -AutoCommit
```

이러면 스냅샷 수집 → git add → commit → push까지 원클릭.

---

## 4. 크로스레포 작업 패턴

### 패턴 A: "다른 레포 참조만"

예시: parksy-audio 세션에서 "parksy-image 지금 뭐 하고 있어?"

→ Claude가 `dtslib-localpc/repos/status.json`을 읽고 대답한다. 너는 아무것도 안 해도 됨.

### 패턴 B: "다른 레포 파일이 필요"

예시: parksy-image에서 "parksy-audio가 만든 MP3 갖고와서 썸네일 작업해"

→ Claude가 `D:\tmp\` (parksy-audio 작업 디렉토리) 경로를 알고 있으므로 파일을 찾아온다.

### 패턴 C: "두 레포 동시 수정"

예시: "dtslib-apk-lab 앱에 parksy-audio의 사운드 파일 넣어줘"

→ **하나의 세션에서 두 레포 모두 수정 가능.** 경로를 다 알고 있으니 크로스 작업이 된다.

> 단, 커밋은 각 레포에서 따로 해야 한다. 한 세션에서 두 레포를 동시에 `git push` 가능.

---

## 5. repos/status.json 수동 갱신

스냅샷 스크립트는 git status만 자동 수집한다. **Phase, 스코어, 큐** 같은 의미 있는 정보는 수동 갱신이 필요하다.

### 갱신 방법: 아무 Claude 세션에서

```
"dtslib-localpc의 status.json에서 parksy-audio Phase를 Phase 10으로 업데이트해줘"
```

Claude가 JSON 파일을 직접 수정하고 커밋한다.

### 또는: 해당 레포 세션 끝날 때

큰 작업이 끝나면 Claude에게:

```
"이번 작업 끝. 관제탑 status.json 갱신해줘"
```

---

## 6. 새 레포 추가하기

미래에 4번째 프로덕션 레포가 생기면:

1. `repos/status.json`에 새 레포 항목 추가
2. `repos/새레포.md` 상세 현황 파일 생성
3. 새 레포의 `CLAUDE.md`에 크로스레포 연동 섹션 추가
4. 기존 3개 레포의 형제 레포 테이블에 새 레포 추가
5. `CLAUDE.md` (관제탑)의 크로스레포 맵에 추가

Claude에게 "새 레포 XXX를 관제탑에 등록해줘"라고 하면 위 5단계를 자동으로 한다.

---

## 7. 중복 클론 방지 규칙

### Canonical 경로 (이것만 쓴다)

| 레포 | 경로 | 절대 여기서만 작업 |
|------|------|:------------------:|
| parksy-audio | `D:\PARKSY\parksy-audio` | O |
| parksy-image | `D:\parksy-image` | O |
| dtslib-apk-lab | `D:\1_GITHUB\dtslib-apk-lab` | O |
| dtslib-localpc | `D:\PARKSY\dtslib-localpc` | O |

### `D:\1_GITHUB\`는 뭐야?

`sync.bat`이 돌면 GitHub 20개 레포를 전부 클론하는 백업 폴더. **여기서 직접 작업하면 안 된다** (dtslib-apk-lab 제외 — 여기가 canonical).

---

## 8. 파일 찾기 가이드

| 뭘 찾고 싶으면 | 어디를 봐라 |
|----------------|------------|
| 3개 레포 현황 한눈에 | `repos/status.json` |
| 특정 레포 상세 | `repos/parksy-audio.md` 등 |
| D드라이브 폴더 구조 | `drive-map/structure.json` |
| GitHub 20개 레포 맵 | `drive-map/repo-map.json` |
| 설치된 소프트웨어 | `snapshots/installed-software.json` |
| 개발도구 버전 | `snapshots/env-versions.json` |
| PC 복원 가이드 | `env/RESTORE.md` |
| 중복 클론 정리 기록 | `drive-map/duplicates.md` |

---

## 9. 트러블슈팅

### "Claude가 다른 레포를 모르는 것 같아"

→ CLAUDE.md의 크로스레포 연동 섹션이 있는지 확인. 있으면 Claude에게 직접 말해:
```
"dtslib-localpc/repos/status.json 읽어봐"
```

### "status.json이 옛날 정보야"

→ 스냅샷 갱신 실행:
```powershell
powershell -ExecutionPolicy Bypass -File D:\PARKSY\dtslib-localpc\scripts\snapshot.ps1 -AutoCommit
```

### "새 PC로 옮겼는데 다 날아갔어"

→ `env/RESTORE.md` 따라하면 됨. Phase 0~6 순서대로.

### "D드라이브에 모르는 폴더가 있어"

→ `drive-map/structure.json` 확인. 없으면 스냅샷 갱신해서 `snapshots/drive-d.txt` 확인.

---

## 10. 하지 말아야 할 것

| 하지 마라 | 이유 |
|-----------|------|
| `D:\1_GITHUB\`에서 직접 코드 수정 | sync.bat이 덮어씀 |
| status.json을 직접 텍스트 에디터로 수정 | JSON 깨질 수 있음, Claude에게 시켜 |
| 같은 레포를 여러 폴더에 클론 | 중복 지옥 재발 |
| snapshot.ps1을 매번 세션마다 실행 | 불필요, 큰 변경 있을 때만 |
| _SYSTEM 폴더 삭제 | sync.bat, dashboard 아직 거기 있음 |

---

*이 매뉴얼은 dtslib-localpc Control Tower v2.0 기준입니다.*
