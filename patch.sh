#!/bin/bash

PATCHES_DIR=$(dirname $(realpath $0))
PACKAGES_DIR=${PATCHES_DIR}/../packages

source "$PATCHES_DIR"/.abash/abash.sh

(arge help ||
([ -z "$(nfargs)" ] &&
  ! arge unpatched && ! arge list-unpatched && ! arge list-nonlocal:L)) &&
usage '[OPTION]... PACKAGE [PACKAGE]...

  -d, --download          download packages before patching
  -D, --download-only     download packages without patching
  -H, --hard-update       rebuild patches by comparing against original packages
  -u, --unpatched         include unpatched installed packages
  -l, --list-unpatched    list unpatched installed packages and exit
  -L, --list-nonlocal     list packages without patches needing local build
  -h, --help              this message
'

getPkgbuildDir() {
  [ -n "$1" ] || return

  local PATCH_DIR="$PATCHES_DIR"/$1
  [ -d "$PATCH_DIR" ] || return

  local PATCHES=("$PATCH_DIR"/*.patch)
  local PATCH=${PATCHES[0]}

  if [ -n "$PATCH" ]; then
    echo "$PACKAGES_DIR"/$1
    return
  fi

  local PKGBUILD_DIR=$(cat "$PATCH" | grep ^diff | head -n1 | sed 's/.*\s\(.*\)\.ORIG\/.*/\1/')
  cd "$PACKAGES_DIR/$PKGBUILD_DIR" &> /dev/null || return

  echo "$PWD"
}

getPkgSourceDir() {
  local PKGBUILD_DIR=$(getPkgbuildDir $1)
  local srcdir='./src'
  local TRY_MESON=0

  [ -n "$PKGBUILD_DIR" ] || return
  cd "$PKGBUILD_DIR" &> /dev/null || return
  source PKGBUILD || return

  if [ -x "$PATCHES_DIR"/$PKG/pkgsrcdir.sh ]; then
    source "$PATCHES_DIR"/$PKG/pkgsrcdir.sh
    return
  fi

  local pkgbase=${pkgbase:-$pkgname}

  # cd $srcdir/foo-$pkgver
  local PKGSRC_DIR_CMD=$(grep srcdir PKGBUILD | grep pkgver | grep '^\s*cd\s' | head -n1)

  # cd $pkgname-foo
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname}\\?-\"\\? PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd $srcdir/$pkgname
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname PKGBUILD | grep srcdir | grep '^\s*cd\s' | head -n1)
  fi

  # cd $pkgname
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd $pkgver
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgver PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd $srcdir/foo
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep srcdir PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd $pkgname-$pkgver
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgname PKGBUILD | grep pkgver | grep '^\s*cd\s' | head -n1)
  fi

  # cd $pkgbase-foo
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep pkgbase}\\?-\"\\? PKGBUILD | grep '^\s*cd\s' | head -n1)
  fi

  # cd
  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_CMD=$(grep '^\s*cd\s' PKGBUILD | head -n1)
    [ -n "$PKGSRC_DIR_CMD" ] && TRY_MESON=1
  fi

  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_STR=$(grep -e '\s\+patch -d' PKGBUILD | sed 's/.* -d \([^\ ]*\).*/\1/g' | head -n1)
    [ -n "$PKGSRC_DIR_STR" ] && PKGSRC_DIR_CMD="cd $PKGSRC_DIR_STR"
  fi

  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_STR=$(grep '^\s\+make\s' PKGBUILD | sed 's/.*-C "\(.*\)".*/\1/g' | head -n1)
    [ -n "$PKGSRC_DIR_STR" ] && PKGSRC_DIR_CMD="cd $PKGSRC_DIR_STR"
  fi

  if [ -z "$PKGSRC_DIR_CMD" ]; then
    PKGSRC_DIR_STR=$(grep '^\s\+cmake\s' PKGBUILD | sed 's/.*-S "\(.*\)".*/\1/g' | head -n1)
    [ -n "$PKGSRC_DIR_STR" ] && PKGSRC_DIR_CMD="cd $PKGSRC_DIR_STR"
  fi

  if [ -n "$PKGSRC_DIR_CMD" ]; then
    cd "$srcdir" &> /dev/null

    if ! eval "$PKGSRC_DIR_CMD" &> /dev/null; then
      cd "$PKGBUILD_DIR" &> /dev/null
      eval "$PKGSRC_DIR_CMD" &> /dev/null # || return
    fi
  fi

  if [ -z "$PKGSRC_DIR_CMD" -o $TRY_MESON == 1 ]; then
    MESON_DIR=$(grep arch-meson "$PKGBUILD_DIR"/PKGBUILD | awk '{print $2;}')

    [ -n "$MESON_DIR" ] &&
    [ "$(eval echo "src/$MESON_DIR")" != "$(basename "$(pwd -P)")" ] &&
    cd "$(eval echo "src/$MESON_DIR")" &> /dev/null
  fi

  if [ $(realpath "$PWD" --relative-to "$PKGBUILD_DIR") != '.' ]; then
    echo "$PWD"
  else
    echo "${PKGBUILD_DIR}/src"
  fi
}

