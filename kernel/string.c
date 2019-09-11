// SPDX-License-Identifier: GPL-2.0
/*
 *  linux/lib/string.c
 *
 *  Copyright (C) 1991, 1992  Linus Torvalds
 */

/*
 * stupid library routines.. The optimized versions should generally be found
 * as inline code in <asm-xx/string.h>
 *
 * These are buggy as well..
 *
 * * Fri Jun 25 1999, Ingo Oeser <ioe@informatik.tu-chemnitz.de>
 * -  Added strsep() which will replace strtok() soon (because strsep() is
 *    reentrant and should be faster). Use only strsep() in new code, please.
 *
 * * Sat Feb 09 2002, Jason Thomas <jason@topic.com.au>,
 *                    Matthew Hawkins <matt@mh.dropbear.id.au>
 * -  Kissed strtok() goodbye
 */

#include <asm/word-at-a-time.h>
#include <sys/errno.h>
#include <sys/string.h>

/**
 * memchr - Find a character in an area of memory.
 * @s: The memory area
 * @c: The byte to search for
 * @n: The size of the area.
 *
 * returns the address of the first occurrence of @c, or %NULL
 * if @c is not found
 */
void *memchr(const void *s, int c, size_t n)
{
        const unsigned char *p = s;
        while (n-- != 0) {
                if ((unsigned char)c == *p++) {
                        return (void *)(p - 1);
                }
        }
        return NULL;
}

/**
 * memcmp - Compare two areas of memory
 * @cs: One area of memory
 * @ct: Another area of memory
 * @count: The size of the area.
 */
int memcmp(const void *cs, const void *ct, size_t count)
{
        const unsigned char *su1, *su2;
        int res = 0;

        for (su1 = cs, su2 = ct; 0 < count; ++su1, ++su2, count--)
                if ((res = *su1 - *su2) != 0)
                        break;
        return res;
}

/**
 * memcpy - Copy one area of memory to another
 * @dest: Where to copy to
 * @src: Where to copy from
 * @count: The size of the area.
 *
 * You should not use this function to access IO space, use memcpy_toio()
 * or memcpy_fromio() instead.
 */
#ifndef memcpy
__weak void *memcpy(void *dest, const void *src, size_t count)
{
        char *tmp = dest;
        const char *s = src;

        while (count--)
                *tmp++ = *s++;
        return dest;
}
#endif

size_t memfind64(const uint64_t *s, uint64_t v, size_t n)
{
        size_t i;

        for (i = 0; i < n; ++i) {
                if (s[i] == v)
                        break;
        }
        return i;
}

size_t memfind128(const unsigned __int128 *s, unsigned __int128 v, size_t n)
{
        size_t i;

        for (i = 0; i < n; ++i) {
                if (s[i] == v)
                        break;
        }
        return i;
}

/**
 * memmove - Copy one area of memory to another
 * @dest: Where to copy to
 * @src: Where to copy from
 * @count: The size of the area.
 *
 * Unlike memcpy(), memmove() copes with overlapping areas.
 */
void *memmove(void *dest, const void *src, size_t count)
{
        char *tmp;
        const char *s;

        if (dest <= src) {
                tmp = dest;
                s = src;
                while (count--)
                        *tmp++ = *s++;
        } else {
                tmp = dest;
                tmp += count;
                s = src;
                s += count;
                while (count--)
                        *--tmp = *--s;
        }
        return dest;
}

/**
 * memset - Fill a region of memory with the given value
 * @s: Pointer to the start of the area.
 * @c: The byte to fill the area with
 * @count: The size of the area.
 *
 * Do not use memset() to access IO space, use memset_io() instead.
 */
__weak void *memset(void *s, int c, size_t count)
{
        char *xs = s;

        while (count--)
                *xs++ = c;
        return s;
}

/**
 * memset64() - Fill a memory area with a uint64_t
 * @s: Pointer to the start of the area.
 * @v: The value to fill the area with
 * @count: The number of values to store
 *
 * Differs from memset() in that it fills with a uint64_t instead
 * of a byte.  Remember that @count is the number of uint64_ts to
 * store, not the number of bytes.
 */
void *memset64(uint64_t *s, uint64_t v, size_t count)
{
        uint64_t *xs = s;

        while (count--)
                *xs++ = v;
        return s;
}

/**
 * memzero_explicit - Fill a region of memory (e.g. sensitive
 *                    keying data) with 0s.
 * @s: Pointer to the start of the area.
 * @count: The size of the area.
 *
 * Note: usually using memset() is just fine (!), but in cases
 * where clearing out _local_ data at the end of a scope is
 * necessary, memzero_explicit() should be used instead in
 * order to prevent the compiler from optimising away zeroing.
 *
 * memzero_explicit() doesn't need an arch-specific version as
 * it just invokes the one of memset() implicitly.
 */
void memzero_explicit(void *s, size_t count)
{
        memset(s, 0, count);
        barrier_data(s);
}

/**
 * strchr - Find the first occurrence of a character in a string
 * @s: The string to be searched
 * @c: The character to search for
 */
char *strchr(const char *s, int c)
{
        for (; *s != (char)c; ++s)
                if (*s == '\0')
                        return NULL;
        return (char *)s;
}

/**
 * strcmp - Compare two strings
 * @cs: One string
 * @ct: Another string
 */
int strcmp(const char *cs, const char *ct)
{
        unsigned char c1, c2;

        while (1) {
                c1 = *cs++;
                c2 = *ct++;
                if (c1 != c2)
                        return c1 < c2 ? -1 : 1;
                if (!c1)
                        break;
        }
        return 0;
}

