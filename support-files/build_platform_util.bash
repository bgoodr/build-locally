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
  actualLocation=$(export PATH=$INSTALL_DIR/bin:$PATH; which $file)
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

DownloadURLIntoLocalFile () {
  local URL="$1"
  local retvar="$2"

  # Only download the file once:
  local localFile=$(echo "$URL" | sed 's%\([^a-zA-Z0-9_-]\)%_%g')
  if [ ! -f $localFile ]
  then
    echo "Note: Downloading $URL into local file: $localFile"
    wget -O - "$URL" > $localFile
  else
    echo "Note: Skipping download of $URL and reusing pre-existing local file: $localFile"
  fi

  retval=$(echo "$retval" | sed 's%^ *%%g') # strip leading whitespace

  # Return the name of the local file:
  eval "$retvar=\"$localFile\""
}

GetDebianSourcePackageTarBalls () {
  local package="$1"
  local suite="$2"
  local retvar="$3"

  # Search for the source package and store the results into sourcePackageSearchPageFile:
  local sourcePackageSearchURL="http://packages.debian.org/search?keywords=${package}&searchon=sourcenames&exact=1&suite=${suite}&section=all"
  local sourcePackageSearchPageFile=""
  DownloadURLIntoLocalFile "$sourcePackageSearchURL" sourcePackageSearchPageFile

  # Extract the result link:
  local resultLink=$(sed -n 's%^.*class="resultlink" href="\([^"]*\)".*%\1%gp' < $sourcePackageSearchPageFile)
  # Assert that there should be only one result link:
  local numResultLinks=$(echo "$resultLink" | wc -l)
  if [ "$numResultLinks" -gt 1 ]
  then
    echo "ASSERTION FAILED: Saw got $numResultLinks result links when only 1 was expected, downloaded from $sourcePackageSearchURL"
    exit 1
  fi

  # Download the package page into sourcePackageSearchPageFile.
  # Assume the resultLink is a relative one (if this breaks then
  # we will have to do some futzing with it here):
  local sourcePackageURL="http://packages.debian.org${resultLink}"
  local sourcePackagePageFile=""
  DownloadURLIntoLocalFile "$sourcePackageURL" sourcePackagePageFile

  # Extract the list of tarball URLs:
  local tarballURLs=$(sed -n 's%^.*<a href="\([^"]*\)">.*$%\1%gp' < $sourcePackagePageFile | grep tar.gz)
  if [ -z "$tarballURLs" ]
  then
    echo "ERROR: Failed to extract source package tarball URLs from $tarballURLPage"
    exit 1
  fi
  local retval=""
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
    retval="$retval $tarballBaseFile"
  done

  retval=$(echo "$retval" | sed 's%^ *%%g') # strip leading whitespace

  retval=$(echo "$retval" | sed 's%^ *%%g') # strip leading whitespace

  # Return the list of tarball files:
  eval "$retvar=\"$retval\""
}

ExtractTarBall () {
  local tarball="$1"
  local expectedFilesOrDirsRegexp="$2"
  echo "expectedFilesOrDirsRegexp==\"${expectedFilesOrDirsRegexp}\""
  local retvar="$3"

  local retval=$(ls -d * | grep '$expectedFilesOrDirsRegexp' 2>/dev/null)
  if [ -z "$retval" ]
  then
    tar zxvf $tarball
    retval=$(ls -d * | grep "$expectedFilesOrDirsRegexp" 2>/dev/null)
    if [ -z "$retval" ]
    then
      echo "ERROR: Failed to extract files matching regular expression \"$expectedFilesOrDirsRegexp\" from $tarball!"
      exit 1
    fi
  else
    echo "Note: Skipping extraction of $tarball and reusing pre-existing files: $retval"
  fi

  retval=$(echo "$retval" | sed 's%^ *%%g') # strip leading whitespace

  # Return the list of actual files:
  eval "$retvar=\"$retval\""
}

ExtractDebianSourcePackageTarBall () {
  local tarballs="$1"
  local expectedTarBallRegexp="$2"
  local expectedFilesOrDirsRegexp="$3"
  local retvar="$4"

  local tarball=""
  local actualFiles=""
  local retval=""
  for tarball in $tarballs
  do
    if echo "$tarball" | grep "$expectedTarBallRegexp" >/dev/null
    then
      echo "Note: Identified Debian tarball matching regular expression \"$expectedTarBallRegexp\": $tarball"
      ExtractTarBall $tarball "$expectedFilesOrDirsRegexp" actualFiles
      retval="$retval $actualFiles"
    fi
  done

  retval=$(echo "$retval" | sed 's%^ *%%g') # strip leading whitespace

  # Return the list of actual files:
  eval "$retvar=\"$retval\""
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

  # Apply patches listed in the seriesFile
  if [ -f $seriesFile ]
  then

    # Skip commented out patches:
    local patches=$(grep -v '^[ \t]*#' $seriesFile)

    # Apply the patches in the order of the series
    # file, because http://www.debian.org/doc/manuals/maint-guide/dother.en.html#patches
    # states: "The order of these patches is recorded in the
    # debian/patches/series file":
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
        echo Note: Applying patch $patch
        (cd $origDir; patch -p1 --forward) < $patchDir/$patch
        if [ $? != 0 ]
        then
          echo "ERROR: Patch $patch failed to apply"
          exit 1
        fi
        touch $patchCompleteFile
      else
        echo Note: Skipping patch $patch which was already applied
      fi
    done
  fi
}

DownloadExtractBuildGnuPackage () {
  local package="$1"
  local packageURL="http://ftp.gnu.org/gnu/${package}/"

  # --------------------------------------------------------------------------------
  # Downloading:
  # --------------------------------------------------------------------------------
  echo "Downloading ..."
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

DownloadPackageFromGitRepo () {
  local gitrepo="$1"
  local packageSubDir="$2"
  local depth="$3"
  echo "Checking out from git repo $gitrepo ..."
  if [ ! -d $packageSubDir ]
  then
    if [ -n "$depth" ]
    then
      PrintRun git clone $gitrepo
    else
      PrintRun git clone --depth 1 $gitrepo
    fi
    if [ ! -d $packageSubDir ]
    then
      echo "ERROR: Failed to checkout $packageSubDir sources from git repo at $gitrepo"
      exit 1
    fi
  else
    PrintRun cd $packageSubDir
    PrintRun git pull
    PrintRun cd ..
  fi
}
