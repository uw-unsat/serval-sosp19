#pragma once

#include <io/compiler.h>
#include <io/sizes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdnoreturn.h>
#include <uapi/certikos/elf.h>
#include <uapi/certikos/param.h>

#define assert(expr)                                                                                    \
({                                                                                                      \
        if (!(expr)) {                                                                                  \
                printf("%s:%d: %s: Assertion `%s' failed.\n", __FILE__, __LINE__, __func__, #expr);     \
                while (1) ;                                                                             \
        }                                                                                               \
})

#ifndef max
#define max(a, b)                                                                                       \
({                                                                                                      \
        _Static_assert(__builtin_types_compatible_p(typeof(a), typeof(b)),                              \
                      "must be the same type");                                                         \
        typeof(a) _a = (a);                                                                             \
        typeof(b) _b = (b);                                                                             \
        _a >= _b ? _a : _b;                                                                             \
})
#endif

#ifndef min
#define min(a, b)                                                                                       \
({                                                                                                      \
        _Static_assert(__builtin_types_compatible_p(typeof(a), typeof(b)),                              \
                      "must be the same type");                                                         \
        typeof(a) _a = (a);                                                                             \
        typeof(b) _b = (b);                                                                             \
        _a <= _b ? _a : _b;                                                                             \
 })
 #endif

/* syscalls */
long get_quota(void);
long spawn(size_t fileid, size_t quota);
void yield(void);
void print(unsigned char c);

/* raw syscalls */
long sys_get_quota(void);
long sys_spawn(size_t fileid, size_t quota, size_t pid);
long sys_getpid(void);
long sys_donate(size_t quantum, size_t pid);

/* libc functions */
int memcmp(const void *cs, const void *ct, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
void *memset(void *s, int c, size_t count);
void printf(const char *fmt, ...);
size_t strlen(const char *s);
