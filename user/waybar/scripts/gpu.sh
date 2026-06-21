#!/bin/sh
# Waybar custom/gpu — GPU utilisation % in the bar; card name / temp / VRAM in the
# hover tooltip. Multi-vendor:
#   * NVIDIA via nvidia-smi
#   * AMD    via amdgpu sysfs (gpu_busy_percent / hwmon / mem_info_vram_*) — no tools
#   * Intel  via sysfs, best-effort (i915 exposes no utilisation counter → name+temp)
# Prints NOTHING when no supported GPU is found, so Waybar hides the whole module
# (icon included) — keeps the config portable. Priority on a multi-GPU box:
# NVIDIA > AMD/sysfs > Intel (show the discrete card).

# --- NVIDIA (nvidia-smi) ------------------------------------------------------
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,name \
        --format=csv,noheader,nounits 2>/dev/null | head -1 | awk -F', *' '
        { printf "{\"text\":\"%s%%\",\"tooltip\":\"%s\\n%s%% · %s°C · %s / %s MiB\"}\n", \
                 $1, $5, $1, $2, $3, $4 }'
    exit 0
fi

# first hwmon temp (°C, rounded) under a DRM device dir, or empty
drm_temp() {
    for t in "$1"/hwmon/hwmon*/temp1_input; do
        [ -r "$t" ] || continue
        awk '{printf "%d", $1/1000; exit}' "$t"; return
    done
}

# PCI marketing name via lspci (best-effort), else the $2 fallback
drm_name() {
    _pci=$(basename "$(readlink -f "$1")" 2>/dev/null)
    _name=""
    if command -v lspci >/dev/null 2>&1 && [ -n "$_pci" ]; then
        _name=$(lspci -s "${_pci#0000:}" 2>/dev/null | sed 's/.*: //; s/ (rev .*)//' | head -1)
    fi
    [ -n "$_name" ] && printf '%s' "$_name" || printf '%s' "$2"
}

# --- AMD / any DRM card exposing gpu_busy_percent (also covers Intel Xe) -------
for d in /sys/class/drm/card[0-9]*/device; do
    [ -r "$d/gpu_busy_percent" ] || continue
    case "$(cat "$d/vendor" 2>/dev/null)" in
        0x1002) fb="AMD GPU" ;; 0x8086) fb="Intel GPU" ;; *) fb="GPU" ;;
    esac
    util=$(cat "$d/gpu_busy_percent" 2>/dev/null)
    temp=$(drm_temp "$d")
    tip="$(drm_name "$d" "$fb")\\n${util}%"
    [ -n "$temp" ] && tip="$tip · ${temp}°C"
    if [ -r "$d/mem_info_vram_used" ] && [ -r "$d/mem_info_vram_total" ]; then
        used=$(awk '{printf "%d", $1/1048576; exit}' "$d/mem_info_vram_used")
        total=$(awk '{printf "%d", $1/1048576; exit}' "$d/mem_info_vram_total")
        tip="$tip · ${used} / ${total} MiB"
    fi
    printf '{"text":"%s%%","tooltip":"%s"}\n' "$util" "$tip"
    exit 0
done

# --- Intel i915 (no gpu_busy_percent): name + temp only -----------------------
for d in /sys/class/drm/card[0-9]*/device; do
    [ "$(cat "$d/vendor" 2>/dev/null)" = 0x8086 ] || continue
    temp=$(drm_temp "$d")
    tip="$(drm_name "$d" "Intel GPU")"
    [ -n "$temp" ] && tip="$tip\\n${temp}°C"
    tip="$tip\\n(utilisation needs intel-gpu-tools)"
    printf '{"text":"GPU","tooltip":"%s"}\n' "$tip"
    exit 0
done

# No supported GPU → print nothing so Waybar hides the module.
exit 0
