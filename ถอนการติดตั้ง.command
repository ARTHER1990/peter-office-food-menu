#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

./uninstall.sh

osascript -e 'display dialog "🛑 ถอนการติดตั้งระบบแจ้งเตือนเมนูอาหารเรียบร้อยแล้ว!" buttons {"ตกลง"} default button "ตกลง" with title "Peter Food Menu Alert" with icon note'

osascript -e 'tell application "Terminal" to close (every window whose name contains "ถอนการติดตั้ง")' &
exit 0
