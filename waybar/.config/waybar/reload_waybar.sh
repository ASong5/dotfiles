#!/bin/sh
killall waybar
killall rofi

waybar -c ~/.config/waybar/config.jsonc & -s
rofi -show combi -monitor DP-1 &

