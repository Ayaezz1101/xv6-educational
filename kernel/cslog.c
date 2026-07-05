#include "types.h"
#include "riscv.h"
#include "param.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"
#include "ringbuf.h"
#include "cslog.h"

static struct ringbuf cs_rb;
static uint64 cs_seq = 0;

static void
fill_from_proc(struct cs_event *e, struct proc *p)
{
  memset(e, 0, sizeof(*e));
  e->ticks = ticks;
  e->cpu   = cpuid();
  e->pid   = p->pid;
  e->state = p->state;
  safestrcpy(e->name, p->name, CS_NM);
}

void
cslog_init(void)
{
  ringbuf_init(&cs_rb, "cslog", sizeof(struct cs_event));
  printf("CS sizeof(cs_event)=%ld RB_MAX_ELEM=%d\n", sizeof(struct cs_event), RB_MAX_ELEM);
}

void
cslog_push(struct cs_event *e)
{
  e->seq = ++cs_seq;
  ringbuf_push(&cs_rb, e);
}

int
cslog_read_many(struct cs_event *out, int max)
{
  return ringbuf_read_many(&cs_rb, out, max);
}

void
cslog_run_start(struct proc *p)
{
  // سجل كل context switch، حتى idle
  if(p == 0) {
    // idle process
    struct cs_event e;
    memset(&e, 0, sizeof(e));
    e.ticks = ticks;
    e.cpu = cpuid();
    e.pid = 0;
    e.state = 0;
    safestrcpy(e.name, "idle", CS_NM);
    e.type = CS_RUN_START;
    cslog_push(&e);
    return;
  }
  
  // تخطي بعض processes
  if(p->pid <= 0) return;
  if(p->name[0] == 0) return;
  if(strncmp(p->name, "cscat", 5) == 0) return;
  if(strncmp(p->name, "csexport", 8) == 0) return;

  struct cs_event e;
  fill_from_proc(&e, p);
  e.type = CS_RUN_START;
  cslog_push(&e);
}
