cd abs/virtualbox

source ./PKGBUILD

for OSIMG in ./src/VirtualBox-${pkgver}/src/VBox/Frontends/VirtualBox/images/os_*; do
  cp ./src/VirtualBox-${pkgver}/src/VBox/Frontends/VirtualBox/images/OSE/VirtualBox_16px.png $OSIMG;
done

sed -i "s/^\(VBOX_PRODUCT\s*=\s*\).*/\1VirtualBox/g" ./src/VirtualBox-${pkgver}/Config.kmk
