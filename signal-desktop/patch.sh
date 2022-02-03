#!/bin/bash

inform 'Replacing icons'
cp icons/signal-tray.png "$PKGSRC_DIR"/images/icon_256.png

for I in {1..10}; do
  cp icons/signal-tray-unread.png "$PKGSRC_DIR"/images/alert/256/$I.png
done
