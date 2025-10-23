#!/bin/bash

items="\uf023  Lock\n\uf08b  Logout\n\uf186  Suspend\n\uf2f1  Reboot\n\uf011  Shutdown"
output=$(echo -e "$items" | walker --dmenu -H)

case "$output" in
    *Lock)
        hyprlock
        ;;
    *Logout)
        uwsm stop
        ;;
    *Suspend)
        systemctl suspend
        ;;
    *Reboot)
        systemctl reboot
        ;;
    *Shutdown)
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
