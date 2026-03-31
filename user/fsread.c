#include "user/user.h"
#include "kernel/syscall.h"
#include "kernel/fslog.h"

int fsread(struct fs_event *buf, int n) {
    return syscall(SYS_fsread, buf, n); // تأكدي من حذف كلمة log لتصبح SYS_fsread
}