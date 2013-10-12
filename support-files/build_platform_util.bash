#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

if [ -z "$PACKAGE_DIR" ]; then echo "ASSERTION FAILED: Calling script always has to dynamically determine and set the PACKAGE_DIR variable."; exit 1 ; fi # see ./PACKAGE_DIR_detect.org

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables:
. $PACKAGE_DIR/../../../support-files/init_vars.bash
# Get the PrintRun utility defined:
. $PACKAGE_DIR/../../../support-files/printrun.bash

EmitStandardUsage () {
  cat <<EOF
USAGE: $0 ... options ...

Options are:

[ -builddir BUILD_DIR ]

  Override the BUILD_DIR default, which is $BUILD_DIR.

[ -installdir INSTALL_DIR ]

  Override the INSTALL_DIR default, which is $INSTALL_DIR.

[ -clean ]

  Build from scratch.

EOF

}

BuildDependentPackage () {
  local dependentPackage="$1"
  local installBase="$2"
  # Allow globbing in $installBase by exploiting ls:
  local files=$(ls $INSTALL_DIR/$installBase 2>/dev/null)
  if [ -z "$files" ]
  then
    echo "( BEGIN BUILDING DEPENDENCY: $installBase provided by $dependentPackage"
    $PACKAGE_DIR/../../../packages/${dependentPackage}/$PLATFORM/build.bash
    exitcode=$?
    echo ") END BUILDING DEPENDENCY: $installBase provided by $dependentPackage"
    if [ "$exitcode" != 0 ]
    then
      echo "ERROR: ${dependentPackage} failed."
      exit 1
    fi
  fi
}

CreateAndChdirIntoBuildDir () {
  local package="$1"
  echo "Creating build directory structure ..."
  HEAD_DIR=$BUILD_DIR/$package
  mkdir -p $BUILD_DIR
  mkdir -p $INSTALL_DIR
  mkdir -p $HEAD_DIR
  PrintRun cd $HEAD_DIR
}

ValidateFileInInstallBinDir () {
  local file="$1"
  export PATH=$INSTALL_DIR/bin:$PATH
  actualLocation=$(which $file)
  if [ ! -f "$INSTALL_DIR/bin/$file" ]
  then
    echo "ERROR: $INSTALL_DIR/bin/$file does not exist which is unexpected"
    exit 1
  else
    echo "Note: $INSTALL_DIR/bin/$file exists which was expected."
  fi
}

VerifySystemPackage () {
  local expected_release_type="$1"
  local package="$2"
  if [ "$expected_release_type" = "Debian" ]
  then
    dpkg-query --status ${package} 2>/dev/null | grep "Status:" | grep "install ok installed" >/dev/null || {
      echo "ERROR: You must install system package $package under root before proceeding, via: apt-get install $package"
      exit 1
    }
  else
    echo "ASSERTION FAILED: VerifySystemPackage not yet implemented on $expected_release_type."
    exit 1
  fi
}

VerifyOperatingSystemPackageContainingFile () {
  local expected_release_type="$1"
  local package="$2"
  local needed_file="$3"
  if [ "$expected_release_type" = "$release_type" ]
  then
    if [ ! -f "$needed_file" ]
    then
      VerifySystemPackage "$expected_release_type" "$package"
    else
      echo "Note: No need to install package \"${package}\" because file \"${needed_file}\" already exists."
    fi
  fi
}

GetDebianSourcePackageTarBalls () {
  local tarballURLPage="$1"
  local downloadFile=`echo "$tarballURLPage" | sed 's%\([^a-zA-Z0-9_-]\)%_%g' `
  if [ ! -f $downloadFile ]
  then
    wget -O - $tarballURLPage > $downloadFile
  else
    echo Note: Skipping download of $tarballURLPage and reusing pre-existing download file: $downloadFile
  fi
  local tarballURLs=`sed -n '/Download Source Package/,$p' < $downloadFile| \
sed -n 's%^.*<a href="\([^"]*\)">.*$%\1%gp' | \
grep tar.gz`
  if [ -z "$tarballURLs" ]
  then
    echo "ERROR: Failed to extract source package tarball URLs from $tarballURLPage"
    exit 1
  fi
  GetDebianSourcePackageTarBalls_return=""
  local tarballURL=""
  for tarballURL in $tarballURLs
  do
    tarballBaseFile=`echo "$tarballURL" | sed 's%^.*/\('"$package"'.*\.tar\.gz\)$%\1%g'`
    if [ ! -f $tarballBaseFile ]
    then
      wget $tarballURL
      if [ ! -f $tarballBaseFile ]
      then
        echo "ERROR: Could not retrieve $tarballBaseFile from $tarballURL"
        exit 1
      fi
    else
      echo Note: Skipping download of $tarballURL and reusing pre-existing tarball: $tarballBaseFile
    fi
    GetDebianSourcePackageTarBalls_return="$GetDebianSourcePackageTarBalls_return $tarballBaseFile"
  done
}

ExtractTarBall () {
  local tarball="$1"
  local expectedFiles="$2"
  local actualFiles=`ls -d $expectedFiles 2>/dev/null`
  if [ -z "$actualFiles" ]
  then
    tar zxvf $tarball
    local actualFiles=`ls -d $expectedFiles 2>/dev/null`
    if [ -z "$actualFiles" ]
    then
      echo "ERROR: Failed to extract $expectedFiles from $tarball!"
      exit 1
    fi
  else
    echo "Note: Skipping extraction of $tarball and reusing pre-existing files: $actualFiles"
  fi
  ExtractTarBall_return="$actualFiles"
}

