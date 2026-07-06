CC ?= cc
CPPFLAGS ?=
CFLAGS ?= -O2
CFLAGS += -fPIC -Wall -Wextra -Werror
LDFLAGS ?=
LDLIBS += -ldl

SHIM := libgowin-env-shim.so
SHIM_SOURCE := gowin-env-shim.c
SHIM_VERSION_MAP := gowin-env-shim.map

.PHONY: all clean

all: $(SHIM)

$(SHIM): $(SHIM_SOURCE) $(SHIM_VERSION_MAP)
	$(CC) $(CPPFLAGS) $(CFLAGS) -shared $(LDFLAGS) \
		-Wl,--version-script=$(SHIM_VERSION_MAP) \
		-Wl,-soname,$(notdir $(SHIM)) \
		-o $@ $(SHIM_SOURCE) $(LDLIBS)

clean:
	rm -f $(SHIM)