#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# define utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

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
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
# sudo apt-get install libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' libcurl4-gnutls-dev /usr/include/curl/curl.h
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' libexpat1-dev /usr/include/expat.h
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' gettext /usr/bin/msgcat
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' libssl-dev /usr/include/openssl/ssl.h
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' zlib1g-dev /usr/include/zlib.h
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' asciidoc /usr/bin/asciidoc
VerifyOperatingSystemPackageContainingFile 'Debian|Ubuntu' docbook2x /usr/bin/docbook2x-texi

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir git

# See http://git-scm.com/book/en/v2/Getting-Started-Installing-Git

# --------------------------------------------------------------------------------
# Download release tarball:
# --------------------------------------------------------------------------------
releasesHtmlFile=releases.html
releasesURL=https://github.com/git/git/releases
if [ ! -f $releasesHtmlFile ]
then
  PrintRun wget -O $releasesHtmlFile $releasesURL
fi

subPath=$(cat $releasesHtmlFile | sed -n '/tar.gz/{ s%^.*<a href="\([^"]*\)".*$%\1%gp; }' | sort | tail -1)
echo "subPath==\"${subPath}\""
baseTarball=$(basename $subPath)
echo "baseTarball==\"${baseTarball}\""
if [ ! -f $baseTarball ]
then
  downloadURL=https://github.com$subPath
  PrintRun wget $downloadURL
  if [ ! -f $baseTarball ]
  then
    echo "ERROR: Failed to download $downloadURL into $baseTarball"
    exit 1
  fi
fi

# --------------------------------------------------------------------------------
# Check out the source into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=$(echo $baseTarball | sed -e 's%\.tar\.gz$%%g' -e 's%^v%git-%g')
echo "packageSubDir==\"${packageSubDir}\""
if [ ! -d $packageSubDir ]
then
  PrintRun tar zxvf $baseTarball
  if [ ! -d $packageSubDir ]
  then
    echo "ERROR: Failed to extract $baseTarball into $packageSubDir"
    exit 1
  fi
fi
PrintRun cd $packageSubDir

# --------------------------------------------------------------------------------
# Configure
# --------------------------------------------------------------------------------
echo "Configuring ..."

PrintRun make configure
if [ ! -f ./configure ]
then
  echo "ERROR: Could not create ./configure file. make configure must have failed."
  exit 1
fi
PrintRun ./configure --prefix="$INSTALL_DIR"

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun make all doc info

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install install-doc install-html install-info

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."

gitExe="$INSTALL_DIR/bin/git"
if [ ! -f "$gitExe" ]
then
  echo "ERROR: Could not find expected executable at: $gitExe"
  exit 1
fi


# Determine the expected version from the ./configure file:
expected_git_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_git_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected git version."
  exit 1
fi

# Determine the actual version we built:
actual_git_version=$($gitExe --version | sed -n 's%^git version \(.*\)$%\1%gp')

# Now compare:
if [ "$expected_git_version" != "$actual_git_version" ]
then
  echo "ERROR: Failed to build expected git version: $expected_git_version"
  echo "                         actual git version: $actual_git_version"
  exit 1
fi
echo "Note: All installation tests passed. Git version $actual_git_version was built and installed."
exit 0

exit 0
