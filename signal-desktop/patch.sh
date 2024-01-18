#!/bin/bash

inform 'Replacing icons'

for PX in 16 32 256; do
  cp icons/signal-tray.png "$PKGSRC_DIR"/images/icon_$PX.png

  for I in {1..10}; do
    cp icons/signal-tray-unread.png "$PKGSRC_DIR"/images/alert/$PX/$I.png
  done
done
