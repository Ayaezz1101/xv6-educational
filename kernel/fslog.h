#ifndef FSLOG_H
#define FSLOG_H

#include "kernel/types.h"


#define LAYER_BCACHE 1
#define LAYER_LOG    2
#define LAYER_BALLOC 3
#define LAYER_INODE  4
#define LAYER_DIR    5
#define LAYER_PATH   6
#define LAYER_FILE   7

struct file;

struct fs_event {
  uint64 seq;
  uint ticks;
  int pid;
  int type;        // LAYER_BCACHE or LAYER_LOG or LAYER_BALLOC
  char op_name[16];

  // حقول البفر كاش (Bcache)
  int blockno;
  int buf_id;
  int refcnt;
  int old_refcnt;
  int valid;
  int old_valid;

  // حقول اللوغ (Log)
  int log_n;
  int old_log_n;
  int outstanding;
  int old_outstanding;
  int committing;
  int old_committing;
  // حقول الـ BALLOC
  //int blockno;
  int bit;
  int old_bit;

  // ===== INODE =====
int inum;
int ref;
int old_ref;
int valid_inode;
int old_valid_inode;
int inode_type;
int old_type_inode;
int size;
int old_size;
int locked;
int old_locked;
// ===== PATH =====
char cwd[128];
char syscall[32];
// ===== DIRECTORY =====
char path[128];
char name[20];
int parent_inum;
int target_inum;
int offset;

// ===== FILE DESCRIPTOR =====
int fd;
int file_type;
char file_type_str[16];
int readable;
int writable;
int file_ref;
int old_file_ref;
int file_off;
int old_file_off;
int file_inum;
char file_path[128];
uint64 file_object_id;
int old_fd;

char details[128];


};

void fslog_init(void);
void fslog_push(struct fs_event *e);
// دالة مخصصة لأحداث اللوغ لتبسيط الكود في log.c
void fslog_log_event(char* op, int n, int old_n, int out, int old_out, int comm, char* det);
void state_update_file(int pid, int fd, struct file *f, char *path);
void state_remove_fd(int pid, int fd, struct file *f);
void state_dup_file(int pid,int oldfd,int newfd,struct file *f);


#endif