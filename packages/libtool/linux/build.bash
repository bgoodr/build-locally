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
# No known dependent packages.

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir libtool

# --------------------------------------------------------------------------------
# Download the tarball into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
tarbasefile=$(wget http://ftp.gnu.org/gnu/libtool/ -O - | \
  grep 'href=' | \
  grep '\.tar\.gz"' | \
  tr '"' '\012' | \
  grep '^libtool' | \
  sed 's%-%-.%g' | \
  sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | \
  sed 's%-\.%-%g' | \
  tail -1)
if [ -z "$tarbasefile" ]
then
  echo "ASSERTION FAILED: Could not automatically determine download file from http://ftp.gnu.org/gnu/libtool/"
  exit 1
fi
if [ ! -f $tarbasefile ]
then
  wget http://ftp.gnu.org/gnu/libtool/$tarbasefile
  if [ ! -f $tarbasefile ]
  then
    echo "ERROR: Could not retrieve $tarbasefile"
    exit 1
  fi
fi
subdir=`tar tf $tarbasefile 2>/dev/null | sed -n '1{s%/$%%gp; q}'`
if [ ! -d "$subdir" ]
then
  tar zxvf $tarbasefile
  if [ ! -d "$subdir" ]
  then
    echo "ERROR: Could not extract `pwd`/$tarbasefile"
    exit 1
  fi
fi

PrintRun cd $HEAD_DIR/$subdir

# --------------------------------------------------------------------------------
# Configuring:
# --------------------------------------------------------------------------------
echo "Configuring ..."
# The distclean command will fail if there the top-level Makefile has not yet been generated:
if [ -f Makefile ]
then
  PrintRun make distclean
fi
if [ ! -f configure ]
then
  echo "ASSERTION FAILED: configure file not found"
  exit 1
fi
PrintRun ./configure --prefix="$INSTALL_DIR"

# --------------------------------------------------------------------------------
# Building:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun make

# --------------------------------------------------------------------------------
# Installing:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install
exit 0
