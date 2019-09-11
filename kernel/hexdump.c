// SPDX-License-Identifier: GPL-2.0-only

#include <sys/ctype.h>
#include <sys/errno.h>
#include <sys/types.h>

const char hex_asc[] = "0123456789abcdef";
const char hex_asc_upper[] = "0123456789ABCDEF";

/**
 * hex_to_bin - convert a hex digit to its real value
 * @ch: ascii character represents hex digit
 *
 * hex_to_bin() converts one hex digit to its actual value or -1 in case of bad
 * input.
 */
int hex_to_bin(char ch)
{
        if ((ch >= '0') && (ch <= '9'))
                return ch - '0';
        ch = tolower(ch);
        if ((ch >= 'a') && (ch <= 'f'))
                return ch - 'a' + 10;
        return -1;
}

/**
 * hex2bin - convert an ascii hexadecimal string to its binary representation
 * @dst: binary result
 * @src: ascii hexadecimal string
 * @count: result length
 *
 * Return 0 on success, -EINVAL in case of bad input.
 */
int hex2bin(uint8_t *dst, const char *src, size_t count)
{
        while (count--) {
                int hi = hex_to_bin(*src++);
                int lo = hex_to_bin(*src++);

                if ((hi < 0) || (lo < 0))
                        return -EINVAL;

                *dst++ = (hi << 4) | lo;
        }
        return 0;
}

/**
 * bin2hex - convert binary data to an ascii hexadecimal string
 * @dst: ascii hexadecimal result
 * @src: binary data
 * @count: binary data length
 */
char *bin2hex(char *dst, const void *src, size_t count)
{
        const unsigned char *_src = src;

        while (count--)
                dst = hex_byte_pack(dst, *_src++);
        return dst;
}
