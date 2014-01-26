#!/bin/bash

for DIR in */ ; do
  PKG=${DIR%*/}
  PACKAGER=$(pacman -Qi $PKG | grep ^Packager | cut -d':' -f2 | sed 's/^\s*//g')

  if [[ $PACKAGER != $(gecos ${USER})* ]]; then
    echo $PKG - $PACKAGER

    [ "x$1" != 'x-p' ] && (pkgsource $PKG; echo)
  fi
done
