#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

ApplyPatch () {
  local patchFile="$1"
  local toBePatchedFiles=$(sed 's%^--- \([^ ]*\) .*$%\1%gp' <$patchFile)
  local toBePatchedFile=""
  for toBePatchedFile in $toBePatchedFiles
  do
    if [ ! -f "$toBePatchedFile" ]
    then
      echo "ASSERTION FAILED: toBePatchedFile $toBePatchedFile does not exist as expected."
      exit 1
    fi
    # Save off the original and apply it each time through, to allow re-execution:
    if [ ! -f ${toBePatchedFile}.orig ]
    then
      cat ${toBePatchedFile} > ${toBePatchedFile}.orig
    fi
  done
  set -x -e
  cat ${toBePatchedFile}.orig > ${toBePatchedFile}
  # Patch the files:
  patch -t -p0 $patchFile
}
