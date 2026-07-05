#pragma once
#include "types.h"
#include "spinlock.h"

#define RB_CAP 65536
#define RB_MAX_ELEM 256

struct ringbuf {
  struct spinlock lock;
  uint head;
  uint tail;
  uint count;
  uint elem_size;
  uint64 seq;
  char buf[RB_CAP * RB_MAX_ELEM];
};

void ringbuf_init(struct ringbuf *rb, char *name, uint elem_size);

int  ringbuf_push(struct ringbuf *rb, void *elem);
int  ringbuf_pop(struct ringbuf *rb, void *dst);
int  ringbuf_read_many(struct ringbuf *rb, void *out, int max);
