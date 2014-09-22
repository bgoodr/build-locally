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
BuildDependentPackage gobject-introspection bin/g-ir-compiler
BuildDependentPackage atk lib/pkgconfig/atk.pc
BuildDependentPackage pango lib/pkgconfig/pango.pc
BuildDependentPackage cairo lib/pkgconfig/cairo.pc
echo "TODO: build the dependent packages:"; exit 1
# No package 'cairo-gobject' found
# No package 'gdk-pixbuf-2.0' found

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir gtk

# --------------------------------------------------------------------------------
# Check out the source for emacs into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=gtk+
# http://www.gtk.org/download/index.php#BleedingEdge
DownloadPackageFromGitRepo git://git.gnome.org/gtk+ $packageSubDir

PrintRun cd $packageSubDir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."
# Run autogen.sh which also generates and runs ./configure:
PrintRun ./autogen.sh --prefix="$INSTALL_DIR"
echo "ERROR: debugging"; exit 1
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

gtkExe="$INSTALL_DIR/bin/gtk"
if [ ! -f "$gtkExe" ]
then
  echo "ERROR: Could not find expected executable at: $gtkExe"
  exit 1
fi

# Determine the expected version from the ./configure file:
expected_gtk_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_gtk_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected gtk version."
  exit 1
fi

# Determine the actual version we built:
actual_gtk_version=$($gtkExe --batch --quick --eval '(prin1 gtk-version t)' | tr -d '"')

# Trim off the final number. That last number gets tacked on by
# something in the build (how? the makefiles are obfuscated) and we
# don't care about that. And if you run make then make install, that
# number gets bumped again.
echo "Original actual_gtk_version is \"${actual_gtk_version}\" but we are ripping off the last number which gets incremented in each local build."
actual_gtk_version=$(echo "$actual_gtk_version" | sed 's%^\([0-9]*.[0-9]*.[0-9]*\).[0-9]*$%\1%g')

# Now compare:
if [ "$expected_gtk_version" != "$actual_gtk_version" ]
then
  echo "ERROR: Failed to build expected gtk version: $expected_gtk_version"
  echo "                         actual gtk version: $actual_gtk_version"
  exit 1
fi
echo "Note: All installation tests passed. Gtk version $actual_gtk_version was built and installed."
exit 0
