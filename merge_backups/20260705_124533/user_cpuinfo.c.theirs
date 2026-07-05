#include "user/user.h"
#include "kernel/procinfo.h"
#include "kernel/types.h"
#include "kernel/fslog.h"

#define OUTBUF_SZ 1024  

// المصفوفات العالمية لحماية الـ Stack
static struct cpu_info cpus[NCPU];
static struct proc_stats stats;
static struct cs_event cs_ev[256];
static struct fs_event fs_ev[256];

static const char *state_names[PROC_STATE_COUNT] = {
  "UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE"
};

// دوال المساعدة للـ JSON
static void append_str(char *buf, int *pos, const char *s) {
    while (*s && *pos < OUTBUF_SZ - 50) { 
        buf[(*pos)++] = *s++;
    }
}

static void append_uint(char *buf, int *pos, uint x) {
    char tmp[16]; 
    int n = 0;
    if (*pos >= OUTBUF_SZ - 20) return; 
    if (x == 0) { buf[(*pos)++] = '0'; return; }
    while (x > 0) { tmp[n++] = '0' + (x % 10); x /= 10; }
    while (n > 0) buf[(*pos)++] = tmp[--n];
}

static void append_int(char *buf, int *pos, int x) {
    if (*pos >= OUTBUF_SZ - 20) return;
    if (x < 0) {
        buf[(*pos)++] = '-';
        x = -x;
    }
    append_uint(buf, pos, (uint)x);
}

static void print_fs_event(const struct fs_event *e) {
    char buf[OUTBUF_SZ];
    int pos = 0;
    memset(buf, 0, OUTBUF_SZ);

    append_str(buf, &pos, "EV {\"seq\":");
    append_uint(buf, &pos, (uint)e->seq);
    append_str(buf, &pos, ",\"tick\":");
    append_uint(buf, &pos, e->ticks);
    append_str(buf, &pos, ",\"type\":\"FS\",\"fs_event_type\":"); 
    append_int(buf, &pos, e->type); 
    append_str(buf, &pos, ",\"pid\":");
    append_int(buf, &pos, e->pid);
    append_str(buf, &pos, ",\"inum\":");
    append_int(buf, &pos, e->inum);
    append_str(buf, &pos, ",\"block\":");
    append_int(buf, &pos, e->blockno);
    append_str(buf, &pos, ",\"size\":");         
    append_uint(buf, &pos, e->i_size);
    append_str(buf, &pos, ",\"name\":\"");
    append_str(buf, &pos, e->name);
    append_str(buf, &pos, "\"}\n");

    write(1, buf, pos);
}

static void print_cs_event(const struct cs_event *e) {
    char buf[OUTBUF_SZ];
    int pos = 0;
    memset(buf, 0, OUTBUF_SZ);

    append_str(buf, &pos, "EV {\"seq\":");
    append_uint(buf, &pos, (uint)e->seq);
    append_str(buf, &pos, ",\"tick\":");
    append_uint(buf, &pos, e->ticks);
    append_str(buf, &pos, ",\"cpu\":");
    append_int(buf, &pos, e->cpu);
    append_str(buf, &pos, ",\"pid\":");
    append_int(buf, &pos, e->pid);
    append_str(buf, &pos, ",\"name\":\"");
    append_str(buf, &pos, e->name);
    append_str(buf, &pos, "\",\"state\":");
    append_int(buf, &pos, e->state);
    append_str(buf, &pos, ",\"type\":\"ON_CPU\"}\n");

    write(1, buf, pos);
}

int
main(void)
{
    int n;

    memset(cpus, 0, sizeof(cpus));
    memset(&stats, 0, sizeof(stats));

    n = getcpuinfo(cpus, NCPU);
    if (n < 0 || getprocstats(&stats) < 0) {
        printf("Error fetching system info\n");
        exit(1);
    }
    
    // DEBUG: Print number of CPUs returned
    printf("[DEBUG] getcpuinfo returned %d CPUs\n", n);

    // 1. طباعة حالة المعالجات الحالية
    printf("CPU {\"timestamp\":\"now\",\"system\":{");
    printf("\"total_created\":%lu,\"total_exited\":%lu,", stats.total_created, stats.total_exited);
    printf("\"ever_running\":%lu,\"ever_sleeping\":%lu,\"ever_zombie\":%lu},", 
            stats.unique_count[4], stats.unique_count[2], stats.unique_count[5]);

    printf("\"cpus\":[");
    for (int i = 0; i < n; i++) {
        int state_idx = cpus[i].current_state;
        const char *st_name = "UNK";
        if (state_idx >= 0 && state_idx < PROC_STATE_COUNT) {
            st_name = state_names[state_idx];
        }

        printf("{\"cpu_id\":\"cpu%d\",\"active\":%d,\"current_pid\":%d,\"proc_name\":\"%s\",\"current_state\":\"%s\",\"context_eip\":\"0x%lx\",\"context_esp\":\"0x%lx\",\"busy_percent\":%d}",
               cpus[i].cpu, cpus[i].active, cpus[i].current_pid, cpus[i].proc_name, st_name, cpus[i].context_eip, cpus[i].context_esp, cpus[i].busy_percent);
        
        if (i < n - 1) printf(",");
    }
    printf("]}\n");

    // 2. قراءة أحداث المعالج - اقرأ 256 حدث بنسخة واحدة
    int n_cs = csread(cs_ev, 256);
    for (int i = 0; i < n_cs; i++) {
        if (cs_ev[i].type == 1) 
            print_cs_event(&cs_ev[i]);
    }

    // 3. قراءة أحداث نظام الملفات - اقرأ 256 حدث بنسخة واحدة
    int n_fs = fsread(fs_ev, 256);
    for (int i = 0; i < n_fs; i++) {
        if (fs_ev[i].seq != 0) {
            print_fs_event(&fs_ev[i]);
        }
    }
    
    exit(0); 
}
