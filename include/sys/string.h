/* SPDX-License-Identifier: GPL-2.0 */
#pragma once

#include <sys/types.h>

void *memchr(const void *s, int c, size_t n);
int memcmp(const void *dest, const void *src, size_t count);
size_t memfind64(const uint64_t *s, uint64_t v, size_t n);
void *memset(void *s, int c, size_t count);
void *memset64(uint64_t *s, uint64_t v, size_t n);
void *memmove(void *dest, const void *src, size_t count);
void memzero_explicit(void *s, size_t count);

/*
 * Expand memcpy according to dest/src tyeps to avoid modeling it.
 * In all our use cases, the size is constant.
 */

#define memcpy(dest, src, n)                                                    \
        __builtin_choose_expr((sizeof(*(dest)) == 8) && (sizeof(*(src)) == 8),  \
                              __memcpy_64((dest), (src), (n)),                  \
        __builtin_choose_expr((sizeof(*(dest)) == 4) && (sizeof(*(src)) == 4),  \
                              __memcpy_32((dest), (src), (n)),                  \
        __builtin_choose_expr((sizeof(*(dest)) == 2) && (sizeof(*(src)) == 2),  \
                              __memcpy_16((dest), (src), (n)),                  \
        __memcpy_8((dest), (src), (n)))))

#define __memcpy(n)                                             \
static inline                                                   \
void *__memcpy_##n(void *dest, const void *src, size_t count)   \
{                                                               \
        uint##n##_t *tmp = dest;                                \
        const uint##n##_t *s = src;                             \
                                                                \
        if (count % sizeof(uint##n##_t))                        \
                return __memcpy_8(dest, src, count);            \
                                                                \
        for (; count; count -= sizeof(uint##n##_t))             \
                *tmp++ = *s++;                                  \
        return dest;                                            \
}

__memcpy(8)
__memcpy(16)
__memcpy(32)
__memcpy(64)

#undef __memcpy

char *strchr(const char *s, int c);
int strcmp(const char *dest, const char *src);
size_t strlen(const char *s);
int strncmp(const char *dest, const char *src, size_t count);
size_t strnlen(const char *s, size_t count);
char *strpbrk(const char *s, const char *accept);
char *strrchr(const char *s, int c);
ssize_t strscpy(char *dest, const char *src, size_t count);
char *strsep(char **stringp, const char *delim);
char *strstr(const char *haystack, const char *needle);

/**
 * kbasename - return the last part of a pathname.
 *
 * @path: path to extract the filename from.
 */
static inline const char *kbasename(const char *path)
{
        const char *tail = strrchr(path, '/');
        return tail ? tail + 1 : path;
}
