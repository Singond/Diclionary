Building for Arch-based Distros
===============================
1. In the project root, run `make dist` to generate the source tarball.
2. Change to the `pkg/arch` directory.
3. Update the `PKGBUILD` file (at least the `pkgver` and `sha256sums` fields).
4. Run `makepkg`.
