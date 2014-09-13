intltool
==========================

Parent: [build-locally](../../README.md)

This directory builds the intltool package needed by [xkeyboard-config](../xkeyboard-config/README.md).

Requires perl to have the XML::Parser package:

http://forums.gentoo.org/viewtopic-t-926740.html

Need to build perl and install that package. So we depend upon the
perl--xml-parser which will in turn depend upon perl.
