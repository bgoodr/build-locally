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
# Create build directory structure:
# --------------------------------------------------------------------------------
CreateAndChdirIntoBuildDir freecad


# http://freecadweb.org/wiki/index.php?title=CompileOnUnix#Compile_FreeCAD

# This will work only for Debian systems. Later on we can rework this to build completely from source:

# TODO: See if we can build all of these from source, or use my Debian
# source package routines as done in ../../sqlite3/linux/build.bash

# Set BUILD_LOCALLY_FREECAD_DO_DEBIAN_PACKAGE_INSTALLS=0 in the
# environment for skipping this lengthy process of installing Debian
# packages if you have just done it already (for debugging the build) :
BUILD_LOCALLY_FREECAD_DO_DEBIAN_PACKAGE_INSTALLS=${BUILD_LOCALLY_FREECAD_DO_DEBIAN_PACKAGE_INSTALLS:=1}

if [ "$BUILD_LOCALLY_FREECAD_DO_DEBIAN_PACKAGE_INSTALLS" = "1" ]
then
  tmpscript=$(pwd)/tmpscript.$$
  trap "rm -f $tmpscript" 0 # arrange to remove $tmpscript upon failure

  set -x

  cat > $tmpscript <<EOF
set -x -e

# --------------------------------------------------------------------------------
# apt-get update <-- It is not certain if this helps with missing packages
# --------------------------------------------------------------------------------

apt-get install -y build-essential
apt-get install -y cmake
apt-get install -y python
apt-get install -y python-matplotlib
apt-get install -y libtool

# --------------------------------------------------------------------------------
# Now getting this error:
# Building dependency tree       
# Reading state information... Done
# E: Unable to locate package libcoin80-dev
# + rm -f /home/brentg/build/Debian.7.x86_64/freecad/tmpscript.4338
# + exit -1
# 
# I cannot find libcoin80-dev. Try apt-get update. No that does not work.
#
# See if using python-pivy http://forum.freecadweb.org/viewtopic.php?f=4&t=5096#p40018 will work around it.
# It might: python-pivy depends upon libcoin60. Also libsoqt4-dev depends upon libcoin60-dev.
# apt-get install -y libcoin80-dev <-- this does not work on Wheezy for some reason.
apt-get install -y python-pivy  # <-- this does work and is dependent upon libcoin60
# But that leaves us with the outstanding question: What are we missing
# out on if we install libcoin60 and not libcoin80? Is libcoin80
# "better"?
# --------------------------------------------------------------------------------

apt-get install -y libsoqt4-dev
apt-get install -y libxerces-c-dev
apt-get install -y libboost-dev
apt-get install -y libboost-filesystem-dev
apt-get install -y libboost-regex-dev
apt-get install -y libboost-program-options-dev 
apt-get install -y libboost-signals-dev
apt-get install -y libboost-thread-dev
apt-get install -y libqt4-dev
apt-get install -y libqt4-opengl-dev
apt-get install -y qt4-dev-tools
apt-get install -y python-dev
apt-get install -y python-pyside

# --------------------------------------------------------------------------------
# apt-get install -y liboce*-dev (opencascade community edition) <-- huh? They didn't spell out which ones are in the "*"???
apt-get install -y liboce-foundation-dev
apt-get install -y liboce-modeling-dev
apt-get install -y liboce-ocaf-dev
# apt-get install -y liboce-ocaf-lite-dev # <-- huh? What is this lite thing huh whuh?
apt-get install -y liboce-visualization-dev
# --------------------------------------------------------------------------------

apt-get install -y oce-draw
apt-get install -y gfortran
apt-get install -y libeigen3-dev
apt-get install -y libqtwebkit-dev
apt-get install -y libshiboken-dev
apt-get install -y libpyside-dev
apt-get install -y libode-dev
apt-get install -y swig
apt-get install -y libzipios++-dev
apt-get install -y libfreetype6
apt-get install -y libfreetype6-dev

# --------------------------------------------------------------------------------
# Extra packages:
apt-get install -y libsimage-dev                 # <-- (to make Coin to support additional image file formats)
#apt-get install -y checkinstall                 # <-- (to register your installed files into your system's package manager, so yo can easily uninstall later)
#apt-get install -y python-pivy                  # <-- (needed for the 2D Drafting module) (ALREADY INSTALLED ABOVE)
apt-get install -y python-qt4                    # <-- (needed for the 2D Drafting module)
apt-get install -y doxygen libcoin60-doc         # <-- (if you intend to generate source code documentation)
#apt-get install -y libspnav-dev                 # <-- (for 3Dconnexion devices support like the Space Navigator or Space Pilot) (I DON'T HAVE SUCH A DEVICE SO EXCLUDING THIS)
# --------------------------------------------------------------------------------
EOF

  chmod a+x $tmpscript
  sudo sh -c $tmpscript
  
