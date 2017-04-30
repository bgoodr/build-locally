#!/bin/bash
# -*-mode: Shell-script; indent-tabs-mode: nil; sh-basic-offset: 2 -*-
# This script must be in Bash since we make use of local function variables herein.

# Add system-defined directories to PKG_CONFIG_PATH:
Add_System_Defined_PKG_CONFIG_PATH ()
{
  # Allow system supplied gtk libraries to also be found by pkg-config
  # versus our locally built pkg-config that does not also read from the
  # system-supplied .pc files. This may also solve problems finding
  # other system-supplied packages that I am choosing not to build in
  # the near term:
  #
  #   Specifically, this is to pick up fontconfig which is needed by xft
  #   which is needed in order to display better fonts.
  #
  #   The alternative is to build both xft and all of its dependencies
  #   but let's see if we can get by with this approach first:
  #
  # Our local pkg-config PKG_CONFIG_PATH value:
  local_pkg_config_path=$(pkg-config --variable pc_path pkg-config)
  echo "local_pkg_config_path==\"${local_pkg_config_path}\""

  # The system-supplied pkg-config PKG_CONFIG_PATH value:
  system_pkg_config_path=$(/usr/bin/pkg-config --variable pc_path pkg-config)
  if [ -z "$system_pkg_config_path" ]
  then
    # pkg-config on RHEL6 does not return anything. Try to extract the
    # path by forcing the buggy pkg-config on RHEL6 to give us the value
    # of "pc_path"
    system_pkg_config_path=$(/usr/bin/pkg-config --debug 2>&1 | \
      sed -n "s%Will find package '[^']*' in file '\([^']*\)'%\1%gp" | \
      xargs -n1 dirname | \
      uniq | \
      tr '\012' :)
    echo "WARNING: System-supplied buggy pkg-config that returns nothing for 'pkg-config --variable pc_path pkg-config'. Hacking around it with: $system_pkg_config_path"
  fi
  echo "system_pkg_config_path==\"${system_pkg_config_path}\""

  export PKG_CONFIG_PATH="$local_pkg_config_path:$system_pkg_config_path"
  echo "PKG_CONFIG_PATH now is ... ${PKG_CONFIG_PATH}"
}
