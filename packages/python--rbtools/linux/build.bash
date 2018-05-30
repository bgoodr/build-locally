#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
# Define python utility functions:
. $PACKAGE_DIR/../../../support-files/python_util.bash

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
# rbtools depends upon setuptools. See https://www.reviewboard.org/docs/manual/1.7/users/tools/post-review/#installing-rbtools
BuildDependentPackage python--setuptools bin/easy_install

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python--rbtools

if [ "$CLEAN" = 1 ]
then
  find $INSTALL_DIR/lib/python*/site-packages -name 'RBTools*' | xargs -n5 rm -rf
  ##### No, we do not want to do this at all --> rm -f $INSTALL_DIR/RHEL.6.4.x86_64/bin
  
  # TODO: During the install, we see "Adding RBTools 0.6.2 to
  # easy-install.pth file". So how do we remove the egg from the .pth
  # file cleanly?
  
fi

# Avoid installing into the system defined Python (which cannot work
# unless the user is root which is not the intended use case):
echo "Ensuring that our locally built python is in the path prior to any system or other Python ..."
export PATH="$INSTALL_DIR/bin:$PATH"

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun easy_install -U RBTools

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
ValidateFileInInstallBinDir rbt
echo "Note: All installation tests passed."
exit 0
