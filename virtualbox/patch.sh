cd abs/virtualbox

source ./PKGBUILD

for OSIMG in ./src/VirtualBox-$pkgver/src/VBox/Frontends/VirtualBox/images/os_*; do
  cp ./src/VirtualBox-$pkgver/src/VBox/Resources/other/virtualbox-vbox-16px.png $OSIMG;
done

sed -i "s/Oracle VM VirtualBox/VirtualBox/g" $(grep -rl "Oracle VM VirtualBox" *)
