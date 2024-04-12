#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash
. $PACKAGE_DIR/../../../support-files/pkg_config_util.bash

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
# Verify or build the system-supplied prerequisites:
# --------------------------------------------------------------------------------

function install_packages_ubuntu {

  # Use the apt system to get the build dependencies.
  #
  #   This is what worked as of 2021-09-26.08-29-40 on Ubuntu 20.04
  #   
  
  # I don't want to have to do this as it requires a prompt for passwords, but I don't know of any other way to just get the @#$% dependencies already:
  xterm -fn 9x15 -title 'Getting Emacs dependent packages' -e '
    set -x

    # https://emacs.stackexchange.com/questions/60062/ubuntu-27-1-install-needs-x-libraries#comment94341_60070
    sudo apt-get install build-essential texinfo libx11-dev libxpm-dev libjpeg-dev libpng-dev libgif-dev libtiff-dev libgtk2.0-dev libncurses-dev gnutls-dev libgtk-3-dev libxml2-dev

    # Compile with native JSON:
    #
    #   Per https://www.reddit.com/r/emacs/comments/gzoicx/comment/ftirn3q/?utm_source=share&utm_medium=web2x&context=3: "If you want to try the builtin json parsing youll need to install libjansson". 
    #
    #   From https://www.masteringemacs.org/article/speed-up-emacs-libjansson-native-elisp-compilation#:~:text=heavy%20user%20of%20lsp%2Dmode :
    #
    #     If you’re a heavy user of lsp-mode or eglot then I highly recommend you upgrade for that reason alone.
    #
    #   You can manually verify that the build has the native JSON using:
    #   https://www.masteringemacs.org/article/speed-up-emacs-libjansson-native-elisp-compilation#:~:text=is%20*not*%20available%22))-,And%20for%20the%20JSON,-%3A
    #
    # It turns out that there does not need to be a ./configure flag of --with-json as it seems to use it by default if the libjansson-dev package is installed.
    sudo apt install libjansson-dev

    echo Press return to continue the build:
    read dummy
    '
}

