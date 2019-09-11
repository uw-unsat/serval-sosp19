#include <crypto/hmac.h>
#include "hacl/Hacl_HMAC_SHA2_256.h"

void hmac256_hash(uint8_t *out, const uint8_t *key, size_t keylen, const void *data, size_t datalen)
{
        Hacl_HMAC_SHA2_256_hmac(out, (uint8_t *)key, keylen, (uint8_t *)data, datalen);
}
