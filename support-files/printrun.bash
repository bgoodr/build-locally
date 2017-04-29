#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

# Transcribe the command and fail upon errors:
PrintRun ()
{
  echo 
  echo "COMMAND: $*"
  set -e

  # These two expressions do not handle embedded whitespace:
  #
  #   $*
  #   $@
  #
  # So, instead use this:
  "$@"

  set +e
}
