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

#include "libwaive/waive.h"
#include <stddef.h>
#include <string.h>
#include <ctype.h>


static const struct {
    const char *pledge_name;
    int         waive_flag;
} flag_table[] = {
    { "stdio",     WAIVE_PIPE  |
                   WAIVE_SOCKET},
    { "rpath",     WAIVE_OPEN  },
    { "wpath",     WAIVE_OPEN  },
    { "cpath",     0           },
    { "tmppath",   WAIVE_OPEN  },
    { "inet",      WAIVE_INET  },
    { "fattr",     0           },
    { "flock",     WAIVE_OPEN  },
    { "unix",      WAIVE_UN    |
                   WAIVE_SOCKET},
    { "dns",       WAIVE_INET  },
    { "getpw",     WAIVE_OPEN  },
    { "sendfd",    0           },
    { "recvfd",    0           },
    { "ioctl",     0           },
    { "tty",       0           },
    { "proc",      WAIVE_CLONE |
                   WAIVE_KILL  },
    { "exec",      WAIVE_EXEC  },
    { "prot_exec", WAIVE_EXEC  },
    { "settime",   0           },
    { "ps",        0           },
    { "vminfo",    0           },
    { "id",        0           },
    { "pf",        0           },
};


static int
find_flag (const char *pledge_name, size_t len)
{
    size_t i;
    for (i = 0; i < sizeof (flag_table) / sizeof (flag_table[0]); i++) {
        if (strncmp (pledge_name, flag_table[i].pledge_name, len) == 0)
            return flag_table[i].waive_flag;
    }
    return 0;
}


int
pledge (const char *promises, const char *execpromises)
{
    int flags = WAIVE_INET | WAIVE_UN | WAIVE_PACKET | WAIVE_MOUNT |
        WAIVE_OPEN | WAIVE_EXEC | WAIVE_CLONE | WAIVE_KILL |
        WAIVE_PIPE;

    size_t s = 0;
    size_t e = 0;

    (void) execpromises;

    for (;;) {
        while (promises[e] != '\0' && !isspace (promises[e]))
            e++;
        if (s < e)
            flags &= ~find_flag (&promises[s], e-s);
        if (promises[e] == '\0')
            break;
        e++;
        while (promises[e] != '\0' && isspace (promises[e]))
            e++;
        s = e;
    }

    return waive (flags);
}
