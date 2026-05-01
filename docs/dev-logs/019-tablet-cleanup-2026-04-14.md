# 019 — Tab S9 태블릿 청소 (2026-04-14)

## 작업 배경

Tab S9 내부 저장소 106GB 중 87GB 사용 (83%) → 여유 18GB로 한계.
작업대 철학 재확인: 태블릿은 창고가 아니라 작업대. 녹화→즉시 업로드→삭제 회전.

## 태블릿 운용 철학 확정

```
역할: 방송 녹화 + 그림 작업
흐름: 작업 → YouTube 즉시 포스팅 → 삭제 → 다음 작업
원칙: 자료 관리 안 함. 회전율이 전략.
```

## 청소 전/후

| 항목 | 전 | 후 |
|------|----|----|
| 사용 | 87GB (83%) | 58GB (55%) |
| 여유 | 18GB | 48GB |
| 확보 | — | **+30GB** |

## 삭제 항목

### Download (8.4GB → 0)
- app-debug.apk 계열 (370MB)
- Parksy APK 3개 — Parksy-TTS-v1.0.2, parksy-studio-v1.0.0, laser-pen-v24.2 (설치됨, 불필요)
- Quick Share hash.zip (2.4GB, 정체불명 구파일 2026-03-30)
- debug 폴더 — capture-pipeline-debug, tts-factory-debug, laser-pen-overlay-debug
- 나머지 전체 (MP4 435개 쇼츠 생성물, TTS 오디오 등)

### Movies (8.4GB → 0)
- 전체 (타임스탬프명 생성 콘텐츠)

### DCIM (11GB → 0)
- Camera (4.3GB) — 핸드폰 Samsung Cloud 동기화로 복구 가능. Quick Share로 필요시 수령
- Screen recordings (4.8GB) — 76개, 이미 업로드된 것들
- Clipped images, Collage, GIF, Samsung Notes, Sketch to image, Video Editor, 리마인더이미지, 움짤 동영상

### Pictures (2GB → 135MB)
- ChatGPT 생성 이미지 225개 (file-*.webp/jpg)
- ChatGPT 4o 생성 이미지 119개 (file_0000*.png)
- ChatGPT/ 폴더 (222MB)
- KakaoTalk/ 폴더 (139MB)
- 타임스탬프 jpg/png (17*.jpg 계열)

**보존:**
- 브랜드 에셋 (Artrew-logo.png, dtsliblogo.png, Brandlogo 등)
- gohsy 프로필 사진
- Sketchbook Gallery

### DCIM/Screenshots
- 이미 이전 세션에서 비어있음

## 앱 환경 비교 (폰 vs 탭)

```
📱 폰 앱: 217개
📟 탭 앱: 225개

폰에만 있는 주요 앱:
  com.discord                  → 웹 대체 가능
  com.dtslib.parksy_melody     → APK 재설치 5분
  com.parksy.chronocall        → APK 재설치 5분
  com.nhn.android.nmap         → 스토어 설치
  kr.go.mobileid               → 재발급 필요 (유일한 약점)
  com.samsung.android.spay     → 재등록 필요
```

## 핸드폰 분실 시 태블릿 대체 가능 여부

**가능 (95%):**
- Claude Code 작업: PC(WSL2) 메인 → 탭 SSH 접속으로 그대로 이어서 작업
- 앱 환경: 거의 동일
- 자체 개발 앱: APK 재설치로 5분 복구

**불가 (5%):**
- 모바일 신분증: 재발급 필요
- Samsung Pay: 재등록 필요
- 유심 이동 시 번호 인증 해결

**결론: 유심만 탭에 꽂으면 사실상 완벽 대체.**

## 잔여 용량 구조 (58GB 사용 중)

```
시스템/OS:     ~9GB  (고정, 건드릴 수 없음)
앱 225개:     ~49GB  (설치 + 데이터 + 캐시)
미디어:         1GB  (정리 완료)
```

앱이 49GB 점유 — 미디어 정리로는 한계. 운용 철학(회전율)이 근본 해법.

## 펜딩

- microSD(E:) Windows To Go 설치 → PC 앞 재부팅 필요 시 진행
- wsl_backup.tar (E드라이브 13.8GB) → D드라이브 이동 예정
