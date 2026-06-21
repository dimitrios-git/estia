#!/bin/sh
# Notification-history viewer for the waybar custom/notifications bell. `show` formats
# mako's history (makoctl history → JSON) into a readable, most-recent-first list and
# opens it in a pager (the on-click handler runs it in a floatterm).

if [ "$1" = show ]; then
    python3 - <<'PY' | less -R
import json, subprocess, datetime

def field(n, k):
    v = n.get(k)
    return v.get("data") if isinstance(v, dict) else (v if v is not None else "")

try:
    out = subprocess.run(["makoctl", "history"], capture_output=True, text=True, timeout=5).stdout
    items = (json.loads(out).get("data") or [[]])[0]
except Exception as e:
    print("Could not read notification history:", e)
    raise SystemExit

if not items:
    print("No notifications in history.")
    raise SystemExit

print(f"Notification history — {len(items)} item(s)\n" + "─" * 48)
for n in items:
    app = field(n, "app-name") or "?"
    summ = field(n, "summary")
    body = field(n, "body")
    ts = field(n, "time")
    when = ""
    try:
        when = datetime.datetime.fromtimestamp(int(ts)).strftime("%a %H:%M") if ts else ""
    except Exception:
        when = ""
    head = f"● {app}"
    if when:
        head += f"  ({when})"
    print(head)
    if summ:
        print(f"  {summ}")
    if body:
        for line in str(body).splitlines():
            print(f"    {line}")
    print()
PY
    exit 0
fi

# (No bar output — the waybar module is a static bell; this script only serves `show`.)
exit 0
