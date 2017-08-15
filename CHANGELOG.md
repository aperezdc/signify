# Change Log
All notable changes to this project will be documented in this file.

## [v22] - 2018-08-15
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

[v22]: https://github.com/aperezdc/signify/compare/v21...v22
[v21]: https://github.com/aperezdc/signify/compare/v20...v21
[v20]: https://github.com/aperezdc/signify/compare/v19...v20
[v19]: https://github.com/aperezdc/signify/compare/v18...v19
[v18]: https://github.com/aperezdc/signify/compare/v17...v18

