#!/usr/bin/env python3
"""
parksy-infra MCP Server v1.0
폰-랩탑 미러링 인프라 전체를 MCP 툴로 노출.
Claude Code가 장애 감지 → 자동 복구까지 처리 가능.

등록: ~/.claude/settings.json → mcpServers → parksy-infra
"""

import asyncio
import subprocess
import json
import os
import re
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

# ─── 상수 ────────────────────────────────────────────────────────────────────

load_dotenv(Path(__file__).parent.parent / ".env")
HOME           = Path.home()
LOG_PATH       = HOME / "server.log"
INIT_SCRIPT    = HOME / "wsl-server-init.sh"
WATCHDOG_SCRIPT= HOME / "dtslib-localpc/telegram-bots/watchdog.sh"
BOT_IMAGE_PATH = Path("/mnt/d/parksy-image/tools/telegram-bridge/bot.py")
BOT_AUDIO_PATH = Path("/mnt/d/PARKSY/parksy-audio/local-agent/bot.py")
PHONE_IP_FILE  = HOME / ".phone_ip"
PHONE_PORT     = 8022

REQUIRED_SESSIONS = [
    "phone_claude", "tab_claude",
    "phone_aider", "tab_aider",
    "tg-image", "tg-audio", "watchdog"
]

TG_BOT_TOKEN = os.getenv("TG_BOT_TOKEN", "")
TG_CHAT_ID   = os.getenv("TG_CHAT_ID", "")

# ─── 헬퍼 ────────────────────────────────────────────────────────────────────

def run(cmd: str, timeout: int = 10) -> str:
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return (r.stdout + r.stderr).strip()
    except subprocess.TimeoutExpired:
        return f"[TIMEOUT after {timeout}s]"
    except Exception as e:
        return f"[ERROR: {e}]"

def get_phone_ip() -> str:
    try:
        return PHONE_IP_FILE.read_text().strip()
    except Exception:
        return ""

def ssh_phone(cmd: str, timeout: int = 8) -> str:
    ip = get_phone_ip()
    if not ip:
        return "[no phone IP]"
    return run(f'ssh -p {PHONE_PORT} -o ConnectTimeout=5 -o StrictHostKeyChecking=no {ip} "{cmd}"', timeout=timeout)

def tmux_sessions() -> dict:
    raw = run("tmux ls 2>/dev/null")
    sessions = {}
    for line in raw.splitlines():
        m = re.match(r'^([\w\-]+):', line)
        if m:
            sessions[m.group(1)] = line
    return sessions

def pgrep(pattern: str) -> bool:
    return run(f"pgrep -f '{pattern}'") != ""

# ─── MCP 서버 ────────────────────────────────────────────────────────────────

server = Server("parksy-infra")

@server.list_tools()
async def list_tools() -> list[types.Tool]:
    return [
        types.Tool(
            name="health_check",
            description=(
                "전체 인프라 헬스체크. Tailscale, SSH, tmux 7세션, "
                "tg-image/tg-audio 봇, Vast.ai 인스턴스, 폰 SSH 연결 상태를 한 번에 반환."
            ),
            inputSchema={"type": "object", "properties": {}, "required": []}
        ),
        types.Tool(
            name="recover_service",
            description=(
                "장애 서비스를 복구. service: sshd | tg-image | tg-audio | "
                "watchdog | tailscale | sessions | all"
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "service": {
                        "type": "string",
                        "enum": ["sshd", "tg-image", "tg-audio", "watchdog", "tailscale", "sessions", "all"]
                    }
                },
                "required": ["service"]
            }
        ),
        types.Tool(
            name="get_sessions",
            description="tmux 세션 전체 목록과 누락 세션 진단.",
            inputSchema={"type": "object", "properties": {}, "required": []}
        ),
        types.Tool(
            name="get_log",
            description="server.log 최근 N줄 반환 (기본 50줄).",
            inputSchema={
                "type": "object",
                "properties": {"lines": {"type": "integer", "default": 50}},
                "required": []
            }
        ),
        types.Tool(
            name="phone_status",
            description="폰 SSH 접속 → sshd, mosh, shortcuts, Claude 상태 확인.",
            inputSchema={"type": "object", "properties": {}, "required": []}
        ),
        types.Tool(
            name="init_all",
            description="전체 인프라 재초기화 (wsl-server-init.sh 재실행). 재부팅 후 복구에 사용.",
            inputSchema={"type": "object", "properties": {}, "required": []}
        ),
        types.Tool(
            name="notify_telegram",
            description="박씨 텔레그램으로 알림 전송.",
            inputSchema={
                "type": "object",
                "properties": {"message": {"type": "string"}},
                "required": ["message"]
            }
        ),
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[types.TextContent]:
    result = await _dispatch(name, arguments)
    return [types.TextContent(type="text", text=result)]

