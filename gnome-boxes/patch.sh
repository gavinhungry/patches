#!/bin/bash

inform 'Updating logo'
convert \
  -background none "$PKGSRC_DIR"/help/C/figures/boxes_icon.svg \
  -resize 256x256 "$PKGSRC_DIR"/data/icons/empty-boxes.png
