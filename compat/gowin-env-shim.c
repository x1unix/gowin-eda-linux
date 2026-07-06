#define _GNU_SOURCE

#include <dlfcn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * QByteArray is intentionally opaque here. A C++ reference is passed as a
 * pointer by the x86-64 ABI, and the shim only needs to inspect the key.
 */
typedef bool (*qt_qputenv_fn)(const char *name, const void *value);

bool gowin_qputenv(const char *name, const void *value)
    __asm__("_Z7qputenvPKcRK10QByteArray");

bool gowin_qputenv(const char *name, const void *value)
{
    static qt_qputenv_fn real_qputenv;

    if (strcmp(name, "QT_XCB_GL_INTEGRATION") == 0)
        return true;

    if (real_qputenv == NULL) {
        real_qputenv = (qt_qputenv_fn)dlsym(RTLD_NEXT,
                                            "_Z7qputenvPKcRK10QByteArray");
        if (real_qputenv == NULL) {
            fputs("gowin-env-shim: cannot resolve Qt qputenv\n", stderr);
            abort();
        }
    }

    return real_qputenv(name, value);
}
