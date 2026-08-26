#!/bin/bash
INSTALL_DIR="$HOME/.peter_food_menu"
APP_DIR="$HOME/Applications"
PLIST_NAME="com.peter.foodmenu.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo "🍱 กำลังติดตั้ง Peter Food Menu Alert (เวอร์ชันแจ้งเตือนมุมบนขวา)..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$LAUNCH_AGENTS_DIR"

if [ -f "./PeterFoodMenu" ]; then
    cp ./PeterFoodMenu "$INSTALL_DIR/"
    cp ./menu_schedule.json "$INSTALL_DIR/" 2>/dev/null
    cp ./company_logo.png "$INSTALL_DIR/" 2>/dev/null
else
    echo "⬇️ กำลังดาวน์โหลดตัวโปรแกรมและข้อมูลล่าสุด..."
    curl -sL "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/PeterFoodMenu" -o "$INSTALL_DIR/PeterFoodMenu"
    curl -sL "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/menu_schedule.json" -o "$INSTALL_DIR/menu_schedule.json"
    curl -sL "https://raw.githubusercontent.com/ARTHER1990/peter-office-food-menu/main/company_logo.png" -o "$INSTALL_DIR/company_logo.png"
fi

chmod +x "$INSTALL_DIR/PeterFoodMenu"
xattr -cr "$INSTALL_DIR" 2>/dev/null

# สร้างแอปใน ~/Applications เพื่อให้ค้นหาใน Spotlight Search (Command + Space) ได้ง่ายๆ
APP_BUNDLE="$APP_DIR/เมนูอาหาร.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cat << APP_EOF > "$APP_BUNDLE/Contents/MacOS/เมนูอาหาร"
#!/bin/bash
killall PeterFoodMenu 2>/dev/null
"$HOME/.peter_food_menu/PeterFoodMenu" &
APP_EOF
chmod +x "$APP_BUNDLE/Contents/MacOS/เมนูอาหาร"

# ติดตั้ง LaunchAgent ให้เปิดอัตโนมัติเมื่อเปิดเครื่อง
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

launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null
killall PeterFoodMenu 2>/dev/null
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "✅ ติดตั้งสำเร็จเรียบร้อย! ไอคอนช้อนส้อมจะปรากฏบน Menu Bar ด้านบนข้างนาฬิกา และแจ้งเตือนมุมบนขวาเวลา 10:50 น."

