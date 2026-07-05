// kernel/procinfo.h
#ifndef XV6_PROCINFO_H
#define XV6_PROCINFO_H

#include "types.h"
#include "param.h"

#define PROC_STATE_COUNT 6

struct cpu_info {
  int cpu;
  int active;
  int current_pid;
  int current_state;
  int last_pid;
  int last_state;
  uint64 active_ticks;
  int busy_percent;
};

struct proc_stats {
  uint64 current_count[PROC_STATE_COUNT];
  uint64 unique_count[PROC_STATE_COUNT];
  uint64 total_created;
  uint64 total_exited;
};

#endif
