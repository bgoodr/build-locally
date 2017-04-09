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

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir zlib

# --------------------------------------------------------------------------------
# Get dependent packages:
# --------------------------------------------------------------------------------
# No known dependent packages.

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
downloadURL=http://zlib.net
tarballBase=$(curl -L $downloadURL 2>/dev/null | sed -n 's%^.*href="\(zlib-.*\.tar\.gz\)".*$%\1%gip' )
echo "tarballBase==\"${tarballBase}\""
if [ -z "$tarballBase" ]
then
  echo "ERROR: Could not determine downloadable tarball from $downloadURL"
  exit 1
fi
tarballURL=$downloadURL/$tarballBase
versionSubdir=${tarballBase/.tar.*z/}
echo "versionSubdir==\"${versionSubdir}\""
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$versionSubdir"
fi
if [ ! -d "$versionSubdir" ]
then
  if [ ! -f $tarballBase ]
  then
    PrintRun curl -L -o $tarballBase $tarballURL
    if [ ! -f $tarballBase ]
    then
      echo "ERROR: Failed to download"
      exit 1
    fi
    if [ ! -f $tarballBase ]
    then
      echo "ERROR: Download from $tarballURL failed as $tarballBase does not exist"
      exit 1
    fi
  fi
  PrintRun tar xvf $tarballBase
  if [ ! -d "$versionSubdir" ]
  then
    echo "ERROR: Failed to extract tarball at $tarballBase"
    exit 1
  fi
else
  echo "Note: $versionSubdir already exists. Continuing..."
fi
if [ -z "$versionSubdir" ]
then
  echo "ASSERTION FAILED: versionSubdir was not initialized."
  exit 1
fi
if [ ! -d "$versionSubdir" ]
then
  echo "ASSERTION FAILED: $versionSubdir should exist as a directory by now but does not."
  exit 1
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Configuring ..."
PrintRun cd "$versionSubdir"
if [ ! -f ./configure ]
then
  echo "ASSERTION FAILED: we should have seen a ./configure file inside $(pwd) by now."
  exit 1
fi
echo "Running ./configure ..."
# The zlib configure script is not really a standard autoconf-based script: No --prefix option:
export prefix="$INSTALL_DIR" 
PrintRun ./configure 

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
# Test:
# --------------------------------------------------------------------------------
echo "Testing ..."
PrintRun make test

if [ ! -f $INSTALL_DIR/include/zlib.h ]
then
  echo "ERROR: Header $INSTALL_DIR/include/zlib.h was not installed correctly"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
