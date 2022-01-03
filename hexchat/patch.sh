#!/bin/bash

ICONS_DIR="$PKGBUILD_DIR"/src/hexchat/data/icons

inform 'Updating icons'
cp hexchat-indicator.png "$ICONS_DIR"/hexchat.png
cp empty.png "$ICONS_DIR"/tray_fileoffer.png
cp empty.png "$ICONS_DIR"/tray_highlight.png
cp empty.png "$ICONS_DIR"/tray_message.png
