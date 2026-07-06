# GOWIN EDA AppImage research log

Date: 2026-07-06

## Scope

- Package **GOWIN EDA v1.9.11.03** as one x86-64 AppImage.
- Package `IDE/` only. `Programmer/` is a separate application and is excluded.
- Run through XCB/Xwayland. Native Wayland support is out of scope.
- Keep packaging sources, staging files, output, and this log under
  `packaging/appimage/`.
- Keep the vendor Qt runtime intact. Do not substitute the host Qt runtime.

## Plan

1. Inspect the installed `appimagetool`, application tree, supplied icons, and
   desktop metadata requirements.
2. Create a conventional AppDir with `AppRun`, a desktop entry, hicolor icons,
   the complete `IDE/` payload, and the compatibility shim.
3. Make the AppDir entry point relocatable and resolve only ABI-bound host
   libraries through the host dynamic-loader cache.
4. Build the AppImage with name/version/architecture variables.
5. Inspect the image, extract it, and confirm that `Programmer/` is absent.
6. Launch-test the finished image under Xwayland, both normally and with the
   optional `GOWIN_OPENGL=1` workaround.

## Initial findings

- The source `IDE/` tree is approximately 1.4 GiB with 2,533 files.
- `IDE/bin/gw_ide` and the compatibility shim are x86-64 ELF objects.
- Supplied PNG icons are available at 16, 24, 32, 48, and 256 pixels.
- `appimagetool` is installed at
  `/home/x1unix/.local/bin/appimagetool`.
- The AppImage manual requires an AppDir containing at minimum `AppRun`, a
  desktop file, an icon, and the application payload. It also requires
  relocatable paths and recommends validating the desktop file.
- The desktop category is `Development;IDE;Electronics;`, with keywords for
  FPGA, EDA, HDL, Verilog, VHDL, and synthesis.

## Runtime design

The AppImage contains the entire vendor `IDE/` tree at
`usr/lib/gowin-eda/IDE` and the OpenGL environment shim at
`usr/lib/gowin-eda/compat`. `AppRun` changes into the embedded IDE directory
before execution because Gowin resolves resources relative to that directory.

The bundled Qt library path remains first in `LD_LIBRARY_PATH`. Host Freetype
is resolved by SONAME because the bundled copy is incompatible with current
host font libraries.

When `GOWIN_OPENGL=1` is set, `AppRun` additionally loads the embedded shim
and resolves host `libstdc++`, `libGLdispatch`, and `libGLX`. These are needed
by the host Mesa driver; no host Qt library is used.

## Actions and results

### Packaging files created

- `Makefile`: validates metadata, builds the shim, stages the AppDir, extracts
  a known-working type-2 runtime from the installed `appimagetool`, and creates
  the versioned AppImage.
- `AppRun`: relocatable runtime entry point for XCB/Xwayland.
- `com.gowinsemi.GowinEDA.desktop`: desktop integration metadata.
- `com.gowinsemi.GowinEDA.appdata.xml`: AppStream metadata.
- `icons/`: user-supplied hicolor icons at 16, 24, 32, 48, and 256 pixels.
- `build/GOWIN_EDA.AppDir/`: staged AppDir.
- `dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage`: final artifact.

The compatibility shim is built from the existing `compat/` source directly
inside the AppDir. A user distributing the AppImage does not need to carry the
shim or launcher as separate files.

The shim Makefile accepts an optional `OUTPUT` parameter. Its default remains
`compat/libgowin-env-shim.so`, which preserves the standalone
`start-ide.sh` path. The AppImage Makefile passes the final AppDir shim path as
`OUTPUT`, so it compiles the library directly into the staged image.

The AppImage Makefile also accepts `SOURCE_DIR`, the directory containing the
source `IDE/` directory. An unset or empty value resolves to the repository
root (`../..` relative to the packaging directory). The resolved source
directory is printed at the beginning of every AppDir build.

`SOURCE_DIR` is validated while GNU Make parses the Makefile. The build stops
before running any recipe if either `IDE/` or `IDE/bin/gw_ide` is absent.

Verified commands:

