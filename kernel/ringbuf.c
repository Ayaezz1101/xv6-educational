#include "types.h"
#include "riscv.h"
#include "spinlock.h"
#include "defs.h"
#include "ringbuf.h"

static void *
slot_ptr(struct ringbuf *rb, uint idx)
{
  return (void *)(rb->buf + idx * rb->elem_size);
}

void
ringbuf_init(struct ringbuf *rb, char *name, uint elem_size)
{
  initlock(&rb->lock, name);
  rb->head = 0;
  rb->tail = 0;
  rb->count = 0;
  rb->seq = 0;
  rb->elem_size = elem_size;
}

int
ringbuf_push(struct ringbuf *rb, void *elem)
{
  acquire(&rb->lock);

  if(rb->count == RB_CAP){
    rb->tail = (rb->tail + 1) % RB_CAP;
    rb->count--;
  }

  memmove(slot_ptr(rb, rb->head), elem, rb->elem_size);
  rb->head = (rb->head + 1) % RB_CAP;
  rb->count++;

  release(&rb->lock);
  return 0;
}

int
ringbuf_read_many(struct ringbuf *rb, void *out, int max)
{
  int n = 0;
  char *dst = (char *)out;

  if(max <= 0)
    return 0;

  acquire(&rb->lock);
  while(n < max && rb->count > 0){
    memmove(dst + n * rb->elem_size, slot_ptr(rb, rb->tail), rb->elem_size);
    rb->tail = (rb->tail + 1) % RB_CAP;
    rb->count--;
    n++;
  }
  release(&rb->lock);

  return n;
<<<<<<< Updated upstream
}
=======
}
int
ringbuf_pop(struct ringbuf *rb, void *dst)
{
  acquire(&rb->lock);
  
  if(rb->count == 0){ // البفر فارغ تماماً
    release(&rb->lock);
    return -1;
  }

  // استخدام الدالة المساعدة slot_ptr الموجودة عندك أصلاً
  void *src = slot_ptr(rb, rb->tail);
  memmove(dst, src, rb->elem_size);
  
  // تحديث المؤشرات بنفس منطق المشروع
  rb->tail = (rb->tail + 1) % RB_CAP;
  rb->count--;
  
  release(&rb->lock);
  return 0;
} 
>>>>>>> Stashed changes
