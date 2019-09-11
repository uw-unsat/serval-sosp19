#pragma once

#include <crypto/sha.h>

void hmac256_hash(uint8_t *out, const uint8_t *key, size_t keylen, const void *data, size_t datalen);
