#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
. $PACKAGE_DIR/../../../support-files/python_util.bash

CLEAN=0
while [ $# -gt 0 ]
do
  if [ "$1" = "-builddir" ]
  then
    BUILD_DIR="$2"
    shift
  elif [ "$1" = "-installdir" ]
  then
    INSTALL_DIR="$2"
    shift
  elif [ "$1" = "-clean" ]
  then
    CLEAN=1
  elif [ "$1" = "-h" ]
  then
    EmitStandardUsage
    exit 0
  else
    echo "Undefined parameter $1"
    exit 1
  fi
  shift
done

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
# jira-python depends upon pip. See http://jira-python.readthedocs.org/en/latest/#installation
BuildDependentPackage python--pip bin/pip

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir python--jira-python

# --------------------------------------------------------------------------------
# Downloading and installing:
# --------------------------------------------------------------------------------
echo "Downloading and installing ..."
# http://jira-python.readthedocs.org/en/latest/#installation
# Not using a virtualenv. The locally built python is acts as the virtualenv already:
PrintRun pip install jira-python
# Output seen was: 
# ,----
# |     Installing jirashell script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |   Running setup.py install for requests
# |     
# |   Running setup.py install for requests-oauthlib
# |     
# |   Running setup.py install for ipython
# |     
# |     Installing ipcontroller script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing iptest script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing ipcluster script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing ipython script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing pycolor script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing iplogger script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing irunner script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |     Installing ipengine script to /home/brentg/install/RHEL.6.2.x86_64/bin
# |   Running setup.py install for tlslite
# |     changing mode of build/scripts-2.7/tls.py from 664 to 775
# |     changing mode of build/scripts-2.7/tlsdb.py from 664 to 775
# |     
# |     changing mode of /home/brentg/install/RHEL.6.2.x86_64/bin/tlsdb.py to 775
# |     changing mode of /home/brentg/install/RHEL.6.2.x86_64/bin/tls.py to 775
# |   Running setup.py install for oauthlib
# `----

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."
ValidateFileInInstallBinDir jirashell
echo "Note: All installation tests passed."
exit 0
