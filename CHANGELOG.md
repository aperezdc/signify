# Change Log
All notable changes to this project will be documented in this file.

## [v30] - 2020-09-24
### Changed
- Silence a compiler warning produced by Clang 10.

## [v29] - 2020-03-07
### Added
- Source packages now include a license. Thanks to Marcus Müller for the
  patch (#24).
- New convenience targets for static builds (`make static` &
  `make static-musl`). Thanks to @frink for the bug report.

### Fixed
- Static builds should work again. Thanks to @frink for the bug report.

## [v28] - 2020-02-06
### Added
- In verification mode (with `-C`) it is now possible to use the `-t` command
  line flag to specify the key type.
- A copy of the regression tests from the OpenBSD CVS repository is now
  included.

### Changed
- Bumped version of libbsd to 0.10.0, which is the most recent stable.

### Fixed
- Ensure that release packages include the code for the `libwaive/` submodule.

## [v27] - 2019-11-04
### Fixed
- Updated to the latest upstream sources, the size of a fixed buffer has
  been changed to use `PATH_MAX` instead to avoid potential overflows when
  using very long path names.

## [v26] - 2019-07-25
### Added
- Provide a definition for the `__dead` marker when using GCC 4+ or Clang.

### Fixed
- Adapted to the new `pledge()` definition in OpenBSD 6.3 and newer.
- Ensure that the prototype for `asprintf()` gets defined by system headers.

### Changed
- Silence (harmless) compiler warnings enabled in more recent GCC/Clang
  releases when using `-Wall`.

## [v25] - 2019-04-28
### Added
- Updated to the latest upstream sources, the `-z` command line flag can
  now be used to zero the timestamp when producing a signature.

## [v24] - 2018-09-03
### Fixed
- Fixed memory corruption due to incorrect remapping of SHA-224, SHA-384,
  and SHA-512-256 to incompatible counterparts in `compat.h`. Thanks to
  Ori Bernstein for the bug report (#17) and Wolfgang Müller for submitting
  the fix (#18).

## Changed
- Bumped version of libbsd to 0.9.1 for bundling, which does not need
  patching to work with Musl.

## [v23] - 2017-11-20
### Fixed
- Fixed handling of the `errno` variable.

## [v22] - 2017-08-15
### Added
- For systems using GNU libc 2.25 or newer, the version of `explicit_bzero()`
  supplied by the C library is used by default instead of the bundled one.

### Fixed
- The bundled implementation of `explicit_bzero()` was changed, the old one
  was likely to be inlined by the compiler.

## [v21] - 2017-06-05
### Changed
- Unneeded files have been removed from the repository, and from the list of
  files imported from OpenBSD (in `cvs-files`).

## [v20] - 2016-11-04
### Added
- New `-z` command line option for signing `gzip` archives.
- Documented how public key file names are guessed from signature comments.

### Changed
- Extensions used for public/private key file names are now checked. Key
  generation will use the recommended extensions.

### Fixed
- Improved how the secret and public key names are checked for equality.

## [v19] - 2016-08-18
### Changed
- Use `getprogname()` instead of accessing `__progname` directly.

## [v18] - 2016-06-06
### Changed
- Support using versions 0.8.2 and 0.8.3 of libbsd when `BUNDLED_LIBBSD=1` is
  specified.

[v30]: https://github.com/aperezdc/signify/compare/v29...v30
[v29]: https://github.com/aperezdc/signify/compare/v28...v29
[v28]: https://github.com/aperezdc/signify/compare/v27...v28
[v27]: https://github.com/aperezdc/signify/compare/v26...v27
[v26]: https://github.com/aperezdc/signify/compare/v25...v26
[v25]: https://github.com/aperezdc/signify/compare/v24...v25
[v24]: https://github.com/aperezdc/signify/compare/v23...v24
[v23]: https://github.com/aperezdc/signify/compare/v22...v23
[v22]: https://github.com/aperezdc/signify/compare/v21...v22
[v21]: https://github.com/aperezdc/signify/compare/v20...v21
[v20]: https://github.com/aperezdc/signify/compare/v19...v20
[v19]: https://github.com/aperezdc/signify/compare/v18...v19
[v18]: https://github.com/aperezdc/signify/compare/v17...v18
