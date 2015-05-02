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
BuildDependentPackage texinfo bin/makeinfo
BuildDependentPackage pkg-config bin/pkg-config
BuildDependentPackage libffi lib/pkgconfig/libffi.pc

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir glib

# --------------------------------------------------------------------------------
# Check out the source into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=glib
DownloadPackageFromGitRepo git://git.gnome.org/$packageSubDir $packageSubDir

PrintRun cd $packageSubDir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."
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

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."

GLIB_MAJOR_VERSION=$(sed -n 's/^GLIB_MAJOR_VERSION *= *\([0-9]*\) *$/\1/gp' Makefile)

glibHeader="$INSTALL_DIR/lib/glib-${GLIB_MAJOR_VERSION}.0/include/glibconfig.h"
if [ ! -f "$glibHeader" ]
then
  echo "ERROR: Could not find expected file at: $glibHeader"
  exit 1
fi

GLIB_HEADER_MAJOR_VERSION=$(sed -n 's/^#define GLIB_MAJOR_VERSION \([0-9]*\) *$/\1/gp' $glibHeader)
GLIB_HEADER_MINOR_VERSION=$(sed -n 's/^#define GLIB_MINOR_VERSION \([0-9]*\) *$/\1/gp' $glibHeader)
GLIB_HEADER_MICRO_VERSION=$(sed -n 's/^#define GLIB_MICRO_VERSION \([0-9]*\) *$/\1/gp' $glibHeader)

# Determine the expected version from the ./configure file:
expected_glib_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_glib_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected $PACKAGE version."
  exit 1
fi

# Determine the actual version we built:
actual_glib_version="$GLIB_HEADER_MAJOR_VERSION.$GLIB_HEADER_MINOR_VERSION.$GLIB_HEADER_MICRO_VERSION"

# Now compare:
if [ "$expected_glib_version" != "$actual_glib_version" ]
then
  echo "ERROR: Failed to build expected glib version: $expected_glib_version"
  echo "                         actual glib version: $actual_glib_version"
  exit 1
fi
echo "Note: All installation tests passed. glib version $actual_glib_version was built and installed."
exit 0
