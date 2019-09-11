#pragma once

struct siginfo;
struct rusage;

/* First argument to waitid: */
#define P_ALL           0
#define P_PID           1
#define P_PGID          2
