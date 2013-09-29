#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
. $PACKAGE_DIR/../../../support-files/python_util.bash

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

# python-setuptools is a dependency because http://www.pip-installer.org/en/latest/installing.html#id2 says so:
BuildDependentPackage python-setuptools bin/easy_install

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python-pip

# --------------------------------------------------------------------------------
# Download the installer into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
# Securely download get-pip.py
# as instructed by http://www.pip-installer.org/en/latest/installing.html#install-or-upgrade-pip
# home page http://www.pip-installer.org/en/latest/
PythonDownloadAndRunBootstrapScript "https://raw.github.com/pypa/pip/master/contrib/get-pip.py"

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun python $bootstrapScript 

# Output seen was: 
# ,----
# |     Installing pip script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing pip-2.7 script to /home/brentg/install/RHEL.6.2.x86_64/bin
# `----

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
ValidateFileInInstallBinDir pip
echo "Note: All installation tests passed."
exit 0