function install_packages_rhel {

  # This is what worked on RHEL8 that does not use the apt system, AFAIK.

  # For RHEL6, I think I need these packages installed which I now have
  # to ask the admins to do:
  #
  #   librsvg2-devel
  #   dbus
  #   atk-devel
  #   cairo-devel
  #   libXi-devel
  #   pango-devel
  #   gtk2-devel
  #   ncurses-devel
  #   libXpm-devel
  #   giflib-devel
  #   libtiff-devel
  #   bitstream-vera-fonts <-- not any more; see git controlled .fonts directory
  #
  # But here is what the admins actually found on 2012-10-19:
  #
  #   All of the packages below were on the RHEL6 system by default, except for:
  #   
  #   giflib-devel
  #   libtiff-devel
  #   bitstream-vera-fonts
  #   
  #   libtiff-devel is part of the distribution, the admin will have to
  #   add that to the system.
  #   
  #   giflib-devel is no longer part of the ISO distribution but RedHat
  #   does carry it in one of the repositories on their site, so the
  #   admin will have to install it on the system.
  #   
  #   bitstream-vera-fonts is not available for RHEL6, but my hackaround
  #   was to just copy them from a Debian wheezy/sid release and store
  #   them under git under ~/.fonts (they are platform-independent files
  #   anyhow, and I could not find the right CentOS RPM to scavenge them
  #   from!).
  #
  #   Sun Apr 23 09:58:08 PDT 2017: libpng is not on RHEL 6.8 by default
  #   so it is now added as a build dependency below.


  if ! which git >/dev/null
  then
    echo "ERROR: git executable not found in the PATH."
  fi

  if [ ! -f /usr/include/X11/X.h ]
  then
    echo "ERROR: You must install development headers for X"
    echo "       On Debian, maybe the package is libx11-dev"
    echo "       On Ubuntu, maybe the package is x11proto-core-dev"
  fi

  # Disabled svg_config_options code for now as it does not seem to adversely impact the build:
  # svg_config_options="--without-rsvg"
  # if [ "$DO_SVG" = 1 ]
  # then
  #   svg_config_options=""
  #   # From http://linux.derkeiler.com/Mailing-Lists/Debian/2008-12/msg02185.html
  #   # we see:
  #   #
  #   #  Assuming that you have a suitable deb-src line in your sources.list, you
  #   #  can simply use "apt-get build-dep emacs22" to install the needed
  #   #  packages. You also may want to install librsvg2-dev and libdbus-1-dev
  #   #  for SVG and Dbus support that is new in Emacs 23.
  #   files=`ls -d /usr/include/librsvg*/librsvg/rsvg.h 2>/dev/null`
  #   if [ -z "$files" ]
  #   then
  #     echo "ERROR: rsvg.h header is missing from the system."
  #     echo "       On Debian, maybe the package is librsvg2-dev"
  #     echo "       On RHEL, maybe the package is librsvg2-devel"
  #     exit 1
  #   fi
  # fi

  if [ ! -f /usr/include/dbus-1.0/dbus/dbus.h ]
  then
    echo "ERROR: dbus.h is missing from the system."
    echo "       On Debian, maybe the package is libdbus-1-dev"
    echo "       On RHEL, maybe the package is dbus"
    exit 1
  fi

  # About this error that can occur:
  #
  #    configure: error: No package 'gtk+-3.0' found
  #    No package 'glib-2.0' found
  #
  # See later on where we include both system and locally built
  # directories into the value of PKG_CONFIG_PATH that pkg-config sees
  # during ./configure execution.
  # 
  # Therefore, test for the existence of GTK headers. Here, we are using
  # either GTK2 or GTK3 headers. Note ./configure searches for GTK3
  # headers first, then GTK2 headers, when --with-x-toolkit is specified
  # (versus us specifying --with-x-toolkit=gtk3). we look for both GTK2
  # and GTK3 because ideally we would not have to request admins to
  # install gtk3 on RHEL6 systems if we can avoid it (and it is not
  # apparent if gtk3 is needed on RHEL6 for Emacs).
  if [ -z "$(ls -d /usr/include/gtk-[23].0/gtk/gtk.h 2>/dev/null)" ]
  then
    echo "ERROR: gtk.h is missing from the system."
    echo "       On Debian, maybe the package is libgtk-3-dev"
    echo "       On RHEL, maybe the packages to install are: atk-devel cairo-devel libXi-devel pango-devel gtk3-devel"
    exit 1
  fi

  if [ ! -f /usr/include/ncurses.h ]
  then
    echo "ERROR: ncurses.h is missing from the system."
    echo "       On Debian, maybe the package is libncurses-dev"
    echo "       On RHEL, maybe the package to install is libncurses5-dev"
    exit 1
  fi

  if [ ! -f /usr/include/X11/xpm.h ]
  then
    echo "ERROR: xpm.h is missing from the system."
    echo "       On Debian, maybe the package is libxpm-dev"
    echo "       On RHEL, maybe the package to install is libXpm-devel"
    exit 1
  fi

  gif_config_options=""
  if [ "$WITH_GIF" = 1 ]
  then
    if [ ! -e /usr/lib64/libungif.so -a ! -e /usr/lib/libungif.so ]
    then
      echo "ERROR: gif libraries are missing from the system."
      echo "       On Debian, maybe the package is libgif-dev"
      echo "       On RHEL, maybe the package to install is giflib-devel"
      exit 1
    fi
  else
    # I added --without-gif because on RHEL6.4 gif is not there. Temporary
    # hack until we decide we need to build it from source.
    gif_config_options="--without-gif"
  fi

  tiff_config_options=""
  if [ "$WITH_TIFF" = 1 ]
  then
    files=`ls -d /usr/lib/x86_64-linux-gnu/libtiff.so /usr/lib64/libtiff.so 2>/dev/null`
    if [ -z "$files" ]
    then
      echo "ERROR: libtiff headers are missing from the system."
      echo "       On Debian, maybe the package is libtiff4-dev"
      echo "       On RHEL, maybe the package to install is libtiff-devel"
      exit 1
      # rpm -q --whatprovides libtiff-devel
      # rpm -q -l libtiff-devel-3.9.4-1.el6_0.3.x86_64
    fi
  else
    # I added --with-tiff=no because on RHEL6.4 tiff is not there. Temporary
    # hack until we decide we need to build it from source.
    #
    # Sun Apr 23 12:22:53 PDT 2017: The INSTALL file in the emacs
    # distribution has a path to a URL that is dead so we will continue
    # to just not have tiff support if they are going to maintaining it
    # on a solid server, like GitHub.
    #
    tiff_config_options="--with-tiff=no"
  fi

  BuildDependentPackage autoconf bin/autoconf
  BuildDependentPackage automake bin/automake
  BuildDependentPackage texinfo bin/makeinfo
  BuildDependentPackage pkg-config bin/pkg-config
  BuildDependentPackage zlib include/zlib.h
  BuildDependentPackage libpng lib/pkgconfig/libpng\*.pc
  BuildDependentPackage make bin/make # because GNU make 3.80 that is default in RHEL6 has a buggy (or ...) operator
  # Try building with gtk now that I'm running RHEL 6.8 which should have the gtk headers: 
  ###echo "TODO: build gtk as a dependency: BuildDependentPackage gtk bin/fixmeforgtk"; exit 1

}

