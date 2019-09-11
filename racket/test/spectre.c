#include <stddef.h>
#include <io/nospec.h>

#define N       4

int arr[N];

int test_read(size_t i)
{
        if (i >= N)
                return 0;
        return arr[i];
}

int test_read_nospec(size_t i)
{
        if (i >= N)
                return 0;
        i = array_index_nospec(i, N);
        return arr[i];
}
