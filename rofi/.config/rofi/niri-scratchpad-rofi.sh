#!/usr/bin/env bash
NIRI_WORKSPACE_ID=8

niri msg --json windows | jq -r --arg scratch "$NIRI_WORKSPACE_ID" '
  .[] | 
  select(
    (.workspace_id | tostring) == $scratch
  ) | 
  "\(.id): \(.title) — \(.app_id)"
'