if lsb_release -i | grep -q Ubuntu
then
  install_packages_ubuntu
elif lsb_release -i | grep -qE 'RedHatEnterprise|Rocky'
then
  install_packages_rhel
else
  echo "ASSERTION FAILED: Unknown release: $(lsb_release -i)"
  exit 1
fi

# The xft stuff may have problems on older Linux systems but require
# it since this is primarily geared for building an X11 version of
# Emacs:
xft_option="--with-xft"


# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir emacs

# --------------------------------------------------------------------------------
# Download and build tarball into the build directory:
# --------------------------------------------------------------------------------
# The V variable referenced by the Emacs configure script to enable
# verbose output of compile lines, which we need in order to debug
# compile failures:
export V=1

# zlib.h is still not found when compiling decompress.c, so I have to hack with this CFLAGS setting:
export CFLAGS="-I$INSTALL_DIR/include"

# Hack in the -L options from libpng which are not recognized by the configure script (bug?):
libpng_ldflags="$(libpng-config --L_opts)"

# But libraries like libpng###.so will not be found at runtime unless you use an RPATH:
#
#   The reason Linux distributions do not use an RPATH is that they
#   instead use ld.conf.so. You can see this via 
#
#      objdump -x path_to_some_executable | grep RPATH
#
#   Emacs on those distributions thus do not have an RPATH. See
#   https://gcc.gnu.org/ml/gcc-help/2005-12/msg00017.html for details.
#
rpath_options="-Wl,-rpath=$INSTALL_DIR/lib"

# Sigh. You cannot pass LDFLAGS to the ./configure command line. It
# does some weird expansion and trips up on it. So we HAVE to export
# it as an environment variable:
export LDFLAGS="$libpng_ldflags $rpath_options"

# Disable libgif for now (why it is listed as an "X" for X11 in the
# INSTALL file I don't know). Are playing gifs inside Emacs really
# necessary?
libgif_config_options="--with-gif=no"

# Add system-defined directories to PKG_CONFIG_PATH:
#
#   This is needed in order to find xft and fontconfig packages (maybe
#   more than that):
#
Add_System_Defined_PKG_CONFIG_PATH

DownloadExtractBuildGnuPackage emacs "$libgif_config_options;$tiff_config_options;$xft_option"

# Experiment with:
# bash -c '
# export BUILD_DIR=$HOME/build/RHEL.6.8.x86_64.for_emacs;
# export INSTALL_DIR=$HOME/install/RHEL.6.8.x86_64.for_emacs;
# $HOME/bgoodr/build-locally/packages/emacs/linux/build.bash -clean
# '

# --------------------------------------------------------------------------------
# Testing:
# --------------------------------------------------------------------------------
echo "Testing ..."

emacsExe="$INSTALL_DIR/bin/emacs"
if [ ! -f "$emacsExe" ]
then
  echo "ERROR: Could not find expected executable at: $emacsExe"
  exit 1
fi

# Determine the expected version from the ./configure file:
expected_emacs_version=$(sed -n "s%^ *PACKAGE_VERSION='\\([^']*\\)'.*\$%\\1%gp" < configure);
if [ -z "$expected_emacs_version" ]
then
  echo "ASSERTION FAILED: Could not determine expected emacs version."
  exit 1
fi

# Determine the actual version we built:
actual_emacs_version=$($emacsExe --batch --quick --eval '(prin1 emacs-version t)')

# Use the first two numbers of the version. The 3rd and subsequent numbers gets added by
# something in the build (how? the makefiles are obfuscated) and we
# don't care about that. And if you run make then make install, that
# number gets bumped again.
echo "Original actual_emacs_version is \"${actual_emacs_version}\"."
actual_emacs_version=$(echo "$actual_emacs_version" | sed -e 's/"//g' -e 's%^\([0-9]*\.[0-9]*\).*$%\1%g' )
echo "Trimmed actual_emacs_version is \"${actual_emacs_version}\"."

# Now compare:
if [ "$expected_emacs_version" != "$actual_emacs_version" ]
then
  echo "ERROR: Failed to build expected emacs version: $expected_emacs_version"
  echo "                         actual emacs version: $actual_emacs_version"
  exit 1
fi
echo "Note: All installation tests passed. Emacs version $actual_emacs_version was built and installed."
exit 0
