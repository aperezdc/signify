/*
 * Copyright (c) 2015, Adrián Pérez de Castro <aperez@igalia.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef COMPAT_H
#define COMPAT_H

#ifndef COMPAT_BOUNDS_CHECKING
#define __bounded__(a, b, c)
#endif /* !COMPAT_BOUNDS_CHECKING */

#ifndef __dead
#define __dead
#endif /* !__dead */

#define DEF_WEAK(a)
#define MAKE_CLONE(a, b)

#define SHA224Transform     SHA256Transform
#define SHA224Update        SHA256Update
#define SHA224Pad           SHA256Pad
#define SHA384Transform     SHA512Transform
#define SHA384Update        SHA512Update
#define SHA384Pad           SHA512Pad
#define SHA512_256Transform SHA512Transform
#define SHA512_256Update    SHA512Update
#define SHA512_256Pad       SHA512Pad
#define SHA512_256Data      SHA512Data

#include <stdint.h>
#include <stddef.h>

extern int timingsafe_bcmp(const void *b1, const void *b2, size_t n);
extern void explicit_bzero(void *buf, size_t len);
extern int pledge (const char *promises, const char *paths[]);
extern int bcrypt_pbkdf(const char *pass, size_t passlen,
                        const uint8_t *salt, size_t saltlen,
                        uint8_t *key, size_t keylen,
                        unsigned int rounds);

#endif /* !COMPAT_H */
