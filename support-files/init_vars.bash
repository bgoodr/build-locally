#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
#
# This script sets and exports the following environment variables:
#
# PLATFORM:       Identifies the general name of the platform without any embedded version information.
# RELEASE_SUBDIR: Identifies the specific platform and version upon which the package is being built.
# INSTALL_DIR:    Installation directory
# BUILD_DIR:      Where the sources are downloaded and built.
# PACKAGE:        Name of the build-locally package (which not always be equal to what the package wants to call itself)

if [ -z "$RELEASE_SUBDIR" -o -z "$PLATFORM" ]
then
  #
  # The /etc/issue contains useless crap on RHEL7 and Rocky
  # so detect it:
  #
  issueFile="/etc/issue"
  crap_sniffer=$(sed -n '1s/^\\S$/crap/gp' $issueFile)
  if [ "$crap_sniffer" = "crap" ]
  then
    issueFile="/etc/redhat-release"
  fi

  if [ -r "$issueFile" ]
  then
    PLATFORM=linux; export PLATFORM
    release_type=""
    release_num=""
    spec=$(
      sed -E -n '

        # RHEL:
        s/^Red Hat Enterprise Linux (Client |WS |Workstation |)release ([0-9.]*) [^ ]*$/release_type=RHEL; release_num="\2"; /gp;
        s/^Red Hat Enterprise Linux (Client |WS |Workstation |)release ([0-9.]*) ([^ ]* Update ([0-9]*))$/release_type=RHEL; release_num="\2.\3"; /gp;

        # Rocky:
        s%^Rocky Linux release ([0-9.]+) .*$%release_type=Rocky; release_num="\1"; %gp;

        # For "CentOS Linux release 7.9.2009 (Core)" we do not care about the "(Core)" part:
        s/^CentOS (Linux |)release ([0-9.-]*).*$/release_type=CentOS; release_num="\2"; /gp;

        # Ubuntu detection:
        #
        #   We do not want full release_num values like "20.04.5"
        #   because the "5" part seems to keep changing on regular
        #   updates. If we allow for that, then we keep having to
        #   rebuild our local tools repeatedly for no good reason.
        #
        s/^Ubuntu ([0-9]+(\.[0-9]+)+).*$/release_type=Ubuntu; release_num="\1"; /gp;

        # Replace wheezy/sid with wheezy_sid on Debian so that release_num does not have slashes in it because it will be used in directory filenames:
        /Debian/s%/%_%g;
        s/^Debian GNU.Linux ([^ ]*) .n .l$/release_type=Debian; release_num="\1"; /gp;
        s/^.*SUSE Linux Enterprise Server ([0-9]*) SP([0-9]*) .*/release_type=SUSE; release_num="\1.\2"; /gp;
      ' $issueFile 2>/dev/null)
    eval "$spec"
    if [ -z "$release_type" ]
    then
      echo "WARNING: $0: Unrecognized Linux release type \"$release_type\" on host `uname -n`."
    fi
    release_kernel_version=`cat /proc/version | sed -n 's%^Linux version \([^ ]*\) .*$%\1%gp'`
    release_machine_type=`uname -m | sed 's%^i686$%x86%g; s%-%_%g;'`
    spec=`echo "$release_num" | sed -n 's%^\([0-9]*\)\\.\([0-9]*\)$%major_release_num="\1"; minor_release_num="\2"; %gp' 2>/dev/null`
    eval "$spec"
  else
    # TODO: Someone can provide support other *NIX flavors (Mac) here if they desire.
    echo "ASSERTION FAILED: Cannot identify this version of Linux or UNIX"
    exit 1
  fi
  RELEASE_SUBDIR="${release_type}.${release_num}.${release_machine_type}"; export RELEASE_SUBDIR
fi

if [ -z "$BUILD_DIR" ]
then
  BUILD_DIR="$HOME/build/$RELEASE_SUBDIR"; export BUILD_DIR
fi
echo "Note: Using BUILD_DIR==\"${BUILD_DIR}\""

if [ -z "$INSTALL_DIR" ]
then
  INSTALL_DIR="$HOME/install/$RELEASE_SUBDIR"; export INSTALL_DIR
fi
echo "Note: Using INSTALL_DIR==\"${INSTALL_DIR}\""

# Find the base directory while avoiding subtle variations in $0.
# Note that the *.bash files also do this; It is extra work, it is ok, just calm down:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR
PACKAGE=$(basename $(dirname $PACKAGE_DIR))
