#!/bin/sh
# imv-vifm-return.sh [quit|up] — run by imv (config-vifm) when imv was launched
# from vifm's image-browse. Kept as a script so imv binds stay trivial
# (`exec …/imv-vifm-return.sh [mode]`): imv splits binds on ';' and parses each
# part as an imv command, and inline shell quoting in a bind gets mangled — a
# bare script path has nothing to misparse. imv exposes its state as env vars to
# exec'd commands; we use $imv_current_file (image shown) and $imv_pid.
#
#   (no arg)  live sync — move vifm's cursor onto the current image (each j/k)
#   quit      also restore vifm's dual-pane preview, then close imv (q)
#   up        restore the preview + take vifm UP one dir, then close imv (h) —
#             vifm's cursor lands on the folder you were browsing
#
# :goto SELECTS without opening (a plain `--remote <file>` would re-open it).
# vifm --remote no-ops if no vifm server is running.

close_imv() {
    # ask imv to quit, then guarantee the window closes
    imv-msg "$imv_pid" quit 2>/dev/null
    kill "$imv_pid" 2>/dev/null
}

case "$1" in
    quit)
        vifm --remote -c 'vsplit' -c 'view!' -c "goto '$imv_current_file'"
        close_imv
        ;;
    up)
        # Up one dir from the IMAGE's folder (absolute), not vifm's current dir —
        # the user may have changed vifm's cwd while imv was open. :goto <dir>
        # cd's to that dir's parent and puts the cursor on it.
        vifm --remote -c 'vsplit' -c 'view!' -c "goto '$(dirname "$imv_current_file")'"
        close_imv
        ;;
    *)
        vifm --remote -c "goto '$imv_current_file'"
        ;;
esac
