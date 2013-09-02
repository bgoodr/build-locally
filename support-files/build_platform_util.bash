#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

if [ -z "$PACKAGE_DIR" ]; then echo "ASSERTION FAILED: Calling script always has to dynamically determine and set the PACKAGE_DIR variable."; exit 1 ; fi # see ./PACKAGE_DIR_detect.org

# Set defaults for BUILD_DIR and INSTALL_DIR environment variables:
. $PACKAGE_DIR/../../../support-files/init_vars.bash
# Get the PrintRun utility defined:
. $PACKAGE_DIR/../../../support-files/printrun.bash


builddep () {
  local dependentPackage="$1"
  local installBase="$2"
  # Allow globbing in $installBase by exploiting ls:
  local files=$(ls $INSTALL_DIR/$installBase 2>/dev/null)
  if [ -z "$files" ]
  then
    echo "( BEGIN BUILDING DEPENDENCY: $installBase provided by $dependentPackage"
    $PACKAGE_DIR/../../../tools/${dependentPackage}/$PLATFORM/build.${dependentPackage}.bash
    exitcode=$?
    echo ") END BUILDING DEPENDENCY: $installBase provided by $dependentPackage"
    if [ "$exitcode" != 0 ]
    then
      echo "ERROR: build_${dependentPackage}.sh failed"
      exit 1
    fi
  fi
}

indicate_missing_system_packages ()
{
  local releaseType="$1"
  local pkg="$2"
  if [ -z "$releaseType" ]
  then
    echo "ASSERTION FAILED: releaseType argument is mandatory"
    exit 1
  fi
  if [ -z "$pkg" ]
  then
    echo "ASSERTION FAILED: pkg argument is mandatory"
    exit 1
  fi
  local var="needed_${releaseType}_packages"
  eval "$var=\"\$$var $pkg\""
}

GetOrInstallDebianSystemPackage () {
  local package="$1"
  sudo dpkg-query --status ${package} 2>/dev/null | grep "Status:" | grep "install ok installed" >/dev/null || {
    # the --fix-missing is to hack around this oddity:
    #
    # Err http://ftp.us.debian.org/debian/ wheezy/main libglu1-mesa-dev amd64 7.11.2-1
    #   404  Not Found [IP: 35.9.37.225 80]
    # Failed to fetch http://ftp.us.debian.org/debian/pool/main/m/mesa/libglu1-mesa-dev_7.11.2-1_amd64.deb  404  Not Found [IP: 35.9.37.225 80]
    #
    PrintRun sudo apt-get --fix-missing -y install ${package}
  }
  sudo dpkg-query --status ${package} 2>/dev/null | grep "Status:" | grep "install ok installed" >/dev/null || {
    echo "ASSERTION FAILED: Could not install ${package}"
    exit 1
  }
}

GetOrInstallOperatingSystemPackages ()
{
  if [ "$release_type" = "Debian" ]
  then
    for debianPackage in $*
    do
      GetOrInstallDebianSystemPackage $debianPackage
    done
  else
    echo "ASSERTION FAILED: GetOrInstallOperatingSystemPackages is not yet implemented for release_type==\"${release_type}\""
    exit 1
  fi
}

GetOrInstallOperatingSystemPackageContainingFile ()
{
  local package="$1"
  local neededFile="$2"
  if [ ! -f "$neededFile" ]
  then
    GetOrInstallOperatingSystemPackages "$package"
    if [ ! -f "$neededFile" ]
    then
      echo "ERROR: Failed to install package \"${package}\" because file \"${neededFile}\" still does not exist."
      exit 1
    fi
  else
    echo "Note: No need to install package \"${package}\" because file \"${neededFile}\" already exists."
  fi
}

GetDebianSourcePackageTarBalls ()
{
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

ExtractTarBall ()
{
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

ExtractDebianSourcePackageTarBalls ()
{
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

ApplyDebianPatches ()
{
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

