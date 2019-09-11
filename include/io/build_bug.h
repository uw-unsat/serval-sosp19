/* SPDX-License-Identifier: GPL-2.0 */

#pragma once

/* Force a compilation error if condition is true, but also produce a
   result (of value 0 and type size_t), so the expression can be used
   e.g. in a structure initializer (or where-ever else comma expressions
   aren't permitted). */
#define BUILD_BUG_ON_ZERO(e) (sizeof(struct { int:-!!(e); }))
#define BUILD_BUG_ON_NULL(e) ((void *)sizeof(struct { int:-!!(e); }))

#define BUILD_BUG_ON_MSG(cond, msg) _Static_assert(!(cond), msg)

#define BUILD_BUG_ON(condition) \
        BUILD_BUG_ON_MSG(condition, "BUILD_BUG_ON failed: " #condition)

#define BUILD_BUG_ON_NOT_POWER_OF_2(n)                  \
        BUILD_BUG_ON((n) == 0 || (((n) & ((n) - 1)) != 0))
