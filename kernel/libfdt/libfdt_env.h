#pragma once

#include <sys/byteorder.h>
#include <sys/string.h>

typedef be16_t fdt16_t;
typedef be32_t fdt32_t;
typedef be64_t fdt64_t;

#define fdt32_to_cpu(x) be32_to_cpu(x)
#define cpu_to_fdt32(x) cpu_to_be32(x)
#define fdt64_to_cpu(x) be64_to_cpu(x)
#define cpu_to_fdt64(x) cpu_to_be64(x)
