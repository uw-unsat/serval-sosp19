#pragma once

#include <io/const.h>

#define PMPCFG_R        BIT_64(0)
#define PMPCFG_W        BIT_64(1)
#define PMPCFG_X        BIT_64(2)
#define PMPCFG_RWX      (PMPCFG_R | PMPCFG_W | PMPCFG_X)

#define PMPCFG_A_SHIFT  3
#define PMPCFG_A_OFF    (0 << PMPCFG_A_SHIFT)
#define PMPCFG_A_TOR    (1 << PMPCFG_A_SHIFT)
#define PMPCFG_A_NA4    (2 << PMPCFG_A_SHIFT)
#define PMPCFG_A_NAPOT  (3 << PMPCFG_A_SHIFT)

#define PMPCFG_L        BIT_64(7)
