#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
#

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; BASE_DIR=`dirname $dollar0`

usage () {
  echo "USAGE: $0 -s path"
}

SOME_OPTION=""

while [ $# -gt 0 ]
do
  if [ "$1" = "-sa" ]
  then
    SOME_OPTION="$2"
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

if [ "$SOME_OPTION" != "" ]
then
  echo "ERROR: SOME_OPTION was not specified"
  exit 1
fi

