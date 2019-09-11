#pragma once

#include <asm/processor.h>

struct spinlock {
        atomic_flag lock;
};

#define DEFINE_SPINLOCK(x)      struct spinlock x = { ATOMIC_FLAG_INIT }

static inline void spinlock_init(struct spinlock *lock)
{
        atomic_flag_clear(&lock->lock);
}

/* return whether it has acquired the lock */
static inline bool spin_trylock(struct spinlock *lock)
{
        return !atomic_flag_test_and_set_explicit(&lock->lock, memory_order_acquire);
}

static inline void spin_lock(struct spinlock *lock)
{
        while (!spin_trylock(lock))
                cpu_relax();
}

static inline void spin_unlock(struct spinlock *lock)
{
        atomic_flag_clear_explicit(&lock->lock, memory_order_release);
}
