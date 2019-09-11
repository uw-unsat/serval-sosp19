#include <stdint.h>

int main(void) {}

uint64_t add(uint64_t a, uint64_t b)
{
    return a + b;
}

uint64_t sub(uint64_t a, uint64_t b)
{
    return a - b;
}

uint64_t neg(uint64_t a)
{
    return -a;
}

uint64_t mul(uint64_t a, uint64_t b)
{
    return a * b;
}

/*
    Div and mod will not work without linking
    with gcc libraries---I don't have the 32-bit
    toolchain installed so these won't work for now.
 */
uint64_t div(uint64_t a, uint64_t b)
{
    return a / b;
}

uint64_t mod(uint64_t a, uint64_t b)
{
    return a % b;
}

uint64_t lsh(uint64_t a, uint64_t b)
{
    return a << b;
}

uint64_t rsh(uint64_t a, uint64_t b)
{
    return a >> b;
}

int64_t arsh(int64_t a, int64_t b)
{
    return a >> b;
}
