emacs
==========================

Parent: [build-locally](../../README.md)

This directory builds Emacs.

TODO:

 - Build and locally install packages that ./linux/build.bash
   currently requires from the system, since that deviates from the
   intent of the build-locally system. See the notes in the comments
   inside ./linux/build.bash. Namely, re-examine the hardcoded
   --without-gif and with-tiff options to configure.

 - Re-enable building with svg. Currently disabled due to its complex dependencies.

