#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

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

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir pkg-config

# --------------------------------------------------------------------------------
# Check out the source for pkg-config into the build directory:
# --------------------------------------------------------------------------------
DownloadPackageFromGitRepo git://anongit.freedesktop.org/pkg-config pkg-config
PrintRun cd pkg-config

# echo "Creating ./configure file ..."
# PrintRun rm -f ./configure
# PrintRun ./autogen.sh --prefix="$INSTALL_DIR" --with-internal-glib 
# if [ ! -f ./configure ]
# then
#   echo "ERROR: Could not create ./configure file. autoconf must have failed."
#   exit 1
# fi

# --------------------------------------------------------------------------------
# Hack around this error:
#   cd /home/brentg/install/Debian.7.x86_64/bin && ln pkg-config x86_64-unknown-linux-gnu-pkg-config
#   ln: failed to create hard link `x86_64-unknown-linux-gnu-pkg-config': File exists
# --------------------------------------------------------------------------------
PrintRun make uninstall-hook

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

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
pkgM4=$INSTALL_DIR/share/aclocal/pkg.m4
if [ ! -f "$pkgM4" ]
then
  echo "ERROR: Could not locate pkg.m4 file at $pkgM4"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
