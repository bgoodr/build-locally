#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

CLEAN=0
while [ $# -gt 0 ]
do
  if [ "$1" = "-builddir" ]
  then
    BUILD_DIR="$2"
    shift
  elif [ "$1" = "-installdir" ]
  then
    INSTALL_DIR="$2"
    shift
  elif [ "$1" = "-clean" ]
  then
    CLEAN=1
  elif [ "$1" = "-h" ]
  then
    EmitStandardUsage
    exit 0
  else
    echo "Undefined parameter $1"
    exit 1
  fi
  shift
done

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# Taking a hint from the script mentioned at
# https://askubuntu.com/a/947219/340383 (which is
# https://github.com/mtalexan/emacs-settings/blob/master/global_install.sh),
# we move aside the ctags that the emacs builds produce so that we can
# build one here. We have to do this before the check for dependency
# in a bit.
if [ "$(which ctags)" = "$INSTALL_DIR/bin/ctags" ]
then
  echo "ctags exists in INSTALL_DIR/bin already"
  emacs_version_ctags=$(ctags --version | grep "Emacs")
  if [ -n "$emacs_version_ctags" ] ; then
    echo "Ctags version found in path is an Emacs version (too old for GNU Global). Moving it aside now."
    mv $INSTALL_DIR/bin/ctags $INSTALL_DIR/bin/ctags.moved.for.gnu.global.b7f2c3b9-3f7b-4424-96e0-c1dff1d739c7
  fi
  ls -ld $INSTALL_DIR/bin/ctags*
fi

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
BuildDependentPackage universal-ctags bin/ctags  # Note: See above comments

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir global

# --------------------------------------------------------------------------------
# Download, configure, build, and install:
# --------------------------------------------------------------------------------

# We need to specify the path to the specific universal-ctags to use (probably to avoid using the ctags in /usr/local or /bin or or or ...)
ctags_config_options="--with-universal-ctags=$INSTALL_DIR/bin/ctags"

#   For this error:
#
#      mv -f $depbase.Tpo $depbase.Po
#      find.c: In function ‘findassign’:
#      find.c:557:2: error: ‘for’ loop initial declarations are only allowed in C99 mode
#        for (int i = 0; opts[i] != NULL; i++) {
#        ^
#      find.c:557:2: note: use option -std=c99 or -std=gnu99 to compile your code
#      make[2]: *** [Makefile:501: find.o] Error 1
#      make[2]: Leaving directory '/home/brentg/build/CentOS.7.2.1511.x86_64/global/global-6.6.3/gtags-cscope'
#      make[1]: *** [Makefile:516: all-recursive] Error 1
#      make[1]: Leaving directory '/home/brentg/build/CentOS.7.2.1511.x86_64/global/global-6.6.3'
#      make: *** [Makefile:423: all] Error 2
#
#   See https://www.mail-archive.com/bug-global@gnu.org/msg01815.html
#   that indicated to use CC='gcc -std=gnu99'.  We cannot include
#   the single quotes which would be normal, so don't do this:
#      CC='gcc -std=gnu99'
#   as it won't make it to the ./configure line
#
gcc_config_options="CC=gcc -std=gnu99"

DownloadExtractBuildGnuPackage global "$ctags_config_options;$gcc_config_options"

exit 0