async def _dispatch(name: str, args: dict) -> str:
    if name == "health_check":
        return await _health_check()
    elif name == "recover_service":
        return await _recover(args.get("service", "all"))
    elif name == "get_sessions":
        return await _get_sessions()
    elif name == "get_log":
        return _get_log(args.get("lines", 50))
    elif name == "phone_status":
        return await _phone_status()
    elif name == "init_all":
        return await _init_all()
    elif name == "notify_telegram":
        return _notify(args.get("message", ""))
    return f"[unknown tool: {name}]"

# ─── 툴 구현 ──────────────────────────────────────────────────────────────────

async def _health_check() -> str:
    ok, ng = "✅", "❌"
    now = datetime.now().strftime("%Y-%m-%d %H:%M")

    ts_count = run("tailscale status 2>/dev/null | grep -c active || echo 0")
    adb_count = run("adb devices 2>/dev/null | grep -v 'List of' | grep -c device$ || echo 0")
    phone_ip = get_phone_ip()
    phone_ssh = ssh_phone("echo OK")
    mosh_wsl = run("which mosh-server 2>/dev/null")
    reaper = run("powershell.exe -Command \"Get-Process reaper -EA SilentlyContinue | Select-Object -First 1 -ExpandProperty Id\" 2>/dev/null | tr -d '\\r'")
    vast = run("vastai show instances 2>/dev/null | grep running | awk '{print $1, $7}' | head -3")
    ram_used = run("free -h | awk '/Mem/{print $3}'")
    ram_tot  = run("free -h | awk '/Mem/{print $2}'")
    disk_c   = run("df -h /mnt/c | awk 'NR==2{print $3\"/\"$2}'")
    disk_d   = run("df -h /mnt/d 2>/dev/null | awk 'NR==2{print $3\"/\"$2}'") or "미연결"

    sessions = tmux_sessions()
    session_status = {}
    for s in REQUIRED_SESSIONS:
        session_status[s] = ok if s in sessions else ng

    bot_image = ok if pgrep("telegram-bridge/bot.py") else ng
    bot_audio = ok if pgrep("local-agent/bot.py") else ng
    watchdog  = ok if pgrep("watchdog.sh") else ng

    lines = [
        f"┌─── parksy-infra 헬스체크 {now} ───┐",
        f"│ 🌐 Tailscale  : {ok if ts_count.strip() != '0' else ng} ({ts_count.strip()} active)",
        f"│ 📱 ADB        : {ok if adb_count.strip() != '0' else ng} ({adb_count.strip()}대)",
        f"│ 📱 폰 SSH     : {ok if 'OK' in phone_ssh else ng} {phone_ip}",
        f"│ 🔒 mosh WSL   : {ok if mosh_wsl else ng}",
        f"│ 🎛  REAPER    : {ok + ' PID ' + reaper if reaper.strip() else '—  미실행'}",
        f"│ ☁️  Vast.ai   : {ok + ' ' + vast if vast else '—  없음'}",
        "│",
        "│ 🤖 tmux 세션:",
        *[f"│   {s:15s}: {v}" for s, v in session_status.items()],
        "│",
        f"│ 🤖 tg-image 봇: {bot_image}",
        f"│ 🤖 tg-audio 봇: {bot_audio}",
        f"│ 🐕 watchdog   : {watchdog}",
        "│",
        f"│ 💾 RAM: {ram_used} / {ram_tot}",
        f"│ 💿 C: {disk_c}  D: {disk_d}",
        "└────────────────────────────────────────┘",
    ]
    return "\n".join(lines)


async def _recover(service: str) -> str:
    results = []
    targets = REQUIRED_SESSIONS if service == "sessions" else [service]

    if service in ("sshd", "all"):
        out = run("sudo service ssh start 2>&1 || true")
        results.append(f"sshd: {out or 'started'}")

    if service in ("tailscale", "all"):
        if not run("pgrep -x tailscaled"):
            run("sudo tailscaled --state=/var/lib/tailscale/tailscaled.state "
                "--socket=/var/run/tailscale/tailscaled.sock &>/dev/null &")
            await asyncio.sleep(3)
            run("sudo tailscale up --accept-routes --accept-dns=false")
        results.append("tailscale: restarted")

    if service in ("tg-image", "all"):
        run("tmux send-keys -t tg-image:0 C-c 2>/dev/null; sleep 1; true")
        if "tg-image" not in tmux_sessions():
            run("tmux new-session -d -s tg-image -n image-bot")
        run(f"tmux send-keys -t tg-image:0 'source ~/.bashrc && python3 {BOT_IMAGE_PATH}' Enter")
        results.append("tg-image: restarted")

    if service in ("tg-audio", "all"):
        run("tmux send-keys -t tg-audio:0 C-c 2>/dev/null; sleep 1; true")
        if "tg-audio" not in tmux_sessions():
            run("tmux new-session -d -s tg-audio -n audio-bot")
        run(f"tmux send-keys -t tg-audio:0 'source ~/.bashrc && python3 {BOT_AUDIO_PATH}' Enter")
        results.append("tg-audio: restarted")

    if service in ("watchdog", "all"):
        run("tmux kill-session -t watchdog 2>/dev/null; true")
        run("tmux new-session -d -s watchdog -n monitor")
        run(f"tmux send-keys -t watchdog:monitor 'source ~/.bashrc && bash {WATCHDOG_SCRIPT}' Enter")
        results.append("watchdog: restarted")

    if service == "sessions":
        sessions = tmux_sessions()
        claude_bin = run("which claude 2>/dev/null || echo claude")
        created = []
        for s in REQUIRED_SESSIONS:
            if s not in sessions:
                run(f"tmux new-session -d -s {s} -n main")
                if s in ("phone_claude", "tab_claude"):
                    run(f"tmux send-keys -t {s}:main 'source ~/.bashrc && {claude_bin}' Enter")
                created.append(s)
        results.append(f"sessions: created {created if created else 'none (all exist)'}")

    return "복구 완료:\n" + "\n".join(f"  • {r}" for r in results)


