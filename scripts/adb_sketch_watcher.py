#!/usr/bin/env python3
"""
adb_sketch_watcher.py — S펜 스케치 변화 감지 → contour.py → parksy-air 자동 투입

방식: ADB screencap 2초 폴링 → SHA256 diff 감지 → 변화 있으면 pull + contour.py 호출
대상: Tab S9 (100.74.21.77:5555) 삼성 노트 앱 또는 전체 화면

구조:
  PC WSL2 상주 → ADB → 탭 screencap
    → 변화 감지 → /mnt/d/태블릿_캡쳐/Sketches/{날짜}/sketch_{ts}.png
    → contour.py (선화 추출) → sketch_{ts}_contour.png
    → [선택] parksy-air 투입 (MCP 체인)

실행:
  python3 ~/dtslib-localpc/scripts/adb_sketch_watcher.py
  python3 ~/dtslib-localpc/scripts/adb_sketch_watcher.py --no-contour  (캡처만)
  python3 ~/dtslib-localpc/scripts/adb_sketch_watcher.py --chain        (MCP 체인까지)

PID 파일: /tmp/adb_sketch_watcher.pid
로그: /tmp/adb_sketch_watcher.log
"""

from __future__ import annotations

import argparse
import hashlib
import os
import signal
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# ── 설정 ──────────────────────────────────────────────
TAB_IP = os.environ.get("TAB_IP", "100.74.21.77")
ADB_CMD = f"adb -s {TAB_IP}:5555"
DEST_BASE = Path(os.environ.get("SKETCH_DEST", "/mnt/d/태블릿_캡쳐/Sketches"))
CONTOUR_SCRIPT = Path.home() / "parksy-image/scripts/drawing/contour.py"
INTERVAL = int(os.environ.get("SKETCH_INTERVAL", "2"))        # 폴링 간격 (초)
MIN_CHANGE_THRESHOLD = float(os.environ.get("SKETCH_THRESHOLD", "0.01"))  # 1% 픽셀 변화율
PIDFILE = Path("/tmp/adb_sketch_watcher.pid")
TMP_CURRENT = Path("/tmp/sketch_current.png")
TMP_PREV = Path("/tmp/sketch_prev.png")

# 삼성 노트 앱 패키지 (활성 앱 필터용)
SAMSUNG_NOTES_PKG = "com.samsung.android.app.notes"


def _adb(*args) -> subprocess.CompletedProcess:
    cmd = f"{ADB_CMD} {' '.join(str(a) for a in args)}"
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)


def _active_package() -> str:
    """현재 전경 앱 패키지명 반환."""
    r = _adb("shell", "dumpsys", "activity", "top", "|", "grep", "ACTIVITY")
    if r.returncode == 0 and r.stdout.strip():
        # 예: ACTIVITY com.samsung.android.app.notes/.MainActivity
        parts = r.stdout.strip().split()
        if len(parts) >= 2:
            return parts[1].split("/")[0]
    return ""


def _sha256(path: Path) -> str:
    if not path.exists():
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _pixel_diff_ratio(prev: Path, curr: Path) -> float:
    """두 PNG 파일의 픽셀 변화율 (0.0~1.0). cv2 없으면 SHA256 일치 여부만."""
    try:
        import cv2
        import numpy as np
        img_p = cv2.imread(str(prev), cv2.IMREAD_GRAYSCALE)
        img_c = cv2.imread(str(curr), cv2.IMREAD_GRAYSCALE)
        if img_p is None or img_c is None:
            return 1.0
        if img_p.shape != img_c.shape:
            return 1.0
        diff = cv2.absdiff(img_p, img_c)
        changed = np.count_nonzero(diff > 10)  # 임계값 10
        return changed / diff.size
    except ImportError:
        return 1.0 if _sha256(prev) != _sha256(curr) else 0.0


def _screencap() -> bool:
    """탭 화면 캡처 → TMP_CURRENT. 성공 시 True."""
    r = _adb("exec-out", "screencap", "-p")
    if r.returncode != 0 or not r.stdout:
        return False
    TMP_CURRENT.write_bytes(r.stdout.encode("latin-1") if isinstance(r.stdout, str)
                            else r.stdout)
    return TMP_CURRENT.stat().st_size > 10000


