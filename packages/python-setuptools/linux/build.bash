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

# python is a dependency, obviously:
BuildDependentPackage python bin/python

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python-setuptools

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

# Output seen was: 
# ,----
# | Copying setuptools-1.1.6-py2.7.egg to /home/brentg/install/RHEL.6.2.x86_64/lib/python2.7/site-packages
# | Adding setuptools 1.1.6 to easy-install.pth file
# | Installing easy_install script to /home/brentg/install/RHEL.6.2.x86_64/bin
# | Installing easy_install-2.7 script to /home/brentg/install/RHEL.6.2.x86_64/bin
# `----

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
ValidateFileInInstallBinDir easy_install
echo "Note: All installation tests passed."
exit 0
