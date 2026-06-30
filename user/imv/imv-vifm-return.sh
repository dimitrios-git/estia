#!/bin/sh
# imv-vifm-return.sh — run by imv (config-vifm) on quit, when imv was launched
# from vifm's image-browse key. Kept as a script so imv's bind is trivial
# (`exec …/imv-vifm-return.sh`): imv's command parser splits binds on ';' and
# treats each part as an IMV command, so a shell pipeline written inline gets
# mis-split (that's why an inline `; imv-msg … quit` never closed imv). A bare
# script path has nothing to misparse.
#
# imv exposes its state as env vars to exec'd commands; we use:
#   $imv_current_file  — the image shown when the user quit
#   $imv_pid           — this imv instance (for imv-msg / kill)
#
# Restore vifm's dual-pane preview, move its cursor onto that image (:goto
# SELECTS without opening — a plain `--remote <file>` would re-open it), then
# close imv. vifm --remote no-ops if no vifm server is running.

vifm --remote -c 'vsplit' -c 'view!' -c "goto '$imv_current_file'"

# Ask imv to quit, then guarantee it (kill the same pid) in case imv-msg is a
# no-op here — the sync above has already run, so this only closes the window.
imv-msg "$imv_pid" quit 2>/dev/null
kill "$imv_pid" 2>/dev/null
