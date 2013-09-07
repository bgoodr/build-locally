build-locally
=============

This package provides build programs (typically just shell scripts)
that allow automatic downloading, building, and installing (locally)
source packages onto existing systems, typically in a users HOME
directory. This is needed in one or more of the following situations:

- It is difficult to install or upgrade packages using standard
  mechanisms (e.g., Apt, Yum).

- The package does is not provided by the base operating system.

- It is desired to build the package without disturbing the
  configuration of the system, which may be in use by multiple users.

- A more recent package is desired, whereas the operating system
  provided package is too old.

After building, it is intended that the user prepend to the resulting
installation bin directory to their PATH. This will override the
target platforms default installation location (e.g., override what is
installed in /usr/bin) when one of the scripts or executables in the
package is invoked from the UNIX/Linux shell command prompt.

These build programs are intensionally limited to building only those
packages whose build logic that can be coerced (typically via dynamic
build logic patching) into *not* prompting, and that can be downloaded
from source directly from the Internet.

Usage
=====

Instructions to build the ficticious "example-package" on Linux are:

    cd $HOME  # typically
    mkdir bgoodr
    cd bgoodr
    git clone https://github.com/bgoodr/build-locally.git
    $HOME/bgoodr/build-locally/packages/example-package/linux/build.example-package.bash

To build the other packages, just change "example-package" to the name of
the package to build in all places in the above path.

Packages
========

The following is a list of packages whose build programs are provided by this package:

* [example-package](packages/example-package/README.md): An example directory to serve
as a template for adding more packages to be built by this project.

* [texinfo](packages/texinfo/README.md): Building the texinfo package.

* [idutils](packages/idutils/README.md): Building the idutils package.

* [python](packages/python/README.md): Building the Python language system.

... more to come! ...

Development
===========

See [build-locally.org](build-locally.org).
