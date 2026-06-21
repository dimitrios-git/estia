#!/bin/sh
# Live GPU monitor for the waybar custom/gpu click handler (toggled in a floatterm).
# Picks the best tool for whatever GPU is present, falling back to a no-extra-tool
# sysfs poll so it still works on an AMD box without amdgpu_top installed.
# The waybar on-click matches this script's path to toggle the window.

if command -v nvidia-smi    >/dev/null 2>&1; then exec watch -n 1 nvidia-smi; fi
if command -v amdgpu_top    >/dev/null 2>&1; then exec amdgpu_top; fi
if command -v radeontop     >/dev/null 2>&1; then exec radeontop; fi
if command -v intel_gpu_top >/dev/null 2>&1; then exec intel_gpu_top; fi

# Fallback: our own 1 s refresh loop over the first DRM card exposing utilisation.
for d in /sys/class/drm/card[0-9]*/device; do
    [ -r "$d/gpu_busy_percent" ] || continue
    while :; do
        clear
        echo "GPU  ($(basename "$(dirname "$d")"))"
        echo "  busy : $(cat "$d/gpu_busy_percent")%"
        for t in "$d"/hwmon/hwmon*/temp1_input; do
            [ -r "$t" ] && echo "  temp : $(( $(cat "$t") / 1000 ))°C"
        done
        if [ -r "$d/mem_info_vram_used" ] && [ -r "$d/mem_info_vram_total" ]; then
            echo "  vram : $(( $(cat "$d/mem_info_vram_used")/1048576 )) / $(( $(cat "$d/mem_info_vram_total")/1048576 )) MiB"
        fi
        sleep 1
    done
done

echo "No GPU monitoring tool or sysfs counters found."
sleep 3
