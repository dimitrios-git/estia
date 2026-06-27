#!/bin/sh
# vifm quick-view dispatcher — the catch-all `fileviewer {*}` in vifmrc.
# Syntax-highlights text/code with bat (wildcharm theme), and degrades cleanly:
# directory listing for dirs, file-type + hexdump peek for binaries, and plain
# head(1) when bat isn't installed. Always exits 0 so vifm never shows an error.
#
#   $1 = file path (vifm %f)   $2 = pane width (%pw)   $3 = pane height (%ph)
#
# bat needs the wildcharm theme built into its cache once: `bat cache --build`
# after ~/.config/bat/themes/wildcharm.tmTheme is in place (the dotfiles role
# does this). Until then bat falls back to its default theme.

f="$1"
w="${2:-80}"
h="${3:-40}"

# bat is `bat` on most distros but `batcat` on Debian/Ubuntu — accept either.
BAT=""
if command -v bat >/dev/null 2>&1; then
    BAT=bat
elif command -v batcat >/dev/null 2>&1; then
    BAT=batcat
fi

bat_view() {
    "$BAT" --color=always --style=plain --paging=never --wrap=never \
           --theme=wildcharm --terminal-width="$w" --line-range=":$h" -- "$f"
}

if [ -d "$f" ]; then
    # Directory: a quick listing (dirs first), capped to the pane height.
    ls -A --group-directories-first -- "$f" 2>/dev/null || ls -A -- "$f"
    exit 0
fi

mime=$(file -Lb --mime-type -- "$f" 2>/dev/null)

case "$mime" in
    inode/x-empty)
        echo "(empty file)"
        ;;
    text/* | application/json | application/javascript | application/xml \
    | application/x-shellscript | application/x-yaml | application/x-toml \
    | application/x-perl | application/x-php | application/x-ruby \
    | *+json | *+xml)
        if [ -n "$BAT" ]; then
            bat_view
        else
            head -n "$h" -- "$f"
        fi
        ;;
    *)
        # Binary (or unknown): describe it, then a short hex peek.
        file -Lb -- "$f"
        echo
        if command -v hexdump >/dev/null 2>&1; then
            peek=$((h - 4)); [ "$peek" -lt 4 ] && peek=4
            hexdump -C -- "$f" 2>/dev/null | head -n "$peek"
        fi
        ;;
esac

exit 0
