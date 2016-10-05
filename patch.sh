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

. ${PATCHER_DIR}/soft-update.sh ${PKG}
PKGBUILD_DIR=$(pwd)

ARCH_DIR=${PATCHER_DIR}/..
cd ${ARCH_DIR}

PATCHES=(${PATCH_DIR}/*.patch)
if stat -t ${PATCHES} &> /dev/null; then
  for PATCH in ${PATCHES[@]}; do
    inform 'Applying' $(basename ${PATCH})
    patch -Ns -r - -p0 < ${PATCH} || die 'Error applying patch'
  done
fi

if [ -x ${PATCH_DIR}/patch.sh ]; then
  cd ${PATCH_DIR}
  # patch.sh should switch to PKGBUILD directory
  source ${PATCH_DIR}/patch.sh ${ARCH_DIR} ${PKGSRC_DIR}
else
  cd ${PKGBUILD_DIR} &> /dev/null || die 'Could not switch to PKGBUILD directory'
fi

if [ -f PKGBUILD -a ! -f .patched ]; then
  touch .patched
  echo -e "\n"'[[ "$PACKAGER" != *"[p]" ]] && PACKAGER+=" [p]" || true' >> PKGBUILD
fi
