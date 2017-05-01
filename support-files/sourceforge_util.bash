#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

DownloadExtractSourceForgePackage () {
  local package="$1"

  # --------------------------------------------------------------------------------
  # Downloading:
  # --------------------------------------------------------------------------------
  version=$(wget -O - "https://sourceforge.net/projects/$package/?source=typ_redirect" 2>&1 | sed -n "s%^.*/$package/"'\([0-9.]*\)/.*$%\1%gp')
  tarbasefile=$package-$version.tar.gz
  downloadURL=https://downloads.sourceforge.net/project/$package/$package/$version/$tarbasefile
  echo "Downloading ..."
  if [ ! -f $tarbasefile ]
  then
    wget $downloadURL
    if [ ! -f $tarbasefile ]
    then
      echo "ERROR: Could not retrieve $tarbasefile"
      exit 1
    fi
  fi

  # The top-level directory is not guaranteed to be the first line in
  # the tar tf output as of Sun Apr 23 09:41:19 PDT 2017 using tar
  # version tar (GNU tar) 1.23. Maybe it never was guaranteed to be?
  # No matter; just do this:
  subdir=$(tar tf $tarbasefile 2>/dev/null | sed -n '/^\([^/][^/]*\)\/.*$/{ s%%\1%g; p; q; }')
  echo "subdir==\"${subdir}\""

  if [ ! -d "$subdir" ]
  then
    tar zxvf $tarbasefile
    if [ ! -d "$subdir" ]
    then
      echo "ERROR: Could not extract `pwd`/$tarbasefile"
      exit 1
    fi
  fi
  PrintRun cd $HEAD_DIR/$subdir

}
