# Makefile for building KiCad (and dependencies) on Mac OS X.
#
# Written by Henrik Brix Andersen <henrik@brixandersen.dk>
#
# This Makefile is licenced under the GPLv2, same as KiCad itself.

# KiCad version
KICAD_VERSION=5363
KICAD_BUILD_TYPE=Release
#KICAD_BUILD_TYPE=Debug
KICAD_BUILD_DATE:=$(shell date '+%Y-%m-%d')

# Minimum OS X version to support
OSX_DEPLOYMENT_TARGET=10.9

# Dependency versions
BZRTOOLS_VERSION=2.6.0
BZR_VERSION=2.6.0
CMAKE_VERSION=3.0.2
LIBPNG_VERSION=1.4.12
WX_VERSION=3.0.2

# OS X version
OSX_VERSION:=$(shell sw_vers -productVersion)
OSX_VERSION_MAJOR=$(shell echo $(OSX_VERSION) | cut -d . -f 1)
OSX_VERSION_MINOR=$(shell echo $(OSX_VERSION) | cut -d . -f 2)
OSX_VERSION_MICRO=$(shell echo $(OSX_VERSION) | cut -d . -f 3)

# Common directories
DOWNLOADS=downloads
PATCHES=patches

# BZR
BZR_TARBALL=bzr-$(BZR_VERSION).tar.gz
BZR_URL=https://launchpadlibrarian.net/145980211/$(BZR_TARBALL)
BZR_SRC=bzr-src
BZR_BIN=bzr-bin
BZR_UNPACKED=$(BZR_SRC)/.stamp.unpacked
export BZR_EMAIL="Kicad Build <nobody@foo>"
BZR?=$(BZR_BIN)/bin/bzr

# BZRTools
BZRTOOLS_TARBALL=bzrtools-$(BZRTOOLS_VERSION).tar.gz
BZRTOOLS_URL=https://launchpadlibrarian.net/162313124/$(BZRTOOLS_TARBALL)
BZRTOOLS_SRC=bzrtools-src
BZRTOOLS_UNPACKED=$(BZRTOOLS_SRC)/.stamp.unpacked

# CMake
CMAKE_TARBALL=cmake-$(CMAKE_VERSION).tar.gz
CMAKE_URL=http://www.cmake.org/files/v3.0/$(CMAKE_TARBALL)
CMAKE_SRC=cmake-src
CMAKE_BIN=cmake-bin
CMAKE_UNPACKED=$(CMAKE_SRC)/.stamp.unpacked
CMAKE?=$(CMAKE_BIN)/bin/cmake

# wxWidgets
WX_TARBALL=wxWidgets-$(WX_VERSION).tar.bz2
WX_URL=http://heanet.dl.sourceforge.net/project/wxwindows/$(WX_VERSION)/$(WX_TARBALL)
WX_SRC=wx-src
WX_BUILD=wx-build
WX_BIN=wx-bin
WX_UNPACKED=$(WX_SRC)/.stamp.unpacked
WX_CONFIG?=$(WX_BIN)/bin/wx-config

# libpng
LIBPNG_TARBALL=libpng-$(LIBPNG_VERSION).tar.bz2
LIBPNG_URL=http://heanet.dl.sourceforge.net/project/libpng/libpng14/older-releases/$(LIBPNG_VERSION)/$(LIBPNG_TARBALL)

# KiCad
KICAD_URL=https://code.launchpad.net/~kicad-product-committers/kicad/product
KICAD_SRC=kicad-src
KICAD_BUILD=kicad-build
KICAD_BIN=kicad-bin
KICAD_APP=$(KICAD_BIN)/kicad.app
KICAD_DMG=KiCad_$(KICAD_BUILD_TYPE)_r$(KICAD_VERSION)_$(KICAD_BUILD_DATE).dmg

# KiCad Library
KICADLIB_URL=https://github.com/KiCad/kicad-library.git
KICADLIB_SRC=kicad-library-src
KICADLIB_BUILD=kicad-library-build
KICADLIB_BIN=kicad-library-bin
KICADLIB_TARBALL=kicad-library_$(KICAD_BUILD_DATE).tar.bz2

