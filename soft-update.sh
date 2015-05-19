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

  source PKGBUILD || die 'Could not source PKGBUILD'

  PKGSRC_DIR_CMD=$(grep srcdir PKGBUILD | grep '^\s*cd\s' | head -n1)
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep '^\s*cd\s' PKGBUILD | head -n1)
    cd ${srcdir}
  fi
  
  [ -n "$PKGSRC_DIR_CMD" ] || die 'Cound not find package source directory'

  eval ${PKGSRC_DIR_CMD} &> /dev/null || 'Could not switch to package source directory'
  PKGSRC_DIR=$(pwd)
  PKGSRC_DIR_BASE=$(basename ${PKGSRC_DIR})

  inform 'Updating patches to' ${PKGSRC_DIR_BASE}
  for PATCH in ${PATCHES[@]}; do
    perl -pe "s|(^diff(.*?)/src/)[^/]*([^\s]*\s)((.*?)/src/)[^/]*|\1${PKGSRC_DIR_BASE}\3\4${PKGSRC_DIR_BASE}\6|g" -i ${PATCH}
    perl -pe "s|(^(---\|\+\+\+)(.*?)src/)[^/]*|\1${PKGSRC_DIR_BASE}|g" -i ${PATCH}
  done
else
  warn 'No patch files'
fi
