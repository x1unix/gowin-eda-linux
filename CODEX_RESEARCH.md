# Gowin IDE Linux startup investigation

Date: 2026-07-05

## Result

The IDE starts successfully through Xwayland with:

```sh
#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

export LD_LIBRARY_PATH="$root/IDE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LD_PRELOAD="/usr/lib/libfreetype.so.6${LD_PRELOAD:+:$LD_PRELOAD}"
export QT_QPA_PLATFORM=xcb

cd "$root/IDE"
exec ./bin/gw_ide "$@"
```

`QT_DEBUG_PLUGINS=1` is useful for diagnosis but should not be enabled in the
normal launcher.

This was verified in the current Wayland session. The XCB platform plugin
loaded and the GUI appeared.

## Environment

- Arch Linux, glibc 2.43
- Wayland session with Xwayland available (`WAYLAND_DISPLAY=wayland-1`,
  `DISPLAY=:0`)
- System Qt: 5.15.19
- Bundled Qt: 5.15.14
- System `gcc-libs`: 16.1.1
- Bundled `libstdc++.so.6` exports only through `GLIBCXX_3.4.28`

The application binary has:

```text
RPATH=$ORIGIN:$ORIGIN/../lib
```

and `IDE/bin/qt.conf` correctly selects:

```ini
[Paths]
Plugins=../plugins/qt
```

## Root cause of the QPA failure

The QPA plugins exist; this is not a plugin discovery problem.

`IDE/plugins/qt/platforms/libqxcb.so` declares:

```text
RUNPATH=$ORIGIN/../../lib
```

From `IDE/plugins/qt/platforms`, that expands to `IDE/plugins/lib`. The actual
libraries are in `IDE/lib`, which would require `$ORIGIN/../../../lib`.
The same incorrect runpath is present on other bundled Qt plugins.

Consequently, while loading `libqxcb.so`, the dynamic loader finds the system
copy of `libQt5XcbQpa.so.5` instead of `IDE/lib/libQt5XcbQpa.so.5`. This mixes
system Qt 5.15.19 with the bundled Qt 5.15.14 and bundled C++ runtime. The
precise loader error was:

```text
IDE/lib/libstdc++.so.6: version `GLIBCXX_3.4.30' not found
(required by /usr/lib/libQt5XcbQpa.so.5)
```

Qt then reduces that loader failure to the generic message:

```text
Could not load the Qt platform plugin "xcb" ... even though it was found
```

Adding `IDE/lib` to `LD_LIBRARY_PATH` makes the plugin resolve
`libQt5XcbQpa.so.5` and the rest of Qt from the same bundled library set. This
fixes XCB loading.

## Why native Wayland does not work

The package contains Wayland platform plugins, but does **not** contain their
required `libQt5WaylandClient.so.5`. The loader therefore uses the system
library.

With the bundled C++ runtime, this first fails with:

```text
IDE/lib/libstdc++.so.6: version `GLIBCXX_3.4.30' not found
(required by /usr/lib/libQt5WaylandClient.so.5)
```

Preloading the system C++ runtime does not make this combination valid. It
only advances to a Qt private-ABI mismatch:

```text
/usr/lib/libQt5WaylandClient.so.5: undefined symbol:
_ZTI27QPlatformServiceColorPicker, version Qt_5_PRIVATE_API
```

Qt platform backends use Qt private APIs and must match the bundled Qt build.
Native Wayland would require a matching Qt 5.15.14
`libQt5WaylandClient.so.5` and its matching dependency set. For this package,
forcing XCB and using Xwayland is the reliable solution.

## Freetype workaround

The existing system Freetype preload should be retained:

```sh
export LD_PRELOAD="/usr/lib/libfreetype.so.6${LD_PRELOAD:+:$LD_PRELOAD}"
```

Use the SONAME (`libfreetype.so.6`) rather than the development symlink
(`libfreetype.so`). The latter may not exist on systems without development
package links.

`LD_PRELOAD` takes precedence over `LD_LIBRARY_PATH`, so this still replaces
the broken bundled Freetype while `LD_LIBRARY_PATH` ensures that the coherent
bundled Qt set is used.

## OpenGL fix

The initial QPA fix exposed this warning:

```text
QXcbIntegration: Cannot create platform OpenGL context,
neither GLX nor EGL are enabled
```

This was not caused by a missing Mesa library. `IDE/bin/gw_ide` unconditionally
executes the equivalent of:

```cpp
qputenv("QT_XCB_GL_INTEGRATION", "none");
```

That overwrites any value exported by the launcher before `QApplication`
initializes. `compat/libgowin-env-shim.so` intercepts the Qt `qputenv` function
and ignores only this assignment. All other calls are forwarded to the bundled
Qt library. The launcher can consequently select the shipped `xcb_glx`
integration.

There is a second graphics compatibility boundary. Mesa loads its GPU driver
at runtime, after the main ELF dependency closure is resolved. Because
`IDE/lib` is on `LD_LIBRARY_PATH`, Mesa initially inherited Gowin's old
`libstdc++.so.6`, which exports symbols only through `GLIBCXX_3.4.28`.
The current Arch Mesa driver could not initialize and GLX reported that it
could not find an RGB visual or framebuffer configuration.

When `GOWIN_OPENGL=1` is set, the launcher therefore preloads the host:

- `libstdc++.so.6`, required by the current Mesa driver
- `libGLdispatch.so.0` and `libGLX.so.0`, keeping the host GLVND stack coherent
- `libfreetype.so.6`, as required by the earlier font workaround

These are runtime/graphics boundary libraries; the application still loads
all Qt libraries and Qt plugins from its own bundle. With this setup, Qt logs:

```text
Xcb GLX gl-integration created
Xcb GLX gl-integration successfully initialized
```

The GUI then starts without the previous OpenGL warning or GLX crash. Hardware
acceleration is opt-in:

```sh
GOWIN_OPENGL=1 ./start-ide.sh
```

## Diagnostic commands

Show plugin loader errors:

```sh
QT_DEBUG_PLUGINS=1 ./start-ide.sh
```

Inspect the incorrect plugin runpath:

```sh
readelf -d IDE/plugins/qt/platforms/libqxcb.so |
  grep -E 'RPATH|RUNPATH'
```

Compare resolution before and after applying the library path:

```sh
ldd IDE/plugins/qt/platforms/libqxcb.so

LD_LIBRARY_PATH="$PWD/IDE/lib" \
  ldd IDE/plugins/qt/platforms/libqxcb.so
```

The corrected result must include:

```text
libQt5XcbQpa.so.5 => .../IDE/lib/libQt5XcbQpa.so.5
libQt5Gui.so.5    => .../IDE/lib/libQt5Gui.so.5
libQt5Core.so.5   => .../IDE/lib/libQt5Core.so.5
```

## Packaging-quality fix

For redistributing the package, the preferable fix is to rewrite each Qt
plugin runpath from `$ORIGIN/../../lib` to `$ORIGIN/../../../lib` with a tool
such as `patchelf`, then verify every plugin's dependency closure. The launcher
workaround is less invasive and was the only change tested here.

Do not replace all bundled libraries with host libraries. Qt plugins depend
on private ABI, so mixing patch-level/distribution builds can fail even when
the public sonames are identical.
