#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fslog.h"

#define OUTBUF_SZ 1024

static struct fs_event fs_ev[16];

static void append_uint64(char *buf,int *pos,uint64 x)
{
    char tmp[32];
    int n=0;

    if(x==0){
        buf[(*pos)++]='0';
        return;
    }

    while(x){
        tmp[n++]='0'+(x%10);
        x/=10;
    }

    while(n)
        buf[(*pos)++]=tmp[--n];
}

static void append_char(char *buf, int *pos, char c) {
    if (*pos < OUTBUF_SZ - 1) buf[(*pos)++] = c;
}

static void append_str(char *buf, int *pos, const char *s) {
    while (*s && *pos < OUTBUF_SZ - 1) buf[(*pos)++] = *s++;
}

static void append_uint(char *buf, int *pos, uint x) {
    char tmp[16]; int n = 0;
    if (x == 0) { buf[(*pos)++] = '0'; return; }
    while (x > 0) { tmp[n++] = '0' + (x % 10); x /= 10; }
    while (n > 0) buf[(*pos)++] = tmp[--n];
}

static void append_int(char *buf, int *pos, int x) {
    if (x < 0) { append_char(buf, pos, '-'); x = -x; }
    append_uint(buf, pos, (uint)x);
}

static void print_change(char *buf, int *pos, const char *name, int oldv, int newv) {
    if(oldv != newv){
        append_str(buf, pos, "\"");
        append_str(buf, pos, name);
        append_str(buf, pos, "\":\"");
        append_int(buf, pos, oldv);
        append_str(buf, pos, "->");
        append_int(buf, pos, newv);
        append_str(buf, pos, "\",");
    }
}
static void print_fs_event(const struct fs_event *e) {
    char buf[OUTBUF_SZ];
    int pos = 0;

    append_str(buf, &pos, "{");
    append_str(buf, &pos, "\"seq\":");
    append_uint(buf, &pos, e->seq);
    append_str(buf, &pos, ",");

    append_str(buf, &pos, "\"tick\":"); append_uint(buf, &pos, e->ticks);
    append_str(buf, &pos, ",\"pid\":"); append_int(buf, &pos, e->pid);

    append_str(buf, &pos, ",\"layer\":\"");
    if(e->type == LAYER_BCACHE)
    append_str(buf, &pos, "BCACHE");
    else if(e->type == LAYER_LOG)
    append_str(buf, &pos, "LOG");
    else if(e->type == LAYER_BALLOC) 
    append_str(buf, &pos, "BALLOC");
    else if(e->type == LAYER_INODE)
    append_str(buf, &pos, "INODE");
    else if(e->type == LAYER_DIR)
    append_str(buf, &pos, "DIR");
    else if(e->type == LAYER_PATH)
    append_str(buf, &pos, "PATH");
    else if(e->type == LAYER_FILE)
    append_str(buf, &pos, "FILE");
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");

    // ===== BCACHE =====
    if(e->type == LAYER_BCACHE){

        append_str(buf, &pos, ",\"buf\":{");
        append_str(buf, &pos, "\"id\":"); append_int(buf, &pos, e->buf_id);
        append_str(buf, &pos, ",\"block\":"); append_int(buf, &pos, e->blockno);
        append_str(buf, &pos, "}");

        append_str(buf, &pos, ",\"state\":{");
        append_str(buf, &pos, "\"ref\":"); append_int(buf, &pos, e->refcnt);
        append_str(buf, &pos, ",\"valid\":"); append_int(buf, &pos, e->valid);
        append_str(buf, &pos, "}");

        append_str(buf, &pos, ",\"changes\":{");
        print_change(buf, &pos, "ref", e->old_refcnt, e->refcnt);
        print_change(buf, &pos, "valid", e->old_valid, e->valid);

        if(buf[pos-1] == ',') pos--; // remove last comma
        append_str(buf, &pos, "}");
    }

    // ===== LOG =====
    else if(e->type == LAYER_LOG){
        append_str(buf, &pos, ",\"state\":{");
        append_str(buf, &pos, "\"log_n\":"); append_int(buf, &pos, e->log_n);
        append_str(buf, &pos, ",\"outstanding\":"); append_int(buf, &pos, e->outstanding);
        append_str(buf, &pos, ",\"committing\":"); append_int(buf, &pos, e->committing);
        append_str(buf, &pos, "}");

        append_str(buf, &pos, ",\"changes\":{");
        print_change(buf, &pos, "log_n", e->old_log_n, e->log_n);
        print_change(buf, &pos, "outstanding", e->old_outstanding, e->outstanding);
        print_change(buf, &pos, "committing", e->old_committing, e->committing);

        if(buf[pos-1] == ',') pos--;
        append_str(buf, &pos, "}");
    }

    else if(e->type == LAYER_BALLOC){

    append_str(buf, &pos, ",\"block\":");
    append_int(buf, &pos, e->blockno);

    append_str(buf, &pos, ",\"state\":{");
    append_str(buf, &pos, "\"bit\":");
    append_int(buf, &pos, e->bit);
    append_str(buf, &pos, "}");

    append_str(buf, &pos, ",\"changes\":{");
    print_change(buf, &pos, "bit", e->old_bit, e->bit);

    if(buf[pos-1] == ',') pos--;
    append_str(buf, &pos, "}");
}
// ===== INODE =====
else if(e->type == LAYER_INODE){

    append_str(buf, &pos, ",\"inode\":{");
    append_str(buf, &pos, "\"inum\":"); append_int(buf, &pos, e->inum);
    append_str(buf, &pos, "}");


    append_str(buf, &pos, ",\"state\":{");
    append_str(buf, &pos, "\"ref\":"); append_int(buf, &pos, e->ref);
    append_str(buf, &pos, ",\"valid\":"); append_int(buf, &pos, e->valid_inode);
    append_str(buf, &pos, ",\"type\":"); append_int(buf, &pos, e->inode_type);
    append_str(buf, &pos, ",\"size\":"); append_int(buf, &pos, e->size);
    append_str(buf, &pos, ",\"locked\":"); append_int(buf, &pos, e->locked);
    append_str(buf, &pos, "}");


    append_str(buf, &pos, ",\"changes\":{");
    print_change(buf, &pos, "ref", e->old_ref, e->ref);
    print_change(buf, &pos, "valid", e->old_valid_inode, e->valid_inode);
    print_change(buf, &pos, "type", e->old_type_inode, e->inode_type);
    print_change(buf, &pos, "size", e->old_size, e->size);
    print_change(buf, &pos, "locked", e->old_locked, e->locked);

    if(buf[pos-1] == ',') pos--;
    append_str(buf, &pos, "}");
}
else if(e->type == LAYER_DIR){
    append_str(buf, &pos, ",\"dir\":{");

    append_str(buf, &pos, "\"parent\":");
    append_int(buf, &pos, e->parent_inum);

    append_str(buf, &pos, ",\"target\":");
    append_int(buf, &pos, e->target_inum);

    append_str(buf, &pos, ",\"offset\":");
    append_int(buf, &pos, e->offset);

    append_str(buf, &pos, ",\"type\":");
    append_int(buf, &pos, e->inode_type);

    append_str(buf, &pos, ",\"name\":\"");
    append_str(buf, &pos, e->name);
    append_str(buf, &pos, "\"}");

}
else if(e->type == LAYER_PATH){

    append_str(buf, &pos, ",\"syscall\":\"");
    append_str(buf, &pos, e->syscall);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"cwd\":\"");
    append_str(buf, &pos, e->cwd);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"path\":\"");
    append_str(buf, &pos, e->path);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"elem\":\"");
    append_str(buf, &pos, e->name);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"inode\":");
    append_int(buf, &pos, e->parent_inum);
}
else if(e->type == LAYER_FILE){
    append_str(buf, &pos, ",\"fd\":");
    append_int(buf, &pos, e->fd);

    append_str(buf,&pos,",\"file_object_id\":");
    append_uint64(buf,&pos,e->file_object_id);

    append_str(buf, &pos, ",\"file_type\":\"");
    append_str(buf, &pos, e->file_type_str);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"path\":\"");
    append_str(buf, &pos, e->path);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, ",\"inum\":");
    append_int(buf, &pos, e->inum);

    append_str(buf, &pos, ",\"state\":{");

    append_str(buf, &pos, "\"ref\":");
    append_int(buf, &pos, e->file_ref);

    append_str(buf, &pos, ",\"offset\":");
    append_int(buf, &pos, e->file_off);

    append_str(buf, &pos, ",\"readable\":");
    append_int(buf, &pos, e->readable);

    append_str(buf, &pos, ",\"writable\":");
    append_int(buf, &pos, e->writable);

    append_str(buf, &pos, "}");

    append_str(buf, &pos, ",\"changes\":{");

    print_change(buf, &pos,
        "ref",
        e->old_file_ref,
        e->file_ref);

    print_change(buf, &pos,
        "offset",
        e->old_file_off,
        e->file_off);

    if(buf[pos-1] == ',')
        pos--;

    append_str(buf, &pos, "}");
}
    append_str(buf, &pos, ",\"desc\":\"");
    append_str(buf, &pos, e->details);
    append_str(buf, &pos, "\"");

    append_str(buf, &pos, "}\n");

    write(1, buf, pos);
}

int main(void) {
    printf("FS Buffer Cache Export starting...\n");
    
    while (1) {
        int n_fs = fsread(fs_ev, 16);
        if (n_fs < 0) {
            fprintf(2, "fsexport: error reading fslog\n");
            exit(1);
        }

        for (int i = 0; i < n_fs; i++) {
            print_fs_event(&fs_ev[i]);
        }

        // استخدام sleep(2) بدلاً من pause في xv6 لضمان استمرار الحلقة
        pause(2); 
    }
    return 0;
}