fi

# --------------------------------------------------------------------------------
# Download the source for freecad into the build directory:
# --------------------------------------------------------------------------------
echo "Downloading ..."
# http://freecadweb.org/wiki/index.php?title=CompileOnUnix#Getting_the_source

# --------------------------------------------------------------------------------
# Check out the source for freecad into the build directory:
# --------------------------------------------------------------------------------
packageSubDir=free-cad-code
DownloadPackageFromGitRepo git://git.code.sf.net/p/free-cad/code $packageSubDir

# --------------------------------------------------------------------------------
# Build:
# --------------------------------------------------------------------------------
# Per http://forum.freecadweb.org/viewtopic.php?f=4&t=5096#p40018 we see:
#
#   Ah, now I see. On debian based systems there is no need to build
#   the shipped pivy sources because a package already exists, called
#   python-pivy. Install this one and then disable the build of the
#   local pivy by setting FREECAD_USE_EXTERNAL_PIVY on.
#
#
# Do an Out-of-source build as indicated on
# http://freecadweb.org/wiki/index.php?title=CompileOnUnix#Out-of-source_build
#
#
#
# --------------------------------------------------------------------------------
# For this error:
#
#     [ 34%] Building CXX object src/Main/CMakeFiles/FreeCADMainCmd.dir/MainCmd.cpp.o
#     Linking CXX executable ../../bin/FreeCADCmd
#     ../../lib/libFreeCADBase.so: undefined reference to `PyCapsule_New'
#     ../../lib/libFreeCADBase.so: undefined reference to `PyCapsule_GetPointer'
#     ../../lib/libFreeCADBase.so: undefined reference to `PyCapsule_Import'
#     collect2: error: ld returned 1 exit status
#
# This is the same error explained at http://forum.freecadweb.org/viewtopic.php?f=4&t=5130#p40320
#
# Find the references:
#
#    grep -i python ~/build/Debian.7.x86_64/freecad/freecad-build/CMakeCache.txt
#    // the Python import module.
#    //Use system installed python-pivy instead of the bundled.
#    FreeCADBase_LIB_DEPENDS:STATIC=general;/usr/lib/python2.6/config/libpython2.6.so;general;/usr/lib/x86_64-linux-gnu/libxerces-c.so;general;/usr/lib/x86_64-linux-gnu/libQtCore.so;general;/usr/lib/libboost_filesystem-mt.so;general;/usr/lib/libboost_program_options-mt.so;general;/usr/lib/libboost_regex-mt.so;general;/usr/lib/libboost_signals-mt.so;general;/usr/lib/libboost_system-mt.so;general;/usr/lib/libboost_thread-mt.so;general;pthread;general;/usr/lib/x86_64-linux-gnu/libz.so;general;-lutil;general;-ldl;
#    FreeCADGui_LIB_DEPENDS:STATIC=general;FreeCADBase;general;FreeCADApp;general;/usr/lib/libCoin.so;general;/usr/lib/libSoQt.so;general;/usr/lib/x86_64-linux-gnu/libQtOpenGL.so;general;/usr/lib/x86_64-linux-gnu/libQtSvg.so;general;/usr/lib/x86_64-linux-gnu/libQtUiTools.a;general;/usr/lib/x86_64-linux-gnu/libQtWebKit.so;general;/usr/lib/x86_64-linux-gnu/libQtXmlPatterns.so;general;/usr/lib/x86_64-linux-gnu/libQtGui.so;general;/usr/lib/x86_64-linux-gnu/libQtXml.so;general;/usr/lib/x86_64-linux-gnu/libQtNetwork.so;general;/usr/lib/x86_64-linux-gnu/libQtCore.so;general;/usr/lib/libboost_filesystem-mt.so;general;/usr/lib/libboost_program_options-mt.so;general;/usr/lib/libboost_regex-mt.so;general;/usr/lib/libboost_signals-mt.so;general;/usr/lib/libboost_system-mt.so;general;/usr/lib/libboost_thread-mt.so;general;pthread;general;/usr/lib/x86_64-linux-gnu/libGL.so;general;/usr/lib/x86_64-linux-gnu/libshiboken-python2.7.so;general;/usr/lib/x86_64-linux-gnu/libpyside-python2.7.so;
#    PYTHON_EXECUTABLE:FILEPATH=/usr/bin/python
#    PYTHON_INCLUDE_DIR:PATH=/usr/include/python2.7
#    PYTHON_LIBRARY:FILEPATH=/usr/lib/python2.6/config/libpython2.6.so
#    //Details about finding PythonInterp
#    FIND_PACKAGE_MESSAGE_DETAILS_PythonInterp:INTERNAL=[/usr/bin/python][v2.7.3()]
#    //Details about finding PythonLibs
#    FIND_PACKAGE_MESSAGE_DETAILS_PythonLibs:INTERNAL=[/usr/lib/python2.6/config/libpython2.6.so][/usr/include/python2.7][v2.7.3(2.7.3)]
#    //ADVANCED property for variable: PYTHON_EXECUTABLE
#    PYTHON_EXECUTABLE-ADVANCED:INTERNAL=1
#    //ADVANCED property for variable: PYTHON_INCLUDE_DIR
#    PYTHON_INCLUDE_DIR-ADVANCED:INTERNAL=1
#    //ADVANCED property for variable: PYTHON_LIBRARY
#    PYTHON_LIBRARY-ADVANCED:INTERNAL=1
#    
# Looks like PYTHON_LIBRARY:FILEPATH is 2.6 and we need 2.7.
#
# Helpful info at http://forum.freecadweb.org/viewtopic.php?f=4&t=5130
#
# From cmake man page:
#
#   -D <var>:<type>=<value>
#          Create a cmake cache entry.
#  
#          When cmake is first run in an empty build tree, it creates
#          a CMakeCache.txt file and populates it with customizable
#          settings for the project.  This option may be used to
#          specify a setting that takes priority over the project's
#          default value.  The option may be repeated for as many
#          cache entries as desired.
#
# So perhaps we can reconfigure the python lookup by cmake directives.
#
# I installed cmake-doc so that I could examine "FindPythonLibs" at:
#
#   file:///usr/share/doc/cmake-data/cmake-gui.html#module:FindPythonLibs
#
# which says:
#
#     If you'd like to specify the installation of Python to use, you should modify the following cache variables:
#
#       PYTHON_LIBRARY             - path to the python library
#       PYTHON_INCLUDE_DIR         - path to where Python.h is found
#
# I see Python_ADDITIONAL_VERSIONS being set by ~/build/Debian.7.x86_64/freecad/free-cad-code/CMakeLists.txt
#
# But, why do I have both python 2.6 stuff and python 2.7 stuff in the system?
#
# Search for it:
#
#    apt-file search /usr/lib/python2.6/config/libpython2.6.so
#    libpython2.6: /usr/lib/python2.6/config/libpython2.6.so
#
# Tried removing the CMakeCache.txt and setting 
#
#  -DPython_ADDITIONAL_VERSIONS:STRING="2.7"
#
# on the cmake command line and cmake insists on finding the 2.6 .so
# file. So that did not work.
# 
# Now have to manually patch the cmake file in the source tree using sed. :(
# --------------------------------------------------------------------------------
# packageSubDir is the path to the source folder we pulled from git earlier.
sed -i 's%set(Python_ADDITIONAL_VERSIONS [^)]*)%set(Python_ADDITIONAL_VERSIONS "2.7")%g' $packageSubDir/CMakeLists.txt
#
# Now build:
#
echo "Building ..."
PrintRun mkdir -p freecad-build
PrintRun cd freecad-build
# --------------------------------------------------------------------------------
# Per
# http://stackoverflow.com/questions/17445857/clear-cmakes-internal-cache
# we want to remove the cache file to force cmake to respect our
# changes on the cmake command line:
# --------------------------------------------------------------------------------
PrintRun rm -f CMakeCache.txt 

PrintRun cmake \
  -DFREECAD_USE_EXTERNAL_PIVY=ON ../$packageSubDir
PrintRun make




# --------------------------------------------------------------------------------
# Install:
# --------------------------------------------------------------------------------
# Huh? Whuh? No documentation on how to install it inside http://freecadweb.org/wiki/index.php?title=CompileOnUnix#Compile_FreeCAD ???
echo "Installing ..."
# ???

