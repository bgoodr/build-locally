#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; BASE_DIR=`dirname $dollar0`

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as builddep:
. $BASE_DIR/../../subfiles/build_platform_util.sh

usage () {
  cat <<EOF
USAGE: $0 [ -builddir BUILD_DIR ] [ -installdir INSTALL_DIR ]

Options are:

-builddir BUILD_DIR

  Override the BUILD_DIR default, which is $BUILD_DIR.

-installdir INSTALL_DIR

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
# Create build directory structure:
# --------------------------------------------------------------------------------
echo "Creating build directory structure ..."

# --------------------------------------------------------------------------------
# Download the source for example-tool into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."


# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."


# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."


