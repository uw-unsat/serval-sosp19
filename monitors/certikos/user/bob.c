#include "user.h"

int main(int argc, char **argv)
{
        printf("\nHey, this is Bob's process. I'm not really part of this example, just kinda hanging out here.\n");

        while (1)
                yield();

        return 0;
}
