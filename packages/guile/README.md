guile
=====

Parent: [build-locally](../../README.md)

Builds the guile package.See [guile home page](http://www.gnu.org/software/guile/)

Notes
=====
Building guile seems to hang up in various places, e.g.,:

    ...
    make[2]: Entering directory '/home/joeblo/build/RHEL.6.4.x86_64/guile/guile/bootstrap'
      BOOTSTRAP GUILEC ice-9/eval.go
    wrote `ice-9/eval.go'
      BOOTSTRAP GUILEC ice-9/psyntax-pp.go
    ...

See explanation at https://wingolog.org/archives/2016/01/11/the-half-strap-self-hosting-and-guile

