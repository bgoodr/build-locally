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

- The user has to use multiple operating systems under the same
  account (see [Warning](#warning-about-renaming-install_dir) below)

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

Warning about renaming INSTALL_DIR
==================================

If you upgrade your system, then it is likely that `INSTALL_DIR`
variable used in all of the scripts will change, and thus you will
have to rebuild those packages using the new `INSTALL_DIR`.

The reason an `INSTALL_DIR` has a different value for each different
system is because, in practice, if you have to work with multiple
different Linux releases within the same NFS system (e.g., with the
same HOME directory), you will want all of your packages to be
available and built to work with that system.

Below is an example of what not to do:

The default for the `INSTALL_DIR` variable (in
[init_vars.bash](support-files/init_vars.bash)). So, I rebuilt
autoconf at one point and the `INSTALL_DIR` variable was:

    /home/someuser/install/Ubuntu.16.04.1.x86_64

Then some time passed, and I upgraded my system such that the default `INSTALL_DIR` was:

    /home/someuser/install/Ubuntu.16.04.2.x86_64

Then, I might have moved the above "2" directory back to the "1". but then when invoking autoreconf, it fails with:

    Can't locate Autom4te/ChannelDefs.pm in @INC (you may need to install the Autom4te::ChannelDefs module) (@INC contains: /home/someuser/install/Ubuntu.16.04.1.x86_64/share/autoconf /etc/perl /usr/local/lib/x86_64-linux-gnu/perl/5.22.1 /usr/local/share/perl/5.22.1 /usr/lib/x86_64-linux-gnu/perl5/5.22 /usr/share/perl5 /usr/lib/x86_64-linux-gnu/perl/5.22 /usr/share/perl/5.22 /usr/local/lib/site_perl /usr/lib/x86_64-linux-gnu/perl-base .) at /home/someuser/install/Ubuntu.16.04.2.x86_64/bin/autoreconf line 39.
    BEGIN failed--compilation aborted at /home/someuser/install/Ubuntu.16.04.2.x86_64/bin/autoreconf line 39.

Looking inside ~/install/Ubuntu.16.04.2.x86_64/bin/autoreconf we see

    my $pkgdatadir = $ENV{'autom4te_perllibdir'} || '/home/someuser/install/Ubuntu.16.04.1.x86_64/share/autoconf';

So the fully-qualified path to the old directory is being referenced
there and thus is not relocatable. So renaming the directory is not an
option.

You have to rebuild all of the packages I need. Granted, I end up
just creating symbolic links inside the install directory to bypass
having to rebuild packages but that defeats the purpose of having
`INSTALL_DIR` be as fine-grained as it is.

Also consider that fully qualified values of RPATH are being used in
executables in many packages.

Packages
========

The following is a list of packages whose build programs are provided by this package:

* [atk](packages/atk/README.md): Building the atk package.
* [autoconf](packages/autoconf/README.md): Building the autoconf package.
* [automake](packages/automake/README.md): Building the automake package.
* [bdwgc](packages/bdwgc/README.md): Building the bdwgc package.
* [bison](packages/bison/README.md): Building the bison package.
* [cairo](packages/cairo/README.md): Building the cairo package.
* [colm](packages/colm/README.md): Building the colm package.
* [emacs](packages/emacs/README.md): Building the emacs package.
* [example-package](packages/example-package/README.md): An example directory to serve as a template for adding more packages to be built by this project.
* [flex](packages/flex/README.md): Building the flex package.
* [freetype](packages/freetype/README.md): Building the freetype package.
* [gdb](packages/gdb/README.md): Building the gdb package.
* [gettext](packages/gettext/README.md): Building the gettext package.
* [git](packages/git/README.md): Building the Git package.
* [glib](packages/glib/README.md): Building the glib package.
* [gmp](packages/gmp/README.md): Building the gmp package.
* [gnome-common](packages/gnome-common/README.md): Building the gnome-common package.
* [gobject-introspection](packages/gobject-introspection/README.md): Building the gobject-introspection package.
* [gtk-doc](packages/gtk-doc/README.md): Building the gtk-doc package.
* [gtk](packages/gtk/README.md): Building the gtk package.
* [guile](packages/guile/README.md): Building the guile package.
* [harfbuzz](packages/harfbuzz/README.md): Building the harfbuzz package.
* [help2man](packages/help2man/README.md): Building the help2man package.
* [idutils](packages/idutils/README.md): Building the idutils package.
* [intltool](packages/intltool/README.md): Building the intltool package.
* [libffi](packages/libffi/README.md): Building the libffi package.
* [libpng](packages/libpng/README.md): Building the libpng package.
* [libtool](packages/libtool/README.md): Building the libtool package.
* [libunistring](packages/libunistring/README.md): Building the libunistring package.
* [libxkbcommon](packages/libxkbcommon/README.md): Building the libxkbcommon package.
* [make](packages/make/README.md): Building the make package.
* [numdiff](packages/numdiff/README.md): Building the numdiff package.
* [pango](packages/pango/README.md): Building the pango package.
* [patchelf](packages/patchelf/README.md): Building the patchelf package.
* [perl--cpanm](packages/perl--cpanm/README.md): Building the Perl--cpanm language system.
* [perl](packages/perl/README.md): Building the Perl language system.
* [perl--xml-parser](packages/perl--xml-parser/README.md): Building the Perl--xml-parser language system.
* [pixman](packages/pixman/README.md): Building the pixman package.
* [pkg-config](packages/pkg-config/README.md): Building the pkg-config package.
* [python--ipython](packages/python--ipython/README.md): Building the ipython package into the Python installation tree.
* [python--jira-python](packages/python--jira-python/README.md): Building the jira-python package into the Python installation tree.
* [python](packages/python/README.md): Building the Python language system.
* [python--pip](packages/python--pip/README.md): Building the pip Python package into the Python installation tree.
* [python--rbtools](packages/python--rbtools/README.md): Building the python--rbtools package.
* [python--readline](packages/python--readline/README.md): Building the readline Python package into the Python installation tree.
* [python--setuptools](packages/python--setuptools/README.md): Building the setuptools package into the Python installation tree.
* [qt](packages/qt/README.md): Building the Qt framework.
* [ragel](packages/ragel/README.md): Building the ragel package.
* [rdesktop](packages/rdesktop/README.md): Building the rdesktop package.
* [sqlite3](packages/sqlite3/README.md): Building the sqlite3 package.
* [texinfo](packages/texinfo/README.md): Building the texinfo package.
* [xbindkeys](packages/xbindkeys/README.md): Building the xbindkeys package.
* [xkeyboard-config](packages/xkeyboard-config/README.md): Building the xkeyboard-config package.
* [xorg-macros](packages/xorg-macros/README.md): Building the xorg-macros package.


Development
===========

See [build-locally.org](build-locally.org).
