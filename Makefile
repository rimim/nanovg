CPPSTD :=
SRCDIR	:= ./src
SRCEXT	:= .c
LIBTARGET	:= libnanovg.a
SOURCES	:= $(SRCDIR)/nanovg.c
HEADERS	:= $(SRCDIR)/nanovg.h $(SRCDIR)/nanovg_gl.h $(SRCDIR)/nanovg_gl_utils.h
ifeq ($(strip $(GL)),2)
SOURCES	+= $(SRCDIR)/nanovg_gl2.c
else ifeq ($(strip $(GL)),3)
SOURCES	+= $(SRCDIR)/nanovg_gl3.c
else ifeq ($(strip $(GL)),ES2)
SOURCES	+= $(SRCDIR)/nanovg_gles2.c
else ifeq ($(strip $(GL)),ES3)
SOURCES	+= $(SRCDIR)/nanovg_gles3.c
else
HEADERS	+= $(SRCDIR)/nanovg_gl.h
endif

ADD_INCLUDE	:= nanovg_full.h
ADD_INSTALL_SOURCES	:= fontstash.h stb_image.h stb_truetype.h

CPPSTD		?= --std=c++1z
CPPFLAGS	+= $(CPPSTD)

override	CPPFLAGS	+= -MMD -MP
override	CPPFLAGS	+= -I./include
override	CPPFLAGS	+= $(shell cat .cxxflags 2> /dev/null | xargs)

ARFLAGS	:= $(ARFLAGS)c

INSTALL_INCLUDE := include
INSTALL_SOURCE := source
INSTALL_LIB	:= lib
#LOCAL_TEMP
#LOCAL_DIST

ifneq ($(shell cat COPYRIGHT 2> /dev/null),)
COPYRIGHT ?= COPYRIGHT
COPYRIGHT_DEP = COPYRIGHT
else
COPYRIGHT ?= /dev/null
endif

PREFIX	:= $(DESTDIR)/usr/local
INCDIR	:= $(PREFIX)/$(INSTALL_INCLUDE)
LIBDIR	:= $(PREFIX)/$(INSTALL_LIB)
INSTALL_SRCDIR	:= $(PREFIX)/$(INSTALL_SOURCE)

SRCDIR	?= ./source
SRCEXT	?= .cpp

TEMPDIR	:= temp
ifneq ($(LOCAL_TEMP),)
TEMPDIR	:= $(TEMPDIR)/$(LOCAL_TEMP)
endif

DISTDIR	:= out
ifneq ($(LOCAL_DIST),)
DISTDIR	:= $(DISTDIR)/$(LOCAL_DIST)
endif

ifeq ($(origin LIBTARGET), undefined)
LIBTARGET	:= $(shell pwd | xargs basename).a
endif

OUT		:= $(DISTDIR)/$(LIBTARGET)

ifeq ($(origin HEADERS), undefined)
HEADERS	:= $(shell find -wholename "$(SRCDIR)/*.hpp" && find -wholename "$(SRCDIR)/*.h")
endif
INCLUDE	:= $(ADD_INCLUDE:%=$(INCDIR)/%) $(HEADERS:$(SRCDIR)/%=$(INCDIR)/%)
INCDIRS	:= $(shell dirname $(INCLUDE))

ifeq ($(origin SOURCES), undefined)
SOURCES	:= $(shell find -wholename "$(SRCDIR)/*$(SRCEXT)")
endif

OBJECTS	:= $(SOURCES:$(SRCDIR)/%$(SRCEXT)=$(TEMPDIR)/%.o)
OBJDIRS	:= $(shell dirname $(OBJECTS))
DEPENDS	:= $(OBJECTS:.o=.d)

