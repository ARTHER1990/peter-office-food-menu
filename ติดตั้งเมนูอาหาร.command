#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Run install script
./install.sh

# Show native macOS notification dialog
osascript -e 'display dialog "🍱 ติดตั้งระบบแจ้งเตือนเมนูอาหาร (Crazy Factory) สำเร็จเรียบร้อยแล้ว!\n\n• ไอคอนช้อนส้อมปรากฏบนแถบข้างนาฬิกาแล้ว\n• ระบบจะแจ้งเตือนอัตโนมัติทุกวันเวลา 10:50 น." buttons {"ตกลง"} default button "ตกลง" with title "Peter Food Menu Alert" with icon note'

# Auto close terminal window
osascript -e 'tell application "Terminal" to close (every window whose name contains "ติดตั้งเมนูอาหาร")' &
exit 0
