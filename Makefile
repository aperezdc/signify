#
# Makefile
# Adrian Perez, 2014-01-14 14:33
#

S := crypto_api.c \
     mod_ed25519.c \
		 mod_ge25519.c \
		 fe25519.c \
		 sc25519.c \
		 smult_curve25519_ref.c \
		 bcrypt_pbkdf.c \
		 timingsafe_bcmp.c \
		 blowfish.c \
		 base64.c \
		 signify.c
O := $(patsubst %.c,%.o,$S)

PKG_CFLAGS := $(shell pkg-config openssl libbsd --cflags)
PKG_LDLIBS := $(shell pkg-config openssl libbsd --libs)

all: signify

signify: $O
	$(CC) $(LDFLAGS) -o $@ $^ $(PKG_LDLIBS)
signify: CFLAGS += $(PKG_CFLAGS) -Wall

clean:
	$(RM) $O signify signify.1.gz

signify.1.gz: signify.1
	gzip -9c $< > $@

install: signify signify.1.gz
	install -m 755 -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 -t $(DESTDIR)$(PREFIX)/bin signify
	install -m 755 -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man1 signify.1.gz

.PHONY: install
