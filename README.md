# Gowin EDA Education Linux Fixes

Out of the box, Gowin EDA doesn't work as it isn't packaged properly.

This repo provides a standalone script to start the IDE, and as a bonus, a recipe to build a portable AppImage file.

**Disclaimer:** Most of research is done by OpenAI Codex. See [the research doc](docs/CODEX_RESEARCH.md)

## Usage

### Standalone

1. [Download](https://www.gowinsemi.com/en/support/download_eda/) and extract the Gowin EDA for Linux.
2. [Download](https://github.com/x1unix/gowin-eda-fixes/archive/refs/heads/main.zip) this repository and extract it **near** the `IDE` directory of the application.
3. Use the [`start-ide.sh`](start-ide.sh) shell script to launch the IDE.

### AppImage Generator

This repo provides an [AppImage packaging script](./packaging/appimage/) to generate a portable Linux executable file.

See [the instructions](./packaging/appimage/) to build an AppImage.

## Known Issues

### Native Wayland Support

Application runs inside XWayland as it doesn't provide Wayland support plugin.

### Hardware Acceleration

By default, hardware acceleration is *disabled* by IDE itself before QT application is initialized.

The reason is the bundled `libstdc++.so` (C++ standard library) is different from system's one, thus breaking GPU driver's OpenGL.

There is a hacky way to enable it, but it is **unstable**, *use it at your own risk*.

See [here](compat) for the fix.


## Additional Resources

See [this gist][gist] for troubleshooting programmer issues.

[gist]: https://gist.github.com/retrofun/57b6f0bbca01f0650a8b7137f69dd674
