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
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Install:
#   This is intended to work on both Ubuntu-based and RHEL-based Linux systems.
# --------------------------------------------------------------------------------
env_file="$INSTALL_DIR/rust/cargo/env"
test -f "$env_file" || {
  echo "Installing ..."
  PrintRun CARGO_HOME=$INSTALL_DIR/rust/cargo RUSTUP_HOME=$INSTALL_DIR/rust/rustup bash -c '
  curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
'
}

test -f "$env_file" || {
  echo "${BASH_SOURCE[0]}:${LINENO}: ERROR: Failed to install rust as $env_file does not exist as a file." 1>&2
  exit 1
}

source $env_file

# https://www.rust-lang.org/tools/install
# says run this to see if it fails:
#
#   PrintRun rustc --version
#
# yes sure enough, it does:
#
#   COMMAND: rustc --version
#   error: rustup could not choose a version of rustc to run, because one wasn't specified explicitly, and no default is configured.
#   help: run 'rustup default stable' to download the latest stable release of Rust and set it as your default toolchain.
#
# So we must download the stable release, as follows:
PrintRun rustup default stable

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
PrintRun rustc --version

echo "Note: Rust installation succeeded. Update your startup files to source $env_file"
exit 0
