/*
 * explicit_bzero.h
 * Copyright (C) 2017 Adrian Perez <aperez@igalia.com>
 *
 * Distributed under terms of the MIT license.
 *
 * IMPORTANT: This file is preprocessed manually and the last non-empty
 * line of the output is used by the Makefile.
 */

#include <string.h>

#if defined(__GLIBC__) && defined(__GLIBC_MINOR__) && __GLIBC__ >= 2 && __GLIBC_MINOR__ >= 25
libc
#else
bundled
#endif
