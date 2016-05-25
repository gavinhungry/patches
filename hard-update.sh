#!/bin/bash

source $(dirname "${BASH_SOURCE}")/soft-update.sh "$@"
rm -fr ${PKGBUILD_DIR}.ORIG
cp -r ${PKGBUILD_DIR} ${PKGBUILD_DIR}.ORIG

cd ${PATCHER_DIR}/..

inform 'Hard-updating patches to' ${PKGSRC_DIR_BASE}
for PATCH in ${PATCHES[@]}; do
  inform 'Updating' $(basename ${PATCH})
  patch -Ns -r - -p0 < $PATCH
  diff -ru ${PKGBUILD_PARENT}/${PKG}.ORIG ${PKGBUILD_PARENT}/${PKG} > ${PATCH}

  rm -fr ${PKGBUILD_DIR}
  cp -r ${PKGBUILD_DIR}.ORIG ${PKGBUILD_DIR}
done

rm -fr ${PKGBUILD_DIR}.ORIG
