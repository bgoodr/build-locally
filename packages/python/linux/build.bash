#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

# --------------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------------
MAJOR_VERSION=2
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

[ -majorversion MAJOR_VERSION ]

  Build the version of Python whose major version is given by
  MAJOR_VERSION. MAJOR_VERSION defaults to "$MAJOR_VERSION"

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
  elif [ "$1" = "-majorversion" ]
  then
    MAJOR_VERSION="$2"
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
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python

# --------------------------------------------------------------------------------
# Get dependent packages:
# --------------------------------------------------------------------------------
VerifyOperatingSystemPackageContainingFile Debian libbz2-dev /usr/include/bzlib.h

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
version=$(wget -O - "http://www.python.org/download/releases/" \
  | sed -n 's%^.*href="\([0-9.]*\)".*$%\1%gp' \
  | sort -t. -k1,1n -k2,2n -k3.3n \
  | grep "^${MAJOR_VERSION}\." \
  | tail -1)
if [ -z "$version" ]
then
  echo "ERROR: Cannot download major version $MAJOR_VERSION of Python"
  exit 1
fi
echo "Note: Found latest major version $MAJOR_VERSION version of $version"
version_subdir="Python-${version}"
tarballBase="$version_subdir.tgz"
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$version_subdir"
fi
if [ ! -d "$version_subdir" ]
then
  tarballURL="http://www.python.org/ftp/python/${version}/$tarballBase"
  if [ ! -f $tarballBase ]
  then
    PrintRun wget -O $tarballBase $tarballURL
    if [ ! -f $tarballBase ]
    then
      echo "ERROR: Download from $tarballURL failed as $tarballBase does not exist"
      exit 1
    fi
  fi
  PrintRun tar zxvf $tarballBase
  if [ ! -d "$version_subdir" ]
  then
    echo "ERROR: Failed to extract tarball at $tarballBase"
    exit 1
  fi
else
  echo "Note: $version_subdir already exists. Continuing..."
fi
if [ -z "$version_subdir" ]
then
  echo "ASSERTION FAILED: version_subdir was not initialized."
  exit 1
fi
if [ ! -d "$version_subdir" ]
then
  echo "ASSERTION FAILED: $version_subdir should exist as a directory by now but does not."
  exit 1
fi

# --------------------------------------------------------------------------------
# Documentation:
# --------------------------------------------------------------------------------
# Docs should be installed locally to avoid having to browse to a web
# page on some remote web server each and every time just to lookup
# syntax for Python syntax:
InstallDocs () {
  local docType="$1"
  local savedir="$(pwd)"
  local docBase="python-${version}-docs-${docType}.tar.bz2"
  local docTarBallPath="$savedir/$docBase"
  local docDir="$INSTALL_DIR/share/doc/$version_subdir"
  local docInstallDir="$docDir/python-${version}-docs-$docType"
  echo "Note: Installing $docType docs into $docDir ..."
  if [ ! -f "$docBase" ]
  then
    local docURL="http://docs.python.org/$MAJOR_VERSION/archives/$docBase"
    PrintRun wget -O "$docBase" "$docURL"
    if [ ! -f "$docBase" ]
    then
      echo "ERROR: Failed to download docs from $docURL"
      exit 1
    fi
  fi
  if [ ! -d "$docInstallDir" ]
  then
    PrintRun mkdir -p "$docDir"
    PrintRun cd "$docDir"
    PrintRun tar xvf "$docTarBallPath"
    PrintRun cd "$savedir"
  else
    echo "Note: $docInstallDir already exists."
  fi
}

InstallDocs text
InstallDocs html

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun cd "$version_subdir"
if [ ! -f ./configure ]
then
  echo "ASSERTION FAILED: we should have seen a ./configure file inside $(pwd) by now."
  exit 1
fi
echo "Running ./configure ..."
PrintRun ./configure --prefix="$INSTALL_DIR"
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
export PATH="$INSTALL_DIR/bin:$PATH"
runtime_version=$(python --version 2>&1 | sed 's%^Python %%g')
if [ "$runtime_version" != "$version" ]
then
  echo "ERROR: Build must have failed because the version under $INSTALL_DIR/bin was not found. Got $runtime_version instead"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
