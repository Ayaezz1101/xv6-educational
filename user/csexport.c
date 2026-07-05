#include "kernel/types.h"
#include "user/user.h"

// نحن نحتاج فقط لهيكل أحداث المعالج هنا
static struct cs_event cs_ev[8];

#define OUTBUF_SZ 512

// دالة طباعة أحداث المعالج (القديمة)
static void print_cs_event(const struct cs_event *e) {
    // نستخدم printf العادية هنا لأن أحداث المعالج ليست بكثافة أحداث الـ FS
    printf("EV {\"seq\":%ld,\"tick\":%d,\"cpu\":%d,\"pid\":%d,\"name\":\"%s\",\"state\":%d,\"type\":\"ON_CPU\"}\n",
           e->seq, e->ticks, e->cpu, e->pid, e->name, e->state);
}

int main(void) {
    // تنبيه لبدء البرنامج
    printf("CS Export (Context Switch) starting...\n");

    while (1) {
        // قراءة أحداث المعالج فقط
        int n_cs = csread(cs_ev, 8);
        for (int i = 0; i < n_cs; i++) {
            // نوع الحدث 1 عادة ما يرمز لتغيير السياق (Context Switch)
            if (cs_ev[i].type == 1)
                print_cs_event(&cs_ev[i]);
        }
        
        // استخدام sleep أو pause لتقليل استهلاك المعالج
        pause(2); 
    }

    return 0;
}
