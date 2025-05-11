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
# The rust package in ../../rust should install this file so ensure that other packages does just that:
rust_base_env_file="rust/cargo/env"
BuildDependentPackage rust "$rust_base_env_file"
rust_env_file="$INSTALL_DIR/$rust_base_env_file"
test -f "$rust_env_file" || {
  echo "${BASH_SOURCE[0]}:${LINENO}: ERROR: Failed to install rust dependency because $rust_env_file does not exist as a file." 1>&2
  exit 1
}

# Get the paths to rust into the environment required by the rigrep builds:
source "$rust_env_file"

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir ripgrep

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
test -d ripgrep || {
  PrintRun git clone https://github.com/BurntSushi/ripgrep
}

# --------------------------------------------------------------------------------
# Build and install:
# --------------------------------------------------------------------------------
echo "Building and installing ..."
PrintRun cd ripgrep
PrintRun cargo build --release --features 'pcre2'

# --------------------------------------------------------------------------------
# Installing:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun cp -p target/release/rg $INSTALL_DIR/bin

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
echo "Running tests on this package ..."

if [ ! -f "$INSTALL_DIR/bin/rg" ]
then
  echo "TEST FAILED: Failed to find application installed at $INSTALL_DIR/bin/rg"
  exit 1
fi

# $BUILD_DIR/ripgrep/ripgrep/FAQ.md says this is how the man page is generated:
# and from what can be ascertained, their build logic does not do this automatically:
man_path_dir="$INSTALL_DIR/share/man"
PrintRun mkdir -p $man_path_dir/man1
PrintRun bash -c "rg --generate man > $man_path_dir/man1/rg.1"
num_man_output_lines=$(MANPATH="$man_path_dir" man rg | col -b | wc -l)
test "$num_man_output_lines" -gt 0 || {
  echo "ERROR: Could not generate rg man page." 1>&2
  exit 1
}

echo "Note: All installation tests passed."
exit 0
