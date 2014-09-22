build-locally
=============

This package provides build programs (typically just shell scripts)
that allow automatic downloading, building, and installing (locally)
source packages onto existing systems, typically in a users HOME
directory. Building locally in this context includes either full
compilation or just downloading and installing packages that do not
require compilation (but the goal is to always build from sources
where possible (some exceptions will be allowed).

This is needed in one or more of the following situations:

- It is difficult to install or upgrade packages using standard
  mechanisms (e.g., Apt, Yum).

- The package is not provided by the base operating system.

- It is desired to build the package without disturbing the
  configuration of the system, which may be in use by multiple
  users. Or you do not have system administrator (root) permissions
  and desire not to obtain those permissions just to install packages
  for your local use.

- A more recent package is desired, whereas the operating system
  provided package is too old.

After building, it is intended that the user prepend to the resulting
installation bin directory to their PATH. This will override the
target platforms default installation location (e.g., override what is
installed in /usr/bin) when one of the scripts or executables in the
package is invoked from the UNIX/Linux shell command prompt.

These build programs are intensionally limited to building only those
packages whose build logic that can be coerced (typically via dynamic
build logic patching) into *not* prompting, and that can be downloaded
from source directly from the Internet.


Usage
=====

The following is an example of building the ficticious
"example-package" on Linux, assuming that "whynot" is the GitHub user
name that contains these files (e.g., GitHub cloning):

    cd $HOME  # typically
    mkdir whynot
    cd whynot
    git clone https://github.com/whynot/build-locally.git
    $HOME/whynot/build-locally/packages/example-package/linux/build.bash

To build the other packages, just change "example-package" to the name of
the package to build above.

Packages
========

The following is a list of packages whose build programs are provided by this package:

* [atk](packages/atk/README.md): Building the atk package.
* [autoconf](packages/autoconf/README.md): Building the autoconf package.
* [automake](packages/automake/README.md): Building the automake package.
* [bison](packages/bison/README.md): Building the bison package.
* [cairo](packages/cairo/README.md): Building the cairo package.
* [colm](packages/colm/README.md): Building the colm package.
* [emacs](packages/emacs/README.md): Building the emacs package.
* [example-package](packages/example-package/README.md): An example directory to serve as a template for adding more packages to be built by this project.
* [flex](packages/flex/README.md): Building the flex package.
* [freetype](packages/freetype/README.md): Building the freetype package.
* [gettext](packages/gettext/README.md): Building the gettext package.
* [glib](packages/glib/README.md): Building the glib package.
* [gnome-common](packages/gnome-common/README.md): Building the gnome-common package.
* [gobject-introspection](packages/gobject-introspection/README.md): Building the gobject-introspection package.
* [gtk-doc](packages/gtk-doc/README.md): Building the gtk-doc package.
* [harfbuzz](packages/harfbuzz/README.md): Building the harfbuzz package.
* [help2man](packages/help2man/README.md): Building the help2man package.
* [idutils](packages/idutils/README.md): Building the idutils package.
* [intltool](packages/intltool/README.md): Building the intltool package.
* [libffi](packages/libffi/README.md): Building the libffi package.
* [libpng](packages/libpng/README.md): Building the libpng package.
* [libtool](packages/libtool/README.md): Building the libtool package.
* [libxkbcommon](packages/libxkbcommon/README.md): Building the libxkbcommon package.
* [make](packages/make/README.md): Building the make package.
* [patchelf](packages/patchelf/README.md): Building the patchelf package.
* [perl--cpanm](packages/perl--cpanm/README.md): Building the Perl--cpanm language system.
* [perl--xml-parser](packages/perl--xml-parser/README.md): Building the Perl--xml-parser language system.
* [perl](packages/perl/README.md): Building the Perl language system.
* [pkg-config](packages/pkg-config/README.md): Building the pkg-config package.
* [pixman](packages/pixman/README.md): Building the pixman package.
* [python--ipython](packages/python--ipython/README.md): Building the ipython package into the Python installation tree.
* [python--jira-python](packages/python--jira-python/README.md): Building the jira-python package into the Python installation tree.
* [python--pip](packages/python--pip/README.md): Building the pip Python package into the Python installation tree.
* [python--rbtools](packages/python--rbtools/README.md): Building the python--rbtools package.
* [python--readline](packages/python--readline/README.md): Building the readline Python package into the Python installation tree.
* [python--setuptools](packages/python--setuptools/README.md): Building the setuptools package into the Python installation tree.
* [python](packages/python/README.md): Building the Python language system.
* [qt](packages/qt/README.md): Building the Qt framework.
* [ragel](packages/ragel/README.md): Building the ragel package.
* [sqlite3](packages/sqlite3/README.md): Building the sqlite3 package.
* [texinfo](packages/texinfo/README.md): Building the texinfo package.
* [xkeyboard-config](packages/xkeyboard-config/README.md): Building the xkeyboard-config package.
* [xorg-macros](packages/xorg-macros/README.md): Building the xorg-macros package.


Development
===========

See [build-locally.org](build-locally.org).
