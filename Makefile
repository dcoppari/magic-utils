PACKAGE_NAME=magic-utils
VERSION_RAW ?= $(shell echo $$VERSION)
VERSION := $(shell echo $(VERSION_RAW) | sed 's/^v//')
ifeq ($(VERSION),)
  VERSION := 0.0.0
endif
RELEASE_NAME := Magic Utils $(VERSION)
ARCH=amd64
BUILD_DIR=$(PACKAGE_NAME)
BIN_DIR=$(BUILD_DIR)/usr/local/bin
FONT_DIR=$(BUILD_DIR)/windows/fonts
DEBIAN_DIR=$(BUILD_DIR)/DEBIAN
DEB_FILE=$(PACKAGE_NAME)_$(VERSION)_$(ARCH).deb

FONTS=fonts/*.ttf
SCRIPTS=magicpcl magicqr magicspool
BINARIES=pcl6

all: clean build

build: clean setup control copy-scripts copy-fonts permissions ownership package

setup:
	mkdir -p $(BIN_DIR)
	mkdir -p $(FONT_DIR)
	mkdir -p $(DEBIAN_DIR)

control:
	@echo "Creating control file..."
	@mkdir -p $(DEBIAN_DIR)
	@printf "Package: %s\n" "$(PACKAGE_NAME)" > $(DEBIAN_DIR)/control
	@printf "Version: %s\n" "$(VERSION)" >> $(DEBIAN_DIR)/control
	@printf "Section: utils\n" >> $(DEBIAN_DIR)/control
	@printf "Priority: optional\n" >> $(DEBIAN_DIR)/control
	@printf "Architecture: %s\n" "$(ARCH)" >> $(DEBIAN_DIR)/control
	@printf "Maintainer: Diego J. Coppari <diego2k[_at_]gmail.com>\n" >> $(DEBIAN_DIR)/control
	@printf "Depends: bash, perl, dos2unix, rlpr, lpr, pdftk, qrencode, imagemagick\n" >> $(DEBIAN_DIR)/control
	@printf "Description: MagicSpool Utilities (magicpcl, magicqr, magicspool)\n" >> $(DEBIAN_DIR)/control
	@printf " Suite of tools to process PCL input streams, generate QR codes as PCL,\n" >> $(DEBIAN_DIR)/control
	@printf " apply background to PDFs and handle remote spool via magicspooler.\n" >> $(DEBIAN_DIR)/control
	@printf " Includes bundled pcl6 binary and required TTF fonts in /windows/fonts.\n" >> $(DEBIAN_DIR)/control

copy-scripts:
	@for f in $(SCRIPTS); do \
	  cp $$f $(BIN_DIR)/ ; \
	done
	cp $(BINARIES) $(BIN_DIR)/pcl6

copy-fonts:
	cp $(FONTS) $(FONT_DIR)/

permissions:
	chmod 755 $(BIN_DIR)/*
	chmod 644 $(FONT_DIR)/*.ttf

ownership:
	@chown -R root:root $(BUILD_DIR)

package:
	dpkg-deb --build $(BUILD_DIR) .
	@echo "✅ Package built: $(DEB_FILE)"
	@echo "📦 Release name: $(RELEASE_NAME)"

clean:
	rm -rf $(BUILD_DIR) $(DEB_FILE)
