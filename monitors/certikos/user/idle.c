#include "user.h"

int main(int argc, char **argv)
{
        long ping_pid, pong_pid, ding_pid;
        size_t aliceq = 100, bobq = 50, hackerq = 22;

        printf("idle\n");

        if ((ping_pid = spawn(ELF_FILE_ALICE, aliceq)) >= 0)
                printf("Alice in process %d with %d quota.\n", ping_pid, aliceq);
        else
                printf("Failed to launch ping.\n");

        if ((pong_pid = spawn(ELF_FILE_HACKER, hackerq)) >= 0)
                printf ("Hacker in process %d with %d quota.\n", pong_pid, hackerq);
        else
                printf ("Failed to launch pong.\n");

        if ((ding_pid = spawn(ELF_FILE_BOB, bobq)) >= 0)
                printf("Bob in process %d with %d quota.\n", ding_pid, bobq);
        else
                printf("Failed to launch ding.\n");

        while (1)
                yield();

        return 0;
}
