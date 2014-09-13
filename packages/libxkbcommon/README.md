xkbcommon
==========================

Parent: [build-locally](../../README.md)

This directory builds the libxkbcommon package.

This package needs [xorg-macros](../xorg-macros/README.md) to avoid this failure:

    COMMAND: autoconf
    configure.ac:44: error: must install xorg-macros 1.16 or later before running autoconf/autogen
    configure.ac:44: the top level
    autom4te: /usr/bin/m4 failed with exit status: 1


Kept getting:

    COMMAND: automake --add-missing
    configure.ac:47: warning: PKG_PROG_PKG_CONFIG is m4_require'd but not m4_defun'd
    aclocal.m4:3008: XORG_INSTALL is expanded from...
    aclocal.m4:2988: XORG_DEFAULT_OPTIONS is expanded from...
    configure.ac:47: the top level
    Makefile.am:155: error: Libtool library used but 'LIBTOOL' is undefined
    Makefile.am:155:   The usual way to define 'LIBTOOL' is to add 'LT_INIT'
    Makefile.am:155:   to 'configure.ac' and run 'aclocal' and 'autoconf' again.
    Makefile.am:155:   If 'LT_INIT' is in 'configure.ac', make sure
    Makefile.am:155:   its definition is in aclocal's search path.

Found: http://stackoverflow.com/questions/15703522/libtool-library-used-but-libtool-is-undefined

Have to have libtool built which is now a dependency of this package.

For this error:

    COMMAND: automake --add-missing
    configure.ac:47: warning: PKG_PROG_PKG_CONFIG is m4_require'd but not m4_defun'd
    aclocal.m4:11595: XORG_INSTALL is expanded from...
    aclocal.m4:11575: XORG_DEFAULT_OPTIONS is expanded from...
    configure.ac:47: the top level
    configure.ac:41: error: required file 'build-aux/ltmain.sh' not found

Found http://www.gnu.org/software/automake/manual/html_node/Error-required-file-ltmain_002esh-not-found.html#Error-required-file-ltmain_002esh-not-found

Just run the autogen.sh script.

Now I get possibly undefined macro: AC_MSG_ERROR

    autoreconf: running: /home/someuser/install/Debian.7.x86_64/bin/autoconf --force --warnings=all
    configure.ac:47: warning: PKG_PROG_PKG_CONFIG is m4_require'd but not m4_defun'd
    aclocal.m4:1844: XORG_INSTALL is expanded from...
    aclocal.m4:1824: XORG_DEFAULT_OPTIONS is expanded from...
    configure.ac:47: the top level
    configure.ac:67: error: possibly undefined macro: AC_MSG_ERROR
          If this token and others are legitimate, please use m4_pattern_allow.
          See the Autoconf documentation.
    autoreconf: /home/someuser/install/Debian.7.x86_64/bin/autoconf failed with exit status: 1

Searching finds http://stackoverflow.com/questions/8811381/possibly-undefined-macro-ac-msg-error

pkg-config must be needed. PKG_PROG_PKG_CONFIG is missing and so pkg-config should provide it.

New error about xkeyboard-config.pc

    checking whether the linker accepts -Wl,--no-undefined... yes
    Package xkeyboard-config was not found in the pkg-config search path.
    Perhaps you should add the directory containing `xkeyboard-config.pc'
    to the PKG_CONFIG_PATH environment variable
    No package 'xkeyboard-config' found
    checking for XCB_XKB... no
    configure: error: xkbcommon-x11 requires xcb-xkb >= 1.10 which was not found. You can disable X11 support with --disable-x11.

/usr/share/pkgconfig/xkeyboard-config.pc exists.

From the pkg-config man page:

       PKG_CONFIG_PATH
              A colon-separated (on Windows, semicolon-separated) list
              of directories to search for .pc files.  The default
              directory will always be searched after searching the
              path; the default is libdir/pkgconfig:datadir/pkgconfig
              where libdir is the libdir for pkg-config and datadir is
              the datadir for pkg-config when it was installed.

And that is correct. Here we really do not want to be dependent upon
what is installed in /usr/share/ unless that is the only way to go
about it.

We have to build http://www.freedesktop.org/Software/XKeyboardConfig into ../xkeyboard-config

Now xcb-xkb is needed:

    configure: error: xkbcommon-x11 requires xcb-xkb >= 1.10 which was not found. You can disable X11 support with --disable-x11.

I'm stuck

    https://github.com/stapelberg/libxcb/blob/master/xcb-xkb.pc.in#raw-url

has it but where is the Debian package for that? Could not find it.

I will have to install xcb-xkb from source. And maybe have to remove
the HACK changes to PKG_CONFIG_PATH for x11 and x11proto too.
