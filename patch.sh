#!/bin/bash

PATCHER_DIR=$(dirname $(realpath $0))
PATCHES_DIR=${PATCHER_DIR}/pkgs
source ${PATCHER_DIR}/abash/abash.sh

PKG=$1
PKG=${PKG#pkgs/}
PKG=${PKG%/}
[ -n "${PKG}" ] || usage 'PACKAGE'

PATCH_DIR=${PATCHES_DIR}/${PKG}
[ -d "${PATCH_DIR}" ] || die 'Could not find patch directory'

source ${PATCHER_DIR}/soft-update.sh ${PKG}
cd ${PATCHER_DIR}/..

for PATCH in ${PATCH_DIR}/*.patch; do
  inform 'Applying' $(basename ${PATCH})
  patch -Ns -r - -p0 < ${PATCH} || die 'Error applying patch'
done

if [ -x ${PATCH_DIR}/patch.sh ]; then
  [ -d "$PKGSRC_DIR" ] && cd ${PKGSRC_DIR}
  source ${PATCH_DIR}/patch.sh
fi
