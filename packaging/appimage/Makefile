APP_NAME := GOWIN EDA
APP_ID := com.gowinsemi.GowinEDA
ICON_NAME := gowin-eda
VERSION ?= v1.9.11.03
ARCH ?= x86_64

APPIMAGETOOL ?= appimagetool
DESKTOP_FILE_VALIDATE ?= desktop-file-validate
RSYNC ?= rsync

SOURCE_DIR ?=
ifeq ($(strip $(SOURCE_DIR)),)
override SOURCE_DIR := ../..
endif
override SOURCE_DIR := $(abspath $(SOURCE_DIR))
IDE_SOURCE_DIR := $(SOURCE_DIR)/IDE
COMPAT_DIR := $(abspath ../../compat)

ifeq ($(wildcard $(IDE_SOURCE_DIR)),)
$(error Invalid SOURCE_DIR '$(SOURCE_DIR)': expected IDE directory at '$(IDE_SOURCE_DIR)')
endif

ifeq ($(wildcard $(IDE_SOURCE_DIR)/bin/gw_ide),)
$(error Invalid SOURCE_DIR '$(SOURCE_DIR)': expected executable at '$(IDE_SOURCE_DIR)/bin/gw_ide')
endif

APPDIR := build/GOWIN_EDA.AppDir
RUNTIME_FILE := build/runtime-$(ARCH)
PAYLOAD_DIR := $(APPDIR)/usr/lib/gowin-eda
SHIM_OUTPUT := $(abspath $(PAYLOAD_DIR)/compat/libgowin-env-shim.so)
DIST_DIR := dist
APPIMAGE := $(DIST_DIR)/GOWIN_EDA-$(VERSION)-$(ARCH).AppImage

ICON_SIZES := 16 24 32 48 256

.PHONY: all appdir appimage clean distclean validate

all: appimage

appdir:
	@printf 'Using GOWIN EDA source directory: %s\n' "$(SOURCE_DIR)"
	mkdir -p $(PAYLOAD_DIR)/IDE $(PAYLOAD_DIR)/compat
	$(MAKE) -C $(COMPAT_DIR) OUTPUT=$(SHIM_OUTPUT)
	$(RSYNC) -a --delete $(IDE_SOURCE_DIR)/ $(PAYLOAD_DIR)/IDE/
	install -m 0755 AppRun $(APPDIR)/AppRun
	rm -f $(APPDIR)/gowin-eda.desktop
	install -m 0644 $(APP_ID).desktop $(APPDIR)/$(APP_ID).desktop
	install -m 0644 icons/gw_ide_256x256.png $(APPDIR)/$(ICON_NAME).png
	ln -sfn $(ICON_NAME).png $(APPDIR)/.DirIcon
	mkdir -p $(APPDIR)/usr/share/applications
	rm -f $(APPDIR)/usr/share/applications/gowin-eda.desktop
	install -m 0644 $(APP_ID).desktop \
		$(APPDIR)/usr/share/applications/$(APP_ID).desktop
	mkdir -p $(APPDIR)/usr/share/metainfo
	rm -f $(APPDIR)/usr/share/metainfo/gowin-eda.metainfo.xml \
		$(APPDIR)/usr/share/metainfo/gowin-eda.appdata.xml
	install -m 0644 $(APP_ID).appdata.xml \
		$(APPDIR)/usr/share/metainfo/$(APP_ID).appdata.xml
	for size in $(ICON_SIZES); do \
		directory="$(APPDIR)/usr/share/icons/hicolor/$${size}x$${size}/apps"; \
		mkdir -p "$$directory"; \
		install -m 0644 "icons/gw_ide_$${size}x$${size}.png" \
			"$$directory/$(ICON_NAME).png"; \
	done

validate:
	$(DESKTOP_FILE_VALIDATE) $(APP_ID).desktop
	appstreamcli validate --no-net $(APP_ID).appdata.xml
	test -x AppRun
	test -x $(IDE_SOURCE_DIR)/bin/gw_ide
	test -f icons/gw_ide_256x256.png

$(RUNTIME_FILE):
	mkdir -p $(dir $(RUNTIME_FILE))
	tool=$$(command -v "$(APPIMAGETOOL)"); \
		offset=$$("$$tool" --appimage-offset); \
		head -c "$$offset" "$$tool" > $(RUNTIME_FILE)
	chmod 0755 $(RUNTIME_FILE)

appimage: validate appdir $(RUNTIME_FILE)
	mkdir -p $(DIST_DIR)
	ARCH=$(ARCH) VERSION=$(VERSION) \
		$(APPIMAGETOOL) --runtime-file $(RUNTIME_FILE) \
			$(APPDIR) $(APPIMAGE)

clean:
	rm -rf build

distclean: clean
	rm -rf $(DIST_DIR)