#include "user.h"

#define C       'a'
#define SIZE    100000000

char buf[SIZE];

void write_buf(int i)
{
        size_t new_quota;

        buf[i] = C;
        new_quota = get_quota();

        printf("Alice: I did something secret, my quota is now %zd.\n", new_quota);
}

int main(int argc, char **argv)
{
        size_t quota;
        int i, j, k;

        printf("\nHello! This is Alice's process. I've been told that this execution environment is secure,\n");
        printf("so I will be performing top secret computations here!\n");

        printf("Before I begin, I will be a nice person and yield to other processes. See you in a bit!\n");

        yield();

        printf("\nAlice: Hello again! Now it's time for me to perform some secret computations that will\n");
        printf("require allocating memory.\n");

        quota = get_quota();
        printf("Alice: I have %zd available quota for my computations. How nice!\n", quota);
        for (i = 0; i < 5; i++) {
                for (j = 0; j < 5; j++) {
                        k = i * SZ_4K * SZ_4K + (j + 1) * SZ_4K / 2;
                        write_buf(k);
                }
        }

        printf("Alice: I've finished my top secret computation! I sure hope no one was able to learn anything\n");
        printf("about what I did. Goodbye!\n");

        while (1)
                yield();

        return 0;
}
