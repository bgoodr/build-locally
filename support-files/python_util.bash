#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

if [ -z "$PACKAGE_DIR" ]; then echo "ASSERTION FAILED: Calling script always has to dynamically determine and set the PACKAGE_DIR variable."; exit 1 ; fi # see ./PACKAGE_DIR_detect.org

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables:
. $PACKAGE_DIR/../../../support-files/init_vars.bash
# Get the PrintRun utility defined:
. $PACKAGE_DIR/../../../support-files/printrun.bash

PythonDownloadAndRunBootstrapScript () {
  local bootstrapURL="$1"
  # bootstrapScript is exposed to the caller:
  bootstrapScript=$(basename "$bootstrapURL")
  rm -f $bootstrapScript
  wget "$bootstrapURL"
  if [ ! $bootstrapScript ]
  then
    echo "ERROR: Failed to download $bootstrapScript from $bootstrapURL"
    exit 1
  fi
}

VerifyPythonWith () {
  local test_expr="$1"
  local python_expr="$2"
  echo "Note: $test_expr ..."
  if ! python -c "$python_expr"
  then
    echo "ERROR: Failed verification test: $test_expr"
    exit 1
  else
    echo "Note: Verification test passed: $test_expr"
  fi
}

