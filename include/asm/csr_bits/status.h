#pragma once

#include <io/const.h>

#define SR_UIE          BIT_64(0) /* User interrupt-enable */
#define SR_SIE          BIT_64(1) /* Supervisor interrupt-enable */
/* RESERVED             BIT_64(2) */
#define SR_MIE          BIT_64(3) /* Machine interrupt-enable */
#define SR_UPIE         BIT_64(4) /* User previous interrupt-enable */
#define SR_SPIE         BIT_64(5) /* Supervisor previous interrupt-enable */
/* RESERVED             BIT_64(6) */
#define SR_MPIE         BIT_64(7) /* Machine previous interrupt-enable */
#define SR_SPP          BIT_64(8) /* Supervisor previous privilege */
/* RESERVED             GENMASK_64(10, 9) */
#define SR_MPP          GENMASK_64(12, 11) /* Machine previous privilege */
#define SR_FS           GENMASK_64(14, 13)
#define SR_XS           GENMASK_64(16, 15)
#define SR_MPRV         BIT_64(17) /* Modify privilege */
#define SR_SUM          BIT_64(18) /* Permit supervisor user memory access */
#define SR_MXR          BIT_64(19) /* Make executable readable */
#define SR_TVM          BIT_64(20) /* Trap virtual memory */
#define SR_TW           BIT_64(21) /* Timeout wait */
#define SR_TSR          BIT_64(22) /* Trap SRET */
/* RESERVED             GENMASK_64(31, 23) */
#define SR_UXL          GENMASK_64(33, 32) /* User XLEN */
#define SR_SXL          GENMASK_64(35, 34) /* Supervisor XLEN */
/* RESERVED             GENMASK_64(62, 36) */
#define SR_SD           BIT_64(63)

#define SR_MPP_SHIFT    11
#define SR_MPP_U        (0 << SR_MPP_SHIFT)
#define SR_MPP_S        (1 << SR_MPP_SHIFT)
#define SR_MPP_M        (3 << SR_MPP_SHIFT)

#define SR_UXL_SHIFT    32ul
#define SR_UXL_32       (1ul << SR_UXL_SHIFT)
#define SR_UXL_64       (2ul << SR_UXL_SHIFT)
#define SR_UXL_128      (3ul << SR_UXL_SHIFT)

#define SR_SXL_SHIFT    34ul
#define SR_SXL_32       (1ul << SR_SXL_SHIFT)
#define SR_SXL_64       (2ul << SR_SXL_SHIFT)
#define SR_SXL_128      (3ul << SR_SXL_SHIFT)
