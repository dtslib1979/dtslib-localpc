# 021 — 인프라 공백 A~H 실행 분류 (2026-04-20)

> 중간 점검(`dtslib-papyrus/infra-history/17_MIDPOINT_CHECK_20260420.md`)에서 식별된 공백을
> **박씨 물리 개입 필요 여부**로 분류한 실행 계획.

---

## 분류 원칙

- **🟢 원격 가능 (재부팅 불필요)** — 박씨는 폰으로 지시/승인만
- **🟡 원격 재부팅 가능** — `shutdown /r` 트리거, 박씨 PC 앞 불필요
- **🔴 PC 앞 물리 작업 필수** — BIOS/F12/microSD 등 손으로 해야 함

---

## 🟢 원격 가능 (9개)

| # | 항목 | 소요 | 비고 |
|---|------|-----|------|
| 1 | F: `DEEPSEEK_API_KEY` `.bashrc` 추가 | 1분 | 박씨가 키값만 전달하면 끝 |
| 2 | E: watchdog.sh 파일 존재 가드 추가 | 5분 | image bot 무한루프(3,979회 누적) 즉시 정지 |
| 3 | Task Scheduler `WSL-SSHD-AutoStart` 중복 삭제 | 1분 | 실패 태스크 (LastTaskResult=4294967295) |
| 4 | watchdog.sh 중복 프로세스 1개 kill | 30초 | pts/11 + pts/21 두 개 돌고 있음 |
| 5 | 17번 중간점검 문서 git 커밋/푸시 | 2분 | `dtslib-papyrus/infra-history/17_*` |
| 6 | B: watchdog에 텔레그램 알림 훅 | 20분 | 복구/장애 시 폰 푸시. 기존 봇 토큰 재활용 |
| 7 | C: 폰/태블릿 레인 역할 규칙 메모리화 | 15분 | 박씨 운영 규약 → `project_lane_rules.md` |
| 8 | D: Win11 ↔ WSL 상호 치료 치트시트 | 30분 | `infra-history/18_MUTUAL_RECOVERY.md` 예정 |
| 9 | A 설정 변경 (wuauserv/Active Hours/Metered 3중) | 10분 | powershell 레지스트리 원격 수정 |

**합계**: 약 85분. 박씨 폰 지시 5분 + 관제탑 자율 80분.

---

## 🟡 원격 재부팅 검증 (2개)

| # | 항목 | 방법 |
|---|------|------|
| 10 | A 검증 — wuauserv 설정 재부팅 후 유지 | 폰에서 `powershell.exe shutdown /r /t 60` → 5분 후 재접속 확인 |
| 11 | H — 4/17 이후 server.log 공백 원인 조사 | 위 재부팅 시 `tail -f ~/server.log` 스트림 관찰 |

**합계**: 재부팅 1회 (심야 추천). 박씨 PC 앞 불필요.

---

## 🔴 PC 앞 물리 작업 (1개)

| # | 항목 | 물리 필요 이유 |
|---|------|---------------|
| 12 | G: WTG 재부팅 테스트 | F12 부팅 메뉴, microSD 삽입 확인, Tailscale 최초 로그인 |

**합계**: 박씨 집 방문 1회.

---

## 📊 요약 비율

```
원격 가능 (재부팅 없이):   9개  (75.0%)
원격 재부팅으로 검증:       2개  (16.7%)
PC 앞 물리 필수:           1개  ( 8.3%)
─────────────────────────────
합계:                     12개  (100%)

박씨 폰에서 처리 가능: 11/12 = 91.7%
```

---

## 추천 실행 순서

### Phase 1 — 박씨 폰 지시 (5분)
- [ ] F 키값 전달
- [ ] E 처리 옵션 결정 (권장: (ii) watchdog 가드)
- [ ] 17번 문서 git 커밋 OK
- [ ] A(wuauserv) 즉시 적용 OK

### Phase 2 — 관제탑 자율 실행 (80분)
- [ ] 순서: F → Task Scheduler 삭제 → watchdog 중복 kill → E 가드 추가 → A 3중 설정 → B 알림 훅 → 17번 커밋 → C/D 문서화

### Phase 3 — 원격 재부팅 검증 (심야)
- [ ] `shutdown /r /t 60` 트리거
- [ ] 재접속까지 스톱워치 (SLA 측정)
- [ ] server.log 흐름 관찰

### Phase 4 — 집 방문 (별도 일정)
- [ ] WTG 재부팅 테스트

---

## 진행 상태 (업데이트 필드)

| # | 항목 | 상태 | 완료 시각 |
|---|------|-----|----------|
| 1 | F | ✅ 완료 | 2026-04-20 12:05 (DEEPSEEK_API_KEY .bashrc 등록, 현재 셸 반영) |
| 2 | E | ✅ 완료 | 2026-04-20 12:07 (파일 존재 가드 추가, 재기동 후 70초간 재시작 0회 검증) |
| 3 | Task Scheduler 삭제 | ✅ 완료 | 2026-04-20 12:05 (`WSL-SSHD-AutoStart` Unregister, WSL_Init/WSL_SSHD 2개만 남음) |
| 4 | watchdog 중복 kill | ✅ 완료 | 2026-04-20 12:07 (root 프로세스 정리, dtsli로 단일 재기동) |
| 5 | 17번 커밋 (+ push) | ✅ 완료 | 2026-04-20 12:18 (papyrus/localpc/bridges 3개 push 완료) |
| 6 | B 텔레그램 훅 | ✅ 완료 | 2026-04-20 12:24 (notify_telegram 함수 + log_restart 확장 + 기동 알림) |
| 7 | C 레인 규칙 | ✅ 초안 완료 | 2026-04-20 12:26 (project_lane_rules.md, 박씨 보완 대기) |
| 8 | D 치트시트 | ✅ 완료 | 2026-04-20 12:26 (infra-history/18_MUTUAL_RECOVERY.md, 증상 A~J) |
| 9 | A 3중 방어 | ✅ 완료 | 2026-04-20 12:18 (wuauserv Disabled + NoAutoUpdate=1 + ActiveHours 0~23) |
| 10 | A 검증 재부팅 | ⏳ 대기 | — |
| 11 | H 로그 조사 | ⏳ 대기 | — |
| 12 | G WTG 테스트 | ⏳ 대기 | — |

완료 시 체크박스 + 시각 기록. Phase 2 종료 후 일괄 업데이트.

---

## 연관 문서

- 중간 점검: `dtslib-papyrus/infra-history/17_MIDPOINT_CHECK_20260420.md`
- 사건 원점: `~/.claude/projects/-home-dtsli/memory/project_kb5083769_origin.md`
- 로그 먼저 규칙: `~/.claude/projects/-home-dtsli/memory/feedback_server_log_first.md`
- 3일 포스트모템: `020-wtg-postmortem-model-matching-2026-04-18.md`

---

*작성: 2026-04-20 관제탑 Opus 세션*
*다음 액션: 박씨 Phase 1 결정 대기*
