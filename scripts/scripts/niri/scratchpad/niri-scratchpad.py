#!/usr/bin/env python3
# Adapted from the many ideas shared at: https://github.com/YaLTeR/niri/discussions/329
import argparse
import json
import os
import subprocess
import sys
import time

# output sizes for centering
OUTPUT_SIZES = {"DP-1": (2560, 1440), "DP-2": (1080, 1920), "HDMI-A-1": (1920, 1080)}

# bar height subtracted from output height for working area centering
BAR_HEIGHT = 30

# state file for tracking scratchpad window IDs per app
STATE_FILE = os.path.expanduser("~/.cache/niri-scratchpad-state.json")

# config file for per-output scratchpad dimensions
CONFIG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config.json")

# the found scratchpad window (id, workspace_id, is_focused, is_floating)
scratch_window = {}
# the focused workspace data
focused_workspace = {}
# the scratchpad workspace name
scratch_workspace = os.getenv("NS_WORKSPACE", "scratch")

def niri_cmd(cmd_args):
    subprocess.run(["niri", "msg", "action"] + cmd_args)

def set_window_size(width=None, height=None, window_id=None):
    """Set the size of a window by ID or the currently focused window"""
    if width is not None:
        if window_id is not None:
            niri_cmd(["set-window-width", "--id", str(window_id), str(width)])
        else:
            niri_cmd(["set-window-width", str(width)])
    if height is not None:
        if window_id is not None:
            niri_cmd(["set-window-height", "--id", str(window_id), str(height)])
        else:
            niri_cmd(["set-window-height", str(height)])

def move_window_to_scratchpad(window_id, animations):
    niri_cmd(["move-window-to-workspace", "--window-id", str(window_id), scratch_workspace, "--focus=false"])
    if animations:
        niri_cmd(["move-window-to-tiling", "--id", str(window_id)])

def bring_scratchpad_window_to_focus(window_id, args):
    # Move to target workspace/monitor first (window may be tiled)
    niri_cmd(["move-window-to-workspace", "--window-id", str(window_id), str(focused_workspace["idx"])])
    if args.multi_monitor:
        niri_cmd(["move-window-to-monitor", "--id", str(window_id), focused_workspace["output"]])

    # Animate floating transition visible on current workspace
    if args.animations and not scratch_window["is_floating"]:
        niri_cmd(["move-window-to-floating", "--id", str(window_id)])
    niri_cmd(["move-window-to-floating", "--id", str(window_id)])

    # Set custom size on the now-floating window (size will stick)
    w, h = desired_size(focused_workspace["output"], args.app_id, args)
    if w or h:
        set_window_size(w, h, window_id)
        # Update the stored size for accurate centering
        if w:
            scratch_window["size"][0] = w
        if h:
            scratch_window["size"][1] = h
    
    niri_cmd(["focus-window", "--id", str(window_id)])
    
    # Re-query actual window size after all layout operations
    time.sleep(0.05)
    props = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        capture_output=True, text=True,
    )
    try:
        windows = json.loads(props.stdout)
        for w in windows:
            if w["id"] == window_id:
                scratch_window["size"] = list(w["layout"]["window_size"])
                break
    except json.JSONDecodeError:
        pass
    
    center_floating_window()

