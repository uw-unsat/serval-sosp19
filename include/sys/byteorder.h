/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <io/const.h>
#include <sys/swab.h>

#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__

#define cpu_to_be16(x) swab16(x)
#define be16_to_cpu(x) swab16(x)
#define cpu_to_be32(x) swab32(x)
#define be32_to_cpu(x) swab32(x)
#define cpu_to_be64(x) swab64(x)
#define be64_to_cpu(x) swab64(x)
#define cpu_to_le16(x) (x)
#define le16_to_cpu(x) (x)
#define cpu_to_le32(x) (x)
#define le32_to_cpu(x) (x)
#define cpu_to_le64(x) (x)
#define le64_to_cpu(x) (x)

#endif

static inline uint32_t be32_to_cpup(const be32_t *p)
{
        return be32_to_cpu(*(uint32_t *)p);
}
