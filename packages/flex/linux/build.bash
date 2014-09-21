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
BuildDependentPackage pkg-config bin/pkg-config
BuildDependentPackage gettext bin/gettext
BuildDependentPackage help2man bin/help2man

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir flex

# --------------------------------------------------------------------------------
# Check out the source:
# --------------------------------------------------------------------------------
# http://sourceforge.net/p/forge/documentation/Git/#anonymous-access-read-only
# git://git.code.sf.net/p/PROJECTNAME/MOUNTPOINT/
# http://git.code.sf.net/p/PROJECTNAME/MOUNTPOINT/
DownloadPackageFromGitRepo git://git.code.sf.net/p/flex/flex/ flex

PrintRun cd flex

# Extricate some flex executables that do not return valid information
# to the ./configure script:
i=0
while true
do
  curflex=$(which flex)
  if [ -n "$curflex" ]
  then
    if ! flex --version 2>&1 | grep '^flex [0-9.a-z-]*$'
    then
      echo "Warning: Bogus flex executable at: $curflex"
      echo "Remove it from the PATH and retrying"
      curflexdir=$(dirname $curflex)
      PATH=$(echo $PATH | tr : '\012' | grep -v "^$curflexdir\$" | tr '\012' :)
      if [ $i -gt 5 ]
      then
        echo "ERROR: ASSERTION FAILED: Giving up trying to extricate bad flex executable from PATH"
        exit 1
      fi
    else
      break
    fi
  fi
done
  
# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."
# Run autogen.sh (which does generate ./configure but does not then call ./configure like some other packages do):
PrintRun ./autogen.sh

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
flexExe="$INSTALL_DIR/bin/flex"
if [ ! -f "$flexExe" ]
then
  echo "ERROR: Could not find expected executable at: $flexExe"
  exit 1
fi

# Determine the expected version from the ./configure file:
expected_flex_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_flex_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected flex version."
  exit 1
fi

# Determine the actual version we built:
actual_flex_version=$($flexExe --version | sed -n 's/^flex \([0-9.a-z-]*\)$/\1/gp')

# Now compare:
if [ "$expected_flex_version" != "$actual_flex_version" ]
then
  echo "ERROR: Failed to build expected flex version: $expected_flex_version"
  echo "                         actual flex version: $actual_flex_version"
  exit 1
fi
echo "Note: All installation tests passed. TheExecutable version $actual_flex_version was built and installed."
exit 0
