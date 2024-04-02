#!/usr/bin/env bash

set -o nounset
set -o errexit

# Get current input
current=$(ddcutil -d 2 getvcp 60 | sed -n "s/.*(sl=\(.*\))/\1/p")

# Get the other input
case $current in

    0x11)
        output=0x0f
        ;;

    0x0f)
        output=0x11
        ;;

    *)
        echo "Unknown input"
        exit 1
        ;;
esac

# Set new input
ddcutil -d 2 setvcp 60 $output
