#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

usage () {
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

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
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage perl bin/perl

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir perl--cpanm

# --------------------------------------------------------------------------------
# Install cpanm:
# --------------------------------------------------------------------------------
# http://search.cpan.org/dist/App-cpanminus/lib/App/cpanminus.pm#permalink
#PrintRun sh -c 'curl -L http://cpanmin.us | perl - App::cpanminus'
set -x
set -e
curl -L http://cpanmin.us | perl - App::cpanminus
set +x
set +e

# --------------------------------------------------------------------------------
# Testing the installation:
# --------------------------------------------------------------------------------
echo "Testing the installation ..."
actualCpanmExe=$(which cpanm)
if [ "$actualCpanmExe" != "$INSTALL_DIR/bin/cpanm" ]
then
  echo "ERROR: cpanm should be at"
  echo "         $INSTALL_DIR/bin/cpanm"
  echo "       but we instead got "
  echo "         $actualCpanmExe"
  exit 1
fi

echo "Note: All installation tests passed."
exit 0
