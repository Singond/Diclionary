Changelog
=========

[Unreleased]
------------
### Added
- This changelog.

### Changed
- Improved parsing of entries in `ssjc` containing multiple headwords.

### Fixed
- Fixed a bug causing the program to crash on entries in the `ssjc` dictionary
  where the label of the first item in a numbered list was not equal to `1.`,
  but contained a non-numeric prefix, as in the entry
  <https://ssjc.ujc.cas.cz/search.php?hledej=Hledat&heslo=jeviti&sti=EMPTY&where=hesla&hsubstr=no>.
- Prevented an exception raised during dictionary search from freezing
  the whole program.

[0.1.0] - 2021-10-24
--------------------
### Added
- First release with basic functionality and one supported dictionary.
