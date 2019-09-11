/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <sys/byteorder.h>
#include <sys/unaligned/be_byteshift.h>
#include <sys/unaligned/le_byteshift.h>
#include <sys/unaligned/generic.h>

#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
# define get_unaligned  __get_unaligned_le
# define put_unaligned  __put_unaligned_le
#elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
# define get_unaligned  __get_unaligned_be
# define put_unaligned  __put_unaligned_be
#else
# error need to define endianess
#endif
