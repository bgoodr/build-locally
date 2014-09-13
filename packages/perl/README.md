perl
==========================

Parent: [build-locally](../../README.md)

This directory builds the perl package needed by [intltool](../intltool/README.md).

In ~/build/Debian.7.x86_64/perl/perl-5.20.0/pod/perlgit.pod we see instructions for building from git.

    git checkout -b maint-5.10 origin/maint-5.10

And http://www.cpan.org/src/#content says:

     wget http://www.cpan.org/src/5.0/perl-5.20.0.tar.gz
     tar -xzf perl-5.20.0.tar.gz
     cd perl-5.20.0
     ./Configure -des -Dprefix=$HOME/localperl
     make
     make test
     make install

http://perl5.git.perl.org/perl.git is the page describing the repos.
