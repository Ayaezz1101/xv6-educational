#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "buf.h"
#include "fslog.h"
#include "proc.h"

struct logheader {
  int n;
  int block[LOGBLOCKS];
};

struct log {
  struct spinlock lock;
  int start;
  int outstanding;
  int committing;
  int dev;
  struct logheader lh;
};

struct log log;

static void recover_from_log(void);
static void commit(void);

//
// 🔥 snapshot للحالة (مثل bcache)
//
struct log_state {
  int n;
  int out;
  int committing;
};

static struct log_state
log_get_state(void)
{
  struct log_state s;
  s.n = log.lh.n;
  s.out = log.outstanding;
  s.committing = log.committing;
  return s;
}
void log_report(char *op, int bno, struct log_state old, char *desc)
{
  struct fs_event e;
  memset(&e, 0, sizeof(e));

  struct log_state now = log_get_state();

  e.ticks = ticks;
  e.pid = myproc() ? myproc()->pid : 0;
  e.type = LAYER_LOG;
  e.blockno = bno;

  // before
  e.old_log_n = old.n;
  e.old_outstanding = old.out;
  e.old_committing = old.committing;

  // after
  e.log_n = now.n;
  e.outstanding = now.out;
  e.committing = now.committing;

  safestrcpy(e.op_name, op, 16);
  safestrcpy(e.details, desc, 128);

  fslog_push(&e);
}

void
initlog(int dev, struct superblock *sb)
{
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  initlock(&log.lock, "log");
  log.start = sb->logstart;
  log.dev = dev;

  struct log_state old = log_get_state();
  log_report("INIT_LOG", 0, old, "Initialize log system");

  recover_from_log();
}

static void
read_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);

  struct log_state old = log_get_state();

  log.lh.n = lh->n;
  for (int i = 0; i < log.lh.n; i++)
    log.lh.block[i] = lh->block[i];

  log_report("READ_HEAD", 0, old, "Read log header from disk");

  brelse(buf);
}

static void
write_head(void)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);

  struct log_state old = log_get_state();

  hb->n = log.lh.n;
  for (int i = 0; i < log.lh.n; i++)
    hb->block[i] = log.lh.block[i];

  bwrite(buf);

  log_report("WRITE_HEAD", 0, old, "Write log header to disk");

  brelse(buf);
}

static void
install_trans(int recovering)
{
  for (int tail = 0; tail < log.lh.n; tail++) {
    struct buf *lbuf = bread(log.dev, log.start+tail+1);
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);

    struct log_state old = log_get_state();

    if (recovering)
      log_report("RECOVER_BLK", log.lh.block[tail], old, "Recover block");
    else
      log_report("INSTALL_BLK", log.lh.block[tail], old, "Install block");

    memmove(dbuf->data, lbuf->data, BSIZE);
    bwrite(dbuf);

    if (!recovering)
      bunpin(dbuf);

    brelse(lbuf);
    brelse(dbuf);
  }
}

static void
recover_from_log(void)
{
  read_head();

  if (log.lh.n > 0) {
    struct log_state old = log_get_state();

    log_report("RECOVER_START", 0, old, "Start recovery");

    install_trans(1);

    old = log_get_state();
    log.lh.n = 0;
    write_head();

    log_report("RECOVER_DONE", 0, old, "Recovery done");
  }
}

void
begin_op(void)
{
  acquire(&log.lock);

  while (1) {
    if (log.committing) {
      struct log_state old = log_get_state();
      log_report("WAIT_COMMIT", 0, old, "Waiting for commit");
      sleep(&log, &log.lock);

    } else if (log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS) {
      struct log_state old = log_get_state();
      log_report("WAIT_SPACE", 0, old, "Waiting for log space");
      sleep(&log, &log.lock);

    } else {
      struct log_state old = log_get_state();

      log.outstanding++;

      log_report("BEGIN_OP", 0, old, "Begin operation");

      release(&log.lock);
      break;
    }
  }
}

void
end_op(void)
{
  int do_commit = 0;

  acquire(&log.lock);

  struct log_state old = log_get_state();

  log.outstanding--;

  if (log.outstanding == 0) {
    do_commit = 1;
    log.committing = 1;

    log_report("PRE_COMMIT", 0, old, "Start committing");
  } else {
    log_report("END_OP", 0, old, "End operation");
    wakeup(&log);
  }

  release(&log.lock);

  if (do_commit) {
    commit();

    acquire(&log.lock);

    old = log_get_state();
    log.committing = 0;

    log_report("FINAL_RELEASE", 0, old, "Commit finished");

    wakeup(&log);
    release(&log.lock);
  }
}

static void
write_log(void)
{
  for (int tail = 0; tail < log.lh.n; tail++) {
    struct buf *to = bread(log.dev, log.start+tail+1);
    struct buf *from = bread(log.dev, log.lh.block[tail]);

    struct log_state old = log_get_state();

    log_report("LOG_SYNC", log.lh.block[tail], old, "Write to log");

    memmove(to->data, from->data, BSIZE);
    bwrite(to);

    brelse(from);
    brelse(to);
  }
}

static void
commit(void)
{
  if (log.lh.n > 0) {
    struct log_state old = log_get_state();

    log_report("COMMIT_START", 0, old, "Commit start");

    write_log();
    write_head();

    old = log_get_state();
    log_report("WRITE_HEAD", 0, old, "Header committed");

    install_trans(0);

    old = log_get_state();
    log.lh.n = 0;
    write_head();

    log_report("COMMIT_DONE", 0, old, "Commit done");
  }
}

void
log_write(struct buf *b)
{
  acquire(&log.lock);

  struct log_state old = log_get_state();

  int i;
  for (i = 0; i < log.lh.n; i++) {
    if (log.lh.block[i] == b->blockno)
      break;
  }

  log.lh.block[i] = b->blockno;

  if (i == log.lh.n) {
    bpin(b);
    log.lh.n++;

    log_report("LOG_WRITE", b->blockno, old, "Add block to log");
  } else {
    log_report("LOG_MERGE", b->blockno, old, "Merge block");
  }

  release(&log.lock);
}