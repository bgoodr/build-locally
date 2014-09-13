xorg-macros
==========================

Parent: [build-locally](../../README.md)

This directory builds the xorg-macros package needed by [libxkbcommon](../libxkbcommon/README.md).

libxkbcommon needed xorg-macros because of this failure:

    COMMAND: autoconf
    configure.ac:44: error: must install xorg-macros 1.16 or later before running autoconf/autogen
    configure.ac:44: the top level
    autom4te: /usr/bin/m4 failed with exit status: 1

Searching finds https://lists.debian.org/debian-user/2011/10/msg01045.html

apt-cache search xorg-macros returns:

    xutils-dev - X Window System utility programs for development

installed xutils-dev on Debian to understand where the file will go:

    /usr/share/aclocal/xorg-macros.m4

and then removed the package as I want to avoid being dependent upon
Debian since this needs to run on RHEL6 too.

Found http://cgit.freedesktop.org/xorg/util/macros/ has this:

    http://cgit.freedesktop.org/xorg/util/macros/
 
as the git repo. 
