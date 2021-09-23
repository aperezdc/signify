# Signify - Sign and Verify

[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Faperezdc%2Fsignify%2Fbadge&style=flat)](https://actions-badge.atrox.dev/aperezdc/signify/goto)

OpenBSD tool to sign and verify signatures on files. This is a portable
version which uses [libbsd](http://libbsd.freedesktop.org/wiki/) (version
0.8 or newer is required).

See https://www.tedunangst.com/flak/post/signify for more information.

## License

Signify is distributed under the terms of the [ISC
license](https://opensource.org/licenses/isc-license.txt).


## Installation

Some GNU/Linux distributions have readily available packages in their
repositories. It is recommended to use these, unless you absolutely need to
build from source code:

-   Debian: `apt install signify-openbsd`
-   Arch Linux: `pacman -S signify`


## Building

### Dependencies

* GNU Make (any version above 3.70).
* C compiler. Both GCC and Clang are tested and supported.
* [libbsd](http://libbsd.freedesktop.org/wiki/) 0.8 or newer.

If your system does not provide a package for `libbsd`, it is possible to use
a bundled copy, check the [build options](#options) section for more details.


### Options

The following options can be passed to Make:

* `VERIFY_ONLY=1`

    Build only the verification code. Support for signing will not
    be available in the built `signify` binary. **Note that this is
    unsupported and compilation may not succeed.**

* `BOUNDS_CHECKING=1`

    Enables bounds-checking using `__attribute__((bounded))`. Your
    compiler must have support for this. Clang 3.4 is known to work.

* `BUNDLED_LIBBSD=1`

    Instead of picking [libbsd](http://libbsd.freedesktop.org/wiki/) from the
    system, use a copy of the needed files included as part of the source tree
    and link them statically into Signify. This can be used when the version
    installed in the system is an unsupported version, or when installing it
    in the system is not desirable.

* `MUSL=1`

    Enable linking against the [Musl libc](http://www.musl-libc.org/). At the
    moment this needs a patched `libbsd`, so enabling this option will
    automatically set `BUNDLED_LIBBSD=1` and patch the locally-built version.

* `LTO=1`

    Perform Link-Time Optimizations. Both your compiler *and* linker
    must have support for this. Recent binutils and GCC/Clang are
    known to work.

* `PLEDGE=…`

    Choose among one of the alternative implementations of the
    [pledge(2)](https://man.openbsd.org/pledge.2)
    system call. For the moment the only supported values are:

    - `noop` *(default)*: Uses an implementation which does nothing
    - `waive` *(Linux-only)*: Uses
      [libwaive](https://github.com/dimkr/libwaive), which itself uses
      [seccomp filters](https://en.wikipedia.org/wiki/Seccomp).

    To use your own implementation, use an empty value, and pass
    the needed flags for linking its code. For example:
    `make PLEDGE='' EXTRA_LDFLAGS=my-pledge.o`.

* `BZERO=…`

    Choose which implementation of
    [`explicit_bzero(3)`](https://man.openbsd.org/bzero.3)
    to use. Supported values are:

    - `libc`: Relies on the system C library providing the function definition
      in the `<string.h>` header.
    - `bundled`: Use the portable implementation included with Signify's source
      code in `explicit_bzero.c`.

    The build system will try to detect whether the C library includes the
    function, and in most cases it will *not* be needed to specify this option.
    Providing a value for `BZERO` disables the automatic detection.

* `EXTRA_CFLAGS=…`, `EXTRA_LDFLAGS=…`

    Additional flags to be passed to the compiler and the linker,
    respectively.

For example, you can build a size-optimized version with:

    make EXTRA_CFLAGS='-Os -s' LTO=1


### Convenience Targets

The following Make targets are provided as convenience for building static
`signify` binaries:

* `make static`: Build a static binary bundling `libbsd` and using the system
  default C library.
* `make static-musl`: Build a static binary bundling `libbsd` using the Musl
  C library. This will set `musl-gcc` both as the compiler and linker to use
  and may not work on systems where this wrapper scripts is not available.


## Release Signing

### PGP

PGP detached signatures of source tarballs (`.asc`) are done with key
[0x91C559DBE4C9123B](https://keys.openpgp.org/search?q=5AA3BC334FD7E3369E7C77B291C559DBE4C9123B).
The key can be obtained with the following command:

```sh
gpg --keyserver hkps://keys.openpgp.org --recv-keys 5AA3BC334FD7E3369E7C77B291C559DBE4C9123B
```

Assuming that both the tarball and its signature are in the same directory,
a release can be checked using:

```sh
gpg --verify signify-<version>.tar.xz.asc
```

### Signify

An OpenBSD-style `SHA256.sig` signed checksum is provided alongside with each
release. The signing key can be found at
[keys/signifyportable.pub](keys/signifyportable.pub), its contents are:

```
untrusted comment: Signify portable release signing public key
RWRQFCY809DUoWEHxWmoTNtxph6yUlWNsjfW54PqLI6S3dWfuZN4Ovj1
```

To verify a release, save the associated `SHA256.sig` file in the same
directory as the source tarball. If the signing key is into a file named
`signifyportable.pub`, then use:

```sh
signify -C -p signifyportable.pub -x SHA256.sig
```

The above Signify public key can itself be verified using the same PGP key
used for release tarballs. Grab the [keys/signifyportable.pub.asc](keys/signifyportable.pub.asc)
file as well, the run:

```
gpg --verify signifyportable.pub.asc
```


## Troubleshooting

* **Problem:** Undefined references to `clock_gettime`. <br>
  **Solution:** Your system has an old `glibc` version, you need to pass
  `LDLIBS=-lrt` to `make`.


## Other implementations

* [asignify](https://github.com/vstakhov/asignify) can read signatures
  generated by Signify (generating them is not yet implemented), and can be
  used as a library.
* [signify-rs](https://github.com/badboy/signify-rs), a re-implementation in Rust. It's fully compatible with the original implementation.
