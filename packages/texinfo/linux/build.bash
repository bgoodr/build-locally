#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

usage ()
{
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

  Override the INSTALL_DIR default, which is $INSTALL_DIR.

EOF
}

CLEAN=0
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
BuildDependentPackage libtool bin/libtool

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir texinfo

if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf $HEAD_DIR
  PrintRun mkdir -p $HEAD_DIR
fi


# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
# Determine the most recent tarball file:
tarbasefile=$(wget http://ftp.gnu.org/gnu/texinfo/ -O - \
  | grep 'href=' \
  | grep '\.tar\.gz"' \
  | tr '"' '\012' \
  | grep '^texinfo' \
  | sed 's%-%-.%g' \
  | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n \
  | sed 's%-\.%-%g' \
  | tail -1)
if [ ! -f "$tarbasefile" ]
then
  PrintRun wget http://ftp.gnu.org/gnu/texinfo/$tarbasefile
  if [ ! -f "$tarbasefile" ]
  then
    echo "ERROR: Could not retrieve $tarbasefile"
    exit 1
  fi
fi

# --------------------------------------------------------------------------------
# Extracting:
# --------------------------------------------------------------------------------
echo "Extracting ..."
subdir=`tar tf $tarbasefile 2>/dev/null \
  | sed -n '1{s%/$%%gp; q}'`
if [ ! -d "$subdir" ]
then
  PrintRun tar zxvf $tarbasefile
  if [ ! -d "$subdir" ]
  then
    echo "ERROR: Could not extract `pwd`/$tarbasefile"
    exit 1
  fi
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building and installing ..."
PrintRun cd $HEAD_DIR/$subdir
if [ ! -f configure ]
then
  echo "ASSERTION FAILED: configure file not found"
  exit 1
fi
PrintRun ./configure --prefix="$INSTALL_DIR"
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install




