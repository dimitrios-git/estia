# Sway session launcher (`start-sway`)

`start-sway` is what greetd actually runs to start the desktop
(`/etc/greetd/config.toml` → `tuigreet … --cmd start-sway`). It sets the Wayland
session environment and `exec`s sway.

- **Tracked file:** `system/sway-session/start-sway`
- **Deployed to:** `/usr/local/bin/start-sway` (root, `0755`) by the **`sway_session`**
  bootstrap role (`ansible-playbook site.yml --tags sway_session`).

## NVIDIA workarounds are conditional

The proprietary-driver env (`GBM_BACKEND=nvidia-drm`,
`__GLX_VENDOR_LIBRARY_NAME=nvidia`, `WLR_NO_HARDWARE_CURSORS=1`,
`NVIDIA_DRIVER_CAPABILITIES=all`) and the `--unsupported-gpu` flag are applied **only
when an NVIDIA GPU is live** — detected at launch via `/dev/nvidia0` or the `nvidia`
entry in `/proc/modules`. On an AMD/Intel box none of that is exported (those vars
would otherwise break rendering), so the same script is correct everywhere. The
generic Wayland env (`XDG_*`, `MOZ_ENABLE_WAYLAND`, `GTK_THEME`) is always set.

Pairs with the opt-in `nvidia` role (`enable_nvidia`), but doesn't depend on it — the
guard is on the *running* hardware, not the install toggle.

## Still manual

`/etc/greetd/config.toml` (the `--cmd start-sway` line) is **not** tracked yet — set
it up by hand when installing greetd/tuigreet (runbook §0). Everything else about the
launcher is reproduced by the role.
