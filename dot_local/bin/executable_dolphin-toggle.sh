#!/usr/bin/env bash

# 현재 떠 있는 konsole 창 목록
mapfile -t WINS < <(kdotool search --class dolphin)

# 1) konsole이 없으면 실행
if [ "${#WINS[@]}" -eq 0 ]; then
    setsid -f dolphin >/dev/null 2>&1
    exit 0
fi

# 2) 현재 활성 창이 konsole인지 확인
ACTIVE=$(kdotool getactivewindow 2>/dev/null)

for w in "${WINS[@]}"; do
    if [ "$w" = "$ACTIVE" ]; then
        # 이미 포커스된 상태 -> 최소화
        kdotool windowminimize "$w"
        exit 0
    fi
done

# 3) konsole은 있지만 포커스가 없음
#    -> 현재 데스크톱으로 가져온 뒤 복원 + 활성화
TARGET="${WINS[0]}"
CUR_DESKTOP=$(kdotool get_desktop)

kdotool set_desktop_for_window "$TARGET" "$CUR_DESKTOP"
kdotool windowstate --remove MINIMIZED "$TARGET"
kdotool windowactivate "$TARGET"
