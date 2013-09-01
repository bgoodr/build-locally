# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

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
  cmd="$1"
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

