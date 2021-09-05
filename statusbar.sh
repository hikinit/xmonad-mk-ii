#!/bin/sh

now_playing() {
    local status=$(playerctl status)
    local title=$(playerctl metadata title  2>&1)
    local icon="\ue05c"
    local iconPause="\ue059"

    if [ "$status" == "Stopped" ];
    then
        title=$status
    fi

    if [ "$status" == "Paused" ]; then
        icon=$iconPause
    fi

    _click_wrapper "playerctl play-pause" $icon $title
}

_click_wrapper() {
    echo -e "%{A:$1:}" "${@:2}" "${A}"
}

$1