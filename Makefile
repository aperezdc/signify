##################################################################
# The following variables may be overriden in the command line:  #
#                                                                #
MUSL           ?= 0
BUNDLED_LIBBSD ?= 0
PLEDGE         ?= noop
libbsd_VERSION ?= 0.8.1
libbsd_BASEURL ?= http://libbsd.freedesktop.org/releases/
#                                                                #
##################################################################

CFLAGS   += $(EXTRA_CFLAGS)
LDFLAGS  += $(EXTRA_LDFLAGS)
CPPFLAGS += -include compat.h

S := crypto_api.c \
     mod_ed25519.c \
	 mod_ge25519.c \
	 fe25519.c \
	 sc25519.c \
	 smult_curve25519_ref.c \
	 bcrypt_pbkdf.c \
	 timingsafe_bcmp.c \
	 explicit_bzero.c \
	 blowfish.c \
	 base64.c \
	 sha2.c \
	 sha256hl.c \
	 sha512hl.c \
	 signify.c

PLEDGE := $(strip $(PLEDGE))
ifneq ($(PLEDGE),)
    S += pledge_$(PLEDGE).c
endif

MUSL := $(strip $(MUSL))
ifeq ($(MUSL),1)
  CC ?= musl-gcc
  BUNDLED_LIBBSD := 1
endif

BUNDLED_LIBBSD := $(strip $(BUNDLED_LIBBSD))
BUNDLED_LIBBSD_VERIFY_GPG := $(strip $(BUNDLED_LIBBSD_VERIFY_GPG))

ifneq ($(BUNDLED_LIBBSD_VERIFY_GPG),0)
  ifeq ($(BUNDLED_LIBBSD_VERIFY_GPG),)
    # Try to detect whether "gpg" is installed.
    BUNDLED_LIBBSD_VERIFY_GPG := $(shell which gpg 2> /dev/null || echo 0)
  endif
endif


all: signify
clean:


# Building a static binary with Musl requires a patched libbsd.
# The rules take care of:
#
#   - Downloading a release (needed tools: wget).
#   - Check the PGP signature (needed tools: gpg).
#   - Unpack the tarball (needed tools: xz, tar).
#   - Patch libbsd (needed tools: patch).
#   - Build libbsd.
#
# TODO: Also support curl for downloads.
#
ifeq ($(BUNDLED_LIBBSD),1)

libbsd_VERSION  := $(strip $(libbsd_VERSION))
libbsd_BASEURL  := $(strip $(libbsd_BASEURL))
libbsd_PATCH    := libbsd-$(libbsd_VERSION)-musl.patch
libbsd_TAR_NAME := libbsd-$(libbsd_VERSION).tar.xz
libbsd_TAR_URL  := $(libbsd_BASEURL)/$(libbsd_TAR_NAME)
libbsd_ARLIB    := libbsd-prefix/lib/libbsd.a
libbsd_INCLUDE  := libbsd-prefix/include

ifneq ($(BUNDLED_LIBBSD_VERIFY_GPG),0)
libbsd_ASC_NAME := $(libbsd_TAR_NAME).asc
libbsd_ASC_URL  := $(libbsd_BASEURL)/$(libbsd_ASC_NAME)
$(libbsd_ASC_NAME):
	wget -cO $@ '$(libbsd_ASC_URL)'
	touch $@
endif

$(libbsd_TAR_NAME): $(libbsd_ASC_NAME)
	wget -cO $@ '$(libbsd_TAR_URL)'
ifneq ($(BUNDLED_LIBBSD_VERIFY_GPG),0)
	$(BUNDLED_LIBBSD_VERIFY_GPG) --verify $(libbsd_ASC_NAME)
endif
	touch $@

libbsd-download: $(libbsd_TAR_NAME)

libbsd-clean:
	$(RM) -r libbsd-prefix libbsd-$(libbsd_VERSION)

clean: libbsd-clean

libbsd-print-urls:
ifneq ($(BUNDLED_LIBBSD_VERIFY_GPG),0)
	@echo '$(libbsd_ASC_URL)'
endif
	@echo '$(libbsd_TAR_URL)'

libbsd-$(libbsd_VERSION)/configure: $(libbsd_TAR_NAME)
	unxz -c $< | tar -xf -
	touch $@

