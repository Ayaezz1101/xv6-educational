//
// Console input and output, to the uart.
// Reads are line at a time.
// Implements special input characters:
//   newline -- end of line
//   control-h -- backspace
//   control-u -- kill line
//   control-d -- end of file
//   control-p -- print process list
//

#include <stdarg.h>

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "proc.h"

#define BACKSPACE 0x100
#define C(x) ((x) - '@')

void
consputc(int c)
{
  if(c == BACKSPACE){
    uartputc_sync('\b');
    uartputc_sync(' ');
    uartputc_sync('\b');
  } else {
    uartputc_sync(c);
  }
}

struct {
  struct spinlock lock;

#define INPUT_BUF_SIZE 128
  char buf[INPUT_BUF_SIZE];
  uint r;
  uint w;
  uint e;
} cons;

static struct sleeplock conswlock;

int
consolewrite(int user_src, uint64 src, int n)
{
  char buf[128];
  int i = 0;

  acquiresleep(&conswlock);

  while(i < n){
    int nn = sizeof(buf);
    if(nn > n - i)
      nn = n - i;

    if(either_copyin(buf, user_src, src + i, nn) == -1)
      break;

    uartwrite(buf, nn);
    i += nn;
  }

  releasesleep(&conswlock);
  return i;
}

int
consoleread(int user_dst, uint64 dst, int n)
{
  uint target;
  int c;
  char cbuf;

  target = n;
  acquire(&cons.lock);

  while(n > 0){
    while(cons.r == cons.w){
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){
      if(n < target){
        cons.r--;
      }
      break;
    }

    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
      break;

    dst++;
    --n;

    if(c == '\n'){
      break;
    }
  }

  release(&cons.lock);
  return target - n;
}

void
consoleintr(int c)
{
  acquire(&cons.lock);

  switch(c){
  case C('P'):
    procdump();
    break;

  case C('U'):
    while(cons.e != cons.w &&
          cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n'){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;

  case C('H'):
  case '\x7f':
    if(cons.e != cons.w){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;

  default:
    if(c != 0 && cons.e - cons.r < INPUT_BUF_SIZE){
      c = (c == '\r') ? '\n' : c;

      consputc(c);
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;

      if(c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE){
        cons.w = cons.e;
        wakeup(&cons.r);
      }
    }
    break;
  }

  release(&cons.lock);
}

void
consoleinit(void)
{
  initlock(&cons.lock, "cons");
  initsleeplock(&conswlock, "consw");

  uartinit();

  devsw[CONSOLE].read = consoleread;
  devsw[CONSOLE].write = consolewrite;
}