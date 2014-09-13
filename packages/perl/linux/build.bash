#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

usage () {
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

  Override the INSTALL_DIR default, which is $INSTALL_DIR.

EOF
}

while [ $# -gt 0 ]
do
  if [ "$1" = "-builddir" ]
  then
    BUILDDIR="$2"
    shift
  elif [ "$1" = "-installdir" ]
  then
    INSTALLDIR="$2"
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

# --------------------------------------------------------------------------------
# Dependent packages will be installed into $INSTALL_DIR/bin so add
# that directory to the PATH:
# --------------------------------------------------------------------------------
SetupBasicEnvironment

# --------------------------------------------------------------------------------
# Build required dependent packages:
# --------------------------------------------------------------------------------
BuildDependentPackage autoconf bin/autoconf
BuildDependentPackage automake bin/automake
BuildDependentPackage libtool bin/libtool

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir perl

# --------------------------------------------------------------------------------
# Find the version from remote "maint-" branches directly:
# --------------------------------------------------------------------------------
gitRepo=git://perl5.git.perl.org/perl.git
major=5
minor=$(git ls-remote --heads ${gitRepo} | grep refs/heads/maint- | sed -n 's%^.*refs/heads/maint-'"$major"'\.%%gp'  | sort -n | tail -1)
if [ $(expr $minor % 2) != 0 ]
then
  echo "ASSERTION FAILED: version==\"${version}\" should be an even number for latest stable release."
  exit 1
fi
version=${major}.${minor}
echo "Found perl maintenance version: $version"

# --------------------------------------------------------------------------------
# Check out the source for perl into the build directory:
# --------------------------------------------------------------------------------
# use fullcheckout so that we can switch to the production maintenance branch
DownloadPackageFromGitRepo ${gitRepo} perl fullcheckout
PrintRun cd perl
currentBranch=$(git branch | sed -n 's%^\* %%gp')
branch=maint-$version
if [ "$currentBranch" != "$branch" ]
then
  PrintRun git checkout -b maint-$version origin/maint-$version
fi

# Disabled the experimental code for building from tarball in hope of using the git maint branches:
if [ 0 = 1 ]
then
  
  # --------------------------------------------------------------------------------
  # Download the latest atest/stable/production version.  From http://www.cpan.org/src/ we
  # have this info:
  #
  #   Maintenance branches (ready for production use) are even numbers (5.8, 5.10, 5.12 etc)
  #   Sub-branches of maintenance releases (5.12.1, 5.12.2 etc) are mostly just for bug fixes
  #    
  # --------------------------------------------------------------------------------
  tarballHeadURL="http://www.cpan.org/src/"
  tarballURL=$( \
    wget -O - $tarballHeadURL 2>/dev/null | \
    sed -n '/class.*latest/,/<\/table>/p' | \
    sed -n '/tar.gz/{ s/^[^"]*"//g; s/"[^"]*$//g; p; q;}' \
    )
  version=$(echo "$tarballURL" | sed -n -e 's%^.*/perl-%%g; s%\.tar\.gz$%%g; p; ')
  script=$(echo "$version" | sed -n 's%^\([0-9]*\)\.\([0-9]*\)\..*$%major="\1"; minor="\2"; %gp')
  eval $script
  if [ $(expr $minor % 2) != 0 ]
  then
    echo "ASSERTION FAILED: version==\"${version}\" should be an even number for latest stable release."
    exit 1
  fi
  if [ $(expr $major \> 5) != 0 ]
  then
    echo "ASSERTION FAILED: This is not Perl 5. Either a bug is in the script or Perl is now the Parrot release."
    exit 1
  fi
  echo Automatically determined latest/stable/production version == $version

  # --------------------------------------------------------------------------------
  # Extract the source:
  # --------------------------------------------------------------------------------
  tarball=perl-${version}.tar.gz
  subdir=perl-${version}
  if [ ! -d ${subdir} ]
  then
    PrintRun wget $tarballURL
    PrintRun tar zxvf ${tarball}
    if [ ! -d $subdir ]
    then
      echo "ERROR: Failed to extract $tarball since $(pwd)/$subdir does not exist."
      exit 1
    fi
  fi
  PrintRun cd $subdir

fi

# --------------------------------------------------------------------------------
# Configure:
# --------------------------------------------------------------------------------
rm -f config.sh Policy.sh
# -Duserelocatableinc is so that the Perl standard modules are
# found relative to where we relocate Perl to be, and since we
# would like to have the option to relocate the resulting binaries:
PrintRun sh Configure -Dprefix="$INSTALL_DIR" -Duserelocatableinc -de

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."
PrintRun make
# Gives nothing to be done for all? Huh?

# --------------------------------------------------------------------------------
# Test:
# --------------------------------------------------------------------------------
echo "Testing ..."
PrintRun make test

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install

# --------------------------------------------------------------------------------
# Setup cpan:
# --------------------------------------------------------------------------------
actualCpanExe=$(which cpan)
if [ "$actualCpanExe" != "$INSTALL_DIR/bin/cpan" ]
then
  echo "ASSERTION FAILED: cpan should be at"
  echo "            $INSTALL_DIR/bin/cpan"
  echo "          but we instead got "
  echo "            $actualCpanExe"
  exit 1
fi

################################################################################
# Note: Attempt fully unattended Perl installation on Linux systems that
# always are behind the main Perl distribution. We can do this to
# get some level of unattended processing:
#
#     (echo "yes"; echo "yes") | cpan Bundle::CPAN
#
# But that gets foiled with the tests that run in Term-ReadLine-Perl:
#    
#    Checking if your kit is complete...
#    Looks good
#    Writing Makefile for Term::ReadLine
#    Writing MYMETA.yml and MYMETA.json
#    cp ReadLine/Perl.pm blib/lib/Term/ReadLine/Perl.pm
#    cp ReadLine/readline.pm blib/lib/Term/ReadLine/readline.pm
#      ILYAZ/modules/Term-ReadLine-Perl-1.0303.tar.gz
#      /usr/bin/make -- OK
#    Running make test
#    PERL_DL_NONLAZY=1 /home/someuser/install/Debian.wheezy_sid.3.2.0-3-amd64.x86_64/bin/perl "-Iblib/lib" "-Iblib/arch" test.pl
#    Use of uninitialized value $ENV{"PERL_RL_TEST_PROMPT_MINLEN"} in bitwise or (|) at test.pl line 33.
#     at test.pl line 33.
#    Features present: preput 1 getHistory 1 addHistory 1 attribs 1 ornaments 1 appname 1 minline 1 autohistory 1 newTTY 1 tkRunning 1 setHistory 1
#    
#      Flipping rl_default_selected each line.
#    
#    	Hint: Entering the word
#    		exit
#    	would exit the test. ;-)  (If feature 'preput' is present,
#    	this word should be already entered.)
#    
#    Enter arithmetic or Perl expression: 1+1
#    2
#    Enter arithmetic or Perl expression: 2+2
#    4
#    Enter arithmetic or Perl expression: exit
#      ILYAZ/modules/Term-ReadLine-Perl-1.0303.tar.gz
#      /usr/bin/make test -- OK
#    
# Therefore, we whack all of these silly hanging prompts with a
# Size 11 Hammer: The following Tcl Expect script:
echo Executing $PACKAGE_DIR/automate_cpan_setup.tcl 
$PACKAGE_DIR/automate_cpan_setup.tcl $(pwd)/build.log </dev/null

# --------------------------------------------------------------------------------
# Testing the installation:
# --------------------------------------------------------------------------------
echo "Testing the installation ..."
perlExe="$INSTALL_DIR/bin/perl"
if [ ! -f "$perlExe" ]
then
  echo "ERROR: Could not find expected perl executable file at: $perlExe"
  exit 1
fi
echo "Note: All installation tests passed."
exit 0
