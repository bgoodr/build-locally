#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

# List of supported compressed file types downloadable from sourceforge:
sourceforge_compressed_file_types="tar_gz zip"

# Apply a function over the list of sourceforge_compressed_file_types
# This simulates a Template Method Design Pattern in Bash syntax (not quite the same as there are no objects here).
apply_on_all_compressed_file_types () {
  local method="$1"
  local arg1="$2"
  local files
  local results
  for file_type in $sourceforge_compressed_file_types
  do
    results=$(${method}_${file_type} "$arg1")
    files="$files $results"
  done
  files=$(echo "$files" | sed -e 's%^ *%%g' -e 's% *$%%g')
  echo "$files"
}

# Apply the specified operation on the correct file type:
apply_on_compressed_file_type () {
  local method="$1"
  local arg1="$2"
  local files
  local results
  for file_type in $sourceforge_compressed_file_types
  do
    is_type=$(is_file_type_${file_type} "$arg1")
    if [ "$is_type" = 1 ]
    then
      ${method}_${file_type} "$arg1"
      return
    fi
    files="$files $results"
  done
}

is_file_type_tar_gz () {
  local compressed_file="$1"
  echo "$compressed_file" | sed -n \
    -e 's%^.*\.tar\.gz$%1%gp' \
    -e 's%^.*\.tgz$%1%gp'
}

is_file_type_zip () {
  local compressed_file="$1"
  echo "$compressed_file" | sed -n \
    -e 's%^.*\.zip$%1%gp'
}

find_downloaded_compressed_files_tar_gz () {
  find . -maxdepth 1 -name "*.tar.gz" -o -name "*.tgz" | sed 's%^\./%%g'
}

find_downloaded_compressed_files_zip () {
  find . -maxdepth 1 -name "*.zip" | sed 's%^\./%%g'
}

get_version_from_compressed_file_tar_gz () {
  local compressed_file="$1"
  local version=$(echo "$compressed_base_file" | sed -n \
    -e 's%^[^-]*-\(.*\)\.tar\.gz$%\1%gp' \
    -e 's%^[^-]*-\(.*\)\.tgz$%\1%gp' \
  )
  echo "$version"
}

get_version_from_compressed_file_zip () {
  local compressed_file="$1"
  local version=$(echo "$compressed_base_file" | sed -n \
    -e 's%^[^-]*-\(.*\)\.zip$%\1%gp' \
  )
  echo "$version"
}

get_subdir_from_first_slashed_line () {
  #
  # The top-level directory is not guaranteed to be the first line in
  # the tar tf output as of Sun Apr 23 09:41:19 PDT 2017 using tar
  # version tar (GNU tar) 1.23. Maybe it never was guaranteed to be?
  #
  # And do this also for unzip (with -Z for zipinfo mode) output.
  #
  sed -n '/^\([^/][^/]*\)\/.*$/{ s%%\1%g; p; q; }'
}

get_extracted_subdir_from_compressed_file_tar_gz () {
  local compressed_base_file="$1"
  tar tf "$compressed_base_file" 2>/dev/null | get_subdir_from_first_slashed_line
}

get_extracted_subdir_from_compressed_file_zip () {
  local compressed_base_file="$1"
  unzip -Z -1 "$compressed_base_file" 2>/dev/null | get_subdir_from_first_slashed_line
}

extract_compressed_file_tar_gz () {
  local compressed_base_file="$1"
  tar zxvf "$compressed_base_file"
}

extract_compressed_file_zip () {
  local compressed_base_file="$1"
  unzip -o "$compressed_base_file"
}

DownloadExtractSourceForgePackage () {
  local package="$1"

  # --------------------------------------------------------------------------------
  # Downloading:
  # --------------------------------------------------------------------------------
  # Just download it and identify the final compressed filename that may
  # NOT have the same $package name (e.g., package of "docbook2x"
  # gives a downloaded compressed of docbook2X-0.8.8.tar.gz)
  compressed_base_file=""
  for i in 1 2
  do
    compressed_base_file=$(apply_on_all_compressed_file_types find_downloaded_compressed_files)
    if [ -n "$compressed_base_file" ]
    then
      echo "Note: Found existing compressed(s) files: $compressed_base_file"
      multiple=$(echo "$compressed_base_file" | grep ' ')
      if [ -n "$multiple" ]
      then
        echo "ASSERTION FAILED: Multiple pre-existing compressed files found: $compressed_base_file"
        exit 1
      fi
      break
    else
      if [ "$i" = 2 ]
      then
        echo "ERROR: Could not download a compressed file. Did it download some new type of file?"
        exit 1
      fi
      #
      # Download it:
      #
      downloadURL="https://sourceforge.net/projects/$package/files/latest/download?source=typ_redirect"
      echo "Note: Downloading package from \"$downloadURL\""
      set -o pipefail # http://unix.stackexchange.com/a/73180
      wget -O tmp_downloaded_file "$downloadURL" 2>&1 | tee download.log
      if [ $? != 0 ]
      then
        echo "ERROR: Download of \"$downloadURL\" failed."
        exit 1
      fi
      #
      # Pull out the final URL that was (possibly) redirected:
      # E.g., we are looking for the _last_ line of the form:
      #
      #   --2017-06-25 08:07:57--  https://superb-sea2.dl.sourceforge.net/project/docbook2x/docbook2x/0.8.8/docbook2X-0.8.8.tar.gz
      #
      final_url=$(sed -n 's%^--[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]-- *\(http.*\)$%\1%gp' download.log | tail -1)
      #
      # Pull out the final compressed_base_file:
      #
      compressed_base_file=$(basename "$final_url")
      #
      # Move the file into place:
      #
      mv tmp_downloaded_file $compressed_base_file
      break
    fi
  done

  #
  # Scrape out the version of the file thus downloaded:
  #
  version=$(apply_on_all_compressed_file_types get_version_from_compressed_file "$compressed_base_file")
  if [ -z "$version" ]
  then
    echo "ASSERTION FAILED: Could not determine the version from the compressed_base_file \"$compressed_base_file\""
    exit 1
  fi

  #
  # Get the subdir from the compressed_base_file:
  #
  subdir=$(apply_on_all_compressed_file_types get_extracted_subdir_from_compressed_file "$compressed_base_file")
  if [ ! -d "$subdir" ]
  then
    apply_on_compressed_file_type extract_compressed_file "$compressed_base_file"
    if [ ! -d "$subdir" ]
    then
      echo "ERROR: Could not extract `pwd`/$compressed_base_file"
      exit 1
    fi
  fi
  PrintRun cd $HEAD_DIR/$subdir

}
