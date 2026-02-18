#!/usr/bin/env python3
"""
TOTAL UP BLOCK - Blocks 100% of UP scrolls
"""
import evdev
from evdev import UInput, ecodes as e
import time
import sys

print("TOTAL UP BLOCK starting...", file=sys.stderr)

# ── Find Razer Orochi ──
devices = []
for path in evdev.list_devices():
    try:
        dev = evdev.InputDevice(path)
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
            print(f"Selected: {dev.path} → {dev.name}", file=sys.stderr)
            break
        elif not devices:
            devices = [dev]
            print(f"Fallback: {dev.path} → {dev.name}", file=sys.stderr)
    except:
        pass

if not devices:
    print("ERROR: No device found", file=sys.stderr)
    sys.exit(1)

primary = devices[0]

# ── Create virtual ──
caps = primary.capabilities()
clean_caps = {k: v for k, v in caps.items() if k not in [e.EV_SYN, e.EV_FF, e.EV_PWR]}
uinput = UInput(clean_caps, name="Filtered", vendor=0x1532, product=0x0094, bustype=0x0003)
print(f"Virtual: {uinput.device.path}", file=sys.stderr)
time.sleep(0.8)

# ── Grab ──
try:
    primary.grab()
    print(f"Grabbed: {primary.path}", file=sys.stderr)
except Exception as ex:
    print(f"ERROR: {ex}", file=sys.stderr)
    sys.exit(1)

print("\n" + "="*60, file=sys.stderr)
print("BLOCKING ALL UP SCROLLS", file=sys.stderr)
print("Try scrolling UP - it should NOT work", file=sys.stderr)
print("="*60 + "\n", file=sys.stderr)

up_blocked = 0
down_passed = 0

try:
    for event in primary.read_loop():
        if event.type == e.EV_REL and event.code == e.REL_WHEEL:
            if event.value > 0:
                # UP - BLOCK
                up_blocked += 1
                print(f"✗ BLOCKED UP (total: {up_blocked})", file=sys.stderr)
                continue
            else:
                # DOWN - PASS
                down_passed += 1
                uinput.write(e.EV_REL, e.REL_WHEEL, -1)
                uinput.syn()
                print(f"✓ PASSED DOWN (total: {down_passed})", file=sys.stderr)
                continue
        
        elif event.type == e.EV_REL and event.code == e.REL_WHEEL_HI_RES:
            # Ignore hi-res
            pass
        
        else:
            # Pass everything else
            uinput.write_event(event)
            if event.type == e.EV_SYN:
                uinput.syn()

except KeyboardInterrupt:
    print(f"\nBlocked: {up_blocked} | Passed: {down_passed}", file=sys.stderr)

finally:
    try:
        primary.ungrab()
    except:
        pass
    uinput.close()
