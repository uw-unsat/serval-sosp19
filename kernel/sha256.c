#include <crypto/sha.h>
#include "hacl/Hacl_SHA2_256.h"

void sha256_init(struct sha256_ctx *ctx)
{
        Hacl_SHA2_256_init(ctx->state);
}

void sha256_update(struct sha256_ctx *ctx, const uint8_t *data)
{
        Hacl_SHA2_256_update(ctx->state, (uint8_t *)data);
}

void sha256_update_last(struct sha256_ctx *ctx, const uint8_t *data, size_t len)
{
        Hacl_SHA2_256_update_last(ctx->state, (uint8_t *)data, len);
}

void sha256_finish(struct sha256_ctx *ctx, uint8_t *out)
{
        Hacl_SHA2_256_finish(ctx->state, out);
}

void sha256_update_multi(struct sha256_ctx *ctx, const uint8_t *data, size_t n)
{
        Hacl_SHA2_256_update_multi(ctx->state, (uint8_t *)data, n);
}

void sha256_hash(uint8_t *out, const void *data, size_t len)
{
        Hacl_SHA2_256_hash(out, (uint8_t *)data, len);
}
