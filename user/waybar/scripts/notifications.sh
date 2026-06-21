#!/bin/sh
# Notification-history viewer for the waybar custom/notifications bell. `show` reads
# mako's history (`makoctl history`) and opens a readable list in a pager (the on-click
# runs it in a floatterm). Robust to mako's output: this build of mako prints a
# human-readable text block per notification (no JSON, and NO timestamp — mako doesn't
# record arrival times); older builds print JSON. Both are formatted to one line each.

if [ "$1" = show ]; then
    python3 - <<'PY' | less -R
import json, subprocess, sys, re

try:
    p = subprocess.run(["makoctl", "history"], capture_output=True, text=True, timeout=5)
except Exception as e:
    print("Failed to run makoctl:", e); sys.exit()

raw = (p.stdout or "").strip()
if not raw:
    err = (p.stderr or "").strip()
    if p.returncode != 0 and err:
        print("Could not reach mako:", err)
    else:
        print("No notifications in history yet.")
        print("(mako keeps dismissed/expired notifications — wait for one to time out, "
              "or dismiss it, then check again.)")
    sys.exit()

def header(n):
    print(f"Notification history — {n} item(s)\n" + "─" * 44)

# 1) JSON ({"data": [[ {notif}, … ]]}) — older mako builds.
try:
    d = json.loads(raw)
    items = d.get("data") if isinstance(d, dict) else d
    while isinstance(items, list) and len(items) == 1 and isinstance(items[0], list):
        items = items[0]
except Exception:
    items = None
if isinstance(items, list):
    if not items:
        print("No notifications in history yet."); sys.exit()
    def field(n, k):
        v = n.get(k) if isinstance(n, dict) else None
        return v.get("data") if isinstance(v, dict) else (v if v is not None else "")
    header(len(items))
    for n in items:
        app = field(n, "app-name") or "?"
        summ = field(n, "summary")
        print(f"● {summ or app}" + (f"   ·   {app}" if summ and app else ""))
        for ln in str(field(n, "body")).splitlines():
            if ln:
                print(f"    {ln}")
    sys.exit()

# 2) makoctl's human-readable text — "Notification N: <summary>" + indented "App name:".
entries = []
cur = None
for line in raw.splitlines():
    m = re.match(r"^Notification \d+:\s*(.*)", line)
    if m:
        if cur:
            entries.append(cur)
        cur = {"summary": m.group(1).strip(), "app": ""}
    elif cur is not None:
        a = re.match(r"^\s+App name:\s*(.*)", line)
        if a:
            cur["app"] = a.group(1).strip()
if cur:
    entries.append(cur)
if entries:
    header(len(entries))
    for e in entries:
        print(f"● {e['summary'] or '(no summary)'}" + (f"   ·   {e['app']}" if e["app"] else ""))
    sys.exit()

# 3) Unknown format — show it verbatim.
print(raw)
PY
    exit 0
fi

# (No bar output — the waybar module is a static bell; this script only serves `show`.)
exit 0