getPkgSourceDirBase() {
  basename $(getPkgSourceDir $1) 2> /dev/null
}

softUpdatePkg() {
  local PKG=$1
  [ -e "$PATCHES_DIR"/$PKG/.no-update ] && return

  local PKGSRC_DIR=$(getPkgSourceDir $PKG)
  local PKGSRC_DIR_BASE=$(getPkgSourceDirBase $PKG)

  if [ ! -d "$PKGSRC_DIR" ]; then
    err "Could not find $PKG package source directory"
    return 1
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
  [ -e "$PATCHES_DIR"/$PKG/.no-update ] && return
  
  local PKGBUILD_DIR=$(getPkgbuildDir $PKG)
  local PKGSRC_DIR_BASE=$(getPkgSourceDirBase $PKG)

  if [ ! -d "$PKGBUILD_DIR" ]; then
    err "Could not find $PKG PKGBUILD directory"
    return 1
  fi

  local PARENT_DIR=$(basename $(realpath ${PKGBUILD_DIR}/..))
  cd "$PACKAGES_DIR"

  rm -fr "$PKGBUILD_DIR".ORIG
  cp -r "$PKGBUILD_DIR" "$PKGBUILD_DIR".ORIG

  inform "Hard-updating $PKG patches to $PKGSRC_DIR_BASE"
  local PATCHES="$PATCHES_DIR"/$PKG/*.patch
  for PATCH in ${PATCHES[@]}; do
    patch -Ns -r - -p0 --no-backup-if-mismatch < "$PATCH"
    diff -ru "$PKG.ORIG" "$PKG" > "$PATCH"

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

  # if [ ! -d "$PKGSRC_DIR" ]; then
  #   return
  # fi

  cd "$PACKAGES_DIR"

  if compgen -G "$PATCHES_DIR"/$PKG/*.patch > /dev/null; then
    local PATCHES="$PATCHES_DIR"/$PKG/*.patch
    for PATCH in ${PATCHES[@]}; do
      inform "Applying $(basename $PATCH)"
      patch -Ns -r - -p0 --no-backup-if-mismatch < "$PATCH" || warn 'Error applying patch'
    done
  fi

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

arge list-unpatched && getUnpatchedPkgs
arge list-nonlocal:L && getNonLocalPkgs

if arge list-unpatched || arge list-nonlocal:L; then
  exit
fi

_PKGS=($(nfargs))
arge unpatched && _PKGS+=($(getUnpatchedPkgs))
_PKGS=$(echo ${_PKGS[*]} | tr ' ' '\n' | cut -d'/' -f1 | sort -u)

PKGS=""
NOSYNC_PKGS=""

for PKG in $_PKGS; do
  [ -e "$PATCHES_DIR"/$PKG/.no-sync ] &&
    NOSYNC_PKGS+="$PKG " ||
    PKGS+="$PKG "
done

if (arge download || arge download-only:D); then
  [ -n "$PKGS" ] && downloadPkgs $PKGS
  [ -n "$NOSYNC_PKGS" ] && downloadPkgs -p $NOSYNC_PKGS
fi

arge download-only:D && exit

softUpdatePkgs $PKGS
arge hard-update:H && hardUpdatePkgs $PKGS

patchPkgs $_PKGS
