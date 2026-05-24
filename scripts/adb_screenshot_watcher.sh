#!/bin/bash
# 태블릿 스크린샷 자동 수집 watcher (PC-side)
# inotifywait로 /sdcard/DCIM/Screenshots/ 새 파일 감지 → adb pull

TAB_IP="100.74.21.77"
DEST_BASE="/mnt/d/태블릿_캡쳐/Screenshots"
PIDFILE="/tmp/adb_screenshot_watcher.pid"

watch_screenshots() {
    echo "[$(date +%H:%M:%S)] 스크린샷 watcher 시작 (Tab: $TAB_IP)"
    echo "[$(date +%H:%M:%S)] 저장 경로: $DEST_BASE"
    
    # ADB 연결 확인
    adb -s $TAB_IP:5555 shell "echo OK" 2>/dev/null || {
        echo "ADB 연결 실패. 종료."
        exit 1
    }
    
    # 초기 파일 목록 스냅샷
    adb -s $TAB_IP:5555 shell "ls /sdcard/DCIM/Screenshots/" > /tmp/adb_ss_prev.lst 2>/dev/null
    
    while true; do
        sleep 5
        # 새 파일 감지
        adb -s $TAB_IP:5555 shell "ls /sdcard/DCIM/Screenshots/" > /tmp/adb_ss_curr.lst 2>/dev/null
        
        NEW_FILES=$(diff /tmp/adb_ss_prev.lst /tmp/adb_ss_curr.lst 2>/dev/null | grep '^>' | cut -d' ' -f2-)
        if [ -n "$NEW_FILES" ]; then
            DATE_DIR=$(date +%Y%m%d)
            mkdir -p "$DEST_BASE/$DATE_DIR"
            
            echo "$NEW_FILES" | while read -r file; do
                [ -z "$file" ] && continue
                echo "[$(date +%H:%M:%S)] 새 스크린샷: $file"
                adb -s $TAB_IP:5555 pull "/sdcard/DCIM/Screenshots/$file" "$DEST_BASE/$DATE_DIR/" 2>&1 | tail -1
            done
            cp /tmp/adb_ss_curr.lst /tmp/adb_ss_prev.lst
        fi
    done
}

case "${1:-start}" in
    start)
        echo "Starting screenshot watcher..."
        nohup bash -c "source \"$0\"; watch_screenshots" > /tmp/adb_ss_watcher.log 2>&1 &
        echo $! > "$PIDFILE"
        echo "PID: $(cat $PIDFILE)"
        ;;
    stop)
        if [ -f "$PIDFILE" ]; then
            kill $(cat "$PIDFILE") 2>/dev/null
            rm -f "$PIDFILE"
            echo "Stopped."
        else
            echo "Not running."
        fi
        ;;
    status)
        if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
            echo "Running. PID: $(cat $PIDFILE)"
        else
            echo "Not running."
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        ;;
esac
