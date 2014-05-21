#
# Makefile
# Adrian Perez, 2014-01-14 14:33
#

CFLAGS += $(EXTRA_CFLAGS)
LDFLAGS += $(EXTRA_LDFLAGS)

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

ifeq ($(strip $(VERIFY_ONLY)),)
S += ohash_init.c \
     ohash_enum.c \
     ohash_delete.c \
     ohash_entries.c \
     ohash_qlookup.c \
     ohash_qlookupi.c \
     ohash_interval.c \
     ohash_lookup_interval.c \
     ohash_do.c
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

ifeq ($(strip $(BOUNDS_CHECKING)),)
    CPPFLAGS += -D'__bounded__(a,b,c)='
endif

ifneq ($(strip $(LTO)),)
    CFLAGS += -flto
    LDFLAGS += -flto
endif

O := $(patsubst %.c,%.o,$S)

PKG_CFLAGS := $(shell pkg-config libbsd --cflags)
PKG_LDLIBS := $(shell pkg-config libbsd --libs)

all: signify

signify: $O
	$(CC) $(LDFLAGS) -o $@ $^ $(PKG_LDLIBS)
signify: CFLAGS += $(PKG_CFLAGS) -Wall

clean:
	$(RM) $O signify signify.1.gz sha256hl.c sha512hl.c

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
