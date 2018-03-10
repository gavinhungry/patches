#!/bin/bash

PATCHER_DIR=$(dirname $(realpath $0))
PATCHES_DIR=${PATCHER_DIR}/pkgs
source "$PATCHER_DIR"/abash/abash.sh

(arge help ||
([ -z "$(nfargs)" ] &&
  ! arge unpatched && ! arge list-unpatched && ! arge list-nonlocal:L)) &&
usage '[OPTION]... PACKAGE [PACKAGE]...

  -d, --download          download packages before patching
  -H, --hard-update       rebuild patches by comparing against original packages
  -u, --unpatched         include unpatched installed packages
  -l, --list-unpatched    list unpatched installed packages and exit
  -L, --list-nonlocal     list packages without patches needing local build
  -h, --help              this message
'

PATCHER_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))
PATCHES_DIR="$PATCHER_DIR"/pkgs

[ -d "$PATCHES_DIR" ] || die 'Could not find pkgs directory'

getPkgbuildDir() {
  [ -n "$1" ] || return

  local PATCH_DIR="$PATCHES_DIR"/$1
  [ -d "$PATCH_DIR" ] || return

  local PATCHES=("$PATCH_DIR"/*.patch)
  local PATCH=${PATCHES[0]}

  local PKGBUILD_DIR=$(cat "$PATCH" | grep ^diff | head -n1 | sed 's/.*\s\(.*\)\.ORIG\/.*/\1/')
  cd "$PATCHER_DIR/../$PKGBUILD_DIR" &> /dev/null || return

  pwd
}

getPkgSourceDir() {
  local PKGBUILD_DIR=$(getPkgbuildDir $1)
  local srcdir='./src'

  [ -n "$PKGBUILD_DIR" ] || return
  cd "$PKGBUILD_DIR" &> /dev/null || return
  source PKGBUILD || return

  local pkgbase=${pkgbase:-$pkgname}

  # cd $srcdir/foo-$pkgver
  local PKGSRC_DIR_CMD=$(grep srcdir "$PKGBUILD_DIR"/PKGBUILD | grep pkgver | grep '^\s*cd\s' | head -n1)

  # cd $srcdir/foo-
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname}\\?-\"\\? "$PKGBUILD_DIR"/PKGBUILD | grep '^\s*cd\s' | head -n1)
    cd "$PKGBUILD_DIR"
  fi

  # cd $srcdir/$pkgname
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname "$PKGBUILD_DIR"/PKGBUILD | grep srcdir | grep '^\s*cd\s' | head -n1)
    cd "$PKGBUILD_DIR"
  fi

  # cd $pkgname
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname "$PKGBUILD_DIR"/PKGBUILD | grep '^\s*cd\s' | head -n1)
    cd "$PKGBUILD_DIR"
    cd "$srcdir"
  fi

  # cd $pkgver
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgver "$PKGBUILD_DIR"/PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd $srcdir/foo
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep srcdir "$PKGBUILD_DIR"/PKGBUILD | grep '^\s*cd\s' | head -n1)
    cd "$PKGBUILD_DIR"
  fi

  # cd $pkgname-$pkgver
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname "$PKGBUILD_DIR"/PKGBUILD | grep pkgver | grep '^\s*cd\s' | head -n1)
    cd "$PKGBUILD_DIR"
    cd "$srcdir"
  fi

  # cd
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep '^\s*cd\s' "$PKGBUILD_DIR"/PKGBUILD | head -n1)
    cd "$PKGBUILD_DIR"
    cd "$srcdir"
  fi

  [ -n "$PKGSRC_DIR_CMD" ] || return

  if ! eval "$PKGSRC_DIR_CMD" &> /dev/null; then
     cd "$srcdir" &> /dev/null
     eval "$PKGSRC_DIR_CMD" &> /dev/null || return
  fi

  pwd
}

getPkgSourceDirBase() {
  basename $(getPkgSourceDir $1) 2> /dev/null
}

