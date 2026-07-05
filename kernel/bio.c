#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "proc.h"
#include "defs.h"
#include "fs.h"
#include "fslog.h"
#include "buf.h"

struct {
  struct spinlock lock;
  struct buf buf[NBUF];
  struct buf head;
} bcache;

static int buf_id(struct buf *b);

// --- الدالة المساعدة الجديدة للتقرير ---
void bcache_report(char* op, struct buf *b, int old_ref, int old_val,  char* det) {
    struct fs_event e;
    memset(&e, 0, sizeof(e));
    e.ticks = ticks; 
    e.pid = myproc() ? myproc()->pid : 0;
    e.type = LAYER_BCACHE;
    safestrcpy(e.op_name, op, 16);

    // تعبئة بيانات البفر الحالية والقديمة
    e.buf_id = buf_id(b);
    e.blockno = b->blockno;
    e.refcnt = b->refcnt;
    e.old_refcnt = old_ref;
    e.valid = b->valid;
    e.old_valid = old_val;

    safestrcpy(e.details, det, 128);
    fslog_push(&e);
}

void
binit(void)
{
  struct buf *b;
  initlock(&bcache.lock, "bcache");
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}

static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;
  acquire(&bcache.lock);

  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      int old_ref = b->refcnt;
      b->refcnt++;
      
      // تقرير عن وجود البلوك في الكاش (HIT)
      bcache_report("BGET_HIT", b, old_ref, b->valid, "HIT: Buffer found in cache");
      
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    if(b->refcnt == 0) {
  int old_ref = b->refcnt;
  int old_val = b->valid;

  b->dev = dev;
  b->blockno = blockno;
  b->valid = 0;
  b->refcnt = 1;   

  bcache_report("BGET_MISS", b, old_ref, old_val, "MISS: Evicting LRU buffer");
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
}

struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;
  b = bget(dev, blockno);
  if(!b->valid) {
    int old_valid = b->valid;

  bcache_report("BREAD_START", b, b->refcnt, old_valid, "Reading from disk...");
    
    virtio_disk_rw(b, 0);
    b->valid = 1;

    // تقرير بعد انتهاء القراءة
  bcache_report("BREAD_END", b, b->refcnt, b->valid, "Read finished: Valid=1");
  }
  return b;
}

void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  int old_valid = b->valid;
  virtio_disk_rw(b, 1);
  b->disk = 0;

  bcache_report("BWRITE", b, b->refcnt, old_valid, "Writing buffer to disk");
}

void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  acquire(&bcache.lock);
  int old_ref = b->refcnt;
int old_valid = b->valid;
  b->refcnt--;

  // تقرير عن تحرير البفر
  bcache_report("BRELEASE", b, old_ref, old_valid, "Released buffer");

  if (b->refcnt == 0) {
    b->next->prev = b->prev;
    b->prev->next = b->next;
    b->next = bcache.head.next;
    b->prev = &bcache.head;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
  release(&bcache.lock);
}

void
bpin(struct buf *b) {
  acquire(&bcache.lock);
  int old_ref = b->refcnt;
int old_valid = b->valid;
  b->refcnt++;
  bcache_report("BPIN", b, old_ref, old_valid, "Pinned buffer"); 
  release(&bcache.lock);
}

void
bunpin(struct buf *b) {
  acquire(&bcache.lock);
  int old_ref = b->refcnt;
  int old_valid = b->valid;
  b->refcnt--;
  bcache_report("BUNPIN",b, old_ref, old_valid, "Unpinned buffer");
  release(&bcache.lock);
}

static int
buf_id(struct buf *b)
{
  return (int)(b - bcache.buf);
}