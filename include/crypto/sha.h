#pragma once

#include <stddef.h>
#include <stdint.h>

#define SHA256_DIGEST_SIZE      32
#define SHA256_BLOCK_SIZE       64

struct sha256_ctx {
        uint32_t state[137];
};

void sha256_init(struct sha256_ctx *ctx);
void sha256_update(struct sha256_ctx *ctx, const uint8_t *data);
void sha256_update_last(struct sha256_ctx *ctx, const uint8_t *data, size_t len);
void sha256_finish(struct sha256_ctx *ctx, uint8_t *out);

void sha256_update_multi(struct sha256_ctx *ctx, const uint8_t *data, size_t n);

void sha256_hash(uint8_t *out, const void *data, size_t len);
