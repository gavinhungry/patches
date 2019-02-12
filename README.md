patches
=======
Patches for Arch Linux packages to fix things that annoy me

Usage
=====
    $ ./patch.sh 
    usage: patch.sh [OPTION]... PACKAGE [PACKAGE]...

      -d, --download          download packages before patching
      -D, --download-only     download packages without patching
      -H, --hard-update       rebuild patches by comparing against original packages
      -u, --unpatched         include unpatched installed packages
      -l, --list-unpatched    list unpatched installed packages and exit
      -L, --list-nonlocal     list packages without patches needing local build
      -h, --help              this message
