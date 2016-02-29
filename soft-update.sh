#!/bin/bash

PATCHER_DIR=$(dirname $(realpath $0))
PATCHES_DIR=${PATCHER_DIR}/pkgs
source ${PATCHER_DIR}/abash/abash.sh

PKG=$1
PKG=${PKG#pkgs/}
PKG=${PKG%/}
[ -n "${PKG}" ] || usage 'PACKAGE'

srcdir='./src'

PATCH_DIR=${PATCHES_DIR}/${PKG}
[ -d "${PATCH_DIR}" ] || die 'Could not find patch directory'

PATCHES=(${PATCH_DIR}/*.patch)
if stat -t ${PATCHES} &> /dev/null; then
  _PATCH=${PATCHES[0]}
  PKGBUILD_DIR=$(cat ${_PATCH} | grep ^diff | head -n1 | sed 's/.*\s\(.*\)\.ORIG\/.*/\1/')
  cd ${PATCHER_DIR}/../${PKGBUILD_DIR} &> /dev/null || die 'Could not switch to PKGBUILD directory'
  PKGBUILD_DIR=$(pwd)

  source PKGBUILD || die 'Could not source PKGBUILD'
  pkgbase=${pkgbase:-$pkgname}

  # cd $srcdir/foo-$pkgver
  PKGSRC_DIR_CMD=$(grep srcdir ${PKGBUILD_DIR}/PKGBUILD | grep pkgver | grep '^\s*cd\s' | head -n1)

  # cd $srcdir/foo-
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname}\\?-\"\\? ${PKGBUILD_DIR}/PKGBUILD | grep '^\s*cd\s' | head -n1)
    cd "${PKGBUILD_DIR}"
  fi

  # cd $pkgname
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname ${PKGBUILD_DIR}/PKGBUILD | grep '^\s*cd\s' | head -n1)
    cd "${PKGBUILD_DIR}"
    cd "${srcdir}"
  fi

  # cd $pkgver
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgver ${PKGBUILD_DIR}/PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd $srcdir/foo
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep srcdir ${PKGBUILD_DIR}/PKGBUILD | grep '^\s*cd\s' | head -n1)
    cd "${PKGBUILD_DIR}"
  fi

  # cd $pkgname-$pkgver
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname ${PKGBUILD_DIR}/PKGBUILD | grep pkgver | grep '^\s*cd\s' | head -n1)
    cd "${PKGBUILD_DIR}"
    cd "${srcdir}"
  fi

  # cd
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep '^\s*cd\s' ${PKGBUILD_DIR}/PKGBUILD | head -n1)
    cd "${PKGBUILD_DIR}"
    cd "${srcdir}"
  fi

  [ -n "$PKGSRC_DIR_CMD" ] || die 'Cound not find package source directory'

  eval ${PKGSRC_DIR_CMD} &> /dev/null || cd ${srcdir} &> /dev/null
  eval ${PKGSRC_DIR_CMD} &> /dev/null || die 'Could not switch to package source directory'

  PKGSRC_DIR=$(pwd)
  PKGSRC_DIR_BASE=$(basename ${PKGSRC_DIR})

  inform 'Updating patches to' ${PKGSRC_DIR_BASE}
  for PATCH in ${PATCHES[@]}; do
    perl -pe "s|(^diff(.*?)/src/)[^/]*([^\s]*\s)((.*?)/src/)[^/]*|\1${PKGSRC_DIR_BASE}\3\4${PKGSRC_DIR_BASE}\6|g" -i ${PATCH}
    perl -pe "s|(^(---\|\+\+\+)(.*?)src/)[^/]*|\1${PKGSRC_DIR_BASE}|g" -i ${PATCH}
  done

  cd ${PKGBUILD_DIR} &> /dev/null || die 'Could not switch back to PKGBUILD directory'
else
  warn 'No patch files'
fi
