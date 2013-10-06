#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
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
# setuptools depends upon python:
BuildDependentPackage python bin/python

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python--setuptools

if [ "$CLEAN" = 1 ]
then
  # This is in effect an uninstall as given by https://pypi.python.org/pypi/setuptools/1.1.6#uninstalling
  find $INSTALL_DIR/lib/python*/site-packages -name 'setuptools*' -o -name 'distribute*' | xargs -n5 rm -rf
  find $INSTALL_DIR/bin -name 'easy_install*' | xargs -n5 rm -f
fi

# --------------------------------------------------------------------------------
# Download the installer into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
# Securely download ez_setup.py.
# home page https://pypi.python.org/pypi/setuptools
#           https://pypi.python.org/pypi/setuptools/1.1.6#id119
#           https://pypi.python.org/pypi/setuptools/1.1.6#unix-based-systems-including-mac-os-x
# Download ez_setup.py and run it using the target Python version. The script will download the appropriate version and install it for you:
# URL to download is https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py
PythonDownloadAndRunBootstrapScript "https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py"

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun python $bootstrapScript 

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
ValidateFileInInstallBinDir easy_install
echo "Note: All installation tests passed."
exit 0
