#pragma once

#include <io/const.h>

/* Atomic extension */
#define MISA_A      BIT_64(0)

/* Compressed extension */
#define MISA_C      BIT_64(2)

/* Double-precision floating-point extension */
#define MISA_D      BIT_64(3)

/* RV32E base ISA */
#define MISA_E      BIT_64(4)

/* Single-precision floating-point extension */
#define MISA_F      BIT_64(5)

/* RV32I / 64I / 128I base ISA */
#define MISA_I      BIT_64(8)

/* Integer Multiply / Divide extension */
#define MISA_M      BIT_64(12)

/* User-level interrupts supported */
#define MISA_N      BIT_64(13)

/* Supervisor mode implemented */
#define MISA_S      BIT_64(18)

/* User mode implemented */
#define MISA_U      BIT_64(20)

/* Non-standard extensions present */
#define MISA_X      BIT_64(23)
