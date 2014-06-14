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
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir xdotool

# --------------------------------------------------------------------------------
# Check out the source for xdotool into the build directory:
# --------------------------------------------------------------------------------
echo "Checking out from git repo ..."
gitrepo=git://github.com/jordansissel/xdotool.git
if [ ! -d xdotool ]
then
  PrintRun git clone --depth 1 $gitrepo
  if [ ! -d xdotool ]
  then
    echo "ERROR: Failed to checkout xdotool sources from git repo at $gitrepo"
    exit 1
  fi
  PrintRun cd xdotool
else
  PrintRun cd xdotool
  PrintRun git pull
fi

if [ ! -f /usr/include/X11/extensions/XTest.h ]
then
  echo "ASSERTION FAILED: /usr/include/X11/extensions/XTest.h does not exist"
  echo "                  TODO: We need to build libxtst debian source package and make it a dependency. This file did exist on RHEL6.4 machines and on Debian machines on Sun Mar 16 20:25:26 PDT 2014."
  echo "                        See 'libxtst' git branch."
  exit 1
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
makefile=Makefile
# The -R sets the RPATH to avoid having inject wrapper scripts in the $INSTALL_DIR/bin directory:
sed -i.orig \
  -e 's%^\([ \t]*\)ldconfig \\$%\1echo NOTE: The '"$0"' script has disabled running ldconfig as that requires root. \\%g' \
  -e 's%\(-L\. \)%-Wl,-R'"$INSTALL_DIR/lib"' \1%g' \
  $makefile
diff ${makefile}.orig $makefile 

PREFIX="$INSTALL_DIR"; export PREFIX
PrintRun make
PrintRun make showman

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

installedBinFile=$INSTALL_DIR/bin/xdotool
if [ ! -f $installedBinFile ]
then
  echo "ERROR: xdotool did not properly install into $installedBinFile"
  exit 1
fi

ldd $installedBinFile | grep "$INSTALL_DIR"'/lib/libxdo\.so' >/dev/null || {
  echo "ERROR: Could not inject the lib directory into the RPATH of $installedBinFile"
  exit 1
}

echo "Note: Compilation and installation succeeded."
exit 0
