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
BuildDependentPackage gnome-common bin/gnome-autogen.sh
BuildDependentPackage gtk-doc share/aclocal/gtk-doc.m4
BuildDependentPackage glib bin/gobject-query

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# ldconfig will find the old glib-2.0 version installed locally on the
# system, but we want it paired up with our locally built
# version. What happens here is that this package ./configure file
# compiles a conftest executable that, when executed, will pull in the
# ldconfig defined library and not the one we build (see ld.so(8) man
# page for the ordering):
#
#    *** 'pkg-config --modversion glib-2.0' returned 2.41.5, but GLIB (2.22.5)
#    *** was found! If pkg-config was correct, then it is best
#    *** to remove the old version of GLib. You may also be able to fix the error
#    *** by modifying your LD_LIBRARY_PATH enviroment variable, or by editing
#    *** /etc/ld.so.conf. Make sure you have run ldconfig if that is
#    *** required on your system.
#    *** If pkg-config was wrong, set the environment variable PKG_CONFIG_PATH
#    *** to point to the correct configuration files
#
# Therefore, override LD_LIBRARY_PATH with path before calling ./configure:
export LD_LIBRARY_PATH=$INSTALL_DIR/lib:$LD_LIBRARY_PATH

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir atk

# --------------------------------------------------------------------------------
# Check out the source for emacs into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=atk
DownloadPackageFromGitRepo git://git.gnome.org/$packageSubDir $packageSubDir

PrintRun cd $packageSubDir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."
# Run autogen.sh which also generates and runs ./configure:
PrintRun ./autogen.sh --prefix="$INSTALL_DIR"
if [ ! -f ./configure ]
then
  echo "ERROR: Could not create ./configure file. autoconf must have failed."
  exit 1
fi

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

pcFile="$INSTALL_DIR/lib/pkgconfig/atk.pc"
if [ ! -f "$pcFile" ]
then
  echo "ERROR: Could not find expected file at: $pcFile"
  exit 1
fi

echo "Note: All installation tests passed."
exit 0