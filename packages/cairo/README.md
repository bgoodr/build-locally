cairo
=====

Parent: [build-locally](../../README.md)

Builds the cairo package. See [cairo home page](http://cairographics.org/)

See also [linux from scratch](http://www.linuxfromscratch.org/blfs/view/svn/x/cairo.html)

Freetype is a dependency even though the cairo builds do not properly
use pkg-config stuff to find it:

  /usr/include/ft2build.h:56:38: error: freetype/config/ftheader.h: No such file or directory


TODO: Consider adding fontconfig package as a required dependency.
