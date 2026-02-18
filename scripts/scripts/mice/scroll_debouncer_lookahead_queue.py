#!/usr/bin/env python3
"""
Razer Orochi V2 - Pattern-based filter with confirmation window
Uses look-ahead to detect if a direction change is sustained or bounces back
"""
import evdev
from evdev import UInput, ecodes as e
import time
import sys
from collections import deque
import threading

print("Pattern-based filter with confirmation window starting...", file=sys.stderr)

# ── Find device ──
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
uinput = UInput(clean_caps, name="Razer Orochi V2 Filtered", vendor=0x1532, product=0x0094, bustype=0x0003)
print(f"Virtual: {uinput.device.path}", file=sys.stderr)
time.sleep(0.8)

# ── Grab ──
try:
    primary.grab()
    print(f"Grabbed: {primary.path}", file=sys.stderr)
except Exception as ex:
    print(f"ERROR: {ex}", file=sys.stderr)
    sys.exit(1)

print("\nPattern-based filter: fast threshold + confirmation window for slow changes", file=sys.stderr)
print("Fast reversals (<50ms) blocked immediately", file=sys.stderr)
print("Slow reversals (50-800ms) wait 80ms to see if sustained\n", file=sys.stderr)

# ── State ──
FAST_THRESHOLD_MS = 50       # Block immediately if under this
CONFIRMATION_WINDOW_MS = 80  # Wait this long to confirm slow direction changes
MAX_DELAY_MS = 800          # Apply confirmation to reversals up to this timing

last_scroll_time = {}
last_any_scroll_time = 0
pending_scroll = None  # (timestamp, direction, timer_handle)
blocked_count = 0
emitted_count = 0
event_num = 0
pending_lock = threading.Lock()

def emit_scroll(direction, reason=""):
    global emitted_count
    emit_val = 1 if direction > 0 else -1
    uinput.write(e.EV_REL, e.REL_WHEEL, emit_val)
    uinput.syn()
    emitted_count += 1
    dir_str = "UP" if direction > 0 else "DOWN"
    if reason:
        print(f"✓ EMIT {dir_str} {reason} | total: {emitted_count}", file=sys.stderr)

def emit_pending_scroll():
    """Called by timer - emit the pending scroll if still valid"""
    global pending_scroll, blocked_count
    
    with pending_lock:
        if pending_scroll is None:
            return
        
        pending_time, pending_dir, _ = pending_scroll
        time_since_opposite = None
        opposite_direction = -pending_dir
        
        if opposite_direction in last_scroll_time:
            time_since_opposite = (time.time() - last_scroll_time[opposite_direction]) * 1000
        
        # Check if we scrolled back in the original direction during the wait
        # If so, the direction change was a phantom
        if pending_dir in last_scroll_time:
            if last_scroll_time[pending_dir] > pending_time:
                # We scrolled in pending direction AFTER it was queued
                # This means pattern was: opposite → pending(phantom) → opposite(confirmed)
                # The pending was a phantom bounce
                blocked_count += 1
                dir_str = "UP" if pending_dir > 0 else "DOWN"
                print(f"✗ BLOCK {dir_str} (bounced back within {CONFIRMATION_WINDOW_MS}ms) | total: {blocked_count}", file=sys.stderr)
                pending_scroll = None
                return
        
        # Confirmed - emit it
        emit_scroll(pending_dir, f"[CONFIRMED after {CONFIRMATION_WINDOW_MS}ms wait]")
        last_scroll_time[pending_dir] = time.time()
        pending_scroll = None

try:
    for event in primary.read_loop():
        current_time = time.time()
        
        if event.type == e.EV_REL and event.code == e.REL_WHEEL:
            direction = 1 if event.value > 0 else -1
            opposite_direction = -direction
            event_num += 1
            
            # Calculate timing
            time_since_opposite = None
            if opposite_direction in last_scroll_time:
                time_since_opposite = (current_time - last_scroll_time[opposite_direction]) * 1000
            
            # Fast reversal - block immediately
            if time_since_opposite is not None and time_since_opposite < FAST_THRESHOLD_MS:
                blocked_count += 1
                dir_str = "UP" if direction > 0 else "DOWN"
                print(f"[{event_num:4d}] ✗ BLOCK {dir_str} [FAST] | {time_since_opposite:.1f}ms since opposite | total: {blocked_count}", file=sys.stderr)
                continue
            
            # Cancel any pending scroll in the opposite direction
            with pending_lock:
                if pending_scroll is not None:
                    pending_time, pending_dir, timer = pending_scroll
                    if pending_dir == opposite_direction:
                        # Cancel the pending opposite scroll - this confirms current direction
                        timer.cancel()
                        pending_scroll = None
            
            # Medium-speed reversal - needs confirmation
            if time_since_opposite is not None and FAST_THRESHOLD_MS <= time_since_opposite <= MAX_DELAY_MS:
                # Queue this scroll with a confirmation timer
                timer = threading.Timer(CONFIRMATION_WINDOW_MS / 1000, emit_pending_scroll)
                
                with pending_lock:
                    pending_scroll = (current_time, direction, timer)
                
                timer.start()
                dir_str = "UP" if direction > 0 else "DOWN"
                print(f"[{event_num:4d}] ⏳ QUEUE {dir_str} [CONFIRM] | {time_since_opposite:.1f}ms since opposite | waiting {CONFIRMATION_WINDOW_MS}ms...", file=sys.stderr)
                continue
            
            # Fast scroll in same direction OR very slow reversal (>800ms) - emit immediately
            emit_scroll(direction, f"[IMMEDIATE]")
            last_scroll_time[direction] = current_time
            last_any_scroll_time = current_time
            
        elif event.type == e.EV_REL and event.code == e.REL_WHEEL_HI_RES:
            pass
        else:
            uinput.write_event(event)
            if event.type == e.EV_SYN:
                uinput.syn()

except KeyboardInterrupt:
    print(f"\n{'='*60}", file=sys.stderr)
    print(f"Blocked: {blocked_count} | Emitted: {emitted_count}", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)

finally:
    try:
        primary.ungrab()
    except:
        pass
    uinput.close()