/**
 * strncmp - Compare two length-limited strings
 * @cs: One string
 * @ct: Another string
 * @count: The maximum number of bytes to compare
 */
int strncmp(const char *cs, const char *ct, size_t count)
{
        unsigned char c1, c2;

        while (count) {
                c1 = *cs++;
                c2 = *ct++;
                if (c1 != c2)
                        return c1 < c2 ? -1 : 1;
                if (!c1)
                        break;
                count--;
        }
        return 0;
}

/**
 * strlen - Find the length of a string
 * @s: The string to be sized
 */
size_t strlen(const char *s)
{
        const char *sc;

        for (sc = s; *sc != '\0'; ++sc)
                /* nothing */;
        return sc - s;
}

/**
 * strnlen - Find the length of a length-limited string
 * @s: The string to be sized
 * @count: The maximum number of bytes to search
 */
size_t strnlen(const char *s, size_t count)
{
        const char *sc;

        for (sc = s; count-- && *sc != '\0'; ++sc)
                /* nothing */;
        return sc - s;
}

/**
 * strpbrk - Find the first occurrence of a set of characters
 * @cs: The string to be searched
 * @ct: The characters to search for
 */
char *strpbrk(const char *cs, const char *ct)
{
        const char *sc1, *sc2;

        for (sc1 = cs; *sc1 != '\0'; ++sc1) {
                for (sc2 = ct; *sc2 != '\0'; ++sc2) {
                        if (*sc1 == *sc2)
                                return (char *)sc1;
                }
        }
        return NULL;
}

/**
 * strrchr - Find the last occurrence of a character in a string
 * @s: The string to be searched
 * @c: The character to search for
 */
char *strrchr(const char *s, int c)
{
        const char *last = NULL;
        do {
                if (*s == (char)c)
                        last = s;
        } while (*s++);
        return (char *)last;
}

/**
 * strscpy - Copy a C-string into a sized buffer
 * @dest: Where to copy the string to
 * @src: Where to copy the string from
 * @count: Size of destination buffer
 *
 * Copy the string, or as much of it as fits, into the dest buffer.
 * The routine returns the number of characters copied (not including
 * the trailing NUL) or -E2BIG if the destination buffer wasn't big enough.
 * The behavior is undefined if the string buffers overlap.
 * The destination buffer is always NUL terminated, unless it's zero-sized.
 *
 * Preferred to strlcpy() since the API doesn't require reading memory
 * from the src string beyond the specified "count" bytes, and since
 * the return value is easier to error-check than strlcpy()'s.
 * In addition, the implementation is robust to the string changing out
 * from underneath it, unlike the current strlcpy() implementation.
 *
 * Preferred to strncpy() since it always returns a valid string, and
 * doesn't unnecessarily force the tail of the destination buffer to be
 * zeroed.  If the zeroing is desired, it's likely cleaner to use strscpy()
 * with an overflow test, then just memset() the tail of the dest buffer.
 */
ssize_t strscpy(char *dest, const char *src, size_t count)
{
        const struct word_at_a_time constants = WORD_AT_A_TIME_CONSTANTS;
        size_t max = count;
        long res = 0;

        if (count == 0)
                return -E2BIG;

        /* If src or dest is unaligned, don't do word-at-a-time. */
        if (((long) dest | (long) src) & (sizeof(long) - 1))
                max = 0;

        while (max >= sizeof(unsigned long)) {
                unsigned long c, data;

                c = *(unsigned long *)(src+res);
                if (has_zero(c, &data, &constants)) {
                        data = prep_zero_mask(c, data, &constants);
                        data = create_zero_mask(data);
                        *(unsigned long *)(dest+res) = c & zero_bytemask(data);
                        return res + find_zero(data);
                }
                *(unsigned long *)(dest+res) = c;
                res += sizeof(unsigned long);
                count -= sizeof(unsigned long);
                max -= sizeof(unsigned long);
        }

        while (count) {
                char c;

                c = src[res];
                dest[res] = c;
                if (!c)
                        return res;
                res++;
                count--;
        }

        /* Hit buffer length without finding a NUL; force NUL-termination. */
        if (res)
                dest[res-1] = '\0';

        return -E2BIG;
}

/**
 * strsep - Split a string into tokens
 * @s: The string to be searched
 * @ct: The characters to search for
 *
 * strsep() updates @s to point after the token, ready for the next call.
 *
 * It returns empty tokens, too, behaving exactly like the libc function
 * of that name. In fact, it was stolen from glibc2 and de-fancy-fied.
 * Same semantics, slimmer shape. ;)
 */
char *strsep(char **s, const char *ct)
{
        char *sbegin = *s;
        char *end;

        if (sbegin == NULL)
                return NULL;

        end = strpbrk(sbegin, ct);
        if (end)
                *end++ = '\0';
        *s = end;
        return sbegin;
}

/**
 * strstr - Find the first substring in a %NUL terminated string
 * @s1: The string to be searched
 * @s2: The string to search for
 */
char *strstr(const char *s1, const char *s2)
{
        size_t l1, l2;

        l2 = strlen(s2);
        if (!l2)
                return (char *)s1;
        l1 = strlen(s1);
        while (l1 >= l2) {
                l1--;
                if (!memcmp(s1, s2, l2))
                        return (char *)s1;
                s1++;
        }
        return NULL;
}
