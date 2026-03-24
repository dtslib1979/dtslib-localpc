#!/usr/bin/env python3
"""
Windows GUI MCP Server
Provides direct Windows desktop control: screenshot, click, type, windows management
Runs as Windows Python process, communicates via stdio JSON-RPC (MCP protocol)
"""
import sys
import json
import base64
import io
import time
import ctypes
import ctypes.wintypes
import threading

# Disable pyautogui failsafe for automation
import pyautogui
pyautogui.FAILSAFE = False
pyautogui.PAUSE = 0.05

from PIL import ImageGrab, Image

# Windows API constants
SW_RESTORE = 9
SW_SHOW = 5
WM_CLOSE = 0x0010
HWND_TOP = 0

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

# ─── helpers ───────────────────────────────────────────────────────────────

def screenshot_base64(x=None, y=None, w=None, h=None, hwnd=None):
    """Take screenshot, return base64 PNG string."""
    if hwnd:
        import win32gui, win32ui, win32con
        left, top, right, bottom = win32gui.GetWindowRect(hwnd)
        width = right - left
        height = bottom - top
        hwndDC = win32gui.GetWindowDC(hwnd)
        mfcDC = win32ui.CreateDCFromHandle(hwndDC)
        saveDC = mfcDC.CreateCompatibleDC()
        saveBitMap = win32ui.CreateBitmap()
        saveBitMap.CreateCompatibleBitmap(mfcDC, width, height)
        saveDC.SelectObject(saveBitMap)
        result = ctypes.windll.user32.PrintWindow(hwnd, saveDC.GetSafeHdc(), 0x2)
        bmpinfo = saveBitMap.GetInfo()
        bmpstr = saveBitMap.GetBitmapBits(True)
        img = Image.frombuffer('RGB', (bmpinfo['bmWidth'], bmpinfo['bmHeight']), bmpstr, 'raw', 'BGRX', 0, 1)
        win32gui.DeleteObject(saveBitMap.GetHandle())
        saveDC.DeleteDC()
        mfcDC.DeleteDC()
        win32gui.ReleaseDC(hwnd, hwndDC)
    elif x is not None and w is not None:
        img = ImageGrab.grab(bbox=(x, y, x+w, y+h))
    else:
        img = ImageGrab.grab()
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return base64.b64encode(buf.getvalue()).decode()

def get_all_windows():
    """Return list of visible windows with titles."""
    windows = []
    def enum_cb(hwnd, _):
        if user32.IsWindowVisible(hwnd):
            buf = ctypes.create_unicode_buffer(256)
            user32.GetWindowTextW(hwnd, buf, 256)
            title = buf.value
            if title:
                rect = ctypes.wintypes.RECT()
                user32.GetWindowRect(hwnd, ctypes.byref(rect))
                windows.append({
                    "hwnd": hwnd,
                    "title": title,
                    "x": rect.left,
                    "y": rect.top,
                    "w": rect.right - rect.left,
                    "h": rect.bottom - rect.top
                })
        return True
    ctypes.windll.user32.EnumWindows(ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_size_t, ctypes.c_size_t)(enum_cb), 0)
    return windows

def find_window(title_substr):
    """Find window by partial title match."""
    for w in get_all_windows():
        if title_substr.lower() in w["title"].lower():
            return w
    return None

def activate_window(hwnd):
    user32.ShowWindow(hwnd, SW_RESTORE)
    user32.SetForegroundWindow(hwnd)
    time.sleep(0.3)

# ─── MCP tools ─────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "screenshot",
        "description": "Take a screenshot of the Windows desktop or a region. Returns base64 PNG.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "x": {"type": "integer", "description": "Left x (optional, for region)"},
                "y": {"type": "integer", "description": "Top y (optional, for region)"},
                "width": {"type": "integer", "description": "Width (optional, for region)"},
                "height": {"type": "integer", "description": "Height (optional, for region)"},
                "window_title": {"type": "string", "description": "Capture specific window by title substr"}
            }
        }
    },
    {
        "name": "click",
        "description": "Click mouse at (x,y). button: left/right/middle. double: true for double-click.",
        "inputSchema": {
            "type": "object",
            "required": ["x", "y"],
            "properties": {
                "x": {"type": "integer"},
                "y": {"type": "integer"},
                "button": {"type": "string", "enum": ["left","right","middle"], "default": "left"},
                "double": {"type": "boolean", "default": False}
            }
        }
    },
    {
        "name": "type_text",
        "description": "Type text at current focus. Use for filling in text fields.",
        "inputSchema": {
            "type": "object",
            "required": ["text"],
            "properties": {
                "text": {"type": "string"},
                "interval": {"type": "number", "description": "Seconds between keystrokes", "default": 0.02}
            }
        }
    },
    {
        "name": "key_press",
        "description": "Press keyboard key(s). Supports combos like 'ctrl+c', 'alt+f4', 'enter', 'tab'.",
        "inputSchema": {
            "type": "object",
            "required": ["key"],
            "properties": {
                "key": {"type": "string"},
                "presses": {"type": "integer", "default": 1}
            }
        }
    },
    {
        "name": "move_mouse",
        "description": "Move mouse to (x,y) without clicking.",
        "inputSchema": {
            "type": "object",
            "required": ["x", "y"],
            "properties": {
                "x": {"type": "integer"},
                "y": {"type": "integer"},
                "duration": {"type": "number", "default": 0.1}
            }
        }
    },
    {
        "name": "scroll",
        "description": "Scroll mouse wheel at (x,y). clicks: positive=up, negative=down.",
        "inputSchema": {
            "type": "object",
            "required": ["x", "y", "clicks"],
            "properties": {
                "x": {"type": "integer"},
                "y": {"type": "integer"},
                "clicks": {"type": "integer"}
            }
        }
    },
    {
        "name": "list_windows",
        "description": "List all visible Windows windows with their titles, positions, and sizes.",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "focus_window",
        "description": "Bring a window to foreground by partial title match.",
        "inputSchema": {
            "type": "object",
            "required": ["title"],
            "properties": {"title": {"type": "string"}}
        }
    },
    {
        "name": "send_message_to_window",
        "description": "Send WM_CLOSE or other Windows message to a window.",
        "inputSchema": {
            "type": "object",
            "required": ["title", "message"],
            "properties": {
                "title": {"type": "string"},
                "message": {"type": "string", "enum": ["close", "minimize", "maximize"]}
            }
        }
    },
    {
        "name": "run_powershell",
        "description": "Run a PowerShell command and return output. For Windows system operations.",
        "inputSchema": {
            "type": "object",
            "required": ["command"],
            "properties": {
                "command": {"type": "string"},
                "timeout": {"type": "integer", "default": 30}
            }
        }
    },
    {
        "name": "get_screen_size",
        "description": "Get primary monitor screen dimensions.",
        "inputSchema": {"type": "object", "properties": {}}
    }
]

