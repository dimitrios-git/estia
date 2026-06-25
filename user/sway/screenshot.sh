#!/usr/bin/env sh
# screenshot.sh — region screenshot, saved either locally or to the shared tree.
#
# Bound in the sway config to Print (local) and $mod+Print (shared). A SHARED
# shot lands in /srv/clipshare, which the unprivileged `claude` user can Read
# (devshare group + the tree's default ACLs) — this is the supported way to
# show Claude Code an image: it runs as a separate user, walled off from this
# session's Wayland clipboard, so a Ctrl+V image paste into it can't work. Just
# take a shared shot, then tell claude "look at the screenshot". A LOCAL shot
# stays in ~/Pictures/Screenshots and is never exposed to claude.
#
# Usage: screenshot.sh [local|shared]   (default: local)
#
# `shared` falls back to the local dir when /srv/clipshare isn't provisioned
# (a spin without the claude_user feature), so the binding works either way —
# the notification shows where the file actually landed.

set -eu

local_dir="$HOME/Pictures/Screenshots"

case "${1:-local}" in
    shared)
        if [ -d /srv/clipshare ] && [ -w /srv/clipshare ]; then
            dir=/srv/clipshare
        else
            dir="$local_dir"
        fi
        ;;
    *)
        dir="$local_dir"
        ;;
esac
mkdir -p "$dir"

# Region select; exit cleanly if slurp is cancelled (Esc/right-click).
geom=$(slurp) || exit 0
out="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
grim -g "$geom" "$out"

notify-send "Screenshot saved" "$out"