softUpdatePkg() {
  local PKG=$1
  local PKGSRC_DIR=$(getPkgSourceDir $PKG)
  local PKGSRC_DIR_BASE=$(getPkgSourceDirBase $PKG)

  if [ ! -d "$PKGSRC_DIR" ]; then
    err "Could not find $PKG package source directory"
    return
  fi

  inform "Soft-updating $PKG patches to $PKGSRC_DIR_BASE"
  local PATCHES="$PATCHES_DIR"/$PKG/*.patch
  for PATCH in ${PATCHES[@]}; do
    perl -pe "s|(^diff(.*?)/src/)[^/]*([^\s]*\s)((.*?)/src/)[^/]*|\1${PKGSRC_DIR_BASE}\3\4${PKGSRC_DIR_BASE}\6|g" -i "$PATCH"
    perl -pe "s|(^(---\|\+\+\+)(.*?)src/)[^/]*|\1${PKGSRC_DIR_BASE}|g" -i "$PATCH"
  done
}

softUpdatePkgs() {
  for PKG in "$@"; do
    softUpdatePkg $PKG
  done
}

hardUpdatePkg() {
  local PKG=$1
  local PKGBUILD_DIR=$(getPkgbuildDir $PKG)
  local PKGSRC_DIR_BASE=$(getPkgSourceDirBase $PKG)

  if [ ! -d "$PKGBUILD_DIR" ]; then
    err "Could not find $PKG PKGBUILD directory"
    return
  fi

  local PARENT_DIR=$(basename $(realpath ${PKGBUILD_DIR}/..))
  cd "$PATCHER_DIR"/..

  rm -fr "$PKGBUILD_DIR".ORIG
  cp -r "$PKGBUILD_DIR" "$PKGBUILD_DIR".ORIG

  inform "Hard-updating $PKG patches to $PKGSRC_DIR_BASE"
  local PATCHES="$PATCHES_DIR"/$PKG/*.patch
  for PATCH in ${PATCHES[@]}; do
    patch -Ns -r - -p0 --no-backup-if-mismatch < "$PATCH"
    diff -ru "$PARENT_DIR"/$PKG.ORIG "$PARENT_DIR"/$PKG > "$PATCH"

    rm -fr "$PKGBUILD_DIR"
    cp -r "$PKGBUILD_DIR".ORIG "$PKGBUILD_DIR"
  done

  rm -fr "$PKGBUILD_DIR".ORIG
}

hardUpdatePkgs() {
  for PKG in "$@"; do
    hardUpdatePkg $PKG
  done
}

getUnpatchedPkgs() {
  for DIR in "$PATCHES_DIR"/*/ ; do
    local PKG=$(basename "$DIR")

    pacman -Q $PKG &> /dev/null &&
    [[ "$(expac -Q '%p' $PKG)" != *"[p]" ]] &&
    ! grep "^${PKG}$" .pkgignore &> /dev/null &&
    echo $PKG
  done
}

getNonLocalPkgs() {
  source $HOME/.makepkg.conf
  for PKG in $(cat .pkglocal 2> /dev/null); do
    pacman -Q $PKG &> /dev/null &&
    [[ "$(expac -Q '%p' $PKG)" != "$PACKAGER"* ]] &&
    echo $PKG
  done
}

downloadPkgs() {
  pkgsource $@
}

patchPkg() {
  local PKG=$1
  local PKGBUILD_DIR=$(getPkgbuildDir $PKG)
  local PKGSRC_DIR=$(getPkgSourceDir $PKG)

  if [ ! -d "$PKGSRC_DIR" ]; then
    err "Could not find $PKG package source directory"
    return
  fi

  cd "$PATCHER_DIR"/..

  local PATCHES="$PATCHES_DIR"/$PKG/*.patch
  for PATCH in ${PATCHES[@]}; do
    inform "Applying $(basename $PATCH)"
    patch -Ns -r - -p0 < "$PATCH" || warn 'Error applying patch'
  done

  if [ -x "$PATCHES_DIR"/$PKG/patch.sh ]; then
    cd "$PATCHES_DIR"/$PKG
    source patch.sh
  fi

  cd "$PKGBUILD_DIR" &> /dev/null || warn 'Could not switch to PKGBUILD directory'

  if [ -f PKGBUILD -a ! -f .patched ]; then
    touch .patched
    echo -e "\n"'[[ "$PACKAGER" != *"[p]" ]] && PACKAGER+=" [p]" || true' >> PKGBUILD
  fi
}

patchPkgs() {
  for PKG in "$@"; do
    patchPkg $PKG
  done
}

if arge list-unpatched; then
  getUnpatchedPkgs
  exit
fi

if arge list-nonlocal:L; then
  getNonLocalPkgs
  exit
fi

_PKGS=($(nfargs))
arge unpatched && _PKGS+=($(getUnpatchedPkgs))
PKGS=$(echo ${_PKGS[*]} | tr ' ' '\n' | cut -d'/' -f2 | sort -u)

arge download && downloadPkgs $PKGS

softUpdatePkgs $PKGS
arge hard-update:H && hardUpdatePkgs $PKGS

patchPkgs $PKGS
