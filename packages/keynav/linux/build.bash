#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

# Define source patching utilities:
. $PACKAGE_DIR/../../../support-files/patch_util.bash

# --------------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------------
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
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir keynav

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
version_subdir=keynav
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$version_subdir"
fi
if [ ! -d "$version_subdir" ]
then
  PrintRun git clone https://github.com/jordansissel/keynav
  if [ ! -d "$version_subdir" ]
  then
    echo "ERROR: Failed to checkout sources"
    exit 1
  fi
else
  echo "$version_subdir already exists."
fi
if [ -z "$version_subdir" ]
then
  echo "ASSERTION FAILED: version_subdir was not not initialized."
  exit 1
fi
if [ ! -d "$version_subdir" ]
then
  echo "ASSERTION FAILED: $version_subdir should exist as a directory by now but does not."
  exit 1
fi

function install_packages_ubuntu {
  # Ideally, we would get libxdo-dev from xdotool that is built in
  # ../../xdotool/linux/build.bash but we are cheating for now as this
  # is used only on Ubuntu-based Linux:

  # Only install the packages that are not yet installed:
  #
  #   To avoid interactive prompting for password via sudo unless it
  #   is absolutely necessary, because it is a speedbump for repeated
  #   compilation such as for doing development work on a copy in the
  #   BUILD_DIR.
  #
  local packages_to_install=""
  for package in libcairo2-dev libxinerama-dev libxdo-dev
  do
    is_installed=$(apt-cache policy "$package" | grep Installed: | grep -c -v '(none)')
    test "$is_installed" = 0 && {
      packages_to_install="$packages_to_install $package"
    }
  done

  test -n "$packages_to_install" && {
    # Launch an xterm for the prompt for the password:
    PrintRun xterm -e sudo apt-get install $packages_to_install
  }
}

if lsb_release -i | grep -q Ubuntu
then
  install_packages_ubuntu
elif lsb_release -i | grep -q RedHatEnterprise
then
  echo "ASSERTION FAILED: RHEL building is not supported at this time"
  exit 1
else
  echo "ASSERTION FAILED: Unknown release: $(lsb_release -i)"
  exit 1
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun cd $version_subdir
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make PREFIX=$INSTALL_DIR install

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

if [ ! -f "$INSTALL_DIR/bin/keynav" ]
then
  echo "TEST FAILED: Failed to find application installed at $INSTALL_DIR/bin/keynav"
  exit 1
fi

# There is nothing that can be easily tested here. So this is a lame section.
echo "Note: All installation tests passed."
exit 0
