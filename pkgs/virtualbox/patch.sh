ARCH_DIR=$1
PKGSRC_DIR=$2

cd ${ARCH_DIR}/abs/virtualbox
source ./PKGBUILD

inform 'Replacing icons'
for OSIMG in ./src/VirtualBox-${pkgver}/src/VBox/Frontends/VirtualBox/images/{hidpi,}/os_*; do
  cp ./src/VirtualBox-${pkgver}/src/VBox/Frontends/VirtualBox/images/OSE/about_16px.png ${OSIMG};
done

inform 'Updating VBOX_PRODUCT'
sed -i "s/^\(VBOX_PRODUCT\s*=\s*\).*/\1VirtualBox/g" ./src/VirtualBox-${pkgver}/Config.kmk
