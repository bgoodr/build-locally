#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

# --------------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------------
MAJOR_VERSION=4
CONFIGURE_OPTIONS="-opensource -plugin-sql-sqlite -verbose"
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

[ -majorversion MAJOR_VERSION ]

  Build the version of Qt whose major version is given by
  MAJOR_VERSION. MAJOR_VERSION defaults to "$MAJOR_VERSION"


[ -configureopts CONFIGURE_OPTIONS ]

  Options to pass to ./configure. Defaults to "$CONFIGURE_OPTIONS"

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
  elif [ "$1" = "-majorversion" ]
  then
    MAJOR_VERSION="$2"
    shift
  elif [ "$1" = "-configureopts" ]
  then
    CONFIGURE_OPTIONS="$2"
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
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir qt

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
# http://qt-project.org/wiki/Get_The_Source
#### TOO SLOW --> git clone git://gitorious.org/qt/qt.git

echo "Note: Determining downloadable tarball URL ..."
tarballURL=$(wget -O - http://qt-project.org/downloads 2>/dev/null | \
  sed -n 's%href="\([^"]*\)"%~\1~%gp' | \
  tr '~' '\012' | \
  fgrep 'tar.gz' | \
  fgrep -v mirrorlist | \
  grep '/'"${MAJOR_VERSION}"'\.' | \
  sort | \
  uniq | \
  tail -1)

if [ -z "$tarballURL" ]
then
  echo "ERROR: Could not determine download tarball for MAJOR_VERSION $MAJOR_VERSION"
  exit 1
fi

tarballBase=$(basename "$tarballURL")
if [ ! -f "$tarballBase" ]
then
  echo "Note: Downloading latest major version $MAJOR_VERSION version of Qt from $tarballURL ..."
  PrintRun wget $tarballURL
else
  echo "Note: Not downloading $tarballURL as $tarballBase was found."
  echo "Note: $tarballBase already exists, not downloading $tarballURL. Continuing..."
fi

versionSubdir=$(echo "$tarballBase" | sed 's%\.tar\.gz$%%g')
if [ -z "$versionSubdir" ]
then
  echo "ASSERTION FAILED: versionSubdir was not initialized."
  exit 1
fi
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$versionSubdir"
fi
if [ ! -d "$versionSubdir" ]
then
  PrintRun tar zxvf $tarballBase
  if [ ! -d "$versionSubdir" ]
  then
    echo "ERROR: Failed to extract tarball at $tarballBase"
    exit 1
  fi
else
  echo "Note: $versionSubdir directory already exists. Continuing..."
fi
if [ ! -d "$versionSubdir" ]
then
  echo "ASSERTION FAILED: $versionSubdir should exist as a directory by now but does not."
  exit 1
fi

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Note: Configuring ..."
# http://qt-project.org/doc/qt-4.8/install-x11.html
PrintRun cd "$versionSubdir"
if [ ! -f ./configure ]
then
  echo "ASSERTION FAILED: we should have seen a ./configure file inside $(pwd) by now."
  exit 1
fi

if [ 0 = 1 ]
then
  
# Mandate fully-automated builds by saying yes to the prompts:
sed -i 's%read acceptance%acceptance=y%g' ./configure

# Hack around https://bugs.webkit.org/show_bug.cgi?id=89312 that leads to
#    g++: error: unrecognized command line option ‘-fuse-ld=gold’
# when building webkit:
sed -i \
  -e 's%\(^[ 	]*QMAKE_LFLAGS+=-fuse-ld=gold\)%#\1%g' \
  -e 's%\(^[ 	]*message(Using gold linker)\)%#\1%g' \
  src/3rdparty/webkit/Source/common.pri

echo "Note: Running ./configure ..."
PrintRun ./configure -prefix-install -prefix "$INSTALL_DIR" $CONFIGURE_OPTIONS

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Note: Building ..."
PrintRun make
fi

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Note: Installing ..."
PrintRun make install
