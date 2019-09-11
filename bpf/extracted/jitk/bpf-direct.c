
#define __USE_GNU 1
#define _GNU_SOURCE 1

#include <linux/types.h>
#include <linux/filter.h>
#include <linux/seccomp.h>
#include <linux/unistd.h>
#include <signal.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

#define MAXSIZE 16384

static int install_filter(const char *filename)
{
    char filter[MAXSIZE];
    int fd;

    memset(filter, 0, MAXSIZE);

    fd = open(filename, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return -1;
    }

    ssize_t readbytes = 0;
    ssize_t i;
    while ((i = read(fd, &filter[readbytes], MAXSIZE - readbytes))) {
        readbytes += i;
    }

    printf("%lu bytes\n", readbytes);

	struct sock_fprog prog = {
		.len = (unsigned short)(readbytes / sizeof(struct sock_filter)),
		.filter = (struct sock_filter *) filter,
	};

	if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)) {
		perror("prctl(NO_NEW_PRIVS)");
		return 1;
	}

	if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &prog)) {
		perror("prctl");
		return 1;
	}
	return 0;
}

int main(int argc, char **argv)
{
	ssize_t bytes = 0;

    if (argc < 2) {
        fprintf(stderr, "Usage: ./bpf_direct [filename]\n");
        return -1;
    }

	if (install_filter(argv[1]))
		return 1;

	return 0;
}

