# Theming estia

estia has one look: a **dark theme** on near-black `#0a0a0a`, accent **official Debian
red `#ce0056`**, and a saturated **16-colour palette from the `wildcharm` vim
colorscheme**. This doc is the **process** for bringing a new app onto that look. The
colours themselves live in one place — **`themes/wildcharm/palette.yml`** (the single
source of truth) — so this doc never repeats hex values; it tells you how to apply them.

> **How the system works today.** The palette is applied **by hand**: you read the right
> value from `palette.yml` and write the literal hex into the app's own config, which is
> then deployed by the bootstrap (symlinked or rendered). Configs stay directly editable.
> A future Ansible/Jinja2 step could render `palette.yml` straight into configs and remove
> the hand-copying (`docs/repo-structure-design.md` §9.3) — `palette.yml` is already
> shaped for that — but that engine is **deferred**; for now, follow the steps below.

## The per-app process

1. **Identify** the app's colour mechanism. Common shapes:
   - *Terminal/TUI* (kitty, cmus, cava, vifm) → an ANSI 16-colour table or `colorN` slots.
   - *GTK/CSS* (waybar, wofi) → a stylesheet with `color`/`background-color`.
   - *key=value config* (mako, swaylock, zathura) → named colour options.
   - *Own colorscheme format* (vim `wildcharm`, vifm `.vifm`, glow glamour JSON).
   - *GTK app theme* (GNOME/libadwaita) → named theme colours / `gtk.css` — the hard case.
2. **Map** each colour surface to a palette entry:
   - GUI chrome → a **role** (`bg`, `surface`, `border`, `text`, `dim`, `accent`, …).
   - Terminal colour slots → the matching **`ansi`** name.
   Decide the mapping in role/ANSI *names* first; it makes intent reviewable.
3. **Apply** the hex from `palette.yml`. Copy the literal value (strip the leading `#` for
   tools that want bare `RRGGBB`, e.g. swaylock). **Never invent a shade** — if the app
   genuinely needs one the palette lacks, **add it to `palette.yml` first** (with a comment),
   then use it. That keeps the SSOT complete.
4. **Deploy** via the bootstrap manifest (`bootstrap/group_vars/all.yml`):
   - Static config → add to **`dotfile_links`** (symlinked; stays direct-editable).
   - Only if it must carry a host/identity/path value → **`templated_configs`** (`.j2`).
   - If you touched `dotfile_links`, run **`bootstrap/gen-symlink-table.py`** to regenerate
     the symlink table in `CLAUDE.md`.
5. **Verify** live — reload the app and eyeball **every state** (idle/active/hover/error,
   focused/unfocused, etc.), not just the happy path.
6. **Document** — add or update the app's section in `CLAUDE.md`, and **tick the status
   table** below.

## Status

Legend: ✅ themed · 🟡 partial · ⬜ not yet.

| App | Mechanism | Status | Notes |
|---|---|---|---|
| kitty | ANSI 16 + roles | ✅ | the canonical 16-colour definition |
| sway | `$bg/$surface/…` vars | ✅ | window borders, urgent |
| waybar | GTK CSS | ✅ | bar + tooltips |
| swaylock | key=value config | ✅ | `user/swaylock/config`; all indicator states |
| swaynag | key=value + `[type]` | ✅ | `user/swaynag/config`; exit/warning/error dialogs |
| mako | key=value config | ✅ | notifications, urgent variant |
| wofi | GTK CSS | ✅ | launcher |
| cava | gradient config | ✅ | 8-stop accent gradient |
| cmus | cterm slots (rc) | ✅ | accent tracks ANSI red |
| vifm | `.vifm` colorscheme | ✅ | file-type colours from the ANSI set |
| glow | glamour JSON | ✅ | markdown render theme |
| vim / nvim | `wildcharm` scheme | ✅ | external plugin + render-markdown accent |
| zathura | key=value config | ✅ | `user/zathura/zathurarc`; UI chrome + document recolour (dark mode on, `r` toggles) |
| GNOME / Adwaita | libadwaita / `gtk.css` | ⬜ | **the hard one** — a named-colour Adwaita variant; its own future sub-design |
| Firefox / PWAs | userChrome / theme | ⬜ | later |

Add a row when you start a new app; flip it to ✅ when it passes step 5.
