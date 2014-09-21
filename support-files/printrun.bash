#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

# Transcribe the command and fail upon errors:
PrintRun ()
{
  echo 
  echo "COMMAND: $*"
  set -e
  $*
  set +e
}

TestPrintRun () {
  local cmd="$1"
  eval "
    PrintRun $cmd; \
    if [ \"\$?\" != \"0\" ]; then \
        echo \"ERROR: Could not execute $cmd\"; \
        exit 1; \
    else \
        echo \"Test run passed: $cmd\"; \
    fi;
    "
}

