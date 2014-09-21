#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
# Define perl utility functions:
. $PACKAGE_DIR/../../../support-files/perl_util.bash

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
BuildDependentPackage pkg-config bin/pkg-config

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir libpng

# --------------------------------------------------------------------------------
# Check out the source for emacs into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=code
# http://libpng.sourceforge.net/index.html
DownloadPackageFromGitRepo git://git.code.sf.net/p/libpng/code $packageSubDir

PrintRun cd $packageSubDir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."
# Run autogen.sh (which does generate ./configure but does not then call ./configure like some other packages do):
# But libpng is disallows running autogen.sh idempotently, which produces this error:
#
#    ERROR: running autoreconf on an initialized sytem
#      This is not necessary; it is only necessary to remake the
#      autotools generated files if Makefile.am or configure.ac
#      change and make does the right thing with:
#    
#         ./configure --enable-maintainer-mode.
#    
#      You can run autoreconf yourself if you don't like maintainer
#      mode and you can also just run autoreconf -f -i to initialize
#      everything in the first place; this script is only for
#      compatibility with prior releases.
if [ ! -f ./configure ]
then
  PrintRun ./autogen.sh
fi

PrintRun ./configure --prefix="$INSTALL_DIR"

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

# Determine the expected version from the ./configure file:
expected_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected $PACKAGE version."
  exit 1
fi

expected_major_version=$(echo "$expected_version" | sed -n 's/^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$/\1/gp');
expected_minor_version=$(echo "$expected_version" | sed -n 's/^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$/\2/gp');

# Verify a file we should have installed:
pcfile="$INSTALL_DIR/lib/pkgconfig/libpng${expected_major_version}${expected_minor_version}.pc"
if [ ! -f "$pcfile" ]
then
  echo "ERROR: Failed to install file: $pcfile"
  exit 1
fi
echo "Note: All installation tests passed. libpng version $expected_version was built and installed."
exit 0
