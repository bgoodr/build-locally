#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

# Define source patching utilities:
. $PACKAGE_DIR/../../../support-files/patch_util.bash

# --------------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------------
usage () {
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

  Override the INSTALL_DIR default, which is $INSTALL_DIR.

[ -clean ]

  Build from scratch.

EOF
}

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
    usage
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

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage texinfo bin/makeinfo
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage libtool bin/libtool
BuildDependentPackage gmp lib/libgmp.so
BuildDependentPackage libunistring lib/libunistring.so
BuildDependentPackage bdwgc lib/libgc.so

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir guile

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
version_subdir=guile
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$version_subdir"
fi
if [ ! -d "$version_subdir" ]
then
  # Using --depth 1 since this is a huge repo and we only need it for building:
  PrintRun git clone --depth 1 git://git.sv.gnu.org/guile.git
  if [ ! -d "$version_subdir" ]
  then
    echo "ERROR: Failed to checkout sources"
    exit 1
  fi
else
  echo "$version_subdir already exists."
fi
if [ -z "$version_subdir" ]
then
  echo "ASSERTION FAILED: version_subdir was not not initialized."
  exit 1
fi
if [ ! -d "$version_subdir" ]
then
  echo "ASSERTION FAILED: $version_subdir should exist as a directory by now but does not."
  exit 1
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun cd $version_subdir
if [ ! -f ./configure ]
then
  echo "Creating ./configure file ..."
  PrintRun ./autogen.sh
  if [ ! -f ./configure ]
  then
    echo "ERROR: Could not create ./configure file. autoconf must have failed."
    exit 1
  fi
fi

# libtool is not recognized properly by the guile configure script on
# RHEL.  From the ..../guile/config.log we see that the
# $INSTALL_DIR/include directory is not being put onto the compile
# line.
#
#   configure:45998: gcc -std=gnu99 -o conftest -g -O2   conftest.c  /home/joeblo/install/RHEL.6.6.x86_64/lib/libltdl.so -ldl -Wl,-rpath -Wl,/home/joeblo/install/RHEL.6.6.x86_64/lib >&5
#   conftest.c:569:18: error: ltdl.h: No such file or directory
#   conftest.c: In function 'main':
#   conftest.c:573: warning: implicit declaration of function 'lt_dlopenext'
#   configure:45998: $? = 1
#   configure: failed program was:
#   
# I tried to force it with:
#
#   --with-libltdl-prefix[=DIR]  search for libltdl in DIR/include and DIR/lib
#
# But that was ignored.  
#
# So try explicitly adding the include directory (I saved off my heavy
# debug code into ./configure.debug.sh for future reference; grep for
# "bgdbg" there; the bottom line is that there is a bug in libtool or
# in the m4 macros guile uses to find libtool).
#
export CFLAGS=-I$INSTALL_DIR/include #  <-- this makes its way into $ac_link variable in configure script
#
# And of course later on we have this error shown in config.log:
#
#   configure:46493: gcc -std=gnu99 -o conftest -I/home/brentg/install/RHEL.6.6.x86_64/include   conftest.c  -lltdl >&5
#   /usr/bin/ld: cannot find -lltdl
#   collect2: ld returned 1 exit status
#
# so hack it with LDFLAGS:
export LDFLAGS=-L$INSTALL_DIR/lib
PrintRun ./configure --prefix="$INSTALL_DIR" --with-libltdl-prefix="$INSTALL_DIR"
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
if [ ! -d "$INSTALL_DIR" ]
then
  echo "ERROR: $INSTALL_DIR does not exist. You must build it first."
  exit 1
fi
echo "Running tests on this package ..."

if [ ! -f "$INSTALL_DIR/bin/guile" ]
then
  echo "TEST FAILED: Failed to find application installed at $INSTALL_DIR/bin/guile"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