async def _get_sessions() -> str:
    sessions = tmux_sessions()
    lines = [f"현재 tmux 세션 ({len(sessions)}개):"]
    for name, info in sessions.items():
        lines.append(f"  {info}")
    lines.append("")
    missing = [s for s in REQUIRED_SESSIONS if s not in sessions]
    if missing:
        lines.append(f"⚠ 누락 세션: {', '.join(missing)}")
        lines.append("→ recover_service('sessions') 로 복구 가능")
    else:
        lines.append("✅ 필수 세션 전부 정상")
    return "\n".join(lines)


def _get_log(lines: int) -> str:
    try:
        out = run(f"tail -n {lines} {LOG_PATH}")
        return f"server.log (최근 {lines}줄):\n{out}"
    except Exception as e:
        return f"[로그 읽기 실패: {e}]"


async def _phone_status() -> str:
    ip = get_phone_ip()
    if not ip:
        return "❌ ~/.phone_ip 없음"

    checks = {
        "sshd"     : ssh_phone("pgrep -x sshd && echo OK || echo NG"),
        "mosh"     : ssh_phone("ls /data/data/com.termux/files/usr/bin/mosh 2>/dev/null && echo OK || echo NG"),
        "shortcuts": ssh_phone("ls /data/data/com.termux/files/home/.shortcuts/ | wc -l"),
        "claude"   : ssh_phone("pgrep -f claude && echo running || echo stopped"),
        "disk"     : ssh_phone("df -h /data/data/com.termux/files | awk 'NR==2{print $3\"/\"$2}'"),
    }
    lines = [f"📱 폰 상태 ({ip}):"]
    for k, v in checks.items():
        icon = "✅" if ("OK" in v or "running" in v or v.strip().isdigit()) else "❌"
        lines.append(f"  {icon} {k:12s}: {v.strip()}")
    return "\n".join(lines)


async def _init_all() -> str:
    if not INIT_SCRIPT.exists():
        return f"❌ {INIT_SCRIPT} 없음"
    out = run(f"bash {INIT_SCRIPT} 2>&1", timeout=60)
    return f"wsl-server-init.sh 실행 완료:\n{out[-2000:]}"


def _notify(message: str) -> str:
    import urllib.parse
    encoded = urllib.parse.quote(message)
    out = run(
        f'curl -s -m 10 -X POST '
        f'"https://api.telegram.org/bot{TG_BOT_TOKEN}/sendMessage" '
        f'--data-urlencode "chat_id={TG_CHAT_ID}" '
        f'--data-urlencode "text={message}"'
    )
    return f"텔레그램 전송: {'OK' if 'message_id' in out else 'FAIL'}\n{out[:200]}"


# ─── 리소스 ───────────────────────────────────────────────────────────────────

@server.list_resources()
async def list_resources() -> list[types.Resource]:
    return [
        types.Resource(
            uri="infra://status",
            name="인프라 실시간 상태",
            description="tmux 세션, 봇, Tailscale 현재 상태 JSON",
            mimeType="application/json"
        ),
        types.Resource(
            uri="infra://log",
            name="서버 로그",
            description="server.log 최근 100줄",
            mimeType="text/plain"
        ),
        types.Resource(
            uri="infra://sessions",
            name="tmux 세션 목록",
            description="현재 실행 중인 tmux 세션 전체",
            mimeType="text/plain"
        ),
    ]

@server.read_resource()
async def read_resource(uri: str) -> str:
    if uri == "infra://status":
        sessions = tmux_sessions()
        return json.dumps({
            "timestamp": datetime.now().isoformat(),
            "sessions": list(sessions.keys()),
            "missing": [s for s in REQUIRED_SESSIONS if s not in sessions],
            "bot_image": pgrep("telegram-bridge/bot.py"),
            "bot_audio": pgrep("local-agent/bot.py"),
            "watchdog":  pgrep("watchdog.sh"),
            "tailscale": run("tailscale status 2>/dev/null | head -1"),
        }, ensure_ascii=False, indent=2)
    elif uri == "infra://log":
        return _get_log(100)
    elif uri == "infra://sessions":
        return run("tmux ls 2>/dev/null || echo '세션 없음'")
    return "[unknown resource]"


# ─── 진입점 ───────────────────────────────────────────────────────────────────

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
