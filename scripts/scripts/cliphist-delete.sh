#!/usr/bin/env bash
cliphist list | fzf --multi --prompt="Delete> " --header="Tab to mark, Enter to delete" | cliphist delete
