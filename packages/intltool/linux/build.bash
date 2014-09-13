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
BuildDependentPerlModule perl--xml-parser XML::Parser

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir intltool

# --------------------------------------------------------------------------------
# Check out the source for intltool into the build directory:
# --------------------------------------------------------------------------------
version=0.50.2
tarball=intltool-${version}.tar.gz
subdir=intltool-${version}
if [ ! -d ${subdir} ]
then
  url=https://launchpad.net/intltool/trunk/${version}/+download/${tarfile}
  PrintRun wget $url
  PrintRun tar zxvf ${tarfile}
  if [ ! -d $subdir ]
  then
    echo "ERROR: Failed to extract $tarball since $(pwd)/$subdir does not exist."
    exit 1
  fi
fi
PrintRun cd $subdir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."
# There is no autogen.sh here and the configure file should already
# exist. I could not find a way to get the source without using bzr
# which I don't want to have to require users install as I would have
# to build that tool too. (maybe someday we do build it).
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
intltoolizeExe="$INSTALL_DIR/bin/intltoolize"
if [ ! -f "$intltoolizeExe" ]
then
  echo "ERROR: Could not find expected intltoolize executable at: $intltoolizeExe"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
