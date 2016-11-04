# Change Log
All notable changes to this project will be documented in this file.

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

[v20]: https://github.com/aperezdc/signify/compare/v19...v20
[v19]: https://github.com/aperezdc/signify/compare/v18...v19
[v18]: https://github.com/aperezdc/signify/compare/v17...v18

