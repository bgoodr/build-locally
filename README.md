build-locally
=============

Build programs that allow automatic downloading and building of
Internet-provided tools locally, typically in a users HOME
directory. 

After building, it is intended that the user prepend to the resulting
installation bin directory to their PATH. This will override the
target platforms default installation location (e.g., override what is
installed in /usr/bin) when the tool is invoked from the UNIX/Linux
shell command prompt.

These build programs are intensionally limited to building only those
tools whose build logic that can be coerced (typically via dynamic
build logic patching) into *not* prompting for anything, and that can
be downloaded from source directly from the Internet.

Usage
=====

Instructions to build the ficticious "example-tool" on Linux are:

    cd $HOME  # typically
    mkdir bgoodr
    cd bgoodr
    gitw clone https://github.com/bgoodr/build-locally.git
    $HOME/bgoodr/build-locally/tools/example-tool/linux/build.example-tool.bash

To build the other tools, just change "example-tool" to the name of
the tool to build in all places in the above path.

What is included
================

List of tools provided are in subdirectories:

* [example-tool](tools/example-tool/README.md): An example directory to serve
as a template for adding more tools to be built by this project.

... more to come! ...

Development
===========

See [build-locally.org](build-locally.org).
