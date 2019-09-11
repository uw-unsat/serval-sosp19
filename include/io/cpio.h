/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <stddef.h>

#define MAX_CPIO_FILE_NAME 64

struct cpio_data {
        void *data;
        size_t size;
        unsigned int mode;
        char name[MAX_CPIO_FILE_NAME];
};

struct cpio_data find_cpio_data(const char *path, void *data, size_t len, long *offset);
