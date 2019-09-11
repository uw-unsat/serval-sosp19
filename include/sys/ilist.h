#pragma once

#include <stdint.h>

/*
 * Use integers instead of pointers to form a list.
 * This makes verification easier.
 */

/* insert new beteween prev and next */
#define __ilist_add(a, new, iprev, inext)       \
({                                              \
        typeof(new) _new = new;                 \
        typeof(iprev) _prev = iprev;            \
        typeof(inext) _next = inext;            \
        a[_next].prev = _new;                   \
        a[_new].next = _next;                   \
        a[_new].prev = _prev;                   \
        a[_prev].next = _new;                   \
})

#define ilist_add(a, new, head)                 \
        __ilist_add(a, new, head, a[head].next)

#define ilist_add_tail(a, new, head)            \
        __ilist_add(a, new, a[head].prev, head)

/* delete by pointing prev and next to each other */
#define __ilist_del(a, iprev, inext)            \
({                                              \
        typeof(iprev) _prev = iprev;            \
        typeof(inext) _next = inext;            \
        a[_next].prev = _prev;                  \
        a[_prev].next = _next;                  \
})

#define ilist_del(a, i, poison)                 \
({                                              \
        typeof(i) _i = i;                       \
        __ilist_del(a, a[_i].prev, a[_i].next); \
        a[_i].prev = poison;                    \
        a[_i].next = poison;                    \
})

#define ilist_empty(a, head)                    \
        (a[head].next == (head))

#define ilist_first_entry(a, head)              \
        (a[head].next)
