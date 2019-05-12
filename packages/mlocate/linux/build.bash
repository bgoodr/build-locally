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

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
# BuildDependentPackage pkg-config bin/pkg-config

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir mlocate

# --------------------------------------------------------------------------------
# Download and build tarball into the build directory:
# --------------------------------------------------------------------------------
GetDebianSourcePackageTarBalls mlocate testing tarballs

debianFiles=""
ExtractDebianSourcePackageTarBall "$tarballs" '.*debian\.tar\.gz$' '^debian$' debianFiles

origFiles=""
ExtractDebianSourcePackageTarBall "$tarballs" '.*orig\.tar\.gz$' '^mlocate-[0-9.]*$' origFiles

wwwFiles=""
ExtractDebianSourcePackageTarBall "$tarballs" '.*orig-www\.tar\.gz$' '^www$' wwwFiles

# --------------------------------------------------------------------------------
# Applying Debian patches:
# --------------------------------------------------------------------------------
ApplyDebianPatches "$debianFiles" "$origFiles"

# At this point, I discovered that https://salsa.debian.org/tfheen/mlocate exists so I might be able to use that.
# So I'm checking in what I have right now and trying that instead of using the "Debian" stuff above. 
echo pwd is $(pwd)
exit 1





# --------------------------------------------------------------------------------
# Check out the source:
# --------------------------------------------------------------------------------
DownloadPackageFromGitRepo https://pagure.io/mlocate.git mlocate

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
PrintRun cd mlocate

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."

# /home/brentg/build/CentOS.7.2.1511.x86_64/mlocate/mlocate/HACKING
#
#   To set up a build environment from this repository, run:
#       mkdir $gldir; cd $gldir
#       git clone git://git.savannah.gnu.org/gnulib.git
#       git checkout 5861339993f3014cfad1b94fc7fe366fc2573598
#       cd $mlocate_dir
#       $gldir/gnulib/gnulib-tool --import
#       hg revert --all
#       autoreconf -is
#
gldir=$(pwd)/tmp_for_gnulib
# gldir=$(pwd)
if [ ! -d $gldir/gnulib ]
then
  PrintRun mkdir $gldir
  PrintRun cd $gldir

  PrintRun git clone --depth 1 git://git.savannah.gnu.org/gnulib.git

  # Skipping this:
  #   PrintRun git checkout 5861339993f3014cfad1b94fc7fe366fc2573598
  # because it gives this:
  #   COMMAND: git checkout 5861339993f3014cfad1b94fc7fe366fc2573598
  #   fatal: reference is not a tree: 5861339993f3014cfad1b94fc7fe366fc2573598

  PrintRun cd ..
fi

PrintRun $gldir/gnulib/gnulib-tool --import

# Workaround odd reference to "gnulib" subdirectory in the Makefile.am and configure.ac files because this is what I see as output from gnulib-tool above:
#
#    Don't forget to
#      - add "lib/Makefile" to AC_CONFIG_FILES in ./configure.ac,
#      - mention "lib" in SUBDIRS in Makefile.am,
#      - mention "-I m4" in ACLOCAL_AMFLAGS in Makefile.am,
#      - mention "m4/gnulib-cache.m4" in EXTRA_DIST in Makefile.am,
#      - invoke gl_EARLY in ./configure.ac, right after AC_PROG_CC,
#      - invoke gl_INIT in ./configure.ac.
#    
sed -i 's%gnulib/lib/Makefile%lib/Makefile%g' configure.ac
sed -i 's%gnulib/lib%lib%g; s%gnulib/m4%m4%g;  s%EXTRA_DIST = %EXTRA_DIST = m4/gnulib-cache.m4 %g' Makefile.am

PrintRun autoreconf -is

# Skipping this as I don't have it on my system (and is it necessary for just building?):
#   PrintRun hg revert --all

PrintRun ./configure --prefix="$INSTALL_DIR"

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
mlocateExe="$INSTALL_DIR/bin/mlocate"
if [ ! -f "$mlocateExe" ]
then
  echo "ERROR: Could not find expected executable at: $mlocateExe"
  exit 1
fi

# Determine the expected version from the ./configure file:
expected_mlocate_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_mlocate_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected mlocate version."
  exit 1
fi

# Determine the actual version we built:
actual_mlocate_version=$($mlocateExe --version | sed -n 's/^mlocate \([0-9.a-z-]*\)$/\1/gp')

# Now compare:
if [ "$expected_mlocate_version" != "$actual_mlocate_version" ]
then
  echo "ERROR: Failed to build expected mlocate version: $expected_mlocate_version"
  echo "                         actual mlocate version: $actual_mlocate_version"
  exit 1
fi
echo "Note: All installation tests passed. TheExecutable version $actual_mlocate_version was built and installed."
exit 0
