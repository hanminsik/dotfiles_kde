#!/usr/bin/env bash
# ~/.local/bin/rofi-google

# 이미 떠 있는 검색창이 있으면 끄고 종료 (토글)
pkill -x rofi && exit 0

query=$(rofi -dmenu -p "Google Private" -theme-str 'listview { enabled: false; }' < /dev/null)
[ -z "$query" ] && exit 0

encoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))' "$query")

# 실행 전에 이미 있던 Firefox 창 목록 저장
before=$(kdotool search --class firefox-developer-edition)

firefox-developer-edition --private-window "https://www.google.com/search?q=${encoded}" &

# 새로 생긴 창(= 방금 연 프라이빗 창)을 찾아서 활성화
for _ in $(seq 1 50); do
    for win in $(kdotool search --class firefox-developer-edition); do
        if ! grep -qx "$win" <<< "$before"; then
            kdotool windowactivate "$win"
            break 2
        fi
    done
    sleep 0.1
done
