#!/bin/bash

source $(dirname "${BASH_SOURCE}")/soft-update.sh "$@"
rm -fr ${PKGBUILD_DIR}.ORIG
cp -r ${PKGBUILD_DIR} ${PKGBUILD_DIR}.ORIG

cd ${PATCHER_DIR}/..

for PATCHFILE in ${PATCHES[@]}; do
  patch -p0 < $PATCHFILE
  diff -ru ${PKGBUILD_PARENT}/${PKG}.ORIG ${PKGBUILD_PARENT}/${PKG} > ${PATCHFILE}

  rm -fr ${PKGBUILD_DIR}
  cp -r ${PKGBUILD_DIR}.ORIG ${PKGBUILD_DIR}
done

rm -fr ${PKGBUILD_DIR}.ORIG
