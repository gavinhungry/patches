#!/bin/bash

PATCHER_DIR=$(dirname $(realpath $0))
PATCHES_DIR=${PATCHER_DIR}/pkgs
source ${PATCHER_DIR}/abash/abash.sh

for DIR in ${PATCHES_DIR}/* ; do
  PKG=$(basename ${DIR})
  PACKAGER=$(pacman -Qi ${PKG} 2>&1 | grep ^Packager | cut -d':' -f2-)

  if [[ ${PACKAGER} != *"[p]" ]] && \
    pacman -Q ${PKG} &> /dev/null && \
    ! grep "^${PKG}$" .pkgignore &> /dev/null;
  then
    arge download && pkgsource ${PKG} || echo ${PKG}
  fi
done
