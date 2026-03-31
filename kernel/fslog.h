#pragma once
#include "types.h"
#include "ringbuf.h"

#define FS_NM 16

enum {
  FS_ALLOC_BLOCK = 1,
  FS_CREATE_FILE = 2,
  FS_WRITE_FILE  = 3,
  FS_READ_FILE   = 4,
  FS_FREE_BLOCK  = 5,
  FS_BGET_HIT    = 6,   // موجودين هون وهاد بيكفي
  FS_BGET_MISS   = 7,
  FS_BRELEASE    = 8
};

struct fs_event {
  uint64 seq;
  uint   ticks;
  int    type;      // نوع الحدث من الـ enum
  int    pid;       // العملية اللي عملت هاد الشيء
  int    inum;      // رقم الـ Inode
  int    blockno;   // رقم البلوك (إذا كان الحدث بيتعلق ببلوك)
  uint   size;      // حجم البيانات (بالقراءة أو الكتابة)
  char   name[FS_NM]; // اسم الملف
};

void fslog_init(void);
void fslog_push(int type, int inum, int bno, uint size, char* name);
int  fslog_read_many(struct fs_event *out, int max);