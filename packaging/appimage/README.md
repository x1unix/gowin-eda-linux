# GOWIN AppImage packaging

This directory contains AppImage packaging for the two Linux GUI applications:

- `ide/` builds the GOWIN EDA IDE AppImage.
- `programmer/` builds the standalone GOWIN Programmer AppImage.
- `icons/` contains shared application icons used by both packages.

Build both AppImages from the repository root:

```sh
make -C packaging/appimage
```

Build one package directly:

```sh
make -C packaging/appimage/ide
make -C packaging/appimage/programmer
```