def center_floating_window():
    output = focused_workspace["output"]

    if output not in OUTPUT_SIZES:
        return

    output_w, output_h = OUTPUT_SIZES[output]

    win_w = int(scratch_window["size"][0])
    win_h = int(scratch_window["size"][1])

    x = (output_w // 2) - (win_w // 2)
    y = ((output_h - BAR_HEIGHT) // 2) - (win_h // 2)

    subprocess.run([
        "niri", "msg", "action", "move-floating-window",
        "-x", str(x),
        "-y", str(y),
    ])

def center_floating_window_with_size(output, window_size):
    """Center a floating window on the given output with explicit size"""
    if output not in OUTPUT_SIZES:
        return

    output_w, output_h = OUTPUT_SIZES[output]
    win_w = int(window_size[0])
    win_h = int(window_size[1])

    x = (output_w // 2) - (win_w // 2)
    y = ((output_h - BAR_HEIGHT) // 2) - (win_h // 2)

    subprocess.run([
        "niri", "msg", "action", "move-floating-window",
        "-x", str(x),
        "-y", str(y),
    ])

def load_scratchpad_state():
    """Load the scratchpad state dict from cache file"""
    try:
        with open(STATE_FILE, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def save_scratchpad_state(state):
    """Save the scratchpad state dict to cache file"""
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f)


def load_scratchpad_config():
    """Load per-output scratchpad dimensions from config file"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def desired_size(output, app_id, args):
    """Resolve desired (width, height) from config file, CLI args override.
    
    Config format: {"output": {"app_id": {"width": N, "height": N}}}
    Falls back to args.width/args.height if config has no matching entry.
    """
    if not app_id:
        return (args.width, args.height)
    config = load_scratchpad_config()
    if not isinstance(config, dict):
        return (args.width, args.height)
    section = config.get(output)
    if not isinstance(section, dict):
        return (args.width, args.height)
    entry = section.get(app_id)
    if not isinstance(entry, dict):
        return (args.width, args.height)
    return (
        args.width if args.width is not None else entry.get("width"),
        args.height if args.height is not None else entry.get("height"),
    )


def window_matches(window, args):
    """Check if a window matches the given args criteria"""
    if args.window_id and window["id"] == args.window_id:
        return True
    if args.app_id and window["app_id"] == args.app_id:
        return True
    if args.title and window["title"] == args.title:
        return True
    return False


def fetch_focused_workspace():
    props = subprocess.run(
        ["niri", "msg", "--json", "workspaces"],
        capture_output=True,
        text=True,
    )
    workspaces = json.loads(props.stdout)
    
    # get the focused workspace
    for workspace in workspaces:
        if workspace["is_focused"]:
            focused_workspace["idx"] = workspace["idx"]
            focused_workspace["output"] = workspace["output"]
            return workspace["id"]

def get_scratch_workspace_id():
    """Get the workspace_id for the scratch workspace"""
    props = subprocess.run(
        ["niri", "msg", "--json", "workspaces"],
        capture_output=True,
        text=True,
    )
    workspaces = json.loads(props.stdout)
    
    for workspace in workspaces:
        if workspace["name"] == scratch_workspace:
            return workspace["id"]
    
    return None

def get_focused_window_id():
    """Get the currently focused window ID"""
    props = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        capture_output=True,
        text=True,
    )
    windows = json.loads(props.stdout)
    
    for window in windows:
        if window["is_focused"]:
            return window["id"]
    
    return None

def get_scratchpad_windows_sorted(scratch_workspace_id):
    """Get all windows in scratchpad workspace, sorted by focus_timestamp (most recent first)"""
    props = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        capture_output=True,
        text=True,
    )
    windows = json.loads(props.stdout)
    
    # Filter windows in scratch workspace
    scratch_windows = [w for w in windows if w["workspace_id"] == scratch_workspace_id]
    
    # Sort by focus_timestamp (most recent first)
    # Handle None timestamps by treating them as oldest
    def get_timestamp(window):
        ts = window.get("focus_timestamp")
        if ts is None:
            return (0, 0)
        return (ts["secs"], ts["nanos"])
    
    scratch_windows.sort(key=get_timestamp, reverse=True)
    
    return scratch_windows

def bring_recent_scratchpad_window(args):
    """Bring back the most recent scratchpad window, or toggle off focused tracked window"""
    focused_id = get_focused_window_id()
    state = load_scratchpad_state()

    # If focused on a tracked visible window, toggle it off instead
    if focused_id is not None:
        scratch_workspace_id = get_scratch_workspace_id()
        if scratch_workspace_id is None:
            print(f"Error: Scratch workspace '{scratch_workspace}' not found", file=sys.stderr)
            sys.exit(1)
        for app_id, entry in state.items():
            wid = entry.get("id") if isinstance(entry, dict) else entry
            if wid == focused_id:
                props = subprocess.run(
                    ["niri", "msg", "--json", "windows"],
                    capture_output=True, text=True,
                )
                try:
                    windows = json.loads(props.stdout)
                    windows_by_id = {w["id"]: w for w in windows}
                except json.JSONDecodeError:
                    windows_by_id = {}
                if focused_id in windows_by_id and windows_by_id[focused_id]["workspace_id"] != scratch_workspace_id:
                    move_window_to_scratchpad(focused_id, args.animations)
                    state[app_id] = {"id": focused_id, "hidden": True}
                    save_scratchpad_state(state)
                    sys.exit(0)
                break

    # Not focused on a tracked visible window → bring back most recent from scratch
    scratch_workspace_id = get_scratch_workspace_id()
    if scratch_workspace_id is None:
        print(f"Error: Scratch workspace '{scratch_workspace}' not found", file=sys.stderr)
        sys.exit(1)

    # Prefer state-tracked windows over any random scratchpad window
    tracked_ids = set()
    for val in state.values():
        if isinstance(val, dict):
            wid = val.get("id")
        else:
            wid = val
        if wid is not None:
            tracked_ids.add(wid)

    # Get sorted scratchpad windows
    scratch_windows = get_scratchpad_windows_sorted(scratch_workspace_id)

    # Filter to only tracked windows if any tracked IDs exist
    if tracked_ids:
        tracked_scratch = [w for w in scratch_windows if w["id"] in tracked_ids]
        if not tracked_scratch:
            # No tracked windows in scratch — nothing to bring back
            print("No tracked windows in scratchpad", file=sys.stderr)
            sys.exit(1)
        scratch_windows = tracked_scratch

    if not scratch_windows:
        print("No windows in scratchpad", file=sys.stderr)
        sys.exit(1)

    # Get focused workspace and window
    fetch_focused_workspace()
    focused_window_id = get_focused_window_id()

    # Find the first non-focused scratchpad window
    window_to_bring = None
    for window in scratch_windows:
        if window["id"] != focused_window_id:
            window_to_bring = window
            break

    if window_to_bring is None:
        window_to_bring = scratch_windows[0]

    # Bring the window to focus
    window_id = window_to_bring["id"]
    window_size = list(window_to_bring["layout"]["window_size"])

    niri_cmd(["move-window-to-workspace", "--window-id", str(window_id), str(focused_workspace["idx"])])

    if args.multi_monitor:
        niri_cmd(["move-window-to-monitor", "--id", str(window_id), focused_workspace["output"]])

    if args.animations and not window_to_bring["is_floating"]:
        niri_cmd(["move-window-to-floating", "--id", str(window_id)])
    niri_cmd(["move-window-to-floating", "--id", str(window_id)])

    w, h = desired_size(focused_workspace["output"], window_to_bring.get("app_id"), args)
    if w or h:
        set_window_size(w, h, window_id)
        if w:
            window_size[0] = w
        if h:
            window_size[1] = h

    niri_cmd(["focus-window", "--id", str(window_id)])

    time.sleep(0.05)
    props = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        capture_output=True, text=True,
    )
    try:
        windows = json.loads(props.stdout)
        for w in windows:
            if w["id"] == window_id:
                window_size = list(w["layout"]["window_size"])
                break
    except json.JSONDecodeError:
        pass

    center_floating_window_with_size(focused_workspace["output"], window_size)

    app_id = window_to_bring.get("app_id")
    if app_id:
        entry = state.get(app_id)
        if isinstance(entry, dict) and entry.get("id") == window_id:
            entry["hidden"] = False
            save_scratchpad_state(state)
        elif not isinstance(entry, dict) and entry == window_id:
            state[app_id] = {"id": window_id, "hidden": False}
            save_scratchpad_state(state)

def ns(parser):
    args = parser.parse_args()

    if args.recent:
        bring_recent_scratchpad_window(args)
        return
    
    props = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        capture_output=True,
        text=True,
    )
    windows = json.loads(props.stdout)
    
    scratch_workspace_id = get_scratch_workspace_id()
    state = load_scratchpad_state()
    windows_by_id = {w["id"]: w for w in windows}
    
    # Determine key for state lookup
    state_key = None
    if args.app_id:
        state_key = args.app_id
    elif args.window_id is not None:
        state_key = f"id:{args.window_id}"
    elif args.title is not None:
        state_key = f"title:{args.title}"
    
    stored_window_id = None
    stored_hidden = True
    if state_key:
        val = state.get(state_key)
        if isinstance(val, dict):
            stored_window_id = val.get("id")
            stored_hidden = val.get("hidden", True)
        elif val is not None:
            stored_window_id = val
            stored_hidden = True
    
    # --- Case 1: stored scratchpad window exists and is still alive ---
    if stored_window_id is not None and stored_window_id in windows_by_id:
        window = windows_by_id[stored_window_id]
        
        scratch_window["id"] = window["id"]
        scratch_window["workspace_id"] = window["workspace_id"]
        scratch_window["is_focused"] = window["is_focused"]
        scratch_window["is_floating"] = window["is_floating"]
        scratch_window["size"] = list(window["layout"]["window_size"])
        
        in_scratch = window["workspace_id"] == scratch_workspace_id
        
        if in_scratch and stored_hidden:
            # Toggle ON: scratchpad is in scratch → bring to current workspace
            fetch_focused_workspace()
            bring_scratchpad_window_to_focus(window["id"], args)
            if state_key:
                state[state_key] = {"id": stored_window_id, "hidden": False}
                save_scratchpad_state(state)
        elif not in_scratch and not stored_hidden:
            # Toggle OFF: scratchpad is visible → send to scratch
            move_window_to_scratchpad(window["id"], args.animations)
            if state_key:
                state[state_key] = {"id": stored_window_id, "hidden": True}
                save_scratchpad_state(state)
        elif in_scratch and not stored_hidden:
            # Inconsistent state: in scratch but marked visible (e.g., via Grave)
            # User clearly wants to bring it back — toggle on
            fetch_focused_workspace()
            bring_scratchpad_window_to_focus(window["id"], args)
            if state_key:
                state[state_key] = {"id": stored_window_id, "hidden": False}
                save_scratchpad_state(state)
        else:
            # Not in scratch but marked hidden → stale, clean state
            if state_key:
                state.pop(state_key, None)
                save_scratchpad_state(state)
                stored_window_id = None
                stored_hidden = True
        
        if stored_window_id is not None:
            return
    
    # --- Case 2: stored scratchpad window was closed → clean state ---
    if stored_window_id is not None and stored_window_id not in windows_by_id:
        if state_key:
            state.pop(state_key, None)
            save_scratchpad_state(state)
    
    # --- Case 3: find a matching window in scratch (untracked) ---
    for window in windows:
        if window_matches(window, args) and window["workspace_id"] == scratch_workspace_id:
            scratch_window["id"] = window["id"]
            scratch_window["workspace_id"] = window["workspace_id"]
            scratch_window["is_focused"] = window["is_focused"]
            scratch_window["is_floating"] = window["is_floating"]
            scratch_window["size"] = window["layout"]["window_size"]
            
            fetch_focused_workspace()
            bring_scratchpad_window_to_focus(window["id"], args)
            
            # Track by app_id when available (survives restarts), else fall back to state_key
            save_key = window.get("app_id") or state_key
            if save_key and (save_key == state_key or not state.get(save_key)):
                state[save_key] = {"id": window["id"], "hidden": False}
                save_scratchpad_state(state)
            # Also clean up stale id: state_key if tracking under app_id now
            if save_key != state_key and state_key and state_key in state:
                del state[state_key]
                save_scratchpad_state(state)
            return
    
    # --- Case 4: no matching window at all → spawn ---
    if args.spawn:
        # Record existing window IDs to detect the spawned window
        existing_ids = {w["id"] for w in windows}
        
        niri_cmd(["spawn", "--"] + args.spawn.split(' '))
        
        # Wait for the spawned window to appear
        deadline = time.time() + 2.0
        spawned_window = None
        while time.time() < deadline:
            time.sleep(0.15)
            props = subprocess.run(
                ["niri", "msg", "--json", "windows"],
                capture_output=True, text=True,
            )
            new_windows = json.loads(props.stdout)
            for w in new_windows:
                if w["id"] not in existing_ids and window_matches(w, args):
                    spawned_window = w
                    break
            if spawned_window is not None:
                break
        
        if spawned_window is not None:
            window_id = spawned_window["id"]

            # Determine target output before sizing (config is per-output)
            fetch_focused_workspace()
            output = focused_workspace["output"]

            # Make floating
            niri_cmd(["move-window-to-floating", "--id", str(window_id)])

            # Move to correct monitor if multi-monitor
            if args.multi_monitor:
                niri_cmd(["move-window-to-monitor", "--id", str(window_id), output])

            # Set custom size from config or CLI
            w, h = desired_size(output, args.app_id, args)
            if w or h:
                set_window_size(w, h, window_id)

            # Focus
            niri_cmd(["focus-window", "--id", str(window_id)])
            niri_cmd(["move-window-to-floating"])

            # Center - re-query actual size after layout operations
            time.sleep(0.05)
            props = subprocess.run(
                ["niri", "msg", "--json", "windows"],
                capture_output=True, text=True,
            )
            try:
                cur_windows = json.loads(props.stdout)
                for cw in cur_windows:
                    if cw["id"] == window_id:
                        window_size = cw["layout"]["window_size"]
                        win_w, win_h = window_size
                        break
            except json.JSONDecodeError:
                win_w = w or spawned_window["layout"]["window_size"][0]
                win_h = h or spawned_window["layout"]["window_size"][1]
            else:
                win_w = w or win_w
                win_h = h or win_h
            center_floating_window_with_size(output, (win_w, win_h))
            
            # Save to state for future tracking
            if state_key:
                state[state_key] = {"id": window_id, "hidden": False}
                save_scratchpad_state(state)
        
        sys.exit(0)
    else:
        parser.print_help()
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(prog='nscratch', description='Niri Scratchpad support')
    group = parser.add_mutually_exclusive_group(required=False)
    group.add_argument('-w', '--window-id', type=int, help='The window identifier (unique)')
    group.add_argument('-id', '--app-id', help='The application identifier')
    group.add_argument('-t', '--title', help='The application title')
    group.add_argument('-r', '--recent', action='store_true', help='Bring back most recent scratchpad window')
    parser.add_argument('-s', '--spawn', help='The process name to spawn when non-existing')
    parser.add_argument('-a', '--animations', action='store_true', help='Enable animations')
    parser.add_argument('-m', '--multi-monitor', action='store_true', help='Multi-monitor support')
    parser.add_argument('--width', type=int, help='Set window width when bringing back from scratchpad')
    parser.add_argument('--height', type=int, help='Set window height when bringing back from scratchpad')

    # Make the group required only if --recent is not specified
    args = parser.parse_args()
    if not args.recent and not any([args.window_id, args.app_id, args.title]):
        parser.error('one of the arguments -w/--window-id -id/--app-id -t/--title -r/--recent is required')
    
    ns(parser)

if __name__ == "__main__":
    main()
