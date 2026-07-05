#include "types.h"
#include "riscv.h"
#include "param.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"
#include "memevent.h"

#define MEM_RB_CAP 512

static struct spinlock mem_lock;
static struct mem_event mem_buf[MEM_RB_CAP];
static uint mem_head = 0;
static uint mem_tail = 0;
static uint mem_count = 0;
static uint64 mem_seq = 0;

void
memlog_init(void)
{
  initlock(&mem_lock, "memlog");
  mem_head = 0;
  mem_tail = 0;
  mem_count = 0;
  mem_seq = 0;
  printf("MEM memlog initialized, buffer capacity: %d events\n", MEM_RB_CAP);
}

void
memlog_push(struct mem_event *e)
{
  acquire(&mem_lock);

  e->seq = ++mem_seq;

  if(mem_count == MEM_RB_CAP){
    mem_tail = (mem_tail + 1) % MEM_RB_CAP;
    mem_count--;
  }

  mem_buf[mem_head] = *e;
  mem_head = (mem_head + 1) % MEM_RB_CAP;
  mem_count++;

  release(&mem_lock);
}

int
memlog_read_many(struct mem_event *out, int max)
{
  int n = 0;

  if(max <= 0)
    return 0;

  acquire(&mem_lock);
  while(n < max && mem_count > 0){
    out[n] = mem_buf[mem_tail];
    mem_tail = (mem_tail + 1) % MEM_RB_CAP;
    mem_count--;
    n++;
  }
  release(&mem_lock);

  return n;
}
