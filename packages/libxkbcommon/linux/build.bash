#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

cat <<EOF

The libxkbcommon package is not ready yet. We see this error on Debian:

configure: error: xkbcommon-x11 requires xcb-xkb >= 1.10 which was not found. You can disable X11 support with --disable-x11.

So have to figure out how to build xcb-xkb first.

EOF
exit 1

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

usage () {
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

  Override the INSTALL_DIR default, which is $INSTALL_DIR.

EOF
}

while [ $# -gt 0 ]
do
  if [ "$1" = "-builddir" ]
  then
    BUILDDIR="$2"
    shift
  elif [ "$1" = "-installdir" ]
  then
    INSTALLDIR="$2"
    shift
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
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
BuildDependentPackage libtool bin/libtool
BuildDependentPackage bison bin/bison
BuildDependentPackage xorg-macros share/aclocal/xorg-macros.m4
BuildDependentPackage xkeyboard-config share/pkgconfig/xkeyboard-config.pc

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir libxkbcommon

# --------------------------------------------------------------------------------
# Check out the source for libxkbcommon into the build directory:
# --------------------------------------------------------------------------------
DownloadPackageFromGitRepo https://github.com/xkbcommon/libxkbcommon.git libxkbcommon
PrintRun cd libxkbcommon


# HACK: We need x11-xcb which I don't want to have to build yet:
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:$INSTALL_DIR/share/pkgconfig

echo "Creating ./configure file ..."
# Run autogen.sh which also generates and runs ./configure:
PrintRun ./autogen.sh --prefix="$INSTALL_DIR"
if [ ! -f ./configure ]
then
  echo "ERROR: Could not create ./configure file. autoconf must have failed."
  exit 1
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

echo "ERROR: debugging"
exit 1

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
expectedVersion=$(echo "$origFiles" | sed 's%sqlite3-%%g')
executable=$INSTALL_DIR/bin/sqlite3
actualVersion=$($executable -version | awk '{printf("%s",$1);}')
if [ "$expectedVersion" = "$actualVersion" ]
then
  echo "Note: Verified expected version of executable $executable is $expectedVersion"
else
  echo "ERROR: Expected version of executable $executable is $expectedVersion but got $actualVersion instead."
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
