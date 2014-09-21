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
BuildDependentPackage libtool bin/libtool
BuildDependentPackage pkg-config bin/pkg-config

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir freetype

# --------------------------------------------------------------------------------
# Check out the source for emacs into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=freetype2
DownloadPackageFromGitRepo git://git.sv.gnu.org/freetype/freetype2.git $packageSubDir

PrintRun cd $packageSubDir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."

# # We see:
# #
# #    cd builds/unix; /bin/sh ./configure  '--prefix=/home/brentg/install/RHEL.6.4.x86_64'
# #    /bin/sh: ./configure: No such file or directory
# #    builds/unix/detect.mk:86: recipe for target 'setup' failed
# #    
# # Hack around it via tips at https://bugs.freedesktop.org/show_bug.cgi?id=75652#c7 that state:
# #
# #   Adding ./autogen.sh into the command string (i.e. `make distclean
# #   && ./autogen.sh && ./configure...` works around the error. Perhaps
# #   the distclean target is removing a little too much?
# #
# PrintRun make distclean

# # Run autogen.sh (which does generate ./configure but does not then call ./configure like some other packages do):
# PrintRun ./autogen.sh

# PrintRun ./configure --prefix="$INSTALL_DIR"

# # --------------------------------------------------------------------------------
# # Build:
# # --------------------------------------------------------------------------------
# echo "Building ..."
# PrintRun make

# # --------------------------------------------------------------------------------
# # Install:
# # --------------------------------------------------------------------------------
# echo "Installing ..."
# PrintRun make install

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."

# Determine the expected version from the ./configure file:
expected_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < builds/unix/configure);
if [ -z "$expected_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected $PACKAGE version."
  exit 1
fi

expected_major_version=$(echo "$expected_version" | sed -n 's/^\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)$/\1/gp');

# Verify a file we should have installed:
pcfile="$INSTALL_DIR/lib/pkgconfig/freetype${expected_major_version}.pc"
if [ ! -f "$pcfile" ]
then
  echo "ERROR: Failed to install file: $pcfile"
  exit 1
fi
echo "Note: All installation tests passed. freetype version $expected_version was built and installed."
exit 0
