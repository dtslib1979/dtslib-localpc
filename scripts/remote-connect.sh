#!/bin/bash
# remote-connect.sh — Termux에서 PC SSH 접속 헬퍼
# 용도: 폰에서 한 줄로 PC 접속 + tmux 워크스페이스 자동 시작
# 설치: Termux에서 이 파일을 ~/bin/pc 로 복사
#   cp remote-connect.sh ~/bin/pc && chmod +x ~/bin/pc
# 사용: pc                    # 기본 접속 + tmux attach
#       pc audio              # audio 프리셋
#       pc batch              # batch 프리셋
#       pc raw                # tmux 없이 그냥 접속
#       pc setup              # 초기 설정 (최초 1회)

set -e

# === 설정 (최초 실행 시 수정) ===
PC_USER="${PC_USER:-}"
PC_HOST="${PC_HOST:-}"
PC_PORT="${PC_PORT:-22}"
SSH_KEY="$HOME/.ssh/id_ed25519"

CONFIG_FILE="$HOME/.pc-remote.conf"

# === 설정 파일 로드 ===
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# === 설정 파일 저장 ===
save_config() {
    cat > "$CONFIG_FILE" << EOF
# PC 원격 접속 설정 (remote-connect.sh)
PC_USER="$PC_USER"
PC_HOST="$PC_HOST"
PC_PORT="$PC_PORT"
EOF
    echo "[OK] 설정 저장: $CONFIG_FILE"
}

# === 초기 설정 ===
do_setup() {
    echo "=== PC 원격 접속 초기 설정 ==="
    echo ""

    read -p "PC 사용자 이름 (Windows 계정): " PC_USER
    read -p "PC IP 주소 (예: 192.168.0.10): " PC_HOST
    read -p "SSH 포트 [22]: " input_port
    PC_PORT="${input_port:-22}"

    save_config

    # SSH 키 생성 (없으면)
    if [ ! -f "$SSH_KEY" ]; then
        echo ""
        echo "[INFO] SSH 키 생성..."
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "termux-park"
        echo "[OK] SSH 키 생성 완료"
    fi

    echo ""
    echo "=== 다음 단계 ==="
    echo ""
    echo "1. PC에 공개키 등록:"
    echo "   ssh-copy-id -p $PC_PORT $PC_USER@$PC_HOST"
    echo ""
    echo "2. 접속 테스트:"
    echo "   pc raw"
    echo ""
    echo "3. tmux 워크스페이스:"
    echo "   pc"
    echo ""
}

# === SSH 접속 ===
do_connect() {
    local preset="${1:-default}"
    local ssh_opts="-p $PC_PORT"

    if [ -f "$SSH_KEY" ]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi

    # 접속 가능 체크 (2초 타임아웃)
    if ! ssh $ssh_opts -o ConnectTimeout=3 -o BatchMode=yes "$PC_USER@$PC_HOST" "echo ok" &>/dev/null; then
        echo "[ERROR] PC 접속 불가: $PC_USER@$PC_HOST:$PC_PORT"
        echo ""
        echo "확인사항:"
        echo "  1. PC 켜져있는지"
        echo "  2. SSH 서버 실행 중인지 (Get-Service sshd)"
        echo "  3. 같은 네트워크인지 (WiFi)"
        echo "  4. IP 바뀌었는지 (ipconfig)"
        echo ""
        echo "재설정: pc setup"
        exit 1
    fi

    case "$preset" in
        raw)
            echo "PC 직접 접속..."
            ssh $ssh_opts "$PC_USER@$PC_HOST"
            ;;
        *)
            echo "PC 접속 + tmux ($preset)..."
            # tmux가 이미 있으면 attach, 없으면 워크스페이스 생성
            ssh $ssh_opts -t "$PC_USER@$PC_HOST" \
                "tmux attach -t work 2>/dev/null || bash -c 'cd /mnt/d/PARKSY/dtslib-localpc && bash scripts/tmux-workspace.sh $preset work'"
            ;;
    esac
}

# === 메인 ===
load_config

case "${1:-}" in
    setup)
        do_setup
        ;;
    help|--help|-h)
        echo "pc — Park PC 원격 접속"
        echo ""
        echo "사용법:"
        echo "  pc              # 기본 접속 (tmux default)"
        echo "  pc audio        # audio 프리셋"
        echo "  pc batch        # batch 프리셋"
        echo "  pc monitor      # 모니터링 프리셋"
        echo "  pc raw          # tmux 없이 직접 접속"
        echo "  pc setup        # 초기 설정"
        echo ""
        echo "설정: $CONFIG_FILE"
        ;;
    *)
        if [ -z "$PC_USER" ] || [ -z "$PC_HOST" ]; then
            echo "[ERROR] 초기 설정 필요"
            echo "  pc setup"
            exit 1
        fi
        do_connect "${1:-default}"
        ;;
esac
