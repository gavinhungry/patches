#!/bin/bash

for DIR in */ ; do
  PKG=${DIR%*/}
  PACKAGER=$(pacman -Qi $PKG 2>&1 | grep ^Packager | cut -d':' -f2 | sed 's/^\s*//g')

  if [[ $PACKAGER && $PACKAGER != $(gecos ${USER})* ]]; then
    echo $PKG
  fi
done