def _screencap_file() -> bool:
    """파일 방식 screencap (exec-out 실패 시 fallback)."""
    r = _adb("shell", "screencap", "-p", "/sdcard/Download/.sketch_tmp.png")
    if r.returncode != 0:
        return False
    r2 = _adb("pull", "/sdcard/Download/.sketch_tmp.png", str(TMP_CURRENT))
    return r2.returncode == 0 and TMP_CURRENT.exists() and TMP_CURRENT.stat().st_size > 10000


def _run_contour(src: Path, dst: Path) -> bool:
    """contour.py로 선화 추출. 성공 시 True."""
    if not CONTOUR_SCRIPT.exists():
        print(f"[WARN] contour.py 없음: {CONTOUR_SCRIPT}", flush=True)
        return False
    venv_py = Path.home() / "parksy-image/.venv/bin/python"
    py = str(venv_py) if venv_py.exists() else sys.executable
    r = subprocess.run(
        [py, str(CONTOUR_SCRIPT), str(src), "--output", str(dst)],
        capture_output=True, text=True, timeout=30
    )
    if r.returncode == 0:
        return dst.exists()
    print(f"[WARN] contour.py 실패: {r.stderr[:200]}", flush=True)
    return False


def _notify_telegram(image_path: Path) -> None:
    """텔레그램으로 선화 이미지 전송 (캡처 → 분배 체인 시작점)."""
    BOT_TOKEN = os.environ.get("PARKSY_BOT_TOKEN", "8621929617:AAH-XpVJ4PKVJV8m9-qB2aLupMHO0nYfZLQ")
    CHAT_ID = os.environ.get("PARKSY_CHAT_ID", "6858098283")
    caption = f"🎨 S펜 스케치 감지: {image_path.name}"
    r = subprocess.run(
        ["curl", "-s", "-X", "POST",
         f"https://api.telegram.org/bot{BOT_TOKEN}/sendPhoto",
         "-F", f"chat_id={CHAT_ID}",
         "-F", f"photo=@{image_path}",
         "-F", f"caption={caption}"],
        capture_output=True, text=True, timeout=30
    )
    if '"ok":true' in r.stdout:
        print(f"[TG] ✅ 전송 완료: {image_path.name}", flush=True)
    else:
        print(f"[TG] ❌ 전송 실패: {r.stdout[:100]}", flush=True)


