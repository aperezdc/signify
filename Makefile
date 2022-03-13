##################################################################
# The following variables may be overriden in the command line:  #
#                                                                #
BZERO          ?=
MUSL           ?= 0
BUNDLED_LIBBSD ?= 0
PLEDGE         ?= noop
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
	 bcrypt_pbkdf.c \
	 timingsafe_bcmp.c \
	 blowfish.c \
	 base64.c \
	 sha2.c \
	 sha256hl.c \
	 sha512hl.c \
	 sha512_256hl.c \
	 signify.c \
	 zsig.c

define SED_LAST_LINE
sed -n -e '/^[a-zA-Z_-]\+$$/p' | sed -n '$$p'
endef

BZERO := $(strip $(BZERO))
ifeq ($(BZERO),)
  BZERO := $(strip $(shell $(CC) -x c -E -P explicit_bzero.h | $(SED_LAST_LINE)))
endif
ifeq ($(BZERO),bundled)
  CPPFLAGS += -DBUNDLED_BZERO=1
  S += explicit_bzero.c
endif

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


all: signify
clean:


ifeq ($(BUNDLED_LIBBSD),1)

S += libbsd/arc4random.c \
     libbsd/freezero.c \
     libbsd/progname.c \
     libbsd/readpassphrase.c \
     libbsd/strlcpy.c

libbsd-config.h:
	for i in $(patsubst conf/%.c,%,$(wildcard conf/*.c)); do \
		if $(CC) $(LDFLAGS) -o conf-$$i conf/$$i.c > /dev/null 2>&1 ; then \
			echo "#define $$i" ; \
		fi ; \
		$(RM) conf-$$i ; \
	done > $@

clean: clean-libbsd-config

clean-libbsd-config:
	$(RM) libbsd-config.h

.PHONY: clean-libbsd-config

$S: libbsd-config.h

LIBBSD_DEPS    :=
LIBBSD_CFLAGS  := -isystem libbsd/bsd -DLIBBSD_OVERLAY -include libbsd-config.h
LIBBSD_LDFLAGS :=

else

LIBBSD_PKG_VERSION := 0.7
LIBBSD_PKG_CHECK   := $(shell pkg-config libbsd --atleast-version=$(LIBBSD_PKG_VERSION) && echo ok)
ifneq ($(strip $(LIBBSD_PKG_CHECK)),ok)
  $(error libbsd is not installed or version is older than $(LIBBSD_PKG_VERSION))
endif
LIBBSD_DEPS    :=
LIBBSD_CFLAGS  := $(shell pkg-config libbsd-overlay --cflags)
LIBBSD_LDFLAGS := $(shell pkg-config libbsd-overlay --libs)

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

ifneq ($(wildcard .gitmodules),)
libwaive/waive.c: .gitmodules
	git submodule init && git submodule update libwaive
	touch $@
endif
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


signify: override CFLAGS += $(LIBBSD_CFLAGS) -Wall
signify: $O $(LIBBSD_DEPS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBBSD_LDFLAGS) $(LDLIBS)

zsig.o signify.o bcrypt_pbkdf.o: override CFLAGS += -Wno-pointer-sign

clean-signify:
	$(RM) $O signify signify.1.gz sha256hl.c sha512hl.c sha512_256hl.c

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

sha512_256hl.c:	helper.c
	sed -e 's/hashinc/sha2.h/g' \
	    -e 's/HASH/SHA512_256/g' \
	    -e 's/SHA512_256_CTX/SHA2_CTX/g' $< > $@

install: signify signify.1.gz
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 -t $(DESTDIR)$(PREFIX)/bin signify
	install -m 755 -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man1 signify.1.gz

.PHONY: install

ifneq ($(wildcard .git/),)
GIT_TAG  = $(shell git describe --tags HEAD)
dist: T := $(GIT_TAG)
dist: V := $(patsubst v%,%,$T)
dist:
	git archive-all --force-submodules --prefix=signify-$V/ signify-$V.tar
	xz -f9 signify-$V.tar

.PHONY: dist
endif

check: signify
	@sh regress/run

.PHONY: check

static:
	$(MAKE) EXTRA_CFLAGS='$(EXTRA_CFLAGS) -pthread' EXTRA_LDFLAGS='$(EXTRA_LDFLAGS) -pthread -static' BUNDLED_LIBBSD=1

static-musl:
	$(MAKE) EXTRA_CFLAGS='$(EXTRA_CFLAGS) -pthread' EXTRA_LDFLAGS='$(EXTRA_LDFLAGS) -pthread -static' MUSL=1 CC=musl-gcc LD=musl-gcc

.PHONY: static static-musl