# KiCad Documentation
KICADDOC_URL=https://code.launchpad.net/~kicad-developers/kicad/doc
KICADDOC_SRC=kicad-doc-src
KICADDOC_BUILD=kicad-doc-build
KICADDOC_BIN=kicad-doc-bin

# Environment
export PATH:=$(CURDIR)/$(BZR_BIN)/bin:$(CURDIR)/$(CMAKE_BIN)/bin:$(CURDIR)/$(WX_BIN)/bin:$(PATH)

# KiCad build environment requires full path to compilers
CLANG=$(shell which clang)
CLANGPP=$(shell which clang++)

# Top-level rules
.PHONY: all app clean cleanall dmg force lib

all: app lib

app: $(KICAD_APP)

lib: $(KICADLIB_TARBALL)

dmg: $(KICAD_DMG)

clean:
	$(RM) -r $(BZR_SRC) $(BZRTOOLS_SRC) $(BZR_BIN)
	$(RM) -r $(CMAKE_SRC) $(CMAKE_BIN)
	$(RM) -r $(WX_SRC) $(WX_BUILD) $(WX_BIN)
	$(RM) -r $(KICAD_BUILD) $(KICAD_BIN)
	$(RM) -r $(KICADLIB_BUILD) $(KICADLIB_BIN)
	$(RM) -r $(KICADDOC_BUILD) $(KICADDOC_BIN)

cleanall: clean
	$(RM) -r $(DOWNLOADS)
	$(RM) -r $(KICAD_SRC)
	$(RM) -r $(KICADLIB_SRC)
	$(RM) -r $(KICADDOC_SRC)

# KiCad
$(KICAD_SRC): force | $(BZR)
	if ! [ -d $(KICAD_SRC) ]; then \
		bzr checkout -r $(KICAD_VERSION) $(KICAD_URL) $(KICAD_SRC) && \
		bzr patch -v -p 1 $(CURDIR)/$(PATCHES)/kicad-disable-download-wxwidgets.diff; \
	else \
		cd $(KICAD_SRC) && bzr up -r $(KICAD_VERSION); \
	fi

$(KICAD_APP): $(KICAD_SRC) | $(BZR) $(CMAKE) $(WX_CONFIG) $(DOWNLOADS)/$(LIBPNG_TARBALL)
	mkdir -p $(KICAD_BUILD)
	cd $(KICAD_BUILD) && \
		$(CURDIR)/$(CMAKE) $(CURDIR)/$(KICAD_SRC) \
			-DCMAKE_C_COMPILER=$(CLANG) \
			-DCMAKE_CXX_COMPILER=$(CLANGPP) \
			-DCMAKE_OSX_DEPLOYMENT_TARGET=$(OSX_DEPLOYMENT_TARGET) \
			-DwxWidgets_CONFIG_EXECUTABLE=$(CURDIR)/$(WX_CONFIG) \
			-DUSE_OSX_DEPS_BUILDER=ON \
			-DKICAD_BUILD_STATIC=ON \
			-DBUILD_GITHUB_PLUGIN=ON \
			-DKICAD_SCRIPTING=OFF \
			-DKICAD_SCRIPTING_MODULES=OFF \
			-DKICAD_SCRIPTING_WXPYTHON=OFF \
			-DCMAKE_INSTALL_PREFIX=$(CURDIR)/$(KICAD_BIN) \
			-DCMAKE_BUILD_TYPE=$(KICAD_BUILD_TYPE)
	cp $(DOWNLOADS)/$(LIBPNG_TARBALL) $(KICAD_SRC)/.downloads-by-cmake/
	$(MAKE) -C $(KICAD_BUILD) install

$(KICAD_DMG): $(KICAD_APP)
	cd $(KICAD_SRC)/packaging/mac-osx/dmg-generator && \
		$(SHELL) make-diskimage.sh $(CURDIR)/$@ $(CURDIR)/$(KICAD_BIN) 'KiCad r$(KICAD_VERSION) $(KICAD_BUILD_TYPE) $(KICAD_BUILD_DATE)'

# KiCad Library
$(KICADLIB_SRC): force
	if ! [ -d $(KICADLIB_SRC) ]; then \
		git clone $(KICADLIB_URL) $(KICADLIB_SRC); \
	else \
		cd $(KICADLIB_SRC) && git pull; \
	fi

