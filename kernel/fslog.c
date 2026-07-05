#include "types.h"
#include "riscv.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"   // أضف هذا
#include "fs.h"          // أضف هذا
#include "file.h"
#include "defs.h"
#include "proc.h"
#include "fslog.h"

static struct ringbuf fs_rb;
static uint64 fs_seq = 0;

void
fslog_init(void)
{
  // تهيئة الـ ring buffer الخاص بـ أحداث نظام الملفات
  ringbuf_init(&fs_rb, "fslog", sizeof(struct fs_event));
}

void
fslog_push(struct fs_event *e)
{
  // إضافة رقم تسلسلي لكل حدث لترتيبها في الواجهة الرسومية
  e->seq = ++fs_seq;
  ringbuf_push(&fs_rb, e);
}

int
fslog_read_many(struct fs_event *out, int max)
{
  struct fs_event e;
  int count = 0;
  struct proc *p = myproc();
  
  while(count < max){
    if(ringbuf_pop(&fs_rb, &e) != 0)
      break;

    // نقل البيانات من مساحة النواة إلى مساحة المستخدم (User Space) ليعرضها الـ GUI
    uint64 dst = (uint64)out + count * sizeof(struct fs_event);
    if(copyout(p->pagetable, dst, (char *)&e, sizeof(struct fs_event)) < 0)
      break;
    count++;
  }
  return count;
}
void
state_update_file(int pid, int fd, struct file *f, char *path)
{
    struct fs_event e;
    memset(&e, 0, sizeof(e));

    e.ticks = ticks;
    e.pid = pid;
    e.type = LAYER_FILE;

    safestrcpy(e.op_name, "OPEN", sizeof(e.op_name));

    e.fd = fd;
    e.file_object_id = (uint64)f;

    e.file_type = f->type;
    e.file_ref = f->ref;
    e.file_off = f->off;
    e.file_inum = f->ip ? f->ip->inum : -1;

    e.readable = f->readable;
    e.writable = f->writable;

    safestrcpy(e.path, path, MAXPATH);

    // human-readable file type
    if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));

    fslog_push(&e);
}

void
state_remove_fd(int pid, int fd , struct file *f)
{
    struct fs_event e;
    memset(&e, 0, sizeof(e));

    e.ticks = ticks;
    e.pid = pid;
    e.type = LAYER_FILE;

    safestrcpy(e.op_name, "FILECLOSE", sizeof(e.op_name));

    e.fd = fd;
    e.file_object_id=(uint64)f;

    e.file_ref=f->ref;

    e.file_off=f->off;

    e.file_inum=f->ip ? f->ip->inum : -1;

    safestrcpy(e.path,f->path,MAXPATH);

    if(f){
      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
      else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));
    }

    fslog_push(&e);
}
void
state_dup_file(int pid, int oldfd, int newfd, struct file *f)
{
    struct fs_event e;
    memset(&e,0,sizeof(e));

    e.ticks = ticks;
    e.pid = pid;
    e.type = LAYER_FILE;

    safestrcpy(e.op_name,"DUP",sizeof(e.op_name));

    e.old_fd = oldfd;
    e.fd = newfd;

    e.file_object_id = (uint64)f;

    if(f){
        e.file_type = f->type;
        e.file_ref = f->ref;
        e.file_off = f->off;
        e.file_inum = f->ip ? f->ip->inum : -1;
        e.readable = f->readable;
        e.writable = f->writable;
        safestrcpy(e.path,f->path,MAXPATH);

      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
      else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));
    }

    fslog_push(&e);
}