/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

#include <asm/setup.h>
#include <io/compiler.h>
#include <io/build_bug.h>

#if IS_ENABLED(CONFIG_VERIFICATION)
#define BUG() do { unreachable(); } while (0)
#else /* ! IS_ENABLED(CONFIG_VERIFICATION) */
#define BUG() do { \
        panic("BUG: failure at %s:%d/%s()\n", __FILE__, __LINE__, __func__); \
} while (0)
#endif /*  IS_ENABLED(CONFIG_VERIFICATION) */

#define BUG_ON(condition) do { if (condition) BUG(); } while (0)

struct pt_regs;

noreturn void die(struct pt_regs *regs, const char *str);
void show_regs(struct pt_regs *regs);
void show_gp_regs(struct pt_regs *regs);
void show_sys_regs(void);

__printf(1, 2) noreturn
void panic(const char *fmt, ...);

noreturn void shutdown(void);

void dump_stack(void);
