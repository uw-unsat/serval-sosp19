#pragma once

#include <asm/csr_bits/ip.h>

#define IDEL_SOFT_U     IP_USIP
#define IDEL_SOFT_S     IP_SSIP
#define IDEL_SOFT_M     IP_MSIP
#define IDEL_TIMER_U    IP_UTIP
#define IDEL_TIMER_S    IP_STIP
#define IDEL_TIMER_M    IP_MTIP
#define IDEL_EXT_U      IP_UEIP
#define IDEL_EXT_S      IP_SEIP
#define IDEL_EXT_M      IP_MEIP
