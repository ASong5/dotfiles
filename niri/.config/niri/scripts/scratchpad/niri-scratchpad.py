#!/usr/bin/env python3
# Adapted from the many ideas shared at: https://github.com/YaLTeR/niri/discussions/329
import argparse
import json
import os
import subprocess
import sys

# output sizes for centering
OUTPUT_SIZES = {"DP-1": (2560, 1440), "DP-2": (1920, 1080), "HDMI-A-1": (1920, 1080)}

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
    # Set custom size if specified (before moving, so it's not visible yet)
    if args.width or args.height:
        set_window_size(args.width, args.height, window_id)
        # Update the stored size for accurate centering
        if args.width:
            scratch_window["size"][0] = args.width
        if args.height:
            scratch_window["size"][1] = args.height
    
    niri_cmd(["move-window-to-workspace", "--window-id", str(window_id), str(focused_workspace["idx"])])
    if args.multi_monitor:
        niri_cmd(["move-window-to-monitor", "--id", str(window_id), focused_workspace["output"]])
    if args.animations and not scratch_window["is_floating"]:
        niri_cmd(["move-window-to-floating", "--id", str(window_id)])
    niri_cmd(["focus-window", "--id", str(window_id)])
    niri_cmd(["move-window-to-floating"])
    
    center_floating_window()

def center_floating_window():
    output = focused_workspace["output"]

    if output not in OUTPUT_SIZES:
        return

    output_w, output_h = OUTPUT_SIZES[output]

    win_w = int(scratch_window["size"][0])
    win_h = int(scratch_window["size"][1])

    x = (output_w // 2) - (win_w // 2)
    y = (output_h // 2) - (win_h // 2)

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
    y = (output_h // 2) - (win_h // 2)

    subprocess.run([
        "niri", "msg", "action", "move-floating-window",
        "-x", str(x),
        "-y", str(y),
    ])

def find_scratch_window(args, windows):
    for window in windows:
        if (args.window_id and window["id"] == args.window_id) or \
           (args.app_id and window["app_id"] == args.app_id) or \
           (args.title and window["title"] == args.title):
            scratch_window["id"] = window["id"]
            scratch_window["workspace_id"] = window["workspace_id"]
            scratch_window["is_focused"] = window["is_focused"]
            scratch_window["is_floating"] = window["is_floating"]
            scratch_window["size"] = window["layout"]["window_size"]
            break

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
    """Bring back the most recent scratchpad window"""
    # Get scratch workspace ID
    scratch_workspace_id = get_scratch_workspace_id()
    if scratch_workspace_id is None:
        print(f"Error: Scratch workspace '{scratch_workspace}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Get sorted scratchpad windows
    scratch_windows = get_scratchpad_windows_sorted(scratch_workspace_id)
    
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
        # All scratchpad windows are already focused (unlikely with only 1 window)
        # Just bring back the most recent one anyway
        window_to_bring = scratch_windows[0]
    
    # Bring the window to focus
    window_id = window_to_bring["id"]
    
    # Get the window size for centering (will be updated if we resize)
    window_size = list(window_to_bring["layout"]["window_size"])
    
    # Set custom size if specified (before moving, so it's not visible yet)
    if args.width or args.height:
        set_window_size(args.width, args.height, window_id)
        # Update the size for accurate centering
        if args.width:
            window_size[0] = args.width
        if args.height:
            window_size[1] = args.height
    
    niri_cmd(["move-window-to-workspace", "--window-id", str(window_id), str(focused_workspace["idx"])])
    
    if args.multi_monitor:
        niri_cmd(["move-window-to-monitor", "--id", str(window_id), focused_workspace["output"]])
    
    if args.animations and not window_to_bring["is_floating"]:
        niri_cmd(["move-window-to-floating", "--id", str(window_id)])
    
    niri_cmd(["focus-window", "--id", str(window_id)])
    niri_cmd(["move-window-to-floating"])
    
    center_floating_window_with_size(focused_workspace["output"], window_size)

def ns(parser):
    args = parser.parse_args()
    
    # Handle --recent mode
    if args.recent:
        bring_recent_scratchpad_window(args)
        return
    
    props = subprocess.run(
        ["niri", "msg", "--json", "windows"],
        capture_output=True,
        text=True,
    )
    windows = json.loads(props.stdout)
    
    find_scratch_window(args, windows)
    
    # scratchpad does not yet exist, spawn?
    if not scratch_window:
        if args.spawn:
            niri_cmd(["spawn", "--"] + args.spawn.split(' '))
            sys.exit(0)
        else:
            parser.print_help()
            sys.exit(1)
    
    window_id = scratch_window["id"]
    
    # the scratchpad window exists and it's focused
    if not scratch_window["is_focused"]:
        workspace_id = fetch_focused_workspace()
        # the window is not in the focused workspace
        if scratch_window["workspace_id"] != workspace_id:
            bring_scratchpad_window_to_focus(window_id, args)
            return
    
    move_window_to_scratchpad(window_id, args.animations)

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
