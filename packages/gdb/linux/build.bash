#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-

# Find the base directory while avoiding subtle variations in $0:
dollar0=`which $0`; PACKAGE_DIR=$(cd $(dirname $dollar0); pwd) # NEVER export PACKAGE_DIR

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables and
# utility functions such as BuildDependentPackage:
. $PACKAGE_DIR/../../../support-files/build_platform_util.bash

usage ()
{
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

  Override the INSTALL_DIR default, which is $INSTALL_DIR.

EOF
}

CLEAN=0
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
  elif [ "$1" = "-clean" ]
  then
    CLEAN=1
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
# For debugging packages like Qt5, we require gdb to depend upon
# python (see subsequent comments about python later on in this
# script):
BuildDependentPackage python bin/python
#
# Save building with guile dependency for later. I need python, not guile. So I will build without it later in configure:
#
#    # Build dependency upon guile:
#    # Without it, build of gdb-7.12.1 fails with:
#    #
#    #    g++ -g -O2   -I. -I. -I./common -I./config -DLOCALEDIR="\"/home/CENSORED/install/RHEL.6.6.x86_64/share/locale\"" -DHAVE_CONFIG_H -I./../include/opcode -I./../opcodes/.. -I./../readline/.. -I./../zlib -I../bfd -I./../bfd -I./../include -I../libdecnumber -I./../libdecnumber  -I./gnulib/import -Ibuild-gnulib/import   -DTUI=1   -pthread -I/home/CENSORED/install/RHEL.6.6.x86_64/include/guile/2.2 -I/home/CENSORED/install/RHEL.6.6.x86_64/include -I/home/CENSORED/install/RHEL.6.6.x86_64/include/python2.7 -I/home/CENSORED/install/RHEL.6.6.x86_64/include/python2.7 -Wall -Wpointer-arith -Wno-unused -Wunused-value -Wunused-function -Wno-switch -Wno-char-subscripts -Wempty-body -Wunused-but-set-parameter -Wunused-but-set-variable -Wno-sign-compare -Wno-write-strings -Wformat-nonliteral  -c -o scm-ports.o -MT scm-ports.o -MMD -MP -MF .deps/scm-ports.Tpo ./guile/scm-ports.c
#    #    ./guile/scm-ports.c: In function ‘scm_unused_struct* ioscm_open_port(scm_t_bits, long int)’:
#    #    ./guile/scm-ports.c:139: error: ‘scm_new_port_table_entry’ was not declared in this scope
#    #    ./guile/scm-ports.c: In function ‘int ioscm_fill_input(scm_unused_struct*)’:
#    #    ./guile/scm-ports.c:224: error: ‘SCM_PTAB_ENTRY’ was not declared in this scope
#    #    ./guile/scm-ports.c:233: error: invalid use of incomplete type ‘struct scm_t_port’
#    #    /home/CENSORED/install/RHEL.6.6.x86_64/include/guile/2.2/libguile/ports.h:82: error: forward declaration of ‘struct scm_t_port’
#    #
#    # If it becomes too difficult, just give up: gdb-7.12.1/gdb/doc/guile.texi says we can turn it off via:
#    #
#    #    This feature is available only if @value{GDBN} was configured using
#    #    @option{--with-guile}.
#    #    
#    BuildDependentPackage guile bin/guile
#

# --------------------------------------------------------------------------------
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir gdb

# --------------------------------------------------------------------------------
# Download the source into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
# Determine the most recent tarball file:
tarbasefile=$(wget http://ftp.gnu.org/gnu/gdb/ -O - \
  | grep 'href=' \
  | grep '\.tar\.gz"' \
  | tr '"' '\012' \
  | grep '^gdb' \
  | sed 's%-%-.%g' \
  | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n \
  | sed 's%-\.%-%g' \
  | tail -1)
echo "tarbasefile==\"${tarbasefile}\""
if [ ! -f "$tarbasefile" ]
then
  PrintRun wget http://ftp.gnu.org/gnu/gdb/$tarbasefile
  if [ ! -f "$tarbasefile" ]
  then
    echo "ERROR: Could not retrieve $tarbasefile"
    exit 1
  fi
fi

subdir=$(tar tf $tarbasefile 2>/dev/null | sed -n '1{s%/.*$%%gp; q}')

# --------------------------------------------------------------------------------
# Cleaning:
# --------------------------------------------------------------------------------
if [ "$CLEAN" = 1 ]
then
  echo "Cleaning ..."
  PrintRun rm -rf $subdir
fi

# --------------------------------------------------------------------------------
# Extracting:
# --------------------------------------------------------------------------------
echo "Extracting ..."
if [ ! -d "$subdir" ]
then
  PrintRun tar zxvf $tarbasefile
  if [ ! -d "$subdir" ]
  then
    echo "ERROR: Could not extract `pwd`/$tarbasefile because $subdir does not exist as a directory."
    exit 1
  fi
fi

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
echo "Building and installing ..."
PrintRun cd $HEAD_DIR/$subdir
if [ ! -f configure ]
then
  echo "ASSERTION FAILED: configure file not found"
  exit 1
fi

#
# We need python built into gdb (for Qt5 pretty printing for in
# http://stackoverflow.com/questions/10492290/gdb-pretty-printers-for-qt5
# using http://stackoverflow.com/a/31766741/257924 which refers to
# https://github.com/Lekensteyn/qt5printers which led to the post at
# http://stackoverflow.com/questions/42571014/what-version-of-gdb-provides-the-gdb-printing-python-module)
# but it should hopefully pick up the new version of python by default
# because of the following blurb inside gdb-7.12/gdb/README:
#
#    `--with-python[=PATH]'
#         Build GDB with Python scripting support.  (Done by default if
#         libpython is present and found at configure time.)  Python makes
#         GDB scripting much more powerful than the restricted CLI
#         scripting language.  If your host does not have Python installed,
#         you can find it on http://www.python.org/download/.  The oldest
#         version of Python supported by GDB is 2.4.  The optional argument
#         PATH says where to find the Python headers and libraries; the
#         configure script will look in PATH/include for headers and in
#         PATH/lib for the libraries.
#
# That should work since we are forcing python package as a dependency
# earlier in this script.
#
# Also, disable building with guile for now (see guile comments earlier in the script).
#
PrintRun ./configure --prefix="$INSTALL_DIR" --with-guile=no
PrintRun make

# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
echo "Installing ..."
PrintRun make install




