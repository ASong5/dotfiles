#!/usr/bin/env python3
"""
Razer Orochi V2 - Pure verbose logger (no filtering)
Improved device detection to match your working filter's priority.
Prints all candidates for debugging.
"""

import evdev
from evdev import InputDevice, ecodes as e
import time
import sys

print("Starting raw scroll event logger for Razer Orochi V2...", file=sys.stderr)
print("No filtering — logging every REL_WHEEL event.", file=sys.stderr)
print("Press Ctrl+C to stop and see final stats.\n", file=sys.stderr)

# ── Find device with same priority as your filter ──
candidates = []
preferred = None
fallback = None

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
        
        candidates.append((path, dev.name))
        
        # Priority: prefer non-"mouse" name
        if 'mouse' not in name_lower:
            preferred = dev
            print(f"Preferred candidate (no 'mouse' in name): {path} → {dev.name}", file=sys.stderr)
        else:
            if fallback is None:
                fallback = dev
                print(f"Fallback candidate ('mouse' in name): {path} → {dev.name}", file=sys.stderr)
    
    except Exception as ex:
        print(f"Skipped {path}: {ex}", file=sys.stderr)

# Select best
mouse = preferred if preferred else fallback

if not mouse:
    print("\nERROR: No suitable Razer Orochi V2 device found.", file=sys.stderr)
    print("Candidates found:", file=sys.stderr)
    for p, n in candidates:
        print(f"  {p} → {n}", file=sys.stderr)
    print("Try: sudo evtest and scroll to see which event# shows REL_WHEEL", file=sys.stderr)
    sys.exit(1)

print(f"\nSelected: {mouse.path} → {mouse.name}", file=sys.stderr)

# ── Grab ──
try:
    mouse.grab()
    print(f"Grabbed successfully: {mouse.path}", file=sys.stderr)
except Exception as ex:
    print(f"Grab failed: {ex}", file=sys.stderr)
    print("Stop any other scripts (e.g. your filter) that may have grabbed it.", file=sys.stderr)
    sys.exit(1)

# ── Stats & Logging ──
total_scrolls = 0
up_count = 0
down_count = 0
reversals_detected = 0
last_direction = None
last_time = 0.0

print("\nLogging started. Scroll the wheel now.", file=sys.stderr)
print("Format: [time] direction value (total)\n", file=sys.stderr)

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

            reversal_note = ""
            if last_direction and direction != last_direction:
                time_diff_ms = (current_time - last_time) * 1000
                if time_diff_ms < 500:
                    reversals_detected += 1
                    reversal_note = f"  ^^^ REVERSAL ({time_diff_ms:.0f} ms) ^^^"

            last_direction = direction
            last_time = current_time

            ts = time.strftime("%H:%M:%S", time.localtime(current_time))
            print(f"[{ts}] {direction:<4} value={value:>3}   (total: {total_scrolls}){reversal_note}")

            if total_scrolls % 20 == 0 and total_scrolls > 0:
                rate = (reversals_detected / total_scrolls * 100) if total_scrolls else 0
                print(f"\n--- Stats @ {total_scrolls} --- Up: {up_count} Down: {down_count} Reversals: {reversals_detected} ({rate:.2f}%) ---\n")

except KeyboardInterrupt:
    rate = (reversals_detected / total_scrolls * 100) if total_scrolls else 0
    print("\n" + "="*50, file=sys.stderr)
    print(f"Stopped. Total scrolls: {total_scrolls}")
    print(f"Up: {up_count}   Down: {down_count}")
    print(f"Quick reversals: {reversals_detected} ({rate:.2f}%)")
    print("="*50, file=sys.stderr)

finally:
    try:
        mouse.ungrab()
    except:
        pass
    print("Done.", file=sys.stderr)
