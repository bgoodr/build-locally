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
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
# BuildDependentPackage pkg-config bin/pkg-config

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir mlocate

# --------------------------------------------------------------------------------
# Check out the source:
# --------------------------------------------------------------------------------
# DownloadPackageFromGitRepo https://pagure.io/mlocate.git mlocate
DownloadPackageFromGitRepo https://salsa.debian.org/tfheen/mlocate mlocate

# --------------------------------------------------------------------------------
# Configure:
# --------------------------------------------------------------------------------
PrintRun cd mlocate
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
locateExe="$INSTALL_DIR/bin/locate"
if [ ! -f "$locateExe" ]
then
  echo "ERROR: Could not find expected executable at: $locateExe"
  exit 1
fi

# Determine the expected version from the ./configure file:
expected_locate_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_locate_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected locate version."
  exit 1
fi

# Determine the actual version we built:
actual_locate_version=$($locateExe --version | sed -n 's/^mlocate \([0-9.a-z-]*\)$/\1/gp')

# Now compare:
if [ "$expected_locate_version" != "$actual_locate_version" ]
then
  echo "ERROR: Failed to build expected locate version: $expected_locate_version"
  echo "                         actual locate version: $actual_locate_version"
  exit 1
fi
echo "Note: All installation tests passed. TheExecutable version $actual_locate_version was built and installed."
exit 0
