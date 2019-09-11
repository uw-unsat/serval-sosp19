#pragma once

#include <sys/string.h>
#include <sys/unaligned.h>

#define load16_be(ptr)          get_unaligned_be16(ptr)
#define load32_be(ptr)          get_unaligned_be32(ptr)
#define load64_be(ptr)          get_unaligned_be64(ptr)

#define store16_be(ptr, val)    put_unaligned_be16(val, ptr)
#define store32_be(ptr, val)    put_unaligned_be32(val, ptr)
#define store64_be(ptr, val)    put_unaligned_be64(val, ptr)
