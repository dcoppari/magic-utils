PACKAGE_NAME=magic-utils
VERSION ?= $(shell echo $$VERSION)
VERSION := $(if $(VERSION),$(VERSION),dev)
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

build: setup control copy-scripts copy-fonts permissions package

setup:
	mkdir -p $(BIN_DIR)
	mkdir -p $(FONT_DIR)
	mkdir -p $(DEBIAN_DIR)

control:
	@echo "Creating control file..."
	@cat > $(DEBIAN_DIR)/control <<EOF
Package: $(PACKAGE_NAME)
Version: $(VERSION)
Section: utils
Priority: optional
Architecture: $(ARCH)
Maintainer: Diego J. Coppari <diego2k[_at_]gmail.com>
Depends: bash, perl, dos2unix, rlpr, lpr, pdftk, qrencode, imagemagick
Description: MagicSpool Utilities (magicpcl, magicqr, magicspool)
 Suite of tools to process PCL input streams, generate QR codes as PCL,
 apply background to PDFs and handle remote spool via magicspooler.
 Includes bundled pcl6 binary and required TTF fonts in /windows/fonts.
EOF

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

package:
	dpkg-deb --build $(BUILD_DIR) .
	@echo "✅ Package built: $(DEB_FILE)"

clean:
	rm -rf $(BUILD_DIR) $(DEB_FILE)
