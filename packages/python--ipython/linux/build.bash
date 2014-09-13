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
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
# jira-python depends upon pip. See http://jira-python.readthedocs.org/en/latest/#installation
BuildDependentPackage python--pip bin/pip

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python--ipython

# --------------------------------------------------------------------------------
# Downloading and installing:
# --------------------------------------------------------------------------------
echo "Downloading and installing ..."
# http://ipython.org/ipython-doc/stable/install/install.html#installation-from-source
# From http://ipython.org/ipython-doc/stable/install/install.html "...If
# you use pip to install these packages, it will always compile from
# source, which may not succeed."
# TODO: Figure out what the difference is between 'pip install ipython[all]' and just 'pip install ipython'
PrintRun pip install ipython

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
ValidateFileInInstallBinDir ipython
echo "Note: All installation tests passed."
exit 0
