//
// Support functions for system calls that involve file descriptors.
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "fs.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "file.h"
#include "stat.h"
#include "proc.h"
#include "fslog.h"

struct devsw devsw[NDEV];
struct {
  struct spinlock lock;
  struct file file[NFILE];
} ftable;
 
static void file_report(
    char *op,
    struct file *f,
    int old_ref,
    int old_off,
    char *details
){
    struct fs_event e;

    memset(&e, 0, sizeof(e));

    e.ticks = ticks;
    e.pid = myproc() ? myproc()->pid : 0;

    e.type = LAYER_FILE;

    safestrcpy(e.op_name, op, sizeof(e.op_name));
    e.file_object_id = (uint64)f;

    if(f){
        e.file_type = f->type;

        e.readable = f->readable;
        e.writable = f->writable;

      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
      else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));

        e.file_ref = f->ref;
        e.old_file_ref = old_ref;

        e.file_off = f->off;
        e.old_file_off = old_off;

        e.inum = f->ip ? f->ip->inum : -1;
        safestrcpy(e.path, f->path, MAXPATH);
    }


    safestrcpy(e.details, details, sizeof(e.details));

    fslog_push(&e);}

void
fileinit(void)
{
  initlock(&ftable.lock, "ftable");
}

// Allocate a file structure.
struct file*
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
  return 0;
}

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("filedup");
  int old_ref = f->ref;
  f->ref++;
  
  file_report(
    "FILEDUP",
    f,
    old_ref,
    f->off,
    "Duplicated file reference"
  );
  release(&ftable.lock);
  return f;
}

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
  struct file ff;

  acquire(&ftable.lock);
  if(f->ref < 1)
    panic("fileclose");
  int old_ref = f->ref;
  int old_off = f->off;
  
  
  if(--f->ref > 0){
    file_report(
      "FILECLOSE",
      f,
      old_ref,
      old_off,
      "Closing file descriptor"
    );
    release(&ftable.lock);
    return;
  }
  
  // في حال رغبنا بالتقرير عند الإغلاق النهائي والتصفير:
  file_report(
    "FILE_FREE",
    f,
    old_ref,
    old_off,
    "File structure fully freed"
  );

  ff = *f;
  f->ref = 0;
  f->type = FD_NONE;
  release(&ftable.lock);

  if(ff.type == FD_PIPE){
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    begin_op();
    iput(ff.ip);
    end_op();
  }
}

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
  struct proc *p = myproc();
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    ilock(f->ip);
    stati(f->ip, &st);
    iunlock(f->ip);
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
      return -1;
    return 0;
  }
  return -1;
}

// Read from file f.
// addr is a user virtual address.

int fileread(struct file *f, int fd, uint64 addr, int n)
{
  int r = 0;

  if(f->readable == 0)
    return -1;

  if(f->type == FD_PIPE){
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    ilock(f->ip);
    int old_off = f->off;

    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
   
   { f->off += r;}
    file_report(
    "FILE_READ",
    f,
    f->ref,
    old_off,
    "Read from file"
);
    iunlock(f->ip);
  } else {
    panic("fileread");
  }

  return r;
}

// Write to file f.
// addr is a user virtual address.

int filewrite(struct file *f, int fd, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    return -1;

  if(f->type == FD_PIPE){
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    int old_off;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
      ilock(f->ip);
      old_off = f->off;
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;
      file_report(
    "FILE_WRITE",
    f,
    f->ref,
    old_off,
    "Write to file"
);
      iunlock(f->ip);
      end_op();

      if(r != n1){
        // error from writei
        break;
      }
      i += r;
    }
    ret = (i == n ? n : -1);
  } else {
    panic("filewrite");
  }

  return ret;
}