libbsd-$(libbsd_VERSION)/.patched: libbsd-0.8.1/configure $(libbsd_PATCH)
ifeq ($(MUSL),1)
	patch -p0 < $(libbsd_PATCH)
endif
	touch $@

libbsd-$(libbsd_VERSION)/Makefile: libbsd-$(libbsd_VERSION)/.patched
	( cd libbsd-$(libbsd_VERSION) && ./configure \
		--enable-static --disable-shared \
		--prefix=$$(pwd)/../libbsd-prefix \
		CC=$(CC) LD=$(CC) )

$(libbsd_ARLIB) $(libbsd_INCLUDE)/bsd/bsd.h: libbsd-$(libbsd_VERSION)/Makefile
	$(MAKE) -C libbsd-$(libbsd_VERSION) install

.PHONY: libbsd-download libbsd-clean libbsd-print-urls

LIBBSD_DEPS    := libbsd-prefix/lib/libbsd.a
LIBBSD_CFLAGS  := -isystem libbsd-prefix/include
LIBBSD_LDFLAGS :=

$S: $(libbsd_INCLUDE)/bsd/bsd.h

else

LIBBSD_PKG_VERSION := 0.7
LIBBSD_PKG_CHECK   := $(shell pkg-config libbsd --atleast-version=$(LIBBSD_PKG_VERSION) && echo ok)
ifneq ($(strip $(LIBBSD_PKG_CHECK)),ok)
  $(error libbsd is not installed or version is older than $(LIBBSD_PKG_VERSION))
endif
LIBBSD_DEPS    :=
LIBBSD_CFLAGS  := $(shell pkg-config libbsd --cflags)
LIBBSD_LDFLAGS := $(shell pkg-config libbsd --libs)

endif


# In order to use libwaive, we need libseccomp and making sure that the
# Git submodule corresponding to libwaive is properly checked out.
#
ifeq ($(PLEDGE),waive)
SECCOMP_CFLAGS := $(shell pkg-config libseccomp --cflags)
SECCOMP_LIBS   := $(shell pkg-config libseccomp --libs)
CFLAGS  += $(SECCOMP_CFLAGS) -pthread
LDFLAGS += $(SECCOMP_LIBS) -pthread
S       += libwaive/waive.c

libwaive/waive.c: .gitmodules
	git submodule init && git submodule update libwaive
	touch $@
endif

ifeq ($(strip $(VERIFY_ONLY)),)
S += ohash.c
else
     CPPFLAGS += -DVERIFY_ONLY=1
     $(warning )
     $(warning ******************************************************)
     $(warning )
     $(warning Building with VERIFY_ONLY enabled is unsupported, YMMV)
     $(warning )
     $(warning ******************************************************)
     $(warning )
endif

ifeq ($(strip $(BOUNDS_CHECKING)),1)
    CPPFLAGS += -DCOMPAT_BOUNDS_CHECKING
endif

ifneq ($(strip $(LTO)),)
    CFLAGS += -flto
    LDFLAGS += -flto
endif

O := $(patsubst %.c,%.o,$S)


signify: CFLAGS += $(LIBBSD_CFLAGS) -Wall
signify: $O $(LIBBSD_DEPS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBBSD_LDFLAGS)

clean-signify:
	$(RM) $O signify signify.1.gz sha256hl.c sha512hl.c

clean: clean-signify
.PHONY: clean-signify

signify.1.gz: signify.1
	gzip -9c $< > $@

sha256hl.c: helper.c
	sed -e 's/hashinc/sha2.h/g' \
	    -e 's/HASH/SHA256/g' \
	    -e 's/SHA[0-9][0-9][0-9]_CTX/SHA2_CTX/g' $< > $@

sha512hl.c: helper.c
	sed -e 's/hashinc/sha2.h/g' \
	    -e 's/HASH/SHA512/g' \
	    -e 's/SHA[0-9][0-9][0-9]_CTX/SHA2_CTX/g' $< > $@

install: signify signify.1.gz
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 -t $(DESTDIR)$(PREFIX)/bin signify
	install -m 755 -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man1 signify.1.gz

.PHONY: install

GIT_TAG  = $(shell git describe --tags HEAD)
dist: T := $(GIT_TAG)
dist: V := $(patsubst v%,%,$T)
dist:
	git archive --prefix=signify-$V/ $T | xz -9c > signify-$V.tar.xz

.PHONY: dist
