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
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir flameshot

# --------------------------------------------------------------------------------
# Acquire dependencies:
#
#   This will necessarily be Debian (or Debian-derived) specific as
#   that is what I need the most right now.
#
# --------------------------------------------------------------------------------

# Avoid installing packages if they are already installed
#
#   Because: it is annoying to have to answer a prompt inside an xterm if there was nothing to do
#
#   When SKIP_CHECK_FOR_NEEDED_PACKAGES is set to 1, just skip it
#   because apt list is dog slow, and for development of this script,
#   we know we did the dependency check already.
#
test "$SKIP_CHECK_FOR_NEEDED_PACKAGES" = 1 || {
  needed_packages=$(
    (
      cat <<'EOF'
  # Compile-time
  g++ cmake build-essential qtbase5-dev qttools5-dev-tools libqt5svg5-dev qttools5-dev
  
  # Run-time
  libqt5dbus5 libqt5network5 libqt5core5a libqt5widgets5 libqt5gui5 libqt5svg5
  
  # Optional
  git openssl ca-certificates
EOF
    ) |
      # Noise removal (to allow us to have comments as to the packages) :
      grep -v -E '^ *#|^ *$' |
      # Break them up into words, one word per package:
      tr ' ' '\012' |
      # Loop through the packages:
      while read package
      do
        # Only echo the package name if it is NOT installed:
        apt list $package |& grep -q -F '[installed]' || {
          echo $package
        }
      done
    ) 

  test -n "$needed_packages" && {
    tmperrors=$(pwd)/errors.$$
    tmpscript=$(pwd)/tmpscript.$$
    trap "rm -f $tmpscript $tmperrors" 0 # arrange to remove temporary files upon exiting

    cat > $tmpscript <<EOF
#!/bin/bash

# Execute the sudo commands, bailing out immediately:
#
#   The use of the Bash script, fed to the xterm, allows the prompt
#   for a password for the sudo calls. But if the sudo fails (mistyped
#   password), or whatever the failure is caused by, we need to abort
#   the entire script.
#
#   Although, the following construct is cumbersome, but does exactly
#   what is required.  Reference: https://stackoverflow.com/q/76607149/257924
#
bash -c '

  set -x -e

  # --------------------------------------------------------------------------------
  # apt-get update
  #
  #   It is not certain if this helps with missing packages.
  #
  # --------------------------------------------------------------------------------
  sudo apt update
  
  # --------------------------------------------------------------------------------
  # Get the needed_packages:
  #
  #   Reference: https://github.com/flameshot-org/flameshot#debian
  #
  #   But modified to use "-y" option to avoid the evil of annoying questions.
  #
  # --------------------------------------------------------------------------------
  sudo apt install -y $needed_packages
' || {
  touch $tmperrors
}

echo Press return to continue:
read dummy
EOF

    chmod a+x $tmpscript
    rm -f $tmperrors
    export tmperrors

    # Execute $tmpscript inside an xterm so as to allow for the sudo to prompt for the password:
    xterm -fn 9x15 -title 'Getting flameshot dependent packages' -e $tmpscript
    test -f $tmperrors && {
      echo "$0:$LINENO: ERROR: Errors occurred during apt package installation. Exiting."
      exit 1
    }
  }
}

# --------------------------------------------------------------------------------
# Check out the source for flameshot into the build directory:
# --------------------------------------------------------------------------------
# Remove previous version and do not use git pull as then you'll get
# yet again royally hassled with a prompt (see
# 4ad73fdf_d70b_4c3e_82c3_6beef191a53c):
rm -rf flameshot
# Do not do this:
#
#   DownloadPackageFromGitRepo git@github.com:flameshot-org/flameshot.git flameshot
#
# because it prompts for personal access tokens and that is a royal
# hassle (4ad73fdf_d70b_4c3e_82c3_6beef191a53c) if you are not doing development, but just want to build and
# use the tool.
#
DownloadPackageFromGitRepo https://github.com/flameshot-org/flameshot.git flameshot

PrintRun cd flameshot

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building ..."

PrintRun cmake -S . -B build

PrintRun cmake --build build

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun cmake --install build  --prefix "$INSTALL_DIR"

installedBinFile=$INSTALL_DIR/bin/flameshot
if [ ! -f $installedBinFile ]
then
  echo "ERROR: flameshot did not properly install into $installedBinFile"
  exit 1
fi

echo "Note: Compilation and installation succeeded."
exit 0
