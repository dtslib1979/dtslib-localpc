#!/bin/bash
# 태블릿 화면녹화 자동 수집 (PC-side)
# 새 MP4 파일 감시 → adb pull → /mnt/d/태블릿_캡쳐/Recordings/

TAB_IP="100.74.21.77"
DEST_BASE="/mnt/d/태블릿_캡쳐/Recordings"
PIDFILE="/tmp/adb_screenrecord_watcher.pid"

watch_recordings() {
    echo "[$(date +%H:%M:%S)] 녹화 watcher 시작 (Tab: $TAB_IP)"
    
    adb -s $TAB_IP:5555 shell "echo OK" 2>/dev/null || {
        echo "ADB 연결 실패."
        exit 1
    }
    
    # 감시할 디렉토리들
    WATCH_DIRS=(
        "/sdcard/DCIM/Screen recordings"
        "/sdcard/Movies"
    )
    
    # 초기 파일 목록
    : > /tmp/adb_rec_prev.lst
    for dir in "${WATCH_DIRS[@]}"; do
        adb -s $TAB_IP:5555 shell "ls -t \"$dir\"/*.mp4 2>/dev/null | head -5" >> /tmp/adb_rec_prev.lst 2>/dev/null
    done
    
    while true; do
        sleep 10
        
        : > /tmp/adb_rec_curr.lst
        for dir in "${WATCH_DIRS[@]}"; do
            adb -s $TAB_IP:5555 shell "ls -t \"$dir\"/*.mp4 2>/dev/null | head -5" >> /tmp/adb_rec_curr.lst 2>/dev/null
        done
        
        NEW_FILES=$(diff /tmp/adb_rec_prev.lst /tmp/adb_rec_curr.lst 2>/dev/null | grep '^>' | cut -d' ' -f2-)
        if [ -n "$NEW_FILES" ]; then
            DATE_DIR=$(date +%Y%m%d)
            mkdir -p "$DEST_BASE/$DATE_DIR"
            
            echo "$NEW_FILES" | while read -r file; do
                [ -z "$file" ] && continue
                echo "[$(date +%H:%M:%S)] 새 녹화: $file"
                adb -s $TAB_IP:5555 pull "$file" "$DEST_BASE/$DATE_DIR/" 2>&1 | tail -1
            done
            cp /tmp/adb_rec_curr.lst /tmp/adb_rec_prev.lst
        fi
    done
}

case "${1:-start}" in
    start)
        echo "Starting screenrecord watcher..."
        nohup bash -c "source \"$0\"; watch_recordings" > /tmp/adb_rec_watcher.log 2>&1 &
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
