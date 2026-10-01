#!/bin/bash
# ---------------------------------------------------------
# 🍱 1-CLICK AUTO-INSTALLER: PETER FOOD MENU ALERT
# ติดตั้งเมนูอาหารออฟฟิศลงในเครื่องอัตโนมัติ 100%
# ---------------------------------------------------------

echo "=========================================="
echo "   🍱 กำลังติดตั้ง Peter Food Menu Alert ลงในเครื่อง..."
echo "=========================================="

INSTALL_DIR="$HOME/.peter_food_menu"
APP_DIR="$HOME/Applications"
PLIST_NAME="com.peter.foodmenu.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

mkdir -p "$INSTALL_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$LAUNCH_AGENTS_DIR"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_ZIP="$SCRIPT_DIR/PeterFoodMenu_Installer.zip"

if [ ! -f "$APP_ZIP" ]; then
    APP_ZIP="PeterFoodMenu_Installer.zip"
fi

if [ -f "$APP_ZIP" ]; then
    # 1. ปิดตัวเก่า
    killall PeterFoodMenu 2>/dev/null || true
    sleep 0.3

    # 2. คลายไฟล์ลง /tmp
    TEMP_DIR="/tmp/PeterFoodMenu_Install_$(date +%s)"
    mkdir -p "$TEMP_DIR"
    unzip -q -o "$APP_ZIP" -d "$TEMP_DIR"

    cp "$TEMP_DIR/PeterFoodMenu" "$INSTALL_DIR/"
    cp "$TEMP_DIR/menu_schedule.json" "$INSTALL_DIR/" 2>/dev/null || true
    cp "$TEMP_DIR/company_logo.png" "$INSTALL_DIR/" 2>/dev/null || true
    rm -rf "$TEMP_DIR"

    chmod +x "$INSTALL_DIR/PeterFoodMenu"
    xattr -cr "$INSTALL_DIR" 2>/dev/null || true

    # 3. สร้างชอร์ตคัทใน ~/Applications เพื่อค้นหาใน Spotlight ได้
    APP_BUNDLE="$APP_DIR/เมนูอาหาร.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    cat << 'APP_EOF' > "$APP_BUNDLE/Contents/MacOS/เมนูอาหาร"
#!/bin/bash
killall PeterFoodMenu 2>/dev/null
"$HOME/.peter_food_menu/PeterFoodMenu" &
APP_EOF
    chmod +x "$APP_BUNDLE/Contents/MacOS/เมนูอาหาร"
    xattr -cr "$APP_BUNDLE" 2>/dev/null || true

    # 4. ติดตั้ง LaunchAgent ให้เปิดอัตโนมัติเมื่อเปิดเครื่อง
    cat << PLIST_EOF > "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.peter.foodmenu</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/PeterFoodMenu</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/peter_food_menu.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/peter_food_menu_err.log</string>
</dict>
</plist>
PLIST_EOF

    launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
    killall PeterFoodMenu 2>/dev/null || true
    launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true

    # 5. เปิดโปรแกรมทันที
    "$INSTALL_DIR/PeterFoodMenu" &

    echo ""
    echo "✅ [สำเร็จ 100%] ติดตั้ง Peter Food Menu เข้าเครื่องเรียบร้อยแล้ว!"
    echo "👉 ไอคอนช้อนส้อม 🍱 ปรากฏบนแถบนาฬิกาบนขวา และจะแจ้งเตือนอัตโนมัติเวลา 10:50 น."
    echo "=========================================="
else
    echo "❌ ไม่พบไฟล์ PeterFoodMenu_Installer.zip"
fi
