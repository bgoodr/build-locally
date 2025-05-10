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
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' cvs /usr/bin/cvs
BuildDependentPackage texinfo bin/makeinfo
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir idutils

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
version_subdir=idutils
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$version_subdir"
fi
if [ ! -d "$version_subdir" ]
then
  PrintRun cvs -d:pserver:anonymous@cvs.savannah.gnu.org:/sources/idutils co idutils
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

# --------------------------------------------------------------------------------
# Patch:
# --------------------------------------------------------------------------------
echo "Patching ..."
PrintRun cd $version_subdir
echo "version_subdir==\"${version_subdir}\""
# Apply a patch to build logic files to make it just work!:
# Reference http://mail-archives.apache.org/mod_mbox/qpid-dev/200812.mbox/<87fxko4gfy.fsf@rho.meyering.net>
ApplyPatch $PACKAGE_DIR/hack_old_AC_USE_SYSTEM_EXTENSIONS_def_patch.patch
# Apply a patch to allow skipping of certain files/directories in
# the build environment.  TODO: This should not be here. It, or an
# equivalent change, should be applied upstream to the idutils
# source:
ApplyPatch $PACKAGE_DIR/exclude_files.patch
# Apply a patch so that the Info manual can be generated properly:
ApplyPatch $PACKAGE_DIR/idutils_texinfo.patch

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
if [ ! -f ./configure ]
then
  echo "Creating ./configure file ..."
  PrintRun ./autogen.sh
  if [ ! -f ./configure ]
  then
    echo "ERROR: Could not create ./configure file. autoconf must have failed."
    exit 1
  fi
fi
PrintRun ./configure --enable-maintainer-mode --prefix="$INSTALL_DIR"
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

# Note: The install-info called from the above "make install" step
# will update the $INSTALL_DIR/share/info/dir file if it already
# exists, and will splice in the info for this package into that dir
# file.

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
tmpdir="/tmp/tmptest"
set -x -e
rm -rf $tmpdir
mkdir -p $tmpdir
populate () {
  mkdir -p $tmpdir/$1/dir1/CVS
  mkdir -p $tmpdir/$1/dir2
  echo "void dir2foo();" >$tmpdir/$1/dir2/dir2file.c
  echo "void dir1foo();" >$tmpdir/$1/dir1/dir1file.c
  echo "void cvsfunc();" >$tmpdir/$1/dir1/CVS/cvsfile.c
}
populate local
populate remote
ln -s $tmpdir/remote/dir2 $tmpdir/local/dir1/some_link
find $tmpdir | xargs -n1 ls -ld
PATH="$INSTALL_DIR/bin:$PATH"; export PATH; echo PATH $PATH
set +x +e

cd $tmpdir/local;
MKID_AVOID_NAME=some_link mkid
cd $tmpdir/local/dir1/
dir1foo_result=`lid dir1foo | grep 'dir1foo *dir1file.c'`
if [ -z "$dir1foo_result" ]
then
  echo "TEST FAILED: Did not see expected result for dir1foo"
  exit 1
fi
dir2foo_result=`lid dir2foo | grep some_link/`
if [ -n "$dir2foo_result" ]
then
  echo "TEST FAILED: Got an some_link in the results: $dir2foo_result"
  exit 1
fi
cvsfunc_result=`lid cvsfunc`
if [ -n "$cvsfunc_result" ]
then
  echo "TEST FAILED: Got cvsfunc result: $cvsfunc_result"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
