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
stat -t ${PATCHES} &> /dev/null || die 'No patch files'

_PATCH=${PATCHES[0]}
PKGBUILD_DIR=$(cat ${_PATCH} | grep ^diff | head -n1 | sed 's/.*\s\(.*\)\.ORIG\/.*/\1/')
cd ${PATCHER_DIR}/../${PKGBUILD_DIR} || die 'Could not switch to PKGBUILD directory'

source PKGBUILD || die 'Could not source PKGBUILD'

PKGSRC_DIR_CMD=$(grep srcdir PKGBUILD | awk '{$1=$1}1' | grep ^cd | head -n1)
eval ${PKGSRC_DIR_CMD} || 'Could not swtich to package source directory'
PKGSRC_DIR=$(pwd)
PKGSRC_DIR_BASE=$(basename ${PKGSRC_DIR})

inform 'Updating patches to' ${PKGSRC_DIR_BASE}
for PATCH in ${PATCHES[@]}; do
  perl -pe "s|(^diff(.*?)src/)[^/]*((.*?)src/)*[^/]*|\1\\${PKGSRC_DIR_BASE}\3\\${PKGSRC_DIR_BASE}|g" -i ${PATCH}
  perl -pe "s|(^(---\|\+\+\+)(.*?)src/)[^/]*|\1\\${PKGSRC_DIR_BASE}|g" -i ${PATCH}
done
