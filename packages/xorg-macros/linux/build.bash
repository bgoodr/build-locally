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
BuildDependentPackage autoconf bin/autoconf

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir xorg-macros

# --------------------------------------------------------------------------------
# Check out the source for xorg-macros into the build directory:
# --------------------------------------------------------------------------------
DownloadPackageFromGitRepo git://anongit.freedesktop.org/xorg/util/macros macros
PrintRun cd macros

echo "Creating ./configure file ..."
PrintRun rm -f ./configure

# None of these worked:
#PrintRun ./autogen.sh
#PrintRun autoconf
#PrintRun autogen.sh --force

# Found http://adesklets.sourceforge.net/forum_archive/topics/404.html#2308 which gave me a few tips.
PrintRun aclocal
# PrintRun autoheader      gave this error :   autoheader: error: AC_CONFIG_HEADERS not found in configure.ac
PrintRun automake --add-missing
PrintRun autoconf

if [ ! -f ./configure ]
then
  echo "ERROR: Could not create ./configure file. autogen.sh must have failed."
  exit 1
fi

echo "Running ./configure ..."
PrintRun ./configure --prefix="$INSTALL_DIR"

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun make
# Gives nothing to be done for all? Huh?

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
pcfile="$INSTALL_DIR/share/pkgconfig/xorg-macros.pc"
if [ ! -f "$pcfile" ]
then
  echo "ERROR: Could not find expected pkgconfig file at: $pcfile"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
