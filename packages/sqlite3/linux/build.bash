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
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir sqlite3

# --------------------------------------------------------------------------------
# Download and build tarball into the build directory:
# --------------------------------------------------------------------------------
# We are making use of the Debian build code that includes patches
# that might be useful. Otherwise, it is overkill to be dependent upon
# Debian here:
GetDebianSourcePackageTarBalls sqlite3 testing tarballs

debianFiles=""
ExtractDebianSourcePackageTarBall "$tarballs" '.*debian\.tar\.gz$' '^debian$' debianFiles

origFiles=""
ExtractDebianSourcePackageTarBall "$tarballs" '.*orig\.tar\.gz$' '^sqlite3-[0-9.]*$' origFiles

wwwFiles=""
ExtractDebianSourcePackageTarBall "$tarballs" '.*orig-www\.tar\.gz$' '^www$' wwwFiles

# --------------------------------------------------------------------------------
# Applying Debian patches:
# --------------------------------------------------------------------------------
ApplyDebianPatches "$debianFiles" "$origFiles"

# Note: The debian/README.Debian file has useful info.

# --------------------------------------------------------------------------------
# Configure:
# --------------------------------------------------------------------------------
echo "Configuring ..."

# Pull out the CFLAGS from debian/rules and export it to be seen by
# the build:
export CFLAGS=$(sed -n '/export CFLAGS/,/^$/{ s/^ *export *CFLAGS *+= *//g; s/\\$//g; p; }' < $HEAD_DIR/debian/rules | tr '\012' ' ')

# ApplyDebianPatches above will assert there is only one subdir inside origFiles:
subdir=$origFiles
PrintRun cd $HEAD_DIR/$subdir

# Typically, the configure file already exists when the tarball is
# extracted, but we will do the following anyhow in case that ever
# changes:
if [ ! -f ./configure ]
then
  echo "Creating ./configure file ..."
  PrintRun autoconf
  if [ ! -f ./configure ]
  then
    echo "ERROR: Could not create ./configure file. autoconf must have failed."
    exit 1
  fi
fi
echo "Running ./configure ..."
# Here we run similar steps as is in the debian/rules configure rule
# but elide options that are Debian specific (--disable-tcl is so as
# to allow us to build on RHEL; without that, the Makefile has rules
# that attempt to install files into a root-owned directory, and right
# now we do not need the Tcl extension):
PrintRun ./configure --prefix="$INSTALL_DIR" --enable-threadsafe --enable-load-extension --disable-tcl
# Not sure if we need to set this yet:  TCLLIBDIR=/usr/lib/tcltk/sqlite3

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
expectedVersion=$(echo "$origFiles" | sed 's%sqlite3-%%g')
executable=$INSTALL_DIR/bin/sqlite3
actualVersion=$($executable -version | awk '{printf("%s\n",$1);}')
if [ "$expectedVersion" = "$actualVersion" ]
then
  echo "Note: Verified expected version of executable $executable is $expectedVersion"
else
  echo "ERROR: Expected version of executable $executable is $expectedVersion but got $actualVersion instead."
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
