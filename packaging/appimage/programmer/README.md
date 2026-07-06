# GOWIN Programmer AppImage packaging

This directory builds the standalone GOWIN Programmer Linux application as a
single x86-64 AppImage. It packages the vendor `Programmer/` directory,
desktop metadata, and the shared GOWIN icons from `../icons`.

The launcher follows the environment used by `start-programmer.sh`: bundled
Programmer libraries are loaded first, Qt uses the bundled PyQt5 plugin
directory, and the application runs on XCB/Xwayland. Host `libz` and
`libfreetype` are preloaded to avoid conflicts with the older bundled copies.

## Prerequisites

The build requires:

- `appimagetool`
- GNU Make
- `rsync`
- `desktop-file-validate`
- `appstreamcli`

The installed `appimagetool` must itself be an AppImage because the build
reuses its embedded type-2 runtime.

## Build

From the repository root:

```sh
make -C packaging/appimage/programmer
```

By default, the source directory is the repository root, resolved as `../../..`
from this directory. It must contain:

```text
Programmer/
Programmer/bin/programmer
```

To package Programmer from another extracted application directory, set
`SOURCE_DIR` to the directory containing `Programmer/`, not to `Programmer/`
itself:

```sh
make -C packaging/appimage/programmer \
  SOURCE_DIR=/home/user/Applications/Gowin_V1.9.11.03_Education_x64
```

The version and architecture can also be overridden:

```sh
make -C packaging/appimage/programmer \
  VERSION=v1.9.11.03 \
  ARCH=x86_64
```

## Output

The staged AppDir and final image are written under this directory:

```text
build/GOWIN_Programmer.AppDir/
dist/GOWIN_Programmer-v1.9.11.03-x86_64.AppImage
```

## Run

```sh
./packaging/appimage/programmer/dist/GOWIN_Programmer-v1.9.11.03-x86_64.AppImage
```

## Other targets

Validate packaging metadata and source paths:

```sh
make -C packaging/appimage/programmer validate
```

Create only the staged AppDir:

```sh
make -C packaging/appimage/programmer appdir
```

Remove staged build files:

```sh
make -C packaging/appimage/programmer clean
```

Remove staged files and the generated AppImage:

```sh
make -C packaging/appimage/programmer distclean
```
