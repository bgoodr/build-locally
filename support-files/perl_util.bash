#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

if [ -z "$PACKAGE_DIR" ]; then echo "ASSERTION FAILED: Calling script always has to dynamically determine and set the PACKAGE_DIR variable."; exit 1 ; fi # see ./PACKAGE_DIR_detect.org

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables:
. $PACKAGE_DIR/../../../support-files/init_vars.bash
# Get the PrintRun utility defined:
. $PACKAGE_DIR/../../../support-files/printrun.bash

BuildDependentPerlModule () {
  local package="$1"
  local module="$2"
  version=$(perl -le 'eval "require $ARGV[0]" and print $ARGV[0]->VERSION' $module)
  if [ -z "$version" ]
  then
    perlVersion=$(perl -le 'print $^V' | sed 's%^v%%g')
    subdir=$(echo "$module" | sed 's%::%-%g')
    echo $subdir
    BuildDependentPackage $package "lib/perl5/site_perl/$perlVersion/*/.meta/${subdir}*"
  fi
}
