# 018 — XPS 13 9370 스토리지 아키텍처 재설계 연구
**날짜:** 2026-04-12
**세션 유형:** 리서치 + 설계
**관련 장비:** Dell XPS 13 9370, Samsung microSD 512GB (Tab S9에서 이전)

---

## 배경

C: 드라이브 85% 포화 (392G/461G). Tab S9에서 사용하던 512GB microSD를 PC SD카드 슬롯에 이전. 이를 활용한 스토리지 재구조화 방안 탐색.

---

## 현재 드라이브 현황

| 드라이브 | 레이블 | 타입 | 용량 | 여유 | 비고 |
|----------|--------|------|------|------|------|
| C: (NVMe) | OS | Samsung PM981a | 512GB | 70GB (15%) | Windows + WSL VHDX (141GB) |
| D: | My Passport | WD USB HDD | 2TB | 1.3TB (70%) | 데이터 창고 |
| E: | WIP SSD | Samsung microSD | 512GB | 379GB (74%) | SD카드 슬롯, 태블릿에서 이전 |

**E: 드라이브 식별 결과:**
- `Model: SDXC Card / MediaType: Removable Media / BusType: SCSI`
- XPS 9370 내장 Realtek PCIe SD카드 슬롯에 연결됨

---

## 커뮤니티 리서치 요약

### WSL VHDX를 microSD에 올리는 것 — 불가
- exFAT → NTFS 변환 필요
- Removable 타입 → Hyper-V가 VHDX 거부 (`0x80070299`)
- sleep/resume 중 VHDX 부패 위험

### XPS 9370 SD카드 부팅 — 가능
- BIOS에 **"SD Card Boot" 옵션 명시적 존재** (XPS 9370 전용 특이사항)
- Rufus로 Windows To Go 설치 후 부팅 확인된 커뮤니티 사례 다수
- write caching 비활성화로 Windows UI 버벅임 있으나 WSL 작업엔 영향 없음

### WSL2 메인으로 쓰는 것 — 커뮤니티 표준
- 2025/2026 커뮤니티 컨센서스: WSL2가 듀얼부팅 대체 수준 도달
- "Windows as hypervisor only" 철학 — Win11Debloat로 껍데기화
- 모든 개발 작업은 WSL 내부 파일시스템(`~/`)에서 수행

---

## 확정 설계 방향

### 목표 아키텍처

```
microSD (512GB) → Windows 최소 설치 (부팅 + 드라이버 + WSL 호스트)
NVMe (512GB)    → WSL2 Ubuntu VHDX 전용 (개발 메인, 고속 I/O)
WD D: (2TB)     → 데이터 창고 (모델, 오디오, 영상)
```

### 설계 철학
- Windows = 부팅 도구 + 원격 고장 수리 도구
- WSL = 실제 개발 환경 (메인)
- 두 환경이 서로를 복구하는 "상호 백업" 구조 유지
- 개발 작업은 WSL에서만, Windows는 건드리지 않음

### 실행 계획 (미실행 — 펜딩)

```
Step 1: Rufus로 microSD에 Windows 11 To Go 설치
Step 2: XPS BIOS → SD Card Boot 활성화
Step 3: microSD Windows 부팅 확인 + 드라이버 설치
Step 4: wsl --manage Ubuntu --move D:\WSL 또는 NVMe 경로로 VHDX 이동
Step 5: NVMe 기존 Windows 파티션 정리 → WSL VHDX 전용 NTFS 볼륨
Step 6: Win11Debloat 실행 → Windows 껍데기화
```

### 선행 확인 필요
- [ ] microSD 종류 확인 (일반 카드 vs Samsung PRO Endurance 급)
  - 일반 카드: 1-2년 수명 이슈 → 쓰기 최소화 전략 필요
  - PRO Endurance: 문제없음
- [ ] Rufus Windows To Go 생성 시 Secure Boot 설정 확인
- [ ] NVMe SATA 모드 확인 (현재 RAID → AHCI 변경 필요할 수 있음)

---

## 참고: 커뮤니티 소스
- ArchWiki: Dell XPS 13 (9370) Linux 호환성 문서
- Dell Community: XPS 9370 SD Card Boot 스레드
- XDA: "WSL2 is good enough that I stopped dual-booting"
- GitHub WSL: VHDX exFAT 거부 이슈 #12882

---

**다음 세션:** microSD 카드 종류 확인 후 Rufus Windows To Go 실행

---

## 2026-04-15 업데이트 — 확정 사항 4개

### 1. diskpart san policy=onlineall (치명적 선행 조건)

microSD WTG 부팅 시 PM981a가 기본 오프라인 처리됨.
이 명령 없이 진행하면 C:\WSL\ 접근 불가 → 이후 모든 단계 실패.

```
microSD Windows 부팅 직후 첫 번째 명령:
diskpart
san policy=onlineall
exit
```

### 2. WSL VHDX 이전 경로 — D:\WSL\ (WD Passport)

microSD는 공간/속도 제한으로 WSL VHDX 저장 부적합.
WSL minimal + 메인 Ubuntu 전부 D:\(WD Passport)에 저장.

```powershell
wsl --import UbuntuMin D:\WSL\min D:\wsl-min-base.tar
wsl --manage Ubuntu --move D:\WSL\Ubuntu
```

### 3. WSL minimal + mosh 자동시작 필수

SSH만으로는 WiFi→LTE 전환 시 세션 끊김 → 복구 도중 접속 소멸.
microSD Windows에 WSL minimal + mosh 설치 필수.

```
wsl --install --no-distribution
wsl --import UbuntuMin D:\WSL\min D:\wsl-min-base.tar
sudo apt install mosh
→ mosh 자동시작 + Windows 자동 로그인 등록
```

### 4. D:\_SYSTEM REBUILD.md 연동

WD Passport D:\_SYSTEM\passport-control\REBUILD.md 에
어느 PC에서든 원커맨드로 전체 환경 재현 스크립트 존재.
microSD 부팅 + WD Passport 연결 → REBUILD.md = 풀 환경 복원.

### BIOS 확정

SD Card Boot = 2순위 (NVMe 1순위 유지)
평상시 NVMe 자동 부팅 / NVMe 고장 시 microSD 자동 부팅