# ─── tool execution ─────────────────────────────────────────────────────────

def call_tool(name, args):
    if name == "screenshot":
        wt = args.get("window_title")
        if wt:
            win = find_window(wt)
            if not win:
                return {"error": f"Window '{wt}' not found"}
            activate_window(win["hwnd"])
            time.sleep(0.3)
            img_b64 = screenshot_base64(hwnd=win["hwnd"])
        elif "x" in args and "width" in args:
            img_b64 = screenshot_base64(args["x"], args["y"], args["width"], args["height"])
        else:
            img_b64 = screenshot_base64()
        return [{"type": "image", "data": img_b64, "mimeType": "image/png"}]

    elif name == "click":
        x, y = args["x"], args["y"]
        btn = args.get("button", "left")
        dbl = args.get("double", False)
        pyautogui.moveTo(x, y, duration=0.1)
        time.sleep(0.05)
        if dbl:
            pyautogui.doubleClick(x, y, button=btn)
        else:
            pyautogui.click(x, y, button=btn)
        return {"ok": True, "x": x, "y": y, "button": btn}

    elif name == "type_text":
        interval = args.get("interval", 0.02)
        pyautogui.typewrite(args["text"], interval=interval)
        return {"ok": True, "typed": len(args["text"])}

    elif name == "key_press":
        key = args["key"]
        presses = args.get("presses", 1)
        if "+" in key:
            parts = key.split("+")
            pyautogui.hotkey(*parts)
        else:
            pyautogui.press(key, presses=presses)
        return {"ok": True, "key": key}

    elif name == "move_mouse":
        pyautogui.moveTo(args["x"], args["y"], duration=args.get("duration", 0.1))
        return {"ok": True}

    elif name == "scroll":
        pyautogui.scroll(args["clicks"], x=args["x"], y=args["y"])
        return {"ok": True}

    elif name == "list_windows":
        return get_all_windows()

    elif name == "focus_window":
        win = find_window(args["title"])
        if not win:
            return {"error": f"Window '{args['title']}' not found"}
        activate_window(win["hwnd"])
        return {"ok": True, "window": win}

    elif name == "send_message_to_window":
        win = find_window(args["title"])
        if not win:
            return {"error": f"Window not found"}
        msg_map = {"close": 0x0010, "minimize": 0x0112, "maximize": 0x0112}
        user32.PostMessageW(win["hwnd"], msg_map[args["message"]], 0, 0)
        return {"ok": True}

    elif name == "run_powershell":
        import subprocess
        result = subprocess.run(
            ["powershell.exe", "-Command", args["command"]],
            capture_output=True, text=True,
            timeout=args.get("timeout", 30)
        )
        return {
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "returncode": result.returncode
        }

    elif name == "get_screen_size":
        w, h = pyautogui.size()
        return {"width": w, "height": h}

    else:
        return {"error": f"Unknown tool: {name}"}

# ─── MCP JSON-RPC server ─────────────────────────────────────────────────────

def send_response(resp):
    line = json.dumps(resp, ensure_ascii=False) + "\n"
    sys.stdout.write(line)
    sys.stdout.flush()

def handle_request(req):
    method = req.get("method", "")
    req_id = req.get("id")
    params = req.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0", "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "win-gui-mcp", "version": "1.0.0"}
            }
        }
    elif method == "notifications/initialized":
        return None
    elif method == "tools/list":
        return {
            "jsonrpc": "2.0", "id": req_id,
            "result": {"tools": TOOLS}
        }
    elif method == "tools/call":
        tool_name = params.get("name", "")
        tool_args = params.get("arguments", {})
        try:
            result = call_tool(tool_name, tool_args)
            if isinstance(result, list):
                content = result
            elif isinstance(result, dict) and "error" in result:
                content = [{"type": "text", "text": f"Error: {result['error']}"}]
            else:
                content = [{"type": "text", "text": json.dumps(result, ensure_ascii=False)}]
            return {
                "jsonrpc": "2.0", "id": req_id,
                "result": {"content": content, "isError": False}
            }
        except Exception as e:
            return {
                "jsonrpc": "2.0", "id": req_id,
                "result": {"content": [{"type": "text", "text": f"Error: {e}"}], "isError": True}
            }
    elif method == "ping":
        return {"jsonrpc": "2.0", "id": req_id, "result": {}}
    else:
        if req_id is not None:
            return {
                "jsonrpc": "2.0", "id": req_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"}
            }
        return None

def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError:
            continue
        resp = handle_request(req)
        if resp is not None:
            send_response(resp)

if __name__ == "__main__":
    main()
