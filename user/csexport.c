#include "kernel/types.h"
#include "user/user.h"

#define OUTBUF_SZ 256

static void append_char(char *buf, int *pos, int max, char c) {
  if (*pos < max - 1) {
    buf[*pos] = c;
    (*pos)++;
  }
}

static void append_str(char *buf, int *pos, int max, const char *s) {
  while (*s) {
    append_char(buf, pos, max, *s);
    s++;
  }
}

static void append_uint(char *buf, int *pos, int max, uint x) {
  char tmp[16];
  int n = 0;

  if (x == 0) {
    append_char(buf, pos, max, '0');
    return;
  }

  while (x > 0 && n < (int)sizeof(tmp)) {
    tmp[n++] = '0' + (x % 10);
    x /= 10;
  }

  while (n > 0) {
    append_char(buf, pos, max, tmp[--n]);
  }
}

static void append_int(char *buf, int *pos, int max, int x) {
  if (x < 0) {
    append_char(buf, pos, max, '-');
    x = -x;
  }
  append_uint(buf, pos, max, (uint)x);
}

static void append_json_string(char *buf, int *pos, int max, const char *s) {
  while (*s) {
    char c = *s++;

    if (c == '"' || c == '\\') {
      append_char(buf, pos, max, '\\');
      append_char(buf, pos, max, c);
    } else if (c >= 32 && c < 127) {
      append_char(buf, pos, max, c);
    }
    // نتجاهل الأحرف غير القابلة للطباعة
  }
}

static void print_json_event(const struct cs_event *e) {
  char buf[OUTBUF_SZ];
  int pos = 0;

  append_str(buf, &pos, OUTBUF_SZ, "EV {\"seq\":");
  append_uint(buf, &pos, OUTBUF_SZ, (uint)e->seq);

  append_str(buf, &pos, OUTBUF_SZ, ",\"tick\":");
  append_uint(buf, &pos, OUTBUF_SZ, e->ticks);

  append_str(buf, &pos, OUTBUF_SZ, ",\"cpu\":");
  append_int(buf, &pos, OUTBUF_SZ, e->cpu);

  append_str(buf, &pos, OUTBUF_SZ, ",\"pid\":");
  append_int(buf, &pos, OUTBUF_SZ, e->pid);

  append_str(buf, &pos, OUTBUF_SZ, ",\"name\":\"");
  append_json_string(buf, &pos, OUTBUF_SZ, e->name);
  append_str(buf, &pos, OUTBUF_SZ, "\"");

  append_str(buf, &pos, OUTBUF_SZ, ",\"state\":");
  append_int(buf, &pos, OUTBUF_SZ, e->state);

  append_str(buf, &pos, OUTBUF_SZ, ",\"type\":\"ON_CPU\"}\n");

  write(1, buf, pos);
}

int main(void) {
  struct cs_event ev[64];

  while (1) {
    int n = csread(ev, 64);

    for (int i = 0; i < n; i++) {
      if (ev[i].type != CS_RUN_START)
        continue;

      print_json_event(&ev[i]);
    }

    // إذا حبيتي تخففي السبام:
    // sleep(1);
  }

  return 0;
}