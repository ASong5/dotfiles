#!/usr/bin/env python3
"""
Razer Orochi V2 - Pure verbose logger (no filtering, no virtual device)
Logs every raw REL_WHEEL event with timestamp, direction, value.
Shows running stats and rough reversal rate.
Uses the same permissive device detection as your working filter.
"""

import evdev
from evdev import InputDevice, ecodes as e
import time
import sys

print("Starting raw scroll event logger for Razer Orochi V2...", file=sys.stderr)
print("No filtering — logging every REL_WHEEL event.", file=sys.stderr)
print("Press Ctrl+C to stop and see final stats.\n", file=sys.stderr)

# ── Find device (same logic as your working filter) ──
devices = []
for path in evdev.list_devices():
    try:
        dev = InputDevice(path)
        name_lower = dev.name.lower()
        if 'razer' not in name_lower or 'orochi' not in name_lower or 'filtered' in name_lower:
            continue
        caps = dev.capabilities()
        if e.EV_REL not in caps:
            continue
        rel_codes = caps.get(e.EV_REL, [])
        if e.REL_WHEEL not in rel_codes and e.REL_WHEEL_HI_RES not in rel_codes:
            continue
        if 'mouse' not in name_lower:
            devices = [dev]
            print(f"Selected primary: {dev.path} → {dev.name}", file=sys.stderr)
            break
        elif not devices:
            devices = [dev]
            print(f"Fallback selected: {dev.path} → {dev.name}", file=sys.stderr)
    except:
        pass

if not devices:
    print("ERROR: No suitable Razer Orochi V2 device found.", file=sys.stderr)
    print("Try running with sudo, or check 'evtest' to see exact device names.", file=sys.stderr)
    sys.exit(1)

mouse = devices[0]

# ── Grab the device ──
try:
    mouse.grab()
    print(f"Successfully grabbed: {mouse.path}", file=sys.stderr)
except Exception as ex:
    print(f"Grab failed: {ex}", file=sys.stderr)
    print("This usually means another process has grabbed it (e.g. your filter script is running).", file=sys.stderr)
    print("Stop any other mouse scripts first.", file=sys.stderr)
    sys.exit(1)

# ── Stats ──
total_scrolls = 0
up_count = 0
down_count = 0
reversals_detected = 0
last_direction = None
last_time = 0.0

print("\nLogging started. Every raw scroll event will be printed below.")
print("Format: [timestamp] direction value (total so far)\n", file=sys.stderr)

try:
    for event in mouse.read_loop():
        if event.type == e.EV_REL and event.code == e.REL_WHEEL:
            current_time = time.time()
            direction = "UP" if event.value > 0 else "DOWN"
            value = event.value

            total_scrolls += 1

            if direction == "UP":
                up_count += 1
            else:
                down_count += 1

            # Rough immediate reversal detection
            reversal_note = ""
            if last_direction is not None and direction != last_direction:
                time_diff_ms = (current_time - last_time) * 1000
                if time_diff_ms < 500:
                    reversals_detected += 1
                    reversal_note = f"  ^^^ REVERSAL ({time_diff_ms:.0f} ms) ^^^"

            last_direction = direction
            last_time = current_time

            # Verbose log
            ts = time.strftime("%H:%M:%S", time.localtime(current_time))
            print(f"[{ts}] {direction:<4} value={value:>3}   (total: {total_scrolls}){reversal_note}")

            # Periodic stats
            if total_scrolls % 20 == 0 and total_scrolls > 0:
                reversal_rate = (reversals_detected / total_scrolls * 100) if total_scrolls > 0 else 0
                print(f"\n--- Stats @ {total_scrolls} events ---")
                print(f"  Up: {up_count}   Down: {down_count}")
                print(f"  Quick reversals detected: {reversals_detected}")
                print(f"  Rough reversal rate: {reversal_rate:.2f}%")
                print("---------------------------\n")

except KeyboardInterrupt:
    print("\n" + "="*60, file=sys.stderr)
    print("Logger stopped.", file=sys.stderr)
    print(f"Total scroll events: {total_scrolls}")
    print(f"Up scrolls:          {up_count}")
    print(f"Down scrolls:        {down_count}")
    reversal_rate = (reversals_detected / total_scrolls * 100) if total_scrolls > 0 else 0
    print(f"Quick reversals detected: {reversals_detected}")
    print(f"Rough reversal/phantom rate: {reversal_rate:.2f}%")
    print("="*60, file=sys.stderr)

finally:
    try:
        mouse.ungrab()
        print("Device ungrabbed.", file=sys.stderr)
    except:
        pass
    print("Done.", file=sys.stderr)
