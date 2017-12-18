patches
=======
Patches for Arch Linux packages to fix things that annoy me

Usage
=====
```sh
$ ./patch.sh 
usage: patch.sh [OPTION]... PACKAGE [PACKAGE]...

  -d, --download          download packages before patching
  -H, --hard-update       rebuild patches by comparing against original packages
  -u, --unpatched         include unpatched installed packages
  -l, --list-unpatched    list unpatched installed packages and exit
  -h, --help              this message
```
