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
CreateAndChdirIntoBuildDir freecad

# This will work only for Debian systems. Later on we can rework this to build completely from source:

# Now getting this error:
# Building dependency tree       
# Reading state information... Done
# E: Unable to locate package libcoin80-dev
# + rm -f /home/brentg/build/Debian.7.x86_64/freecad/tmpscript.4338
# + exit -1


tmpscript=$(pwd)/tmpscript.$$
set -x

cat > $tmpscript <<EOF
set -x -e
apt-get install -y  build-essential
apt-get install -y  cmake
apt-get install -y  python
apt-get install -y  python-matplotlib
apt-get install -y  libtool
apt-get install -y  libcoin80-dev
apt-get install -y  libsoqt4-dev
apt-get install -y  libxerces-c-dev
apt-get install -y  libboost-dev
apt-get install -y  libboost-filesystem-dev
apt-get install -y  libboost-regex-dev
apt-get install -y  libboost-program-options-dev 
apt-get install -y  libboost-signals-dev
apt-get install -y  libboost-thread-dev
apt-get install -y  libqt4-dev
apt-get install -y  libqt4-opengl-dev
apt-get install -y  qt4-dev-tools
apt-get install -y  python-dev
apt-get install -y  python-pyside
apt-get install -y  liboce*-dev (opencascade community edition)
apt-get install -y  oce-draw
apt-get install -y  gfortran
apt-get install -y  libeigen3-dev
apt-get install -y  libqtwebkit-dev
apt-get install -y  libshiboken-dev
apt-get install -y  libpyside-dev
apt-get install -y  libode-dev
apt-get install -y  swig
apt-get install -y  libzipios++-dev
apt-get install -y  libfreetype6
apt-get install -y  libfreetype6-dev
EOF

chmod a+x $tmpscript
sudo sh -c $tmpscript
rm -f $tmpscript
exit -1

# --------------------------------------------------------------------------------
# Download the source for freecad into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
# http://freecadweb.org/wiki/index.php?title=CompileOnUnix#Getting_the_source
git clone git://git.code.sf.net/p/free-cad/code free-cad-code

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."


# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."


