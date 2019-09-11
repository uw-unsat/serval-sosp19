#pragma once

#include <io/const.h>

#define SATP_PPN                GENMASK_64(43, 0)
#define SATP_ASID               GENMASK_64(59, 44)
#define SATP_MODE               GENMASK_64(63, 60)

#define SATP_MODE_SHIFT         60
#define SATP_MODE_BARE          (UINT64_C(0) << SATP_MODE_SHIFT)
/* Reserved                     ...                             */
#define SATP_MODE_SV39          (UINT64_C(8) << SATP_MODE_SHIFT)
#define SATP_MODE_SV48          (UINT64_C(9) << SATP_MODE_SHIFT)
/* Reserved                     ...                             */
