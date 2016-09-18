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
BuildDependentPackage texinfo bin/makeinfo
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
BuildDependentPackage guile bin/guile

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir xbindkeys

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
version_subdir=xbindkeys
if [ "$CLEAN" = 1 ]
then
  PrintRun rm -rf "$version_subdir"
fi
if [ ! -d "$version_subdir" ]
then
  PrintRun git clone git://git.savannah.nongnu.org/xbindkeys.git/
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
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun cd $version_subdir

# The following is a massive failure to do the right thing and
# resulted in a hack. Scroll down after this mess to find the actual
# hack I resorted to:
#
#   When building, I found that xbindkeys did not have its rpath set
#   properly.  The guile executable did have rpath set properly.
#   
#   Tracked this down: I see this error during configure (using the configure file gotten from Git):
#   
#     checking for shared library run path origin... /bin/sh: ./config.rpath: No such file or directory
#   
#   Might be related. Did some searching and found:
#   
#     http://ramblingfoo.blogspot.com/2007/07/required-file-configrpath-not-found.html
#   
#   Searching the code found xbindkeys/aclocal.m4 "GUILE_FLAGS" defun
#   that has code that is attempting to get the rpath into GUILE_LIBS.
#   
#   Attempt to understand this a bit mroe by hacking: Move the configure
#   aside which will force this script to run autogen.sh:
#   
#      if [ -f ./configure ]
#      then
#        PrintRun mv configure configure.moved.by.build-locally.to.hack.around.a.build.bug
#      fi
#   
#   but that gave:
#   
#     COMMAND: ./autogen.sh
#     configure.ac:7: warning: AM_INIT_AUTOMAKE: two- and three-arguments forms are deprecated.  For more info, see:
#     configure.ac:7: http://www.gnu.org/software/automake/manual/automake.html#Modernize-AM_005fINIT_005fAUTOMAKE-invocation
#     configure.ac:14: installing './compile'
#     configure.ac:74: error: required file './config.rpath' not found
#   
#   ignoring the warning, and searching the web for that last error:
#   
#     http://www.dovecot.org/list/dovecot/2007-November/027106.html
#   
#   Searching my installation area finds:
#   
#     $INSTALL_DIR/share/gettext/config.rpath
#   
#   In the generated configure file I see:
#   
#     echo -e "\n$BUILD_DIR/xbindkeys/xbindkeys/configure:$LINENO: bgdbg host==\"${host}\"" >&6; # <-- I added this for debugging to find the value of $host
#     CC="$CC" GCC="$GCC" LDFLAGS="$LDFLAGS" LD="$LD" with_gnu_ld="$with_gnu_ld" \
#     ${CONFIG_SHELL-/bin/sh} "$ac_aux_dir/config.rpath" "$host" > conftest.sh
#     . ./conftest.sh
#     rm -f ./conftest.sh
#     acl_cv_rpath=done
#   
#   Finds that host is x86_64-unknown-linux-gnu. Executing $INSTALL_DIR/share/gettext/config.rpath this way:
#   
#    
#     CC="$CC" GCC="$GCC" LDFLAGS="$LDFLAGS" LD="$LD" with_gnu_ld="$with_gnu_ld" \
#     ${CONFIG_SHELL-/bin/sh} "$INSTALL_DIR/share/gettext/config.rpath" "$host"       # > conftest.sh
#   
#   gives:
#    
#     # How to pass a linker flag through the compiler.
#     acl_cv_wl="-Wl,"
#     
#     # Static library suffix (normally "a").
#     acl_cv_libext="a"
#     
#     # Shared library suffix (normally "so").
#     acl_cv_shlibext="so"
#     
#     # Format of library name prefix.
#     acl_cv_libname_spec="lib\$name"
#     
#     # Library names that the linker finds when passed -lNAME.
#     acl_cv_library_names_spec="\$libname\$shrext"
#     
#     # Flag to hardcode $libdir into a binary during linking.
#     # This must work even if $libdir does not exist.
#     acl_cv_hardcode_libdir_flag_spec="\${wl}-rpath \${wl}\$libdir"
#     
#     # Whether we need a single -rpath flag with a separated argument.
#     acl_cv_hardcode_libdir_separator=""
#     
#     # Set to yes if using DIR/libNAME.so during linking hardcodes DIR into the
#     # resulting binary.
#     acl_cv_hardcode_direct="no"
#     
#     # Set to yes if using the -LDIR flag during linking hardcodes DIR into the
#     # resulting binary.
#     acl_cv_hardcode_minus_L="no"
#    
#   Doing replacing the lines with:
#   
#     CC="$CC" GCC="$GCC" LDFLAGS="$LDFLAGS" LD="$LD" with_gnu_ld="$with_gnu_ld" \
#     ${CONFIG_SHELL-/bin/sh} "$INSTALL_DIR/share/gettext/config.rpath" "$host" > conftest.sh
#   
#   did not help either. This is is way way more difficult than it should be.
#
# So hack around it by forcing the rpath into LDFLAGS:
#
export LDFLAGS="-Wl,-R$INSTALL_DIR/lib"

#
# Now proceed with (optional) configure generation and execution
#
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
PrintRun ./configure --prefix="$INSTALL_DIR"
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
if [ ! -d "$INSTALL_DIR" ]
then
  echo "ERROR: $INSTALL_DIR does not exist. You must build it first."
  exit 1
fi
echo "Running tests on this package ..."

if [ ! -f "$INSTALL_DIR/bin/xbindkeys" ]
then
  echo "TEST FAILED: Failed to find application installed at $INSTALL_DIR/bin/xbindkeys"
  exit 1
fi
missing_shared_libraries=$(unset LD_LIBRARY_PATH; ldd $INSTALL_DIR/bin/xbindkeys | grep 'not found')
if [ -n "$missing_shared_libraries" ]
then
  echo "TEST FAILED: rpath not set correctly in $INSTALL_DIR/bin/xbindkeys:"
  echo "$missing_shared_libraries"
  exit 1
fi
version=$($INSTALL_DIR/bin/xbindkeys --version 2>&1 | sed -n 's%^xbindkeys \([0-9.]*\).*$%found%gp')
if [ -z "$version" ]
then
  echo "ERROR: Failed to get version from $INSTALL_DIR/bin/xbindkeys"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
