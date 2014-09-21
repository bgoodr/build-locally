#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
# Define perl utility functions:
. $PACKAGE_DIR/../../../support-files/perl_util.bash

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
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
BuildDependentPackage texinfo bin/makeinfo
BuildDependentPackage pkg-config bin/pkg-config
BuildDependentPackage flex bin/flex
BuildDependentPackage glib bin/gobject-query

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir gobject-introspection

# --------------------------------------------------------------------------------
# Check out the source for emacs into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=gobject-introspection
# https://wiki.gnome.org/action/show/Projects/GObjectIntrospection#Getting_the_code
DownloadPackageFromGitRepo git://git.gnome.org/$packageSubDir $packageSubDir

PrintRun cd $packageSubDir

if false
then

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."

# Run configure by way of autogen.sh
PrintRun ./autogen.sh --prefix="$INSTALL_DIR"

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

  
fi


# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."

gircompilerExe="$INSTALL_DIR/bin/g-ir-compiler"
if [ ! -f "$gircompilerExe" ]
then
  echo "ERROR: Could not find expected executable at: $gircompilerExe"
  exit 1
fi

# Determine the expected version from the ./configure file:
expected_package_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_package_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected gobject-introspection version."
  exit 1
fi

# There does not seem to be any version info embedded in the headers so we have to the best we can to test:
major_version=$(echo "${expected_package_version}" | sed 's/^\([0-9]\)\..*$/\1/g')
expected_header="$INSTALL_DIR/include/gobject-introspection-${major_version}.0/giversionmacros.h"

if [ ! -f "$expected_header" ]
then
  echo "ERROR: Failed to build expected header: $expected_header"
  exit 1
fi
echo "Note: All installation tests passed. gobject-introspection version $expected_package_version was built and installed."
exit 0