INSTALL_SOURCES	:= $(SOURCES:$(SRCDIR)/%=$(INSTALL_SRCDIR)/%)
INSTALL_SOURCES	+= $(INCLUDE:$(INCDIR)/%=$(INSTALL_SRCDIR)/%)
INSTALL_SOURCES	+= $(ADD_INSTALL_SOURCES:%=$(INSTALL_SRCDIR)/%)
INSTALL_SRCDIRS	:= $(shell dirname $(INSTALL_SOURCES))

$(OUT): $(OBJECTS) | $(DISTDIR)
	$(AR) $(ARFLAGS) $@ $^

$(TEMPDIR)/%.o: $(SRCDIR)/%$(SRCEXT) | $(TEMPDIR)
	@mkdir -p $(@D)
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(CXXFLAGS) -o $@ -c $<

$(TEMPDIR):
	@mkdir -p $@

$(DISTDIR):
	@mkdir -p $@

clean:
	@rm $(DEPENDS) 2> /dev/null || true
	@rm $(OBJECTS) 2> /dev/null || true
	@rmdir -p $(OBJDIRS) 2> /dev/null || true
	@rmdir -p $(TEMPDIR) 2> /dev/null || true
	@echo Temporaries cleaned!

distclean: clean
	@rm $(OUT) 2> /dev/null || true
	@rmdir -p $(DISTDIR) 2> /dev/null || true
	@echo All clean!

install_all: install install_source

install: $(LIBDIR)/$(LIBTARGET) $(INCLUDE)

$(LIBDIR)/$(LIBTARGET): $(OUT) | $(LIBDIR)
	cp $< $@

$(LIBDIR):
	@mkdir -p $@

$(INCDIR)/%.h: $(SRCDIR)/%.h $(COPYRIGHT_DEP)
	@mkdir -p $(@D)
	cat $(COPYRIGHT) > $@
	cat $< >> $@

$(INCDIR)/%.hpp: $(SRCDIR)/%.hpp $(COPYRIGHT_DEP)
	@mkdir -p $(@D)
	cat $(COPYRIGHT) > $@
	cat $< >> $@

install_source: $(INSTALL_SOURCES)

$(INSTALL_SRCDIR)/%: $(SRCDIR)/% $(COPYRIGHT_DEP)
	@mkdir -p $(@D)
	cat $(COPYRIGHT) > $@
	cat $< >> $@

uninstall:
	-rm $(INCLUDE)
	@rmdir -p $(INCDIRS) 2> /dev/null || true
	-rm $(LIBDIR)/$(LIBTARGET)
	@rmdir -p $(LIBDIR) 2> /dev/null || true
	@echo Archives/includes uninstalled!

uninstall_source:
	-rm $(INSTALL_SOURCES)
	@rmdir -p $(INSTALL_SRCDIRS) 2> /dev/null || true
	@echo Source code uninstalled!

uninstall_all: uninstall uninstall_source
	@echo Everything uninstalled!


-include $(DEPENDS)

.PRECIOUS : $(OBJECTS)
.PHONY : clean distclean uninstall uninstall_source uninstall_all

ifeq ($(strip $(GL)),2)
$(INCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gl2.h
	@mkdir -p $(@D)
	cp $< $@
$(INSTALL_SRCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gl2.h
	@mkdir -p $(@D)
	cp $< $@
else ifeq ($(strip $(GL)),3)
$(INCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gl3.h
	@mkdir -p $(@D)
	cp $< $@
$(INSTALL_SRCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gl3.h
	@mkdir -p $(@D)
	cp $< $@
else ifeq ($(strip $(GL)),ES2)
$(INCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gles2.h
	@mkdir -p $(@D)
	cp $< $@
$(INSTALL_SRCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gles2.h
	@mkdir -p $(@D)
	cp $< $@
else ifeq ($(strip $(GL)),ES3)
$(INCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gles3.h
	@mkdir -p $(@D)
	cp $< $@
$(INSTALL_SRCDIR)/nanovg_full.h: $(SRCDIR)/nanovg_gles3.h
	@mkdir -p $(@D)
	cp $< $@
endif