ExtractDebianSourcePackageTarBalls () {
  local tarballs="$1"
  local expectedFilesOrDirs="$2"
  ExtractDebianSourcePackageTarBalls_returnDebianFileOrDirs=""
  ExtractDebianSourcePackageTarBalls_returnOrigFileOrDirs=""
  local tarball=""
  for tarball in $tarballs
  do
    if expr $tarball : '.*debian\.tar\.gz' >/dev/null
    then
      echo Note: Identified Debian patch tarball: $tarball
      ExtractTarBall $tarball debian
      ExtractDebianSourcePackageTarBalls_returnDebianFileOrDirs="$ExtractTarBall_return"
    elif expr $tarball : '.*orig\.tar\.gz' >/dev/null
    then
      echo Note: Identified original source tarball: $tarball
      ExtractTarBall $tarball "$expectedFilesOrDirs"
      ExtractDebianSourcePackageTarBalls_returnOrigFileOrDirs="$ExtractTarBall_return"
    else
      echo "ASSERTION FAILED: Unexpected type of tarball: $tarball"
      exit 1
    fi
  done
}

AssertNumFilesOrDirs () 
{
  local num="$1"
  local glob="$2"
  if ! expr "$num" = `ls -d $glob 2>/dev/null | wc -l` >/dev/null 2>&1
  then
    local actualFiles=`ls -d $glob 2>/dev/null`
    echo "ASSERTION FAILED: Expected $num file(s) or director(ies) but got: $actualFiles"
    exit 1
  fi
}

ApplyDebianPatches () {
  local debianDir="$1"
  local origDir="$2"
  local skipRegexpList="$3"
  AssertNumFilesOrDirs 1 "$debianDir"
  AssertNumFilesOrDirs 1 "$origDir"
  local patchDir=$debianDir/patches
  local seriesFile=$patchDir/series
  if [ ! -f $seriesFile ]
  then
    echo "ASSERTION FAILED: Expected a Debian patch series file but did not find it at: $seriesFile"
    exit 1
  fi
  # http://www.debian.org/doc/manuals/maint-guide/dother.en.html#patches states:
  # "The order of these patches is recorded in the debian/patches/series file"
  #
  # Skip commented out patches:
  local patches=`grep -v '^[ \t]*#' $seriesFile`
  local patch=""
  for patch in $patches
  do
    local skip=0
    local skipRegexp
    for skipRegexp in $skipRegexpList
    do
      if echo "$patch" | grep "$skipRegexp" >/dev/null
      then
        echo "Note: Skipping patch $patch since it matches $skipRegexp"
        skip=1
        break
      fi
    done
    if [ $skip = 1 ]
    then
      continue
    fi
    local patchCompleteFile=`echo "$patch" | sed 's%\([^a-zA-Z0-9_-]\)%_%g' `
    if [ ! -f $patchCompleteFile ]
    then
      echo
      echo Note: Applying patch $patch
      (cd $origDir; patch -p1 --forward) < $patchDir/$patch
      if [ $? != 0 ]
      then
        echo "ERROR: Patch $patch failed to apply"
        exit 1
      fi
      echo
      touch $patchCompleteFile
    else
      echo Note: Patch $patch already applied
    fi
  done
}

DownloadExtractChdirGnuTarball () {
  local package="$1"
  local packageURL="http://ftp.gnu.org/gnu/${package}/"
  tarbasefile=$(wget $packageURL -O - | \
    grep 'href=' | \
    grep '\.tar\.gz"' | \
    tr '"' '\012' | \
    grep "^${package}" | \
    sed 's%-%-.%g' | \
    sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | \
    sed 's%-\.%-%g' | \
    tail -1)
  if [ -z "$tarbasefile" ]
  then
    echo "ASSERTION FAILED: Could not automatically determine download file from $packageURL"
    exit 1
  fi
  if [ ! -f $tarbasefile ]
  then
    wget http://ftp.gnu.org/gnu/${package}/$tarbasefile
    if [ ! -f $tarbasefile ]
    then
      echo "ERROR: Could not retrieve $tarbasefile"
      exit 1
    fi
  fi
  subdir=`tar tf $tarbasefile 2>/dev/null | sed -n '1{s%/$%%gp; q}'`
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

ConfigureAndBuildGnuPackage () {
  # --------------------------------------------------------------------------------
  # Configuring:
  # --------------------------------------------------------------------------------
  echo "Configuring ..."
  # The distclean command will fail if there the top-level Makefile has not yet been generated:
  if [ -f Makefile ]
  then
    PrintRun make distclean
  fi
  if [ ! -f configure ]
  then
    echo "ASSERTION FAILED: configure file not found"
    exit 1
  fi
  PrintRun ./configure --prefix="$INSTALL_DIR"

  # --------------------------------------------------------------------------------
  # Building:
  # --------------------------------------------------------------------------------
  echo "Building ..."
  PrintRun make

  # --------------------------------------------------------------------------------
  # Installing:
  # --------------------------------------------------------------------------------
  echo "Installing ..."
  PrintRun make install
}
