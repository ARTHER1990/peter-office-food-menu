#!/bin/bash
PLIST_NAME="com.peter.foodmenu.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
INSTALL_DIR="$HOME/.peter_food_menu"

launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
killall PeterFoodMenu 2>/dev/null
rm -rf "$INSTALL_DIR"

echo "🛑 ถอนการติดตั้ง Peter Food Menu Alert เรียบร้อยแล้ว!"
