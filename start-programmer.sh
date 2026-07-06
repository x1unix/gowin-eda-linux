#!/usr/bin/env sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# Programmer is a separate PyQt/Qt bundle. Its shared libraries live directly
# next to the executable, so keep that directory first in the dynamic linker
# search path.
export LD_LIBRARY_PATH="$root/Programmer/bin${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# The bundled Freetype is incompatible with libraries on the host system.
# Programmer also does not bundle libpng, so host libpng can otherwise load
# the bundled old zlib and fail on Arch with a missing ZLIB_1.2.3.4 symbol.
export LD_PRELOAD="/usr/lib/libz.so.1:/usr/lib/libfreetype.so.6${LD_PRELOAD:+:$LD_PRELOAD}"

# The bundled Qt plugins are under PyQt5/qt-plugins. Point Qt there explicitly
# so it does not try to mix with host Qt plugin directories.
export QT_PLUGIN_PATH="$root/Programmer/bin/PyQt5/qt-plugins"

# Use the XCB backend through Xwayland. The Programmer bundle does not ship
# Wayland Qt plugins.
export QT_QPA_PLATFORM=xcb

cd "$root/Programmer"
exec ./bin/programmer "$@"
