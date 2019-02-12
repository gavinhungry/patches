#!/bin/bash

inform 'Replacing icons'
for OSIMG in "$PKGSRC_DIR"/src/VBox/Frontends/VirtualBox/images/{x2,x3,x4,}/os_*; do
  cp "$PKGSRC_DIR"/src/VBox/Frontends/VirtualBox/images/OSE/about_16px.png "$OSIMG";
done

inform 'Updating VBOX_PRODUCT'
sed -i "s/^\(VBOX_PRODUCT\s*=\s*\).*/\1VirtualBox/g" "$PKGSRC_DIR"/Config.kmk
