#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "☁️ กำลังส่งข้อมูลเมนูขึ้น GitHub Cloud..."
git add menu_schedule.json
git commit -m "Update monthly food menu $(date +'%Y-%m-%d %H:%M')"
git push origin main
echo "✅ อัปเดตข้อมูลขึ้น Cloud เรียบร้อยแล้ว! เครื่องเพื่อนๆ จะได้รับข้อมูลทันที"
