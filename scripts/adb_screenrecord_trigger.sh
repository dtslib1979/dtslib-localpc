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
        "/sdcard/YT_QUEUE"
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
            mkdir -p "$DEST_BASE/YT_upload"

            echo "$NEW_FILES" | while read -r file; do
                [ -z "$file" ] && continue

                # YT_QUEUE.ready 파일 처리
                if [[ "$file" == *.ready ]]; then
                    MP4_BASE="${file%.ready}"
                    MP4_NAME=$(basename "$MP4_BASE")
                    echo "[$(date +%H:%M:%S)] YT 업로드 요청: $MP4_NAME"
                    # .ready 파일에서 타임스탬프 읽기
                    READY_TS=$(adb -s $TAB_IP:5555 shell "cat \"$file\"" 2>/dev/null)
                    echo "   큐 시각: $READY_TS"
                    # 원본 MP4 찾아서 pull
                    for mp4_dir in "/sdcard/DCIM/Screen recordings" "/sdcard/Movies"; do
                        FOUND=$(adb -s $TAB_IP:5555 shell "ls \"$mp4_dir/$MP4_NAME\" 2>/dev/null" | tr -d '\r')
                        if [ -n "$FOUND" ]; then
                            echo "[$(date +%H:%M:%S)] YT 업로드용 MP4 수집: $MP4_NAME"
                            adb -s $TAB_IP:5555 pull "$mp4_dir/$MP4_NAME" "$DEST_BASE/YT_upload/" 2>&1 | tail -1
                            break
                        fi
                    done
                    # .ready 파일 정리
                    adb -s $TAB_IP:5555 shell "rm \"$file\"" 2>/dev/null
                else
                    echo "[$(date +%H:%M:%S)] 새 녹화: $file"
                    adb -s $TAB_IP:5555 pull "$file" "$DEST_BASE/$DATE_DIR/" 2>&1 | tail -1
                fi
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