```sh
make -C compat OUTPUT=/tmp/libgowin-env-shim-test.so
make -C packaging/appimage appdir SOURCE_DIR=
```

The first command produced a valid shared object with SONAME
`libgowin-env-shim.so`. The second printed the resolved repository root,
compiled the shim directly into the AppDir, and synchronized the default
`IDE/` source successfully.

### Validation

The following checks pass:

```sh
make validate
shellcheck AppRun
desktop-file-validate com.gowinsemi.GowinEDA.desktop
appstreamcli validate --no-net com.gowinsemi.GowinEDA.appdata.xml
```

The desktop and AppStream files use the matching reverse-DNS identifier
`com.gowinsemi.GowinEDA`. The icon name remains `gowin-eda`.

The AppImage was fully extracted under `build/inspection/squashfs-root` and
compared with the packaging inputs. It contains:

- 2,544 files
- the complete `IDE/` payload
- the embedded compatibility shim
- `AppRun`, desktop metadata, AppStream metadata, and all supplied icons

The top-level `Programmer/` application is absent. A Programmer user-guide PDF
inside `IDE/doc/` remains because it is part of the IDE documentation tree,
not the separate Programmer application.

### AppImage runtime workaround

The first build used the continuously downloaded type-2 runtime selected by
`appimagetool`. That runtime created the image successfully but aborted before
`AppRun`, reporting a failure to resolve the AppImage's own real path.

The runtime embedded in the installed `appimagetool` works on this host.
The Makefile now extracts that runtime using `appimagetool
--appimage-offset` and passes it back with `--runtime-file`. This also avoids a
runtime download during subsequent builds.

The final runtime reports:

```text
AppImage runtime version:
https://github.com/AppImage/type2-runtime/commit/caf24f9
```

### Build result

Build from the repository root:

```sh
make -C packaging/appimage
```

Override the version or architecture when needed:

```sh
make -C packaging/appimage VERSION=v1.9.11.03 ARCH=x86_64
```

Build from another extracted GOWIN tree:

```sh
make -C packaging/appimage SOURCE_DIR=/path/to/gowin-eda
```

Output:

```text
packaging/appimage/dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage
```

- Uncompressed AppDir: approximately 1.4 GiB
- AppImage: 434.84 MiB
- Compression: zstd, approximately 31% of the uncompressed size
- SHA-256:
  `e0c22c9ea9a4f2c1ced9e685bea92a8e66d9962340ae8c350879ce5e8ae16e4f`

### Launch tests

Default Xwayland launch:

```sh
./packaging/appimage/dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage
```

The GUI appeared. It retains Gowin's software-rendering configuration and
prints the known non-fatal message:

```text
QXcbIntegration: Cannot create platform OpenGL context,
neither GLX nor EGL are enabled
```

Optional hardware acceleration:

```sh
GOWIN_OPENGL=1 \
  ./packaging/appimage/dist/GOWIN_EDA-v1.9.11.03-x86_64.AppImage
```

The GUI appeared and Qt reported:

```text
Xcb GLX gl-integration created
Xcb GLX gl-integration successfully initialized
```

Both tests ran the finished AppImage rather than the staged AppDir.

## Portability limits

- The image is x86-64 and requires glibc, X11/Xwayland, and a working host
  dynamic loader cache or one of the standard x86-64 library directories.
- Freetype is host-provided because mixing the bundled Freetype with current
  host font libraries caused the original startup failure.
- Hardware acceleration intentionally uses the host Mesa/GLVND stack and host
  C++ runtime. GPU drivers cannot be made portable by bundling the build
  machine's driver.
- Native Wayland is not supported. `AppRun` forces `QT_QPA_PLATFORM=xcb`.
- This image was tested on the current Arch Linux host. The AppImage testing
  guide recommends testing every intended base distribution; that broader
  compatibility matrix has not been run.

## References

- [AppImage manual packaging guide](https://docs.appimage.org/packaging-guide/manual.html)
- [AppImage testing guide](https://docs.appimage.org/packaging-guide/testing.html)
- [GOWIN EDA product page](https://www.gowinsemi.com/en/support/home/)
