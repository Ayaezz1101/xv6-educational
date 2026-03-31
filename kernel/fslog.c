#include "types.h"
#include "riscv.h"
#include "param.h"
#include "spinlock.h"
#include "defs.h"
#include "proc.h"
#include "ringbuf.h"
#include "fslog.h"
#include "defs.h"

static struct ringbuf fs_rb;
static uint64 fs_seq = 0;

void fslog_init(void) {
  ringbuf_init(&fs_rb, "fslog", sizeof(struct fs_event));
}

void fslog_push(int type, int inum, int bno, uint size, char* name) {
  struct fs_event e;
  memset(&e, 0, sizeof(e));
  e.seq = ++fs_seq;
  e.ticks = ticks;
  e.type = type;
  e.pid = myproc() ? myproc()->pid : 0;
  e.inum = inum;
  e.blockno = bno;
  e.size = size;
  if(name) safestrcpy(e.name, name, FS_NM);
  ringbuf_push(&fs_rb, &e);
}
// لا تنسي إضافة fslog_read_many أيضاً هنا

int
fslog_read_many(struct fs_event *out, int max)
{
  struct fs_event e;
  int count = 0;
  struct proc *p = myproc();

  while(count < max){
    // سحب حدث واحد من الرينغ بفر (موجود في ذاكرة الكيرنل)
    if(ringbuf_pop(&fs_rb, &e) != 0)
      break;

    // 🔥 النسخ الآمن لذاكرة المستخدم باستخدام copyout
    // العنوان الهدف: out + (count * حجم الـ struct)
    uint64 dst_addr = (uint64)out + (count * sizeof(struct fs_event));
    if(copyout(p->pagetable, dst_addr, (char *)&e, sizeof(struct fs_event)) < 0)
      break;

    count++;
  }
  return count;
}