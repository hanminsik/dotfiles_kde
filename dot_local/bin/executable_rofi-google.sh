#!/usr/bin/env bash
# ~/.local/bin/rofi-google

# 이미 떠 있는 구글 검색창이 있으면 끄고 종료 (토글)
pkill -x rofi && exit 0

query=$(rofi -dmenu -p "Google" -theme-str 'listview { enabled: false; }' < /dev/null)
[ -z "$query" ] && exit 0

encoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$query")

firefox-developer-edition --new-tab "https://www.google.com/search?q=${encoded}" &

for _ in $(seq 1 50); do
    win=$(kdotool search --class firefoxdeveloperedition | head -n1)
    if [ -n "$win" ]; then
        kdotool windowactivate "$win"
        break
    fi
    sleep 0.1
done