def watch(no_contour: bool = False, chain: bool = False, notes_only: bool = False) -> None:
    """메인 감시 루프."""
    DEST_BASE.mkdir(parents=True, exist_ok=True)
    PIDFILE.write_text(str(os.getpid()))

    print(f"[INFO] adb_sketch_watcher 시작 (interval={INTERVAL}s, threshold={MIN_CHANGE_THRESHOLD:.1%})")
    print(f"[INFO] 탭 IP: {TAB_IP}, 저장: {DEST_BASE}")
    print(f"[INFO] contour.py: {'비활성' if no_contour else str(CONTOUR_SCRIPT)}")
    print(f"[INFO] MCP 체인: {'활성' if chain else '비활성'}")
    print(f"[INFO] 삼성 노트 전용: {notes_only}")
    print(f"[INFO] PID: {os.getpid()} → {PIDFILE}", flush=True)

    prev_hash = ""
    consecutive_fails = 0

    while True:
        try:
            # ADB 연결 확인
            if consecutive_fails >= 10:
                print("[WARN] ADB 연결 실패 10회 → 5초 대기", flush=True)
                time.sleep(5)
                consecutive_fails = 0
                continue

            # 삼성 노트 전용 모드: 전경 앱 확인
            if notes_only:
                pkg = _active_package()
                if SAMSUNG_NOTES_PKG not in pkg:
                    time.sleep(INTERVAL)
                    continue

            # screencap
            ok = _screencap()
            if not ok:
                ok = _screencap_file()
            if not ok:
                consecutive_fails += 1
                time.sleep(INTERVAL)
                continue

            consecutive_fails = 0
            curr_hash = _sha256(TMP_CURRENT)

            # 첫 번째 캡처 — 기준점만 저장
            if not prev_hash:
                TMP_CURRENT.rename(TMP_PREV)
                prev_hash = curr_hash
                time.sleep(INTERVAL)
                continue

            # 동일하면 스킵
            if curr_hash == prev_hash:
                time.sleep(INTERVAL)
                continue

            # 픽셀 diff 계산
            diff = _pixel_diff_ratio(TMP_PREV, TMP_CURRENT)
            if diff < MIN_CHANGE_THRESHOLD:
                # 변화 미미 → 이전 업데이트만
                TMP_CURRENT.replace(TMP_PREV)
                prev_hash = curr_hash
                time.sleep(INTERVAL)
                continue

            # ── 변화 감지! ──
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            date_dir = DEST_BASE / datetime.now().strftime("%Y%m%d")
            date_dir.mkdir(parents=True, exist_ok=True)
            sketch_path = date_dir / f"sketch_{ts}.png"

            import shutil
            shutil.copy2(TMP_CURRENT, sketch_path)
            TMP_CURRENT.replace(TMP_PREV)
            prev_hash = curr_hash

            print(f"[NEW] 스케치 감지 ({diff:.1%} 변화): {sketch_path.name}", flush=True)

            # contour.py 실행
            if not no_contour and CONTOUR_SCRIPT.exists():
                contour_path = date_dir / f"sketch_{ts}_contour.png"
                if _run_contour(sketch_path, contour_path):
                    print(f"[CONTOUR] ✅ 선화 추출: {contour_path.name}", flush=True)

                    # MCP 체인 트리거 (--chain 옵션)
                    if chain:
                        _notify_telegram(contour_path)
                else:
                    print(f"[CONTOUR] ❌ 선화 추출 실패", flush=True)
                    if chain:
                        _notify_telegram(sketch_path)
            elif chain:
                _notify_telegram(sketch_path)

            time.sleep(INTERVAL)

        except KeyboardInterrupt:
            print("\n[INFO] 종료", flush=True)
            break
        except Exception as e:
            print(f"[ERR] {e}", flush=True)
            time.sleep(INTERVAL)

    PIDFILE.unlink(missing_ok=True)


def stop() -> None:
    """실행 중인 워처 종료."""
    if not PIDFILE.exists():
        print("실행 중인 워처 없음")
        return
    pid = int(PIDFILE.read_text().strip())
    try:
        os.kill(pid, signal.SIGTERM)
        print(f"[STOP] PID {pid} 종료 신호 전송")
    except ProcessLookupError:
        print(f"[STOP] PID {pid} 이미 종료됨")
    PIDFILE.unlink(missing_ok=True)


def status() -> None:
    """워처 상태 확인."""
    if not PIDFILE.exists():
        print("❌ adb_sketch_watcher 미실행")
        return
    pid = int(PIDFILE.read_text().strip())
    try:
        os.kill(pid, 0)
        print(f"✅ 실행 중 (PID {pid})")
    except ProcessLookupError:
        print(f"❌ PID {pid} 없음 (비정상 종료)")
        PIDFILE.unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="S펜 스케치 ADB 감시 데몬")
    parser.add_argument("action", nargs="?", default="start",
                        choices=["start", "stop", "status"],
                        help="start|stop|status (기본: start)")
    parser.add_argument("--no-contour", action="store_true",
                        help="contour.py 선화 추출 비활성화")
    parser.add_argument("--chain", action="store_true",
                        help="선화 추출 후 TG 전송까지 자동")
    parser.add_argument("--notes-only", action="store_true",
                        help="삼성 노트 앱 활성 시에만 감시")
    args = parser.parse_args()

    if args.action == "stop":
        stop()
    elif args.action == "status":
        status()
    else:
        watch(no_contour=args.no_contour, chain=args.chain, notes_only=args.notes_only)
