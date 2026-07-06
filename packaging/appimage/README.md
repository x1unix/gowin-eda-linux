# GOWIN EDA AppImage packaging

This directory builds the GOWIN EDA Linux IDE as a single x86-64 AppImage.
It packages the vendor `IDE/` directory, desktop metadata, icons, and the
compatibility shim required by the optional OpenGL workaround.

The separate `Programmer/` application is not included. The AppImage uses
XCB/Xwayland because the bundled native Wayland backend is incomplete.

## Prerequisites

The build requires:

- `appimagetool`
- GNU Make
- a C compiler
- `rsync`
- `desktop-file-validate`
- `appstreamcli`

The installed `appimagetool` must itself be an AppImage because the build
reuses its embedded type-2 runtime.

## Build

From the repository root:

```sh
make -C packaging/appimage
```

By default, the source directory is the repository root, resolved as `../..`
from this directory. It must contain:

```text
IDE/
IDE/bin/gw_ide
```

The resolved source directory is printed before staging begins.

To package an IDE from another extracted application directory, set
`SOURCE_DIR` to the directory containing `IDE/`, not to `IDE/` itself:

```sh
make -C packaging/appimage \
  SOURCE_DIR=/home/user/Applications/Gowin_V1.9.11.03_Education_x64
```

An invalid source directory is rejected while GNU Make parses the Makefile,
before any build commands run.

The version and architecture can also be overridden:

```sh
make -C packaging/appimage \
  VERSION=v1.9.11.03 \
  ARCH=x86_64
```

## Output

The staged AppDir and final image are written under this directory:

```text
build/GOWIN_EDA.AppDir/
dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage
```

The compatibility shim is compiled directly into the AppDir. No external
launcher or shim is required beside the finished AppImage.

## Run

Normal Xwayland/software-rendering mode:

```sh
./packaging/appimage/dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage
```

Optional hardware-accelerated OpenGL workaround:

```sh
GOWIN_OPENGL=1 \
  ./packaging/appimage/dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage
```

The OpenGL mode uses the host Mesa/GLVND libraries and GPU driver while
retaining the Qt libraries bundled with GOWIN EDA.

## Other targets

Validate packaging metadata and source paths:

```sh
make -C packaging/appimage validate
```

Create only the staged AppDir:

```sh
make -C packaging/appimage appdir
```

Remove staged build files:

```sh
make -C packaging/appimage clean
```

Remove staged files and the generated AppImage:

```sh
make -C packaging/appimage distclean
```

See [research doc](../../docs/APPIMAGE_RESEARCH.md) for investigation details,
runtime compatibility findings, and validation results.
