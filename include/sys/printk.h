/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <stddef.h>
#include <asm/setup.h>
#include <io/compiler.h>

#define LOGLEVEL_EMERG          0       /* system is unusable */
#define LOGLEVEL_ERR            3       /* error conditions */
#define LOGLEVEL_WARNING        4       /* warning conditions */
#define LOGLEVEL_INFO           6       /* informational */
#define LOGLEVEL_DEBUG          7       /* debug-level messages */
#define LOGLEVEL_CONT           -1

#define LOGLEVEL_DEFAULT        LOGLEVEL_INFO

#ifndef pr_fmt
#define pr_fmt(fmt) fmt
#endif

#if IS_ENABLED(CONFIG_VERIFICATION)

#define pr_emerg                printk_unused
#define pr_err                  printk_unused
#define pr_warn                 printk_unused
#define pr_info                 printk_unused
#define pr_debug                printk_unused
#define pr_cont                 printk_unused

__printf(1, 2)
static inline void __always_unused printk_unused(const char *fmt, ...) {}

#else /* !IS_ENABLED(CONFIG_VERIFICATION) */

#define pr_emerg(fmt, ...) \
        printk(LOGLEVEL_EMERG, pr_fmt(fmt), ##__VA_ARGS__)
#define pr_err(fmt, ...) \
        printk(LOGLEVEL_ERR, pr_fmt(fmt), ##__VA_ARGS__)
#define pr_warn(fmt, ...) \
        printk(LOGLEVEL_WARNING, pr_fmt(fmt), ##__VA_ARGS__)
#define pr_info(fmt, ...) \
        printk(LOGLEVEL_INFO, pr_fmt(fmt), ##__VA_ARGS__)
#define pr_debug(fmt, ...) \
        printk(LOGLEVEL_DEBUG, pr_fmt(fmt), ##__VA_ARGS__)

#define pr_cont(fmt, ...) \
        printk(LOGLEVEL_CONT, fmt, ##__VA_ARGS__)

#endif /* IS_ENABLED(CONFIG_VERIFICATION) */

/* format specifier macros (inttypes.h is not for freestanding) */
#if defined(__LP64__) || defined(_LP64)
#define __PRI64_PREFIX  "l"
#else
#define __PRI64_PREFIX  "ll"
#endif

#ifndef PRIx64
#define PRIx64  __PRI64_PREFIX "x"
#endif

#ifndef PRIX64
#define PRIX64  __PRI64_PREFIX "X"
#endif

#ifndef PRIu64
#define PRIu64  __PRI64_PREFIX "u"
#endif

#ifndef PRIxPTR
#define PRIxPTR "lx"
#endif

__printf(2, 0)
int vprintk(int level, const char *fmt, va_list args);

__printf(2, 3)
int printk(int level, const char *fmt, ...);

__printf(3, 0)
int vsnprintf(char *buf, size_t size, const char *fmt, va_list args);

__printf(3, 0)
int vscnprintf(char *buf, size_t size, const char *fmt, va_list args);

__printf(3, 4)
int scnprintf(char *buf, size_t size, const char *fmt, ...);
