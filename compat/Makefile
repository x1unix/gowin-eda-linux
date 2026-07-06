CC ?= cc
CPPFLAGS ?=
CFLAGS ?= -O2
CFLAGS += -fPIC -Wall -Wextra -Werror
LDFLAGS ?=
LDLIBS += -ldl

OUTPUT ?= libgowin-env-shim.so
SHIM_SONAME := libgowin-env-shim.so
SHIM_SOURCE := gowin-env-shim.c
SHIM_VERSION_MAP := gowin-env-shim.map

.PHONY: all clean

all: $(OUTPUT)

$(OUTPUT): $(SHIM_SOURCE) $(SHIM_VERSION_MAP)
	mkdir -p $(dir $(OUTPUT))
	$(CC) $(CPPFLAGS) $(CFLAGS) -shared $(LDFLAGS) \
		-Wl,--version-script=$(SHIM_VERSION_MAP) \
		-Wl,-soname,$(SHIM_SONAME) \
		-o $@ $(SHIM_SOURCE) $(LDLIBS)

clean:
	rm -f $(OUTPUT)