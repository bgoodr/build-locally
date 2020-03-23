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

# Taking a hint from the script mentioned at
# https://askubuntu.com/a/947219/340383 (which is
# https://github.com/mtalexan/emacs-settings/blob/master/universal-ctags_install.sh),
# we move aside the ctags that the emacs builds produce so that we can
# build one here. We have to do this before the check for dependency
# in a bit.
if [ "$(which ctags)" = "$INSTALL_DIR/bin/ctags" ]
then
  echo "ctags exists in INSTALL_DIR/bin already"
  emacs_version_ctags=$(ctags --version | grep "Emacs")
  if [ -n "$emacs_version_ctags" ] ; then
    echo "Ctags version found in path is an Emacs version (too old for GNU Global which should use the more efficient universal-ctags). Moving it aside now."
    mv $INSTALL_DIR/bin/ctags $INSTALL_DIR/bin/ctags.moved.for.gnu.universal-ctags.b7f2c3b9-3f7b-4424-96e0-c1dff1d739c7
  fi
fi

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir universal-ctags

# --------------------------------------------------------------------------------
# Check out the source for universal-ctags into the build directory:
# --------------------------------------------------------------------------------
DownloadPackageFromGitRepo https://github.com/universal-ctags/ctags.git ctags

PrintRun cd ctags

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun ./autogen.sh
PrintRun ./configure --prefix="$INSTALL_DIR"
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

installedBinFile=$INSTALL_DIR/bin/ctags
if [ ! -f $installedBinFile ]
then
  echo "ERROR: universal-ctags did not properly install into $installedBinFile"
  exit 1
fi

# Verify what we built is a universal-ctags type of executable:
ctags_version=$(ctags --version >&1)
universal_ctags_version=$(echo "$ctags_version" | grep "Universal Ctags")
if [ -z "$universal_ctags_version" ] ; then
  echo "ERROR: Ctags version found in path is not the expected Universal Ctags version."
  exit 1
fi

echo "Note: Compilation and installation succeeded."
exit 0
