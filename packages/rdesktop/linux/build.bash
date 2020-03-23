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
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir rdesktop

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
# Arbitrarily choosing to build stable releases and not from source.

echo "Note: Determining downloadable tarball URL ..."

homePageURL='https://github.com/rdesktop/rdesktop/releases/latest'
homePageURLFile=""
DownloadURLIntoLocalFile "$homePageURL" homePageURLFile
downloadBasePath=$(cat $homePageURLFile | sed -n '/tar.gz/{ s/^.*href="\([^"]*\)".*$/\1/gp; q; }')
downloadURL="https://github.com$downloadBasePath"
if [ -z "$downloadURL" ]
then
  echo "ERROR: Could not find download URL to latest stable release of rdesktop from $homePageURL"
  exit 1
fi
echo "Got download URL: $downloadURL"
tarballBase=$(basename $downloadURL | sed 's%\?.*$%%g')
downloadTarball=""
DownloadURLIntoLocalFile "$downloadURL" downloadTarball $tarballBase
echo "downloadTarball==\"${downloadTarball}\""
version=$(echo $downloadTarball | sed -e 's%rdesktop-%%g' -e 's%.tar.gz%%g')
if [ -z "$version" ]
then
  echo "ERROR: Could not determine version from downloaded tarball: $downloadTarball"
  exit 1
fi
echo "version: ${version}"
versionSubdir=$(tar tf $tarballBase | sed -n '/\//{ s%^\([^/]*\)/.*$%\1%gp; q; }')
echo "versionSubdir==\"${versionSubdir}\""
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
PrintRun cd "$versionSubdir"

# Disabled this stuff for now. It might need it later on RHEL machines:
### if [ ! -f /usr/include/X11/Xlib.h ]
### then
###   echo "ERROR: X headers are missing. Do this first:"
###   echo
###   echo "sudo apt-get install libx11-dev"
###   echo
###   exit 1
### fi
### if [ ! -f /usr/lib/libssl.so -a ! -f /usr/lib/x86_64-linux-gnu/libssl.so ]
### then
###   echo "ERROR: /usr/lib/libssl.so does not exist so you need to run: sudo apt-get install libssl-dev"
###   exit 1
### fi

if [ ! -f configure ]
then
  PrintRun ./bootstrap
  if [ ! -f configure ]
  then
    echo "ERROR: bootstrap step failed to create configure script."
    exit 1
  fi
else
  echo "Note: Not creating configure script since it already exists as a file."
fi
if [ ! -f Makefile ]
then

  # I see this:
  #
  #   checking for GSSGLUE... no
  #   CredSSP support requires libgssglue, install the dependency
  #   or disable the feature using --disable-credssp.
  #
  #   checking for PCSCLITE... no
  #   SmartCard support requires PCSC, install the dependency
  #   or disable the feature using --disable-smartcard.
  #
  # so disable them.
  
  PrintRun ./configure --prefix="$INSTALL_DIR" --disable-credssp --disable-smartcard
  if [ ! -f Makefile ]
  then
    echo "ERROR: configure script failed to create a Makefile"
    exit 1
  fi
else
  echo "Note: Not creating Makefile since it already exists as a file."
fi

PrintRun make
PrintRun make install