$(KICADLIB_TARBALL): $(KICADLIB_SRC)
	mkdir -p $(KICADLIB_BUILD)
	cd $(KICADLIB_BUILD) && \
		$(CURDIR)/$(CMAKE) $(CURDIR)/$(KICADLIB_SRC) \
			-DCMAKE_INSTALL_PREFIX=$(CURDIR)/$(KICADLIB_BIN)
	$(MAKE) -C $(KICADLIB_BUILD) install
	tar cfvj $(KICADLIB_TARBALL) -C $(KICADLIB_BIN) .

# KiCad Documentation
$(KICADDOC_SRC): force | $(BZR)
	if ! [ -d $(KICADDOC_SRC) ]; then \
		bzr checkout $(KICADDOC_URL) $(KICADDOC_SRC); \
	else \
		cd $(KICADDOC_SRC) && bzr up; \
	fi

# Bazaar
$(DOWNLOADS)/$(BZR_TARBALL):
	mkdir -p $(dir $@)
	curl -o $@ $(BZR_URL)

$(DOWNLOADS)/$(BZRTOOLS_TARBALL):
	mkdir -p $(dir $@)
	curl -o $@ $(BZRTOOLS_URL)

$(BZRTOOLS_UNPACKED): $(DOWNLOADS)/$(BZRTOOLS_TARBALL)
	$(RM) -r $(BZRTOOLS_SRC)
	mkdir -p $(BZRTOOLS_SRC)
	tar xf $< --strip-components 1 -C $(BZRTOOLS_SRC)
	touch $@

$(BZR_UNPACKED): $(DOWNLOADS)/$(BZR_TARBALL)
	$(RM) -r $(BZR_SRC)
	mkdir -p $(BZR_SRC)
	tar xf $< --strip-components 1 -C $(BZR_SRC)
	touch $@

$(BZR): $(BZR_UNPACKED) $(BZRTOOLS_UNPACKED)
	$(MAKE) -C $(BZR_SRC)
	cp -r $(BZRTOOLS_SRC) $(BZR_SRC)/bzrlib/plugins/bzrtools
	mkdir -p $(BZR_BIN)/bin
	touch $@
	ln -nsf $(CURDIR)/$(BZR_SRC)/bzr $(BZR_BIN)/bin

# CMake
$(DOWNLOADS)/$(CMAKE_TARBALL):
	mkdir -p $(dir $@)
	curl -o $@ $(CMAKE_URL)

$(CMAKE_UNPACKED): $(DOWNLOADS)/$(CMAKE_TARBALL)
	$(RM) -r $(CMAKE_SRC)
	mkdir -p $(CMAKE_SRC)
	tar xf $< --strip-components 1 -C $(CMAKE_SRC)
	touch $@

$(CMAKE): $(CMAKE_UNPACKED)
	cd $(CMAKE_SRC) && $(SHELL) configure --prefix=$(CURDIR)/$(CMAKE_BIN)
	$(MAKE) -C $(CMAKE_SRC) install

# wxWidgets
$(DOWNLOADS)/$(WX_TARBALL):
	mkdir -p $(dir $@)
	curl -o $@ $(WX_URL)

$(WX_UNPACKED): $(DOWNLOADS)/$(WX_TARBALL) | $(KICAD_SRC)
	mkdir -p $(WX_SRC)
	tar xf $< --strip-components 1 -C $(WX_SRC)
ifeq ($(OSX_VERSION_MINOR),10)
	patch -d $(WX_SRC) -p0 -i $(CURDIR)/$(KICAD_SRC)/patches/wxwidgets-3.0.2_macosx_yosemite.patch
endif
	touch $@

$(WX_CONFIG): $(WX_UNPACKED) $(KICAD_SRC)
	$(SHELL) $(KICAD_SRC)/scripts/osx_build_wx.sh $(WX_SRC) $(WX_BIN) $(KICAD_SRC) $(OSX_DEPLOYMENT_TARGET)

# libpng
$(DOWNLOADS)/$(LIBPNG_TARBALL):
	mkdir -p $(dir $@)
	curl -o $@ $(LIBPNG_URL)
