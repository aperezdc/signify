# Signify - Sign and Verify

OpenBSD tool to signs and verify signatures on files. This is a portable
version which uses [libbsd](http://libbsd.freedesktop.org/wiki/) (version
0.7 or newer is required).

See http://www.tedunangst.com/flak/post/signify for more information.

## Build options

The following options can be passed to Make:

VERIFY_ONLY=1
  ~ Build only the verification code. Support for signing will not
    be available in the built `signify` binary. **Note that this is
    unsupported and compilation may not succeed.**
BOUNDS_CHECKING=1
  ~ Enables bounds-checking using `__attribute__((bounded))`. Your
    compiler must have support for this. Clang 3.4 is known to work.
LTO=1
  ~ Perform Link-Time Optimizations. Both your compiler *and* linker
    must have support for this. Recent binutils and GCC/Clang are
    known to work.
EXTRA_CFLAGS=…
  ~ Additional flags to be passed to the compiler.

For example, you can build a size-optimized version with:

    make EXTRA_CFLAGS='-Os -s' LTO=1
