#!/usr/bin/env sh
set -eu

root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# Keep the bundled Qt libraries together. The QPA plugins contain an incorrect
# RUNPATH and otherwise load ABI-incompatible Qt libraries from the host.
export LD_LIBRARY_PATH="$root/IDE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# The bundled Freetype is incompatible with libraries on the host system.
export LD_PRELOAD="/usr/lib/libfreetype.so.6${LD_PRELOAD:+:$LD_PRELOAD}"

# The bundled Wayland plugin is missing its matching QtWaylandClient library.
# Use the bundled XCB backend through Xwayland instead.
export QT_QPA_PLATFORM=xcb

# Uncomment to enable the experimental hardware-accelerated OpenGL workaround.
# export GOWIN_OPENGL=1

if [ "${GOWIN_OPENGL:-0}" = 1 ]; then
    # Keep the bundled Qt ABI, but use the host runtimes required by Mesa. The
    # shim prevents gw_ide from changing the GL integration back to "none".
    export LD_PRELOAD="$root/compat/libgowin-env-shim.so:/usr/lib/libstdc++.so.6:/usr/lib/libGLdispatch.so.0:/usr/lib/libGLX.so.0:$LD_PRELOAD"
    export QT_XCB_GL_INTEGRATION=xcb_glx
fi

cd "$root/IDE"
exec ./bin/gw_ide "$@"