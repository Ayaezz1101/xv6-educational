
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	00008117          	auipc	sp,0x8
    80000004:	8a010113          	addi	sp,sp,-1888 # 800078a0 <stack0>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd5bf7>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dee78793          	addi	a5,a5,-530 # 80000e6e <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:

static struct sleeplock conswlock;

int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7115                	addi	sp,sp,-224
    800000d2:	ed86                	sd	ra,216(sp)
    800000d4:	e9a2                	sd	s0,208(sp)
    800000d6:	e5a6                	sd	s1,200(sp)
    800000d8:	f952                	sd	s4,176(sp)
    800000da:	f556                	sd	s5,168(sp)
    800000dc:	f15a                	sd	s6,160(sp)
    800000de:	1180                	addi	s0,sp,224
    800000e0:	8aaa                	mv	s5,a0
    800000e2:	8b2e                	mv	s6,a1
    800000e4:	8a32                	mv	s4,a2
  char buf[128];
  int i = 0;

  acquiresleep(&conswlock);
    800000e6:	0000f517          	auipc	a0,0xf
    800000ea:	7ba50513          	addi	a0,a0,1978 # 8000f8a0 <conswlock>
    800000ee:	597030ef          	jal	80003e84 <acquiresleep>

  while(i < n){
    800000f2:	07405163          	blez	s4,80000154 <consolewrite+0x84>
    800000f6:	e1ca                	sd	s2,192(sp)
    800000f8:	fd4e                	sd	s3,184(sp)
    800000fa:	ed5e                	sd	s7,152(sp)
    800000fc:	e962                	sd	s8,144(sp)
    800000fe:	e566                	sd	s9,136(sp)
  int i = 0;
    80000100:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    80000102:	08000c13          	li	s8,128
    80000106:	08000c93          	li	s9,128
      nn = n - i;

    if(either_copyin(buf, user_src, src + i, nn) == -1)
    8000010a:	5bfd                	li	s7,-1
    8000010c:	a035                	j	80000138 <consolewrite+0x68>
    if(nn > n - i)
    8000010e:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src + i, nn) == -1)
    80000112:	86ce                	mv	a3,s3
    80000114:	01648633          	add	a2,s1,s6
    80000118:	85d6                	mv	a1,s5
    8000011a:	f2040513          	addi	a0,s0,-224
    8000011e:	19c020ef          	jal	800022ba <either_copyin>
    80000122:	03750b63          	beq	a0,s7,80000158 <consolewrite+0x88>
      break;

    uartwrite(buf, nn);
    80000126:	85ce                	mv	a1,s3
    80000128:	f2040513          	addi	a0,s0,-224
    8000012c:	79e000ef          	jal	800008ca <uartwrite>
    i += nn;
    80000130:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000134:	0144da63          	bge	s1,s4,80000148 <consolewrite+0x78>
    if(nn > n - i)
    80000138:	409a093b          	subw	s2,s4,s1
    8000013c:	0009079b          	sext.w	a5,s2
    80000140:	fcfc57e3          	bge	s8,a5,8000010e <consolewrite+0x3e>
    80000144:	8966                	mv	s2,s9
    80000146:	b7e1                	j	8000010e <consolewrite+0x3e>
    80000148:	690e                	ld	s2,192(sp)
    8000014a:	79ea                	ld	s3,184(sp)
    8000014c:	6bea                	ld	s7,152(sp)
    8000014e:	6c4a                	ld	s8,144(sp)
    80000150:	6caa                	ld	s9,136(sp)
    80000152:	a801                	j	80000162 <consolewrite+0x92>
  int i = 0;
    80000154:	4481                	li	s1,0
    80000156:	a031                	j	80000162 <consolewrite+0x92>
    80000158:	690e                	ld	s2,192(sp)
    8000015a:	79ea                	ld	s3,184(sp)
    8000015c:	6bea                	ld	s7,152(sp)
    8000015e:	6c4a                	ld	s8,144(sp)
    80000160:	6caa                	ld	s9,136(sp)
  }

  releasesleep(&conswlock);
    80000162:	0000f517          	auipc	a0,0xf
    80000166:	73e50513          	addi	a0,a0,1854 # 8000f8a0 <conswlock>
    8000016a:	561030ef          	jal	80003eca <releasesleep>
  return i;
}
    8000016e:	8526                	mv	a0,s1
    80000170:	60ee                	ld	ra,216(sp)
    80000172:	644e                	ld	s0,208(sp)
    80000174:	64ae                	ld	s1,200(sp)
    80000176:	7a4a                	ld	s4,176(sp)
    80000178:	7aaa                	ld	s5,168(sp)
    8000017a:	7b0a                	ld	s6,160(sp)
    8000017c:	612d                	addi	sp,sp,224
    8000017e:	8082                	ret

0000000080000180 <consoleread>:

int
consoleread(int user_dst, uint64 dst, int n)
{
    80000180:	711d                	addi	sp,sp,-96
    80000182:	ec86                	sd	ra,88(sp)
    80000184:	e8a2                	sd	s0,80(sp)
    80000186:	e4a6                	sd	s1,72(sp)
    80000188:	e0ca                	sd	s2,64(sp)
    8000018a:	fc4e                	sd	s3,56(sp)
    8000018c:	f852                	sd	s4,48(sp)
    8000018e:	f456                	sd	s5,40(sp)
    80000190:	f05a                	sd	s6,32(sp)
    80000192:	ec5e                	sd	s7,24(sp)
    80000194:	1080                	addi	s0,sp,96
    80000196:	8b2a                	mv	s6,a0
    80000198:	8aae                	mv	s5,a1
    8000019a:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019c:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    800001a0:	0000f517          	auipc	a0,0xf
    800001a4:	73050513          	addi	a0,a0,1840 # 8000f8d0 <cons>
    800001a8:	259000ef          	jal	80000c00 <acquire>

  while(n > 0){
    while(cons.r == cons.w){
    800001ac:	0000f497          	auipc	s1,0xf
    800001b0:	6f448493          	addi	s1,s1,1780 # 8000f8a0 <conswlock>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	0000f997          	auipc	s3,0xf
    800001b8:	71c98993          	addi	s3,s3,1820 # 8000f8d0 <cons>
    800001bc:	0000f917          	auipc	s2,0xf
    800001c0:	7ac90913          	addi	s2,s2,1964 # 8000f968 <cons+0x98>
  while(n > 0){
    800001c4:	0b405e63          	blez	s4,80000280 <consoleread+0x100>
    while(cons.r == cons.w){
    800001c8:	0c84a783          	lw	a5,200(s1)
    800001cc:	0cc4a703          	lw	a4,204(s1)
    800001d0:	0af71363          	bne	a4,a5,80000276 <consoleread+0xf6>
      if(killed(myproc())){
    800001d4:	730010ef          	jal	80001904 <myproc>
    800001d8:	775010ef          	jal	8000214c <killed>
    800001dc:	e12d                	bnez	a0,8000023e <consoleread+0xbe>
      sleep(&cons.r, &cons.lock);
    800001de:	85ce                	mv	a1,s3
    800001e0:	854a                	mv	a0,s2
    800001e2:	533010ef          	jal	80001f14 <sleep>
    while(cons.r == cons.w){
    800001e6:	0c84a783          	lw	a5,200(s1)
    800001ea:	0cc4a703          	lw	a4,204(s1)
    800001ee:	fef703e3          	beq	a4,a5,800001d4 <consoleread+0x54>
    800001f2:	e862                	sd	s8,16(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001f4:	0000f717          	auipc	a4,0xf
    800001f8:	6ac70713          	addi	a4,a4,1708 # 8000f8a0 <conswlock>
    800001fc:	0017869b          	addiw	a3,a5,1
    80000200:	0cd72423          	sw	a3,200(a4)
    80000204:	07f7f693          	andi	a3,a5,127
    80000208:	9736                	add	a4,a4,a3
    8000020a:	04874703          	lbu	a4,72(a4)
    8000020e:	00070c1b          	sext.w	s8,a4

    if(c == C('D')){
    80000212:	4691                	li	a3,4
    80000214:	04dc0763          	beq	s8,a3,80000262 <consoleread+0xe2>
        cons.r--;
      }
      break;
    }

    cbuf = c;
    80000218:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000021c:	4685                	li	a3,1
    8000021e:	faf40613          	addi	a2,s0,-81
    80000222:	85d6                	mv	a1,s5
    80000224:	855a                	mv	a0,s6
    80000226:	04a020ef          	jal	80002270 <either_copyout>
    8000022a:	57fd                	li	a5,-1
    8000022c:	04f50963          	beq	a0,a5,8000027e <consoleread+0xfe>
      break;

    dst++;
    80000230:	0a85                	addi	s5,s5,1
    --n;
    80000232:	3a7d                	addiw	s4,s4,-1

    if(c == '\n'){
    80000234:	47a9                	li	a5,10
    80000236:	04fc0e63          	beq	s8,a5,80000292 <consoleread+0x112>
    8000023a:	6c42                	ld	s8,16(sp)
    8000023c:	b761                	j	800001c4 <consoleread+0x44>
        release(&cons.lock);
    8000023e:	0000f517          	auipc	a0,0xf
    80000242:	69250513          	addi	a0,a0,1682 # 8000f8d0 <cons>
    80000246:	253000ef          	jal	80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
    }
  }

  release(&cons.lock);
  return target - n;
}
    8000024c:	60e6                	ld	ra,88(sp)
    8000024e:	6446                	ld	s0,80(sp)
    80000250:	64a6                	ld	s1,72(sp)
    80000252:	6906                	ld	s2,64(sp)
    80000254:	79e2                	ld	s3,56(sp)
    80000256:	7a42                	ld	s4,48(sp)
    80000258:	7aa2                	ld	s5,40(sp)
    8000025a:	7b02                	ld	s6,32(sp)
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	6125                	addi	sp,sp,96
    80000260:	8082                	ret
      if(n < target){
    80000262:	000a071b          	sext.w	a4,s4
    80000266:	01777a63          	bgeu	a4,s7,8000027a <consoleread+0xfa>
        cons.r--;
    8000026a:	0000f717          	auipc	a4,0xf
    8000026e:	6ef72f23          	sw	a5,1790(a4) # 8000f968 <cons+0x98>
    80000272:	6c42                	ld	s8,16(sp)
    80000274:	a031                	j	80000280 <consoleread+0x100>
    80000276:	e862                	sd	s8,16(sp)
    80000278:	bfb5                	j	800001f4 <consoleread+0x74>
    8000027a:	6c42                	ld	s8,16(sp)
    8000027c:	a011                	j	80000280 <consoleread+0x100>
    8000027e:	6c42                	ld	s8,16(sp)
  release(&cons.lock);
    80000280:	0000f517          	auipc	a0,0xf
    80000284:	65050513          	addi	a0,a0,1616 # 8000f8d0 <cons>
    80000288:	211000ef          	jal	80000c98 <release>
  return target - n;
    8000028c:	414b853b          	subw	a0,s7,s4
    80000290:	bf75                	j	8000024c <consoleread+0xcc>
    80000292:	6c42                	ld	s8,16(sp)
    80000294:	b7f5                	j	80000280 <consoleread+0x100>

0000000080000296 <consputc>:
{
    80000296:	1141                	addi	sp,sp,-16
    80000298:	e406                	sd	ra,8(sp)
    8000029a:	e022                	sd	s0,0(sp)
    8000029c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029e:	10000793          	li	a5,256
    800002a2:	00f50863          	beq	a0,a5,800002b2 <consputc+0x1c>
    uartputc_sync(c);
    800002a6:	6b8000ef          	jal	8000095e <uartputc_sync>
}
    800002aa:	60a2                	ld	ra,8(sp)
    800002ac:	6402                	ld	s0,0(sp)
    800002ae:	0141                	addi	sp,sp,16
    800002b0:	8082                	ret
    uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	6aa000ef          	jal	8000095e <uartputc_sync>
    uartputc_sync(' ');
    800002b8:	02000513          	li	a0,32
    800002bc:	6a2000ef          	jal	8000095e <uartputc_sync>
    uartputc_sync('\b');
    800002c0:	4521                	li	a0,8
    800002c2:	69c000ef          	jal	8000095e <uartputc_sync>
    800002c6:	b7d5                	j	800002aa <consputc+0x14>

00000000800002c8 <consoleintr>:

void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	1000                	addi	s0,sp,32
    800002d2:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d4:	0000f517          	auipc	a0,0xf
    800002d8:	5fc50513          	addi	a0,a0,1532 # 8000f8d0 <cons>
    800002dc:	125000ef          	jal	80000c00 <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	08f48f63          	beq	s1,a5,80000380 <consoleintr+0xb8>
    800002e6:	0297c563          	blt	a5,s1,80000310 <consoleintr+0x48>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48463          	beq	s1,a5,800003d4 <consoleintr+0x10c>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49563          	bne	s1,a5,800003fc <consoleintr+0x134>
  case C('P'):
    procdump();
    800002f6:	00e020ef          	jal	80002304 <procdump>
      }
    }
    break;
  }

  release(&cons.lock);
    800002fa:	0000f517          	auipc	a0,0xf
    800002fe:	5d650513          	addi	a0,a0,1494 # 8000f8d0 <cons>
    80000302:	197000ef          	jal	80000c98 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6105                	addi	sp,sp,32
    8000030e:	8082                	ret
  switch(c){
    80000310:	07f00793          	li	a5,127
    80000314:	0cf48063          	beq	s1,a5,800003d4 <consoleintr+0x10c>
    if(c != 0 && cons.e - cons.r < INPUT_BUF_SIZE){
    80000318:	0000f717          	auipc	a4,0xf
    8000031c:	58870713          	addi	a4,a4,1416 # 8000f8a0 <conswlock>
    80000320:	0d072783          	lw	a5,208(a4)
    80000324:	0c872703          	lw	a4,200(a4)
    80000328:	9f99                	subw	a5,a5,a4
    8000032a:	07f00713          	li	a4,127
    8000032e:	fcf766e3          	bltu	a4,a5,800002fa <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000332:	47b5                	li	a5,13
    80000334:	0cf48763          	beq	s1,a5,80000402 <consoleintr+0x13a>
      consputc(c);
    80000338:	8526                	mv	a0,s1
    8000033a:	f5dff0ef          	jal	80000296 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000033e:	0000f797          	auipc	a5,0xf
    80000342:	56278793          	addi	a5,a5,1378 # 8000f8a0 <conswlock>
    80000346:	0d07a683          	lw	a3,208(a5)
    8000034a:	0016871b          	addiw	a4,a3,1
    8000034e:	0007061b          	sext.w	a2,a4
    80000352:	0ce7a823          	sw	a4,208(a5)
    80000356:	07f6f693          	andi	a3,a3,127
    8000035a:	97b6                	add	a5,a5,a3
    8000035c:	04978423          	sb	s1,72(a5)
      if(c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE){
    80000360:	47a9                	li	a5,10
    80000362:	0cf48563          	beq	s1,a5,8000042c <consoleintr+0x164>
    80000366:	4791                	li	a5,4
    80000368:	0cf48263          	beq	s1,a5,8000042c <consoleintr+0x164>
    8000036c:	0000f797          	auipc	a5,0xf
    80000370:	5fc7a783          	lw	a5,1532(a5) # 8000f968 <cons+0x98>
    80000374:	9f1d                	subw	a4,a4,a5
    80000376:	08000793          	li	a5,128
    8000037a:	f8f710e3          	bne	a4,a5,800002fa <consoleintr+0x32>
    8000037e:	a07d                	j	8000042c <consoleintr+0x164>
    80000380:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000382:	0000f717          	auipc	a4,0xf
    80000386:	51e70713          	addi	a4,a4,1310 # 8000f8a0 <conswlock>
    8000038a:	0d072783          	lw	a5,208(a4)
    8000038e:	0cc72703          	lw	a4,204(a4)
          cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n'){
    80000392:	0000f497          	auipc	s1,0xf
    80000396:	50e48493          	addi	s1,s1,1294 # 8000f8a0 <conswlock>
    while(cons.e != cons.w &&
    8000039a:	4929                	li	s2,10
    8000039c:	02f70863          	beq	a4,a5,800003cc <consoleintr+0x104>
          cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	37fd                	addiw	a5,a5,-1
    800003a2:	07f7f713          	andi	a4,a5,127
    800003a6:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a8:	04874703          	lbu	a4,72(a4)
    800003ac:	03270263          	beq	a4,s2,800003d0 <consoleintr+0x108>
      cons.e--;
    800003b0:	0cf4a823          	sw	a5,208(s1)
      consputc(BACKSPACE);
    800003b4:	10000513          	li	a0,256
    800003b8:	edfff0ef          	jal	80000296 <consputc>
    while(cons.e != cons.w &&
    800003bc:	0d04a783          	lw	a5,208(s1)
    800003c0:	0cc4a703          	lw	a4,204(s1)
    800003c4:	fcf71ee3          	bne	a4,a5,800003a0 <consoleintr+0xd8>
    800003c8:	6902                	ld	s2,0(sp)
    800003ca:	bf05                	j	800002fa <consoleintr+0x32>
    800003cc:	6902                	ld	s2,0(sp)
    800003ce:	b735                	j	800002fa <consoleintr+0x32>
    800003d0:	6902                	ld	s2,0(sp)
    800003d2:	b725                	j	800002fa <consoleintr+0x32>
    if(cons.e != cons.w){
    800003d4:	0000f717          	auipc	a4,0xf
    800003d8:	4cc70713          	addi	a4,a4,1228 # 8000f8a0 <conswlock>
    800003dc:	0d072783          	lw	a5,208(a4)
    800003e0:	0cc72703          	lw	a4,204(a4)
    800003e4:	f0f70be3          	beq	a4,a5,800002fa <consoleintr+0x32>
      cons.e--;
    800003e8:	37fd                	addiw	a5,a5,-1
    800003ea:	0000f717          	auipc	a4,0xf
    800003ee:	58f72323          	sw	a5,1414(a4) # 8000f970 <cons+0xa0>
      consputc(BACKSPACE);
    800003f2:	10000513          	li	a0,256
    800003f6:	ea1ff0ef          	jal	80000296 <consputc>
    800003fa:	b701                	j	800002fa <consoleintr+0x32>
    if(c != 0 && cons.e - cons.r < INPUT_BUF_SIZE){
    800003fc:	ee048fe3          	beqz	s1,800002fa <consoleintr+0x32>
    80000400:	bf21                	j	80000318 <consoleintr+0x50>
      consputc(c);
    80000402:	4529                	li	a0,10
    80000404:	e93ff0ef          	jal	80000296 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000408:	0000f797          	auipc	a5,0xf
    8000040c:	49878793          	addi	a5,a5,1176 # 8000f8a0 <conswlock>
    80000410:	0d07a703          	lw	a4,208(a5)
    80000414:	0017069b          	addiw	a3,a4,1
    80000418:	0006861b          	sext.w	a2,a3
    8000041c:	0cd7a823          	sw	a3,208(a5)
    80000420:	07f77713          	andi	a4,a4,127
    80000424:	97ba                	add	a5,a5,a4
    80000426:	4729                	li	a4,10
    80000428:	04e78423          	sb	a4,72(a5)
        cons.w = cons.e;
    8000042c:	0000f797          	auipc	a5,0xf
    80000430:	54c7a023          	sw	a2,1344(a5) # 8000f96c <cons+0x9c>
        wakeup(&cons.r);
    80000434:	0000f517          	auipc	a0,0xf
    80000438:	53450513          	addi	a0,a0,1332 # 8000f968 <cons+0x98>
    8000043c:	325010ef          	jal	80001f60 <wakeup>
    80000440:	bd6d                	j	800002fa <consoleintr+0x32>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00007597          	auipc	a1,0x7
    8000044e:	bb658593          	addi	a1,a1,-1098 # 80007000 <etext>
    80000452:	0000f517          	auipc	a0,0xf
    80000456:	47e50513          	addi	a0,a0,1150 # 8000f8d0 <cons>
    8000045a:	726000ef          	jal	80000b80 <initlock>
  initsleeplock(&conswlock, "consw");
    8000045e:	00007597          	auipc	a1,0x7
    80000462:	bb258593          	addi	a1,a1,-1102 # 80007010 <etext+0x10>
    80000466:	0000f517          	auipc	a0,0xf
    8000046a:	43a50513          	addi	a0,a0,1082 # 8000f8a0 <conswlock>
    8000046e:	1e1030ef          	jal	80003e4e <initsleeplock>

  uartinit();
    80000472:	400000ef          	jal	80000872 <uartinit>

  devsw[CONSOLE].read = consoleread;
    80000476:	0001f797          	auipc	a5,0x1f
    8000047a:	5ca78793          	addi	a5,a5,1482 # 8001fa40 <devsw>
    8000047e:	00000717          	auipc	a4,0x0
    80000482:	d0270713          	addi	a4,a4,-766 # 80000180 <consoleread>
    80000486:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000488:	00000717          	auipc	a4,0x0
    8000048c:	c4870713          	addi	a4,a4,-952 # 800000d0 <consolewrite>
    80000490:	ef98                	sd	a4,24(a5)
    80000492:	60a2                	ld	ra,8(sp)
    80000494:	6402                	ld	s0,0(sp)
    80000496:	0141                	addi	sp,sp,16
    80000498:	8082                	ret

000000008000049a <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    8000049a:	7139                	addi	sp,sp,-64
    8000049c:	fc06                	sd	ra,56(sp)
    8000049e:	f822                	sd	s0,48(sp)
    800004a0:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    800004a2:	c219                	beqz	a2,800004a8 <printint+0xe>
    800004a4:	08054063          	bltz	a0,80000524 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    800004a8:	4881                	li	a7,0
    800004aa:	fc840693          	addi	a3,s0,-56

  i = 0;
    800004ae:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    800004b0:	00007617          	auipc	a2,0x7
    800004b4:	28860613          	addi	a2,a2,648 # 80007738 <digits>
    800004b8:	883e                	mv	a6,a5
    800004ba:	2785                	addiw	a5,a5,1
    800004bc:	02b57733          	remu	a4,a0,a1
    800004c0:	9732                	add	a4,a4,a2
    800004c2:	00074703          	lbu	a4,0(a4)
    800004c6:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800004ca:	872a                	mv	a4,a0
    800004cc:	02b55533          	divu	a0,a0,a1
    800004d0:	0685                	addi	a3,a3,1
    800004d2:	feb773e3          	bgeu	a4,a1,800004b8 <printint+0x1e>

  if(sign)
    800004d6:	00088a63          	beqz	a7,800004ea <printint+0x50>
    buf[i++] = '-';
    800004da:	1781                	addi	a5,a5,-32
    800004dc:	97a2                	add	a5,a5,s0
    800004de:	02d00713          	li	a4,45
    800004e2:	fee78423          	sb	a4,-24(a5)
    800004e6:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004ea:	02f05963          	blez	a5,8000051c <printint+0x82>
    800004ee:	f426                	sd	s1,40(sp)
    800004f0:	f04a                	sd	s2,32(sp)
    800004f2:	fc840713          	addi	a4,s0,-56
    800004f6:	00f704b3          	add	s1,a4,a5
    800004fa:	fff70913          	addi	s2,a4,-1
    800004fe:	993e                	add	s2,s2,a5
    80000500:	37fd                	addiw	a5,a5,-1
    80000502:	1782                	slli	a5,a5,0x20
    80000504:	9381                	srli	a5,a5,0x20
    80000506:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	d89ff0ef          	jal	80000296 <consputc>
  while(--i >= 0)
    80000512:	14fd                	addi	s1,s1,-1
    80000514:	ff249be3          	bne	s1,s2,8000050a <printint+0x70>
    80000518:	74a2                	ld	s1,40(sp)
    8000051a:	7902                	ld	s2,32(sp)
}
    8000051c:	70e2                	ld	ra,56(sp)
    8000051e:	7442                	ld	s0,48(sp)
    80000520:	6121                	addi	sp,sp,64
    80000522:	8082                	ret
    x = -xx;
    80000524:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    80000528:	4885                	li	a7,1
    x = -xx;
    8000052a:	b741                	j	800004aa <printint+0x10>

000000008000052c <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    8000052c:	7131                	addi	sp,sp,-192
    8000052e:	fc86                	sd	ra,120(sp)
    80000530:	f8a2                	sd	s0,112(sp)
    80000532:	e8d2                	sd	s4,80(sp)
    80000534:	0100                	addi	s0,sp,128
    80000536:	8a2a                	mv	s4,a0
    80000538:	e40c                	sd	a1,8(s0)
    8000053a:	e810                	sd	a2,16(s0)
    8000053c:	ec14                	sd	a3,24(s0)
    8000053e:	f018                	sd	a4,32(s0)
    80000540:	f41c                	sd	a5,40(s0)
    80000542:	03043823          	sd	a6,48(s0)
    80000546:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    8000054a:	00007797          	auipc	a5,0x7
    8000054e:	31a7a783          	lw	a5,794(a5) # 80007864 <panicking>
    80000552:	c3a1                	beqz	a5,80000592 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000554:	00840793          	addi	a5,s0,8
    80000558:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000055c:	000a4503          	lbu	a0,0(s4)
    80000560:	28050763          	beqz	a0,800007ee <printf+0x2c2>
    80000564:	f4a6                	sd	s1,104(sp)
    80000566:	f0ca                	sd	s2,96(sp)
    80000568:	ecce                	sd	s3,88(sp)
    8000056a:	e4d6                	sd	s5,72(sp)
    8000056c:	e0da                	sd	s6,64(sp)
    8000056e:	f862                	sd	s8,48(sp)
    80000570:	f466                	sd	s9,40(sp)
    80000572:	f06a                	sd	s10,32(sp)
    80000574:	ec6e                	sd	s11,24(sp)
    80000576:	4981                	li	s3,0
    if(cx != '%'){
    80000578:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000057c:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    80000580:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000584:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000588:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000058c:	07000d93          	li	s11,112
    80000590:	a01d                	j	800005b6 <printf+0x8a>
    acquire(&pr.lock);
    80000592:	0000f517          	auipc	a0,0xf
    80000596:	3e650513          	addi	a0,a0,998 # 8000f978 <pr>
    8000059a:	666000ef          	jal	80000c00 <acquire>
    8000059e:	bf5d                	j	80000554 <printf+0x28>
      consputc(cx);
    800005a0:	cf7ff0ef          	jal	80000296 <consputc>
      continue;
    800005a4:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    800005a6:	0014899b          	addiw	s3,s1,1
    800005aa:	013a07b3          	add	a5,s4,s3
    800005ae:	0007c503          	lbu	a0,0(a5)
    800005b2:	20050b63          	beqz	a0,800007c8 <printf+0x29c>
    if(cx != '%'){
    800005b6:	ff5515e3          	bne	a0,s5,800005a0 <printf+0x74>
    i++;
    800005ba:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    800005be:	009a07b3          	add	a5,s4,s1
    800005c2:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    800005c6:	20090b63          	beqz	s2,800007dc <printf+0x2b0>
    800005ca:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    800005ce:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    800005d0:	c789                	beqz	a5,800005da <printf+0xae>
    800005d2:	009a0733          	add	a4,s4,s1
    800005d6:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005da:	03690963          	beq	s2,s6,8000060c <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005de:	05890363          	beq	s2,s8,80000624 <printf+0xf8>
    } else if(c0 == 'u'){
    800005e2:	0d990663          	beq	s2,s9,800006ae <printf+0x182>
    } else if(c0 == 'x'){
    800005e6:	11a90d63          	beq	s2,s10,80000700 <printf+0x1d4>
    } else if(c0 == 'p'){
    800005ea:	15b90663          	beq	s2,s11,80000736 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005ee:	06300793          	li	a5,99
    800005f2:	18f90563          	beq	s2,a5,8000077c <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005f6:	07300793          	li	a5,115
    800005fa:	18f90b63          	beq	s2,a5,80000790 <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005fe:	03591b63          	bne	s2,s5,80000634 <printf+0x108>
      consputc('%');
    80000602:	02500513          	li	a0,37
    80000606:	c91ff0ef          	jal	80000296 <consputc>
    8000060a:	bf71                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    8000060c:	f8843783          	ld	a5,-120(s0)
    80000610:	00878713          	addi	a4,a5,8
    80000614:	f8e43423          	sd	a4,-120(s0)
    80000618:	4605                	li	a2,1
    8000061a:	45a9                	li	a1,10
    8000061c:	4388                	lw	a0,0(a5)
    8000061e:	e7dff0ef          	jal	8000049a <printint>
    80000622:	b751                	j	800005a6 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    80000624:	01678f63          	beq	a5,s6,80000642 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    80000628:	03878b63          	beq	a5,s8,8000065e <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    8000062c:	09978e63          	beq	a5,s9,800006c8 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    80000630:	0fa78563          	beq	a5,s10,8000071a <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000634:	8556                	mv	a0,s5
    80000636:	c61ff0ef          	jal	80000296 <consputc>
      consputc(c0);
    8000063a:	854a                	mv	a0,s2
    8000063c:	c5bff0ef          	jal	80000296 <consputc>
    80000640:	b79d                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000642:	f8843783          	ld	a5,-120(s0)
    80000646:	00878713          	addi	a4,a5,8
    8000064a:	f8e43423          	sd	a4,-120(s0)
    8000064e:	4605                	li	a2,1
    80000650:	45a9                	li	a1,10
    80000652:	6388                	ld	a0,0(a5)
    80000654:	e47ff0ef          	jal	8000049a <printint>
      i += 1;
    80000658:	0029849b          	addiw	s1,s3,2
    8000065c:	b7a9                	j	800005a6 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000065e:	06400793          	li	a5,100
    80000662:	02f68863          	beq	a3,a5,80000692 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000666:	07500793          	li	a5,117
    8000066a:	06f68d63          	beq	a3,a5,800006e4 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000066e:	07800793          	li	a5,120
    80000672:	fcf691e3          	bne	a3,a5,80000634 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000676:	f8843783          	ld	a5,-120(s0)
    8000067a:	00878713          	addi	a4,a5,8
    8000067e:	f8e43423          	sd	a4,-120(s0)
    80000682:	4601                	li	a2,0
    80000684:	45c1                	li	a1,16
    80000686:	6388                	ld	a0,0(a5)
    80000688:	e13ff0ef          	jal	8000049a <printint>
      i += 2;
    8000068c:	0039849b          	addiw	s1,s3,3
    80000690:	bf19                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000692:	f8843783          	ld	a5,-120(s0)
    80000696:	00878713          	addi	a4,a5,8
    8000069a:	f8e43423          	sd	a4,-120(s0)
    8000069e:	4605                	li	a2,1
    800006a0:	45a9                	li	a1,10
    800006a2:	6388                	ld	a0,0(a5)
    800006a4:	df7ff0ef          	jal	8000049a <printint>
      i += 2;
    800006a8:	0039849b          	addiw	s1,s3,3
    800006ac:	bded                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    800006ae:	f8843783          	ld	a5,-120(s0)
    800006b2:	00878713          	addi	a4,a5,8
    800006b6:	f8e43423          	sd	a4,-120(s0)
    800006ba:	4601                	li	a2,0
    800006bc:	45a9                	li	a1,10
    800006be:	0007e503          	lwu	a0,0(a5)
    800006c2:	dd9ff0ef          	jal	8000049a <printint>
    800006c6:	b5c5                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	4601                	li	a2,0
    800006d6:	45a9                	li	a1,10
    800006d8:	6388                	ld	a0,0(a5)
    800006da:	dc1ff0ef          	jal	8000049a <printint>
      i += 1;
    800006de:	0029849b          	addiw	s1,s3,2
    800006e2:	b5d1                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	4601                	li	a2,0
    800006f2:	45a9                	li	a1,10
    800006f4:	6388                	ld	a0,0(a5)
    800006f6:	da5ff0ef          	jal	8000049a <printint>
      i += 2;
    800006fa:	0039849b          	addiw	s1,s3,3
    800006fe:	b565                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    80000700:	f8843783          	ld	a5,-120(s0)
    80000704:	00878713          	addi	a4,a5,8
    80000708:	f8e43423          	sd	a4,-120(s0)
    8000070c:	4601                	li	a2,0
    8000070e:	45c1                	li	a1,16
    80000710:	0007e503          	lwu	a0,0(a5)
    80000714:	d87ff0ef          	jal	8000049a <printint>
    80000718:	b579                	j	800005a6 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    8000071a:	f8843783          	ld	a5,-120(s0)
    8000071e:	00878713          	addi	a4,a5,8
    80000722:	f8e43423          	sd	a4,-120(s0)
    80000726:	4601                	li	a2,0
    80000728:	45c1                	li	a1,16
    8000072a:	6388                	ld	a0,0(a5)
    8000072c:	d6fff0ef          	jal	8000049a <printint>
      i += 1;
    80000730:	0029849b          	addiw	s1,s3,2
    80000734:	bd8d                	j	800005a6 <printf+0x7a>
    80000736:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000738:	f8843783          	ld	a5,-120(s0)
    8000073c:	00878713          	addi	a4,a5,8
    80000740:	f8e43423          	sd	a4,-120(s0)
    80000744:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000748:	03000513          	li	a0,48
    8000074c:	b4bff0ef          	jal	80000296 <consputc>
  consputc('x');
    80000750:	07800513          	li	a0,120
    80000754:	b43ff0ef          	jal	80000296 <consputc>
    80000758:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075a:	00007b97          	auipc	s7,0x7
    8000075e:	fdeb8b93          	addi	s7,s7,-34 # 80007738 <digits>
    80000762:	03c9d793          	srli	a5,s3,0x3c
    80000766:	97de                	add	a5,a5,s7
    80000768:	0007c503          	lbu	a0,0(a5)
    8000076c:	b2bff0ef          	jal	80000296 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000770:	0992                	slli	s3,s3,0x4
    80000772:	397d                	addiw	s2,s2,-1
    80000774:	fe0917e3          	bnez	s2,80000762 <printf+0x236>
    80000778:	7be2                	ld	s7,56(sp)
    8000077a:	b535                	j	800005a6 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000077c:	f8843783          	ld	a5,-120(s0)
    80000780:	00878713          	addi	a4,a5,8
    80000784:	f8e43423          	sd	a4,-120(s0)
    80000788:	4388                	lw	a0,0(a5)
    8000078a:	b0dff0ef          	jal	80000296 <consputc>
    8000078e:	bd21                	j	800005a6 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000790:	f8843783          	ld	a5,-120(s0)
    80000794:	00878713          	addi	a4,a5,8
    80000798:	f8e43423          	sd	a4,-120(s0)
    8000079c:	0007b903          	ld	s2,0(a5)
    800007a0:	00090d63          	beqz	s2,800007ba <printf+0x28e>
      for(; *s; s++)
    800007a4:	00094503          	lbu	a0,0(s2)
    800007a8:	de050fe3          	beqz	a0,800005a6 <printf+0x7a>
        consputc(*s);
    800007ac:	aebff0ef          	jal	80000296 <consputc>
      for(; *s; s++)
    800007b0:	0905                	addi	s2,s2,1
    800007b2:	00094503          	lbu	a0,0(s2)
    800007b6:	f97d                	bnez	a0,800007ac <printf+0x280>
    800007b8:	b3fd                	j	800005a6 <printf+0x7a>
        s = "(null)";
    800007ba:	00007917          	auipc	s2,0x7
    800007be:	85e90913          	addi	s2,s2,-1954 # 80007018 <etext+0x18>
      for(; *s; s++)
    800007c2:	02800513          	li	a0,40
    800007c6:	b7dd                	j	800007ac <printf+0x280>
    800007c8:	74a6                	ld	s1,104(sp)
    800007ca:	7906                	ld	s2,96(sp)
    800007cc:	69e6                	ld	s3,88(sp)
    800007ce:	6aa6                	ld	s5,72(sp)
    800007d0:	6b06                	ld	s6,64(sp)
    800007d2:	7c42                	ld	s8,48(sp)
    800007d4:	7ca2                	ld	s9,40(sp)
    800007d6:	7d02                	ld	s10,32(sp)
    800007d8:	6de2                	ld	s11,24(sp)
    800007da:	a811                	j	800007ee <printf+0x2c2>
    800007dc:	74a6                	ld	s1,104(sp)
    800007de:	7906                	ld	s2,96(sp)
    800007e0:	69e6                	ld	s3,88(sp)
    800007e2:	6aa6                	ld	s5,72(sp)
    800007e4:	6b06                	ld	s6,64(sp)
    800007e6:	7c42                	ld	s8,48(sp)
    800007e8:	7ca2                	ld	s9,40(sp)
    800007ea:	7d02                	ld	s10,32(sp)
    800007ec:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007ee:	00007797          	auipc	a5,0x7
    800007f2:	0767a783          	lw	a5,118(a5) # 80007864 <panicking>
    800007f6:	c799                	beqz	a5,80000804 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007f8:	4501                	li	a0,0
    800007fa:	70e6                	ld	ra,120(sp)
    800007fc:	7446                	ld	s0,112(sp)
    800007fe:	6a46                	ld	s4,80(sp)
    80000800:	6129                	addi	sp,sp,192
    80000802:	8082                	ret
    release(&pr.lock);
    80000804:	0000f517          	auipc	a0,0xf
    80000808:	17450513          	addi	a0,a0,372 # 8000f978 <pr>
    8000080c:	48c000ef          	jal	80000c98 <release>
  return 0;
    80000810:	b7e5                	j	800007f8 <printf+0x2cc>

0000000080000812 <panic>:

void
panic(char *s)
{
    80000812:	1101                	addi	sp,sp,-32
    80000814:	ec06                	sd	ra,24(sp)
    80000816:	e822                	sd	s0,16(sp)
    80000818:	e426                	sd	s1,8(sp)
    8000081a:	e04a                	sd	s2,0(sp)
    8000081c:	1000                	addi	s0,sp,32
    8000081e:	84aa                	mv	s1,a0
  panicking = 1;
    80000820:	4905                	li	s2,1
    80000822:	00007797          	auipc	a5,0x7
    80000826:	0527a123          	sw	s2,66(a5) # 80007864 <panicking>
  printf("panic: ");
    8000082a:	00006517          	auipc	a0,0x6
    8000082e:	7f650513          	addi	a0,a0,2038 # 80007020 <etext+0x20>
    80000832:	cfbff0ef          	jal	8000052c <printf>
  printf("%s\n", s);
    80000836:	85a6                	mv	a1,s1
    80000838:	00006517          	auipc	a0,0x6
    8000083c:	7f050513          	addi	a0,a0,2032 # 80007028 <etext+0x28>
    80000840:	cedff0ef          	jal	8000052c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000844:	00007797          	auipc	a5,0x7
    80000848:	0127ae23          	sw	s2,28(a5) # 80007860 <panicked>
  for(;;)
    8000084c:	a001                	j	8000084c <panic+0x3a>

000000008000084e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000084e:	1141                	addi	sp,sp,-16
    80000850:	e406                	sd	ra,8(sp)
    80000852:	e022                	sd	s0,0(sp)
    80000854:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000856:	00006597          	auipc	a1,0x6
    8000085a:	7da58593          	addi	a1,a1,2010 # 80007030 <etext+0x30>
    8000085e:	0000f517          	auipc	a0,0xf
    80000862:	11a50513          	addi	a0,a0,282 # 8000f978 <pr>
    80000866:	31a000ef          	jal	80000b80 <initlock>
}
    8000086a:	60a2                	ld	ra,8(sp)
    8000086c:	6402                	ld	s0,0(sp)
    8000086e:	0141                	addi	sp,sp,16
    80000870:	8082                	ret

0000000080000872 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000872:	1141                	addi	sp,sp,-16
    80000874:	e406                	sd	ra,8(sp)
    80000876:	e022                	sd	s0,0(sp)
    80000878:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000087a:	100007b7          	lui	a5,0x10000
    8000087e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000882:	10000737          	lui	a4,0x10000
    80000886:	f8000693          	li	a3,-128
    8000088a:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000088e:	468d                	li	a3,3
    80000890:	10000637          	lui	a2,0x10000
    80000894:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000898:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000089c:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800008a0:	10000737          	lui	a4,0x10000
    800008a4:	461d                	li	a2,7
    800008a6:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800008aa:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    800008ae:	00006597          	auipc	a1,0x6
    800008b2:	78a58593          	addi	a1,a1,1930 # 80007038 <etext+0x38>
    800008b6:	0000f517          	auipc	a0,0xf
    800008ba:	0da50513          	addi	a0,a0,218 # 8000f990 <tx_lock>
    800008be:	2c2000ef          	jal	80000b80 <initlock>
}
    800008c2:	60a2                	ld	ra,8(sp)
    800008c4:	6402                	ld	s0,0(sp)
    800008c6:	0141                	addi	sp,sp,16
    800008c8:	8082                	ret

00000000800008ca <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    800008ca:	715d                	addi	sp,sp,-80
    800008cc:	e486                	sd	ra,72(sp)
    800008ce:	e0a2                	sd	s0,64(sp)
    800008d0:	fc26                	sd	s1,56(sp)
    800008d2:	ec56                	sd	s5,24(sp)
    800008d4:	0880                	addi	s0,sp,80
    800008d6:	8aaa                	mv	s5,a0
    800008d8:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008da:	0000f517          	auipc	a0,0xf
    800008de:	0b650513          	addi	a0,a0,182 # 8000f990 <tx_lock>
    800008e2:	31e000ef          	jal	80000c00 <acquire>

  int i = 0;
  while(i < n){ 
    800008e6:	06905063          	blez	s1,80000946 <uartwrite+0x7c>
    800008ea:	f84a                	sd	s2,48(sp)
    800008ec:	f44e                	sd	s3,40(sp)
    800008ee:	f052                	sd	s4,32(sp)
    800008f0:	e85a                	sd	s6,16(sp)
    800008f2:	e45e                	sd	s7,8(sp)
    800008f4:	8a56                	mv	s4,s5
    800008f6:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008f8:	00007497          	auipc	s1,0x7
    800008fc:	f7448493          	addi	s1,s1,-140 # 8000786c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000900:	0000f997          	auipc	s3,0xf
    80000904:	09098993          	addi	s3,s3,144 # 8000f990 <tx_lock>
    80000908:	00007917          	auipc	s2,0x7
    8000090c:	f6090913          	addi	s2,s2,-160 # 80007868 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    80000910:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    80000914:	4b05                	li	s6,1
    80000916:	a005                	j	80000936 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	854a                	mv	a0,s2
    8000091c:	5f8010ef          	jal	80001f14 <sleep>
    while(tx_busy != 0){
    80000920:	409c                	lw	a5,0(s1)
    80000922:	fbfd                	bnez	a5,80000918 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    80000924:	000a4783          	lbu	a5,0(s4)
    80000928:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    8000092c:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    80000930:	0a05                	addi	s4,s4,1
    80000932:	015a0563          	beq	s4,s5,8000093c <uartwrite+0x72>
    while(tx_busy != 0){
    80000936:	409c                	lw	a5,0(s1)
    80000938:	f3e5                	bnez	a5,80000918 <uartwrite+0x4e>
    8000093a:	b7ed                	j	80000924 <uartwrite+0x5a>
    8000093c:	7942                	ld	s2,48(sp)
    8000093e:	79a2                	ld	s3,40(sp)
    80000940:	7a02                	ld	s4,32(sp)
    80000942:	6b42                	ld	s6,16(sp)
    80000944:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000946:	0000f517          	auipc	a0,0xf
    8000094a:	04a50513          	addi	a0,a0,74 # 8000f990 <tx_lock>
    8000094e:	34a000ef          	jal	80000c98 <release>
}
    80000952:	60a6                	ld	ra,72(sp)
    80000954:	6406                	ld	s0,64(sp)
    80000956:	74e2                	ld	s1,56(sp)
    80000958:	6ae2                	ld	s5,24(sp)
    8000095a:	6161                	addi	sp,sp,80
    8000095c:	8082                	ret

000000008000095e <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000095e:	1101                	addi	sp,sp,-32
    80000960:	ec06                	sd	ra,24(sp)
    80000962:	e822                	sd	s0,16(sp)
    80000964:	e426                	sd	s1,8(sp)
    80000966:	1000                	addi	s0,sp,32
    80000968:	84aa                	mv	s1,a0
  if(panicking == 0)
    8000096a:	00007797          	auipc	a5,0x7
    8000096e:	efa7a783          	lw	a5,-262(a5) # 80007864 <panicking>
    80000972:	cf95                	beqz	a5,800009ae <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000974:	00007797          	auipc	a5,0x7
    80000978:	eec7a783          	lw	a5,-276(a5) # 80007860 <panicked>
    8000097c:	ef85                	bnez	a5,800009b4 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000097e:	10000737          	lui	a4,0x10000
    80000982:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000984:	00074783          	lbu	a5,0(a4)
    80000988:	0207f793          	andi	a5,a5,32
    8000098c:	dfe5                	beqz	a5,80000984 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000098e:	0ff4f513          	zext.b	a0,s1
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    8000099a:	00007797          	auipc	a5,0x7
    8000099e:	eca7a783          	lw	a5,-310(a5) # 80007864 <panicking>
    800009a2:	cb91                	beqz	a5,800009b6 <uartputc_sync+0x58>
    pop_off();
}
    800009a4:	60e2                	ld	ra,24(sp)
    800009a6:	6442                	ld	s0,16(sp)
    800009a8:	64a2                	ld	s1,8(sp)
    800009aa:	6105                	addi	sp,sp,32
    800009ac:	8082                	ret
    push_off();
    800009ae:	212000ef          	jal	80000bc0 <push_off>
    800009b2:	b7c9                	j	80000974 <uartputc_sync+0x16>
    for(;;)
    800009b4:	a001                	j	800009b4 <uartputc_sync+0x56>
    pop_off();
    800009b6:	28e000ef          	jal	80000c44 <pop_off>
}
    800009ba:	b7ed                	j	800009a4 <uartputc_sync+0x46>

00000000800009bc <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009bc:	1141                	addi	sp,sp,-16
    800009be:	e422                	sd	s0,8(sp)
    800009c0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    800009c2:	100007b7          	lui	a5,0x10000
    800009c6:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009c8:	0007c783          	lbu	a5,0(a5)
    800009cc:	8b85                	andi	a5,a5,1
    800009ce:	cb81                	beqz	a5,800009de <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009d8:	6422                	ld	s0,8(sp)
    800009da:	0141                	addi	sp,sp,16
    800009dc:	8082                	ret
    return -1;
    800009de:	557d                	li	a0,-1
    800009e0:	bfe5                	j	800009d8 <uartgetc+0x1c>

00000000800009e2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009f2:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009f6:	0000f517          	auipc	a0,0xf
    800009fa:	f9a50513          	addi	a0,a0,-102 # 8000f990 <tx_lock>
    800009fe:	202000ef          	jal	80000c00 <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    80000a02:	100007b7          	lui	a5,0x10000
    80000a06:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000a08:	0007c783          	lbu	a5,0(a5)
    80000a0c:	0207f793          	andi	a5,a5,32
    80000a10:	eb89                	bnez	a5,80000a22 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    80000a12:	0000f517          	auipc	a0,0xf
    80000a16:	f7e50513          	addi	a0,a0,-130 # 8000f990 <tx_lock>
    80000a1a:	27e000ef          	jal	80000c98 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a1e:	54fd                	li	s1,-1
    80000a20:	a831                	j	80000a3c <uartintr+0x5a>
    tx_busy = 0;
    80000a22:	00007797          	auipc	a5,0x7
    80000a26:	e407a523          	sw	zero,-438(a5) # 8000786c <tx_busy>
    wakeup(&tx_chan);
    80000a2a:	00007517          	auipc	a0,0x7
    80000a2e:	e3e50513          	addi	a0,a0,-450 # 80007868 <tx_chan>
    80000a32:	52e010ef          	jal	80001f60 <wakeup>
    80000a36:	bff1                	j	80000a12 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a38:	891ff0ef          	jal	800002c8 <consoleintr>
    int c = uartgetc();
    80000a3c:	f81ff0ef          	jal	800009bc <uartgetc>
    if(c == -1)
    80000a40:	fe951ce3          	bne	a0,s1,80000a38 <uartintr+0x56>
  }
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret

0000000080000a4e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4e:	1101                	addi	sp,sp,-32
    80000a50:	ec06                	sd	ra,24(sp)
    80000a52:	e822                	sd	s0,16(sp)
    80000a54:	e426                	sd	s1,8(sp)
    80000a56:	e04a                	sd	s2,0(sp)
    80000a58:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a5a:	03451793          	slli	a5,a0,0x34
    80000a5e:	e7a9                	bnez	a5,80000aa8 <kfree+0x5a>
    80000a60:	84aa                	mv	s1,a0
    80000a62:	00028797          	auipc	a5,0x28
    80000a66:	1a678793          	addi	a5,a5,422 # 80028c08 <end>
    80000a6a:	02f56f63          	bltu	a0,a5,80000aa8 <kfree+0x5a>
    80000a6e:	47c5                	li	a5,17
    80000a70:	07ee                	slli	a5,a5,0x1b
    80000a72:	02f57b63          	bgeu	a0,a5,80000aa8 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a76:	6605                	lui	a2,0x1
    80000a78:	4585                	li	a1,1
    80000a7a:	25a000ef          	jal	80000cd4 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	0000f917          	auipc	s2,0xf
    80000a82:	f2a90913          	addi	s2,s2,-214 # 8000f9a8 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	178000ef          	jal	80000c00 <acquire>
  r->next = kmem.freelist;
    80000a8c:	01893783          	ld	a5,24(s2)
    80000a90:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a92:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a96:	854a                	mv	a0,s2
    80000a98:	200000ef          	jal	80000c98 <release>
}
    80000a9c:	60e2                	ld	ra,24(sp)
    80000a9e:	6442                	ld	s0,16(sp)
    80000aa0:	64a2                	ld	s1,8(sp)
    80000aa2:	6902                	ld	s2,0(sp)
    80000aa4:	6105                	addi	sp,sp,32
    80000aa6:	8082                	ret
    panic("kfree");
    80000aa8:	00006517          	auipc	a0,0x6
    80000aac:	59850513          	addi	a0,a0,1432 # 80007040 <etext+0x40>
    80000ab0:	d63ff0ef          	jal	80000812 <panic>

0000000080000ab4 <freerange>:
{
    80000ab4:	7179                	addi	sp,sp,-48
    80000ab6:	f406                	sd	ra,40(sp)
    80000ab8:	f022                	sd	s0,32(sp)
    80000aba:	ec26                	sd	s1,24(sp)
    80000abc:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000abe:	6785                	lui	a5,0x1
    80000ac0:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ac4:	00e504b3          	add	s1,a0,a4
    80000ac8:	777d                	lui	a4,0xfffff
    80000aca:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000acc:	94be                	add	s1,s1,a5
    80000ace:	0295e263          	bltu	a1,s1,80000af2 <freerange+0x3e>
    80000ad2:	e84a                	sd	s2,16(sp)
    80000ad4:	e44e                	sd	s3,8(sp)
    80000ad6:	e052                	sd	s4,0(sp)
    80000ad8:	892e                	mv	s2,a1
    kfree(p);
    80000ada:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000adc:	6985                	lui	s3,0x1
    kfree(p);
    80000ade:	01448533          	add	a0,s1,s4
    80000ae2:	f6dff0ef          	jal	80000a4e <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae6:	94ce                	add	s1,s1,s3
    80000ae8:	fe997be3          	bgeu	s2,s1,80000ade <freerange+0x2a>
    80000aec:	6942                	ld	s2,16(sp)
    80000aee:	69a2                	ld	s3,8(sp)
    80000af0:	6a02                	ld	s4,0(sp)
}
    80000af2:	70a2                	ld	ra,40(sp)
    80000af4:	7402                	ld	s0,32(sp)
    80000af6:	64e2                	ld	s1,24(sp)
    80000af8:	6145                	addi	sp,sp,48
    80000afa:	8082                	ret

0000000080000afc <kinit>:
{
    80000afc:	1141                	addi	sp,sp,-16
    80000afe:	e406                	sd	ra,8(sp)
    80000b00:	e022                	sd	s0,0(sp)
    80000b02:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b04:	00006597          	auipc	a1,0x6
    80000b08:	54458593          	addi	a1,a1,1348 # 80007048 <etext+0x48>
    80000b0c:	0000f517          	auipc	a0,0xf
    80000b10:	e9c50513          	addi	a0,a0,-356 # 8000f9a8 <kmem>
    80000b14:	06c000ef          	jal	80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b18:	45c5                	li	a1,17
    80000b1a:	05ee                	slli	a1,a1,0x1b
    80000b1c:	00028517          	auipc	a0,0x28
    80000b20:	0ec50513          	addi	a0,a0,236 # 80028c08 <end>
    80000b24:	f91ff0ef          	jal	80000ab4 <freerange>
}
    80000b28:	60a2                	ld	ra,8(sp)
    80000b2a:	6402                	ld	s0,0(sp)
    80000b2c:	0141                	addi	sp,sp,16
    80000b2e:	8082                	ret

0000000080000b30 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b30:	1101                	addi	sp,sp,-32
    80000b32:	ec06                	sd	ra,24(sp)
    80000b34:	e822                	sd	s0,16(sp)
    80000b36:	e426                	sd	s1,8(sp)
    80000b38:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b3a:	0000f497          	auipc	s1,0xf
    80000b3e:	e6e48493          	addi	s1,s1,-402 # 8000f9a8 <kmem>
    80000b42:	8526                	mv	a0,s1
    80000b44:	0bc000ef          	jal	80000c00 <acquire>
  r = kmem.freelist;
    80000b48:	6c84                	ld	s1,24(s1)
  if(r)
    80000b4a:	c485                	beqz	s1,80000b72 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b4c:	609c                	ld	a5,0(s1)
    80000b4e:	0000f517          	auipc	a0,0xf
    80000b52:	e5a50513          	addi	a0,a0,-422 # 8000f9a8 <kmem>
    80000b56:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b58:	140000ef          	jal	80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b5c:	6605                	lui	a2,0x1
    80000b5e:	4595                	li	a1,5
    80000b60:	8526                	mv	a0,s1
    80000b62:	172000ef          	jal	80000cd4 <memset>
  return (void*)r;
}
    80000b66:	8526                	mv	a0,s1
    80000b68:	60e2                	ld	ra,24(sp)
    80000b6a:	6442                	ld	s0,16(sp)
    80000b6c:	64a2                	ld	s1,8(sp)
    80000b6e:	6105                	addi	sp,sp,32
    80000b70:	8082                	ret
  release(&kmem.lock);
    80000b72:	0000f517          	auipc	a0,0xf
    80000b76:	e3650513          	addi	a0,a0,-458 # 8000f9a8 <kmem>
    80000b7a:	11e000ef          	jal	80000c98 <release>
  if(r)
    80000b7e:	b7e5                	j	80000b66 <kalloc+0x36>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	53f000ef          	jal	800018e8 <mycpu>
    80000bae:	40a48533          	sub	a0,s1,a0
    80000bb2:	00153513          	seqz	a0,a0
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret

0000000080000bc0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc0:	1101                	addi	sp,sp,-32
    80000bc2:	ec06                	sd	ra,24(sp)
    80000bc4:	e822                	sd	s0,16(sp)
    80000bc6:	e426                	sd	s1,8(sp)
    80000bc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bca:	100024f3          	csrr	s1,sstatus
    80000bce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd4:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000bd8:	511000ef          	jal	800018e8 <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	cb99                	beqz	a5,80000bf4 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be0:	509000ef          	jal	800018e8 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	2785                	addiw	a5,a5,1
    80000be8:	dd3c                	sw	a5,120(a0)
}
    80000bea:	60e2                	ld	ra,24(sp)
    80000bec:	6442                	ld	s0,16(sp)
    80000bee:	64a2                	ld	s1,8(sp)
    80000bf0:	6105                	addi	sp,sp,32
    80000bf2:	8082                	ret
    mycpu()->intena = old;
    80000bf4:	4f5000ef          	jal	800018e8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf8:	8085                	srli	s1,s1,0x1
    80000bfa:	8885                	andi	s1,s1,1
    80000bfc:	dd64                	sw	s1,124(a0)
    80000bfe:	b7cd                	j	80000be0 <push_off+0x20>

0000000080000c00 <acquire>:
{
    80000c00:	1101                	addi	sp,sp,-32
    80000c02:	ec06                	sd	ra,24(sp)
    80000c04:	e822                	sd	s0,16(sp)
    80000c06:	e426                	sd	s1,8(sp)
    80000c08:	1000                	addi	s0,sp,32
    80000c0a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0c:	fb5ff0ef          	jal	80000bc0 <push_off>
  if(holding(lk))
    80000c10:	8526                	mv	a0,s1
    80000c12:	f85ff0ef          	jal	80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c16:	4705                	li	a4,1
  if(holding(lk))
    80000c18:	e105                	bnez	a0,80000c38 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	87ba                	mv	a5,a4
    80000c1c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c20:	2781                	sext.w	a5,a5
    80000c22:	ffe5                	bnez	a5,80000c1a <acquire+0x1a>
  __sync_synchronize();
    80000c24:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c28:	4c1000ef          	jal	800018e8 <mycpu>
    80000c2c:	e888                	sd	a0,16(s1)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    panic("acquire");
    80000c38:	00006517          	auipc	a0,0x6
    80000c3c:	41850513          	addi	a0,a0,1048 # 80007050 <etext+0x50>
    80000c40:	bd3ff0ef          	jal	80000812 <panic>

0000000080000c44 <pop_off>:

void
pop_off(void)
{
    80000c44:	1141                	addi	sp,sp,-16
    80000c46:	e406                	sd	ra,8(sp)
    80000c48:	e022                	sd	s0,0(sp)
    80000c4a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c4c:	49d000ef          	jal	800018e8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c50:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c54:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c56:	e78d                	bnez	a5,80000c80 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c58:	5d3c                	lw	a5,120(a0)
    80000c5a:	02f05963          	blez	a5,80000c8c <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c5e:	37fd                	addiw	a5,a5,-1
    80000c60:	0007871b          	sext.w	a4,a5
    80000c64:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c66:	eb09                	bnez	a4,80000c78 <pop_off+0x34>
    80000c68:	5d7c                	lw	a5,124(a0)
    80000c6a:	c799                	beqz	a5,80000c78 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c70:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c74:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c78:	60a2                	ld	ra,8(sp)
    80000c7a:	6402                	ld	s0,0(sp)
    80000c7c:	0141                	addi	sp,sp,16
    80000c7e:	8082                	ret
    panic("pop_off - interruptible");
    80000c80:	00006517          	auipc	a0,0x6
    80000c84:	3d850513          	addi	a0,a0,984 # 80007058 <etext+0x58>
    80000c88:	b8bff0ef          	jal	80000812 <panic>
    panic("pop_off");
    80000c8c:	00006517          	auipc	a0,0x6
    80000c90:	3e450513          	addi	a0,a0,996 # 80007070 <etext+0x70>
    80000c94:	b7fff0ef          	jal	80000812 <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	ef3ff0ef          	jal	80000b96 <holding>
    80000ca8:	c105                	beqz	a0,80000cc8 <release+0x30>
  lk->cpu = 0;
    80000caa:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cae:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb2:	0f50000f          	fence	iorw,ow
    80000cb6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cba:	f8bff0ef          	jal	80000c44 <pop_off>
}
    80000cbe:	60e2                	ld	ra,24(sp)
    80000cc0:	6442                	ld	s0,16(sp)
    80000cc2:	64a2                	ld	s1,8(sp)
    80000cc4:	6105                	addi	sp,sp,32
    80000cc6:	8082                	ret
    panic("release");
    80000cc8:	00006517          	auipc	a0,0x6
    80000ccc:	3b050513          	addi	a0,a0,944 # 80007078 <etext+0x78>
    80000cd0:	b43ff0ef          	jal	80000812 <panic>

0000000080000cd4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd4:	1141                	addi	sp,sp,-16
    80000cd6:	e422                	sd	s0,8(sp)
    80000cd8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cda:	ca19                	beqz	a2,80000cf0 <memset+0x1c>
    80000cdc:	87aa                	mv	a5,a0
    80000cde:	1602                	slli	a2,a2,0x20
    80000ce0:	9201                	srli	a2,a2,0x20
    80000ce2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cea:	0785                	addi	a5,a5,1
    80000cec:	fee79de3          	bne	a5,a4,80000ce6 <memset+0x12>
  }
  return dst;
}
    80000cf0:	6422                	ld	s0,8(sp)
    80000cf2:	0141                	addi	sp,sp,16
    80000cf4:	8082                	ret

0000000080000cf6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf6:	1141                	addi	sp,sp,-16
    80000cf8:	e422                	sd	s0,8(sp)
    80000cfa:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfc:	ca05                	beqz	a2,80000d2c <memcmp+0x36>
    80000cfe:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d02:	1682                	slli	a3,a3,0x20
    80000d04:	9281                	srli	a3,a3,0x20
    80000d06:	0685                	addi	a3,a3,1
    80000d08:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0a:	00054783          	lbu	a5,0(a0)
    80000d0e:	0005c703          	lbu	a4,0(a1)
    80000d12:	00e79863          	bne	a5,a4,80000d22 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d16:	0505                	addi	a0,a0,1
    80000d18:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1a:	fed518e3          	bne	a0,a3,80000d0a <memcmp+0x14>
  }

  return 0;
    80000d1e:	4501                	li	a0,0
    80000d20:	a019                	j	80000d26 <memcmp+0x30>
      return *s1 - *s2;
    80000d22:	40e7853b          	subw	a0,a5,a4
}
    80000d26:	6422                	ld	s0,8(sp)
    80000d28:	0141                	addi	sp,sp,16
    80000d2a:	8082                	ret
  return 0;
    80000d2c:	4501                	li	a0,0
    80000d2e:	bfe5                	j	80000d26 <memcmp+0x30>

0000000080000d30 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d30:	1141                	addi	sp,sp,-16
    80000d32:	e422                	sd	s0,8(sp)
    80000d34:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d36:	c205                	beqz	a2,80000d56 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	02a5e263          	bltu	a1,a0,80000d5c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3c:	1602                	slli	a2,a2,0x20
    80000d3e:	9201                	srli	a2,a2,0x20
    80000d40:	00c587b3          	add	a5,a1,a2
{
    80000d44:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d46:	0585                	addi	a1,a1,1
    80000d48:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd63f9>
    80000d4a:	fff5c683          	lbu	a3,-1(a1)
    80000d4e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d52:	feb79ae3          	bne	a5,a1,80000d46 <memmove+0x16>

  return dst;
}
    80000d56:	6422                	ld	s0,8(sp)
    80000d58:	0141                	addi	sp,sp,16
    80000d5a:	8082                	ret
  if(s < d && s + n > d){
    80000d5c:	02061693          	slli	a3,a2,0x20
    80000d60:	9281                	srli	a3,a3,0x20
    80000d62:	00d58733          	add	a4,a1,a3
    80000d66:	fce57be3          	bgeu	a0,a4,80000d3c <memmove+0xc>
    d += n;
    80000d6a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6c:	fff6079b          	addiw	a5,a2,-1
    80000d70:	1782                	slli	a5,a5,0x20
    80000d72:	9381                	srli	a5,a5,0x20
    80000d74:	fff7c793          	not	a5,a5
    80000d78:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d7a:	177d                	addi	a4,a4,-1
    80000d7c:	16fd                	addi	a3,a3,-1
    80000d7e:	00074603          	lbu	a2,0(a4)
    80000d82:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d86:	fef71ae3          	bne	a4,a5,80000d7a <memmove+0x4a>
    80000d8a:	b7f1                	j	80000d56 <memmove+0x26>

0000000080000d8c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8c:	1141                	addi	sp,sp,-16
    80000d8e:	e406                	sd	ra,8(sp)
    80000d90:	e022                	sd	s0,0(sp)
    80000d92:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d94:	f9dff0ef          	jal	80000d30 <memmove>
}
    80000d98:	60a2                	ld	ra,8(sp)
    80000d9a:	6402                	ld	s0,0(sp)
    80000d9c:	0141                	addi	sp,sp,16
    80000d9e:	8082                	ret

0000000080000da0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da6:	ce11                	beqz	a2,80000dc2 <strncmp+0x22>
    80000da8:	00054783          	lbu	a5,0(a0)
    80000dac:	cf89                	beqz	a5,80000dc6 <strncmp+0x26>
    80000dae:	0005c703          	lbu	a4,0(a1)
    80000db2:	00f71a63          	bne	a4,a5,80000dc6 <strncmp+0x26>
    n--, p++, q++;
    80000db6:	367d                	addiw	a2,a2,-1
    80000db8:	0505                	addi	a0,a0,1
    80000dba:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbc:	f675                	bnez	a2,80000da8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dbe:	4501                	li	a0,0
    80000dc0:	a801                	j	80000dd0 <strncmp+0x30>
    80000dc2:	4501                	li	a0,0
    80000dc4:	a031                	j	80000dd0 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000dc6:	00054503          	lbu	a0,0(a0)
    80000dca:	0005c783          	lbu	a5,0(a1)
    80000dce:	9d1d                	subw	a0,a0,a5
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret

0000000080000dd6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd6:	1141                	addi	sp,sp,-16
    80000dd8:	e422                	sd	s0,8(sp)
    80000dda:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ddc:	87aa                	mv	a5,a0
    80000dde:	86b2                	mv	a3,a2
    80000de0:	367d                	addiw	a2,a2,-1
    80000de2:	02d05563          	blez	a3,80000e0c <strncpy+0x36>
    80000de6:	0785                	addi	a5,a5,1
    80000de8:	0005c703          	lbu	a4,0(a1)
    80000dec:	fee78fa3          	sb	a4,-1(a5)
    80000df0:	0585                	addi	a1,a1,1
    80000df2:	f775                	bnez	a4,80000dde <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df4:	873e                	mv	a4,a5
    80000df6:	9fb5                	addw	a5,a5,a3
    80000df8:	37fd                	addiw	a5,a5,-1
    80000dfa:	00c05963          	blez	a2,80000e0c <strncpy+0x36>
    *s++ = 0;
    80000dfe:	0705                	addi	a4,a4,1
    80000e00:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e04:	40e786bb          	subw	a3,a5,a4
    80000e08:	fed04be3          	bgtz	a3,80000dfe <strncpy+0x28>
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e18:	02c05363          	blez	a2,80000e3e <safestrcpy+0x2c>
    80000e1c:	fff6069b          	addiw	a3,a2,-1
    80000e20:	1682                	slli	a3,a3,0x20
    80000e22:	9281                	srli	a3,a3,0x20
    80000e24:	96ae                	add	a3,a3,a1
    80000e26:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e28:	00d58963          	beq	a1,a3,80000e3a <safestrcpy+0x28>
    80000e2c:	0585                	addi	a1,a1,1
    80000e2e:	0785                	addi	a5,a5,1
    80000e30:	fff5c703          	lbu	a4,-1(a1)
    80000e34:	fee78fa3          	sb	a4,-1(a5)
    80000e38:	fb65                	bnez	a4,80000e28 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e3a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3e:	6422                	ld	s0,8(sp)
    80000e40:	0141                	addi	sp,sp,16
    80000e42:	8082                	ret

0000000080000e44 <strlen>:

int
strlen(const char *s)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e422                	sd	s0,8(sp)
    80000e48:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e4a:	00054783          	lbu	a5,0(a0)
    80000e4e:	cf91                	beqz	a5,80000e6a <strlen+0x26>
    80000e50:	0505                	addi	a0,a0,1
    80000e52:	87aa                	mv	a5,a0
    80000e54:	86be                	mv	a3,a5
    80000e56:	0785                	addi	a5,a5,1
    80000e58:	fff7c703          	lbu	a4,-1(a5)
    80000e5c:	ff65                	bnez	a4,80000e54 <strlen+0x10>
    80000e5e:	40a6853b          	subw	a0,a3,a0
    80000e62:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e6a:	4501                	li	a0,0
    80000e6c:	bfe5                	j	80000e64 <strlen+0x20>

0000000080000e6e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6e:	1141                	addi	sp,sp,-16
    80000e70:	e406                	sd	ra,8(sp)
    80000e72:	e022                	sd	s0,0(sp)
    80000e74:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e76:	263000ef          	jal	800018d8 <cpuid>
    cslog_init();
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7a:	00007717          	auipc	a4,0x7
    80000e7e:	9f670713          	addi	a4,a4,-1546 # 80007870 <started>
  if(cpuid() == 0){
    80000e82:	c51d                	beqz	a0,80000eb0 <main+0x42>
    while(started == 0)
    80000e84:	431c                	lw	a5,0(a4)
    80000e86:	2781                	sext.w	a5,a5
    80000e88:	dff5                	beqz	a5,80000e84 <main+0x16>
      ;
    __sync_synchronize();
    80000e8a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e8e:	24b000ef          	jal	800018d8 <cpuid>
    80000e92:	85aa                	mv	a1,a0
    80000e94:	00006517          	auipc	a0,0x6
    80000e98:	20c50513          	addi	a0,a0,524 # 800070a0 <etext+0xa0>
    80000e9c:	e90ff0ef          	jal	8000052c <printf>
    kvminithart();    // turn on paging
    80000ea0:	084000ef          	jal	80000f24 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ea4:	592010ef          	jal	80002436 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ea8:	560040ef          	jal	80005408 <plicinithart>
  }

  scheduler();        
    80000eac:	6cb000ef          	jal	80001d76 <scheduler>
    consoleinit();
    80000eb0:	d92ff0ef          	jal	80000442 <consoleinit>
    printfinit();
    80000eb4:	99bff0ef          	jal	8000084e <printfinit>
    printf("\n");
    80000eb8:	00006517          	auipc	a0,0x6
    80000ebc:	1c850513          	addi	a0,a0,456 # 80007080 <etext+0x80>
    80000ec0:	e6cff0ef          	jal	8000052c <printf>
    printf("xv6 kernel is booting\n");
    80000ec4:	00006517          	auipc	a0,0x6
    80000ec8:	1c450513          	addi	a0,a0,452 # 80007088 <etext+0x88>
    80000ecc:	e60ff0ef          	jal	8000052c <printf>
    printf("\n");
    80000ed0:	00006517          	auipc	a0,0x6
    80000ed4:	1b050513          	addi	a0,a0,432 # 80007080 <etext+0x80>
    80000ed8:	e54ff0ef          	jal	8000052c <printf>
    kinit();         // physical page allocator
    80000edc:	c21ff0ef          	jal	80000afc <kinit>
    kvminit();       // create kernel page table
    80000ee0:	2ce000ef          	jal	800011ae <kvminit>
    kvminithart();   // turn on paging
    80000ee4:	040000ef          	jal	80000f24 <kvminithart>
    procinit();      // process table
    80000ee8:	13b000ef          	jal	80001822 <procinit>
    trapinit();      // trap vectors
    80000eec:	526010ef          	jal	80002412 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ef0:	546010ef          	jal	80002436 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ef4:	4fa040ef          	jal	800053ee <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ef8:	510040ef          	jal	80005408 <plicinithart>
    binit();         // buffer cache
    80000efc:	3d1010ef          	jal	80002acc <binit>
    iinit();         // inode table
    80000f00:	156020ef          	jal	80003056 <iinit>
    fileinit();      // file table
    80000f04:	048030ef          	jal	80003f4c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f08:	5f0040ef          	jal	800054f8 <virtio_disk_init>
    cslog_init();
    80000f0c:	29f040ef          	jal	800059aa <cslog_init>
    userinit();      // first user process
    80000f10:	4bb000ef          	jal	80001bca <userinit>
    __sync_synchronize();
    80000f14:	0ff0000f          	fence
    started = 1;
    80000f18:	4785                	li	a5,1
    80000f1a:	00007717          	auipc	a4,0x7
    80000f1e:	94f72b23          	sw	a5,-1706(a4) # 80007870 <started>
    80000f22:	b769                	j	80000eac <main+0x3e>

0000000080000f24 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f24:	1141                	addi	sp,sp,-16
    80000f26:	e422                	sd	s0,8(sp)
    80000f28:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f2a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f2e:	00007797          	auipc	a5,0x7
    80000f32:	94a7b783          	ld	a5,-1718(a5) # 80007878 <kernel_pagetable>
    80000f36:	83b1                	srli	a5,a5,0xc
    80000f38:	577d                	li	a4,-1
    80000f3a:	177e                	slli	a4,a4,0x3f
    80000f3c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f3e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f42:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f46:	6422                	ld	s0,8(sp)
    80000f48:	0141                	addi	sp,sp,16
    80000f4a:	8082                	ret

0000000080000f4c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f4c:	7139                	addi	sp,sp,-64
    80000f4e:	fc06                	sd	ra,56(sp)
    80000f50:	f822                	sd	s0,48(sp)
    80000f52:	f426                	sd	s1,40(sp)
    80000f54:	f04a                	sd	s2,32(sp)
    80000f56:	ec4e                	sd	s3,24(sp)
    80000f58:	e852                	sd	s4,16(sp)
    80000f5a:	e456                	sd	s5,8(sp)
    80000f5c:	e05a                	sd	s6,0(sp)
    80000f5e:	0080                	addi	s0,sp,64
    80000f60:	84aa                	mv	s1,a0
    80000f62:	89ae                	mv	s3,a1
    80000f64:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f66:	57fd                	li	a5,-1
    80000f68:	83e9                	srli	a5,a5,0x1a
    80000f6a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f6c:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f6e:	02b7fc63          	bgeu	a5,a1,80000fa6 <walk+0x5a>
    panic("walk");
    80000f72:	00006517          	auipc	a0,0x6
    80000f76:	14650513          	addi	a0,a0,326 # 800070b8 <etext+0xb8>
    80000f7a:	899ff0ef          	jal	80000812 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f7e:	060a8263          	beqz	s5,80000fe2 <walk+0x96>
    80000f82:	bafff0ef          	jal	80000b30 <kalloc>
    80000f86:	84aa                	mv	s1,a0
    80000f88:	c139                	beqz	a0,80000fce <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f8a:	6605                	lui	a2,0x1
    80000f8c:	4581                	li	a1,0
    80000f8e:	d47ff0ef          	jal	80000cd4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f92:	00c4d793          	srli	a5,s1,0xc
    80000f96:	07aa                	slli	a5,a5,0xa
    80000f98:	0017e793          	ori	a5,a5,1
    80000f9c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000fa0:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd63ef>
    80000fa2:	036a0063          	beq	s4,s6,80000fc2 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000fa6:	0149d933          	srl	s2,s3,s4
    80000faa:	1ff97913          	andi	s2,s2,511
    80000fae:	090e                	slli	s2,s2,0x3
    80000fb0:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000fb2:	00093483          	ld	s1,0(s2)
    80000fb6:	0014f793          	andi	a5,s1,1
    80000fba:	d3f1                	beqz	a5,80000f7e <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000fbc:	80a9                	srli	s1,s1,0xa
    80000fbe:	04b2                	slli	s1,s1,0xc
    80000fc0:	b7c5                	j	80000fa0 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000fc2:	00c9d513          	srli	a0,s3,0xc
    80000fc6:	1ff57513          	andi	a0,a0,511
    80000fca:	050e                	slli	a0,a0,0x3
    80000fcc:	9526                	add	a0,a0,s1
}
    80000fce:	70e2                	ld	ra,56(sp)
    80000fd0:	7442                	ld	s0,48(sp)
    80000fd2:	74a2                	ld	s1,40(sp)
    80000fd4:	7902                	ld	s2,32(sp)
    80000fd6:	69e2                	ld	s3,24(sp)
    80000fd8:	6a42                	ld	s4,16(sp)
    80000fda:	6aa2                	ld	s5,8(sp)
    80000fdc:	6b02                	ld	s6,0(sp)
    80000fde:	6121                	addi	sp,sp,64
    80000fe0:	8082                	ret
        return 0;
    80000fe2:	4501                	li	a0,0
    80000fe4:	b7ed                	j	80000fce <walk+0x82>

0000000080000fe6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fe6:	57fd                	li	a5,-1
    80000fe8:	83e9                	srli	a5,a5,0x1a
    80000fea:	00b7f463          	bgeu	a5,a1,80000ff2 <walkaddr+0xc>
    return 0;
    80000fee:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000ff0:	8082                	ret
{
    80000ff2:	1141                	addi	sp,sp,-16
    80000ff4:	e406                	sd	ra,8(sp)
    80000ff6:	e022                	sd	s0,0(sp)
    80000ff8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000ffa:	4601                	li	a2,0
    80000ffc:	f51ff0ef          	jal	80000f4c <walk>
  if(pte == 0)
    80001000:	c105                	beqz	a0,80001020 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80001002:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001004:	0117f693          	andi	a3,a5,17
    80001008:	4745                	li	a4,17
    return 0;
    8000100a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000100c:	00e68663          	beq	a3,a4,80001018 <walkaddr+0x32>
}
    80001010:	60a2                	ld	ra,8(sp)
    80001012:	6402                	ld	s0,0(sp)
    80001014:	0141                	addi	sp,sp,16
    80001016:	8082                	ret
  pa = PTE2PA(*pte);
    80001018:	83a9                	srli	a5,a5,0xa
    8000101a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000101e:	bfcd                	j	80001010 <walkaddr+0x2a>
    return 0;
    80001020:	4501                	li	a0,0
    80001022:	b7fd                	j	80001010 <walkaddr+0x2a>

0000000080001024 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001024:	715d                	addi	sp,sp,-80
    80001026:	e486                	sd	ra,72(sp)
    80001028:	e0a2                	sd	s0,64(sp)
    8000102a:	fc26                	sd	s1,56(sp)
    8000102c:	f84a                	sd	s2,48(sp)
    8000102e:	f44e                	sd	s3,40(sp)
    80001030:	f052                	sd	s4,32(sp)
    80001032:	ec56                	sd	s5,24(sp)
    80001034:	e85a                	sd	s6,16(sp)
    80001036:	e45e                	sd	s7,8(sp)
    80001038:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000103a:	03459793          	slli	a5,a1,0x34
    8000103e:	e7a9                	bnez	a5,80001088 <mappages+0x64>
    80001040:	8aaa                	mv	s5,a0
    80001042:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001044:	03461793          	slli	a5,a2,0x34
    80001048:	e7b1                	bnez	a5,80001094 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    8000104a:	ca39                	beqz	a2,800010a0 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    8000104c:	77fd                	lui	a5,0xfffff
    8000104e:	963e                	add	a2,a2,a5
    80001050:	00b609b3          	add	s3,a2,a1
  a = va;
    80001054:	892e                	mv	s2,a1
    80001056:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000105a:	6b85                	lui	s7,0x1
    8000105c:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001060:	4605                	li	a2,1
    80001062:	85ca                	mv	a1,s2
    80001064:	8556                	mv	a0,s5
    80001066:	ee7ff0ef          	jal	80000f4c <walk>
    8000106a:	c539                	beqz	a0,800010b8 <mappages+0x94>
    if(*pte & PTE_V)
    8000106c:	611c                	ld	a5,0(a0)
    8000106e:	8b85                	andi	a5,a5,1
    80001070:	ef95                	bnez	a5,800010ac <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001072:	80b1                	srli	s1,s1,0xc
    80001074:	04aa                	slli	s1,s1,0xa
    80001076:	0164e4b3          	or	s1,s1,s6
    8000107a:	0014e493          	ori	s1,s1,1
    8000107e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001080:	05390863          	beq	s2,s3,800010d0 <mappages+0xac>
    a += PGSIZE;
    80001084:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001086:	bfd9                	j	8000105c <mappages+0x38>
    panic("mappages: va not aligned");
    80001088:	00006517          	auipc	a0,0x6
    8000108c:	03850513          	addi	a0,a0,56 # 800070c0 <etext+0xc0>
    80001090:	f82ff0ef          	jal	80000812 <panic>
    panic("mappages: size not aligned");
    80001094:	00006517          	auipc	a0,0x6
    80001098:	04c50513          	addi	a0,a0,76 # 800070e0 <etext+0xe0>
    8000109c:	f76ff0ef          	jal	80000812 <panic>
    panic("mappages: size");
    800010a0:	00006517          	auipc	a0,0x6
    800010a4:	06050513          	addi	a0,a0,96 # 80007100 <etext+0x100>
    800010a8:	f6aff0ef          	jal	80000812 <panic>
      panic("mappages: remap");
    800010ac:	00006517          	auipc	a0,0x6
    800010b0:	06450513          	addi	a0,a0,100 # 80007110 <etext+0x110>
    800010b4:	f5eff0ef          	jal	80000812 <panic>
      return -1;
    800010b8:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010ba:	60a6                	ld	ra,72(sp)
    800010bc:	6406                	ld	s0,64(sp)
    800010be:	74e2                	ld	s1,56(sp)
    800010c0:	7942                	ld	s2,48(sp)
    800010c2:	79a2                	ld	s3,40(sp)
    800010c4:	7a02                	ld	s4,32(sp)
    800010c6:	6ae2                	ld	s5,24(sp)
    800010c8:	6b42                	ld	s6,16(sp)
    800010ca:	6ba2                	ld	s7,8(sp)
    800010cc:	6161                	addi	sp,sp,80
    800010ce:	8082                	ret
  return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7e5                	j	800010ba <mappages+0x96>

00000000800010d4 <kvmmap>:
{
    800010d4:	1141                	addi	sp,sp,-16
    800010d6:	e406                	sd	ra,8(sp)
    800010d8:	e022                	sd	s0,0(sp)
    800010da:	0800                	addi	s0,sp,16
    800010dc:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010de:	86b2                	mv	a3,a2
    800010e0:	863e                	mv	a2,a5
    800010e2:	f43ff0ef          	jal	80001024 <mappages>
    800010e6:	e509                	bnez	a0,800010f0 <kvmmap+0x1c>
}
    800010e8:	60a2                	ld	ra,8(sp)
    800010ea:	6402                	ld	s0,0(sp)
    800010ec:	0141                	addi	sp,sp,16
    800010ee:	8082                	ret
    panic("kvmmap");
    800010f0:	00006517          	auipc	a0,0x6
    800010f4:	03050513          	addi	a0,a0,48 # 80007120 <etext+0x120>
    800010f8:	f1aff0ef          	jal	80000812 <panic>

00000000800010fc <kvmmake>:
{
    800010fc:	1101                	addi	sp,sp,-32
    800010fe:	ec06                	sd	ra,24(sp)
    80001100:	e822                	sd	s0,16(sp)
    80001102:	e426                	sd	s1,8(sp)
    80001104:	e04a                	sd	s2,0(sp)
    80001106:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001108:	a29ff0ef          	jal	80000b30 <kalloc>
    8000110c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000110e:	6605                	lui	a2,0x1
    80001110:	4581                	li	a1,0
    80001112:	bc3ff0ef          	jal	80000cd4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001116:	4719                	li	a4,6
    80001118:	6685                	lui	a3,0x1
    8000111a:	10000637          	lui	a2,0x10000
    8000111e:	100005b7          	lui	a1,0x10000
    80001122:	8526                	mv	a0,s1
    80001124:	fb1ff0ef          	jal	800010d4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001128:	4719                	li	a4,6
    8000112a:	6685                	lui	a3,0x1
    8000112c:	10001637          	lui	a2,0x10001
    80001130:	100015b7          	lui	a1,0x10001
    80001134:	8526                	mv	a0,s1
    80001136:	f9fff0ef          	jal	800010d4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    8000113a:	4719                	li	a4,6
    8000113c:	040006b7          	lui	a3,0x4000
    80001140:	0c000637          	lui	a2,0xc000
    80001144:	0c0005b7          	lui	a1,0xc000
    80001148:	8526                	mv	a0,s1
    8000114a:	f8bff0ef          	jal	800010d4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000114e:	00006917          	auipc	s2,0x6
    80001152:	eb290913          	addi	s2,s2,-334 # 80007000 <etext>
    80001156:	4729                	li	a4,10
    80001158:	80006697          	auipc	a3,0x80006
    8000115c:	ea868693          	addi	a3,a3,-344 # 7000 <_entry-0x7fff9000>
    80001160:	4605                	li	a2,1
    80001162:	067e                	slli	a2,a2,0x1f
    80001164:	85b2                	mv	a1,a2
    80001166:	8526                	mv	a0,s1
    80001168:	f6dff0ef          	jal	800010d4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000116c:	46c5                	li	a3,17
    8000116e:	06ee                	slli	a3,a3,0x1b
    80001170:	4719                	li	a4,6
    80001172:	412686b3          	sub	a3,a3,s2
    80001176:	864a                	mv	a2,s2
    80001178:	85ca                	mv	a1,s2
    8000117a:	8526                	mv	a0,s1
    8000117c:	f59ff0ef          	jal	800010d4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001180:	4729                	li	a4,10
    80001182:	6685                	lui	a3,0x1
    80001184:	00005617          	auipc	a2,0x5
    80001188:	e7c60613          	addi	a2,a2,-388 # 80006000 <_trampoline>
    8000118c:	040005b7          	lui	a1,0x4000
    80001190:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001192:	05b2                	slli	a1,a1,0xc
    80001194:	8526                	mv	a0,s1
    80001196:	f3fff0ef          	jal	800010d4 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000119a:	8526                	mv	a0,s1
    8000119c:	5ee000ef          	jal	8000178a <proc_mapstacks>
}
    800011a0:	8526                	mv	a0,s1
    800011a2:	60e2                	ld	ra,24(sp)
    800011a4:	6442                	ld	s0,16(sp)
    800011a6:	64a2                	ld	s1,8(sp)
    800011a8:	6902                	ld	s2,0(sp)
    800011aa:	6105                	addi	sp,sp,32
    800011ac:	8082                	ret

00000000800011ae <kvminit>:
{
    800011ae:	1141                	addi	sp,sp,-16
    800011b0:	e406                	sd	ra,8(sp)
    800011b2:	e022                	sd	s0,0(sp)
    800011b4:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800011b6:	f47ff0ef          	jal	800010fc <kvmmake>
    800011ba:	00006797          	auipc	a5,0x6
    800011be:	6aa7bf23          	sd	a0,1726(a5) # 80007878 <kernel_pagetable>
}
    800011c2:	60a2                	ld	ra,8(sp)
    800011c4:	6402                	ld	s0,0(sp)
    800011c6:	0141                	addi	sp,sp,16
    800011c8:	8082                	ret

00000000800011ca <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800011ca:	1101                	addi	sp,sp,-32
    800011cc:	ec06                	sd	ra,24(sp)
    800011ce:	e822                	sd	s0,16(sp)
    800011d0:	e426                	sd	s1,8(sp)
    800011d2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800011d4:	95dff0ef          	jal	80000b30 <kalloc>
    800011d8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011da:	c509                	beqz	a0,800011e4 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011dc:	6605                	lui	a2,0x1
    800011de:	4581                	li	a1,0
    800011e0:	af5ff0ef          	jal	80000cd4 <memset>
  return pagetable;
}
    800011e4:	8526                	mv	a0,s1
    800011e6:	60e2                	ld	ra,24(sp)
    800011e8:	6442                	ld	s0,16(sp)
    800011ea:	64a2                	ld	s1,8(sp)
    800011ec:	6105                	addi	sp,sp,32
    800011ee:	8082                	ret

00000000800011f0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011f0:	7139                	addi	sp,sp,-64
    800011f2:	fc06                	sd	ra,56(sp)
    800011f4:	f822                	sd	s0,48(sp)
    800011f6:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011f8:	03459793          	slli	a5,a1,0x34
    800011fc:	e38d                	bnez	a5,8000121e <uvmunmap+0x2e>
    800011fe:	f04a                	sd	s2,32(sp)
    80001200:	ec4e                	sd	s3,24(sp)
    80001202:	e852                	sd	s4,16(sp)
    80001204:	e456                	sd	s5,8(sp)
    80001206:	e05a                	sd	s6,0(sp)
    80001208:	8a2a                	mv	s4,a0
    8000120a:	892e                	mv	s2,a1
    8000120c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000120e:	0632                	slli	a2,a2,0xc
    80001210:	00b609b3          	add	s3,a2,a1
    80001214:	6b05                	lui	s6,0x1
    80001216:	0535f963          	bgeu	a1,s3,80001268 <uvmunmap+0x78>
    8000121a:	f426                	sd	s1,40(sp)
    8000121c:	a015                	j	80001240 <uvmunmap+0x50>
    8000121e:	f426                	sd	s1,40(sp)
    80001220:	f04a                	sd	s2,32(sp)
    80001222:	ec4e                	sd	s3,24(sp)
    80001224:	e852                	sd	s4,16(sp)
    80001226:	e456                	sd	s5,8(sp)
    80001228:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    8000122a:	00006517          	auipc	a0,0x6
    8000122e:	efe50513          	addi	a0,a0,-258 # 80007128 <etext+0x128>
    80001232:	de0ff0ef          	jal	80000812 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001236:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000123a:	995a                	add	s2,s2,s6
    8000123c:	03397563          	bgeu	s2,s3,80001266 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001240:	4601                	li	a2,0
    80001242:	85ca                	mv	a1,s2
    80001244:	8552                	mv	a0,s4
    80001246:	d07ff0ef          	jal	80000f4c <walk>
    8000124a:	84aa                	mv	s1,a0
    8000124c:	d57d                	beqz	a0,8000123a <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    8000124e:	611c                	ld	a5,0(a0)
    80001250:	0017f713          	andi	a4,a5,1
    80001254:	d37d                	beqz	a4,8000123a <uvmunmap+0x4a>
    if(do_free){
    80001256:	fe0a80e3          	beqz	s5,80001236 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    8000125a:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000125c:	00c79513          	slli	a0,a5,0xc
    80001260:	feeff0ef          	jal	80000a4e <kfree>
    80001264:	bfc9                	j	80001236 <uvmunmap+0x46>
    80001266:	74a2                	ld	s1,40(sp)
    80001268:	7902                	ld	s2,32(sp)
    8000126a:	69e2                	ld	s3,24(sp)
    8000126c:	6a42                	ld	s4,16(sp)
    8000126e:	6aa2                	ld	s5,8(sp)
    80001270:	6b02                	ld	s6,0(sp)
  }
}
    80001272:	70e2                	ld	ra,56(sp)
    80001274:	7442                	ld	s0,48(sp)
    80001276:	6121                	addi	sp,sp,64
    80001278:	8082                	ret

000000008000127a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000127a:	1101                	addi	sp,sp,-32
    8000127c:	ec06                	sd	ra,24(sp)
    8000127e:	e822                	sd	s0,16(sp)
    80001280:	e426                	sd	s1,8(sp)
    80001282:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001284:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001286:	00b67d63          	bgeu	a2,a1,800012a0 <uvmdealloc+0x26>
    8000128a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000128c:	6785                	lui	a5,0x1
    8000128e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001290:	00f60733          	add	a4,a2,a5
    80001294:	76fd                	lui	a3,0xfffff
    80001296:	8f75                	and	a4,a4,a3
    80001298:	97ae                	add	a5,a5,a1
    8000129a:	8ff5                	and	a5,a5,a3
    8000129c:	00f76863          	bltu	a4,a5,800012ac <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800012a0:	8526                	mv	a0,s1
    800012a2:	60e2                	ld	ra,24(sp)
    800012a4:	6442                	ld	s0,16(sp)
    800012a6:	64a2                	ld	s1,8(sp)
    800012a8:	6105                	addi	sp,sp,32
    800012aa:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800012ac:	8f99                	sub	a5,a5,a4
    800012ae:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800012b0:	4685                	li	a3,1
    800012b2:	0007861b          	sext.w	a2,a5
    800012b6:	85ba                	mv	a1,a4
    800012b8:	f39ff0ef          	jal	800011f0 <uvmunmap>
    800012bc:	b7d5                	j	800012a0 <uvmdealloc+0x26>

00000000800012be <uvmalloc>:
  if(newsz < oldsz)
    800012be:	08b66f63          	bltu	a2,a1,8000135c <uvmalloc+0x9e>
{
    800012c2:	7139                	addi	sp,sp,-64
    800012c4:	fc06                	sd	ra,56(sp)
    800012c6:	f822                	sd	s0,48(sp)
    800012c8:	ec4e                	sd	s3,24(sp)
    800012ca:	e852                	sd	s4,16(sp)
    800012cc:	e456                	sd	s5,8(sp)
    800012ce:	0080                	addi	s0,sp,64
    800012d0:	8aaa                	mv	s5,a0
    800012d2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800012d4:	6785                	lui	a5,0x1
    800012d6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012d8:	95be                	add	a1,a1,a5
    800012da:	77fd                	lui	a5,0xfffff
    800012dc:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012e0:	08c9f063          	bgeu	s3,a2,80001360 <uvmalloc+0xa2>
    800012e4:	f426                	sd	s1,40(sp)
    800012e6:	f04a                	sd	s2,32(sp)
    800012e8:	e05a                	sd	s6,0(sp)
    800012ea:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012ec:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012f0:	841ff0ef          	jal	80000b30 <kalloc>
    800012f4:	84aa                	mv	s1,a0
    if(mem == 0){
    800012f6:	c515                	beqz	a0,80001322 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012f8:	6605                	lui	a2,0x1
    800012fa:	4581                	li	a1,0
    800012fc:	9d9ff0ef          	jal	80000cd4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001300:	875a                	mv	a4,s6
    80001302:	86a6                	mv	a3,s1
    80001304:	6605                	lui	a2,0x1
    80001306:	85ca                	mv	a1,s2
    80001308:	8556                	mv	a0,s5
    8000130a:	d1bff0ef          	jal	80001024 <mappages>
    8000130e:	e915                	bnez	a0,80001342 <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001310:	6785                	lui	a5,0x1
    80001312:	993e                	add	s2,s2,a5
    80001314:	fd496ee3          	bltu	s2,s4,800012f0 <uvmalloc+0x32>
  return newsz;
    80001318:	8552                	mv	a0,s4
    8000131a:	74a2                	ld	s1,40(sp)
    8000131c:	7902                	ld	s2,32(sp)
    8000131e:	6b02                	ld	s6,0(sp)
    80001320:	a811                	j	80001334 <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    80001322:	864e                	mv	a2,s3
    80001324:	85ca                	mv	a1,s2
    80001326:	8556                	mv	a0,s5
    80001328:	f53ff0ef          	jal	8000127a <uvmdealloc>
      return 0;
    8000132c:	4501                	li	a0,0
    8000132e:	74a2                	ld	s1,40(sp)
    80001330:	7902                	ld	s2,32(sp)
    80001332:	6b02                	ld	s6,0(sp)
}
    80001334:	70e2                	ld	ra,56(sp)
    80001336:	7442                	ld	s0,48(sp)
    80001338:	69e2                	ld	s3,24(sp)
    8000133a:	6a42                	ld	s4,16(sp)
    8000133c:	6aa2                	ld	s5,8(sp)
    8000133e:	6121                	addi	sp,sp,64
    80001340:	8082                	ret
      kfree(mem);
    80001342:	8526                	mv	a0,s1
    80001344:	f0aff0ef          	jal	80000a4e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001348:	864e                	mv	a2,s3
    8000134a:	85ca                	mv	a1,s2
    8000134c:	8556                	mv	a0,s5
    8000134e:	f2dff0ef          	jal	8000127a <uvmdealloc>
      return 0;
    80001352:	4501                	li	a0,0
    80001354:	74a2                	ld	s1,40(sp)
    80001356:	7902                	ld	s2,32(sp)
    80001358:	6b02                	ld	s6,0(sp)
    8000135a:	bfe9                	j	80001334 <uvmalloc+0x76>
    return oldsz;
    8000135c:	852e                	mv	a0,a1
}
    8000135e:	8082                	ret
  return newsz;
    80001360:	8532                	mv	a0,a2
    80001362:	bfc9                	j	80001334 <uvmalloc+0x76>

0000000080001364 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001364:	7179                	addi	sp,sp,-48
    80001366:	f406                	sd	ra,40(sp)
    80001368:	f022                	sd	s0,32(sp)
    8000136a:	ec26                	sd	s1,24(sp)
    8000136c:	e84a                	sd	s2,16(sp)
    8000136e:	e44e                	sd	s3,8(sp)
    80001370:	e052                	sd	s4,0(sp)
    80001372:	1800                	addi	s0,sp,48
    80001374:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001376:	84aa                	mv	s1,a0
    80001378:	6905                	lui	s2,0x1
    8000137a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000137c:	4985                	li	s3,1
    8000137e:	a819                	j	80001394 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001380:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001382:	00c79513          	slli	a0,a5,0xc
    80001386:	fdfff0ef          	jal	80001364 <freewalk>
      pagetable[i] = 0;
    8000138a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000138e:	04a1                	addi	s1,s1,8
    80001390:	01248f63          	beq	s1,s2,800013ae <freewalk+0x4a>
    pte_t pte = pagetable[i];
    80001394:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001396:	00f7f713          	andi	a4,a5,15
    8000139a:	ff3703e3          	beq	a4,s3,80001380 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000139e:	8b85                	andi	a5,a5,1
    800013a0:	d7fd                	beqz	a5,8000138e <freewalk+0x2a>
      panic("freewalk: leaf");
    800013a2:	00006517          	auipc	a0,0x6
    800013a6:	d9e50513          	addi	a0,a0,-610 # 80007140 <etext+0x140>
    800013aa:	c68ff0ef          	jal	80000812 <panic>
    }
  }
  kfree((void*)pagetable);
    800013ae:	8552                	mv	a0,s4
    800013b0:	e9eff0ef          	jal	80000a4e <kfree>
}
    800013b4:	70a2                	ld	ra,40(sp)
    800013b6:	7402                	ld	s0,32(sp)
    800013b8:	64e2                	ld	s1,24(sp)
    800013ba:	6942                	ld	s2,16(sp)
    800013bc:	69a2                	ld	s3,8(sp)
    800013be:	6a02                	ld	s4,0(sp)
    800013c0:	6145                	addi	sp,sp,48
    800013c2:	8082                	ret

00000000800013c4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013c4:	1101                	addi	sp,sp,-32
    800013c6:	ec06                	sd	ra,24(sp)
    800013c8:	e822                	sd	s0,16(sp)
    800013ca:	e426                	sd	s1,8(sp)
    800013cc:	1000                	addi	s0,sp,32
    800013ce:	84aa                	mv	s1,a0
  if(sz > 0)
    800013d0:	e989                	bnez	a1,800013e2 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013d2:	8526                	mv	a0,s1
    800013d4:	f91ff0ef          	jal	80001364 <freewalk>
}
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013e2:	6785                	lui	a5,0x1
    800013e4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013e6:	95be                	add	a1,a1,a5
    800013e8:	4685                	li	a3,1
    800013ea:	00c5d613          	srli	a2,a1,0xc
    800013ee:	4581                	li	a1,0
    800013f0:	e01ff0ef          	jal	800011f0 <uvmunmap>
    800013f4:	bff9                	j	800013d2 <uvmfree+0xe>

00000000800013f6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013f6:	ce49                	beqz	a2,80001490 <uvmcopy+0x9a>
{
    800013f8:	715d                	addi	sp,sp,-80
    800013fa:	e486                	sd	ra,72(sp)
    800013fc:	e0a2                	sd	s0,64(sp)
    800013fe:	fc26                	sd	s1,56(sp)
    80001400:	f84a                	sd	s2,48(sp)
    80001402:	f44e                	sd	s3,40(sp)
    80001404:	f052                	sd	s4,32(sp)
    80001406:	ec56                	sd	s5,24(sp)
    80001408:	e85a                	sd	s6,16(sp)
    8000140a:	e45e                	sd	s7,8(sp)
    8000140c:	0880                	addi	s0,sp,80
    8000140e:	8aaa                	mv	s5,a0
    80001410:	8b2e                	mv	s6,a1
    80001412:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001414:	4481                	li	s1,0
    80001416:	a029                	j	80001420 <uvmcopy+0x2a>
    80001418:	6785                	lui	a5,0x1
    8000141a:	94be                	add	s1,s1,a5
    8000141c:	0544fe63          	bgeu	s1,s4,80001478 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    80001420:	4601                	li	a2,0
    80001422:	85a6                	mv	a1,s1
    80001424:	8556                	mv	a0,s5
    80001426:	b27ff0ef          	jal	80000f4c <walk>
    8000142a:	d57d                	beqz	a0,80001418 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    8000142c:	6118                	ld	a4,0(a0)
    8000142e:	00177793          	andi	a5,a4,1
    80001432:	d3fd                	beqz	a5,80001418 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001434:	00a75593          	srli	a1,a4,0xa
    80001438:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000143c:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001440:	ef0ff0ef          	jal	80000b30 <kalloc>
    80001444:	89aa                	mv	s3,a0
    80001446:	c105                	beqz	a0,80001466 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	85de                	mv	a1,s7
    8000144c:	8e5ff0ef          	jal	80000d30 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001450:	874a                	mv	a4,s2
    80001452:	86ce                	mv	a3,s3
    80001454:	6605                	lui	a2,0x1
    80001456:	85a6                	mv	a1,s1
    80001458:	855a                	mv	a0,s6
    8000145a:	bcbff0ef          	jal	80001024 <mappages>
    8000145e:	dd4d                	beqz	a0,80001418 <uvmcopy+0x22>
      kfree(mem);
    80001460:	854e                	mv	a0,s3
    80001462:	decff0ef          	jal	80000a4e <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001466:	4685                	li	a3,1
    80001468:	00c4d613          	srli	a2,s1,0xc
    8000146c:	4581                	li	a1,0
    8000146e:	855a                	mv	a0,s6
    80001470:	d81ff0ef          	jal	800011f0 <uvmunmap>
  return -1;
    80001474:	557d                	li	a0,-1
    80001476:	a011                	j	8000147a <uvmcopy+0x84>
  return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	60a6                	ld	ra,72(sp)
    8000147c:	6406                	ld	s0,64(sp)
    8000147e:	74e2                	ld	s1,56(sp)
    80001480:	7942                	ld	s2,48(sp)
    80001482:	79a2                	ld	s3,40(sp)
    80001484:	7a02                	ld	s4,32(sp)
    80001486:	6ae2                	ld	s5,24(sp)
    80001488:	6b42                	ld	s6,16(sp)
    8000148a:	6ba2                	ld	s7,8(sp)
    8000148c:	6161                	addi	sp,sp,80
    8000148e:	8082                	ret
  return 0;
    80001490:	4501                	li	a0,0
}
    80001492:	8082                	ret

0000000080001494 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001494:	1141                	addi	sp,sp,-16
    80001496:	e406                	sd	ra,8(sp)
    80001498:	e022                	sd	s0,0(sp)
    8000149a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000149c:	4601                	li	a2,0
    8000149e:	aafff0ef          	jal	80000f4c <walk>
  if(pte == 0)
    800014a2:	c901                	beqz	a0,800014b2 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014a4:	611c                	ld	a5,0(a0)
    800014a6:	9bbd                	andi	a5,a5,-17
    800014a8:	e11c                	sd	a5,0(a0)
}
    800014aa:	60a2                	ld	ra,8(sp)
    800014ac:	6402                	ld	s0,0(sp)
    800014ae:	0141                	addi	sp,sp,16
    800014b0:	8082                	ret
    panic("uvmclear");
    800014b2:	00006517          	auipc	a0,0x6
    800014b6:	c9e50513          	addi	a0,a0,-866 # 80007150 <etext+0x150>
    800014ba:	b58ff0ef          	jal	80000812 <panic>

00000000800014be <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800014be:	c6dd                	beqz	a3,8000156c <copyinstr+0xae>
{
    800014c0:	715d                	addi	sp,sp,-80
    800014c2:	e486                	sd	ra,72(sp)
    800014c4:	e0a2                	sd	s0,64(sp)
    800014c6:	fc26                	sd	s1,56(sp)
    800014c8:	f84a                	sd	s2,48(sp)
    800014ca:	f44e                	sd	s3,40(sp)
    800014cc:	f052                	sd	s4,32(sp)
    800014ce:	ec56                	sd	s5,24(sp)
    800014d0:	e85a                	sd	s6,16(sp)
    800014d2:	e45e                	sd	s7,8(sp)
    800014d4:	0880                	addi	s0,sp,80
    800014d6:	8a2a                	mv	s4,a0
    800014d8:	8b2e                	mv	s6,a1
    800014da:	8bb2                	mv	s7,a2
    800014dc:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014de:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014e0:	6985                	lui	s3,0x1
    800014e2:	a825                	j	8000151a <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014e4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014e8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014ea:	37fd                	addiw	a5,a5,-1
    800014ec:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014f0:	60a6                	ld	ra,72(sp)
    800014f2:	6406                	ld	s0,64(sp)
    800014f4:	74e2                	ld	s1,56(sp)
    800014f6:	7942                	ld	s2,48(sp)
    800014f8:	79a2                	ld	s3,40(sp)
    800014fa:	7a02                	ld	s4,32(sp)
    800014fc:	6ae2                	ld	s5,24(sp)
    800014fe:	6b42                	ld	s6,16(sp)
    80001500:	6ba2                	ld	s7,8(sp)
    80001502:	6161                	addi	sp,sp,80
    80001504:	8082                	ret
    80001506:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    8000150a:	9742                	add	a4,a4,a6
      --max;
    8000150c:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    80001510:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001514:	04e58463          	beq	a1,a4,8000155c <copyinstr+0x9e>
{
    80001518:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    8000151a:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000151e:	85a6                	mv	a1,s1
    80001520:	8552                	mv	a0,s4
    80001522:	ac5ff0ef          	jal	80000fe6 <walkaddr>
    if(pa0 == 0)
    80001526:	cd0d                	beqz	a0,80001560 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001528:	417486b3          	sub	a3,s1,s7
    8000152c:	96ce                	add	a3,a3,s3
    if(n > max)
    8000152e:	00d97363          	bgeu	s2,a3,80001534 <copyinstr+0x76>
    80001532:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001534:	955e                	add	a0,a0,s7
    80001536:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001538:	c695                	beqz	a3,80001564 <copyinstr+0xa6>
    8000153a:	87da                	mv	a5,s6
    8000153c:	885a                	mv	a6,s6
      if(*p == '\0'){
    8000153e:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001542:	96da                	add	a3,a3,s6
    80001544:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001546:	00f60733          	add	a4,a2,a5
    8000154a:	00074703          	lbu	a4,0(a4)
    8000154e:	db59                	beqz	a4,800014e4 <copyinstr+0x26>
        *dst = *p;
    80001550:	00e78023          	sb	a4,0(a5)
      dst++;
    80001554:	0785                	addi	a5,a5,1
    while(n > 0){
    80001556:	fed797e3          	bne	a5,a3,80001544 <copyinstr+0x86>
    8000155a:	b775                	j	80001506 <copyinstr+0x48>
    8000155c:	4781                	li	a5,0
    8000155e:	b771                	j	800014ea <copyinstr+0x2c>
      return -1;
    80001560:	557d                	li	a0,-1
    80001562:	b779                	j	800014f0 <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    80001564:	6b85                	lui	s7,0x1
    80001566:	9ba6                	add	s7,s7,s1
    80001568:	87da                	mv	a5,s6
    8000156a:	b77d                	j	80001518 <copyinstr+0x5a>
  int got_null = 0;
    8000156c:	4781                	li	a5,0
  if(got_null){
    8000156e:	37fd                	addiw	a5,a5,-1
    80001570:	0007851b          	sext.w	a0,a5
}
    80001574:	8082                	ret

0000000080001576 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001576:	1141                	addi	sp,sp,-16
    80001578:	e406                	sd	ra,8(sp)
    8000157a:	e022                	sd	s0,0(sp)
    8000157c:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    8000157e:	4601                	li	a2,0
    80001580:	9cdff0ef          	jal	80000f4c <walk>
  if (pte == 0) {
    80001584:	c519                	beqz	a0,80001592 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001586:	6108                	ld	a0,0(a0)
    80001588:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000158a:	60a2                	ld	ra,8(sp)
    8000158c:	6402                	ld	s0,0(sp)
    8000158e:	0141                	addi	sp,sp,16
    80001590:	8082                	ret
    return 0;
    80001592:	4501                	li	a0,0
    80001594:	bfdd                	j	8000158a <ismapped+0x14>

0000000080001596 <vmfault>:
{
    80001596:	7179                	addi	sp,sp,-48
    80001598:	f406                	sd	ra,40(sp)
    8000159a:	f022                	sd	s0,32(sp)
    8000159c:	ec26                	sd	s1,24(sp)
    8000159e:	e44e                	sd	s3,8(sp)
    800015a0:	1800                	addi	s0,sp,48
    800015a2:	89aa                	mv	s3,a0
    800015a4:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800015a6:	35e000ef          	jal	80001904 <myproc>
  if (va >= p->sz)
    800015aa:	653c                	ld	a5,72(a0)
    800015ac:	00f4ea63          	bltu	s1,a5,800015c0 <vmfault+0x2a>
    return 0;
    800015b0:	4981                	li	s3,0
}
    800015b2:	854e                	mv	a0,s3
    800015b4:	70a2                	ld	ra,40(sp)
    800015b6:	7402                	ld	s0,32(sp)
    800015b8:	64e2                	ld	s1,24(sp)
    800015ba:	69a2                	ld	s3,8(sp)
    800015bc:	6145                	addi	sp,sp,48
    800015be:	8082                	ret
    800015c0:	e84a                	sd	s2,16(sp)
    800015c2:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800015c4:	77fd                	lui	a5,0xfffff
    800015c6:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    800015c8:	85a6                	mv	a1,s1
    800015ca:	854e                	mv	a0,s3
    800015cc:	fabff0ef          	jal	80001576 <ismapped>
    return 0;
    800015d0:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015d2:	c119                	beqz	a0,800015d8 <vmfault+0x42>
    800015d4:	6942                	ld	s2,16(sp)
    800015d6:	bff1                	j	800015b2 <vmfault+0x1c>
    800015d8:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015da:	d56ff0ef          	jal	80000b30 <kalloc>
    800015de:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015e0:	c90d                	beqz	a0,80001612 <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015e2:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015e4:	6605                	lui	a2,0x1
    800015e6:	4581                	li	a1,0
    800015e8:	eecff0ef          	jal	80000cd4 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015ec:	4759                	li	a4,22
    800015ee:	86d2                	mv	a3,s4
    800015f0:	6605                	lui	a2,0x1
    800015f2:	85a6                	mv	a1,s1
    800015f4:	05093503          	ld	a0,80(s2)
    800015f8:	a2dff0ef          	jal	80001024 <mappages>
    800015fc:	e501                	bnez	a0,80001604 <vmfault+0x6e>
    800015fe:	6942                	ld	s2,16(sp)
    80001600:	6a02                	ld	s4,0(sp)
    80001602:	bf45                	j	800015b2 <vmfault+0x1c>
    kfree((void *)mem);
    80001604:	8552                	mv	a0,s4
    80001606:	c48ff0ef          	jal	80000a4e <kfree>
    return 0;
    8000160a:	4981                	li	s3,0
    8000160c:	6942                	ld	s2,16(sp)
    8000160e:	6a02                	ld	s4,0(sp)
    80001610:	b74d                	j	800015b2 <vmfault+0x1c>
    80001612:	6942                	ld	s2,16(sp)
    80001614:	6a02                	ld	s4,0(sp)
    80001616:	bf71                	j	800015b2 <vmfault+0x1c>

0000000080001618 <copyout>:
  while(len > 0){
    80001618:	c2cd                	beqz	a3,800016ba <copyout+0xa2>
{
    8000161a:	711d                	addi	sp,sp,-96
    8000161c:	ec86                	sd	ra,88(sp)
    8000161e:	e8a2                	sd	s0,80(sp)
    80001620:	e4a6                	sd	s1,72(sp)
    80001622:	f852                	sd	s4,48(sp)
    80001624:	f05a                	sd	s6,32(sp)
    80001626:	ec5e                	sd	s7,24(sp)
    80001628:	e862                	sd	s8,16(sp)
    8000162a:	1080                	addi	s0,sp,96
    8000162c:	8c2a                	mv	s8,a0
    8000162e:	8b2e                	mv	s6,a1
    80001630:	8bb2                	mv	s7,a2
    80001632:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001634:	74fd                	lui	s1,0xfffff
    80001636:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001638:	57fd                	li	a5,-1
    8000163a:	83e9                	srli	a5,a5,0x1a
    8000163c:	0897e163          	bltu	a5,s1,800016be <copyout+0xa6>
    80001640:	e0ca                	sd	s2,64(sp)
    80001642:	fc4e                	sd	s3,56(sp)
    80001644:	f456                	sd	s5,40(sp)
    80001646:	e466                	sd	s9,8(sp)
    80001648:	e06a                	sd	s10,0(sp)
    8000164a:	6d05                	lui	s10,0x1
    8000164c:	8cbe                	mv	s9,a5
    8000164e:	a015                	j	80001672 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001650:	409b0533          	sub	a0,s6,s1
    80001654:	0009861b          	sext.w	a2,s3
    80001658:	85de                	mv	a1,s7
    8000165a:	954a                	add	a0,a0,s2
    8000165c:	ed4ff0ef          	jal	80000d30 <memmove>
    len -= n;
    80001660:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001664:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001666:	040a0363          	beqz	s4,800016ac <copyout+0x94>
    if(va0 >= MAXVA)
    8000166a:	055cec63          	bltu	s9,s5,800016c2 <copyout+0xaa>
    8000166e:	84d6                	mv	s1,s5
    80001670:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    80001672:	85a6                	mv	a1,s1
    80001674:	8562                	mv	a0,s8
    80001676:	971ff0ef          	jal	80000fe6 <walkaddr>
    8000167a:	892a                	mv	s2,a0
    if(pa0 == 0) {
    8000167c:	e901                	bnez	a0,8000168c <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000167e:	4601                	li	a2,0
    80001680:	85a6                	mv	a1,s1
    80001682:	8562                	mv	a0,s8
    80001684:	f13ff0ef          	jal	80001596 <vmfault>
    80001688:	892a                	mv	s2,a0
    8000168a:	c139                	beqz	a0,800016d0 <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    8000168c:	4601                	li	a2,0
    8000168e:	85a6                	mv	a1,s1
    80001690:	8562                	mv	a0,s8
    80001692:	8bbff0ef          	jal	80000f4c <walk>
    if((*pte & PTE_W) == 0)
    80001696:	611c                	ld	a5,0(a0)
    80001698:	8b91                	andi	a5,a5,4
    8000169a:	c3b1                	beqz	a5,800016de <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    8000169c:	01a48ab3          	add	s5,s1,s10
    800016a0:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    800016a4:	fb3a76e3          	bgeu	s4,s3,80001650 <copyout+0x38>
    800016a8:	89d2                	mv	s3,s4
    800016aa:	b75d                	j	80001650 <copyout+0x38>
  return 0;
    800016ac:	4501                	li	a0,0
    800016ae:	6906                	ld	s2,64(sp)
    800016b0:	79e2                	ld	s3,56(sp)
    800016b2:	7aa2                	ld	s5,40(sp)
    800016b4:	6ca2                	ld	s9,8(sp)
    800016b6:	6d02                	ld	s10,0(sp)
    800016b8:	a80d                	j	800016ea <copyout+0xd2>
    800016ba:	4501                	li	a0,0
}
    800016bc:	8082                	ret
      return -1;
    800016be:	557d                	li	a0,-1
    800016c0:	a02d                	j	800016ea <copyout+0xd2>
    800016c2:	557d                	li	a0,-1
    800016c4:	6906                	ld	s2,64(sp)
    800016c6:	79e2                	ld	s3,56(sp)
    800016c8:	7aa2                	ld	s5,40(sp)
    800016ca:	6ca2                	ld	s9,8(sp)
    800016cc:	6d02                	ld	s10,0(sp)
    800016ce:	a831                	j	800016ea <copyout+0xd2>
        return -1;
    800016d0:	557d                	li	a0,-1
    800016d2:	6906                	ld	s2,64(sp)
    800016d4:	79e2                	ld	s3,56(sp)
    800016d6:	7aa2                	ld	s5,40(sp)
    800016d8:	6ca2                	ld	s9,8(sp)
    800016da:	6d02                	ld	s10,0(sp)
    800016dc:	a039                	j	800016ea <copyout+0xd2>
      return -1;
    800016de:	557d                	li	a0,-1
    800016e0:	6906                	ld	s2,64(sp)
    800016e2:	79e2                	ld	s3,56(sp)
    800016e4:	7aa2                	ld	s5,40(sp)
    800016e6:	6ca2                	ld	s9,8(sp)
    800016e8:	6d02                	ld	s10,0(sp)
}
    800016ea:	60e6                	ld	ra,88(sp)
    800016ec:	6446                	ld	s0,80(sp)
    800016ee:	64a6                	ld	s1,72(sp)
    800016f0:	7a42                	ld	s4,48(sp)
    800016f2:	7b02                	ld	s6,32(sp)
    800016f4:	6be2                	ld	s7,24(sp)
    800016f6:	6c42                	ld	s8,16(sp)
    800016f8:	6125                	addi	sp,sp,96
    800016fa:	8082                	ret

00000000800016fc <copyin>:
  while(len > 0){
    800016fc:	c6c9                	beqz	a3,80001786 <copyin+0x8a>
{
    800016fe:	715d                	addi	sp,sp,-80
    80001700:	e486                	sd	ra,72(sp)
    80001702:	e0a2                	sd	s0,64(sp)
    80001704:	fc26                	sd	s1,56(sp)
    80001706:	f84a                	sd	s2,48(sp)
    80001708:	f44e                	sd	s3,40(sp)
    8000170a:	f052                	sd	s4,32(sp)
    8000170c:	ec56                	sd	s5,24(sp)
    8000170e:	e85a                	sd	s6,16(sp)
    80001710:	e45e                	sd	s7,8(sp)
    80001712:	e062                	sd	s8,0(sp)
    80001714:	0880                	addi	s0,sp,80
    80001716:	8baa                	mv	s7,a0
    80001718:	8aae                	mv	s5,a1
    8000171a:	8932                	mv	s2,a2
    8000171c:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    8000171e:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001720:	6b05                	lui	s6,0x1
    80001722:	a035                	j	8000174e <copyin+0x52>
    80001724:	412984b3          	sub	s1,s3,s2
    80001728:	94da                	add	s1,s1,s6
    if(n > len)
    8000172a:	009a7363          	bgeu	s4,s1,80001730 <copyin+0x34>
    8000172e:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001730:	413905b3          	sub	a1,s2,s3
    80001734:	0004861b          	sext.w	a2,s1
    80001738:	95aa                	add	a1,a1,a0
    8000173a:	8556                	mv	a0,s5
    8000173c:	df4ff0ef          	jal	80000d30 <memmove>
    len -= n;
    80001740:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001744:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001746:	01698933          	add	s2,s3,s6
  while(len > 0){
    8000174a:	020a0163          	beqz	s4,8000176c <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    8000174e:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001752:	85ce                	mv	a1,s3
    80001754:	855e                	mv	a0,s7
    80001756:	891ff0ef          	jal	80000fe6 <walkaddr>
    if(pa0 == 0) {
    8000175a:	f569                	bnez	a0,80001724 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000175c:	4601                	li	a2,0
    8000175e:	85ce                	mv	a1,s3
    80001760:	855e                	mv	a0,s7
    80001762:	e35ff0ef          	jal	80001596 <vmfault>
    80001766:	fd5d                	bnez	a0,80001724 <copyin+0x28>
        return -1;
    80001768:	557d                	li	a0,-1
    8000176a:	a011                	j	8000176e <copyin+0x72>
  return 0;
    8000176c:	4501                	li	a0,0
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret
  return 0;
    80001786:	4501                	li	a0,0
}
    80001788:	8082                	ret

000000008000178a <proc_mapstacks>:
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl) {
    8000178a:	7139                	addi	sp,sp,-64
    8000178c:	fc06                	sd	ra,56(sp)
    8000178e:	f822                	sd	s0,48(sp)
    80001790:	f426                	sd	s1,40(sp)
    80001792:	f04a                	sd	s2,32(sp)
    80001794:	ec4e                	sd	s3,24(sp)
    80001796:	e852                	sd	s4,16(sp)
    80001798:	e456                	sd	s5,8(sp)
    8000179a:	e05a                	sd	s6,0(sp)
    8000179c:	0080                	addi	s0,sp,64
    8000179e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++) {
    800017a0:	0000e497          	auipc	s1,0xe
    800017a4:	65848493          	addi	s1,s1,1624 # 8000fdf8 <proc>
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800017a8:	8b26                	mv	s6,s1
    800017aa:	04fa5937          	lui	s2,0x4fa5
    800017ae:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    800017b2:	0932                	slli	s2,s2,0xc
    800017b4:	fa590913          	addi	s2,s2,-91
    800017b8:	0932                	slli	s2,s2,0xc
    800017ba:	fa590913          	addi	s2,s2,-91
    800017be:	0932                	slli	s2,s2,0xc
    800017c0:	fa590913          	addi	s2,s2,-91
    800017c4:	040009b7          	lui	s3,0x4000
    800017c8:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800017ca:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++) {
    800017cc:	00014a97          	auipc	s5,0x14
    800017d0:	02ca8a93          	addi	s5,s5,44 # 800157f8 <tickslock>
    char *pa = kalloc();
    800017d4:	b5cff0ef          	jal	80000b30 <kalloc>
    800017d8:	862a                	mv	a2,a0
    if (pa == 0)
    800017da:	cd15                	beqz	a0,80001816 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int)(p - proc));
    800017dc:	416485b3          	sub	a1,s1,s6
    800017e0:	858d                	srai	a1,a1,0x3
    800017e2:	032585b3          	mul	a1,a1,s2
    800017e6:	2585                	addiw	a1,a1,1
    800017e8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017ec:	4719                	li	a4,6
    800017ee:	6685                	lui	a3,0x1
    800017f0:	40b985b3          	sub	a1,s3,a1
    800017f4:	8552                	mv	a0,s4
    800017f6:	8dfff0ef          	jal	800010d4 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++) {
    800017fa:	16848493          	addi	s1,s1,360
    800017fe:	fd549be3          	bne	s1,s5,800017d4 <proc_mapstacks+0x4a>
  }
}
    80001802:	70e2                	ld	ra,56(sp)
    80001804:	7442                	ld	s0,48(sp)
    80001806:	74a2                	ld	s1,40(sp)
    80001808:	7902                	ld	s2,32(sp)
    8000180a:	69e2                	ld	s3,24(sp)
    8000180c:	6a42                	ld	s4,16(sp)
    8000180e:	6aa2                	ld	s5,8(sp)
    80001810:	6b02                	ld	s6,0(sp)
    80001812:	6121                	addi	sp,sp,64
    80001814:	8082                	ret
      panic("kalloc");
    80001816:	00006517          	auipc	a0,0x6
    8000181a:	94a50513          	addi	a0,a0,-1718 # 80007160 <etext+0x160>
    8000181e:	ff5fe0ef          	jal	80000812 <panic>

0000000080001822 <procinit>:

// initialize the proc table.
void procinit(void) {
    80001822:	7139                	addi	sp,sp,-64
    80001824:	fc06                	sd	ra,56(sp)
    80001826:	f822                	sd	s0,48(sp)
    80001828:	f426                	sd	s1,40(sp)
    8000182a:	f04a                	sd	s2,32(sp)
    8000182c:	ec4e                	sd	s3,24(sp)
    8000182e:	e852                	sd	s4,16(sp)
    80001830:	e456                	sd	s5,8(sp)
    80001832:	e05a                	sd	s6,0(sp)
    80001834:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001836:	00006597          	auipc	a1,0x6
    8000183a:	93258593          	addi	a1,a1,-1742 # 80007168 <etext+0x168>
    8000183e:	0000e517          	auipc	a0,0xe
    80001842:	18a50513          	addi	a0,a0,394 # 8000f9c8 <pid_lock>
    80001846:	b3aff0ef          	jal	80000b80 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000184a:	00006597          	auipc	a1,0x6
    8000184e:	92658593          	addi	a1,a1,-1754 # 80007170 <etext+0x170>
    80001852:	0000e517          	auipc	a0,0xe
    80001856:	18e50513          	addi	a0,a0,398 # 8000f9e0 <wait_lock>
    8000185a:	b26ff0ef          	jal	80000b80 <initlock>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000185e:	0000e497          	auipc	s1,0xe
    80001862:	59a48493          	addi	s1,s1,1434 # 8000fdf8 <proc>
    initlock(&p->lock, "proc");
    80001866:	00006b17          	auipc	s6,0x6
    8000186a:	91ab0b13          	addi	s6,s6,-1766 # 80007180 <etext+0x180>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000186e:	8aa6                	mv	s5,s1
    80001870:	04fa5937          	lui	s2,0x4fa5
    80001874:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    80001878:	0932                	slli	s2,s2,0xc
    8000187a:	fa590913          	addi	s2,s2,-91
    8000187e:	0932                	slli	s2,s2,0xc
    80001880:	fa590913          	addi	s2,s2,-91
    80001884:	0932                	slli	s2,s2,0xc
    80001886:	fa590913          	addi	s2,s2,-91
    8000188a:	040009b7          	lui	s3,0x4000
    8000188e:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001890:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++) {
    80001892:	00014a17          	auipc	s4,0x14
    80001896:	f66a0a13          	addi	s4,s4,-154 # 800157f8 <tickslock>
    initlock(&p->lock, "proc");
    8000189a:	85da                	mv	a1,s6
    8000189c:	8526                	mv	a0,s1
    8000189e:	ae2ff0ef          	jal	80000b80 <initlock>
    p->state = UNUSED;
    800018a2:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800018a6:	415487b3          	sub	a5,s1,s5
    800018aa:	878d                	srai	a5,a5,0x3
    800018ac:	032787b3          	mul	a5,a5,s2
    800018b0:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffd63f9>
    800018b2:	00d7979b          	slliw	a5,a5,0xd
    800018b6:	40f987b3          	sub	a5,s3,a5
    800018ba:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++) {
    800018bc:	16848493          	addi	s1,s1,360
    800018c0:	fd449de3          	bne	s1,s4,8000189a <procinit+0x78>
  }
}
    800018c4:	70e2                	ld	ra,56(sp)
    800018c6:	7442                	ld	s0,48(sp)
    800018c8:	74a2                	ld	s1,40(sp)
    800018ca:	7902                	ld	s2,32(sp)
    800018cc:	69e2                	ld	s3,24(sp)
    800018ce:	6a42                	ld	s4,16(sp)
    800018d0:	6aa2                	ld	s5,8(sp)
    800018d2:	6b02                	ld	s6,0(sp)
    800018d4:	6121                	addi	sp,sp,64
    800018d6:	8082                	ret

00000000800018d8 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid() {
    800018d8:	1141                	addi	sp,sp,-16
    800018da:	e422                	sd	s0,8(sp)
    800018dc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018de:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018e0:	2501                	sext.w	a0,a0
    800018e2:	6422                	ld	s0,8(sp)
    800018e4:	0141                	addi	sp,sp,16
    800018e6:	8082                	ret

00000000800018e8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *mycpu(void) {
    800018e8:	1141                	addi	sp,sp,-16
    800018ea:	e422                	sd	s0,8(sp)
    800018ec:	0800                	addi	s0,sp,16
    800018ee:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018f0:	2781                	sext.w	a5,a5
    800018f2:	079e                	slli	a5,a5,0x7
  return c;
}
    800018f4:	0000e517          	auipc	a0,0xe
    800018f8:	10450513          	addi	a0,a0,260 # 8000f9f8 <cpus>
    800018fc:	953e                	add	a0,a0,a5
    800018fe:	6422                	ld	s0,8(sp)
    80001900:	0141                	addi	sp,sp,16
    80001902:	8082                	ret

0000000080001904 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *myproc(void) {
    80001904:	1101                	addi	sp,sp,-32
    80001906:	ec06                	sd	ra,24(sp)
    80001908:	e822                	sd	s0,16(sp)
    8000190a:	e426                	sd	s1,8(sp)
    8000190c:	1000                	addi	s0,sp,32
  push_off();
    8000190e:	ab2ff0ef          	jal	80000bc0 <push_off>
    80001912:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001914:	2781                	sext.w	a5,a5
    80001916:	079e                	slli	a5,a5,0x7
    80001918:	0000e717          	auipc	a4,0xe
    8000191c:	0b070713          	addi	a4,a4,176 # 8000f9c8 <pid_lock>
    80001920:	97ba                	add	a5,a5,a4
    80001922:	7b84                	ld	s1,48(a5)
  pop_off();
    80001924:	b20ff0ef          	jal	80000c44 <pop_off>
  return p;
}
    80001928:	8526                	mv	a0,s1
    8000192a:	60e2                	ld	ra,24(sp)
    8000192c:	6442                	ld	s0,16(sp)
    8000192e:	64a2                	ld	s1,8(sp)
    80001930:	6105                	addi	sp,sp,32
    80001932:	8082                	ret

0000000080001934 <forkret>:
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void) {
    80001934:	7179                	addi	sp,sp,-48
    80001936:	f406                	sd	ra,40(sp)
    80001938:	f022                	sd	s0,32(sp)
    8000193a:	ec26                	sd	s1,24(sp)
    8000193c:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    8000193e:	fc7ff0ef          	jal	80001904 <myproc>
    80001942:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001944:	b54ff0ef          	jal	80000c98 <release>

  if (first) {
    80001948:	00006797          	auipc	a5,0x6
    8000194c:	f087a783          	lw	a5,-248(a5) # 80007850 <first.1>
    80001950:	cf8d                	beqz	a5,8000198a <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001952:	4505                	li	a0,1
    80001954:	3bf010ef          	jal	80003512 <fsinit>

    first = 0;
    80001958:	00006797          	auipc	a5,0x6
    8000195c:	ee07ac23          	sw	zero,-264(a5) # 80007850 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001960:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){"/init", 0});
    80001964:	00006517          	auipc	a0,0x6
    80001968:	82450513          	addi	a0,a0,-2012 # 80007188 <etext+0x188>
    8000196c:	fca43823          	sd	a0,-48(s0)
    80001970:	fc043c23          	sd	zero,-40(s0)
    80001974:	fd040593          	addi	a1,s0,-48
    80001978:	4a5020ef          	jal	8000461c <kexec>
    8000197c:	6cbc                	ld	a5,88(s1)
    8000197e:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001980:	6cbc                	ld	a5,88(s1)
    80001982:	7bb8                	ld	a4,112(a5)
    80001984:	57fd                	li	a5,-1
    80001986:	02f70d63          	beq	a4,a5,800019c0 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    8000198a:	2c5000ef          	jal	8000244e <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000198e:	68a8                	ld	a0,80(s1)
    80001990:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001992:	04000737          	lui	a4,0x4000
    80001996:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80001998:	0732                	slli	a4,a4,0xc
    8000199a:	00004797          	auipc	a5,0x4
    8000199e:	70278793          	addi	a5,a5,1794 # 8000609c <userret>
    800019a2:	00004697          	auipc	a3,0x4
    800019a6:	65e68693          	addi	a3,a3,1630 # 80006000 <_trampoline>
    800019aa:	8f95                	sub	a5,a5,a3
    800019ac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800019ae:	577d                	li	a4,-1
    800019b0:	177e                	slli	a4,a4,0x3f
    800019b2:	8d59                	or	a0,a0,a4
    800019b4:	9782                	jalr	a5
}
    800019b6:	70a2                	ld	ra,40(sp)
    800019b8:	7402                	ld	s0,32(sp)
    800019ba:	64e2                	ld	s1,24(sp)
    800019bc:	6145                	addi	sp,sp,48
    800019be:	8082                	ret
      panic("exec");
    800019c0:	00005517          	auipc	a0,0x5
    800019c4:	7d050513          	addi	a0,a0,2000 # 80007190 <etext+0x190>
    800019c8:	e4bfe0ef          	jal	80000812 <panic>

00000000800019cc <allocpid>:
int allocpid() {
    800019cc:	1101                	addi	sp,sp,-32
    800019ce:	ec06                	sd	ra,24(sp)
    800019d0:	e822                	sd	s0,16(sp)
    800019d2:	e426                	sd	s1,8(sp)
    800019d4:	e04a                	sd	s2,0(sp)
    800019d6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019d8:	0000e917          	auipc	s2,0xe
    800019dc:	ff090913          	addi	s2,s2,-16 # 8000f9c8 <pid_lock>
    800019e0:	854a                	mv	a0,s2
    800019e2:	a1eff0ef          	jal	80000c00 <acquire>
  pid = nextpid;
    800019e6:	00006797          	auipc	a5,0x6
    800019ea:	e6e78793          	addi	a5,a5,-402 # 80007854 <nextpid>
    800019ee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019f0:	0014871b          	addiw	a4,s1,1
    800019f4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019f6:	854a                	mv	a0,s2
    800019f8:	aa0ff0ef          	jal	80000c98 <release>
}
    800019fc:	8526                	mv	a0,s1
    800019fe:	60e2                	ld	ra,24(sp)
    80001a00:	6442                	ld	s0,16(sp)
    80001a02:	64a2                	ld	s1,8(sp)
    80001a04:	6902                	ld	s2,0(sp)
    80001a06:	6105                	addi	sp,sp,32
    80001a08:	8082                	ret

0000000080001a0a <proc_pagetable>:
pagetable_t proc_pagetable(struct proc *p) {
    80001a0a:	1101                	addi	sp,sp,-32
    80001a0c:	ec06                	sd	ra,24(sp)
    80001a0e:	e822                	sd	s0,16(sp)
    80001a10:	e426                	sd	s1,8(sp)
    80001a12:	e04a                	sd	s2,0(sp)
    80001a14:	1000                	addi	s0,sp,32
    80001a16:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a18:	fb2ff0ef          	jal	800011ca <uvmcreate>
    80001a1c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a1e:	cd05                	beqz	a0,80001a56 <proc_pagetable+0x4c>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline,
    80001a20:	4729                	li	a4,10
    80001a22:	00004697          	auipc	a3,0x4
    80001a26:	5de68693          	addi	a3,a3,1502 # 80006000 <_trampoline>
    80001a2a:	6605                	lui	a2,0x1
    80001a2c:	040005b7          	lui	a1,0x4000
    80001a30:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a32:	05b2                	slli	a1,a1,0xc
    80001a34:	df0ff0ef          	jal	80001024 <mappages>
    80001a38:	02054663          	bltz	a0,80001a64 <proc_pagetable+0x5a>
  if (mappages(pagetable, TRAPFRAME, PGSIZE, (uint64)(p->trapframe),
    80001a3c:	4719                	li	a4,6
    80001a3e:	05893683          	ld	a3,88(s2)
    80001a42:	6605                	lui	a2,0x1
    80001a44:	020005b7          	lui	a1,0x2000
    80001a48:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a4a:	05b6                	slli	a1,a1,0xd
    80001a4c:	8526                	mv	a0,s1
    80001a4e:	dd6ff0ef          	jal	80001024 <mappages>
    80001a52:	00054f63          	bltz	a0,80001a70 <proc_pagetable+0x66>
}
    80001a56:	8526                	mv	a0,s1
    80001a58:	60e2                	ld	ra,24(sp)
    80001a5a:	6442                	ld	s0,16(sp)
    80001a5c:	64a2                	ld	s1,8(sp)
    80001a5e:	6902                	ld	s2,0(sp)
    80001a60:	6105                	addi	sp,sp,32
    80001a62:	8082                	ret
    uvmfree(pagetable, 0);
    80001a64:	4581                	li	a1,0
    80001a66:	8526                	mv	a0,s1
    80001a68:	95dff0ef          	jal	800013c4 <uvmfree>
    return 0;
    80001a6c:	4481                	li	s1,0
    80001a6e:	b7e5                	j	80001a56 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a70:	4681                	li	a3,0
    80001a72:	4605                	li	a2,1
    80001a74:	040005b7          	lui	a1,0x4000
    80001a78:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a7a:	05b2                	slli	a1,a1,0xc
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	f72ff0ef          	jal	800011f0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a82:	4581                	li	a1,0
    80001a84:	8526                	mv	a0,s1
    80001a86:	93fff0ef          	jal	800013c4 <uvmfree>
    return 0;
    80001a8a:	4481                	li	s1,0
    80001a8c:	b7e9                	j	80001a56 <proc_pagetable+0x4c>

0000000080001a8e <proc_freepagetable>:
void proc_freepagetable(pagetable_t pagetable, uint64 sz) {
    80001a8e:	1101                	addi	sp,sp,-32
    80001a90:	ec06                	sd	ra,24(sp)
    80001a92:	e822                	sd	s0,16(sp)
    80001a94:	e426                	sd	s1,8(sp)
    80001a96:	e04a                	sd	s2,0(sp)
    80001a98:	1000                	addi	s0,sp,32
    80001a9a:	84aa                	mv	s1,a0
    80001a9c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a9e:	4681                	li	a3,0
    80001aa0:	4605                	li	a2,1
    80001aa2:	040005b7          	lui	a1,0x4000
    80001aa6:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aa8:	05b2                	slli	a1,a1,0xc
    80001aaa:	f46ff0ef          	jal	800011f0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001aae:	4681                	li	a3,0
    80001ab0:	4605                	li	a2,1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	f34ff0ef          	jal	800011f0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ac0:	85ca                	mv	a1,s2
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	901ff0ef          	jal	800013c4 <uvmfree>
}
    80001ac8:	60e2                	ld	ra,24(sp)
    80001aca:	6442                	ld	s0,16(sp)
    80001acc:	64a2                	ld	s1,8(sp)
    80001ace:	6902                	ld	s2,0(sp)
    80001ad0:	6105                	addi	sp,sp,32
    80001ad2:	8082                	ret

0000000080001ad4 <freeproc>:
static void freeproc(struct proc *p) {
    80001ad4:	1101                	addi	sp,sp,-32
    80001ad6:	ec06                	sd	ra,24(sp)
    80001ad8:	e822                	sd	s0,16(sp)
    80001ada:	e426                	sd	s1,8(sp)
    80001adc:	1000                	addi	s0,sp,32
    80001ade:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001ae0:	6d28                	ld	a0,88(a0)
    80001ae2:	c119                	beqz	a0,80001ae8 <freeproc+0x14>
    kfree((void *)p->trapframe);
    80001ae4:	f6bfe0ef          	jal	80000a4e <kfree>
  p->trapframe = 0;
    80001ae8:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001aec:	68a8                	ld	a0,80(s1)
    80001aee:	c501                	beqz	a0,80001af6 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001af0:	64ac                	ld	a1,72(s1)
    80001af2:	f9dff0ef          	jal	80001a8e <proc_freepagetable>
  p->pagetable = 0;
    80001af6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001afa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001afe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b02:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b0a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b0e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b12:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b16:	0004ac23          	sw	zero,24(s1)
}
    80001b1a:	60e2                	ld	ra,24(sp)
    80001b1c:	6442                	ld	s0,16(sp)
    80001b1e:	64a2                	ld	s1,8(sp)
    80001b20:	6105                	addi	sp,sp,32
    80001b22:	8082                	ret

0000000080001b24 <allocproc>:
static struct proc *allocproc(void) {
    80001b24:	1101                	addi	sp,sp,-32
    80001b26:	ec06                	sd	ra,24(sp)
    80001b28:	e822                	sd	s0,16(sp)
    80001b2a:	e426                	sd	s1,8(sp)
    80001b2c:	e04a                	sd	s2,0(sp)
    80001b2e:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++) {
    80001b30:	0000e497          	auipc	s1,0xe
    80001b34:	2c848493          	addi	s1,s1,712 # 8000fdf8 <proc>
    80001b38:	00014917          	auipc	s2,0x14
    80001b3c:	cc090913          	addi	s2,s2,-832 # 800157f8 <tickslock>
    acquire(&p->lock);
    80001b40:	8526                	mv	a0,s1
    80001b42:	8beff0ef          	jal	80000c00 <acquire>
    if (p->state == UNUSED) {
    80001b46:	4c9c                	lw	a5,24(s1)
    80001b48:	cb91                	beqz	a5,80001b5c <allocproc+0x38>
      release(&p->lock);
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	94cff0ef          	jal	80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001b50:	16848493          	addi	s1,s1,360
    80001b54:	ff2496e3          	bne	s1,s2,80001b40 <allocproc+0x1c>
  return 0;
    80001b58:	4481                	li	s1,0
    80001b5a:	a089                	j	80001b9c <allocproc+0x78>
  p->pid = allocpid();
    80001b5c:	e71ff0ef          	jal	800019cc <allocpid>
    80001b60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b62:	4785                	li	a5,1
    80001b64:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0) {
    80001b66:	fcbfe0ef          	jal	80000b30 <kalloc>
    80001b6a:	892a                	mv	s2,a0
    80001b6c:	eca8                	sd	a0,88(s1)
    80001b6e:	cd15                	beqz	a0,80001baa <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001b70:	8526                	mv	a0,s1
    80001b72:	e99ff0ef          	jal	80001a0a <proc_pagetable>
    80001b76:	892a                	mv	s2,a0
    80001b78:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0) {
    80001b7a:	c121                	beqz	a0,80001bba <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001b7c:	07000613          	li	a2,112
    80001b80:	4581                	li	a1,0
    80001b82:	06048513          	addi	a0,s1,96
    80001b86:	94eff0ef          	jal	80000cd4 <memset>
  p->context.ra = (uint64)forkret;
    80001b8a:	00000797          	auipc	a5,0x0
    80001b8e:	daa78793          	addi	a5,a5,-598 # 80001934 <forkret>
    80001b92:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b94:	60bc                	ld	a5,64(s1)
    80001b96:	6705                	lui	a4,0x1
    80001b98:	97ba                	add	a5,a5,a4
    80001b9a:	f4bc                	sd	a5,104(s1)
}
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	60e2                	ld	ra,24(sp)
    80001ba0:	6442                	ld	s0,16(sp)
    80001ba2:	64a2                	ld	s1,8(sp)
    80001ba4:	6902                	ld	s2,0(sp)
    80001ba6:	6105                	addi	sp,sp,32
    80001ba8:	8082                	ret
    freeproc(p);
    80001baa:	8526                	mv	a0,s1
    80001bac:	f29ff0ef          	jal	80001ad4 <freeproc>
    release(&p->lock);
    80001bb0:	8526                	mv	a0,s1
    80001bb2:	8e6ff0ef          	jal	80000c98 <release>
    return 0;
    80001bb6:	84ca                	mv	s1,s2
    80001bb8:	b7d5                	j	80001b9c <allocproc+0x78>
    freeproc(p);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	f19ff0ef          	jal	80001ad4 <freeproc>
    release(&p->lock);
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	8d6ff0ef          	jal	80000c98 <release>
    return 0;
    80001bc6:	84ca                	mv	s1,s2
    80001bc8:	bfd1                	j	80001b9c <allocproc+0x78>

0000000080001bca <userinit>:
void userinit(void) {
    80001bca:	1101                	addi	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001bd4:	f51ff0ef          	jal	80001b24 <allocproc>
    80001bd8:	84aa                	mv	s1,a0
  initproc = p;
    80001bda:	00006797          	auipc	a5,0x6
    80001bde:	caa7b323          	sd	a0,-858(a5) # 80007880 <initproc>
  p->cwd = namei("/");
    80001be2:	00005517          	auipc	a0,0x5
    80001be6:	5b650513          	addi	a0,a0,1462 # 80007198 <etext+0x198>
    80001bea:	64b010ef          	jal	80003a34 <namei>
    80001bee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001bf2:	478d                	li	a5,3
    80001bf4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	8a0ff0ef          	jal	80000c98 <release>
}
    80001bfc:	60e2                	ld	ra,24(sp)
    80001bfe:	6442                	ld	s0,16(sp)
    80001c00:	64a2                	ld	s1,8(sp)
    80001c02:	6105                	addi	sp,sp,32
    80001c04:	8082                	ret

0000000080001c06 <growproc>:
int growproc(int n) {
    80001c06:	1101                	addi	sp,sp,-32
    80001c08:	ec06                	sd	ra,24(sp)
    80001c0a:	e822                	sd	s0,16(sp)
    80001c0c:	e426                	sd	s1,8(sp)
    80001c0e:	e04a                	sd	s2,0(sp)
    80001c10:	1000                	addi	s0,sp,32
    80001c12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c14:	cf1ff0ef          	jal	80001904 <myproc>
    80001c18:	892a                	mv	s2,a0
  sz = p->sz;
    80001c1a:	652c                	ld	a1,72(a0)
  if (n > 0) {
    80001c1c:	02905963          	blez	s1,80001c4e <growproc+0x48>
    if (sz + n > TRAPFRAME) {
    80001c20:	00b48633          	add	a2,s1,a1
    80001c24:	020007b7          	lui	a5,0x2000
    80001c28:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c2a:	07b6                	slli	a5,a5,0xd
    80001c2c:	02c7ea63          	bltu	a5,a2,80001c60 <growproc+0x5a>
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c30:	4691                	li	a3,4
    80001c32:	6928                	ld	a0,80(a0)
    80001c34:	e8aff0ef          	jal	800012be <uvmalloc>
    80001c38:	85aa                	mv	a1,a0
    80001c3a:	c50d                	beqz	a0,80001c64 <growproc+0x5e>
  p->sz = sz;
    80001c3c:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c40:	4501                	li	a0,0
}
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6902                	ld	s2,0(sp)
    80001c4a:	6105                	addi	sp,sp,32
    80001c4c:	8082                	ret
  } else if (n < 0) {
    80001c4e:	fe04d7e3          	bgez	s1,80001c3c <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c52:	00b48633          	add	a2,s1,a1
    80001c56:	6928                	ld	a0,80(a0)
    80001c58:	e22ff0ef          	jal	8000127a <uvmdealloc>
    80001c5c:	85aa                	mv	a1,a0
    80001c5e:	bff9                	j	80001c3c <growproc+0x36>
      return -1;
    80001c60:	557d                	li	a0,-1
    80001c62:	b7c5                	j	80001c42 <growproc+0x3c>
      return -1;
    80001c64:	557d                	li	a0,-1
    80001c66:	bff1                	j	80001c42 <growproc+0x3c>

0000000080001c68 <kfork>:
int kfork(void) {
    80001c68:	7139                	addi	sp,sp,-64
    80001c6a:	fc06                	sd	ra,56(sp)
    80001c6c:	f822                	sd	s0,48(sp)
    80001c6e:	f04a                	sd	s2,32(sp)
    80001c70:	e456                	sd	s5,8(sp)
    80001c72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c74:	c91ff0ef          	jal	80001904 <myproc>
    80001c78:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0) {
    80001c7a:	eabff0ef          	jal	80001b24 <allocproc>
    80001c7e:	0e050a63          	beqz	a0,80001d72 <kfork+0x10a>
    80001c82:	e852                	sd	s4,16(sp)
    80001c84:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0) {
    80001c86:	048ab603          	ld	a2,72(s5)
    80001c8a:	692c                	ld	a1,80(a0)
    80001c8c:	050ab503          	ld	a0,80(s5)
    80001c90:	f66ff0ef          	jal	800013f6 <uvmcopy>
    80001c94:	04054a63          	bltz	a0,80001ce8 <kfork+0x80>
    80001c98:	f426                	sd	s1,40(sp)
    80001c9a:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001c9c:	048ab783          	ld	a5,72(s5)
    80001ca0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ca4:	058ab683          	ld	a3,88(s5)
    80001ca8:	87b6                	mv	a5,a3
    80001caa:	058a3703          	ld	a4,88(s4)
    80001cae:	12068693          	addi	a3,a3,288
    80001cb2:	0007b803          	ld	a6,0(a5)
    80001cb6:	6788                	ld	a0,8(a5)
    80001cb8:	6b8c                	ld	a1,16(a5)
    80001cba:	6f90                	ld	a2,24(a5)
    80001cbc:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001cc0:	e708                	sd	a0,8(a4)
    80001cc2:	eb0c                	sd	a1,16(a4)
    80001cc4:	ef10                	sd	a2,24(a4)
    80001cc6:	02078793          	addi	a5,a5,32
    80001cca:	02070713          	addi	a4,a4,32
    80001cce:	fed792e3          	bne	a5,a3,80001cb2 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001cd2:	058a3783          	ld	a5,88(s4)
    80001cd6:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001cda:	0d0a8493          	addi	s1,s5,208
    80001cde:	0d0a0913          	addi	s2,s4,208
    80001ce2:	150a8993          	addi	s3,s5,336
    80001ce6:	a831                	j	80001d02 <kfork+0x9a>
    freeproc(np);
    80001ce8:	8552                	mv	a0,s4
    80001cea:	debff0ef          	jal	80001ad4 <freeproc>
    release(&np->lock);
    80001cee:	8552                	mv	a0,s4
    80001cf0:	fa9fe0ef          	jal	80000c98 <release>
    return -1;
    80001cf4:	597d                	li	s2,-1
    80001cf6:	6a42                	ld	s4,16(sp)
    80001cf8:	a0b5                	j	80001d64 <kfork+0xfc>
  for (i = 0; i < NOFILE; i++)
    80001cfa:	04a1                	addi	s1,s1,8
    80001cfc:	0921                	addi	s2,s2,8
    80001cfe:	01348963          	beq	s1,s3,80001d10 <kfork+0xa8>
    if (p->ofile[i])
    80001d02:	6088                	ld	a0,0(s1)
    80001d04:	d97d                	beqz	a0,80001cfa <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d06:	2c8020ef          	jal	80003fce <filedup>
    80001d0a:	00a93023          	sd	a0,0(s2)
    80001d0e:	b7f5                	j	80001cfa <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d10:	150ab503          	ld	a0,336(s5)
    80001d14:	4d4010ef          	jal	800031e8 <idup>
    80001d18:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d1c:	4641                	li	a2,16
    80001d1e:	158a8593          	addi	a1,s5,344
    80001d22:	158a0513          	addi	a0,s4,344
    80001d26:	8ecff0ef          	jal	80000e12 <safestrcpy>
  pid = np->pid;
    80001d2a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001d2e:	8552                	mv	a0,s4
    80001d30:	f69fe0ef          	jal	80000c98 <release>
  acquire(&wait_lock);
    80001d34:	0000e497          	auipc	s1,0xe
    80001d38:	cac48493          	addi	s1,s1,-852 # 8000f9e0 <wait_lock>
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	ec3fe0ef          	jal	80000c00 <acquire>
  np->parent = p;
    80001d42:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	f51fe0ef          	jal	80000c98 <release>
  acquire(&np->lock);
    80001d4c:	8552                	mv	a0,s4
    80001d4e:	eb3fe0ef          	jal	80000c00 <acquire>
  np->state = RUNNABLE;
    80001d52:	478d                	li	a5,3
    80001d54:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d58:	8552                	mv	a0,s4
    80001d5a:	f3ffe0ef          	jal	80000c98 <release>
  return pid;
    80001d5e:	74a2                	ld	s1,40(sp)
    80001d60:	69e2                	ld	s3,24(sp)
    80001d62:	6a42                	ld	s4,16(sp)
}
    80001d64:	854a                	mv	a0,s2
    80001d66:	70e2                	ld	ra,56(sp)
    80001d68:	7442                	ld	s0,48(sp)
    80001d6a:	7902                	ld	s2,32(sp)
    80001d6c:	6aa2                	ld	s5,8(sp)
    80001d6e:	6121                	addi	sp,sp,64
    80001d70:	8082                	ret
    return -1;
    80001d72:	597d                	li	s2,-1
    80001d74:	bfc5                	j	80001d64 <kfork+0xfc>

0000000080001d76 <scheduler>:
void scheduler(void) {
    80001d76:	715d                	addi	sp,sp,-80
    80001d78:	e486                	sd	ra,72(sp)
    80001d7a:	e0a2                	sd	s0,64(sp)
    80001d7c:	fc26                	sd	s1,56(sp)
    80001d7e:	f84a                	sd	s2,48(sp)
    80001d80:	f44e                	sd	s3,40(sp)
    80001d82:	f052                	sd	s4,32(sp)
    80001d84:	ec56                	sd	s5,24(sp)
    80001d86:	e85a                	sd	s6,16(sp)
    80001d88:	e45e                	sd	s7,8(sp)
    80001d8a:	e062                	sd	s8,0(sp)
    80001d8c:	0880                	addi	s0,sp,80
    80001d8e:	8792                	mv	a5,tp
  int id = r_tp();
    80001d90:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d92:	00779b13          	slli	s6,a5,0x7
    80001d96:	0000e717          	auipc	a4,0xe
    80001d9a:	c3270713          	addi	a4,a4,-974 # 8000f9c8 <pid_lock>
    80001d9e:	975a                	add	a4,a4,s6
    80001da0:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001da4:	0000e717          	auipc	a4,0xe
    80001da8:	c5c70713          	addi	a4,a4,-932 # 8000fa00 <cpus+0x8>
    80001dac:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001dae:	4c11                	li	s8,4
        c->proc = p;
    80001db0:	079e                	slli	a5,a5,0x7
    80001db2:	0000ea17          	auipc	s4,0xe
    80001db6:	c16a0a13          	addi	s4,s4,-1002 # 8000f9c8 <pid_lock>
    80001dba:	9a3e                	add	s4,s4,a5
        found = 1;
    80001dbc:	4b85                	li	s7,1
    for (p = proc; p < &proc[NPROC]; p++) {
    80001dbe:	00014997          	auipc	s3,0x14
    80001dc2:	a3a98993          	addi	s3,s3,-1478 # 800157f8 <tickslock>
    80001dc6:	a091                	j	80001e0a <scheduler+0x94>
      release(&p->lock);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	ecffe0ef          	jal	80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80001dce:	16848493          	addi	s1,s1,360
    80001dd2:	03348863          	beq	s1,s3,80001e02 <scheduler+0x8c>
      acquire(&p->lock);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	e29fe0ef          	jal	80000c00 <acquire>
      if (p->state == RUNNABLE) {
    80001ddc:	4c9c                	lw	a5,24(s1)
    80001dde:	ff2795e3          	bne	a5,s2,80001dc8 <scheduler+0x52>
        p->state = RUNNING;
    80001de2:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001de6:	029a3823          	sd	s1,48(s4)
        cslog_run_start(p);
    80001dea:	8526                	mv	a0,s1
    80001dec:	435030ef          	jal	80005a20 <cslog_run_start>
        swtch(&c->context, &p->context);
    80001df0:	06048593          	addi	a1,s1,96
    80001df4:	855a                	mv	a0,s6
    80001df6:	5b2000ef          	jal	800023a8 <swtch>
        c->proc = 0;
    80001dfa:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001dfe:	8ade                	mv	s5,s7
    80001e00:	b7e1                	j	80001dc8 <scheduler+0x52>
    if (found == 0) {
    80001e02:	000a9463          	bnez	s5,80001e0a <scheduler+0x94>
      asm volatile("wfi");
    80001e06:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e0e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e12:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001e1a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e1c:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001e20:	4a81                	li	s5,0
    for (p = proc; p < &proc[NPROC]; p++) {
    80001e22:	0000e497          	auipc	s1,0xe
    80001e26:	fd648493          	addi	s1,s1,-42 # 8000fdf8 <proc>
      if (p->state == RUNNABLE) {
    80001e2a:	490d                	li	s2,3
    80001e2c:	b76d                	j	80001dd6 <scheduler+0x60>

0000000080001e2e <sched>:
void sched(void) {
    80001e2e:	7179                	addi	sp,sp,-48
    80001e30:	f406                	sd	ra,40(sp)
    80001e32:	f022                	sd	s0,32(sp)
    80001e34:	ec26                	sd	s1,24(sp)
    80001e36:	e84a                	sd	s2,16(sp)
    80001e38:	e44e                	sd	s3,8(sp)
    80001e3a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e3c:	ac9ff0ef          	jal	80001904 <myproc>
    80001e40:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001e42:	d55fe0ef          	jal	80000b96 <holding>
    80001e46:	c92d                	beqz	a0,80001eb8 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e48:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001e4a:	2781                	sext.w	a5,a5
    80001e4c:	079e                	slli	a5,a5,0x7
    80001e4e:	0000e717          	auipc	a4,0xe
    80001e52:	b7a70713          	addi	a4,a4,-1158 # 8000f9c8 <pid_lock>
    80001e56:	97ba                	add	a5,a5,a4
    80001e58:	0a87a703          	lw	a4,168(a5)
    80001e5c:	4785                	li	a5,1
    80001e5e:	06f71363          	bne	a4,a5,80001ec4 <sched+0x96>
  if (p->state == RUNNING)
    80001e62:	4c98                	lw	a4,24(s1)
    80001e64:	4791                	li	a5,4
    80001e66:	06f70563          	beq	a4,a5,80001ed0 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e6e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001e70:	e7b5                	bnez	a5,80001edc <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e72:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e74:	0000e917          	auipc	s2,0xe
    80001e78:	b5490913          	addi	s2,s2,-1196 # 8000f9c8 <pid_lock>
    80001e7c:	2781                	sext.w	a5,a5
    80001e7e:	079e                	slli	a5,a5,0x7
    80001e80:	97ca                	add	a5,a5,s2
    80001e82:	0ac7a983          	lw	s3,172(a5)
    80001e86:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e88:	2781                	sext.w	a5,a5
    80001e8a:	079e                	slli	a5,a5,0x7
    80001e8c:	0000e597          	auipc	a1,0xe
    80001e90:	b7458593          	addi	a1,a1,-1164 # 8000fa00 <cpus+0x8>
    80001e94:	95be                	add	a1,a1,a5
    80001e96:	06048513          	addi	a0,s1,96
    80001e9a:	50e000ef          	jal	800023a8 <swtch>
    80001e9e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ea0:	2781                	sext.w	a5,a5
    80001ea2:	079e                	slli	a5,a5,0x7
    80001ea4:	993e                	add	s2,s2,a5
    80001ea6:	0b392623          	sw	s3,172(s2)
}
    80001eaa:	70a2                	ld	ra,40(sp)
    80001eac:	7402                	ld	s0,32(sp)
    80001eae:	64e2                	ld	s1,24(sp)
    80001eb0:	6942                	ld	s2,16(sp)
    80001eb2:	69a2                	ld	s3,8(sp)
    80001eb4:	6145                	addi	sp,sp,48
    80001eb6:	8082                	ret
    panic("sched p->lock");
    80001eb8:	00005517          	auipc	a0,0x5
    80001ebc:	2e850513          	addi	a0,a0,744 # 800071a0 <etext+0x1a0>
    80001ec0:	953fe0ef          	jal	80000812 <panic>
    panic("sched locks");
    80001ec4:	00005517          	auipc	a0,0x5
    80001ec8:	2ec50513          	addi	a0,a0,748 # 800071b0 <etext+0x1b0>
    80001ecc:	947fe0ef          	jal	80000812 <panic>
    panic("sched RUNNING");
    80001ed0:	00005517          	auipc	a0,0x5
    80001ed4:	2f050513          	addi	a0,a0,752 # 800071c0 <etext+0x1c0>
    80001ed8:	93bfe0ef          	jal	80000812 <panic>
    panic("sched interruptible");
    80001edc:	00005517          	auipc	a0,0x5
    80001ee0:	2f450513          	addi	a0,a0,756 # 800071d0 <etext+0x1d0>
    80001ee4:	92ffe0ef          	jal	80000812 <panic>

0000000080001ee8 <yield>:
void yield(void) {
    80001ee8:	1101                	addi	sp,sp,-32
    80001eea:	ec06                	sd	ra,24(sp)
    80001eec:	e822                	sd	s0,16(sp)
    80001eee:	e426                	sd	s1,8(sp)
    80001ef0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001ef2:	a13ff0ef          	jal	80001904 <myproc>
    80001ef6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001ef8:	d09fe0ef          	jal	80000c00 <acquire>
  p->state = RUNNABLE;
    80001efc:	478d                	li	a5,3
    80001efe:	cc9c                	sw	a5,24(s1)
  sched();
    80001f00:	f2fff0ef          	jal	80001e2e <sched>
  release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	d93fe0ef          	jal	80000c98 <release>
}
    80001f0a:	60e2                	ld	ra,24(sp)
    80001f0c:	6442                	ld	s0,16(sp)
    80001f0e:	64a2                	ld	s1,8(sp)
    80001f10:	6105                	addi	sp,sp,32
    80001f12:	8082                	ret

0000000080001f14 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void sleep(void *chan, struct spinlock *lk) {
    80001f14:	7179                	addi	sp,sp,-48
    80001f16:	f406                	sd	ra,40(sp)
    80001f18:	f022                	sd	s0,32(sp)
    80001f1a:	ec26                	sd	s1,24(sp)
    80001f1c:	e84a                	sd	s2,16(sp)
    80001f1e:	e44e                	sd	s3,8(sp)
    80001f20:	1800                	addi	s0,sp,48
    80001f22:	89aa                	mv	s3,a0
    80001f24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f26:	9dfff0ef          	jal	80001904 <myproc>
    80001f2a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80001f2c:	cd5fe0ef          	jal	80000c00 <acquire>
  release(lk);
    80001f30:	854a                	mv	a0,s2
    80001f32:	d67fe0ef          	jal	80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80001f36:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001f3a:	4789                	li	a5,2
    80001f3c:	cc9c                	sw	a5,24(s1)

  sched();
    80001f3e:	ef1ff0ef          	jal	80001e2e <sched>

  // Tidy up.
  p->chan = 0;
    80001f42:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	d51fe0ef          	jal	80000c98 <release>
  acquire(lk);
    80001f4c:	854a                	mv	a0,s2
    80001f4e:	cb3fe0ef          	jal	80000c00 <acquire>
}
    80001f52:	70a2                	ld	ra,40(sp)
    80001f54:	7402                	ld	s0,32(sp)
    80001f56:	64e2                	ld	s1,24(sp)
    80001f58:	6942                	ld	s2,16(sp)
    80001f5a:	69a2                	ld	s3,8(sp)
    80001f5c:	6145                	addi	sp,sp,48
    80001f5e:	8082                	ret

0000000080001f60 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void wakeup(void *chan) {
    80001f60:	7139                	addi	sp,sp,-64
    80001f62:	fc06                	sd	ra,56(sp)
    80001f64:	f822                	sd	s0,48(sp)
    80001f66:	f426                	sd	s1,40(sp)
    80001f68:	f04a                	sd	s2,32(sp)
    80001f6a:	ec4e                	sd	s3,24(sp)
    80001f6c:	e852                	sd	s4,16(sp)
    80001f6e:	e456                	sd	s5,8(sp)
    80001f70:	0080                	addi	s0,sp,64
    80001f72:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++) {
    80001f74:	0000e497          	auipc	s1,0xe
    80001f78:	e8448493          	addi	s1,s1,-380 # 8000fdf8 <proc>
    if (p != myproc()) {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan) {
    80001f7c:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001f7e:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f80:	00014917          	auipc	s2,0x14
    80001f84:	87890913          	addi	s2,s2,-1928 # 800157f8 <tickslock>
    80001f88:	a801                	j	80001f98 <wakeup+0x38>
      }
      release(&p->lock);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	d0dfe0ef          	jal	80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f90:	16848493          	addi	s1,s1,360
    80001f94:	03248263          	beq	s1,s2,80001fb8 <wakeup+0x58>
    if (p != myproc()) {
    80001f98:	96dff0ef          	jal	80001904 <myproc>
    80001f9c:	fea48ae3          	beq	s1,a0,80001f90 <wakeup+0x30>
      acquire(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	c5ffe0ef          	jal	80000c00 <acquire>
      if (p->state == SLEEPING && p->chan == chan) {
    80001fa6:	4c9c                	lw	a5,24(s1)
    80001fa8:	ff3791e3          	bne	a5,s3,80001f8a <wakeup+0x2a>
    80001fac:	709c                	ld	a5,32(s1)
    80001fae:	fd479ee3          	bne	a5,s4,80001f8a <wakeup+0x2a>
        p->state = RUNNABLE;
    80001fb2:	0154ac23          	sw	s5,24(s1)
    80001fb6:	bfd1                	j	80001f8a <wakeup+0x2a>
    }
  }
}
    80001fb8:	70e2                	ld	ra,56(sp)
    80001fba:	7442                	ld	s0,48(sp)
    80001fbc:	74a2                	ld	s1,40(sp)
    80001fbe:	7902                	ld	s2,32(sp)
    80001fc0:	69e2                	ld	s3,24(sp)
    80001fc2:	6a42                	ld	s4,16(sp)
    80001fc4:	6aa2                	ld	s5,8(sp)
    80001fc6:	6121                	addi	sp,sp,64
    80001fc8:	8082                	ret

0000000080001fca <reparent>:
void reparent(struct proc *p) {
    80001fca:	7179                	addi	sp,sp,-48
    80001fcc:	f406                	sd	ra,40(sp)
    80001fce:	f022                	sd	s0,32(sp)
    80001fd0:	ec26                	sd	s1,24(sp)
    80001fd2:	e84a                	sd	s2,16(sp)
    80001fd4:	e44e                	sd	s3,8(sp)
    80001fd6:	e052                	sd	s4,0(sp)
    80001fd8:	1800                	addi	s0,sp,48
    80001fda:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    80001fdc:	0000e497          	auipc	s1,0xe
    80001fe0:	e1c48493          	addi	s1,s1,-484 # 8000fdf8 <proc>
      pp->parent = initproc;
    80001fe4:	00006a17          	auipc	s4,0x6
    80001fe8:	89ca0a13          	addi	s4,s4,-1892 # 80007880 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    80001fec:	00014997          	auipc	s3,0x14
    80001ff0:	80c98993          	addi	s3,s3,-2036 # 800157f8 <tickslock>
    80001ff4:	a029                	j	80001ffe <reparent+0x34>
    80001ff6:	16848493          	addi	s1,s1,360
    80001ffa:	01348b63          	beq	s1,s3,80002010 <reparent+0x46>
    if (pp->parent == p) {
    80001ffe:	7c9c                	ld	a5,56(s1)
    80002000:	ff279be3          	bne	a5,s2,80001ff6 <reparent+0x2c>
      pp->parent = initproc;
    80002004:	000a3503          	ld	a0,0(s4)
    80002008:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000200a:	f57ff0ef          	jal	80001f60 <wakeup>
    8000200e:	b7e5                	j	80001ff6 <reparent+0x2c>
}
    80002010:	70a2                	ld	ra,40(sp)
    80002012:	7402                	ld	s0,32(sp)
    80002014:	64e2                	ld	s1,24(sp)
    80002016:	6942                	ld	s2,16(sp)
    80002018:	69a2                	ld	s3,8(sp)
    8000201a:	6a02                	ld	s4,0(sp)
    8000201c:	6145                	addi	sp,sp,48
    8000201e:	8082                	ret

0000000080002020 <kexit>:
void kexit(int status) {
    80002020:	7179                	addi	sp,sp,-48
    80002022:	f406                	sd	ra,40(sp)
    80002024:	f022                	sd	s0,32(sp)
    80002026:	ec26                	sd	s1,24(sp)
    80002028:	e84a                	sd	s2,16(sp)
    8000202a:	e44e                	sd	s3,8(sp)
    8000202c:	e052                	sd	s4,0(sp)
    8000202e:	1800                	addi	s0,sp,48
    80002030:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002032:	8d3ff0ef          	jal	80001904 <myproc>
    80002036:	89aa                	mv	s3,a0
  if (p == initproc)
    80002038:	00006797          	auipc	a5,0x6
    8000203c:	8487b783          	ld	a5,-1976(a5) # 80007880 <initproc>
    80002040:	0d050493          	addi	s1,a0,208
    80002044:	15050913          	addi	s2,a0,336
    80002048:	00a79f63          	bne	a5,a0,80002066 <kexit+0x46>
    panic("init exiting");
    8000204c:	00005517          	auipc	a0,0x5
    80002050:	19c50513          	addi	a0,a0,412 # 800071e8 <etext+0x1e8>
    80002054:	fbefe0ef          	jal	80000812 <panic>
      fileclose(f);
    80002058:	7bd010ef          	jal	80004014 <fileclose>
      p->ofile[fd] = 0;
    8000205c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++) {
    80002060:	04a1                	addi	s1,s1,8
    80002062:	01248563          	beq	s1,s2,8000206c <kexit+0x4c>
    if (p->ofile[fd]) {
    80002066:	6088                	ld	a0,0(s1)
    80002068:	f965                	bnez	a0,80002058 <kexit+0x38>
    8000206a:	bfdd                	j	80002060 <kexit+0x40>
  begin_op();
    8000206c:	39d010ef          	jal	80003c08 <begin_op>
  iput(p->cwd);
    80002070:	1509b503          	ld	a0,336(s3)
    80002074:	32c010ef          	jal	800033a0 <iput>
  end_op();
    80002078:	3fb010ef          	jal	80003c72 <end_op>
  p->cwd = 0;
    8000207c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002080:	0000e497          	auipc	s1,0xe
    80002084:	96048493          	addi	s1,s1,-1696 # 8000f9e0 <wait_lock>
    80002088:	8526                	mv	a0,s1
    8000208a:	b77fe0ef          	jal	80000c00 <acquire>
  reparent(p);
    8000208e:	854e                	mv	a0,s3
    80002090:	f3bff0ef          	jal	80001fca <reparent>
  wakeup(p->parent);
    80002094:	0389b503          	ld	a0,56(s3)
    80002098:	ec9ff0ef          	jal	80001f60 <wakeup>
  acquire(&p->lock);
    8000209c:	854e                	mv	a0,s3
    8000209e:	b63fe0ef          	jal	80000c00 <acquire>
  p->xstate = status;
    800020a2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800020a6:	4795                	li	a5,5
    800020a8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	bebfe0ef          	jal	80000c98 <release>
  sched();
    800020b2:	d7dff0ef          	jal	80001e2e <sched>
  panic("zombie exit");
    800020b6:	00005517          	auipc	a0,0x5
    800020ba:	14250513          	addi	a0,a0,322 # 800071f8 <etext+0x1f8>
    800020be:	f54fe0ef          	jal	80000812 <panic>

00000000800020c2 <kkill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kkill(int pid) {
    800020c2:	7179                	addi	sp,sp,-48
    800020c4:	f406                	sd	ra,40(sp)
    800020c6:	f022                	sd	s0,32(sp)
    800020c8:	ec26                	sd	s1,24(sp)
    800020ca:	e84a                	sd	s2,16(sp)
    800020cc:	e44e                	sd	s3,8(sp)
    800020ce:	1800                	addi	s0,sp,48
    800020d0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++) {
    800020d2:	0000e497          	auipc	s1,0xe
    800020d6:	d2648493          	addi	s1,s1,-730 # 8000fdf8 <proc>
    800020da:	00013997          	auipc	s3,0x13
    800020de:	71e98993          	addi	s3,s3,1822 # 800157f8 <tickslock>
    acquire(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	b1dfe0ef          	jal	80000c00 <acquire>
    if (p->pid == pid) {
    800020e8:	589c                	lw	a5,48(s1)
    800020ea:	01278b63          	beq	a5,s2,80002100 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	ba9fe0ef          	jal	80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800020f4:	16848493          	addi	s1,s1,360
    800020f8:	ff3495e3          	bne	s1,s3,800020e2 <kkill+0x20>
  }
  return -1;
    800020fc:	557d                	li	a0,-1
    800020fe:	a819                	j	80002114 <kkill+0x52>
      p->killed = 1;
    80002100:	4785                	li	a5,1
    80002102:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING) {
    80002104:	4c98                	lw	a4,24(s1)
    80002106:	4789                	li	a5,2
    80002108:	00f70d63          	beq	a4,a5,80002122 <kkill+0x60>
      release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	b8bfe0ef          	jal	80000c98 <release>
      return 0;
    80002112:	4501                	li	a0,0
}
    80002114:	70a2                	ld	ra,40(sp)
    80002116:	7402                	ld	s0,32(sp)
    80002118:	64e2                	ld	s1,24(sp)
    8000211a:	6942                	ld	s2,16(sp)
    8000211c:	69a2                	ld	s3,8(sp)
    8000211e:	6145                	addi	sp,sp,48
    80002120:	8082                	ret
        p->state = RUNNABLE;
    80002122:	478d                	li	a5,3
    80002124:	cc9c                	sw	a5,24(s1)
    80002126:	b7dd                	j	8000210c <kkill+0x4a>

0000000080002128 <setkilled>:

void setkilled(struct proc *p) {
    80002128:	1101                	addi	sp,sp,-32
    8000212a:	ec06                	sd	ra,24(sp)
    8000212c:	e822                	sd	s0,16(sp)
    8000212e:	e426                	sd	s1,8(sp)
    80002130:	1000                	addi	s0,sp,32
    80002132:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002134:	acdfe0ef          	jal	80000c00 <acquire>
  p->killed = 1;
    80002138:	4785                	li	a5,1
    8000213a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	b5bfe0ef          	jal	80000c98 <release>
}
    80002142:	60e2                	ld	ra,24(sp)
    80002144:	6442                	ld	s0,16(sp)
    80002146:	64a2                	ld	s1,8(sp)
    80002148:	6105                	addi	sp,sp,32
    8000214a:	8082                	ret

000000008000214c <killed>:

int killed(struct proc *p) {
    8000214c:	1101                	addi	sp,sp,-32
    8000214e:	ec06                	sd	ra,24(sp)
    80002150:	e822                	sd	s0,16(sp)
    80002152:	e426                	sd	s1,8(sp)
    80002154:	e04a                	sd	s2,0(sp)
    80002156:	1000                	addi	s0,sp,32
    80002158:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000215a:	aa7fe0ef          	jal	80000c00 <acquire>
  k = p->killed;
    8000215e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	b35fe0ef          	jal	80000c98 <release>
  return k;
}
    80002168:	854a                	mv	a0,s2
    8000216a:	60e2                	ld	ra,24(sp)
    8000216c:	6442                	ld	s0,16(sp)
    8000216e:	64a2                	ld	s1,8(sp)
    80002170:	6902                	ld	s2,0(sp)
    80002172:	6105                	addi	sp,sp,32
    80002174:	8082                	ret

0000000080002176 <kwait>:
int kwait(uint64 addr) {
    80002176:	715d                	addi	sp,sp,-80
    80002178:	e486                	sd	ra,72(sp)
    8000217a:	e0a2                	sd	s0,64(sp)
    8000217c:	fc26                	sd	s1,56(sp)
    8000217e:	f84a                	sd	s2,48(sp)
    80002180:	f44e                	sd	s3,40(sp)
    80002182:	f052                	sd	s4,32(sp)
    80002184:	ec56                	sd	s5,24(sp)
    80002186:	e85a                	sd	s6,16(sp)
    80002188:	e45e                	sd	s7,8(sp)
    8000218a:	e062                	sd	s8,0(sp)
    8000218c:	0880                	addi	s0,sp,80
    8000218e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002190:	f74ff0ef          	jal	80001904 <myproc>
    80002194:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002196:	0000e517          	auipc	a0,0xe
    8000219a:	84a50513          	addi	a0,a0,-1974 # 8000f9e0 <wait_lock>
    8000219e:	a63fe0ef          	jal	80000c00 <acquire>
    havekids = 0;
    800021a2:	4b81                	li	s7,0
        if (pp->state == ZOMBIE) {
    800021a4:	4a15                	li	s4,5
        havekids = 1;
    800021a6:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800021a8:	00013997          	auipc	s3,0x13
    800021ac:	65098993          	addi	s3,s3,1616 # 800157f8 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800021b0:	0000ec17          	auipc	s8,0xe
    800021b4:	830c0c13          	addi	s8,s8,-2000 # 8000f9e0 <wait_lock>
    800021b8:	a871                	j	80002254 <kwait+0xde>
          pid = pp->pid;
    800021ba:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800021be:	000b0c63          	beqz	s6,800021d6 <kwait+0x60>
    800021c2:	4691                	li	a3,4
    800021c4:	02c48613          	addi	a2,s1,44
    800021c8:	85da                	mv	a1,s6
    800021ca:	05093503          	ld	a0,80(s2)
    800021ce:	c4aff0ef          	jal	80001618 <copyout>
    800021d2:	02054b63          	bltz	a0,80002208 <kwait+0x92>
          freeproc(pp);
    800021d6:	8526                	mv	a0,s1
    800021d8:	8fdff0ef          	jal	80001ad4 <freeproc>
          release(&pp->lock);
    800021dc:	8526                	mv	a0,s1
    800021de:	abbfe0ef          	jal	80000c98 <release>
          release(&wait_lock);
    800021e2:	0000d517          	auipc	a0,0xd
    800021e6:	7fe50513          	addi	a0,a0,2046 # 8000f9e0 <wait_lock>
    800021ea:	aaffe0ef          	jal	80000c98 <release>
}
    800021ee:	854e                	mv	a0,s3
    800021f0:	60a6                	ld	ra,72(sp)
    800021f2:	6406                	ld	s0,64(sp)
    800021f4:	74e2                	ld	s1,56(sp)
    800021f6:	7942                	ld	s2,48(sp)
    800021f8:	79a2                	ld	s3,40(sp)
    800021fa:	7a02                	ld	s4,32(sp)
    800021fc:	6ae2                	ld	s5,24(sp)
    800021fe:	6b42                	ld	s6,16(sp)
    80002200:	6ba2                	ld	s7,8(sp)
    80002202:	6c02                	ld	s8,0(sp)
    80002204:	6161                	addi	sp,sp,80
    80002206:	8082                	ret
            release(&pp->lock);
    80002208:	8526                	mv	a0,s1
    8000220a:	a8ffe0ef          	jal	80000c98 <release>
            release(&wait_lock);
    8000220e:	0000d517          	auipc	a0,0xd
    80002212:	7d250513          	addi	a0,a0,2002 # 8000f9e0 <wait_lock>
    80002216:	a83fe0ef          	jal	80000c98 <release>
            return -1;
    8000221a:	59fd                	li	s3,-1
    8000221c:	bfc9                	j	800021ee <kwait+0x78>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    8000221e:	16848493          	addi	s1,s1,360
    80002222:	03348063          	beq	s1,s3,80002242 <kwait+0xcc>
      if (pp->parent == p) {
    80002226:	7c9c                	ld	a5,56(s1)
    80002228:	ff279be3          	bne	a5,s2,8000221e <kwait+0xa8>
        acquire(&pp->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	9d3fe0ef          	jal	80000c00 <acquire>
        if (pp->state == ZOMBIE) {
    80002232:	4c9c                	lw	a5,24(s1)
    80002234:	f94783e3          	beq	a5,s4,800021ba <kwait+0x44>
        release(&pp->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	a5ffe0ef          	jal	80000c98 <release>
        havekids = 1;
    8000223e:	8756                	mv	a4,s5
    80002240:	bff9                	j	8000221e <kwait+0xa8>
    if (!havekids || killed(p)) {
    80002242:	cf19                	beqz	a4,80002260 <kwait+0xea>
    80002244:	854a                	mv	a0,s2
    80002246:	f07ff0ef          	jal	8000214c <killed>
    8000224a:	e919                	bnez	a0,80002260 <kwait+0xea>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000224c:	85e2                	mv	a1,s8
    8000224e:	854a                	mv	a0,s2
    80002250:	cc5ff0ef          	jal	80001f14 <sleep>
    havekids = 0;
    80002254:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    80002256:	0000e497          	auipc	s1,0xe
    8000225a:	ba248493          	addi	s1,s1,-1118 # 8000fdf8 <proc>
    8000225e:	b7e1                	j	80002226 <kwait+0xb0>
      release(&wait_lock);
    80002260:	0000d517          	auipc	a0,0xd
    80002264:	78050513          	addi	a0,a0,1920 # 8000f9e0 <wait_lock>
    80002268:	a31fe0ef          	jal	80000c98 <release>
      return -1;
    8000226c:	59fd                	li	s3,-1
    8000226e:	b741                	j	800021ee <kwait+0x78>

0000000080002270 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    80002270:	7179                	addi	sp,sp,-48
    80002272:	f406                	sd	ra,40(sp)
    80002274:	f022                	sd	s0,32(sp)
    80002276:	ec26                	sd	s1,24(sp)
    80002278:	e84a                	sd	s2,16(sp)
    8000227a:	e44e                	sd	s3,8(sp)
    8000227c:	e052                	sd	s4,0(sp)
    8000227e:	1800                	addi	s0,sp,48
    80002280:	84aa                	mv	s1,a0
    80002282:	892e                	mv	s2,a1
    80002284:	89b2                	mv	s3,a2
    80002286:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002288:	e7cff0ef          	jal	80001904 <myproc>
  if (user_dst) {
    8000228c:	cc99                	beqz	s1,800022aa <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    8000228e:	86d2                	mv	a3,s4
    80002290:	864e                	mv	a2,s3
    80002292:	85ca                	mv	a1,s2
    80002294:	6928                	ld	a0,80(a0)
    80002296:	b82ff0ef          	jal	80001618 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000229a:	70a2                	ld	ra,40(sp)
    8000229c:	7402                	ld	s0,32(sp)
    8000229e:	64e2                	ld	s1,24(sp)
    800022a0:	6942                	ld	s2,16(sp)
    800022a2:	69a2                	ld	s3,8(sp)
    800022a4:	6a02                	ld	s4,0(sp)
    800022a6:	6145                	addi	sp,sp,48
    800022a8:	8082                	ret
    memmove((char *)dst, src, len);
    800022aa:	000a061b          	sext.w	a2,s4
    800022ae:	85ce                	mv	a1,s3
    800022b0:	854a                	mv	a0,s2
    800022b2:	a7ffe0ef          	jal	80000d30 <memmove>
    return 0;
    800022b6:	8526                	mv	a0,s1
    800022b8:	b7cd                	j	8000229a <either_copyout+0x2a>

00000000800022ba <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    800022ba:	7179                	addi	sp,sp,-48
    800022bc:	f406                	sd	ra,40(sp)
    800022be:	f022                	sd	s0,32(sp)
    800022c0:	ec26                	sd	s1,24(sp)
    800022c2:	e84a                	sd	s2,16(sp)
    800022c4:	e44e                	sd	s3,8(sp)
    800022c6:	e052                	sd	s4,0(sp)
    800022c8:	1800                	addi	s0,sp,48
    800022ca:	892a                	mv	s2,a0
    800022cc:	84ae                	mv	s1,a1
    800022ce:	89b2                	mv	s3,a2
    800022d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022d2:	e32ff0ef          	jal	80001904 <myproc>
  if (user_src) {
    800022d6:	cc99                	beqz	s1,800022f4 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800022d8:	86d2                	mv	a3,s4
    800022da:	864e                	mv	a2,s3
    800022dc:	85ca                	mv	a1,s2
    800022de:	6928                	ld	a0,80(a0)
    800022e0:	c1cff0ef          	jal	800016fc <copyin>
  } else {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800022e4:	70a2                	ld	ra,40(sp)
    800022e6:	7402                	ld	s0,32(sp)
    800022e8:	64e2                	ld	s1,24(sp)
    800022ea:	6942                	ld	s2,16(sp)
    800022ec:	69a2                	ld	s3,8(sp)
    800022ee:	6a02                	ld	s4,0(sp)
    800022f0:	6145                	addi	sp,sp,48
    800022f2:	8082                	ret
    memmove(dst, (char *)src, len);
    800022f4:	000a061b          	sext.w	a2,s4
    800022f8:	85ce                	mv	a1,s3
    800022fa:	854a                	mv	a0,s2
    800022fc:	a35fe0ef          	jal	80000d30 <memmove>
    return 0;
    80002300:	8526                	mv	a0,s1
    80002302:	b7cd                	j	800022e4 <either_copyin+0x2a>

0000000080002304 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void) {
    80002304:	715d                	addi	sp,sp,-80
    80002306:	e486                	sd	ra,72(sp)
    80002308:	e0a2                	sd	s0,64(sp)
    8000230a:	fc26                	sd	s1,56(sp)
    8000230c:	f84a                	sd	s2,48(sp)
    8000230e:	f44e                	sd	s3,40(sp)
    80002310:	f052                	sd	s4,32(sp)
    80002312:	ec56                	sd	s5,24(sp)
    80002314:	e85a                	sd	s6,16(sp)
    80002316:	e45e                	sd	s7,8(sp)
    80002318:	0880                	addi	s0,sp,80
      [UNUSED] "unused",   [USED] "used",      [SLEEPING] "sleep ",
      [RUNNABLE] "runble", [RUNNING] "run   ", [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000231a:	00005517          	auipc	a0,0x5
    8000231e:	d6650513          	addi	a0,a0,-666 # 80007080 <etext+0x80>
    80002322:	a0afe0ef          	jal	8000052c <printf>
  for (p = proc; p < &proc[NPROC]; p++) {
    80002326:	0000e497          	auipc	s1,0xe
    8000232a:	c2a48493          	addi	s1,s1,-982 # 8000ff50 <proc+0x158>
    8000232e:	00013917          	auipc	s2,0x13
    80002332:	62290913          	addi	s2,s2,1570 # 80015950 <bcache+0x140>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002336:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002338:	00005997          	auipc	s3,0x5
    8000233c:	ed098993          	addi	s3,s3,-304 # 80007208 <etext+0x208>
    printf("%d %s %s", p->pid, state, p->name);
    80002340:	00005a97          	auipc	s5,0x5
    80002344:	ed0a8a93          	addi	s5,s5,-304 # 80007210 <etext+0x210>
    printf("\n");
    80002348:	00005a17          	auipc	s4,0x5
    8000234c:	d38a0a13          	addi	s4,s4,-712 # 80007080 <etext+0x80>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002350:	00005b97          	auipc	s7,0x5
    80002354:	400b8b93          	addi	s7,s7,1024 # 80007750 <states.0>
    80002358:	a829                	j	80002372 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    8000235a:	ed86a583          	lw	a1,-296(a3)
    8000235e:	8556                	mv	a0,s5
    80002360:	9ccfe0ef          	jal	8000052c <printf>
    printf("\n");
    80002364:	8552                	mv	a0,s4
    80002366:	9c6fe0ef          	jal	8000052c <printf>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000236a:	16848493          	addi	s1,s1,360
    8000236e:	03248263          	beq	s1,s2,80002392 <procdump+0x8e>
    if (p->state == UNUSED)
    80002372:	86a6                	mv	a3,s1
    80002374:	ec04a783          	lw	a5,-320(s1)
    80002378:	dbed                	beqz	a5,8000236a <procdump+0x66>
      state = "???";
    8000237a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000237c:	fcfb6fe3          	bltu	s6,a5,8000235a <procdump+0x56>
    80002380:	02079713          	slli	a4,a5,0x20
    80002384:	01d75793          	srli	a5,a4,0x1d
    80002388:	97de                	add	a5,a5,s7
    8000238a:	6390                	ld	a2,0(a5)
    8000238c:	f679                	bnez	a2,8000235a <procdump+0x56>
      state = "???";
    8000238e:	864e                	mv	a2,s3
    80002390:	b7e9                	j	8000235a <procdump+0x56>
  }
}
    80002392:	60a6                	ld	ra,72(sp)
    80002394:	6406                	ld	s0,64(sp)
    80002396:	74e2                	ld	s1,56(sp)
    80002398:	7942                	ld	s2,48(sp)
    8000239a:	79a2                	ld	s3,40(sp)
    8000239c:	7a02                	ld	s4,32(sp)
    8000239e:	6ae2                	ld	s5,24(sp)
    800023a0:	6b42                	ld	s6,16(sp)
    800023a2:	6ba2                	ld	s7,8(sp)
    800023a4:	6161                	addi	sp,sp,80
    800023a6:	8082                	ret

00000000800023a8 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800023a8:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800023ac:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800023b0:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800023b2:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800023b4:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800023b8:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800023bc:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800023c0:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800023c4:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800023c8:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800023cc:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800023d0:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    800023d4:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    800023d8:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    800023dc:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    800023e0:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    800023e4:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    800023e6:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    800023e8:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    800023ec:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    800023f0:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800023f4:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800023f8:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800023fc:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002400:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002404:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002408:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    8000240c:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002410:	8082                	ret

0000000080002412 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002412:	1141                	addi	sp,sp,-16
    80002414:	e406                	sd	ra,8(sp)
    80002416:	e022                	sd	s0,0(sp)
    80002418:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000241a:	00005597          	auipc	a1,0x5
    8000241e:	e3658593          	addi	a1,a1,-458 # 80007250 <etext+0x250>
    80002422:	00013517          	auipc	a0,0x13
    80002426:	3d650513          	addi	a0,a0,982 # 800157f8 <tickslock>
    8000242a:	f56fe0ef          	jal	80000b80 <initlock>
}
    8000242e:	60a2                	ld	ra,8(sp)
    80002430:	6402                	ld	s0,0(sp)
    80002432:	0141                	addi	sp,sp,16
    80002434:	8082                	ret

0000000080002436 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002436:	1141                	addi	sp,sp,-16
    80002438:	e422                	sd	s0,8(sp)
    8000243a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000243c:	00003797          	auipc	a5,0x3
    80002440:	f5478793          	addi	a5,a5,-172 # 80005390 <kernelvec>
    80002444:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002448:	6422                	ld	s0,8(sp)
    8000244a:	0141                	addi	sp,sp,16
    8000244c:	8082                	ret

000000008000244e <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    8000244e:	1141                	addi	sp,sp,-16
    80002450:	e406                	sd	ra,8(sp)
    80002452:	e022                	sd	s0,0(sp)
    80002454:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002456:	caeff0ef          	jal	80001904 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000245a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000245e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002460:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002464:	04000737          	lui	a4,0x4000
    80002468:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000246a:	0732                	slli	a4,a4,0xc
    8000246c:	00004797          	auipc	a5,0x4
    80002470:	b9478793          	addi	a5,a5,-1132 # 80006000 <_trampoline>
    80002474:	00004697          	auipc	a3,0x4
    80002478:	b8c68693          	addi	a3,a3,-1140 # 80006000 <_trampoline>
    8000247c:	8f95                	sub	a5,a5,a3
    8000247e:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002480:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002484:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002486:	18002773          	csrr	a4,satp
    8000248a:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000248c:	6d38                	ld	a4,88(a0)
    8000248e:	613c                	ld	a5,64(a0)
    80002490:	6685                	lui	a3,0x1
    80002492:	97b6                	add	a5,a5,a3
    80002494:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002496:	6d3c                	ld	a5,88(a0)
    80002498:	00000717          	auipc	a4,0x0
    8000249c:	0f870713          	addi	a4,a4,248 # 80002590 <usertrap>
    800024a0:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800024a2:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800024a4:	8712                	mv	a4,tp
    800024a6:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024a8:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800024ac:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800024b0:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024b4:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800024b8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800024ba:	6f9c                	ld	a5,24(a5)
    800024bc:	14179073          	csrw	sepc,a5
}
    800024c0:	60a2                	ld	ra,8(sp)
    800024c2:	6402                	ld	s0,0(sp)
    800024c4:	0141                	addi	sp,sp,16
    800024c6:	8082                	ret

00000000800024c8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800024c8:	1101                	addi	sp,sp,-32
    800024ca:	ec06                	sd	ra,24(sp)
    800024cc:	e822                	sd	s0,16(sp)
    800024ce:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800024d0:	c08ff0ef          	jal	800018d8 <cpuid>
    800024d4:	cd11                	beqz	a0,800024f0 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    800024d6:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800024da:	000f4737          	lui	a4,0xf4
    800024de:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800024e2:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800024e4:	14d79073          	csrw	stimecmp,a5
}
    800024e8:	60e2                	ld	ra,24(sp)
    800024ea:	6442                	ld	s0,16(sp)
    800024ec:	6105                	addi	sp,sp,32
    800024ee:	8082                	ret
    800024f0:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    800024f2:	00013497          	auipc	s1,0x13
    800024f6:	30648493          	addi	s1,s1,774 # 800157f8 <tickslock>
    800024fa:	8526                	mv	a0,s1
    800024fc:	f04fe0ef          	jal	80000c00 <acquire>
    ticks++;
    80002500:	00005517          	auipc	a0,0x5
    80002504:	38850513          	addi	a0,a0,904 # 80007888 <ticks>
    80002508:	411c                	lw	a5,0(a0)
    8000250a:	2785                	addiw	a5,a5,1
    8000250c:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    8000250e:	a53ff0ef          	jal	80001f60 <wakeup>
    release(&tickslock);
    80002512:	8526                	mv	a0,s1
    80002514:	f84fe0ef          	jal	80000c98 <release>
    80002518:	64a2                	ld	s1,8(sp)
    8000251a:	bf75                	j	800024d6 <clockintr+0xe>

000000008000251c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000251c:	1101                	addi	sp,sp,-32
    8000251e:	ec06                	sd	ra,24(sp)
    80002520:	e822                	sd	s0,16(sp)
    80002522:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002524:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    80002528:	57fd                	li	a5,-1
    8000252a:	17fe                	slli	a5,a5,0x3f
    8000252c:	07a5                	addi	a5,a5,9
    8000252e:	00f70c63          	beq	a4,a5,80002546 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002532:	57fd                	li	a5,-1
    80002534:	17fe                	slli	a5,a5,0x3f
    80002536:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    80002538:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    8000253a:	04f70763          	beq	a4,a5,80002588 <devintr+0x6c>
  }
}
    8000253e:	60e2                	ld	ra,24(sp)
    80002540:	6442                	ld	s0,16(sp)
    80002542:	6105                	addi	sp,sp,32
    80002544:	8082                	ret
    80002546:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002548:	6f5020ef          	jal	8000543c <plic_claim>
    8000254c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000254e:	47a9                	li	a5,10
    80002550:	00f50963          	beq	a0,a5,80002562 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    80002554:	4785                	li	a5,1
    80002556:	00f50963          	beq	a0,a5,80002568 <devintr+0x4c>
    return 1;
    8000255a:	4505                	li	a0,1
    } else if(irq){
    8000255c:	e889                	bnez	s1,8000256e <devintr+0x52>
    8000255e:	64a2                	ld	s1,8(sp)
    80002560:	bff9                	j	8000253e <devintr+0x22>
      uartintr();
    80002562:	c80fe0ef          	jal	800009e2 <uartintr>
    if(irq)
    80002566:	a819                	j	8000257c <devintr+0x60>
      virtio_disk_intr();
    80002568:	39a030ef          	jal	80005902 <virtio_disk_intr>
    if(irq)
    8000256c:	a801                	j	8000257c <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    8000256e:	85a6                	mv	a1,s1
    80002570:	00005517          	auipc	a0,0x5
    80002574:	ce850513          	addi	a0,a0,-792 # 80007258 <etext+0x258>
    80002578:	fb5fd0ef          	jal	8000052c <printf>
      plic_complete(irq);
    8000257c:	8526                	mv	a0,s1
    8000257e:	6df020ef          	jal	8000545c <plic_complete>
    return 1;
    80002582:	4505                	li	a0,1
    80002584:	64a2                	ld	s1,8(sp)
    80002586:	bf65                	j	8000253e <devintr+0x22>
    clockintr();
    80002588:	f41ff0ef          	jal	800024c8 <clockintr>
    return 2;
    8000258c:	4509                	li	a0,2
    8000258e:	bf45                	j	8000253e <devintr+0x22>

0000000080002590 <usertrap>:
{
    80002590:	1101                	addi	sp,sp,-32
    80002592:	ec06                	sd	ra,24(sp)
    80002594:	e822                	sd	s0,16(sp)
    80002596:	e426                	sd	s1,8(sp)
    80002598:	e04a                	sd	s2,0(sp)
    8000259a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000259c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800025a0:	1007f793          	andi	a5,a5,256
    800025a4:	eba5                	bnez	a5,80002614 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025a6:	00003797          	auipc	a5,0x3
    800025aa:	dea78793          	addi	a5,a5,-534 # 80005390 <kernelvec>
    800025ae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800025b2:	b52ff0ef          	jal	80001904 <myproc>
    800025b6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800025b8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025ba:	14102773          	csrr	a4,sepc
    800025be:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025c0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800025c4:	47a1                	li	a5,8
    800025c6:	04f70d63          	beq	a4,a5,80002620 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800025ca:	f53ff0ef          	jal	8000251c <devintr>
    800025ce:	892a                	mv	s2,a0
    800025d0:	e945                	bnez	a0,80002680 <usertrap+0xf0>
    800025d2:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800025d6:	47bd                	li	a5,15
    800025d8:	08f70863          	beq	a4,a5,80002668 <usertrap+0xd8>
    800025dc:	14202773          	csrr	a4,scause
    800025e0:	47b5                	li	a5,13
    800025e2:	08f70363          	beq	a4,a5,80002668 <usertrap+0xd8>
    800025e6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800025ea:	5890                	lw	a2,48(s1)
    800025ec:	00005517          	auipc	a0,0x5
    800025f0:	cac50513          	addi	a0,a0,-852 # 80007298 <etext+0x298>
    800025f4:	f39fd0ef          	jal	8000052c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025f8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025fc:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002600:	00005517          	auipc	a0,0x5
    80002604:	cc850513          	addi	a0,a0,-824 # 800072c8 <etext+0x2c8>
    80002608:	f25fd0ef          	jal	8000052c <printf>
    setkilled(p);
    8000260c:	8526                	mv	a0,s1
    8000260e:	b1bff0ef          	jal	80002128 <setkilled>
    80002612:	a035                	j	8000263e <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002614:	00005517          	auipc	a0,0x5
    80002618:	c6450513          	addi	a0,a0,-924 # 80007278 <etext+0x278>
    8000261c:	9f6fe0ef          	jal	80000812 <panic>
    if(killed(p))
    80002620:	b2dff0ef          	jal	8000214c <killed>
    80002624:	ed15                	bnez	a0,80002660 <usertrap+0xd0>
    p->trapframe->epc += 4;
    80002626:	6cb8                	ld	a4,88(s1)
    80002628:	6f1c                	ld	a5,24(a4)
    8000262a:	0791                	addi	a5,a5,4
    8000262c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000262e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002632:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002636:	10079073          	csrw	sstatus,a5
    syscall();
    8000263a:	246000ef          	jal	80002880 <syscall>
  if(killed(p))
    8000263e:	8526                	mv	a0,s1
    80002640:	b0dff0ef          	jal	8000214c <killed>
    80002644:	e139                	bnez	a0,8000268a <usertrap+0xfa>
  prepare_return();
    80002646:	e09ff0ef          	jal	8000244e <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000264a:	68a8                	ld	a0,80(s1)
    8000264c:	8131                	srli	a0,a0,0xc
    8000264e:	57fd                	li	a5,-1
    80002650:	17fe                	slli	a5,a5,0x3f
    80002652:	8d5d                	or	a0,a0,a5
}
    80002654:	60e2                	ld	ra,24(sp)
    80002656:	6442                	ld	s0,16(sp)
    80002658:	64a2                	ld	s1,8(sp)
    8000265a:	6902                	ld	s2,0(sp)
    8000265c:	6105                	addi	sp,sp,32
    8000265e:	8082                	ret
      kexit(-1);
    80002660:	557d                	li	a0,-1
    80002662:	9bfff0ef          	jal	80002020 <kexit>
    80002666:	b7c1                	j	80002626 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002668:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000266c:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002670:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    80002672:	00163613          	seqz	a2,a2
    80002676:	68a8                	ld	a0,80(s1)
    80002678:	f1ffe0ef          	jal	80001596 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000267c:	f169                	bnez	a0,8000263e <usertrap+0xae>
    8000267e:	b7a5                	j	800025e6 <usertrap+0x56>
  if(killed(p))
    80002680:	8526                	mv	a0,s1
    80002682:	acbff0ef          	jal	8000214c <killed>
    80002686:	c511                	beqz	a0,80002692 <usertrap+0x102>
    80002688:	a011                	j	8000268c <usertrap+0xfc>
    8000268a:	4901                	li	s2,0
    kexit(-1);
    8000268c:	557d                	li	a0,-1
    8000268e:	993ff0ef          	jal	80002020 <kexit>
  if(which_dev == 2)
    80002692:	4789                	li	a5,2
    80002694:	faf919e3          	bne	s2,a5,80002646 <usertrap+0xb6>
    yield();
    80002698:	851ff0ef          	jal	80001ee8 <yield>
    8000269c:	b76d                	j	80002646 <usertrap+0xb6>

000000008000269e <kerneltrap>:
{
    8000269e:	7179                	addi	sp,sp,-48
    800026a0:	f406                	sd	ra,40(sp)
    800026a2:	f022                	sd	s0,32(sp)
    800026a4:	ec26                	sd	s1,24(sp)
    800026a6:	e84a                	sd	s2,16(sp)
    800026a8:	e44e                	sd	s3,8(sp)
    800026aa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026ac:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026b4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800026b8:	1004f793          	andi	a5,s1,256
    800026bc:	c795                	beqz	a5,800026e8 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026be:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026c2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800026c4:	eb85                	bnez	a5,800026f4 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    800026c6:	e57ff0ef          	jal	8000251c <devintr>
    800026ca:	c91d                	beqz	a0,80002700 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    800026cc:	4789                	li	a5,2
    800026ce:	04f50a63          	beq	a0,a5,80002722 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d6:	10049073          	csrw	sstatus,s1
}
    800026da:	70a2                	ld	ra,40(sp)
    800026dc:	7402                	ld	s0,32(sp)
    800026de:	64e2                	ld	s1,24(sp)
    800026e0:	6942                	ld	s2,16(sp)
    800026e2:	69a2                	ld	s3,8(sp)
    800026e4:	6145                	addi	sp,sp,48
    800026e6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800026e8:	00005517          	auipc	a0,0x5
    800026ec:	c0850513          	addi	a0,a0,-1016 # 800072f0 <etext+0x2f0>
    800026f0:	922fe0ef          	jal	80000812 <panic>
    panic("kerneltrap: interrupts enabled");
    800026f4:	00005517          	auipc	a0,0x5
    800026f8:	c2450513          	addi	a0,a0,-988 # 80007318 <etext+0x318>
    800026fc:	916fe0ef          	jal	80000812 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002700:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002704:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002708:	85ce                	mv	a1,s3
    8000270a:	00005517          	auipc	a0,0x5
    8000270e:	c2e50513          	addi	a0,a0,-978 # 80007338 <etext+0x338>
    80002712:	e1bfd0ef          	jal	8000052c <printf>
    panic("kerneltrap");
    80002716:	00005517          	auipc	a0,0x5
    8000271a:	c4a50513          	addi	a0,a0,-950 # 80007360 <etext+0x360>
    8000271e:	8f4fe0ef          	jal	80000812 <panic>
  if(which_dev == 2 && myproc() != 0)
    80002722:	9e2ff0ef          	jal	80001904 <myproc>
    80002726:	d555                	beqz	a0,800026d2 <kerneltrap+0x34>
    yield();
    80002728:	fc0ff0ef          	jal	80001ee8 <yield>
    8000272c:	b75d                	j	800026d2 <kerneltrap+0x34>

000000008000272e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000272e:	1101                	addi	sp,sp,-32
    80002730:	ec06                	sd	ra,24(sp)
    80002732:	e822                	sd	s0,16(sp)
    80002734:	e426                	sd	s1,8(sp)
    80002736:	1000                	addi	s0,sp,32
    80002738:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000273a:	9caff0ef          	jal	80001904 <myproc>
  switch (n) {
    8000273e:	4795                	li	a5,5
    80002740:	0497e163          	bltu	a5,s1,80002782 <argraw+0x54>
    80002744:	048a                	slli	s1,s1,0x2
    80002746:	00005717          	auipc	a4,0x5
    8000274a:	03a70713          	addi	a4,a4,58 # 80007780 <states.0+0x30>
    8000274e:	94ba                	add	s1,s1,a4
    80002750:	409c                	lw	a5,0(s1)
    80002752:	97ba                	add	a5,a5,a4
    80002754:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002756:	6d3c                	ld	a5,88(a0)
    80002758:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000275a:	60e2                	ld	ra,24(sp)
    8000275c:	6442                	ld	s0,16(sp)
    8000275e:	64a2                	ld	s1,8(sp)
    80002760:	6105                	addi	sp,sp,32
    80002762:	8082                	ret
    return p->trapframe->a1;
    80002764:	6d3c                	ld	a5,88(a0)
    80002766:	7fa8                	ld	a0,120(a5)
    80002768:	bfcd                	j	8000275a <argraw+0x2c>
    return p->trapframe->a2;
    8000276a:	6d3c                	ld	a5,88(a0)
    8000276c:	63c8                	ld	a0,128(a5)
    8000276e:	b7f5                	j	8000275a <argraw+0x2c>
    return p->trapframe->a3;
    80002770:	6d3c                	ld	a5,88(a0)
    80002772:	67c8                	ld	a0,136(a5)
    80002774:	b7dd                	j	8000275a <argraw+0x2c>
    return p->trapframe->a4;
    80002776:	6d3c                	ld	a5,88(a0)
    80002778:	6bc8                	ld	a0,144(a5)
    8000277a:	b7c5                	j	8000275a <argraw+0x2c>
    return p->trapframe->a5;
    8000277c:	6d3c                	ld	a5,88(a0)
    8000277e:	6fc8                	ld	a0,152(a5)
    80002780:	bfe9                	j	8000275a <argraw+0x2c>
  panic("argraw");
    80002782:	00005517          	auipc	a0,0x5
    80002786:	bee50513          	addi	a0,a0,-1042 # 80007370 <etext+0x370>
    8000278a:	888fe0ef          	jal	80000812 <panic>

000000008000278e <fetchaddr>:
{
    8000278e:	1101                	addi	sp,sp,-32
    80002790:	ec06                	sd	ra,24(sp)
    80002792:	e822                	sd	s0,16(sp)
    80002794:	e426                	sd	s1,8(sp)
    80002796:	e04a                	sd	s2,0(sp)
    80002798:	1000                	addi	s0,sp,32
    8000279a:	84aa                	mv	s1,a0
    8000279c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000279e:	966ff0ef          	jal	80001904 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800027a2:	653c                	ld	a5,72(a0)
    800027a4:	02f4f663          	bgeu	s1,a5,800027d0 <fetchaddr+0x42>
    800027a8:	00848713          	addi	a4,s1,8
    800027ac:	02e7e463          	bltu	a5,a4,800027d4 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800027b0:	46a1                	li	a3,8
    800027b2:	8626                	mv	a2,s1
    800027b4:	85ca                	mv	a1,s2
    800027b6:	6928                	ld	a0,80(a0)
    800027b8:	f45fe0ef          	jal	800016fc <copyin>
    800027bc:	00a03533          	snez	a0,a0
    800027c0:	40a00533          	neg	a0,a0
}
    800027c4:	60e2                	ld	ra,24(sp)
    800027c6:	6442                	ld	s0,16(sp)
    800027c8:	64a2                	ld	s1,8(sp)
    800027ca:	6902                	ld	s2,0(sp)
    800027cc:	6105                	addi	sp,sp,32
    800027ce:	8082                	ret
    return -1;
    800027d0:	557d                	li	a0,-1
    800027d2:	bfcd                	j	800027c4 <fetchaddr+0x36>
    800027d4:	557d                	li	a0,-1
    800027d6:	b7fd                	j	800027c4 <fetchaddr+0x36>

00000000800027d8 <fetchstr>:
{
    800027d8:	7179                	addi	sp,sp,-48
    800027da:	f406                	sd	ra,40(sp)
    800027dc:	f022                	sd	s0,32(sp)
    800027de:	ec26                	sd	s1,24(sp)
    800027e0:	e84a                	sd	s2,16(sp)
    800027e2:	e44e                	sd	s3,8(sp)
    800027e4:	1800                	addi	s0,sp,48
    800027e6:	892a                	mv	s2,a0
    800027e8:	84ae                	mv	s1,a1
    800027ea:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800027ec:	918ff0ef          	jal	80001904 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800027f0:	86ce                	mv	a3,s3
    800027f2:	864a                	mv	a2,s2
    800027f4:	85a6                	mv	a1,s1
    800027f6:	6928                	ld	a0,80(a0)
    800027f8:	cc7fe0ef          	jal	800014be <copyinstr>
    800027fc:	00054c63          	bltz	a0,80002814 <fetchstr+0x3c>
  return strlen(buf);
    80002800:	8526                	mv	a0,s1
    80002802:	e42fe0ef          	jal	80000e44 <strlen>
}
    80002806:	70a2                	ld	ra,40(sp)
    80002808:	7402                	ld	s0,32(sp)
    8000280a:	64e2                	ld	s1,24(sp)
    8000280c:	6942                	ld	s2,16(sp)
    8000280e:	69a2                	ld	s3,8(sp)
    80002810:	6145                	addi	sp,sp,48
    80002812:	8082                	ret
    return -1;
    80002814:	557d                	li	a0,-1
    80002816:	bfc5                	j	80002806 <fetchstr+0x2e>

0000000080002818 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
    80002822:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002824:	f0bff0ef          	jal	8000272e <argraw>
    80002828:	c088                	sw	a0,0(s1)
}
    8000282a:	60e2                	ld	ra,24(sp)
    8000282c:	6442                	ld	s0,16(sp)
    8000282e:	64a2                	ld	s1,8(sp)
    80002830:	6105                	addi	sp,sp,32
    80002832:	8082                	ret

0000000080002834 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002834:	1101                	addi	sp,sp,-32
    80002836:	ec06                	sd	ra,24(sp)
    80002838:	e822                	sd	s0,16(sp)
    8000283a:	e426                	sd	s1,8(sp)
    8000283c:	1000                	addi	s0,sp,32
    8000283e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002840:	eefff0ef          	jal	8000272e <argraw>
    80002844:	e088                	sd	a0,0(s1)
}
    80002846:	60e2                	ld	ra,24(sp)
    80002848:	6442                	ld	s0,16(sp)
    8000284a:	64a2                	ld	s1,8(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret

0000000080002850 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002850:	7179                	addi	sp,sp,-48
    80002852:	f406                	sd	ra,40(sp)
    80002854:	f022                	sd	s0,32(sp)
    80002856:	ec26                	sd	s1,24(sp)
    80002858:	e84a                	sd	s2,16(sp)
    8000285a:	1800                	addi	s0,sp,48
    8000285c:	84ae                	mv	s1,a1
    8000285e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002860:	fd840593          	addi	a1,s0,-40
    80002864:	fd1ff0ef          	jal	80002834 <argaddr>
  return fetchstr(addr, buf, max);
    80002868:	864a                	mv	a2,s2
    8000286a:	85a6                	mv	a1,s1
    8000286c:	fd843503          	ld	a0,-40(s0)
    80002870:	f69ff0ef          	jal	800027d8 <fetchstr>
}
    80002874:	70a2                	ld	ra,40(sp)
    80002876:	7402                	ld	s0,32(sp)
    80002878:	64e2                	ld	s1,24(sp)
    8000287a:	6942                	ld	s2,16(sp)
    8000287c:	6145                	addi	sp,sp,48
    8000287e:	8082                	ret

0000000080002880 <syscall>:

};

void
syscall(void)
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	e04a                	sd	s2,0(sp)
    8000288a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000288c:	878ff0ef          	jal	80001904 <myproc>
    80002890:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002892:	05853903          	ld	s2,88(a0)
    80002896:	0a893783          	ld	a5,168(s2)
    8000289a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000289e:	37fd                	addiw	a5,a5,-1
    800028a0:	4755                	li	a4,21
    800028a2:	00f76f63          	bltu	a4,a5,800028c0 <syscall+0x40>
    800028a6:	00369713          	slli	a4,a3,0x3
    800028aa:	00005797          	auipc	a5,0x5
    800028ae:	eee78793          	addi	a5,a5,-274 # 80007798 <syscalls>
    800028b2:	97ba                	add	a5,a5,a4
    800028b4:	639c                	ld	a5,0(a5)
    800028b6:	c789                	beqz	a5,800028c0 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800028b8:	9782                	jalr	a5
    800028ba:	06a93823          	sd	a0,112(s2)
    800028be:	a829                	j	800028d8 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800028c0:	15848613          	addi	a2,s1,344
    800028c4:	588c                	lw	a1,48(s1)
    800028c6:	00005517          	auipc	a0,0x5
    800028ca:	ab250513          	addi	a0,a0,-1358 # 80007378 <etext+0x378>
    800028ce:	c5ffd0ef          	jal	8000052c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800028d2:	6cbc                	ld	a5,88(s1)
    800028d4:	577d                	li	a4,-1
    800028d6:	fbb8                	sd	a4,112(a5)
  }
}
    800028d8:	60e2                	ld	ra,24(sp)
    800028da:	6442                	ld	s0,16(sp)
    800028dc:	64a2                	ld	s1,8(sp)
    800028de:	6902                	ld	s2,0(sp)
    800028e0:	6105                	addi	sp,sp,32
    800028e2:	8082                	ret

00000000800028e4 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    800028e4:	1101                	addi	sp,sp,-32
    800028e6:	ec06                	sd	ra,24(sp)
    800028e8:	e822                	sd	s0,16(sp)
    800028ea:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800028ec:	fec40593          	addi	a1,s0,-20
    800028f0:	4501                	li	a0,0
    800028f2:	f27ff0ef          	jal	80002818 <argint>
  kexit(n);
    800028f6:	fec42503          	lw	a0,-20(s0)
    800028fa:	f26ff0ef          	jal	80002020 <kexit>
  return 0;  // not reached
}
    800028fe:	4501                	li	a0,0
    80002900:	60e2                	ld	ra,24(sp)
    80002902:	6442                	ld	s0,16(sp)
    80002904:	6105                	addi	sp,sp,32
    80002906:	8082                	ret

0000000080002908 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002908:	1141                	addi	sp,sp,-16
    8000290a:	e406                	sd	ra,8(sp)
    8000290c:	e022                	sd	s0,0(sp)
    8000290e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002910:	ff5fe0ef          	jal	80001904 <myproc>
}
    80002914:	5908                	lw	a0,48(a0)
    80002916:	60a2                	ld	ra,8(sp)
    80002918:	6402                	ld	s0,0(sp)
    8000291a:	0141                	addi	sp,sp,16
    8000291c:	8082                	ret

000000008000291e <sys_fork>:

uint64
sys_fork(void)
{
    8000291e:	1141                	addi	sp,sp,-16
    80002920:	e406                	sd	ra,8(sp)
    80002922:	e022                	sd	s0,0(sp)
    80002924:	0800                	addi	s0,sp,16
  return kfork();
    80002926:	b42ff0ef          	jal	80001c68 <kfork>
}
    8000292a:	60a2                	ld	ra,8(sp)
    8000292c:	6402                	ld	s0,0(sp)
    8000292e:	0141                	addi	sp,sp,16
    80002930:	8082                	ret

0000000080002932 <sys_wait>:

uint64
sys_wait(void)
{
    80002932:	1101                	addi	sp,sp,-32
    80002934:	ec06                	sd	ra,24(sp)
    80002936:	e822                	sd	s0,16(sp)
    80002938:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000293a:	fe840593          	addi	a1,s0,-24
    8000293e:	4501                	li	a0,0
    80002940:	ef5ff0ef          	jal	80002834 <argaddr>
  return kwait(p);
    80002944:	fe843503          	ld	a0,-24(s0)
    80002948:	82fff0ef          	jal	80002176 <kwait>
}
    8000294c:	60e2                	ld	ra,24(sp)
    8000294e:	6442                	ld	s0,16(sp)
    80002950:	6105                	addi	sp,sp,32
    80002952:	8082                	ret

0000000080002954 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002954:	7179                	addi	sp,sp,-48
    80002956:	f406                	sd	ra,40(sp)
    80002958:	f022                	sd	s0,32(sp)
    8000295a:	ec26                	sd	s1,24(sp)
    8000295c:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    8000295e:	fd840593          	addi	a1,s0,-40
    80002962:	4501                	li	a0,0
    80002964:	eb5ff0ef          	jal	80002818 <argint>
  argint(1, &t);
    80002968:	fdc40593          	addi	a1,s0,-36
    8000296c:	4505                	li	a0,1
    8000296e:	eabff0ef          	jal	80002818 <argint>
  addr = myproc()->sz;
    80002972:	f93fe0ef          	jal	80001904 <myproc>
    80002976:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002978:	fdc42703          	lw	a4,-36(s0)
    8000297c:	4785                	li	a5,1
    8000297e:	02f70763          	beq	a4,a5,800029ac <sys_sbrk+0x58>
    80002982:	fd842783          	lw	a5,-40(s0)
    80002986:	0207c363          	bltz	a5,800029ac <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    8000298a:	97a6                	add	a5,a5,s1
    8000298c:	0297ee63          	bltu	a5,s1,800029c8 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002990:	02000737          	lui	a4,0x2000
    80002994:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002996:	0736                	slli	a4,a4,0xd
    80002998:	02f76a63          	bltu	a4,a5,800029cc <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    8000299c:	f69fe0ef          	jal	80001904 <myproc>
    800029a0:	fd842703          	lw	a4,-40(s0)
    800029a4:	653c                	ld	a5,72(a0)
    800029a6:	97ba                	add	a5,a5,a4
    800029a8:	e53c                	sd	a5,72(a0)
    800029aa:	a039                	j	800029b8 <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    800029ac:	fd842503          	lw	a0,-40(s0)
    800029b0:	a56ff0ef          	jal	80001c06 <growproc>
    800029b4:	00054863          	bltz	a0,800029c4 <sys_sbrk+0x70>
  }
  return addr;
}
    800029b8:	8526                	mv	a0,s1
    800029ba:	70a2                	ld	ra,40(sp)
    800029bc:	7402                	ld	s0,32(sp)
    800029be:	64e2                	ld	s1,24(sp)
    800029c0:	6145                	addi	sp,sp,48
    800029c2:	8082                	ret
      return -1;
    800029c4:	54fd                	li	s1,-1
    800029c6:	bfcd                	j	800029b8 <sys_sbrk+0x64>
      return -1;
    800029c8:	54fd                	li	s1,-1
    800029ca:	b7fd                	j	800029b8 <sys_sbrk+0x64>
      return -1;
    800029cc:	54fd                	li	s1,-1
    800029ce:	b7ed                	j	800029b8 <sys_sbrk+0x64>

00000000800029d0 <sys_pause>:

uint64
sys_pause(void)
{
    800029d0:	7139                	addi	sp,sp,-64
    800029d2:	fc06                	sd	ra,56(sp)
    800029d4:	f822                	sd	s0,48(sp)
    800029d6:	f04a                	sd	s2,32(sp)
    800029d8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800029da:	fcc40593          	addi	a1,s0,-52
    800029de:	4501                	li	a0,0
    800029e0:	e39ff0ef          	jal	80002818 <argint>
  if(n < 0)
    800029e4:	fcc42783          	lw	a5,-52(s0)
    800029e8:	0607c763          	bltz	a5,80002a56 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    800029ec:	00013517          	auipc	a0,0x13
    800029f0:	e0c50513          	addi	a0,a0,-500 # 800157f8 <tickslock>
    800029f4:	a0cfe0ef          	jal	80000c00 <acquire>
  ticks0 = ticks;
    800029f8:	00005917          	auipc	s2,0x5
    800029fc:	e9092903          	lw	s2,-368(s2) # 80007888 <ticks>
  while(ticks - ticks0 < n){
    80002a00:	fcc42783          	lw	a5,-52(s0)
    80002a04:	cf8d                	beqz	a5,80002a3e <sys_pause+0x6e>
    80002a06:	f426                	sd	s1,40(sp)
    80002a08:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a0a:	00013997          	auipc	s3,0x13
    80002a0e:	dee98993          	addi	s3,s3,-530 # 800157f8 <tickslock>
    80002a12:	00005497          	auipc	s1,0x5
    80002a16:	e7648493          	addi	s1,s1,-394 # 80007888 <ticks>
    if(killed(myproc())){
    80002a1a:	eebfe0ef          	jal	80001904 <myproc>
    80002a1e:	f2eff0ef          	jal	8000214c <killed>
    80002a22:	ed0d                	bnez	a0,80002a5c <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002a24:	85ce                	mv	a1,s3
    80002a26:	8526                	mv	a0,s1
    80002a28:	cecff0ef          	jal	80001f14 <sleep>
  while(ticks - ticks0 < n){
    80002a2c:	409c                	lw	a5,0(s1)
    80002a2e:	412787bb          	subw	a5,a5,s2
    80002a32:	fcc42703          	lw	a4,-52(s0)
    80002a36:	fee7e2e3          	bltu	a5,a4,80002a1a <sys_pause+0x4a>
    80002a3a:	74a2                	ld	s1,40(sp)
    80002a3c:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002a3e:	00013517          	auipc	a0,0x13
    80002a42:	dba50513          	addi	a0,a0,-582 # 800157f8 <tickslock>
    80002a46:	a52fe0ef          	jal	80000c98 <release>
  return 0;
    80002a4a:	4501                	li	a0,0
}
    80002a4c:	70e2                	ld	ra,56(sp)
    80002a4e:	7442                	ld	s0,48(sp)
    80002a50:	7902                	ld	s2,32(sp)
    80002a52:	6121                	addi	sp,sp,64
    80002a54:	8082                	ret
    n = 0;
    80002a56:	fc042623          	sw	zero,-52(s0)
    80002a5a:	bf49                	j	800029ec <sys_pause+0x1c>
      release(&tickslock);
    80002a5c:	00013517          	auipc	a0,0x13
    80002a60:	d9c50513          	addi	a0,a0,-612 # 800157f8 <tickslock>
    80002a64:	a34fe0ef          	jal	80000c98 <release>
      return -1;
    80002a68:	557d                	li	a0,-1
    80002a6a:	74a2                	ld	s1,40(sp)
    80002a6c:	69e2                	ld	s3,24(sp)
    80002a6e:	bff9                	j	80002a4c <sys_pause+0x7c>

0000000080002a70 <sys_kill>:

uint64
sys_kill(void)
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002a78:	fec40593          	addi	a1,s0,-20
    80002a7c:	4501                	li	a0,0
    80002a7e:	d9bff0ef          	jal	80002818 <argint>
  return kkill(pid);
    80002a82:	fec42503          	lw	a0,-20(s0)
    80002a86:	e3cff0ef          	jal	800020c2 <kkill>
}
    80002a8a:	60e2                	ld	ra,24(sp)
    80002a8c:	6442                	ld	s0,16(sp)
    80002a8e:	6105                	addi	sp,sp,32
    80002a90:	8082                	ret

0000000080002a92 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002a9c:	00013517          	auipc	a0,0x13
    80002aa0:	d5c50513          	addi	a0,a0,-676 # 800157f8 <tickslock>
    80002aa4:	95cfe0ef          	jal	80000c00 <acquire>
  xticks = ticks;
    80002aa8:	00005497          	auipc	s1,0x5
    80002aac:	de04a483          	lw	s1,-544(s1) # 80007888 <ticks>
  release(&tickslock);
    80002ab0:	00013517          	auipc	a0,0x13
    80002ab4:	d4850513          	addi	a0,a0,-696 # 800157f8 <tickslock>
    80002ab8:	9e0fe0ef          	jal	80000c98 <release>
  return xticks;
}
    80002abc:	02049513          	slli	a0,s1,0x20
    80002ac0:	9101                	srli	a0,a0,0x20
    80002ac2:	60e2                	ld	ra,24(sp)
    80002ac4:	6442                	ld	s0,16(sp)
    80002ac6:	64a2                	ld	s1,8(sp)
    80002ac8:	6105                	addi	sp,sp,32
    80002aca:	8082                	ret

0000000080002acc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002acc:	7179                	addi	sp,sp,-48
    80002ace:	f406                	sd	ra,40(sp)
    80002ad0:	f022                	sd	s0,32(sp)
    80002ad2:	ec26                	sd	s1,24(sp)
    80002ad4:	e84a                	sd	s2,16(sp)
    80002ad6:	e44e                	sd	s3,8(sp)
    80002ad8:	e052                	sd	s4,0(sp)
    80002ada:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002adc:	00005597          	auipc	a1,0x5
    80002ae0:	8bc58593          	addi	a1,a1,-1860 # 80007398 <etext+0x398>
    80002ae4:	00013517          	auipc	a0,0x13
    80002ae8:	d2c50513          	addi	a0,a0,-724 # 80015810 <bcache>
    80002aec:	894fe0ef          	jal	80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002af0:	0001b797          	auipc	a5,0x1b
    80002af4:	d2078793          	addi	a5,a5,-736 # 8001d810 <bcache+0x8000>
    80002af8:	0001b717          	auipc	a4,0x1b
    80002afc:	f8070713          	addi	a4,a4,-128 # 8001da78 <bcache+0x8268>
    80002b00:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002b04:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b08:	00013497          	auipc	s1,0x13
    80002b0c:	d2048493          	addi	s1,s1,-736 # 80015828 <bcache+0x18>
    b->next = bcache.head.next;
    80002b10:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002b12:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002b14:	00005a17          	auipc	s4,0x5
    80002b18:	88ca0a13          	addi	s4,s4,-1908 # 800073a0 <etext+0x3a0>
    b->next = bcache.head.next;
    80002b1c:	2b893783          	ld	a5,696(s2)
    80002b20:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002b22:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002b26:	85d2                	mv	a1,s4
    80002b28:	01048513          	addi	a0,s1,16
    80002b2c:	322010ef          	jal	80003e4e <initsleeplock>
    bcache.head.next->prev = b;
    80002b30:	2b893783          	ld	a5,696(s2)
    80002b34:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002b36:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b3a:	45848493          	addi	s1,s1,1112
    80002b3e:	fd349fe3          	bne	s1,s3,80002b1c <binit+0x50>
  }
}
    80002b42:	70a2                	ld	ra,40(sp)
    80002b44:	7402                	ld	s0,32(sp)
    80002b46:	64e2                	ld	s1,24(sp)
    80002b48:	6942                	ld	s2,16(sp)
    80002b4a:	69a2                	ld	s3,8(sp)
    80002b4c:	6a02                	ld	s4,0(sp)
    80002b4e:	6145                	addi	sp,sp,48
    80002b50:	8082                	ret

0000000080002b52 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002b52:	7179                	addi	sp,sp,-48
    80002b54:	f406                	sd	ra,40(sp)
    80002b56:	f022                	sd	s0,32(sp)
    80002b58:	ec26                	sd	s1,24(sp)
    80002b5a:	e84a                	sd	s2,16(sp)
    80002b5c:	e44e                	sd	s3,8(sp)
    80002b5e:	1800                	addi	s0,sp,48
    80002b60:	892a                	mv	s2,a0
    80002b62:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002b64:	00013517          	auipc	a0,0x13
    80002b68:	cac50513          	addi	a0,a0,-852 # 80015810 <bcache>
    80002b6c:	894fe0ef          	jal	80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002b70:	0001b497          	auipc	s1,0x1b
    80002b74:	f584b483          	ld	s1,-168(s1) # 8001dac8 <bcache+0x82b8>
    80002b78:	0001b797          	auipc	a5,0x1b
    80002b7c:	f0078793          	addi	a5,a5,-256 # 8001da78 <bcache+0x8268>
    80002b80:	02f48b63          	beq	s1,a5,80002bb6 <bread+0x64>
    80002b84:	873e                	mv	a4,a5
    80002b86:	a021                	j	80002b8e <bread+0x3c>
    80002b88:	68a4                	ld	s1,80(s1)
    80002b8a:	02e48663          	beq	s1,a4,80002bb6 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002b8e:	449c                	lw	a5,8(s1)
    80002b90:	ff279ce3          	bne	a5,s2,80002b88 <bread+0x36>
    80002b94:	44dc                	lw	a5,12(s1)
    80002b96:	ff3799e3          	bne	a5,s3,80002b88 <bread+0x36>
      b->refcnt++;
    80002b9a:	40bc                	lw	a5,64(s1)
    80002b9c:	2785                	addiw	a5,a5,1
    80002b9e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ba0:	00013517          	auipc	a0,0x13
    80002ba4:	c7050513          	addi	a0,a0,-912 # 80015810 <bcache>
    80002ba8:	8f0fe0ef          	jal	80000c98 <release>
      acquiresleep(&b->lock);
    80002bac:	01048513          	addi	a0,s1,16
    80002bb0:	2d4010ef          	jal	80003e84 <acquiresleep>
      return b;
    80002bb4:	a889                	j	80002c06 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002bb6:	0001b497          	auipc	s1,0x1b
    80002bba:	f0a4b483          	ld	s1,-246(s1) # 8001dac0 <bcache+0x82b0>
    80002bbe:	0001b797          	auipc	a5,0x1b
    80002bc2:	eba78793          	addi	a5,a5,-326 # 8001da78 <bcache+0x8268>
    80002bc6:	00f48863          	beq	s1,a5,80002bd6 <bread+0x84>
    80002bca:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002bcc:	40bc                	lw	a5,64(s1)
    80002bce:	cb91                	beqz	a5,80002be2 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002bd0:	64a4                	ld	s1,72(s1)
    80002bd2:	fee49de3          	bne	s1,a4,80002bcc <bread+0x7a>
  panic("bget: no buffers");
    80002bd6:	00004517          	auipc	a0,0x4
    80002bda:	7d250513          	addi	a0,a0,2002 # 800073a8 <etext+0x3a8>
    80002bde:	c35fd0ef          	jal	80000812 <panic>
      b->dev = dev;
    80002be2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002be6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002bea:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002bee:	4785                	li	a5,1
    80002bf0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002bf2:	00013517          	auipc	a0,0x13
    80002bf6:	c1e50513          	addi	a0,a0,-994 # 80015810 <bcache>
    80002bfa:	89efe0ef          	jal	80000c98 <release>
      acquiresleep(&b->lock);
    80002bfe:	01048513          	addi	a0,s1,16
    80002c02:	282010ef          	jal	80003e84 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002c06:	409c                	lw	a5,0(s1)
    80002c08:	cb89                	beqz	a5,80002c1a <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002c0a:	8526                	mv	a0,s1
    80002c0c:	70a2                	ld	ra,40(sp)
    80002c0e:	7402                	ld	s0,32(sp)
    80002c10:	64e2                	ld	s1,24(sp)
    80002c12:	6942                	ld	s2,16(sp)
    80002c14:	69a2                	ld	s3,8(sp)
    80002c16:	6145                	addi	sp,sp,48
    80002c18:	8082                	ret
    virtio_disk_rw(b, 0);
    80002c1a:	4581                	li	a1,0
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	2d3020ef          	jal	800056f0 <virtio_disk_rw>
    b->valid = 1;
    80002c22:	4785                	li	a5,1
    80002c24:	c09c                	sw	a5,0(s1)
  return b;
    80002c26:	b7d5                	j	80002c0a <bread+0xb8>

0000000080002c28 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	1000                	addi	s0,sp,32
    80002c32:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c34:	0541                	addi	a0,a0,16
    80002c36:	2cc010ef          	jal	80003f02 <holdingsleep>
    80002c3a:	c911                	beqz	a0,80002c4e <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002c3c:	4585                	li	a1,1
    80002c3e:	8526                	mv	a0,s1
    80002c40:	2b1020ef          	jal	800056f0 <virtio_disk_rw>
}
    80002c44:	60e2                	ld	ra,24(sp)
    80002c46:	6442                	ld	s0,16(sp)
    80002c48:	64a2                	ld	s1,8(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret
    panic("bwrite");
    80002c4e:	00004517          	auipc	a0,0x4
    80002c52:	77250513          	addi	a0,a0,1906 # 800073c0 <etext+0x3c0>
    80002c56:	bbdfd0ef          	jal	80000812 <panic>

0000000080002c5a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	e426                	sd	s1,8(sp)
    80002c62:	e04a                	sd	s2,0(sp)
    80002c64:	1000                	addi	s0,sp,32
    80002c66:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c68:	01050913          	addi	s2,a0,16
    80002c6c:	854a                	mv	a0,s2
    80002c6e:	294010ef          	jal	80003f02 <holdingsleep>
    80002c72:	c135                	beqz	a0,80002cd6 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002c74:	854a                	mv	a0,s2
    80002c76:	254010ef          	jal	80003eca <releasesleep>

  acquire(&bcache.lock);
    80002c7a:	00013517          	auipc	a0,0x13
    80002c7e:	b9650513          	addi	a0,a0,-1130 # 80015810 <bcache>
    80002c82:	f7ffd0ef          	jal	80000c00 <acquire>
  b->refcnt--;
    80002c86:	40bc                	lw	a5,64(s1)
    80002c88:	37fd                	addiw	a5,a5,-1
    80002c8a:	0007871b          	sext.w	a4,a5
    80002c8e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002c90:	e71d                	bnez	a4,80002cbe <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002c92:	68b8                	ld	a4,80(s1)
    80002c94:	64bc                	ld	a5,72(s1)
    80002c96:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002c98:	68b8                	ld	a4,80(s1)
    80002c9a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002c9c:	0001b797          	auipc	a5,0x1b
    80002ca0:	b7478793          	addi	a5,a5,-1164 # 8001d810 <bcache+0x8000>
    80002ca4:	2b87b703          	ld	a4,696(a5)
    80002ca8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002caa:	0001b717          	auipc	a4,0x1b
    80002cae:	dce70713          	addi	a4,a4,-562 # 8001da78 <bcache+0x8268>
    80002cb2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002cb4:	2b87b703          	ld	a4,696(a5)
    80002cb8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002cba:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002cbe:	00013517          	auipc	a0,0x13
    80002cc2:	b5250513          	addi	a0,a0,-1198 # 80015810 <bcache>
    80002cc6:	fd3fd0ef          	jal	80000c98 <release>
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6902                	ld	s2,0(sp)
    80002cd2:	6105                	addi	sp,sp,32
    80002cd4:	8082                	ret
    panic("brelse");
    80002cd6:	00004517          	auipc	a0,0x4
    80002cda:	6f250513          	addi	a0,a0,1778 # 800073c8 <etext+0x3c8>
    80002cde:	b35fd0ef          	jal	80000812 <panic>

0000000080002ce2 <bpin>:

void
bpin(struct buf *b) {
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	1000                	addi	s0,sp,32
    80002cec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002cee:	00013517          	auipc	a0,0x13
    80002cf2:	b2250513          	addi	a0,a0,-1246 # 80015810 <bcache>
    80002cf6:	f0bfd0ef          	jal	80000c00 <acquire>
  b->refcnt++;
    80002cfa:	40bc                	lw	a5,64(s1)
    80002cfc:	2785                	addiw	a5,a5,1
    80002cfe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d00:	00013517          	auipc	a0,0x13
    80002d04:	b1050513          	addi	a0,a0,-1264 # 80015810 <bcache>
    80002d08:	f91fd0ef          	jal	80000c98 <release>
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	64a2                	ld	s1,8(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret

0000000080002d16 <bunpin>:

void
bunpin(struct buf *b) {
    80002d16:	1101                	addi	sp,sp,-32
    80002d18:	ec06                	sd	ra,24(sp)
    80002d1a:	e822                	sd	s0,16(sp)
    80002d1c:	e426                	sd	s1,8(sp)
    80002d1e:	1000                	addi	s0,sp,32
    80002d20:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d22:	00013517          	auipc	a0,0x13
    80002d26:	aee50513          	addi	a0,a0,-1298 # 80015810 <bcache>
    80002d2a:	ed7fd0ef          	jal	80000c00 <acquire>
  b->refcnt--;
    80002d2e:	40bc                	lw	a5,64(s1)
    80002d30:	37fd                	addiw	a5,a5,-1
    80002d32:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d34:	00013517          	auipc	a0,0x13
    80002d38:	adc50513          	addi	a0,a0,-1316 # 80015810 <bcache>
    80002d3c:	f5dfd0ef          	jal	80000c98 <release>
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6105                	addi	sp,sp,32
    80002d48:	8082                	ret

0000000080002d4a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	e426                	sd	s1,8(sp)
    80002d52:	e04a                	sd	s2,0(sp)
    80002d54:	1000                	addi	s0,sp,32
    80002d56:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002d58:	00d5d59b          	srliw	a1,a1,0xd
    80002d5c:	0001b797          	auipc	a5,0x1b
    80002d60:	1907a783          	lw	a5,400(a5) # 8001deec <sb+0x1c>
    80002d64:	9dbd                	addw	a1,a1,a5
    80002d66:	dedff0ef          	jal	80002b52 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002d6a:	0074f713          	andi	a4,s1,7
    80002d6e:	4785                	li	a5,1
    80002d70:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002d74:	14ce                	slli	s1,s1,0x33
    80002d76:	90d9                	srli	s1,s1,0x36
    80002d78:	00950733          	add	a4,a0,s1
    80002d7c:	05874703          	lbu	a4,88(a4)
    80002d80:	00e7f6b3          	and	a3,a5,a4
    80002d84:	c29d                	beqz	a3,80002daa <bfree+0x60>
    80002d86:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002d88:	94aa                	add	s1,s1,a0
    80002d8a:	fff7c793          	not	a5,a5
    80002d8e:	8f7d                	and	a4,a4,a5
    80002d90:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002d94:	7f9000ef          	jal	80003d8c <log_write>
  brelse(bp);
    80002d98:	854a                	mv	a0,s2
    80002d9a:	ec1ff0ef          	jal	80002c5a <brelse>
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6902                	ld	s2,0(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret
    panic("freeing free block");
    80002daa:	00004517          	auipc	a0,0x4
    80002dae:	62650513          	addi	a0,a0,1574 # 800073d0 <etext+0x3d0>
    80002db2:	a61fd0ef          	jal	80000812 <panic>

0000000080002db6 <balloc>:
{
    80002db6:	711d                	addi	sp,sp,-96
    80002db8:	ec86                	sd	ra,88(sp)
    80002dba:	e8a2                	sd	s0,80(sp)
    80002dbc:	e4a6                	sd	s1,72(sp)
    80002dbe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002dc0:	0001b797          	auipc	a5,0x1b
    80002dc4:	1147a783          	lw	a5,276(a5) # 8001ded4 <sb+0x4>
    80002dc8:	0e078f63          	beqz	a5,80002ec6 <balloc+0x110>
    80002dcc:	e0ca                	sd	s2,64(sp)
    80002dce:	fc4e                	sd	s3,56(sp)
    80002dd0:	f852                	sd	s4,48(sp)
    80002dd2:	f456                	sd	s5,40(sp)
    80002dd4:	f05a                	sd	s6,32(sp)
    80002dd6:	ec5e                	sd	s7,24(sp)
    80002dd8:	e862                	sd	s8,16(sp)
    80002dda:	e466                	sd	s9,8(sp)
    80002ddc:	8baa                	mv	s7,a0
    80002dde:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002de0:	0001bb17          	auipc	s6,0x1b
    80002de4:	0f0b0b13          	addi	s6,s6,240 # 8001ded0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002de8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002dea:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002dec:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002dee:	6c89                	lui	s9,0x2
    80002df0:	a0b5                	j	80002e5c <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002df2:	97ca                	add	a5,a5,s2
    80002df4:	8e55                	or	a2,a2,a3
    80002df6:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002dfa:	854a                	mv	a0,s2
    80002dfc:	791000ef          	jal	80003d8c <log_write>
        brelse(bp);
    80002e00:	854a                	mv	a0,s2
    80002e02:	e59ff0ef          	jal	80002c5a <brelse>
  bp = bread(dev, bno);
    80002e06:	85a6                	mv	a1,s1
    80002e08:	855e                	mv	a0,s7
    80002e0a:	d49ff0ef          	jal	80002b52 <bread>
    80002e0e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002e10:	40000613          	li	a2,1024
    80002e14:	4581                	li	a1,0
    80002e16:	05850513          	addi	a0,a0,88
    80002e1a:	ebbfd0ef          	jal	80000cd4 <memset>
  log_write(bp);
    80002e1e:	854a                	mv	a0,s2
    80002e20:	76d000ef          	jal	80003d8c <log_write>
  brelse(bp);
    80002e24:	854a                	mv	a0,s2
    80002e26:	e35ff0ef          	jal	80002c5a <brelse>
}
    80002e2a:	6906                	ld	s2,64(sp)
    80002e2c:	79e2                	ld	s3,56(sp)
    80002e2e:	7a42                	ld	s4,48(sp)
    80002e30:	7aa2                	ld	s5,40(sp)
    80002e32:	7b02                	ld	s6,32(sp)
    80002e34:	6be2                	ld	s7,24(sp)
    80002e36:	6c42                	ld	s8,16(sp)
    80002e38:	6ca2                	ld	s9,8(sp)
}
    80002e3a:	8526                	mv	a0,s1
    80002e3c:	60e6                	ld	ra,88(sp)
    80002e3e:	6446                	ld	s0,80(sp)
    80002e40:	64a6                	ld	s1,72(sp)
    80002e42:	6125                	addi	sp,sp,96
    80002e44:	8082                	ret
    brelse(bp);
    80002e46:	854a                	mv	a0,s2
    80002e48:	e13ff0ef          	jal	80002c5a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002e4c:	015c87bb          	addw	a5,s9,s5
    80002e50:	00078a9b          	sext.w	s5,a5
    80002e54:	004b2703          	lw	a4,4(s6)
    80002e58:	04eaff63          	bgeu	s5,a4,80002eb6 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80002e5c:	41fad79b          	sraiw	a5,s5,0x1f
    80002e60:	0137d79b          	srliw	a5,a5,0x13
    80002e64:	015787bb          	addw	a5,a5,s5
    80002e68:	40d7d79b          	sraiw	a5,a5,0xd
    80002e6c:	01cb2583          	lw	a1,28(s6)
    80002e70:	9dbd                	addw	a1,a1,a5
    80002e72:	855e                	mv	a0,s7
    80002e74:	cdfff0ef          	jal	80002b52 <bread>
    80002e78:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e7a:	004b2503          	lw	a0,4(s6)
    80002e7e:	000a849b          	sext.w	s1,s5
    80002e82:	8762                	mv	a4,s8
    80002e84:	fca4f1e3          	bgeu	s1,a0,80002e46 <balloc+0x90>
      m = 1 << (bi % 8);
    80002e88:	00777693          	andi	a3,a4,7
    80002e8c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002e90:	41f7579b          	sraiw	a5,a4,0x1f
    80002e94:	01d7d79b          	srliw	a5,a5,0x1d
    80002e98:	9fb9                	addw	a5,a5,a4
    80002e9a:	4037d79b          	sraiw	a5,a5,0x3
    80002e9e:	00f90633          	add	a2,s2,a5
    80002ea2:	05864603          	lbu	a2,88(a2)
    80002ea6:	00c6f5b3          	and	a1,a3,a2
    80002eaa:	d5a1                	beqz	a1,80002df2 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002eac:	2705                	addiw	a4,a4,1
    80002eae:	2485                	addiw	s1,s1,1
    80002eb0:	fd471ae3          	bne	a4,s4,80002e84 <balloc+0xce>
    80002eb4:	bf49                	j	80002e46 <balloc+0x90>
    80002eb6:	6906                	ld	s2,64(sp)
    80002eb8:	79e2                	ld	s3,56(sp)
    80002eba:	7a42                	ld	s4,48(sp)
    80002ebc:	7aa2                	ld	s5,40(sp)
    80002ebe:	7b02                	ld	s6,32(sp)
    80002ec0:	6be2                	ld	s7,24(sp)
    80002ec2:	6c42                	ld	s8,16(sp)
    80002ec4:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80002ec6:	00004517          	auipc	a0,0x4
    80002eca:	52250513          	addi	a0,a0,1314 # 800073e8 <etext+0x3e8>
    80002ece:	e5efd0ef          	jal	8000052c <printf>
  return 0;
    80002ed2:	4481                	li	s1,0
    80002ed4:	b79d                	j	80002e3a <balloc+0x84>

0000000080002ed6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002ed6:	7179                	addi	sp,sp,-48
    80002ed8:	f406                	sd	ra,40(sp)
    80002eda:	f022                	sd	s0,32(sp)
    80002edc:	ec26                	sd	s1,24(sp)
    80002ede:	e84a                	sd	s2,16(sp)
    80002ee0:	e44e                	sd	s3,8(sp)
    80002ee2:	1800                	addi	s0,sp,48
    80002ee4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002ee6:	47ad                	li	a5,11
    80002ee8:	02b7e663          	bltu	a5,a1,80002f14 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80002eec:	02059793          	slli	a5,a1,0x20
    80002ef0:	01e7d593          	srli	a1,a5,0x1e
    80002ef4:	00b504b3          	add	s1,a0,a1
    80002ef8:	0504a903          	lw	s2,80(s1)
    80002efc:	06091a63          	bnez	s2,80002f70 <bmap+0x9a>
      addr = balloc(ip->dev);
    80002f00:	4108                	lw	a0,0(a0)
    80002f02:	eb5ff0ef          	jal	80002db6 <balloc>
    80002f06:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f0a:	06090363          	beqz	s2,80002f70 <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    80002f0e:	0524a823          	sw	s2,80(s1)
    80002f12:	a8b9                	j	80002f70 <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002f14:	ff45849b          	addiw	s1,a1,-12
    80002f18:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80002f1c:	0ff00793          	li	a5,255
    80002f20:	06e7ee63          	bltu	a5,a4,80002f9c <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002f24:	08052903          	lw	s2,128(a0)
    80002f28:	00091d63          	bnez	s2,80002f42 <bmap+0x6c>
      addr = balloc(ip->dev);
    80002f2c:	4108                	lw	a0,0(a0)
    80002f2e:	e89ff0ef          	jal	80002db6 <balloc>
    80002f32:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80002f36:	02090d63          	beqz	s2,80002f70 <bmap+0x9a>
    80002f3a:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002f3c:	0929a023          	sw	s2,128(s3)
    80002f40:	a011                	j	80002f44 <bmap+0x6e>
    80002f42:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80002f44:	85ca                	mv	a1,s2
    80002f46:	0009a503          	lw	a0,0(s3)
    80002f4a:	c09ff0ef          	jal	80002b52 <bread>
    80002f4e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f50:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002f54:	02049713          	slli	a4,s1,0x20
    80002f58:	01e75593          	srli	a1,a4,0x1e
    80002f5c:	00b784b3          	add	s1,a5,a1
    80002f60:	0004a903          	lw	s2,0(s1)
    80002f64:	00090e63          	beqz	s2,80002f80 <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002f68:	8552                	mv	a0,s4
    80002f6a:	cf1ff0ef          	jal	80002c5a <brelse>
    return addr;
    80002f6e:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80002f70:	854a                	mv	a0,s2
    80002f72:	70a2                	ld	ra,40(sp)
    80002f74:	7402                	ld	s0,32(sp)
    80002f76:	64e2                	ld	s1,24(sp)
    80002f78:	6942                	ld	s2,16(sp)
    80002f7a:	69a2                	ld	s3,8(sp)
    80002f7c:	6145                	addi	sp,sp,48
    80002f7e:	8082                	ret
      addr = balloc(ip->dev);
    80002f80:	0009a503          	lw	a0,0(s3)
    80002f84:	e33ff0ef          	jal	80002db6 <balloc>
    80002f88:	0005091b          	sext.w	s2,a0
      if(addr){
    80002f8c:	fc090ee3          	beqz	s2,80002f68 <bmap+0x92>
        a[bn] = addr;
    80002f90:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80002f94:	8552                	mv	a0,s4
    80002f96:	5f7000ef          	jal	80003d8c <log_write>
    80002f9a:	b7f9                	j	80002f68 <bmap+0x92>
    80002f9c:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80002f9e:	00004517          	auipc	a0,0x4
    80002fa2:	46250513          	addi	a0,a0,1122 # 80007400 <etext+0x400>
    80002fa6:	86dfd0ef          	jal	80000812 <panic>

0000000080002faa <iget>:
{
    80002faa:	7179                	addi	sp,sp,-48
    80002fac:	f406                	sd	ra,40(sp)
    80002fae:	f022                	sd	s0,32(sp)
    80002fb0:	ec26                	sd	s1,24(sp)
    80002fb2:	e84a                	sd	s2,16(sp)
    80002fb4:	e44e                	sd	s3,8(sp)
    80002fb6:	e052                	sd	s4,0(sp)
    80002fb8:	1800                	addi	s0,sp,48
    80002fba:	89aa                	mv	s3,a0
    80002fbc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002fbe:	0001b517          	auipc	a0,0x1b
    80002fc2:	f3250513          	addi	a0,a0,-206 # 8001def0 <itable>
    80002fc6:	c3bfd0ef          	jal	80000c00 <acquire>
  empty = 0;
    80002fca:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002fcc:	0001b497          	auipc	s1,0x1b
    80002fd0:	f3c48493          	addi	s1,s1,-196 # 8001df08 <itable+0x18>
    80002fd4:	0001d697          	auipc	a3,0x1d
    80002fd8:	9c468693          	addi	a3,a3,-1596 # 8001f998 <log>
    80002fdc:	a039                	j	80002fea <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80002fde:	02090963          	beqz	s2,80003010 <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80002fe2:	08848493          	addi	s1,s1,136
    80002fe6:	02d48863          	beq	s1,a3,80003016 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80002fea:	449c                	lw	a5,8(s1)
    80002fec:	fef059e3          	blez	a5,80002fde <iget+0x34>
    80002ff0:	4098                	lw	a4,0(s1)
    80002ff2:	ff3716e3          	bne	a4,s3,80002fde <iget+0x34>
    80002ff6:	40d8                	lw	a4,4(s1)
    80002ff8:	ff4713e3          	bne	a4,s4,80002fde <iget+0x34>
      ip->ref++;
    80002ffc:	2785                	addiw	a5,a5,1
    80002ffe:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003000:	0001b517          	auipc	a0,0x1b
    80003004:	ef050513          	addi	a0,a0,-272 # 8001def0 <itable>
    80003008:	c91fd0ef          	jal	80000c98 <release>
      return ip;
    8000300c:	8926                	mv	s2,s1
    8000300e:	a02d                	j	80003038 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003010:	fbe9                	bnez	a5,80002fe2 <iget+0x38>
      empty = ip;
    80003012:	8926                	mv	s2,s1
    80003014:	b7f9                	j	80002fe2 <iget+0x38>
  if(empty == 0)
    80003016:	02090a63          	beqz	s2,8000304a <iget+0xa0>
  ip->dev = dev;
    8000301a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000301e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003022:	4785                	li	a5,1
    80003024:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003028:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000302c:	0001b517          	auipc	a0,0x1b
    80003030:	ec450513          	addi	a0,a0,-316 # 8001def0 <itable>
    80003034:	c65fd0ef          	jal	80000c98 <release>
}
    80003038:	854a                	mv	a0,s2
    8000303a:	70a2                	ld	ra,40(sp)
    8000303c:	7402                	ld	s0,32(sp)
    8000303e:	64e2                	ld	s1,24(sp)
    80003040:	6942                	ld	s2,16(sp)
    80003042:	69a2                	ld	s3,8(sp)
    80003044:	6a02                	ld	s4,0(sp)
    80003046:	6145                	addi	sp,sp,48
    80003048:	8082                	ret
    panic("iget: no inodes");
    8000304a:	00004517          	auipc	a0,0x4
    8000304e:	3ce50513          	addi	a0,a0,974 # 80007418 <etext+0x418>
    80003052:	fc0fd0ef          	jal	80000812 <panic>

0000000080003056 <iinit>:
{
    80003056:	7179                	addi	sp,sp,-48
    80003058:	f406                	sd	ra,40(sp)
    8000305a:	f022                	sd	s0,32(sp)
    8000305c:	ec26                	sd	s1,24(sp)
    8000305e:	e84a                	sd	s2,16(sp)
    80003060:	e44e                	sd	s3,8(sp)
    80003062:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003064:	00004597          	auipc	a1,0x4
    80003068:	3c458593          	addi	a1,a1,964 # 80007428 <etext+0x428>
    8000306c:	0001b517          	auipc	a0,0x1b
    80003070:	e8450513          	addi	a0,a0,-380 # 8001def0 <itable>
    80003074:	b0dfd0ef          	jal	80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003078:	0001b497          	auipc	s1,0x1b
    8000307c:	ea048493          	addi	s1,s1,-352 # 8001df18 <itable+0x28>
    80003080:	0001d997          	auipc	s3,0x1d
    80003084:	92898993          	addi	s3,s3,-1752 # 8001f9a8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003088:	00004917          	auipc	s2,0x4
    8000308c:	3a890913          	addi	s2,s2,936 # 80007430 <etext+0x430>
    80003090:	85ca                	mv	a1,s2
    80003092:	8526                	mv	a0,s1
    80003094:	5bb000ef          	jal	80003e4e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003098:	08848493          	addi	s1,s1,136
    8000309c:	ff349ae3          	bne	s1,s3,80003090 <iinit+0x3a>
}
    800030a0:	70a2                	ld	ra,40(sp)
    800030a2:	7402                	ld	s0,32(sp)
    800030a4:	64e2                	ld	s1,24(sp)
    800030a6:	6942                	ld	s2,16(sp)
    800030a8:	69a2                	ld	s3,8(sp)
    800030aa:	6145                	addi	sp,sp,48
    800030ac:	8082                	ret

00000000800030ae <ialloc>:
{
    800030ae:	7139                	addi	sp,sp,-64
    800030b0:	fc06                	sd	ra,56(sp)
    800030b2:	f822                	sd	s0,48(sp)
    800030b4:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800030b6:	0001b717          	auipc	a4,0x1b
    800030ba:	e2672703          	lw	a4,-474(a4) # 8001dedc <sb+0xc>
    800030be:	4785                	li	a5,1
    800030c0:	06e7f063          	bgeu	a5,a4,80003120 <ialloc+0x72>
    800030c4:	f426                	sd	s1,40(sp)
    800030c6:	f04a                	sd	s2,32(sp)
    800030c8:	ec4e                	sd	s3,24(sp)
    800030ca:	e852                	sd	s4,16(sp)
    800030cc:	e456                	sd	s5,8(sp)
    800030ce:	e05a                	sd	s6,0(sp)
    800030d0:	8aaa                	mv	s5,a0
    800030d2:	8b2e                	mv	s6,a1
    800030d4:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800030d6:	0001ba17          	auipc	s4,0x1b
    800030da:	dfaa0a13          	addi	s4,s4,-518 # 8001ded0 <sb>
    800030de:	00495593          	srli	a1,s2,0x4
    800030e2:	018a2783          	lw	a5,24(s4)
    800030e6:	9dbd                	addw	a1,a1,a5
    800030e8:	8556                	mv	a0,s5
    800030ea:	a69ff0ef          	jal	80002b52 <bread>
    800030ee:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800030f0:	05850993          	addi	s3,a0,88
    800030f4:	00f97793          	andi	a5,s2,15
    800030f8:	079a                	slli	a5,a5,0x6
    800030fa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800030fc:	00099783          	lh	a5,0(s3)
    80003100:	cb9d                	beqz	a5,80003136 <ialloc+0x88>
    brelse(bp);
    80003102:	b59ff0ef          	jal	80002c5a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003106:	0905                	addi	s2,s2,1
    80003108:	00ca2703          	lw	a4,12(s4)
    8000310c:	0009079b          	sext.w	a5,s2
    80003110:	fce7e7e3          	bltu	a5,a4,800030de <ialloc+0x30>
    80003114:	74a2                	ld	s1,40(sp)
    80003116:	7902                	ld	s2,32(sp)
    80003118:	69e2                	ld	s3,24(sp)
    8000311a:	6a42                	ld	s4,16(sp)
    8000311c:	6aa2                	ld	s5,8(sp)
    8000311e:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003120:	00004517          	auipc	a0,0x4
    80003124:	31850513          	addi	a0,a0,792 # 80007438 <etext+0x438>
    80003128:	c04fd0ef          	jal	8000052c <printf>
  return 0;
    8000312c:	4501                	li	a0,0
}
    8000312e:	70e2                	ld	ra,56(sp)
    80003130:	7442                	ld	s0,48(sp)
    80003132:	6121                	addi	sp,sp,64
    80003134:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003136:	04000613          	li	a2,64
    8000313a:	4581                	li	a1,0
    8000313c:	854e                	mv	a0,s3
    8000313e:	b97fd0ef          	jal	80000cd4 <memset>
      dip->type = type;
    80003142:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003146:	8526                	mv	a0,s1
    80003148:	445000ef          	jal	80003d8c <log_write>
      brelse(bp);
    8000314c:	8526                	mv	a0,s1
    8000314e:	b0dff0ef          	jal	80002c5a <brelse>
      return iget(dev, inum);
    80003152:	0009059b          	sext.w	a1,s2
    80003156:	8556                	mv	a0,s5
    80003158:	e53ff0ef          	jal	80002faa <iget>
    8000315c:	74a2                	ld	s1,40(sp)
    8000315e:	7902                	ld	s2,32(sp)
    80003160:	69e2                	ld	s3,24(sp)
    80003162:	6a42                	ld	s4,16(sp)
    80003164:	6aa2                	ld	s5,8(sp)
    80003166:	6b02                	ld	s6,0(sp)
    80003168:	b7d9                	j	8000312e <ialloc+0x80>

000000008000316a <iupdate>:
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	e04a                	sd	s2,0(sp)
    80003174:	1000                	addi	s0,sp,32
    80003176:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003178:	415c                	lw	a5,4(a0)
    8000317a:	0047d79b          	srliw	a5,a5,0x4
    8000317e:	0001b597          	auipc	a1,0x1b
    80003182:	d6a5a583          	lw	a1,-662(a1) # 8001dee8 <sb+0x18>
    80003186:	9dbd                	addw	a1,a1,a5
    80003188:	4108                	lw	a0,0(a0)
    8000318a:	9c9ff0ef          	jal	80002b52 <bread>
    8000318e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003190:	05850793          	addi	a5,a0,88
    80003194:	40d8                	lw	a4,4(s1)
    80003196:	8b3d                	andi	a4,a4,15
    80003198:	071a                	slli	a4,a4,0x6
    8000319a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000319c:	04449703          	lh	a4,68(s1)
    800031a0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800031a4:	04649703          	lh	a4,70(s1)
    800031a8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800031ac:	04849703          	lh	a4,72(s1)
    800031b0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800031b4:	04a49703          	lh	a4,74(s1)
    800031b8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800031bc:	44f8                	lw	a4,76(s1)
    800031be:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800031c0:	03400613          	li	a2,52
    800031c4:	05048593          	addi	a1,s1,80
    800031c8:	00c78513          	addi	a0,a5,12
    800031cc:	b65fd0ef          	jal	80000d30 <memmove>
  log_write(bp);
    800031d0:	854a                	mv	a0,s2
    800031d2:	3bb000ef          	jal	80003d8c <log_write>
  brelse(bp);
    800031d6:	854a                	mv	a0,s2
    800031d8:	a83ff0ef          	jal	80002c5a <brelse>
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6902                	ld	s2,0(sp)
    800031e4:	6105                	addi	sp,sp,32
    800031e6:	8082                	ret

00000000800031e8 <idup>:
{
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	1000                	addi	s0,sp,32
    800031f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800031f4:	0001b517          	auipc	a0,0x1b
    800031f8:	cfc50513          	addi	a0,a0,-772 # 8001def0 <itable>
    800031fc:	a05fd0ef          	jal	80000c00 <acquire>
  ip->ref++;
    80003200:	449c                	lw	a5,8(s1)
    80003202:	2785                	addiw	a5,a5,1
    80003204:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003206:	0001b517          	auipc	a0,0x1b
    8000320a:	cea50513          	addi	a0,a0,-790 # 8001def0 <itable>
    8000320e:	a8bfd0ef          	jal	80000c98 <release>
}
    80003212:	8526                	mv	a0,s1
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	64a2                	ld	s1,8(sp)
    8000321a:	6105                	addi	sp,sp,32
    8000321c:	8082                	ret

000000008000321e <ilock>:
{
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	e426                	sd	s1,8(sp)
    80003226:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003228:	cd19                	beqz	a0,80003246 <ilock+0x28>
    8000322a:	84aa                	mv	s1,a0
    8000322c:	451c                	lw	a5,8(a0)
    8000322e:	00f05c63          	blez	a5,80003246 <ilock+0x28>
  acquiresleep(&ip->lock);
    80003232:	0541                	addi	a0,a0,16
    80003234:	451000ef          	jal	80003e84 <acquiresleep>
  if(ip->valid == 0){
    80003238:	40bc                	lw	a5,64(s1)
    8000323a:	cf89                	beqz	a5,80003254 <ilock+0x36>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret
    80003246:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003248:	00004517          	auipc	a0,0x4
    8000324c:	20850513          	addi	a0,a0,520 # 80007450 <etext+0x450>
    80003250:	dc2fd0ef          	jal	80000812 <panic>
    80003254:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003256:	40dc                	lw	a5,4(s1)
    80003258:	0047d79b          	srliw	a5,a5,0x4
    8000325c:	0001b597          	auipc	a1,0x1b
    80003260:	c8c5a583          	lw	a1,-884(a1) # 8001dee8 <sb+0x18>
    80003264:	9dbd                	addw	a1,a1,a5
    80003266:	4088                	lw	a0,0(s1)
    80003268:	8ebff0ef          	jal	80002b52 <bread>
    8000326c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000326e:	05850593          	addi	a1,a0,88
    80003272:	40dc                	lw	a5,4(s1)
    80003274:	8bbd                	andi	a5,a5,15
    80003276:	079a                	slli	a5,a5,0x6
    80003278:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000327a:	00059783          	lh	a5,0(a1)
    8000327e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003282:	00259783          	lh	a5,2(a1)
    80003286:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000328a:	00459783          	lh	a5,4(a1)
    8000328e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003292:	00659783          	lh	a5,6(a1)
    80003296:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000329a:	459c                	lw	a5,8(a1)
    8000329c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000329e:	03400613          	li	a2,52
    800032a2:	05b1                	addi	a1,a1,12
    800032a4:	05048513          	addi	a0,s1,80
    800032a8:	a89fd0ef          	jal	80000d30 <memmove>
    brelse(bp);
    800032ac:	854a                	mv	a0,s2
    800032ae:	9adff0ef          	jal	80002c5a <brelse>
    ip->valid = 1;
    800032b2:	4785                	li	a5,1
    800032b4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800032b6:	04449783          	lh	a5,68(s1)
    800032ba:	c399                	beqz	a5,800032c0 <ilock+0xa2>
    800032bc:	6902                	ld	s2,0(sp)
    800032be:	bfbd                	j	8000323c <ilock+0x1e>
      panic("ilock: no type");
    800032c0:	00004517          	auipc	a0,0x4
    800032c4:	19850513          	addi	a0,a0,408 # 80007458 <etext+0x458>
    800032c8:	d4afd0ef          	jal	80000812 <panic>

00000000800032cc <iunlock>:
{
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	e426                	sd	s1,8(sp)
    800032d4:	e04a                	sd	s2,0(sp)
    800032d6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800032d8:	c505                	beqz	a0,80003300 <iunlock+0x34>
    800032da:	84aa                	mv	s1,a0
    800032dc:	01050913          	addi	s2,a0,16
    800032e0:	854a                	mv	a0,s2
    800032e2:	421000ef          	jal	80003f02 <holdingsleep>
    800032e6:	cd09                	beqz	a0,80003300 <iunlock+0x34>
    800032e8:	449c                	lw	a5,8(s1)
    800032ea:	00f05b63          	blez	a5,80003300 <iunlock+0x34>
  releasesleep(&ip->lock);
    800032ee:	854a                	mv	a0,s2
    800032f0:	3db000ef          	jal	80003eca <releasesleep>
}
    800032f4:	60e2                	ld	ra,24(sp)
    800032f6:	6442                	ld	s0,16(sp)
    800032f8:	64a2                	ld	s1,8(sp)
    800032fa:	6902                	ld	s2,0(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret
    panic("iunlock");
    80003300:	00004517          	auipc	a0,0x4
    80003304:	16850513          	addi	a0,a0,360 # 80007468 <etext+0x468>
    80003308:	d0afd0ef          	jal	80000812 <panic>

000000008000330c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000330c:	7179                	addi	sp,sp,-48
    8000330e:	f406                	sd	ra,40(sp)
    80003310:	f022                	sd	s0,32(sp)
    80003312:	ec26                	sd	s1,24(sp)
    80003314:	e84a                	sd	s2,16(sp)
    80003316:	e44e                	sd	s3,8(sp)
    80003318:	1800                	addi	s0,sp,48
    8000331a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000331c:	05050493          	addi	s1,a0,80
    80003320:	08050913          	addi	s2,a0,128
    80003324:	a021                	j	8000332c <itrunc+0x20>
    80003326:	0491                	addi	s1,s1,4
    80003328:	01248b63          	beq	s1,s2,8000333e <itrunc+0x32>
    if(ip->addrs[i]){
    8000332c:	408c                	lw	a1,0(s1)
    8000332e:	dde5                	beqz	a1,80003326 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003330:	0009a503          	lw	a0,0(s3)
    80003334:	a17ff0ef          	jal	80002d4a <bfree>
      ip->addrs[i] = 0;
    80003338:	0004a023          	sw	zero,0(s1)
    8000333c:	b7ed                	j	80003326 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000333e:	0809a583          	lw	a1,128(s3)
    80003342:	ed89                	bnez	a1,8000335c <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003344:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003348:	854e                	mv	a0,s3
    8000334a:	e21ff0ef          	jal	8000316a <iupdate>
}
    8000334e:	70a2                	ld	ra,40(sp)
    80003350:	7402                	ld	s0,32(sp)
    80003352:	64e2                	ld	s1,24(sp)
    80003354:	6942                	ld	s2,16(sp)
    80003356:	69a2                	ld	s3,8(sp)
    80003358:	6145                	addi	sp,sp,48
    8000335a:	8082                	ret
    8000335c:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000335e:	0009a503          	lw	a0,0(s3)
    80003362:	ff0ff0ef          	jal	80002b52 <bread>
    80003366:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003368:	05850493          	addi	s1,a0,88
    8000336c:	45850913          	addi	s2,a0,1112
    80003370:	a021                	j	80003378 <itrunc+0x6c>
    80003372:	0491                	addi	s1,s1,4
    80003374:	01248963          	beq	s1,s2,80003386 <itrunc+0x7a>
      if(a[j])
    80003378:	408c                	lw	a1,0(s1)
    8000337a:	dde5                	beqz	a1,80003372 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    8000337c:	0009a503          	lw	a0,0(s3)
    80003380:	9cbff0ef          	jal	80002d4a <bfree>
    80003384:	b7fd                	j	80003372 <itrunc+0x66>
    brelse(bp);
    80003386:	8552                	mv	a0,s4
    80003388:	8d3ff0ef          	jal	80002c5a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000338c:	0809a583          	lw	a1,128(s3)
    80003390:	0009a503          	lw	a0,0(s3)
    80003394:	9b7ff0ef          	jal	80002d4a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003398:	0809a023          	sw	zero,128(s3)
    8000339c:	6a02                	ld	s4,0(sp)
    8000339e:	b75d                	j	80003344 <itrunc+0x38>

00000000800033a0 <iput>:
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800033ac:	0001b517          	auipc	a0,0x1b
    800033b0:	b4450513          	addi	a0,a0,-1212 # 8001def0 <itable>
    800033b4:	84dfd0ef          	jal	80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033b8:	4498                	lw	a4,8(s1)
    800033ba:	4785                	li	a5,1
    800033bc:	02f70063          	beq	a4,a5,800033dc <iput+0x3c>
  ip->ref--;
    800033c0:	449c                	lw	a5,8(s1)
    800033c2:	37fd                	addiw	a5,a5,-1
    800033c4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800033c6:	0001b517          	auipc	a0,0x1b
    800033ca:	b2a50513          	addi	a0,a0,-1238 # 8001def0 <itable>
    800033ce:	8cbfd0ef          	jal	80000c98 <release>
}
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	64a2                	ld	s1,8(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033dc:	40bc                	lw	a5,64(s1)
    800033de:	d3ed                	beqz	a5,800033c0 <iput+0x20>
    800033e0:	04a49783          	lh	a5,74(s1)
    800033e4:	fff1                	bnez	a5,800033c0 <iput+0x20>
    800033e6:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    800033e8:	01048913          	addi	s2,s1,16
    800033ec:	854a                	mv	a0,s2
    800033ee:	297000ef          	jal	80003e84 <acquiresleep>
    release(&itable.lock);
    800033f2:	0001b517          	auipc	a0,0x1b
    800033f6:	afe50513          	addi	a0,a0,-1282 # 8001def0 <itable>
    800033fa:	89ffd0ef          	jal	80000c98 <release>
    itrunc(ip);
    800033fe:	8526                	mv	a0,s1
    80003400:	f0dff0ef          	jal	8000330c <itrunc>
    ip->type = 0;
    80003404:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003408:	8526                	mv	a0,s1
    8000340a:	d61ff0ef          	jal	8000316a <iupdate>
    ip->valid = 0;
    8000340e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003412:	854a                	mv	a0,s2
    80003414:	2b7000ef          	jal	80003eca <releasesleep>
    acquire(&itable.lock);
    80003418:	0001b517          	auipc	a0,0x1b
    8000341c:	ad850513          	addi	a0,a0,-1320 # 8001def0 <itable>
    80003420:	fe0fd0ef          	jal	80000c00 <acquire>
    80003424:	6902                	ld	s2,0(sp)
    80003426:	bf69                	j	800033c0 <iput+0x20>

0000000080003428 <iunlockput>:
{
    80003428:	1101                	addi	sp,sp,-32
    8000342a:	ec06                	sd	ra,24(sp)
    8000342c:	e822                	sd	s0,16(sp)
    8000342e:	e426                	sd	s1,8(sp)
    80003430:	1000                	addi	s0,sp,32
    80003432:	84aa                	mv	s1,a0
  iunlock(ip);
    80003434:	e99ff0ef          	jal	800032cc <iunlock>
  iput(ip);
    80003438:	8526                	mv	a0,s1
    8000343a:	f67ff0ef          	jal	800033a0 <iput>
}
    8000343e:	60e2                	ld	ra,24(sp)
    80003440:	6442                	ld	s0,16(sp)
    80003442:	64a2                	ld	s1,8(sp)
    80003444:	6105                	addi	sp,sp,32
    80003446:	8082                	ret

0000000080003448 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003448:	0001b717          	auipc	a4,0x1b
    8000344c:	a9472703          	lw	a4,-1388(a4) # 8001dedc <sb+0xc>
    80003450:	4785                	li	a5,1
    80003452:	0ae7ff63          	bgeu	a5,a4,80003510 <ireclaim+0xc8>
{
    80003456:	7139                	addi	sp,sp,-64
    80003458:	fc06                	sd	ra,56(sp)
    8000345a:	f822                	sd	s0,48(sp)
    8000345c:	f426                	sd	s1,40(sp)
    8000345e:	f04a                	sd	s2,32(sp)
    80003460:	ec4e                	sd	s3,24(sp)
    80003462:	e852                	sd	s4,16(sp)
    80003464:	e456                	sd	s5,8(sp)
    80003466:	e05a                	sd	s6,0(sp)
    80003468:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    8000346a:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000346c:	00050a1b          	sext.w	s4,a0
    80003470:	0001ba97          	auipc	s5,0x1b
    80003474:	a60a8a93          	addi	s5,s5,-1440 # 8001ded0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003478:	00004b17          	auipc	s6,0x4
    8000347c:	ff8b0b13          	addi	s6,s6,-8 # 80007470 <etext+0x470>
    80003480:	a099                	j	800034c6 <ireclaim+0x7e>
    80003482:	85ce                	mv	a1,s3
    80003484:	855a                	mv	a0,s6
    80003486:	8a6fd0ef          	jal	8000052c <printf>
      ip = iget(dev, inum);
    8000348a:	85ce                	mv	a1,s3
    8000348c:	8552                	mv	a0,s4
    8000348e:	b1dff0ef          	jal	80002faa <iget>
    80003492:	89aa                	mv	s3,a0
    brelse(bp);
    80003494:	854a                	mv	a0,s2
    80003496:	fc4ff0ef          	jal	80002c5a <brelse>
    if (ip) {
    8000349a:	00098f63          	beqz	s3,800034b8 <ireclaim+0x70>
      begin_op();
    8000349e:	76a000ef          	jal	80003c08 <begin_op>
      ilock(ip);
    800034a2:	854e                	mv	a0,s3
    800034a4:	d7bff0ef          	jal	8000321e <ilock>
      iunlock(ip);
    800034a8:	854e                	mv	a0,s3
    800034aa:	e23ff0ef          	jal	800032cc <iunlock>
      iput(ip);
    800034ae:	854e                	mv	a0,s3
    800034b0:	ef1ff0ef          	jal	800033a0 <iput>
      end_op();
    800034b4:	7be000ef          	jal	80003c72 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800034b8:	0485                	addi	s1,s1,1
    800034ba:	00caa703          	lw	a4,12(s5)
    800034be:	0004879b          	sext.w	a5,s1
    800034c2:	02e7fd63          	bgeu	a5,a4,800034fc <ireclaim+0xb4>
    800034c6:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800034ca:	0044d593          	srli	a1,s1,0x4
    800034ce:	018aa783          	lw	a5,24(s5)
    800034d2:	9dbd                	addw	a1,a1,a5
    800034d4:	8552                	mv	a0,s4
    800034d6:	e7cff0ef          	jal	80002b52 <bread>
    800034da:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    800034dc:	05850793          	addi	a5,a0,88
    800034e0:	00f9f713          	andi	a4,s3,15
    800034e4:	071a                	slli	a4,a4,0x6
    800034e6:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    800034e8:	00079703          	lh	a4,0(a5)
    800034ec:	c701                	beqz	a4,800034f4 <ireclaim+0xac>
    800034ee:	00679783          	lh	a5,6(a5)
    800034f2:	dbc1                	beqz	a5,80003482 <ireclaim+0x3a>
    brelse(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	f64ff0ef          	jal	80002c5a <brelse>
    if (ip) {
    800034fa:	bf7d                	j	800034b8 <ireclaim+0x70>
}
    800034fc:	70e2                	ld	ra,56(sp)
    800034fe:	7442                	ld	s0,48(sp)
    80003500:	74a2                	ld	s1,40(sp)
    80003502:	7902                	ld	s2,32(sp)
    80003504:	69e2                	ld	s3,24(sp)
    80003506:	6a42                	ld	s4,16(sp)
    80003508:	6aa2                	ld	s5,8(sp)
    8000350a:	6b02                	ld	s6,0(sp)
    8000350c:	6121                	addi	sp,sp,64
    8000350e:	8082                	ret
    80003510:	8082                	ret

0000000080003512 <fsinit>:
fsinit(int dev) {
    80003512:	7179                	addi	sp,sp,-48
    80003514:	f406                	sd	ra,40(sp)
    80003516:	f022                	sd	s0,32(sp)
    80003518:	ec26                	sd	s1,24(sp)
    8000351a:	e84a                	sd	s2,16(sp)
    8000351c:	e44e                	sd	s3,8(sp)
    8000351e:	1800                	addi	s0,sp,48
    80003520:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003522:	4585                	li	a1,1
    80003524:	e2eff0ef          	jal	80002b52 <bread>
    80003528:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000352a:	0001b997          	auipc	s3,0x1b
    8000352e:	9a698993          	addi	s3,s3,-1626 # 8001ded0 <sb>
    80003532:	02000613          	li	a2,32
    80003536:	05850593          	addi	a1,a0,88
    8000353a:	854e                	mv	a0,s3
    8000353c:	ff4fd0ef          	jal	80000d30 <memmove>
  brelse(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	f18ff0ef          	jal	80002c5a <brelse>
  if(sb.magic != FSMAGIC)
    80003546:	0009a703          	lw	a4,0(s3)
    8000354a:	102037b7          	lui	a5,0x10203
    8000354e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003552:	02f71363          	bne	a4,a5,80003578 <fsinit+0x66>
  initlog(dev, &sb);
    80003556:	0001b597          	auipc	a1,0x1b
    8000355a:	97a58593          	addi	a1,a1,-1670 # 8001ded0 <sb>
    8000355e:	8526                	mv	a0,s1
    80003560:	62a000ef          	jal	80003b8a <initlog>
  ireclaim(dev);
    80003564:	8526                	mv	a0,s1
    80003566:	ee3ff0ef          	jal	80003448 <ireclaim>
}
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret
    panic("invalid file system");
    80003578:	00004517          	auipc	a0,0x4
    8000357c:	f1850513          	addi	a0,a0,-232 # 80007490 <etext+0x490>
    80003580:	a92fd0ef          	jal	80000812 <panic>

0000000080003584 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003584:	1141                	addi	sp,sp,-16
    80003586:	e422                	sd	s0,8(sp)
    80003588:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000358a:	411c                	lw	a5,0(a0)
    8000358c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000358e:	415c                	lw	a5,4(a0)
    80003590:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003592:	04451783          	lh	a5,68(a0)
    80003596:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000359a:	04a51783          	lh	a5,74(a0)
    8000359e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800035a2:	04c56783          	lwu	a5,76(a0)
    800035a6:	e99c                	sd	a5,16(a1)
}
    800035a8:	6422                	ld	s0,8(sp)
    800035aa:	0141                	addi	sp,sp,16
    800035ac:	8082                	ret

00000000800035ae <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800035ae:	457c                	lw	a5,76(a0)
    800035b0:	0ed7eb63          	bltu	a5,a3,800036a6 <readi+0xf8>
{
    800035b4:	7159                	addi	sp,sp,-112
    800035b6:	f486                	sd	ra,104(sp)
    800035b8:	f0a2                	sd	s0,96(sp)
    800035ba:	eca6                	sd	s1,88(sp)
    800035bc:	e0d2                	sd	s4,64(sp)
    800035be:	fc56                	sd	s5,56(sp)
    800035c0:	f85a                	sd	s6,48(sp)
    800035c2:	f45e                	sd	s7,40(sp)
    800035c4:	1880                	addi	s0,sp,112
    800035c6:	8b2a                	mv	s6,a0
    800035c8:	8bae                	mv	s7,a1
    800035ca:	8a32                	mv	s4,a2
    800035cc:	84b6                	mv	s1,a3
    800035ce:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800035d0:	9f35                	addw	a4,a4,a3
    return 0;
    800035d2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800035d4:	0cd76063          	bltu	a4,a3,80003694 <readi+0xe6>
    800035d8:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    800035da:	00e7f463          	bgeu	a5,a4,800035e2 <readi+0x34>
    n = ip->size - off;
    800035de:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800035e2:	080a8f63          	beqz	s5,80003680 <readi+0xd2>
    800035e6:	e8ca                	sd	s2,80(sp)
    800035e8:	f062                	sd	s8,32(sp)
    800035ea:	ec66                	sd	s9,24(sp)
    800035ec:	e86a                	sd	s10,16(sp)
    800035ee:	e46e                	sd	s11,8(sp)
    800035f0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800035f2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800035f6:	5c7d                	li	s8,-1
    800035f8:	a80d                	j	8000362a <readi+0x7c>
    800035fa:	020d1d93          	slli	s11,s10,0x20
    800035fe:	020ddd93          	srli	s11,s11,0x20
    80003602:	05890613          	addi	a2,s2,88
    80003606:	86ee                	mv	a3,s11
    80003608:	963a                	add	a2,a2,a4
    8000360a:	85d2                	mv	a1,s4
    8000360c:	855e                	mv	a0,s7
    8000360e:	c63fe0ef          	jal	80002270 <either_copyout>
    80003612:	05850763          	beq	a0,s8,80003660 <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003616:	854a                	mv	a0,s2
    80003618:	e42ff0ef          	jal	80002c5a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000361c:	013d09bb          	addw	s3,s10,s3
    80003620:	009d04bb          	addw	s1,s10,s1
    80003624:	9a6e                	add	s4,s4,s11
    80003626:	0559f763          	bgeu	s3,s5,80003674 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    8000362a:	00a4d59b          	srliw	a1,s1,0xa
    8000362e:	855a                	mv	a0,s6
    80003630:	8a7ff0ef          	jal	80002ed6 <bmap>
    80003634:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003638:	c5b1                	beqz	a1,80003684 <readi+0xd6>
    bp = bread(ip->dev, addr);
    8000363a:	000b2503          	lw	a0,0(s6)
    8000363e:	d14ff0ef          	jal	80002b52 <bread>
    80003642:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003644:	3ff4f713          	andi	a4,s1,1023
    80003648:	40ec87bb          	subw	a5,s9,a4
    8000364c:	413a86bb          	subw	a3,s5,s3
    80003650:	8d3e                	mv	s10,a5
    80003652:	2781                	sext.w	a5,a5
    80003654:	0006861b          	sext.w	a2,a3
    80003658:	faf671e3          	bgeu	a2,a5,800035fa <readi+0x4c>
    8000365c:	8d36                	mv	s10,a3
    8000365e:	bf71                	j	800035fa <readi+0x4c>
      brelse(bp);
    80003660:	854a                	mv	a0,s2
    80003662:	df8ff0ef          	jal	80002c5a <brelse>
      tot = -1;
    80003666:	59fd                	li	s3,-1
      break;
    80003668:	6946                	ld	s2,80(sp)
    8000366a:	7c02                	ld	s8,32(sp)
    8000366c:	6ce2                	ld	s9,24(sp)
    8000366e:	6d42                	ld	s10,16(sp)
    80003670:	6da2                	ld	s11,8(sp)
    80003672:	a831                	j	8000368e <readi+0xe0>
    80003674:	6946                	ld	s2,80(sp)
    80003676:	7c02                	ld	s8,32(sp)
    80003678:	6ce2                	ld	s9,24(sp)
    8000367a:	6d42                	ld	s10,16(sp)
    8000367c:	6da2                	ld	s11,8(sp)
    8000367e:	a801                	j	8000368e <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003680:	89d6                	mv	s3,s5
    80003682:	a031                	j	8000368e <readi+0xe0>
    80003684:	6946                	ld	s2,80(sp)
    80003686:	7c02                	ld	s8,32(sp)
    80003688:	6ce2                	ld	s9,24(sp)
    8000368a:	6d42                	ld	s10,16(sp)
    8000368c:	6da2                	ld	s11,8(sp)
  }
  return tot;
    8000368e:	0009851b          	sext.w	a0,s3
    80003692:	69a6                	ld	s3,72(sp)
}
    80003694:	70a6                	ld	ra,104(sp)
    80003696:	7406                	ld	s0,96(sp)
    80003698:	64e6                	ld	s1,88(sp)
    8000369a:	6a06                	ld	s4,64(sp)
    8000369c:	7ae2                	ld	s5,56(sp)
    8000369e:	7b42                	ld	s6,48(sp)
    800036a0:	7ba2                	ld	s7,40(sp)
    800036a2:	6165                	addi	sp,sp,112
    800036a4:	8082                	ret
    return 0;
    800036a6:	4501                	li	a0,0
}
    800036a8:	8082                	ret

00000000800036aa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800036aa:	457c                	lw	a5,76(a0)
    800036ac:	10d7e063          	bltu	a5,a3,800037ac <writei+0x102>
{
    800036b0:	7159                	addi	sp,sp,-112
    800036b2:	f486                	sd	ra,104(sp)
    800036b4:	f0a2                	sd	s0,96(sp)
    800036b6:	e8ca                	sd	s2,80(sp)
    800036b8:	e0d2                	sd	s4,64(sp)
    800036ba:	fc56                	sd	s5,56(sp)
    800036bc:	f85a                	sd	s6,48(sp)
    800036be:	f45e                	sd	s7,40(sp)
    800036c0:	1880                	addi	s0,sp,112
    800036c2:	8aaa                	mv	s5,a0
    800036c4:	8bae                	mv	s7,a1
    800036c6:	8a32                	mv	s4,a2
    800036c8:	8936                	mv	s2,a3
    800036ca:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800036cc:	00e687bb          	addw	a5,a3,a4
    800036d0:	0ed7e063          	bltu	a5,a3,800037b0 <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800036d4:	00043737          	lui	a4,0x43
    800036d8:	0cf76e63          	bltu	a4,a5,800037b4 <writei+0x10a>
    800036dc:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800036de:	0a0b0f63          	beqz	s6,8000379c <writei+0xf2>
    800036e2:	eca6                	sd	s1,88(sp)
    800036e4:	f062                	sd	s8,32(sp)
    800036e6:	ec66                	sd	s9,24(sp)
    800036e8:	e86a                	sd	s10,16(sp)
    800036ea:	e46e                	sd	s11,8(sp)
    800036ec:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800036ee:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800036f2:	5c7d                	li	s8,-1
    800036f4:	a825                	j	8000372c <writei+0x82>
    800036f6:	020d1d93          	slli	s11,s10,0x20
    800036fa:	020ddd93          	srli	s11,s11,0x20
    800036fe:	05848513          	addi	a0,s1,88
    80003702:	86ee                	mv	a3,s11
    80003704:	8652                	mv	a2,s4
    80003706:	85de                	mv	a1,s7
    80003708:	953a                	add	a0,a0,a4
    8000370a:	bb1fe0ef          	jal	800022ba <either_copyin>
    8000370e:	05850a63          	beq	a0,s8,80003762 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003712:	8526                	mv	a0,s1
    80003714:	678000ef          	jal	80003d8c <log_write>
    brelse(bp);
    80003718:	8526                	mv	a0,s1
    8000371a:	d40ff0ef          	jal	80002c5a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000371e:	013d09bb          	addw	s3,s10,s3
    80003722:	012d093b          	addw	s2,s10,s2
    80003726:	9a6e                	add	s4,s4,s11
    80003728:	0569f063          	bgeu	s3,s6,80003768 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    8000372c:	00a9559b          	srliw	a1,s2,0xa
    80003730:	8556                	mv	a0,s5
    80003732:	fa4ff0ef          	jal	80002ed6 <bmap>
    80003736:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000373a:	c59d                	beqz	a1,80003768 <writei+0xbe>
    bp = bread(ip->dev, addr);
    8000373c:	000aa503          	lw	a0,0(s5)
    80003740:	c12ff0ef          	jal	80002b52 <bread>
    80003744:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003746:	3ff97713          	andi	a4,s2,1023
    8000374a:	40ec87bb          	subw	a5,s9,a4
    8000374e:	413b06bb          	subw	a3,s6,s3
    80003752:	8d3e                	mv	s10,a5
    80003754:	2781                	sext.w	a5,a5
    80003756:	0006861b          	sext.w	a2,a3
    8000375a:	f8f67ee3          	bgeu	a2,a5,800036f6 <writei+0x4c>
    8000375e:	8d36                	mv	s10,a3
    80003760:	bf59                	j	800036f6 <writei+0x4c>
      brelse(bp);
    80003762:	8526                	mv	a0,s1
    80003764:	cf6ff0ef          	jal	80002c5a <brelse>
  }

  if(off > ip->size)
    80003768:	04caa783          	lw	a5,76(s5)
    8000376c:	0327fa63          	bgeu	a5,s2,800037a0 <writei+0xf6>
    ip->size = off;
    80003770:	052aa623          	sw	s2,76(s5)
    80003774:	64e6                	ld	s1,88(sp)
    80003776:	7c02                	ld	s8,32(sp)
    80003778:	6ce2                	ld	s9,24(sp)
    8000377a:	6d42                	ld	s10,16(sp)
    8000377c:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000377e:	8556                	mv	a0,s5
    80003780:	9ebff0ef          	jal	8000316a <iupdate>

  return tot;
    80003784:	0009851b          	sext.w	a0,s3
    80003788:	69a6                	ld	s3,72(sp)
}
    8000378a:	70a6                	ld	ra,104(sp)
    8000378c:	7406                	ld	s0,96(sp)
    8000378e:	6946                	ld	s2,80(sp)
    80003790:	6a06                	ld	s4,64(sp)
    80003792:	7ae2                	ld	s5,56(sp)
    80003794:	7b42                	ld	s6,48(sp)
    80003796:	7ba2                	ld	s7,40(sp)
    80003798:	6165                	addi	sp,sp,112
    8000379a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000379c:	89da                	mv	s3,s6
    8000379e:	b7c5                	j	8000377e <writei+0xd4>
    800037a0:	64e6                	ld	s1,88(sp)
    800037a2:	7c02                	ld	s8,32(sp)
    800037a4:	6ce2                	ld	s9,24(sp)
    800037a6:	6d42                	ld	s10,16(sp)
    800037a8:	6da2                	ld	s11,8(sp)
    800037aa:	bfd1                	j	8000377e <writei+0xd4>
    return -1;
    800037ac:	557d                	li	a0,-1
}
    800037ae:	8082                	ret
    return -1;
    800037b0:	557d                	li	a0,-1
    800037b2:	bfe1                	j	8000378a <writei+0xe0>
    return -1;
    800037b4:	557d                	li	a0,-1
    800037b6:	bfd1                	j	8000378a <writei+0xe0>

00000000800037b8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800037b8:	1141                	addi	sp,sp,-16
    800037ba:	e406                	sd	ra,8(sp)
    800037bc:	e022                	sd	s0,0(sp)
    800037be:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800037c0:	4639                	li	a2,14
    800037c2:	ddefd0ef          	jal	80000da0 <strncmp>
}
    800037c6:	60a2                	ld	ra,8(sp)
    800037c8:	6402                	ld	s0,0(sp)
    800037ca:	0141                	addi	sp,sp,16
    800037cc:	8082                	ret

00000000800037ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800037ce:	7139                	addi	sp,sp,-64
    800037d0:	fc06                	sd	ra,56(sp)
    800037d2:	f822                	sd	s0,48(sp)
    800037d4:	f426                	sd	s1,40(sp)
    800037d6:	f04a                	sd	s2,32(sp)
    800037d8:	ec4e                	sd	s3,24(sp)
    800037da:	e852                	sd	s4,16(sp)
    800037dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800037de:	04451703          	lh	a4,68(a0)
    800037e2:	4785                	li	a5,1
    800037e4:	00f71a63          	bne	a4,a5,800037f8 <dirlookup+0x2a>
    800037e8:	892a                	mv	s2,a0
    800037ea:	89ae                	mv	s3,a1
    800037ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800037ee:	457c                	lw	a5,76(a0)
    800037f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800037f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800037f4:	e39d                	bnez	a5,8000381a <dirlookup+0x4c>
    800037f6:	a095                	j	8000385a <dirlookup+0x8c>
    panic("dirlookup not DIR");
    800037f8:	00004517          	auipc	a0,0x4
    800037fc:	cb050513          	addi	a0,a0,-848 # 800074a8 <etext+0x4a8>
    80003800:	812fd0ef          	jal	80000812 <panic>
      panic("dirlookup read");
    80003804:	00004517          	auipc	a0,0x4
    80003808:	cbc50513          	addi	a0,a0,-836 # 800074c0 <etext+0x4c0>
    8000380c:	806fd0ef          	jal	80000812 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003810:	24c1                	addiw	s1,s1,16
    80003812:	04c92783          	lw	a5,76(s2)
    80003816:	04f4f163          	bgeu	s1,a5,80003858 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000381a:	4741                	li	a4,16
    8000381c:	86a6                	mv	a3,s1
    8000381e:	fc040613          	addi	a2,s0,-64
    80003822:	4581                	li	a1,0
    80003824:	854a                	mv	a0,s2
    80003826:	d89ff0ef          	jal	800035ae <readi>
    8000382a:	47c1                	li	a5,16
    8000382c:	fcf51ce3          	bne	a0,a5,80003804 <dirlookup+0x36>
    if(de.inum == 0)
    80003830:	fc045783          	lhu	a5,-64(s0)
    80003834:	dff1                	beqz	a5,80003810 <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003836:	fc240593          	addi	a1,s0,-62
    8000383a:	854e                	mv	a0,s3
    8000383c:	f7dff0ef          	jal	800037b8 <namecmp>
    80003840:	f961                	bnez	a0,80003810 <dirlookup+0x42>
      if(poff)
    80003842:	000a0463          	beqz	s4,8000384a <dirlookup+0x7c>
        *poff = off;
    80003846:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000384a:	fc045583          	lhu	a1,-64(s0)
    8000384e:	00092503          	lw	a0,0(s2)
    80003852:	f58ff0ef          	jal	80002faa <iget>
    80003856:	a011                	j	8000385a <dirlookup+0x8c>
  return 0;
    80003858:	4501                	li	a0,0
}
    8000385a:	70e2                	ld	ra,56(sp)
    8000385c:	7442                	ld	s0,48(sp)
    8000385e:	74a2                	ld	s1,40(sp)
    80003860:	7902                	ld	s2,32(sp)
    80003862:	69e2                	ld	s3,24(sp)
    80003864:	6a42                	ld	s4,16(sp)
    80003866:	6121                	addi	sp,sp,64
    80003868:	8082                	ret

000000008000386a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000386a:	711d                	addi	sp,sp,-96
    8000386c:	ec86                	sd	ra,88(sp)
    8000386e:	e8a2                	sd	s0,80(sp)
    80003870:	e4a6                	sd	s1,72(sp)
    80003872:	e0ca                	sd	s2,64(sp)
    80003874:	fc4e                	sd	s3,56(sp)
    80003876:	f852                	sd	s4,48(sp)
    80003878:	f456                	sd	s5,40(sp)
    8000387a:	f05a                	sd	s6,32(sp)
    8000387c:	ec5e                	sd	s7,24(sp)
    8000387e:	e862                	sd	s8,16(sp)
    80003880:	e466                	sd	s9,8(sp)
    80003882:	1080                	addi	s0,sp,96
    80003884:	84aa                	mv	s1,a0
    80003886:	8b2e                	mv	s6,a1
    80003888:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000388a:	00054703          	lbu	a4,0(a0)
    8000388e:	02f00793          	li	a5,47
    80003892:	00f70e63          	beq	a4,a5,800038ae <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003896:	86efe0ef          	jal	80001904 <myproc>
    8000389a:	15053503          	ld	a0,336(a0)
    8000389e:	94bff0ef          	jal	800031e8 <idup>
    800038a2:	8a2a                	mv	s4,a0
  while(*path == '/')
    800038a4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800038a8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800038aa:	4b85                	li	s7,1
    800038ac:	a871                	j	80003948 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    800038ae:	4585                	li	a1,1
    800038b0:	4505                	li	a0,1
    800038b2:	ef8ff0ef          	jal	80002faa <iget>
    800038b6:	8a2a                	mv	s4,a0
    800038b8:	b7f5                	j	800038a4 <namex+0x3a>
      iunlockput(ip);
    800038ba:	8552                	mv	a0,s4
    800038bc:	b6dff0ef          	jal	80003428 <iunlockput>
      return 0;
    800038c0:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800038c2:	8552                	mv	a0,s4
    800038c4:	60e6                	ld	ra,88(sp)
    800038c6:	6446                	ld	s0,80(sp)
    800038c8:	64a6                	ld	s1,72(sp)
    800038ca:	6906                	ld	s2,64(sp)
    800038cc:	79e2                	ld	s3,56(sp)
    800038ce:	7a42                	ld	s4,48(sp)
    800038d0:	7aa2                	ld	s5,40(sp)
    800038d2:	7b02                	ld	s6,32(sp)
    800038d4:	6be2                	ld	s7,24(sp)
    800038d6:	6c42                	ld	s8,16(sp)
    800038d8:	6ca2                	ld	s9,8(sp)
    800038da:	6125                	addi	sp,sp,96
    800038dc:	8082                	ret
      iunlock(ip);
    800038de:	8552                	mv	a0,s4
    800038e0:	9edff0ef          	jal	800032cc <iunlock>
      return ip;
    800038e4:	bff9                	j	800038c2 <namex+0x58>
      iunlockput(ip);
    800038e6:	8552                	mv	a0,s4
    800038e8:	b41ff0ef          	jal	80003428 <iunlockput>
      return 0;
    800038ec:	8a4e                	mv	s4,s3
    800038ee:	bfd1                	j	800038c2 <namex+0x58>
  len = path - s;
    800038f0:	40998633          	sub	a2,s3,s1
    800038f4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800038f8:	099c5063          	bge	s8,s9,80003978 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    800038fc:	4639                	li	a2,14
    800038fe:	85a6                	mv	a1,s1
    80003900:	8556                	mv	a0,s5
    80003902:	c2efd0ef          	jal	80000d30 <memmove>
    80003906:	84ce                	mv	s1,s3
  while(*path == '/')
    80003908:	0004c783          	lbu	a5,0(s1)
    8000390c:	01279763          	bne	a5,s2,8000391a <namex+0xb0>
    path++;
    80003910:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003912:	0004c783          	lbu	a5,0(s1)
    80003916:	ff278de3          	beq	a5,s2,80003910 <namex+0xa6>
    ilock(ip);
    8000391a:	8552                	mv	a0,s4
    8000391c:	903ff0ef          	jal	8000321e <ilock>
    if(ip->type != T_DIR){
    80003920:	044a1783          	lh	a5,68(s4)
    80003924:	f9779be3          	bne	a5,s7,800038ba <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003928:	000b0563          	beqz	s6,80003932 <namex+0xc8>
    8000392c:	0004c783          	lbu	a5,0(s1)
    80003930:	d7dd                	beqz	a5,800038de <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003932:	4601                	li	a2,0
    80003934:	85d6                	mv	a1,s5
    80003936:	8552                	mv	a0,s4
    80003938:	e97ff0ef          	jal	800037ce <dirlookup>
    8000393c:	89aa                	mv	s3,a0
    8000393e:	d545                	beqz	a0,800038e6 <namex+0x7c>
    iunlockput(ip);
    80003940:	8552                	mv	a0,s4
    80003942:	ae7ff0ef          	jal	80003428 <iunlockput>
    ip = next;
    80003946:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003948:	0004c783          	lbu	a5,0(s1)
    8000394c:	01279763          	bne	a5,s2,8000395a <namex+0xf0>
    path++;
    80003950:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003952:	0004c783          	lbu	a5,0(s1)
    80003956:	ff278de3          	beq	a5,s2,80003950 <namex+0xe6>
  if(*path == 0)
    8000395a:	cb8d                	beqz	a5,8000398c <namex+0x122>
  while(*path != '/' && *path != 0)
    8000395c:	0004c783          	lbu	a5,0(s1)
    80003960:	89a6                	mv	s3,s1
  len = path - s;
    80003962:	4c81                	li	s9,0
    80003964:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003966:	01278963          	beq	a5,s2,80003978 <namex+0x10e>
    8000396a:	d3d9                	beqz	a5,800038f0 <namex+0x86>
    path++;
    8000396c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000396e:	0009c783          	lbu	a5,0(s3)
    80003972:	ff279ce3          	bne	a5,s2,8000396a <namex+0x100>
    80003976:	bfad                	j	800038f0 <namex+0x86>
    memmove(name, s, len);
    80003978:	2601                	sext.w	a2,a2
    8000397a:	85a6                	mv	a1,s1
    8000397c:	8556                	mv	a0,s5
    8000397e:	bb2fd0ef          	jal	80000d30 <memmove>
    name[len] = 0;
    80003982:	9cd6                	add	s9,s9,s5
    80003984:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003988:	84ce                	mv	s1,s3
    8000398a:	bfbd                	j	80003908 <namex+0x9e>
  if(nameiparent){
    8000398c:	f20b0be3          	beqz	s6,800038c2 <namex+0x58>
    iput(ip);
    80003990:	8552                	mv	a0,s4
    80003992:	a0fff0ef          	jal	800033a0 <iput>
    return 0;
    80003996:	4a01                	li	s4,0
    80003998:	b72d                	j	800038c2 <namex+0x58>

000000008000399a <dirlink>:
{
    8000399a:	7139                	addi	sp,sp,-64
    8000399c:	fc06                	sd	ra,56(sp)
    8000399e:	f822                	sd	s0,48(sp)
    800039a0:	f04a                	sd	s2,32(sp)
    800039a2:	ec4e                	sd	s3,24(sp)
    800039a4:	e852                	sd	s4,16(sp)
    800039a6:	0080                	addi	s0,sp,64
    800039a8:	892a                	mv	s2,a0
    800039aa:	8a2e                	mv	s4,a1
    800039ac:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800039ae:	4601                	li	a2,0
    800039b0:	e1fff0ef          	jal	800037ce <dirlookup>
    800039b4:	e535                	bnez	a0,80003a20 <dirlink+0x86>
    800039b6:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039b8:	04c92483          	lw	s1,76(s2)
    800039bc:	c48d                	beqz	s1,800039e6 <dirlink+0x4c>
    800039be:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800039c0:	4741                	li	a4,16
    800039c2:	86a6                	mv	a3,s1
    800039c4:	fc040613          	addi	a2,s0,-64
    800039c8:	4581                	li	a1,0
    800039ca:	854a                	mv	a0,s2
    800039cc:	be3ff0ef          	jal	800035ae <readi>
    800039d0:	47c1                	li	a5,16
    800039d2:	04f51b63          	bne	a0,a5,80003a28 <dirlink+0x8e>
    if(de.inum == 0)
    800039d6:	fc045783          	lhu	a5,-64(s0)
    800039da:	c791                	beqz	a5,800039e6 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039dc:	24c1                	addiw	s1,s1,16
    800039de:	04c92783          	lw	a5,76(s2)
    800039e2:	fcf4efe3          	bltu	s1,a5,800039c0 <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    800039e6:	4639                	li	a2,14
    800039e8:	85d2                	mv	a1,s4
    800039ea:	fc240513          	addi	a0,s0,-62
    800039ee:	be8fd0ef          	jal	80000dd6 <strncpy>
  de.inum = inum;
    800039f2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800039f6:	4741                	li	a4,16
    800039f8:	86a6                	mv	a3,s1
    800039fa:	fc040613          	addi	a2,s0,-64
    800039fe:	4581                	li	a1,0
    80003a00:	854a                	mv	a0,s2
    80003a02:	ca9ff0ef          	jal	800036aa <writei>
    80003a06:	1541                	addi	a0,a0,-16
    80003a08:	00a03533          	snez	a0,a0
    80003a0c:	40a00533          	neg	a0,a0
    80003a10:	74a2                	ld	s1,40(sp)
}
    80003a12:	70e2                	ld	ra,56(sp)
    80003a14:	7442                	ld	s0,48(sp)
    80003a16:	7902                	ld	s2,32(sp)
    80003a18:	69e2                	ld	s3,24(sp)
    80003a1a:	6a42                	ld	s4,16(sp)
    80003a1c:	6121                	addi	sp,sp,64
    80003a1e:	8082                	ret
    iput(ip);
    80003a20:	981ff0ef          	jal	800033a0 <iput>
    return -1;
    80003a24:	557d                	li	a0,-1
    80003a26:	b7f5                	j	80003a12 <dirlink+0x78>
      panic("dirlink read");
    80003a28:	00004517          	auipc	a0,0x4
    80003a2c:	aa850513          	addi	a0,a0,-1368 # 800074d0 <etext+0x4d0>
    80003a30:	de3fc0ef          	jal	80000812 <panic>

0000000080003a34 <namei>:

struct inode*
namei(char *path)
{
    80003a34:	1101                	addi	sp,sp,-32
    80003a36:	ec06                	sd	ra,24(sp)
    80003a38:	e822                	sd	s0,16(sp)
    80003a3a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003a3c:	fe040613          	addi	a2,s0,-32
    80003a40:	4581                	li	a1,0
    80003a42:	e29ff0ef          	jal	8000386a <namex>
}
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	6105                	addi	sp,sp,32
    80003a4c:	8082                	ret

0000000080003a4e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003a4e:	1141                	addi	sp,sp,-16
    80003a50:	e406                	sd	ra,8(sp)
    80003a52:	e022                	sd	s0,0(sp)
    80003a54:	0800                	addi	s0,sp,16
    80003a56:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003a58:	4585                	li	a1,1
    80003a5a:	e11ff0ef          	jal	8000386a <namex>
}
    80003a5e:	60a2                	ld	ra,8(sp)
    80003a60:	6402                	ld	s0,0(sp)
    80003a62:	0141                	addi	sp,sp,16
    80003a64:	8082                	ret

0000000080003a66 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003a66:	1101                	addi	sp,sp,-32
    80003a68:	ec06                	sd	ra,24(sp)
    80003a6a:	e822                	sd	s0,16(sp)
    80003a6c:	e426                	sd	s1,8(sp)
    80003a6e:	e04a                	sd	s2,0(sp)
    80003a70:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003a72:	0001c917          	auipc	s2,0x1c
    80003a76:	f2690913          	addi	s2,s2,-218 # 8001f998 <log>
    80003a7a:	01892583          	lw	a1,24(s2)
    80003a7e:	02492503          	lw	a0,36(s2)
    80003a82:	8d0ff0ef          	jal	80002b52 <bread>
    80003a86:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003a88:	02892603          	lw	a2,40(s2)
    80003a8c:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003a8e:	00c05f63          	blez	a2,80003aac <write_head+0x46>
    80003a92:	0001c717          	auipc	a4,0x1c
    80003a96:	f3270713          	addi	a4,a4,-206 # 8001f9c4 <log+0x2c>
    80003a9a:	87aa                	mv	a5,a0
    80003a9c:	060a                	slli	a2,a2,0x2
    80003a9e:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003aa0:	4314                	lw	a3,0(a4)
    80003aa2:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003aa4:	0711                	addi	a4,a4,4
    80003aa6:	0791                	addi	a5,a5,4
    80003aa8:	fec79ce3          	bne	a5,a2,80003aa0 <write_head+0x3a>
  }
  bwrite(buf);
    80003aac:	8526                	mv	a0,s1
    80003aae:	97aff0ef          	jal	80002c28 <bwrite>
  brelse(buf);
    80003ab2:	8526                	mv	a0,s1
    80003ab4:	9a6ff0ef          	jal	80002c5a <brelse>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	64a2                	ld	s1,8(sp)
    80003abe:	6902                	ld	s2,0(sp)
    80003ac0:	6105                	addi	sp,sp,32
    80003ac2:	8082                	ret

0000000080003ac4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ac4:	0001c797          	auipc	a5,0x1c
    80003ac8:	efc7a783          	lw	a5,-260(a5) # 8001f9c0 <log+0x28>
    80003acc:	0af05e63          	blez	a5,80003b88 <install_trans+0xc4>
{
    80003ad0:	715d                	addi	sp,sp,-80
    80003ad2:	e486                	sd	ra,72(sp)
    80003ad4:	e0a2                	sd	s0,64(sp)
    80003ad6:	fc26                	sd	s1,56(sp)
    80003ad8:	f84a                	sd	s2,48(sp)
    80003ada:	f44e                	sd	s3,40(sp)
    80003adc:	f052                	sd	s4,32(sp)
    80003ade:	ec56                	sd	s5,24(sp)
    80003ae0:	e85a                	sd	s6,16(sp)
    80003ae2:	e45e                	sd	s7,8(sp)
    80003ae4:	0880                	addi	s0,sp,80
    80003ae6:	8b2a                	mv	s6,a0
    80003ae8:	0001ca97          	auipc	s5,0x1c
    80003aec:	edca8a93          	addi	s5,s5,-292 # 8001f9c4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003af0:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003af2:	00004b97          	auipc	s7,0x4
    80003af6:	9eeb8b93          	addi	s7,s7,-1554 # 800074e0 <etext+0x4e0>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003afa:	0001ca17          	auipc	s4,0x1c
    80003afe:	e9ea0a13          	addi	s4,s4,-354 # 8001f998 <log>
    80003b02:	a025                	j	80003b2a <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003b04:	000aa603          	lw	a2,0(s5)
    80003b08:	85ce                	mv	a1,s3
    80003b0a:	855e                	mv	a0,s7
    80003b0c:	a21fc0ef          	jal	8000052c <printf>
    80003b10:	a839                	j	80003b2e <install_trans+0x6a>
    brelse(lbuf);
    80003b12:	854a                	mv	a0,s2
    80003b14:	946ff0ef          	jal	80002c5a <brelse>
    brelse(dbuf);
    80003b18:	8526                	mv	a0,s1
    80003b1a:	940ff0ef          	jal	80002c5a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b1e:	2985                	addiw	s3,s3,1
    80003b20:	0a91                	addi	s5,s5,4
    80003b22:	028a2783          	lw	a5,40(s4)
    80003b26:	04f9d663          	bge	s3,a5,80003b72 <install_trans+0xae>
    if(recovering) {
    80003b2a:	fc0b1de3          	bnez	s6,80003b04 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b2e:	018a2583          	lw	a1,24(s4)
    80003b32:	013585bb          	addw	a1,a1,s3
    80003b36:	2585                	addiw	a1,a1,1
    80003b38:	024a2503          	lw	a0,36(s4)
    80003b3c:	816ff0ef          	jal	80002b52 <bread>
    80003b40:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003b42:	000aa583          	lw	a1,0(s5)
    80003b46:	024a2503          	lw	a0,36(s4)
    80003b4a:	808ff0ef          	jal	80002b52 <bread>
    80003b4e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003b50:	40000613          	li	a2,1024
    80003b54:	05890593          	addi	a1,s2,88
    80003b58:	05850513          	addi	a0,a0,88
    80003b5c:	9d4fd0ef          	jal	80000d30 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003b60:	8526                	mv	a0,s1
    80003b62:	8c6ff0ef          	jal	80002c28 <bwrite>
    if(recovering == 0)
    80003b66:	fa0b16e3          	bnez	s6,80003b12 <install_trans+0x4e>
      bunpin(dbuf);
    80003b6a:	8526                	mv	a0,s1
    80003b6c:	9aaff0ef          	jal	80002d16 <bunpin>
    80003b70:	b74d                	j	80003b12 <install_trans+0x4e>
}
    80003b72:	60a6                	ld	ra,72(sp)
    80003b74:	6406                	ld	s0,64(sp)
    80003b76:	74e2                	ld	s1,56(sp)
    80003b78:	7942                	ld	s2,48(sp)
    80003b7a:	79a2                	ld	s3,40(sp)
    80003b7c:	7a02                	ld	s4,32(sp)
    80003b7e:	6ae2                	ld	s5,24(sp)
    80003b80:	6b42                	ld	s6,16(sp)
    80003b82:	6ba2                	ld	s7,8(sp)
    80003b84:	6161                	addi	sp,sp,80
    80003b86:	8082                	ret
    80003b88:	8082                	ret

0000000080003b8a <initlog>:
{
    80003b8a:	7179                	addi	sp,sp,-48
    80003b8c:	f406                	sd	ra,40(sp)
    80003b8e:	f022                	sd	s0,32(sp)
    80003b90:	ec26                	sd	s1,24(sp)
    80003b92:	e84a                	sd	s2,16(sp)
    80003b94:	e44e                	sd	s3,8(sp)
    80003b96:	1800                	addi	s0,sp,48
    80003b98:	892a                	mv	s2,a0
    80003b9a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003b9c:	0001c497          	auipc	s1,0x1c
    80003ba0:	dfc48493          	addi	s1,s1,-516 # 8001f998 <log>
    80003ba4:	00004597          	auipc	a1,0x4
    80003ba8:	95c58593          	addi	a1,a1,-1700 # 80007500 <etext+0x500>
    80003bac:	8526                	mv	a0,s1
    80003bae:	fd3fc0ef          	jal	80000b80 <initlock>
  log.start = sb->logstart;
    80003bb2:	0149a583          	lw	a1,20(s3)
    80003bb6:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003bb8:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	f95fe0ef          	jal	80002b52 <bread>
  log.lh.n = lh->n;
    80003bc2:	4d30                	lw	a2,88(a0)
    80003bc4:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003bc6:	00c05f63          	blez	a2,80003be4 <initlog+0x5a>
    80003bca:	87aa                	mv	a5,a0
    80003bcc:	0001c717          	auipc	a4,0x1c
    80003bd0:	df870713          	addi	a4,a4,-520 # 8001f9c4 <log+0x2c>
    80003bd4:	060a                	slli	a2,a2,0x2
    80003bd6:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003bd8:	4ff4                	lw	a3,92(a5)
    80003bda:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003bdc:	0791                	addi	a5,a5,4
    80003bde:	0711                	addi	a4,a4,4
    80003be0:	fec79ce3          	bne	a5,a2,80003bd8 <initlog+0x4e>
  brelse(buf);
    80003be4:	876ff0ef          	jal	80002c5a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003be8:	4505                	li	a0,1
    80003bea:	edbff0ef          	jal	80003ac4 <install_trans>
  log.lh.n = 0;
    80003bee:	0001c797          	auipc	a5,0x1c
    80003bf2:	dc07a923          	sw	zero,-558(a5) # 8001f9c0 <log+0x28>
  write_head(); // clear the log
    80003bf6:	e71ff0ef          	jal	80003a66 <write_head>
}
    80003bfa:	70a2                	ld	ra,40(sp)
    80003bfc:	7402                	ld	s0,32(sp)
    80003bfe:	64e2                	ld	s1,24(sp)
    80003c00:	6942                	ld	s2,16(sp)
    80003c02:	69a2                	ld	s3,8(sp)
    80003c04:	6145                	addi	sp,sp,48
    80003c06:	8082                	ret

0000000080003c08 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003c08:	1101                	addi	sp,sp,-32
    80003c0a:	ec06                	sd	ra,24(sp)
    80003c0c:	e822                	sd	s0,16(sp)
    80003c0e:	e426                	sd	s1,8(sp)
    80003c10:	e04a                	sd	s2,0(sp)
    80003c12:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003c14:	0001c517          	auipc	a0,0x1c
    80003c18:	d8450513          	addi	a0,a0,-636 # 8001f998 <log>
    80003c1c:	fe5fc0ef          	jal	80000c00 <acquire>
  while(1){
    if(log.committing){
    80003c20:	0001c497          	auipc	s1,0x1c
    80003c24:	d7848493          	addi	s1,s1,-648 # 8001f998 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c28:	4979                	li	s2,30
    80003c2a:	a029                	j	80003c34 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003c2c:	85a6                	mv	a1,s1
    80003c2e:	8526                	mv	a0,s1
    80003c30:	ae4fe0ef          	jal	80001f14 <sleep>
    if(log.committing){
    80003c34:	509c                	lw	a5,32(s1)
    80003c36:	fbfd                	bnez	a5,80003c2c <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c38:	4cd8                	lw	a4,28(s1)
    80003c3a:	2705                	addiw	a4,a4,1
    80003c3c:	0027179b          	slliw	a5,a4,0x2
    80003c40:	9fb9                	addw	a5,a5,a4
    80003c42:	0017979b          	slliw	a5,a5,0x1
    80003c46:	5494                	lw	a3,40(s1)
    80003c48:	9fb5                	addw	a5,a5,a3
    80003c4a:	00f95763          	bge	s2,a5,80003c58 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003c4e:	85a6                	mv	a1,s1
    80003c50:	8526                	mv	a0,s1
    80003c52:	ac2fe0ef          	jal	80001f14 <sleep>
    80003c56:	bff9                	j	80003c34 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003c58:	0001c517          	auipc	a0,0x1c
    80003c5c:	d4050513          	addi	a0,a0,-704 # 8001f998 <log>
    80003c60:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003c62:	836fd0ef          	jal	80000c98 <release>
      break;
    }
  }
}
    80003c66:	60e2                	ld	ra,24(sp)
    80003c68:	6442                	ld	s0,16(sp)
    80003c6a:	64a2                	ld	s1,8(sp)
    80003c6c:	6902                	ld	s2,0(sp)
    80003c6e:	6105                	addi	sp,sp,32
    80003c70:	8082                	ret

0000000080003c72 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003c72:	7139                	addi	sp,sp,-64
    80003c74:	fc06                	sd	ra,56(sp)
    80003c76:	f822                	sd	s0,48(sp)
    80003c78:	f426                	sd	s1,40(sp)
    80003c7a:	f04a                	sd	s2,32(sp)
    80003c7c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003c7e:	0001c497          	auipc	s1,0x1c
    80003c82:	d1a48493          	addi	s1,s1,-742 # 8001f998 <log>
    80003c86:	8526                	mv	a0,s1
    80003c88:	f79fc0ef          	jal	80000c00 <acquire>
  log.outstanding -= 1;
    80003c8c:	4cdc                	lw	a5,28(s1)
    80003c8e:	37fd                	addiw	a5,a5,-1
    80003c90:	0007891b          	sext.w	s2,a5
    80003c94:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003c96:	509c                	lw	a5,32(s1)
    80003c98:	ef9d                	bnez	a5,80003cd6 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003c9a:	04091763          	bnez	s2,80003ce8 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003c9e:	0001c497          	auipc	s1,0x1c
    80003ca2:	cfa48493          	addi	s1,s1,-774 # 8001f998 <log>
    80003ca6:	4785                	li	a5,1
    80003ca8:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003caa:	8526                	mv	a0,s1
    80003cac:	fedfc0ef          	jal	80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003cb0:	549c                	lw	a5,40(s1)
    80003cb2:	04f04b63          	bgtz	a5,80003d08 <end_op+0x96>
    acquire(&log.lock);
    80003cb6:	0001c497          	auipc	s1,0x1c
    80003cba:	ce248493          	addi	s1,s1,-798 # 8001f998 <log>
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	f41fc0ef          	jal	80000c00 <acquire>
    log.committing = 0;
    80003cc4:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	a96fe0ef          	jal	80001f60 <wakeup>
    release(&log.lock);
    80003cce:	8526                	mv	a0,s1
    80003cd0:	fc9fc0ef          	jal	80000c98 <release>
}
    80003cd4:	a025                	j	80003cfc <end_op+0x8a>
    80003cd6:	ec4e                	sd	s3,24(sp)
    80003cd8:	e852                	sd	s4,16(sp)
    80003cda:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80003cdc:	00004517          	auipc	a0,0x4
    80003ce0:	82c50513          	addi	a0,a0,-2004 # 80007508 <etext+0x508>
    80003ce4:	b2ffc0ef          	jal	80000812 <panic>
    wakeup(&log);
    80003ce8:	0001c497          	auipc	s1,0x1c
    80003cec:	cb048493          	addi	s1,s1,-848 # 8001f998 <log>
    80003cf0:	8526                	mv	a0,s1
    80003cf2:	a6efe0ef          	jal	80001f60 <wakeup>
  release(&log.lock);
    80003cf6:	8526                	mv	a0,s1
    80003cf8:	fa1fc0ef          	jal	80000c98 <release>
}
    80003cfc:	70e2                	ld	ra,56(sp)
    80003cfe:	7442                	ld	s0,48(sp)
    80003d00:	74a2                	ld	s1,40(sp)
    80003d02:	7902                	ld	s2,32(sp)
    80003d04:	6121                	addi	sp,sp,64
    80003d06:	8082                	ret
    80003d08:	ec4e                	sd	s3,24(sp)
    80003d0a:	e852                	sd	s4,16(sp)
    80003d0c:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d0e:	0001ca97          	auipc	s5,0x1c
    80003d12:	cb6a8a93          	addi	s5,s5,-842 # 8001f9c4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003d16:	0001ca17          	auipc	s4,0x1c
    80003d1a:	c82a0a13          	addi	s4,s4,-894 # 8001f998 <log>
    80003d1e:	018a2583          	lw	a1,24(s4)
    80003d22:	012585bb          	addw	a1,a1,s2
    80003d26:	2585                	addiw	a1,a1,1
    80003d28:	024a2503          	lw	a0,36(s4)
    80003d2c:	e27fe0ef          	jal	80002b52 <bread>
    80003d30:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003d32:	000aa583          	lw	a1,0(s5)
    80003d36:	024a2503          	lw	a0,36(s4)
    80003d3a:	e19fe0ef          	jal	80002b52 <bread>
    80003d3e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003d40:	40000613          	li	a2,1024
    80003d44:	05850593          	addi	a1,a0,88
    80003d48:	05848513          	addi	a0,s1,88
    80003d4c:	fe5fc0ef          	jal	80000d30 <memmove>
    bwrite(to);  // write the log
    80003d50:	8526                	mv	a0,s1
    80003d52:	ed7fe0ef          	jal	80002c28 <bwrite>
    brelse(from);
    80003d56:	854e                	mv	a0,s3
    80003d58:	f03fe0ef          	jal	80002c5a <brelse>
    brelse(to);
    80003d5c:	8526                	mv	a0,s1
    80003d5e:	efdfe0ef          	jal	80002c5a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d62:	2905                	addiw	s2,s2,1
    80003d64:	0a91                	addi	s5,s5,4
    80003d66:	028a2783          	lw	a5,40(s4)
    80003d6a:	faf94ae3          	blt	s2,a5,80003d1e <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003d6e:	cf9ff0ef          	jal	80003a66 <write_head>
    install_trans(0); // Now install writes to home locations
    80003d72:	4501                	li	a0,0
    80003d74:	d51ff0ef          	jal	80003ac4 <install_trans>
    log.lh.n = 0;
    80003d78:	0001c797          	auipc	a5,0x1c
    80003d7c:	c407a423          	sw	zero,-952(a5) # 8001f9c0 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003d80:	ce7ff0ef          	jal	80003a66 <write_head>
    80003d84:	69e2                	ld	s3,24(sp)
    80003d86:	6a42                	ld	s4,16(sp)
    80003d88:	6aa2                	ld	s5,8(sp)
    80003d8a:	b735                	j	80003cb6 <end_op+0x44>

0000000080003d8c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003d8c:	1101                	addi	sp,sp,-32
    80003d8e:	ec06                	sd	ra,24(sp)
    80003d90:	e822                	sd	s0,16(sp)
    80003d92:	e426                	sd	s1,8(sp)
    80003d94:	e04a                	sd	s2,0(sp)
    80003d96:	1000                	addi	s0,sp,32
    80003d98:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003d9a:	0001c917          	auipc	s2,0x1c
    80003d9e:	bfe90913          	addi	s2,s2,-1026 # 8001f998 <log>
    80003da2:	854a                	mv	a0,s2
    80003da4:	e5dfc0ef          	jal	80000c00 <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003da8:	02892603          	lw	a2,40(s2)
    80003dac:	47f5                	li	a5,29
    80003dae:	04c7cc63          	blt	a5,a2,80003e06 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003db2:	0001c797          	auipc	a5,0x1c
    80003db6:	c027a783          	lw	a5,-1022(a5) # 8001f9b4 <log+0x1c>
    80003dba:	04f05c63          	blez	a5,80003e12 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003dbe:	4781                	li	a5,0
    80003dc0:	04c05f63          	blez	a2,80003e1e <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003dc4:	44cc                	lw	a1,12(s1)
    80003dc6:	0001c717          	auipc	a4,0x1c
    80003dca:	bfe70713          	addi	a4,a4,-1026 # 8001f9c4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003dce:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003dd0:	4314                	lw	a3,0(a4)
    80003dd2:	04b68663          	beq	a3,a1,80003e1e <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003dd6:	2785                	addiw	a5,a5,1
    80003dd8:	0711                	addi	a4,a4,4
    80003dda:	fef61be3          	bne	a2,a5,80003dd0 <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003dde:	0621                	addi	a2,a2,8
    80003de0:	060a                	slli	a2,a2,0x2
    80003de2:	0001c797          	auipc	a5,0x1c
    80003de6:	bb678793          	addi	a5,a5,-1098 # 8001f998 <log>
    80003dea:	97b2                	add	a5,a5,a2
    80003dec:	44d8                	lw	a4,12(s1)
    80003dee:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003df0:	8526                	mv	a0,s1
    80003df2:	ef1fe0ef          	jal	80002ce2 <bpin>
    log.lh.n++;
    80003df6:	0001c717          	auipc	a4,0x1c
    80003dfa:	ba270713          	addi	a4,a4,-1118 # 8001f998 <log>
    80003dfe:	571c                	lw	a5,40(a4)
    80003e00:	2785                	addiw	a5,a5,1
    80003e02:	d71c                	sw	a5,40(a4)
    80003e04:	a80d                	j	80003e36 <log_write+0xaa>
    panic("too big a transaction");
    80003e06:	00003517          	auipc	a0,0x3
    80003e0a:	71250513          	addi	a0,a0,1810 # 80007518 <etext+0x518>
    80003e0e:	a05fc0ef          	jal	80000812 <panic>
    panic("log_write outside of trans");
    80003e12:	00003517          	auipc	a0,0x3
    80003e16:	71e50513          	addi	a0,a0,1822 # 80007530 <etext+0x530>
    80003e1a:	9f9fc0ef          	jal	80000812 <panic>
  log.lh.block[i] = b->blockno;
    80003e1e:	00878693          	addi	a3,a5,8
    80003e22:	068a                	slli	a3,a3,0x2
    80003e24:	0001c717          	auipc	a4,0x1c
    80003e28:	b7470713          	addi	a4,a4,-1164 # 8001f998 <log>
    80003e2c:	9736                	add	a4,a4,a3
    80003e2e:	44d4                	lw	a3,12(s1)
    80003e30:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003e32:	faf60fe3          	beq	a2,a5,80003df0 <log_write+0x64>
  }
  release(&log.lock);
    80003e36:	0001c517          	auipc	a0,0x1c
    80003e3a:	b6250513          	addi	a0,a0,-1182 # 8001f998 <log>
    80003e3e:	e5bfc0ef          	jal	80000c98 <release>
}
    80003e42:	60e2                	ld	ra,24(sp)
    80003e44:	6442                	ld	s0,16(sp)
    80003e46:	64a2                	ld	s1,8(sp)
    80003e48:	6902                	ld	s2,0(sp)
    80003e4a:	6105                	addi	sp,sp,32
    80003e4c:	8082                	ret

0000000080003e4e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	e426                	sd	s1,8(sp)
    80003e56:	e04a                	sd	s2,0(sp)
    80003e58:	1000                	addi	s0,sp,32
    80003e5a:	84aa                	mv	s1,a0
    80003e5c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003e5e:	00003597          	auipc	a1,0x3
    80003e62:	6f258593          	addi	a1,a1,1778 # 80007550 <etext+0x550>
    80003e66:	0521                	addi	a0,a0,8
    80003e68:	d19fc0ef          	jal	80000b80 <initlock>
  lk->name = name;
    80003e6c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003e70:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003e74:	0204a423          	sw	zero,40(s1)
}
    80003e78:	60e2                	ld	ra,24(sp)
    80003e7a:	6442                	ld	s0,16(sp)
    80003e7c:	64a2                	ld	s1,8(sp)
    80003e7e:	6902                	ld	s2,0(sp)
    80003e80:	6105                	addi	sp,sp,32
    80003e82:	8082                	ret

0000000080003e84 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003e84:	1101                	addi	sp,sp,-32
    80003e86:	ec06                	sd	ra,24(sp)
    80003e88:	e822                	sd	s0,16(sp)
    80003e8a:	e426                	sd	s1,8(sp)
    80003e8c:	e04a                	sd	s2,0(sp)
    80003e8e:	1000                	addi	s0,sp,32
    80003e90:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003e92:	00850913          	addi	s2,a0,8
    80003e96:	854a                	mv	a0,s2
    80003e98:	d69fc0ef          	jal	80000c00 <acquire>
  while (lk->locked) {
    80003e9c:	409c                	lw	a5,0(s1)
    80003e9e:	c799                	beqz	a5,80003eac <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003ea0:	85ca                	mv	a1,s2
    80003ea2:	8526                	mv	a0,s1
    80003ea4:	870fe0ef          	jal	80001f14 <sleep>
  while (lk->locked) {
    80003ea8:	409c                	lw	a5,0(s1)
    80003eaa:	fbfd                	bnez	a5,80003ea0 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003eac:	4785                	li	a5,1
    80003eae:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003eb0:	a55fd0ef          	jal	80001904 <myproc>
    80003eb4:	591c                	lw	a5,48(a0)
    80003eb6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003eb8:	854a                	mv	a0,s2
    80003eba:	ddffc0ef          	jal	80000c98 <release>
}
    80003ebe:	60e2                	ld	ra,24(sp)
    80003ec0:	6442                	ld	s0,16(sp)
    80003ec2:	64a2                	ld	s1,8(sp)
    80003ec4:	6902                	ld	s2,0(sp)
    80003ec6:	6105                	addi	sp,sp,32
    80003ec8:	8082                	ret

0000000080003eca <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003eca:	1101                	addi	sp,sp,-32
    80003ecc:	ec06                	sd	ra,24(sp)
    80003ece:	e822                	sd	s0,16(sp)
    80003ed0:	e426                	sd	s1,8(sp)
    80003ed2:	e04a                	sd	s2,0(sp)
    80003ed4:	1000                	addi	s0,sp,32
    80003ed6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003ed8:	00850913          	addi	s2,a0,8
    80003edc:	854a                	mv	a0,s2
    80003ede:	d23fc0ef          	jal	80000c00 <acquire>
  lk->locked = 0;
    80003ee2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003ee6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003eea:	8526                	mv	a0,s1
    80003eec:	874fe0ef          	jal	80001f60 <wakeup>
  release(&lk->lk);
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	da7fc0ef          	jal	80000c98 <release>
}
    80003ef6:	60e2                	ld	ra,24(sp)
    80003ef8:	6442                	ld	s0,16(sp)
    80003efa:	64a2                	ld	s1,8(sp)
    80003efc:	6902                	ld	s2,0(sp)
    80003efe:	6105                	addi	sp,sp,32
    80003f00:	8082                	ret

0000000080003f02 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003f02:	7179                	addi	sp,sp,-48
    80003f04:	f406                	sd	ra,40(sp)
    80003f06:	f022                	sd	s0,32(sp)
    80003f08:	ec26                	sd	s1,24(sp)
    80003f0a:	e84a                	sd	s2,16(sp)
    80003f0c:	1800                	addi	s0,sp,48
    80003f0e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003f10:	00850913          	addi	s2,a0,8
    80003f14:	854a                	mv	a0,s2
    80003f16:	cebfc0ef          	jal	80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f1a:	409c                	lw	a5,0(s1)
    80003f1c:	ef81                	bnez	a5,80003f34 <holdingsleep+0x32>
    80003f1e:	4481                	li	s1,0
  release(&lk->lk);
    80003f20:	854a                	mv	a0,s2
    80003f22:	d77fc0ef          	jal	80000c98 <release>
  return r;
}
    80003f26:	8526                	mv	a0,s1
    80003f28:	70a2                	ld	ra,40(sp)
    80003f2a:	7402                	ld	s0,32(sp)
    80003f2c:	64e2                	ld	s1,24(sp)
    80003f2e:	6942                	ld	s2,16(sp)
    80003f30:	6145                	addi	sp,sp,48
    80003f32:	8082                	ret
    80003f34:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f36:	0284a983          	lw	s3,40(s1)
    80003f3a:	9cbfd0ef          	jal	80001904 <myproc>
    80003f3e:	5904                	lw	s1,48(a0)
    80003f40:	413484b3          	sub	s1,s1,s3
    80003f44:	0014b493          	seqz	s1,s1
    80003f48:	69a2                	ld	s3,8(sp)
    80003f4a:	bfd9                	j	80003f20 <holdingsleep+0x1e>

0000000080003f4c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80003f4c:	1141                	addi	sp,sp,-16
    80003f4e:	e406                	sd	ra,8(sp)
    80003f50:	e022                	sd	s0,0(sp)
    80003f52:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80003f54:	00003597          	auipc	a1,0x3
    80003f58:	60c58593          	addi	a1,a1,1548 # 80007560 <etext+0x560>
    80003f5c:	0001c517          	auipc	a0,0x1c
    80003f60:	b8450513          	addi	a0,a0,-1148 # 8001fae0 <ftable>
    80003f64:	c1dfc0ef          	jal	80000b80 <initlock>
}
    80003f68:	60a2                	ld	ra,8(sp)
    80003f6a:	6402                	ld	s0,0(sp)
    80003f6c:	0141                	addi	sp,sp,16
    80003f6e:	8082                	ret

0000000080003f70 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80003f70:	1101                	addi	sp,sp,-32
    80003f72:	ec06                	sd	ra,24(sp)
    80003f74:	e822                	sd	s0,16(sp)
    80003f76:	e426                	sd	s1,8(sp)
    80003f78:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80003f7a:	0001c517          	auipc	a0,0x1c
    80003f7e:	b6650513          	addi	a0,a0,-1178 # 8001fae0 <ftable>
    80003f82:	c7ffc0ef          	jal	80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003f86:	0001c497          	auipc	s1,0x1c
    80003f8a:	b7248493          	addi	s1,s1,-1166 # 8001faf8 <ftable+0x18>
    80003f8e:	0001d717          	auipc	a4,0x1d
    80003f92:	b0a70713          	addi	a4,a4,-1270 # 80020a98 <disk>
    if(f->ref == 0){
    80003f96:	40dc                	lw	a5,4(s1)
    80003f98:	cf89                	beqz	a5,80003fb2 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003f9a:	02848493          	addi	s1,s1,40
    80003f9e:	fee49ce3          	bne	s1,a4,80003f96 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80003fa2:	0001c517          	auipc	a0,0x1c
    80003fa6:	b3e50513          	addi	a0,a0,-1218 # 8001fae0 <ftable>
    80003faa:	ceffc0ef          	jal	80000c98 <release>
  return 0;
    80003fae:	4481                	li	s1,0
    80003fb0:	a809                	j	80003fc2 <filealloc+0x52>
      f->ref = 1;
    80003fb2:	4785                	li	a5,1
    80003fb4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80003fb6:	0001c517          	auipc	a0,0x1c
    80003fba:	b2a50513          	addi	a0,a0,-1238 # 8001fae0 <ftable>
    80003fbe:	cdbfc0ef          	jal	80000c98 <release>
}
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	60e2                	ld	ra,24(sp)
    80003fc6:	6442                	ld	s0,16(sp)
    80003fc8:	64a2                	ld	s1,8(sp)
    80003fca:	6105                	addi	sp,sp,32
    80003fcc:	8082                	ret

0000000080003fce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80003fce:	1101                	addi	sp,sp,-32
    80003fd0:	ec06                	sd	ra,24(sp)
    80003fd2:	e822                	sd	s0,16(sp)
    80003fd4:	e426                	sd	s1,8(sp)
    80003fd6:	1000                	addi	s0,sp,32
    80003fd8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80003fda:	0001c517          	auipc	a0,0x1c
    80003fde:	b0650513          	addi	a0,a0,-1274 # 8001fae0 <ftable>
    80003fe2:	c1ffc0ef          	jal	80000c00 <acquire>
  if(f->ref < 1)
    80003fe6:	40dc                	lw	a5,4(s1)
    80003fe8:	02f05063          	blez	a5,80004008 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80003fec:	2785                	addiw	a5,a5,1
    80003fee:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80003ff0:	0001c517          	auipc	a0,0x1c
    80003ff4:	af050513          	addi	a0,a0,-1296 # 8001fae0 <ftable>
    80003ff8:	ca1fc0ef          	jal	80000c98 <release>
  return f;
}
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	60e2                	ld	ra,24(sp)
    80004000:	6442                	ld	s0,16(sp)
    80004002:	64a2                	ld	s1,8(sp)
    80004004:	6105                	addi	sp,sp,32
    80004006:	8082                	ret
    panic("filedup");
    80004008:	00003517          	auipc	a0,0x3
    8000400c:	56050513          	addi	a0,a0,1376 # 80007568 <etext+0x568>
    80004010:	803fc0ef          	jal	80000812 <panic>

0000000080004014 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004014:	7139                	addi	sp,sp,-64
    80004016:	fc06                	sd	ra,56(sp)
    80004018:	f822                	sd	s0,48(sp)
    8000401a:	f426                	sd	s1,40(sp)
    8000401c:	0080                	addi	s0,sp,64
    8000401e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004020:	0001c517          	auipc	a0,0x1c
    80004024:	ac050513          	addi	a0,a0,-1344 # 8001fae0 <ftable>
    80004028:	bd9fc0ef          	jal	80000c00 <acquire>
  if(f->ref < 1)
    8000402c:	40dc                	lw	a5,4(s1)
    8000402e:	04f05a63          	blez	a5,80004082 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    80004032:	37fd                	addiw	a5,a5,-1
    80004034:	0007871b          	sext.w	a4,a5
    80004038:	c0dc                	sw	a5,4(s1)
    8000403a:	04e04e63          	bgtz	a4,80004096 <fileclose+0x82>
    8000403e:	f04a                	sd	s2,32(sp)
    80004040:	ec4e                	sd	s3,24(sp)
    80004042:	e852                	sd	s4,16(sp)
    80004044:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004046:	0004a903          	lw	s2,0(s1)
    8000404a:	0094ca83          	lbu	s5,9(s1)
    8000404e:	0104ba03          	ld	s4,16(s1)
    80004052:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004056:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000405a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000405e:	0001c517          	auipc	a0,0x1c
    80004062:	a8250513          	addi	a0,a0,-1406 # 8001fae0 <ftable>
    80004066:	c33fc0ef          	jal	80000c98 <release>

  if(ff.type == FD_PIPE){
    8000406a:	4785                	li	a5,1
    8000406c:	04f90063          	beq	s2,a5,800040ac <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004070:	3979                	addiw	s2,s2,-2
    80004072:	4785                	li	a5,1
    80004074:	0527f563          	bgeu	a5,s2,800040be <fileclose+0xaa>
    80004078:	7902                	ld	s2,32(sp)
    8000407a:	69e2                	ld	s3,24(sp)
    8000407c:	6a42                	ld	s4,16(sp)
    8000407e:	6aa2                	ld	s5,8(sp)
    80004080:	a00d                	j	800040a2 <fileclose+0x8e>
    80004082:	f04a                	sd	s2,32(sp)
    80004084:	ec4e                	sd	s3,24(sp)
    80004086:	e852                	sd	s4,16(sp)
    80004088:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000408a:	00003517          	auipc	a0,0x3
    8000408e:	4e650513          	addi	a0,a0,1254 # 80007570 <etext+0x570>
    80004092:	f80fc0ef          	jal	80000812 <panic>
    release(&ftable.lock);
    80004096:	0001c517          	auipc	a0,0x1c
    8000409a:	a4a50513          	addi	a0,a0,-1462 # 8001fae0 <ftable>
    8000409e:	bfbfc0ef          	jal	80000c98 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800040a2:	70e2                	ld	ra,56(sp)
    800040a4:	7442                	ld	s0,48(sp)
    800040a6:	74a2                	ld	s1,40(sp)
    800040a8:	6121                	addi	sp,sp,64
    800040aa:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800040ac:	85d6                	mv	a1,s5
    800040ae:	8552                	mv	a0,s4
    800040b0:	336000ef          	jal	800043e6 <pipeclose>
    800040b4:	7902                	ld	s2,32(sp)
    800040b6:	69e2                	ld	s3,24(sp)
    800040b8:	6a42                	ld	s4,16(sp)
    800040ba:	6aa2                	ld	s5,8(sp)
    800040bc:	b7dd                	j	800040a2 <fileclose+0x8e>
    begin_op();
    800040be:	b4bff0ef          	jal	80003c08 <begin_op>
    iput(ff.ip);
    800040c2:	854e                	mv	a0,s3
    800040c4:	adcff0ef          	jal	800033a0 <iput>
    end_op();
    800040c8:	babff0ef          	jal	80003c72 <end_op>
    800040cc:	7902                	ld	s2,32(sp)
    800040ce:	69e2                	ld	s3,24(sp)
    800040d0:	6a42                	ld	s4,16(sp)
    800040d2:	6aa2                	ld	s5,8(sp)
    800040d4:	b7f9                	j	800040a2 <fileclose+0x8e>

00000000800040d6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800040d6:	715d                	addi	sp,sp,-80
    800040d8:	e486                	sd	ra,72(sp)
    800040da:	e0a2                	sd	s0,64(sp)
    800040dc:	fc26                	sd	s1,56(sp)
    800040de:	f44e                	sd	s3,40(sp)
    800040e0:	0880                	addi	s0,sp,80
    800040e2:	84aa                	mv	s1,a0
    800040e4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800040e6:	81ffd0ef          	jal	80001904 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800040ea:	409c                	lw	a5,0(s1)
    800040ec:	37f9                	addiw	a5,a5,-2
    800040ee:	4705                	li	a4,1
    800040f0:	04f76063          	bltu	a4,a5,80004130 <filestat+0x5a>
    800040f4:	f84a                	sd	s2,48(sp)
    800040f6:	892a                	mv	s2,a0
    ilock(f->ip);
    800040f8:	6c88                	ld	a0,24(s1)
    800040fa:	924ff0ef          	jal	8000321e <ilock>
    stati(f->ip, &st);
    800040fe:	fb840593          	addi	a1,s0,-72
    80004102:	6c88                	ld	a0,24(s1)
    80004104:	c80ff0ef          	jal	80003584 <stati>
    iunlock(f->ip);
    80004108:	6c88                	ld	a0,24(s1)
    8000410a:	9c2ff0ef          	jal	800032cc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000410e:	46e1                	li	a3,24
    80004110:	fb840613          	addi	a2,s0,-72
    80004114:	85ce                	mv	a1,s3
    80004116:	05093503          	ld	a0,80(s2)
    8000411a:	cfefd0ef          	jal	80001618 <copyout>
    8000411e:	41f5551b          	sraiw	a0,a0,0x1f
    80004122:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004124:	60a6                	ld	ra,72(sp)
    80004126:	6406                	ld	s0,64(sp)
    80004128:	74e2                	ld	s1,56(sp)
    8000412a:	79a2                	ld	s3,40(sp)
    8000412c:	6161                	addi	sp,sp,80
    8000412e:	8082                	ret
  return -1;
    80004130:	557d                	li	a0,-1
    80004132:	bfcd                	j	80004124 <filestat+0x4e>

0000000080004134 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004134:	7179                	addi	sp,sp,-48
    80004136:	f406                	sd	ra,40(sp)
    80004138:	f022                	sd	s0,32(sp)
    8000413a:	e84a                	sd	s2,16(sp)
    8000413c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000413e:	00854783          	lbu	a5,8(a0)
    80004142:	cfd1                	beqz	a5,800041de <fileread+0xaa>
    80004144:	ec26                	sd	s1,24(sp)
    80004146:	e44e                	sd	s3,8(sp)
    80004148:	84aa                	mv	s1,a0
    8000414a:	89ae                	mv	s3,a1
    8000414c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000414e:	411c                	lw	a5,0(a0)
    80004150:	4705                	li	a4,1
    80004152:	04e78363          	beq	a5,a4,80004198 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004156:	470d                	li	a4,3
    80004158:	04e78763          	beq	a5,a4,800041a6 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000415c:	4709                	li	a4,2
    8000415e:	06e79a63          	bne	a5,a4,800041d2 <fileread+0x9e>
    ilock(f->ip);
    80004162:	6d08                	ld	a0,24(a0)
    80004164:	8baff0ef          	jal	8000321e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004168:	874a                	mv	a4,s2
    8000416a:	5094                	lw	a3,32(s1)
    8000416c:	864e                	mv	a2,s3
    8000416e:	4585                	li	a1,1
    80004170:	6c88                	ld	a0,24(s1)
    80004172:	c3cff0ef          	jal	800035ae <readi>
    80004176:	892a                	mv	s2,a0
    80004178:	00a05563          	blez	a0,80004182 <fileread+0x4e>
      f->off += r;
    8000417c:	509c                	lw	a5,32(s1)
    8000417e:	9fa9                	addw	a5,a5,a0
    80004180:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004182:	6c88                	ld	a0,24(s1)
    80004184:	948ff0ef          	jal	800032cc <iunlock>
    80004188:	64e2                	ld	s1,24(sp)
    8000418a:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    8000418c:	854a                	mv	a0,s2
    8000418e:	70a2                	ld	ra,40(sp)
    80004190:	7402                	ld	s0,32(sp)
    80004192:	6942                	ld	s2,16(sp)
    80004194:	6145                	addi	sp,sp,48
    80004196:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004198:	6908                	ld	a0,16(a0)
    8000419a:	388000ef          	jal	80004522 <piperead>
    8000419e:	892a                	mv	s2,a0
    800041a0:	64e2                	ld	s1,24(sp)
    800041a2:	69a2                	ld	s3,8(sp)
    800041a4:	b7e5                	j	8000418c <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800041a6:	02451783          	lh	a5,36(a0)
    800041aa:	03079693          	slli	a3,a5,0x30
    800041ae:	92c1                	srli	a3,a3,0x30
    800041b0:	4725                	li	a4,9
    800041b2:	02d76863          	bltu	a4,a3,800041e2 <fileread+0xae>
    800041b6:	0792                	slli	a5,a5,0x4
    800041b8:	0001c717          	auipc	a4,0x1c
    800041bc:	88870713          	addi	a4,a4,-1912 # 8001fa40 <devsw>
    800041c0:	97ba                	add	a5,a5,a4
    800041c2:	639c                	ld	a5,0(a5)
    800041c4:	c39d                	beqz	a5,800041ea <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    800041c6:	4505                	li	a0,1
    800041c8:	9782                	jalr	a5
    800041ca:	892a                	mv	s2,a0
    800041cc:	64e2                	ld	s1,24(sp)
    800041ce:	69a2                	ld	s3,8(sp)
    800041d0:	bf75                	j	8000418c <fileread+0x58>
    panic("fileread");
    800041d2:	00003517          	auipc	a0,0x3
    800041d6:	3ae50513          	addi	a0,a0,942 # 80007580 <etext+0x580>
    800041da:	e38fc0ef          	jal	80000812 <panic>
    return -1;
    800041de:	597d                	li	s2,-1
    800041e0:	b775                	j	8000418c <fileread+0x58>
      return -1;
    800041e2:	597d                	li	s2,-1
    800041e4:	64e2                	ld	s1,24(sp)
    800041e6:	69a2                	ld	s3,8(sp)
    800041e8:	b755                	j	8000418c <fileread+0x58>
    800041ea:	597d                	li	s2,-1
    800041ec:	64e2                	ld	s1,24(sp)
    800041ee:	69a2                	ld	s3,8(sp)
    800041f0:	bf71                	j	8000418c <fileread+0x58>

00000000800041f2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800041f2:	00954783          	lbu	a5,9(a0)
    800041f6:	10078b63          	beqz	a5,8000430c <filewrite+0x11a>
{
    800041fa:	715d                	addi	sp,sp,-80
    800041fc:	e486                	sd	ra,72(sp)
    800041fe:	e0a2                	sd	s0,64(sp)
    80004200:	f84a                	sd	s2,48(sp)
    80004202:	f052                	sd	s4,32(sp)
    80004204:	e85a                	sd	s6,16(sp)
    80004206:	0880                	addi	s0,sp,80
    80004208:	892a                	mv	s2,a0
    8000420a:	8b2e                	mv	s6,a1
    8000420c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000420e:	411c                	lw	a5,0(a0)
    80004210:	4705                	li	a4,1
    80004212:	02e78763          	beq	a5,a4,80004240 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004216:	470d                	li	a4,3
    80004218:	02e78863          	beq	a5,a4,80004248 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000421c:	4709                	li	a4,2
    8000421e:	0ce79c63          	bne	a5,a4,800042f6 <filewrite+0x104>
    80004222:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004224:	0ac05863          	blez	a2,800042d4 <filewrite+0xe2>
    80004228:	fc26                	sd	s1,56(sp)
    8000422a:	ec56                	sd	s5,24(sp)
    8000422c:	e45e                	sd	s7,8(sp)
    8000422e:	e062                	sd	s8,0(sp)
    int i = 0;
    80004230:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004232:	6b85                	lui	s7,0x1
    80004234:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004238:	6c05                	lui	s8,0x1
    8000423a:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000423e:	a8b5                	j	800042ba <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    80004240:	6908                	ld	a0,16(a0)
    80004242:	1fc000ef          	jal	8000443e <pipewrite>
    80004246:	a04d                	j	800042e8 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004248:	02451783          	lh	a5,36(a0)
    8000424c:	03079693          	slli	a3,a5,0x30
    80004250:	92c1                	srli	a3,a3,0x30
    80004252:	4725                	li	a4,9
    80004254:	0ad76e63          	bltu	a4,a3,80004310 <filewrite+0x11e>
    80004258:	0792                	slli	a5,a5,0x4
    8000425a:	0001b717          	auipc	a4,0x1b
    8000425e:	7e670713          	addi	a4,a4,2022 # 8001fa40 <devsw>
    80004262:	97ba                	add	a5,a5,a4
    80004264:	679c                	ld	a5,8(a5)
    80004266:	c7dd                	beqz	a5,80004314 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    80004268:	4505                	li	a0,1
    8000426a:	9782                	jalr	a5
    8000426c:	a8b5                	j	800042e8 <filewrite+0xf6>
      if(n1 > max)
    8000426e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004272:	997ff0ef          	jal	80003c08 <begin_op>
      ilock(f->ip);
    80004276:	01893503          	ld	a0,24(s2)
    8000427a:	fa5fe0ef          	jal	8000321e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000427e:	8756                	mv	a4,s5
    80004280:	02092683          	lw	a3,32(s2)
    80004284:	01698633          	add	a2,s3,s6
    80004288:	4585                	li	a1,1
    8000428a:	01893503          	ld	a0,24(s2)
    8000428e:	c1cff0ef          	jal	800036aa <writei>
    80004292:	84aa                	mv	s1,a0
    80004294:	00a05763          	blez	a0,800042a2 <filewrite+0xb0>
        f->off += r;
    80004298:	02092783          	lw	a5,32(s2)
    8000429c:	9fa9                	addw	a5,a5,a0
    8000429e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800042a2:	01893503          	ld	a0,24(s2)
    800042a6:	826ff0ef          	jal	800032cc <iunlock>
      end_op();
    800042aa:	9c9ff0ef          	jal	80003c72 <end_op>

      if(r != n1){
    800042ae:	029a9563          	bne	s5,s1,800042d8 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    800042b2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800042b6:	0149da63          	bge	s3,s4,800042ca <filewrite+0xd8>
      int n1 = n - i;
    800042ba:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800042be:	0004879b          	sext.w	a5,s1
    800042c2:	fafbd6e3          	bge	s7,a5,8000426e <filewrite+0x7c>
    800042c6:	84e2                	mv	s1,s8
    800042c8:	b75d                	j	8000426e <filewrite+0x7c>
    800042ca:	74e2                	ld	s1,56(sp)
    800042cc:	6ae2                	ld	s5,24(sp)
    800042ce:	6ba2                	ld	s7,8(sp)
    800042d0:	6c02                	ld	s8,0(sp)
    800042d2:	a039                	j	800042e0 <filewrite+0xee>
    int i = 0;
    800042d4:	4981                	li	s3,0
    800042d6:	a029                	j	800042e0 <filewrite+0xee>
    800042d8:	74e2                	ld	s1,56(sp)
    800042da:	6ae2                	ld	s5,24(sp)
    800042dc:	6ba2                	ld	s7,8(sp)
    800042de:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800042e0:	033a1c63          	bne	s4,s3,80004318 <filewrite+0x126>
    800042e4:	8552                	mv	a0,s4
    800042e6:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800042e8:	60a6                	ld	ra,72(sp)
    800042ea:	6406                	ld	s0,64(sp)
    800042ec:	7942                	ld	s2,48(sp)
    800042ee:	7a02                	ld	s4,32(sp)
    800042f0:	6b42                	ld	s6,16(sp)
    800042f2:	6161                	addi	sp,sp,80
    800042f4:	8082                	ret
    800042f6:	fc26                	sd	s1,56(sp)
    800042f8:	f44e                	sd	s3,40(sp)
    800042fa:	ec56                	sd	s5,24(sp)
    800042fc:	e45e                	sd	s7,8(sp)
    800042fe:	e062                	sd	s8,0(sp)
    panic("filewrite");
    80004300:	00003517          	auipc	a0,0x3
    80004304:	29050513          	addi	a0,a0,656 # 80007590 <etext+0x590>
    80004308:	d0afc0ef          	jal	80000812 <panic>
    return -1;
    8000430c:	557d                	li	a0,-1
}
    8000430e:	8082                	ret
      return -1;
    80004310:	557d                	li	a0,-1
    80004312:	bfd9                	j	800042e8 <filewrite+0xf6>
    80004314:	557d                	li	a0,-1
    80004316:	bfc9                	j	800042e8 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004318:	557d                	li	a0,-1
    8000431a:	79a2                	ld	s3,40(sp)
    8000431c:	b7f1                	j	800042e8 <filewrite+0xf6>

000000008000431e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000431e:	7179                	addi	sp,sp,-48
    80004320:	f406                	sd	ra,40(sp)
    80004322:	f022                	sd	s0,32(sp)
    80004324:	ec26                	sd	s1,24(sp)
    80004326:	e052                	sd	s4,0(sp)
    80004328:	1800                	addi	s0,sp,48
    8000432a:	84aa                	mv	s1,a0
    8000432c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000432e:	0005b023          	sd	zero,0(a1)
    80004332:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004336:	c3bff0ef          	jal	80003f70 <filealloc>
    8000433a:	e088                	sd	a0,0(s1)
    8000433c:	c549                	beqz	a0,800043c6 <pipealloc+0xa8>
    8000433e:	c33ff0ef          	jal	80003f70 <filealloc>
    80004342:	00aa3023          	sd	a0,0(s4)
    80004346:	cd25                	beqz	a0,800043be <pipealloc+0xa0>
    80004348:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000434a:	fe6fc0ef          	jal	80000b30 <kalloc>
    8000434e:	892a                	mv	s2,a0
    80004350:	c12d                	beqz	a0,800043b2 <pipealloc+0x94>
    80004352:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004354:	4985                	li	s3,1
    80004356:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000435a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000435e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004362:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004366:	00003597          	auipc	a1,0x3
    8000436a:	23a58593          	addi	a1,a1,570 # 800075a0 <etext+0x5a0>
    8000436e:	813fc0ef          	jal	80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004372:	609c                	ld	a5,0(s1)
    80004374:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004378:	609c                	ld	a5,0(s1)
    8000437a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000437e:	609c                	ld	a5,0(s1)
    80004380:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004384:	609c                	ld	a5,0(s1)
    80004386:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000438a:	000a3783          	ld	a5,0(s4)
    8000438e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004392:	000a3783          	ld	a5,0(s4)
    80004396:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000439a:	000a3783          	ld	a5,0(s4)
    8000439e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800043a2:	000a3783          	ld	a5,0(s4)
    800043a6:	0127b823          	sd	s2,16(a5)
  return 0;
    800043aa:	4501                	li	a0,0
    800043ac:	6942                	ld	s2,16(sp)
    800043ae:	69a2                	ld	s3,8(sp)
    800043b0:	a01d                	j	800043d6 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800043b2:	6088                	ld	a0,0(s1)
    800043b4:	c119                	beqz	a0,800043ba <pipealloc+0x9c>
    800043b6:	6942                	ld	s2,16(sp)
    800043b8:	a029                	j	800043c2 <pipealloc+0xa4>
    800043ba:	6942                	ld	s2,16(sp)
    800043bc:	a029                	j	800043c6 <pipealloc+0xa8>
    800043be:	6088                	ld	a0,0(s1)
    800043c0:	c10d                	beqz	a0,800043e2 <pipealloc+0xc4>
    fileclose(*f0);
    800043c2:	c53ff0ef          	jal	80004014 <fileclose>
  if(*f1)
    800043c6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800043ca:	557d                	li	a0,-1
  if(*f1)
    800043cc:	c789                	beqz	a5,800043d6 <pipealloc+0xb8>
    fileclose(*f1);
    800043ce:	853e                	mv	a0,a5
    800043d0:	c45ff0ef          	jal	80004014 <fileclose>
  return -1;
    800043d4:	557d                	li	a0,-1
}
    800043d6:	70a2                	ld	ra,40(sp)
    800043d8:	7402                	ld	s0,32(sp)
    800043da:	64e2                	ld	s1,24(sp)
    800043dc:	6a02                	ld	s4,0(sp)
    800043de:	6145                	addi	sp,sp,48
    800043e0:	8082                	ret
  return -1;
    800043e2:	557d                	li	a0,-1
    800043e4:	bfcd                	j	800043d6 <pipealloc+0xb8>

00000000800043e6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800043e6:	1101                	addi	sp,sp,-32
    800043e8:	ec06                	sd	ra,24(sp)
    800043ea:	e822                	sd	s0,16(sp)
    800043ec:	e426                	sd	s1,8(sp)
    800043ee:	e04a                	sd	s2,0(sp)
    800043f0:	1000                	addi	s0,sp,32
    800043f2:	84aa                	mv	s1,a0
    800043f4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800043f6:	80bfc0ef          	jal	80000c00 <acquire>
  if(writable){
    800043fa:	02090763          	beqz	s2,80004428 <pipeclose+0x42>
    pi->writeopen = 0;
    800043fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004402:	21848513          	addi	a0,s1,536
    80004406:	b5bfd0ef          	jal	80001f60 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000440a:	2204b783          	ld	a5,544(s1)
    8000440e:	e785                	bnez	a5,80004436 <pipeclose+0x50>
    release(&pi->lock);
    80004410:	8526                	mv	a0,s1
    80004412:	887fc0ef          	jal	80000c98 <release>
    kfree((char*)pi);
    80004416:	8526                	mv	a0,s1
    80004418:	e36fc0ef          	jal	80000a4e <kfree>
  } else
    release(&pi->lock);
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	64a2                	ld	s1,8(sp)
    80004422:	6902                	ld	s2,0(sp)
    80004424:	6105                	addi	sp,sp,32
    80004426:	8082                	ret
    pi->readopen = 0;
    80004428:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000442c:	21c48513          	addi	a0,s1,540
    80004430:	b31fd0ef          	jal	80001f60 <wakeup>
    80004434:	bfd9                	j	8000440a <pipeclose+0x24>
    release(&pi->lock);
    80004436:	8526                	mv	a0,s1
    80004438:	861fc0ef          	jal	80000c98 <release>
}
    8000443c:	b7c5                	j	8000441c <pipeclose+0x36>

000000008000443e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000443e:	711d                	addi	sp,sp,-96
    80004440:	ec86                	sd	ra,88(sp)
    80004442:	e8a2                	sd	s0,80(sp)
    80004444:	e4a6                	sd	s1,72(sp)
    80004446:	e0ca                	sd	s2,64(sp)
    80004448:	fc4e                	sd	s3,56(sp)
    8000444a:	f852                	sd	s4,48(sp)
    8000444c:	f456                	sd	s5,40(sp)
    8000444e:	1080                	addi	s0,sp,96
    80004450:	84aa                	mv	s1,a0
    80004452:	8aae                	mv	s5,a1
    80004454:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004456:	caefd0ef          	jal	80001904 <myproc>
    8000445a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fa2fc0ef          	jal	80000c00 <acquire>
  while(i < n){
    80004462:	0b405a63          	blez	s4,80004516 <pipewrite+0xd8>
    80004466:	f05a                	sd	s6,32(sp)
    80004468:	ec5e                	sd	s7,24(sp)
    8000446a:	e862                	sd	s8,16(sp)
  int i = 0;
    8000446c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000446e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004470:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004474:	21c48b93          	addi	s7,s1,540
    80004478:	a81d                	j	800044ae <pipewrite+0x70>
      release(&pi->lock);
    8000447a:	8526                	mv	a0,s1
    8000447c:	81dfc0ef          	jal	80000c98 <release>
      return -1;
    80004480:	597d                	li	s2,-1
    80004482:	7b02                	ld	s6,32(sp)
    80004484:	6be2                	ld	s7,24(sp)
    80004486:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004488:	854a                	mv	a0,s2
    8000448a:	60e6                	ld	ra,88(sp)
    8000448c:	6446                	ld	s0,80(sp)
    8000448e:	64a6                	ld	s1,72(sp)
    80004490:	6906                	ld	s2,64(sp)
    80004492:	79e2                	ld	s3,56(sp)
    80004494:	7a42                	ld	s4,48(sp)
    80004496:	7aa2                	ld	s5,40(sp)
    80004498:	6125                	addi	sp,sp,96
    8000449a:	8082                	ret
      wakeup(&pi->nread);
    8000449c:	8562                	mv	a0,s8
    8000449e:	ac3fd0ef          	jal	80001f60 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800044a2:	85a6                	mv	a1,s1
    800044a4:	855e                	mv	a0,s7
    800044a6:	a6ffd0ef          	jal	80001f14 <sleep>
  while(i < n){
    800044aa:	05495b63          	bge	s2,s4,80004500 <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    800044ae:	2204a783          	lw	a5,544(s1)
    800044b2:	d7e1                	beqz	a5,8000447a <pipewrite+0x3c>
    800044b4:	854e                	mv	a0,s3
    800044b6:	c97fd0ef          	jal	8000214c <killed>
    800044ba:	f161                	bnez	a0,8000447a <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800044bc:	2184a783          	lw	a5,536(s1)
    800044c0:	21c4a703          	lw	a4,540(s1)
    800044c4:	2007879b          	addiw	a5,a5,512
    800044c8:	fcf70ae3          	beq	a4,a5,8000449c <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800044cc:	4685                	li	a3,1
    800044ce:	01590633          	add	a2,s2,s5
    800044d2:	faf40593          	addi	a1,s0,-81
    800044d6:	0509b503          	ld	a0,80(s3)
    800044da:	a22fd0ef          	jal	800016fc <copyin>
    800044de:	03650e63          	beq	a0,s6,8000451a <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800044e2:	21c4a783          	lw	a5,540(s1)
    800044e6:	0017871b          	addiw	a4,a5,1
    800044ea:	20e4ae23          	sw	a4,540(s1)
    800044ee:	1ff7f793          	andi	a5,a5,511
    800044f2:	97a6                	add	a5,a5,s1
    800044f4:	faf44703          	lbu	a4,-81(s0)
    800044f8:	00e78c23          	sb	a4,24(a5)
      i++;
    800044fc:	2905                	addiw	s2,s2,1
    800044fe:	b775                	j	800044aa <pipewrite+0x6c>
    80004500:	7b02                	ld	s6,32(sp)
    80004502:	6be2                	ld	s7,24(sp)
    80004504:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004506:	21848513          	addi	a0,s1,536
    8000450a:	a57fd0ef          	jal	80001f60 <wakeup>
  release(&pi->lock);
    8000450e:	8526                	mv	a0,s1
    80004510:	f88fc0ef          	jal	80000c98 <release>
  return i;
    80004514:	bf95                	j	80004488 <pipewrite+0x4a>
  int i = 0;
    80004516:	4901                	li	s2,0
    80004518:	b7fd                	j	80004506 <pipewrite+0xc8>
    8000451a:	7b02                	ld	s6,32(sp)
    8000451c:	6be2                	ld	s7,24(sp)
    8000451e:	6c42                	ld	s8,16(sp)
    80004520:	b7dd                	j	80004506 <pipewrite+0xc8>

0000000080004522 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004522:	715d                	addi	sp,sp,-80
    80004524:	e486                	sd	ra,72(sp)
    80004526:	e0a2                	sd	s0,64(sp)
    80004528:	fc26                	sd	s1,56(sp)
    8000452a:	f84a                	sd	s2,48(sp)
    8000452c:	f44e                	sd	s3,40(sp)
    8000452e:	f052                	sd	s4,32(sp)
    80004530:	ec56                	sd	s5,24(sp)
    80004532:	0880                	addi	s0,sp,80
    80004534:	84aa                	mv	s1,a0
    80004536:	892e                	mv	s2,a1
    80004538:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000453a:	bcafd0ef          	jal	80001904 <myproc>
    8000453e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004540:	8526                	mv	a0,s1
    80004542:	ebefc0ef          	jal	80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004546:	2184a703          	lw	a4,536(s1)
    8000454a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000454e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004552:	02f71563          	bne	a4,a5,8000457c <piperead+0x5a>
    80004556:	2244a783          	lw	a5,548(s1)
    8000455a:	cb85                	beqz	a5,8000458a <piperead+0x68>
    if(killed(pr)){
    8000455c:	8552                	mv	a0,s4
    8000455e:	beffd0ef          	jal	8000214c <killed>
    80004562:	ed19                	bnez	a0,80004580 <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004564:	85a6                	mv	a1,s1
    80004566:	854e                	mv	a0,s3
    80004568:	9adfd0ef          	jal	80001f14 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000456c:	2184a703          	lw	a4,536(s1)
    80004570:	21c4a783          	lw	a5,540(s1)
    80004574:	fef701e3          	beq	a4,a5,80004556 <piperead+0x34>
    80004578:	e85a                	sd	s6,16(sp)
    8000457a:	a809                	j	8000458c <piperead+0x6a>
    8000457c:	e85a                	sd	s6,16(sp)
    8000457e:	a039                	j	8000458c <piperead+0x6a>
      release(&pi->lock);
    80004580:	8526                	mv	a0,s1
    80004582:	f16fc0ef          	jal	80000c98 <release>
      return -1;
    80004586:	59fd                	li	s3,-1
    80004588:	a8b9                	j	800045e6 <piperead+0xc4>
    8000458a:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000458c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000458e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004590:	05505363          	blez	s5,800045d6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004594:	2184a783          	lw	a5,536(s1)
    80004598:	21c4a703          	lw	a4,540(s1)
    8000459c:	02f70d63          	beq	a4,a5,800045d6 <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    800045a0:	1ff7f793          	andi	a5,a5,511
    800045a4:	97a6                	add	a5,a5,s1
    800045a6:	0187c783          	lbu	a5,24(a5)
    800045aa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800045ae:	4685                	li	a3,1
    800045b0:	fbf40613          	addi	a2,s0,-65
    800045b4:	85ca                	mv	a1,s2
    800045b6:	050a3503          	ld	a0,80(s4)
    800045ba:	85efd0ef          	jal	80001618 <copyout>
    800045be:	03650e63          	beq	a0,s6,800045fa <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800045c2:	2184a783          	lw	a5,536(s1)
    800045c6:	2785                	addiw	a5,a5,1
    800045c8:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800045cc:	2985                	addiw	s3,s3,1
    800045ce:	0905                	addi	s2,s2,1
    800045d0:	fd3a92e3          	bne	s5,s3,80004594 <piperead+0x72>
    800045d4:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800045d6:	21c48513          	addi	a0,s1,540
    800045da:	987fd0ef          	jal	80001f60 <wakeup>
  release(&pi->lock);
    800045de:	8526                	mv	a0,s1
    800045e0:	eb8fc0ef          	jal	80000c98 <release>
    800045e4:	6b42                	ld	s6,16(sp)
  return i;
}
    800045e6:	854e                	mv	a0,s3
    800045e8:	60a6                	ld	ra,72(sp)
    800045ea:	6406                	ld	s0,64(sp)
    800045ec:	74e2                	ld	s1,56(sp)
    800045ee:	7942                	ld	s2,48(sp)
    800045f0:	79a2                	ld	s3,40(sp)
    800045f2:	7a02                	ld	s4,32(sp)
    800045f4:	6ae2                	ld	s5,24(sp)
    800045f6:	6161                	addi	sp,sp,80
    800045f8:	8082                	ret
      if(i == 0)
    800045fa:	fc099ee3          	bnez	s3,800045d6 <piperead+0xb4>
        i = -1;
    800045fe:	89aa                	mv	s3,a0
    80004600:	bfd9                	j	800045d6 <piperead+0xb4>

0000000080004602 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004602:	1141                	addi	sp,sp,-16
    80004604:	e422                	sd	s0,8(sp)
    80004606:	0800                	addi	s0,sp,16
    80004608:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000460a:	8905                	andi	a0,a0,1
    8000460c:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000460e:	8b89                	andi	a5,a5,2
    80004610:	c399                	beqz	a5,80004616 <flags2perm+0x14>
      perm |= PTE_W;
    80004612:	00456513          	ori	a0,a0,4
    return perm;
}
    80004616:	6422                	ld	s0,8(sp)
    80004618:	0141                	addi	sp,sp,16
    8000461a:	8082                	ret

000000008000461c <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    8000461c:	df010113          	addi	sp,sp,-528
    80004620:	20113423          	sd	ra,520(sp)
    80004624:	20813023          	sd	s0,512(sp)
    80004628:	ffa6                	sd	s1,504(sp)
    8000462a:	fbca                	sd	s2,496(sp)
    8000462c:	0c00                	addi	s0,sp,528
    8000462e:	892a                	mv	s2,a0
    80004630:	dea43c23          	sd	a0,-520(s0)
    80004634:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004638:	accfd0ef          	jal	80001904 <myproc>
    8000463c:	84aa                	mv	s1,a0

  begin_op();
    8000463e:	dcaff0ef          	jal	80003c08 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004642:	854a                	mv	a0,s2
    80004644:	bf0ff0ef          	jal	80003a34 <namei>
    80004648:	c931                	beqz	a0,8000469c <kexec+0x80>
    8000464a:	f3d2                	sd	s4,480(sp)
    8000464c:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000464e:	bd1fe0ef          	jal	8000321e <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004652:	04000713          	li	a4,64
    80004656:	4681                	li	a3,0
    80004658:	e5040613          	addi	a2,s0,-432
    8000465c:	4581                	li	a1,0
    8000465e:	8552                	mv	a0,s4
    80004660:	f4ffe0ef          	jal	800035ae <readi>
    80004664:	04000793          	li	a5,64
    80004668:	00f51a63          	bne	a0,a5,8000467c <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    8000466c:	e5042703          	lw	a4,-432(s0)
    80004670:	464c47b7          	lui	a5,0x464c4
    80004674:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004678:	02f70663          	beq	a4,a5,800046a4 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000467c:	8552                	mv	a0,s4
    8000467e:	dabfe0ef          	jal	80003428 <iunlockput>
    end_op();
    80004682:	df0ff0ef          	jal	80003c72 <end_op>
  }
  return -1;
    80004686:	557d                	li	a0,-1
    80004688:	7a1e                	ld	s4,480(sp)
}
    8000468a:	20813083          	ld	ra,520(sp)
    8000468e:	20013403          	ld	s0,512(sp)
    80004692:	74fe                	ld	s1,504(sp)
    80004694:	795e                	ld	s2,496(sp)
    80004696:	21010113          	addi	sp,sp,528
    8000469a:	8082                	ret
    end_op();
    8000469c:	dd6ff0ef          	jal	80003c72 <end_op>
    return -1;
    800046a0:	557d                	li	a0,-1
    800046a2:	b7e5                	j	8000468a <kexec+0x6e>
    800046a4:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    800046a6:	8526                	mv	a0,s1
    800046a8:	b62fd0ef          	jal	80001a0a <proc_pagetable>
    800046ac:	8b2a                	mv	s6,a0
    800046ae:	2c050b63          	beqz	a0,80004984 <kexec+0x368>
    800046b2:	f7ce                	sd	s3,488(sp)
    800046b4:	efd6                	sd	s5,472(sp)
    800046b6:	e7de                	sd	s7,456(sp)
    800046b8:	e3e2                	sd	s8,448(sp)
    800046ba:	ff66                	sd	s9,440(sp)
    800046bc:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800046be:	e7042d03          	lw	s10,-400(s0)
    800046c2:	e8845783          	lhu	a5,-376(s0)
    800046c6:	12078963          	beqz	a5,800047f8 <kexec+0x1dc>
    800046ca:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800046cc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800046ce:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800046d0:	6c85                	lui	s9,0x1
    800046d2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800046d6:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800046da:	6a85                	lui	s5,0x1
    800046dc:	a085                	j	8000473c <kexec+0x120>
      panic("loadseg: address should exist");
    800046de:	00003517          	auipc	a0,0x3
    800046e2:	eca50513          	addi	a0,a0,-310 # 800075a8 <etext+0x5a8>
    800046e6:	92cfc0ef          	jal	80000812 <panic>
    if(sz - i < PGSIZE)
    800046ea:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800046ec:	8726                	mv	a4,s1
    800046ee:	012c06bb          	addw	a3,s8,s2
    800046f2:	4581                	li	a1,0
    800046f4:	8552                	mv	a0,s4
    800046f6:	eb9fe0ef          	jal	800035ae <readi>
    800046fa:	2501                	sext.w	a0,a0
    800046fc:	24a49a63          	bne	s1,a0,80004950 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004700:	012a893b          	addw	s2,s5,s2
    80004704:	03397363          	bgeu	s2,s3,8000472a <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004708:	02091593          	slli	a1,s2,0x20
    8000470c:	9181                	srli	a1,a1,0x20
    8000470e:	95de                	add	a1,a1,s7
    80004710:	855a                	mv	a0,s6
    80004712:	8d5fc0ef          	jal	80000fe6 <walkaddr>
    80004716:	862a                	mv	a2,a0
    if(pa == 0)
    80004718:	d179                	beqz	a0,800046de <kexec+0xc2>
    if(sz - i < PGSIZE)
    8000471a:	412984bb          	subw	s1,s3,s2
    8000471e:	0004879b          	sext.w	a5,s1
    80004722:	fcfcf4e3          	bgeu	s9,a5,800046ea <kexec+0xce>
    80004726:	84d6                	mv	s1,s5
    80004728:	b7c9                	j	800046ea <kexec+0xce>
    sz = sz1;
    8000472a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000472e:	2d85                	addiw	s11,s11,1
    80004730:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004734:	e8845783          	lhu	a5,-376(s0)
    80004738:	08fdd063          	bge	s11,a5,800047b8 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000473c:	2d01                	sext.w	s10,s10
    8000473e:	03800713          	li	a4,56
    80004742:	86ea                	mv	a3,s10
    80004744:	e1840613          	addi	a2,s0,-488
    80004748:	4581                	li	a1,0
    8000474a:	8552                	mv	a0,s4
    8000474c:	e63fe0ef          	jal	800035ae <readi>
    80004750:	03800793          	li	a5,56
    80004754:	1cf51663          	bne	a0,a5,80004920 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004758:	e1842783          	lw	a5,-488(s0)
    8000475c:	4705                	li	a4,1
    8000475e:	fce798e3          	bne	a5,a4,8000472e <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004762:	e4043483          	ld	s1,-448(s0)
    80004766:	e3843783          	ld	a5,-456(s0)
    8000476a:	1af4ef63          	bltu	s1,a5,80004928 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000476e:	e2843783          	ld	a5,-472(s0)
    80004772:	94be                	add	s1,s1,a5
    80004774:	1af4ee63          	bltu	s1,a5,80004930 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004778:	df043703          	ld	a4,-528(s0)
    8000477c:	8ff9                	and	a5,a5,a4
    8000477e:	1a079d63          	bnez	a5,80004938 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004782:	e1c42503          	lw	a0,-484(s0)
    80004786:	e7dff0ef          	jal	80004602 <flags2perm>
    8000478a:	86aa                	mv	a3,a0
    8000478c:	8626                	mv	a2,s1
    8000478e:	85ca                	mv	a1,s2
    80004790:	855a                	mv	a0,s6
    80004792:	b2dfc0ef          	jal	800012be <uvmalloc>
    80004796:	e0a43423          	sd	a0,-504(s0)
    8000479a:	1a050363          	beqz	a0,80004940 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000479e:	e2843b83          	ld	s7,-472(s0)
    800047a2:	e2042c03          	lw	s8,-480(s0)
    800047a6:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800047aa:	00098463          	beqz	s3,800047b2 <kexec+0x196>
    800047ae:	4901                	li	s2,0
    800047b0:	bfa1                	j	80004708 <kexec+0xec>
    sz = sz1;
    800047b2:	e0843903          	ld	s2,-504(s0)
    800047b6:	bfa5                	j	8000472e <kexec+0x112>
    800047b8:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    800047ba:	8552                	mv	a0,s4
    800047bc:	c6dfe0ef          	jal	80003428 <iunlockput>
  end_op();
    800047c0:	cb2ff0ef          	jal	80003c72 <end_op>
  p = myproc();
    800047c4:	940fd0ef          	jal	80001904 <myproc>
    800047c8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800047ca:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800047ce:	6985                	lui	s3,0x1
    800047d0:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800047d2:	99ca                	add	s3,s3,s2
    800047d4:	77fd                	lui	a5,0xfffff
    800047d6:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    800047da:	4691                	li	a3,4
    800047dc:	6609                	lui	a2,0x2
    800047de:	964e                	add	a2,a2,s3
    800047e0:	85ce                	mv	a1,s3
    800047e2:	855a                	mv	a0,s6
    800047e4:	adbfc0ef          	jal	800012be <uvmalloc>
    800047e8:	892a                	mv	s2,a0
    800047ea:	e0a43423          	sd	a0,-504(s0)
    800047ee:	e519                	bnez	a0,800047fc <kexec+0x1e0>
  if(pagetable)
    800047f0:	e1343423          	sd	s3,-504(s0)
    800047f4:	4a01                	li	s4,0
    800047f6:	aab1                	j	80004952 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800047f8:	4901                	li	s2,0
    800047fa:	b7c1                	j	800047ba <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    800047fc:	75f9                	lui	a1,0xffffe
    800047fe:	95aa                	add	a1,a1,a0
    80004800:	855a                	mv	a0,s6
    80004802:	c93fc0ef          	jal	80001494 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004806:	7bfd                	lui	s7,0xfffff
    80004808:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    8000480a:	e0043783          	ld	a5,-512(s0)
    8000480e:	6388                	ld	a0,0(a5)
    80004810:	cd39                	beqz	a0,8000486e <kexec+0x252>
    80004812:	e9040993          	addi	s3,s0,-368
    80004816:	f9040c13          	addi	s8,s0,-112
    8000481a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000481c:	e28fc0ef          	jal	80000e44 <strlen>
    80004820:	0015079b          	addiw	a5,a0,1
    80004824:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004828:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000482c:	11796e63          	bltu	s2,s7,80004948 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004830:	e0043d03          	ld	s10,-512(s0)
    80004834:	000d3a03          	ld	s4,0(s10)
    80004838:	8552                	mv	a0,s4
    8000483a:	e0afc0ef          	jal	80000e44 <strlen>
    8000483e:	0015069b          	addiw	a3,a0,1
    80004842:	8652                	mv	a2,s4
    80004844:	85ca                	mv	a1,s2
    80004846:	855a                	mv	a0,s6
    80004848:	dd1fc0ef          	jal	80001618 <copyout>
    8000484c:	10054063          	bltz	a0,8000494c <kexec+0x330>
    ustack[argc] = sp;
    80004850:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004854:	0485                	addi	s1,s1,1
    80004856:	008d0793          	addi	a5,s10,8
    8000485a:	e0f43023          	sd	a5,-512(s0)
    8000485e:	008d3503          	ld	a0,8(s10)
    80004862:	c909                	beqz	a0,80004874 <kexec+0x258>
    if(argc >= MAXARG)
    80004864:	09a1                	addi	s3,s3,8
    80004866:	fb899be3          	bne	s3,s8,8000481c <kexec+0x200>
  ip = 0;
    8000486a:	4a01                	li	s4,0
    8000486c:	a0dd                	j	80004952 <kexec+0x336>
  sp = sz;
    8000486e:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004872:	4481                	li	s1,0
  ustack[argc] = 0;
    80004874:	00349793          	slli	a5,s1,0x3
    80004878:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd6388>
    8000487c:	97a2                	add	a5,a5,s0
    8000487e:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004882:	00148693          	addi	a3,s1,1
    80004886:	068e                	slli	a3,a3,0x3
    80004888:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000488c:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004890:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004894:	f5796ee3          	bltu	s2,s7,800047f0 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004898:	e9040613          	addi	a2,s0,-368
    8000489c:	85ca                	mv	a1,s2
    8000489e:	855a                	mv	a0,s6
    800048a0:	d79fc0ef          	jal	80001618 <copyout>
    800048a4:	0e054263          	bltz	a0,80004988 <kexec+0x36c>
  p->trapframe->a1 = sp;
    800048a8:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800048ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800048b0:	df843783          	ld	a5,-520(s0)
    800048b4:	0007c703          	lbu	a4,0(a5)
    800048b8:	cf11                	beqz	a4,800048d4 <kexec+0x2b8>
    800048ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800048bc:	02f00693          	li	a3,47
    800048c0:	a039                	j	800048ce <kexec+0x2b2>
      last = s+1;
    800048c2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800048c6:	0785                	addi	a5,a5,1
    800048c8:	fff7c703          	lbu	a4,-1(a5)
    800048cc:	c701                	beqz	a4,800048d4 <kexec+0x2b8>
    if(*s == '/')
    800048ce:	fed71ce3          	bne	a4,a3,800048c6 <kexec+0x2aa>
    800048d2:	bfc5                	j	800048c2 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    800048d4:	4641                	li	a2,16
    800048d6:	df843583          	ld	a1,-520(s0)
    800048da:	158a8513          	addi	a0,s5,344
    800048de:	d34fc0ef          	jal	80000e12 <safestrcpy>
  oldpagetable = p->pagetable;
    800048e2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800048e6:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800048ea:	e0843783          	ld	a5,-504(s0)
    800048ee:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    800048f2:	058ab783          	ld	a5,88(s5)
    800048f6:	e6843703          	ld	a4,-408(s0)
    800048fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800048fc:	058ab783          	ld	a5,88(s5)
    80004900:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004904:	85e6                	mv	a1,s9
    80004906:	988fd0ef          	jal	80001a8e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000490a:	0004851b          	sext.w	a0,s1
    8000490e:	79be                	ld	s3,488(sp)
    80004910:	7a1e                	ld	s4,480(sp)
    80004912:	6afe                	ld	s5,472(sp)
    80004914:	6b5e                	ld	s6,464(sp)
    80004916:	6bbe                	ld	s7,456(sp)
    80004918:	6c1e                	ld	s8,448(sp)
    8000491a:	7cfa                	ld	s9,440(sp)
    8000491c:	7d5a                	ld	s10,432(sp)
    8000491e:	b3b5                	j	8000468a <kexec+0x6e>
    80004920:	e1243423          	sd	s2,-504(s0)
    80004924:	7dba                	ld	s11,424(sp)
    80004926:	a035                	j	80004952 <kexec+0x336>
    80004928:	e1243423          	sd	s2,-504(s0)
    8000492c:	7dba                	ld	s11,424(sp)
    8000492e:	a015                	j	80004952 <kexec+0x336>
    80004930:	e1243423          	sd	s2,-504(s0)
    80004934:	7dba                	ld	s11,424(sp)
    80004936:	a831                	j	80004952 <kexec+0x336>
    80004938:	e1243423          	sd	s2,-504(s0)
    8000493c:	7dba                	ld	s11,424(sp)
    8000493e:	a811                	j	80004952 <kexec+0x336>
    80004940:	e1243423          	sd	s2,-504(s0)
    80004944:	7dba                	ld	s11,424(sp)
    80004946:	a031                	j	80004952 <kexec+0x336>
  ip = 0;
    80004948:	4a01                	li	s4,0
    8000494a:	a021                	j	80004952 <kexec+0x336>
    8000494c:	4a01                	li	s4,0
  if(pagetable)
    8000494e:	a011                	j	80004952 <kexec+0x336>
    80004950:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004952:	e0843583          	ld	a1,-504(s0)
    80004956:	855a                	mv	a0,s6
    80004958:	936fd0ef          	jal	80001a8e <proc_freepagetable>
  return -1;
    8000495c:	557d                	li	a0,-1
  if(ip){
    8000495e:	000a1b63          	bnez	s4,80004974 <kexec+0x358>
    80004962:	79be                	ld	s3,488(sp)
    80004964:	7a1e                	ld	s4,480(sp)
    80004966:	6afe                	ld	s5,472(sp)
    80004968:	6b5e                	ld	s6,464(sp)
    8000496a:	6bbe                	ld	s7,456(sp)
    8000496c:	6c1e                	ld	s8,448(sp)
    8000496e:	7cfa                	ld	s9,440(sp)
    80004970:	7d5a                	ld	s10,432(sp)
    80004972:	bb21                	j	8000468a <kexec+0x6e>
    80004974:	79be                	ld	s3,488(sp)
    80004976:	6afe                	ld	s5,472(sp)
    80004978:	6b5e                	ld	s6,464(sp)
    8000497a:	6bbe                	ld	s7,456(sp)
    8000497c:	6c1e                	ld	s8,448(sp)
    8000497e:	7cfa                	ld	s9,440(sp)
    80004980:	7d5a                	ld	s10,432(sp)
    80004982:	b9ed                	j	8000467c <kexec+0x60>
    80004984:	6b5e                	ld	s6,464(sp)
    80004986:	b9dd                	j	8000467c <kexec+0x60>
  sz = sz1;
    80004988:	e0843983          	ld	s3,-504(s0)
    8000498c:	b595                	j	800047f0 <kexec+0x1d4>

000000008000498e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000498e:	7179                	addi	sp,sp,-48
    80004990:	f406                	sd	ra,40(sp)
    80004992:	f022                	sd	s0,32(sp)
    80004994:	ec26                	sd	s1,24(sp)
    80004996:	e84a                	sd	s2,16(sp)
    80004998:	1800                	addi	s0,sp,48
    8000499a:	892e                	mv	s2,a1
    8000499c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000499e:	fdc40593          	addi	a1,s0,-36
    800049a2:	e77fd0ef          	jal	80002818 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800049a6:	fdc42703          	lw	a4,-36(s0)
    800049aa:	47bd                	li	a5,15
    800049ac:	02e7e963          	bltu	a5,a4,800049de <argfd+0x50>
    800049b0:	f55fc0ef          	jal	80001904 <myproc>
    800049b4:	fdc42703          	lw	a4,-36(s0)
    800049b8:	01a70793          	addi	a5,a4,26
    800049bc:	078e                	slli	a5,a5,0x3
    800049be:	953e                	add	a0,a0,a5
    800049c0:	611c                	ld	a5,0(a0)
    800049c2:	c385                	beqz	a5,800049e2 <argfd+0x54>
    return -1;
  if(pfd)
    800049c4:	00090463          	beqz	s2,800049cc <argfd+0x3e>
    *pfd = fd;
    800049c8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800049cc:	4501                	li	a0,0
  if(pf)
    800049ce:	c091                	beqz	s1,800049d2 <argfd+0x44>
    *pf = f;
    800049d0:	e09c                	sd	a5,0(s1)
}
    800049d2:	70a2                	ld	ra,40(sp)
    800049d4:	7402                	ld	s0,32(sp)
    800049d6:	64e2                	ld	s1,24(sp)
    800049d8:	6942                	ld	s2,16(sp)
    800049da:	6145                	addi	sp,sp,48
    800049dc:	8082                	ret
    return -1;
    800049de:	557d                	li	a0,-1
    800049e0:	bfcd                	j	800049d2 <argfd+0x44>
    800049e2:	557d                	li	a0,-1
    800049e4:	b7fd                	j	800049d2 <argfd+0x44>

00000000800049e6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800049e6:	1101                	addi	sp,sp,-32
    800049e8:	ec06                	sd	ra,24(sp)
    800049ea:	e822                	sd	s0,16(sp)
    800049ec:	e426                	sd	s1,8(sp)
    800049ee:	1000                	addi	s0,sp,32
    800049f0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800049f2:	f13fc0ef          	jal	80001904 <myproc>
    800049f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800049f8:	0d050793          	addi	a5,a0,208
    800049fc:	4501                	li	a0,0
    800049fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004a00:	6398                	ld	a4,0(a5)
    80004a02:	cb19                	beqz	a4,80004a18 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004a04:	2505                	addiw	a0,a0,1
    80004a06:	07a1                	addi	a5,a5,8
    80004a08:	fed51ce3          	bne	a0,a3,80004a00 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004a0c:	557d                	li	a0,-1
}
    80004a0e:	60e2                	ld	ra,24(sp)
    80004a10:	6442                	ld	s0,16(sp)
    80004a12:	64a2                	ld	s1,8(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret
      p->ofile[fd] = f;
    80004a18:	01a50793          	addi	a5,a0,26
    80004a1c:	078e                	slli	a5,a5,0x3
    80004a1e:	963e                	add	a2,a2,a5
    80004a20:	e204                	sd	s1,0(a2)
      return fd;
    80004a22:	b7f5                	j	80004a0e <fdalloc+0x28>

0000000080004a24 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004a24:	715d                	addi	sp,sp,-80
    80004a26:	e486                	sd	ra,72(sp)
    80004a28:	e0a2                	sd	s0,64(sp)
    80004a2a:	fc26                	sd	s1,56(sp)
    80004a2c:	f84a                	sd	s2,48(sp)
    80004a2e:	f44e                	sd	s3,40(sp)
    80004a30:	ec56                	sd	s5,24(sp)
    80004a32:	e85a                	sd	s6,16(sp)
    80004a34:	0880                	addi	s0,sp,80
    80004a36:	8b2e                	mv	s6,a1
    80004a38:	89b2                	mv	s3,a2
    80004a3a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004a3c:	fb040593          	addi	a1,s0,-80
    80004a40:	80eff0ef          	jal	80003a4e <nameiparent>
    80004a44:	84aa                	mv	s1,a0
    80004a46:	10050a63          	beqz	a0,80004b5a <create+0x136>
    return 0;

  ilock(dp);
    80004a4a:	fd4fe0ef          	jal	8000321e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a4e:	4601                	li	a2,0
    80004a50:	fb040593          	addi	a1,s0,-80
    80004a54:	8526                	mv	a0,s1
    80004a56:	d79fe0ef          	jal	800037ce <dirlookup>
    80004a5a:	8aaa                	mv	s5,a0
    80004a5c:	c129                	beqz	a0,80004a9e <create+0x7a>
    iunlockput(dp);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	9c9fe0ef          	jal	80003428 <iunlockput>
    ilock(ip);
    80004a64:	8556                	mv	a0,s5
    80004a66:	fb8fe0ef          	jal	8000321e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004a6a:	4789                	li	a5,2
    80004a6c:	02fb1463          	bne	s6,a5,80004a94 <create+0x70>
    80004a70:	044ad783          	lhu	a5,68(s5)
    80004a74:	37f9                	addiw	a5,a5,-2
    80004a76:	17c2                	slli	a5,a5,0x30
    80004a78:	93c1                	srli	a5,a5,0x30
    80004a7a:	4705                	li	a4,1
    80004a7c:	00f76c63          	bltu	a4,a5,80004a94 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004a80:	8556                	mv	a0,s5
    80004a82:	60a6                	ld	ra,72(sp)
    80004a84:	6406                	ld	s0,64(sp)
    80004a86:	74e2                	ld	s1,56(sp)
    80004a88:	7942                	ld	s2,48(sp)
    80004a8a:	79a2                	ld	s3,40(sp)
    80004a8c:	6ae2                	ld	s5,24(sp)
    80004a8e:	6b42                	ld	s6,16(sp)
    80004a90:	6161                	addi	sp,sp,80
    80004a92:	8082                	ret
    iunlockput(ip);
    80004a94:	8556                	mv	a0,s5
    80004a96:	993fe0ef          	jal	80003428 <iunlockput>
    return 0;
    80004a9a:	4a81                	li	s5,0
    80004a9c:	b7d5                	j	80004a80 <create+0x5c>
    80004a9e:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004aa0:	85da                	mv	a1,s6
    80004aa2:	4088                	lw	a0,0(s1)
    80004aa4:	e0afe0ef          	jal	800030ae <ialloc>
    80004aa8:	8a2a                	mv	s4,a0
    80004aaa:	cd15                	beqz	a0,80004ae6 <create+0xc2>
  ilock(ip);
    80004aac:	f72fe0ef          	jal	8000321e <ilock>
  ip->major = major;
    80004ab0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004ab4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004ab8:	4905                	li	s2,1
    80004aba:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004abe:	8552                	mv	a0,s4
    80004ac0:	eaafe0ef          	jal	8000316a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004ac4:	032b0763          	beq	s6,s2,80004af2 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ac8:	004a2603          	lw	a2,4(s4)
    80004acc:	fb040593          	addi	a1,s0,-80
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ec9fe0ef          	jal	8000399a <dirlink>
    80004ad6:	06054563          	bltz	a0,80004b40 <create+0x11c>
  iunlockput(dp);
    80004ada:	8526                	mv	a0,s1
    80004adc:	94dfe0ef          	jal	80003428 <iunlockput>
  return ip;
    80004ae0:	8ad2                	mv	s5,s4
    80004ae2:	7a02                	ld	s4,32(sp)
    80004ae4:	bf71                	j	80004a80 <create+0x5c>
    iunlockput(dp);
    80004ae6:	8526                	mv	a0,s1
    80004ae8:	941fe0ef          	jal	80003428 <iunlockput>
    return 0;
    80004aec:	8ad2                	mv	s5,s4
    80004aee:	7a02                	ld	s4,32(sp)
    80004af0:	bf41                	j	80004a80 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004af2:	004a2603          	lw	a2,4(s4)
    80004af6:	00003597          	auipc	a1,0x3
    80004afa:	ad258593          	addi	a1,a1,-1326 # 800075c8 <etext+0x5c8>
    80004afe:	8552                	mv	a0,s4
    80004b00:	e9bfe0ef          	jal	8000399a <dirlink>
    80004b04:	02054e63          	bltz	a0,80004b40 <create+0x11c>
    80004b08:	40d0                	lw	a2,4(s1)
    80004b0a:	00003597          	auipc	a1,0x3
    80004b0e:	ac658593          	addi	a1,a1,-1338 # 800075d0 <etext+0x5d0>
    80004b12:	8552                	mv	a0,s4
    80004b14:	e87fe0ef          	jal	8000399a <dirlink>
    80004b18:	02054463          	bltz	a0,80004b40 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b1c:	004a2603          	lw	a2,4(s4)
    80004b20:	fb040593          	addi	a1,s0,-80
    80004b24:	8526                	mv	a0,s1
    80004b26:	e75fe0ef          	jal	8000399a <dirlink>
    80004b2a:	00054b63          	bltz	a0,80004b40 <create+0x11c>
    dp->nlink++;  // for ".."
    80004b2e:	04a4d783          	lhu	a5,74(s1)
    80004b32:	2785                	addiw	a5,a5,1
    80004b34:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	e30fe0ef          	jal	8000316a <iupdate>
    80004b3e:	bf71                	j	80004ada <create+0xb6>
  ip->nlink = 0;
    80004b40:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004b44:	8552                	mv	a0,s4
    80004b46:	e24fe0ef          	jal	8000316a <iupdate>
  iunlockput(ip);
    80004b4a:	8552                	mv	a0,s4
    80004b4c:	8ddfe0ef          	jal	80003428 <iunlockput>
  iunlockput(dp);
    80004b50:	8526                	mv	a0,s1
    80004b52:	8d7fe0ef          	jal	80003428 <iunlockput>
  return 0;
    80004b56:	7a02                	ld	s4,32(sp)
    80004b58:	b725                	j	80004a80 <create+0x5c>
    return 0;
    80004b5a:	8aaa                	mv	s5,a0
    80004b5c:	b715                	j	80004a80 <create+0x5c>

0000000080004b5e <sys_dup>:
{
    80004b5e:	7179                	addi	sp,sp,-48
    80004b60:	f406                	sd	ra,40(sp)
    80004b62:	f022                	sd	s0,32(sp)
    80004b64:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004b66:	fd840613          	addi	a2,s0,-40
    80004b6a:	4581                	li	a1,0
    80004b6c:	4501                	li	a0,0
    80004b6e:	e21ff0ef          	jal	8000498e <argfd>
    return -1;
    80004b72:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004b74:	02054363          	bltz	a0,80004b9a <sys_dup+0x3c>
    80004b78:	ec26                	sd	s1,24(sp)
    80004b7a:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004b7c:	fd843903          	ld	s2,-40(s0)
    80004b80:	854a                	mv	a0,s2
    80004b82:	e65ff0ef          	jal	800049e6 <fdalloc>
    80004b86:	84aa                	mv	s1,a0
    return -1;
    80004b88:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004b8a:	00054d63          	bltz	a0,80004ba4 <sys_dup+0x46>
  filedup(f);
    80004b8e:	854a                	mv	a0,s2
    80004b90:	c3eff0ef          	jal	80003fce <filedup>
  return fd;
    80004b94:	87a6                	mv	a5,s1
    80004b96:	64e2                	ld	s1,24(sp)
    80004b98:	6942                	ld	s2,16(sp)
}
    80004b9a:	853e                	mv	a0,a5
    80004b9c:	70a2                	ld	ra,40(sp)
    80004b9e:	7402                	ld	s0,32(sp)
    80004ba0:	6145                	addi	sp,sp,48
    80004ba2:	8082                	ret
    80004ba4:	64e2                	ld	s1,24(sp)
    80004ba6:	6942                	ld	s2,16(sp)
    80004ba8:	bfcd                	j	80004b9a <sys_dup+0x3c>

0000000080004baa <sys_read>:
{
    80004baa:	7179                	addi	sp,sp,-48
    80004bac:	f406                	sd	ra,40(sp)
    80004bae:	f022                	sd	s0,32(sp)
    80004bb0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004bb2:	fd840593          	addi	a1,s0,-40
    80004bb6:	4505                	li	a0,1
    80004bb8:	c7dfd0ef          	jal	80002834 <argaddr>
  argint(2, &n);
    80004bbc:	fe440593          	addi	a1,s0,-28
    80004bc0:	4509                	li	a0,2
    80004bc2:	c57fd0ef          	jal	80002818 <argint>
  if(argfd(0, 0, &f) < 0)
    80004bc6:	fe840613          	addi	a2,s0,-24
    80004bca:	4581                	li	a1,0
    80004bcc:	4501                	li	a0,0
    80004bce:	dc1ff0ef          	jal	8000498e <argfd>
    80004bd2:	87aa                	mv	a5,a0
    return -1;
    80004bd4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004bd6:	0007ca63          	bltz	a5,80004bea <sys_read+0x40>
  return fileread(f, p, n);
    80004bda:	fe442603          	lw	a2,-28(s0)
    80004bde:	fd843583          	ld	a1,-40(s0)
    80004be2:	fe843503          	ld	a0,-24(s0)
    80004be6:	d4eff0ef          	jal	80004134 <fileread>
}
    80004bea:	70a2                	ld	ra,40(sp)
    80004bec:	7402                	ld	s0,32(sp)
    80004bee:	6145                	addi	sp,sp,48
    80004bf0:	8082                	ret

0000000080004bf2 <sys_write>:
{
    80004bf2:	7179                	addi	sp,sp,-48
    80004bf4:	f406                	sd	ra,40(sp)
    80004bf6:	f022                	sd	s0,32(sp)
    80004bf8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004bfa:	fd840593          	addi	a1,s0,-40
    80004bfe:	4505                	li	a0,1
    80004c00:	c35fd0ef          	jal	80002834 <argaddr>
  argint(2, &n);
    80004c04:	fe440593          	addi	a1,s0,-28
    80004c08:	4509                	li	a0,2
    80004c0a:	c0ffd0ef          	jal	80002818 <argint>
  if(argfd(0, 0, &f) < 0)
    80004c0e:	fe840613          	addi	a2,s0,-24
    80004c12:	4581                	li	a1,0
    80004c14:	4501                	li	a0,0
    80004c16:	d79ff0ef          	jal	8000498e <argfd>
    80004c1a:	87aa                	mv	a5,a0
    return -1;
    80004c1c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c1e:	0007ca63          	bltz	a5,80004c32 <sys_write+0x40>
  return filewrite(f, p, n);
    80004c22:	fe442603          	lw	a2,-28(s0)
    80004c26:	fd843583          	ld	a1,-40(s0)
    80004c2a:	fe843503          	ld	a0,-24(s0)
    80004c2e:	dc4ff0ef          	jal	800041f2 <filewrite>
}
    80004c32:	70a2                	ld	ra,40(sp)
    80004c34:	7402                	ld	s0,32(sp)
    80004c36:	6145                	addi	sp,sp,48
    80004c38:	8082                	ret

0000000080004c3a <sys_close>:
{
    80004c3a:	1101                	addi	sp,sp,-32
    80004c3c:	ec06                	sd	ra,24(sp)
    80004c3e:	e822                	sd	s0,16(sp)
    80004c40:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004c42:	fe040613          	addi	a2,s0,-32
    80004c46:	fec40593          	addi	a1,s0,-20
    80004c4a:	4501                	li	a0,0
    80004c4c:	d43ff0ef          	jal	8000498e <argfd>
    return -1;
    80004c50:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004c52:	02054063          	bltz	a0,80004c72 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004c56:	caffc0ef          	jal	80001904 <myproc>
    80004c5a:	fec42783          	lw	a5,-20(s0)
    80004c5e:	07e9                	addi	a5,a5,26
    80004c60:	078e                	slli	a5,a5,0x3
    80004c62:	953e                	add	a0,a0,a5
    80004c64:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004c68:	fe043503          	ld	a0,-32(s0)
    80004c6c:	ba8ff0ef          	jal	80004014 <fileclose>
  return 0;
    80004c70:	4781                	li	a5,0
}
    80004c72:	853e                	mv	a0,a5
    80004c74:	60e2                	ld	ra,24(sp)
    80004c76:	6442                	ld	s0,16(sp)
    80004c78:	6105                	addi	sp,sp,32
    80004c7a:	8082                	ret

0000000080004c7c <sys_fstat>:
{
    80004c7c:	1101                	addi	sp,sp,-32
    80004c7e:	ec06                	sd	ra,24(sp)
    80004c80:	e822                	sd	s0,16(sp)
    80004c82:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004c84:	fe040593          	addi	a1,s0,-32
    80004c88:	4505                	li	a0,1
    80004c8a:	babfd0ef          	jal	80002834 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004c8e:	fe840613          	addi	a2,s0,-24
    80004c92:	4581                	li	a1,0
    80004c94:	4501                	li	a0,0
    80004c96:	cf9ff0ef          	jal	8000498e <argfd>
    80004c9a:	87aa                	mv	a5,a0
    return -1;
    80004c9c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c9e:	0007c863          	bltz	a5,80004cae <sys_fstat+0x32>
  return filestat(f, st);
    80004ca2:	fe043583          	ld	a1,-32(s0)
    80004ca6:	fe843503          	ld	a0,-24(s0)
    80004caa:	c2cff0ef          	jal	800040d6 <filestat>
}
    80004cae:	60e2                	ld	ra,24(sp)
    80004cb0:	6442                	ld	s0,16(sp)
    80004cb2:	6105                	addi	sp,sp,32
    80004cb4:	8082                	ret

0000000080004cb6 <sys_link>:
{
    80004cb6:	7169                	addi	sp,sp,-304
    80004cb8:	f606                	sd	ra,296(sp)
    80004cba:	f222                	sd	s0,288(sp)
    80004cbc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004cbe:	08000613          	li	a2,128
    80004cc2:	ed040593          	addi	a1,s0,-304
    80004cc6:	4501                	li	a0,0
    80004cc8:	b89fd0ef          	jal	80002850 <argstr>
    return -1;
    80004ccc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004cce:	0c054e63          	bltz	a0,80004daa <sys_link+0xf4>
    80004cd2:	08000613          	li	a2,128
    80004cd6:	f5040593          	addi	a1,s0,-176
    80004cda:	4505                	li	a0,1
    80004cdc:	b75fd0ef          	jal	80002850 <argstr>
    return -1;
    80004ce0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004ce2:	0c054463          	bltz	a0,80004daa <sys_link+0xf4>
    80004ce6:	ee26                	sd	s1,280(sp)
  begin_op();
    80004ce8:	f21fe0ef          	jal	80003c08 <begin_op>
  if((ip = namei(old)) == 0){
    80004cec:	ed040513          	addi	a0,s0,-304
    80004cf0:	d45fe0ef          	jal	80003a34 <namei>
    80004cf4:	84aa                	mv	s1,a0
    80004cf6:	c53d                	beqz	a0,80004d64 <sys_link+0xae>
  ilock(ip);
    80004cf8:	d26fe0ef          	jal	8000321e <ilock>
  if(ip->type == T_DIR){
    80004cfc:	04449703          	lh	a4,68(s1)
    80004d00:	4785                	li	a5,1
    80004d02:	06f70663          	beq	a4,a5,80004d6e <sys_link+0xb8>
    80004d06:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004d08:	04a4d783          	lhu	a5,74(s1)
    80004d0c:	2785                	addiw	a5,a5,1
    80004d0e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004d12:	8526                	mv	a0,s1
    80004d14:	c56fe0ef          	jal	8000316a <iupdate>
  iunlock(ip);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	db2fe0ef          	jal	800032cc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004d1e:	fd040593          	addi	a1,s0,-48
    80004d22:	f5040513          	addi	a0,s0,-176
    80004d26:	d29fe0ef          	jal	80003a4e <nameiparent>
    80004d2a:	892a                	mv	s2,a0
    80004d2c:	cd21                	beqz	a0,80004d84 <sys_link+0xce>
  ilock(dp);
    80004d2e:	cf0fe0ef          	jal	8000321e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004d32:	00092703          	lw	a4,0(s2)
    80004d36:	409c                	lw	a5,0(s1)
    80004d38:	04f71363          	bne	a4,a5,80004d7e <sys_link+0xc8>
    80004d3c:	40d0                	lw	a2,4(s1)
    80004d3e:	fd040593          	addi	a1,s0,-48
    80004d42:	854a                	mv	a0,s2
    80004d44:	c57fe0ef          	jal	8000399a <dirlink>
    80004d48:	02054b63          	bltz	a0,80004d7e <sys_link+0xc8>
  iunlockput(dp);
    80004d4c:	854a                	mv	a0,s2
    80004d4e:	edafe0ef          	jal	80003428 <iunlockput>
  iput(ip);
    80004d52:	8526                	mv	a0,s1
    80004d54:	e4cfe0ef          	jal	800033a0 <iput>
  end_op();
    80004d58:	f1bfe0ef          	jal	80003c72 <end_op>
  return 0;
    80004d5c:	4781                	li	a5,0
    80004d5e:	64f2                	ld	s1,280(sp)
    80004d60:	6952                	ld	s2,272(sp)
    80004d62:	a0a1                	j	80004daa <sys_link+0xf4>
    end_op();
    80004d64:	f0ffe0ef          	jal	80003c72 <end_op>
    return -1;
    80004d68:	57fd                	li	a5,-1
    80004d6a:	64f2                	ld	s1,280(sp)
    80004d6c:	a83d                	j	80004daa <sys_link+0xf4>
    iunlockput(ip);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	eb8fe0ef          	jal	80003428 <iunlockput>
    end_op();
    80004d74:	efffe0ef          	jal	80003c72 <end_op>
    return -1;
    80004d78:	57fd                	li	a5,-1
    80004d7a:	64f2                	ld	s1,280(sp)
    80004d7c:	a03d                	j	80004daa <sys_link+0xf4>
    iunlockput(dp);
    80004d7e:	854a                	mv	a0,s2
    80004d80:	ea8fe0ef          	jal	80003428 <iunlockput>
  ilock(ip);
    80004d84:	8526                	mv	a0,s1
    80004d86:	c98fe0ef          	jal	8000321e <ilock>
  ip->nlink--;
    80004d8a:	04a4d783          	lhu	a5,74(s1)
    80004d8e:	37fd                	addiw	a5,a5,-1
    80004d90:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004d94:	8526                	mv	a0,s1
    80004d96:	bd4fe0ef          	jal	8000316a <iupdate>
  iunlockput(ip);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	e8cfe0ef          	jal	80003428 <iunlockput>
  end_op();
    80004da0:	ed3fe0ef          	jal	80003c72 <end_op>
  return -1;
    80004da4:	57fd                	li	a5,-1
    80004da6:	64f2                	ld	s1,280(sp)
    80004da8:	6952                	ld	s2,272(sp)
}
    80004daa:	853e                	mv	a0,a5
    80004dac:	70b2                	ld	ra,296(sp)
    80004dae:	7412                	ld	s0,288(sp)
    80004db0:	6155                	addi	sp,sp,304
    80004db2:	8082                	ret

0000000080004db4 <sys_unlink>:
{
    80004db4:	7151                	addi	sp,sp,-240
    80004db6:	f586                	sd	ra,232(sp)
    80004db8:	f1a2                	sd	s0,224(sp)
    80004dba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004dbc:	08000613          	li	a2,128
    80004dc0:	f3040593          	addi	a1,s0,-208
    80004dc4:	4501                	li	a0,0
    80004dc6:	a8bfd0ef          	jal	80002850 <argstr>
    80004dca:	16054063          	bltz	a0,80004f2a <sys_unlink+0x176>
    80004dce:	eda6                	sd	s1,216(sp)
  begin_op();
    80004dd0:	e39fe0ef          	jal	80003c08 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004dd4:	fb040593          	addi	a1,s0,-80
    80004dd8:	f3040513          	addi	a0,s0,-208
    80004ddc:	c73fe0ef          	jal	80003a4e <nameiparent>
    80004de0:	84aa                	mv	s1,a0
    80004de2:	c945                	beqz	a0,80004e92 <sys_unlink+0xde>
  ilock(dp);
    80004de4:	c3afe0ef          	jal	8000321e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004de8:	00002597          	auipc	a1,0x2
    80004dec:	7e058593          	addi	a1,a1,2016 # 800075c8 <etext+0x5c8>
    80004df0:	fb040513          	addi	a0,s0,-80
    80004df4:	9c5fe0ef          	jal	800037b8 <namecmp>
    80004df8:	10050e63          	beqz	a0,80004f14 <sys_unlink+0x160>
    80004dfc:	00002597          	auipc	a1,0x2
    80004e00:	7d458593          	addi	a1,a1,2004 # 800075d0 <etext+0x5d0>
    80004e04:	fb040513          	addi	a0,s0,-80
    80004e08:	9b1fe0ef          	jal	800037b8 <namecmp>
    80004e0c:	10050463          	beqz	a0,80004f14 <sys_unlink+0x160>
    80004e10:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004e12:	f2c40613          	addi	a2,s0,-212
    80004e16:	fb040593          	addi	a1,s0,-80
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	9b3fe0ef          	jal	800037ce <dirlookup>
    80004e20:	892a                	mv	s2,a0
    80004e22:	0e050863          	beqz	a0,80004f12 <sys_unlink+0x15e>
  ilock(ip);
    80004e26:	bf8fe0ef          	jal	8000321e <ilock>
  if(ip->nlink < 1)
    80004e2a:	04a91783          	lh	a5,74(s2)
    80004e2e:	06f05763          	blez	a5,80004e9c <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004e32:	04491703          	lh	a4,68(s2)
    80004e36:	4785                	li	a5,1
    80004e38:	06f70963          	beq	a4,a5,80004eaa <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80004e3c:	4641                	li	a2,16
    80004e3e:	4581                	li	a1,0
    80004e40:	fc040513          	addi	a0,s0,-64
    80004e44:	e91fb0ef          	jal	80000cd4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004e48:	4741                	li	a4,16
    80004e4a:	f2c42683          	lw	a3,-212(s0)
    80004e4e:	fc040613          	addi	a2,s0,-64
    80004e52:	4581                	li	a1,0
    80004e54:	8526                	mv	a0,s1
    80004e56:	855fe0ef          	jal	800036aa <writei>
    80004e5a:	47c1                	li	a5,16
    80004e5c:	08f51b63          	bne	a0,a5,80004ef2 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80004e60:	04491703          	lh	a4,68(s2)
    80004e64:	4785                	li	a5,1
    80004e66:	08f70d63          	beq	a4,a5,80004f00 <sys_unlink+0x14c>
  iunlockput(dp);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	dbcfe0ef          	jal	80003428 <iunlockput>
  ip->nlink--;
    80004e70:	04a95783          	lhu	a5,74(s2)
    80004e74:	37fd                	addiw	a5,a5,-1
    80004e76:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004e7a:	854a                	mv	a0,s2
    80004e7c:	aeefe0ef          	jal	8000316a <iupdate>
  iunlockput(ip);
    80004e80:	854a                	mv	a0,s2
    80004e82:	da6fe0ef          	jal	80003428 <iunlockput>
  end_op();
    80004e86:	dedfe0ef          	jal	80003c72 <end_op>
  return 0;
    80004e8a:	4501                	li	a0,0
    80004e8c:	64ee                	ld	s1,216(sp)
    80004e8e:	694e                	ld	s2,208(sp)
    80004e90:	a849                	j	80004f22 <sys_unlink+0x16e>
    end_op();
    80004e92:	de1fe0ef          	jal	80003c72 <end_op>
    return -1;
    80004e96:	557d                	li	a0,-1
    80004e98:	64ee                	ld	s1,216(sp)
    80004e9a:	a061                	j	80004f22 <sys_unlink+0x16e>
    80004e9c:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80004e9e:	00002517          	auipc	a0,0x2
    80004ea2:	73a50513          	addi	a0,a0,1850 # 800075d8 <etext+0x5d8>
    80004ea6:	96dfb0ef          	jal	80000812 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004eaa:	04c92703          	lw	a4,76(s2)
    80004eae:	02000793          	li	a5,32
    80004eb2:	f8e7f5e3          	bgeu	a5,a4,80004e3c <sys_unlink+0x88>
    80004eb6:	e5ce                	sd	s3,200(sp)
    80004eb8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ebc:	4741                	li	a4,16
    80004ebe:	86ce                	mv	a3,s3
    80004ec0:	f1840613          	addi	a2,s0,-232
    80004ec4:	4581                	li	a1,0
    80004ec6:	854a                	mv	a0,s2
    80004ec8:	ee6fe0ef          	jal	800035ae <readi>
    80004ecc:	47c1                	li	a5,16
    80004ece:	00f51c63          	bne	a0,a5,80004ee6 <sys_unlink+0x132>
    if(de.inum != 0)
    80004ed2:	f1845783          	lhu	a5,-232(s0)
    80004ed6:	efa1                	bnez	a5,80004f2e <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004ed8:	29c1                	addiw	s3,s3,16
    80004eda:	04c92783          	lw	a5,76(s2)
    80004ede:	fcf9efe3          	bltu	s3,a5,80004ebc <sys_unlink+0x108>
    80004ee2:	69ae                	ld	s3,200(sp)
    80004ee4:	bfa1                	j	80004e3c <sys_unlink+0x88>
      panic("isdirempty: readi");
    80004ee6:	00002517          	auipc	a0,0x2
    80004eea:	70a50513          	addi	a0,a0,1802 # 800075f0 <etext+0x5f0>
    80004eee:	925fb0ef          	jal	80000812 <panic>
    80004ef2:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80004ef4:	00002517          	auipc	a0,0x2
    80004ef8:	71450513          	addi	a0,a0,1812 # 80007608 <etext+0x608>
    80004efc:	917fb0ef          	jal	80000812 <panic>
    dp->nlink--;
    80004f00:	04a4d783          	lhu	a5,74(s1)
    80004f04:	37fd                	addiw	a5,a5,-1
    80004f06:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004f0a:	8526                	mv	a0,s1
    80004f0c:	a5efe0ef          	jal	8000316a <iupdate>
    80004f10:	bfa9                	j	80004e6a <sys_unlink+0xb6>
    80004f12:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80004f14:	8526                	mv	a0,s1
    80004f16:	d12fe0ef          	jal	80003428 <iunlockput>
  end_op();
    80004f1a:	d59fe0ef          	jal	80003c72 <end_op>
  return -1;
    80004f1e:	557d                	li	a0,-1
    80004f20:	64ee                	ld	s1,216(sp)
}
    80004f22:	70ae                	ld	ra,232(sp)
    80004f24:	740e                	ld	s0,224(sp)
    80004f26:	616d                	addi	sp,sp,240
    80004f28:	8082                	ret
    return -1;
    80004f2a:	557d                	li	a0,-1
    80004f2c:	bfdd                	j	80004f22 <sys_unlink+0x16e>
    iunlockput(ip);
    80004f2e:	854a                	mv	a0,s2
    80004f30:	cf8fe0ef          	jal	80003428 <iunlockput>
    goto bad;
    80004f34:	694e                	ld	s2,208(sp)
    80004f36:	69ae                	ld	s3,200(sp)
    80004f38:	bff1                	j	80004f14 <sys_unlink+0x160>

0000000080004f3a <sys_open>:

uint64
sys_open(void)
{
    80004f3a:	7131                	addi	sp,sp,-192
    80004f3c:	fd06                	sd	ra,184(sp)
    80004f3e:	f922                	sd	s0,176(sp)
    80004f40:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004f42:	f4c40593          	addi	a1,s0,-180
    80004f46:	4505                	li	a0,1
    80004f48:	8d1fd0ef          	jal	80002818 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004f4c:	08000613          	li	a2,128
    80004f50:	f5040593          	addi	a1,s0,-176
    80004f54:	4501                	li	a0,0
    80004f56:	8fbfd0ef          	jal	80002850 <argstr>
    80004f5a:	87aa                	mv	a5,a0
    return -1;
    80004f5c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004f5e:	0a07c263          	bltz	a5,80005002 <sys_open+0xc8>
    80004f62:	f526                	sd	s1,168(sp)

  begin_op();
    80004f64:	ca5fe0ef          	jal	80003c08 <begin_op>

  if(omode & O_CREATE){
    80004f68:	f4c42783          	lw	a5,-180(s0)
    80004f6c:	2007f793          	andi	a5,a5,512
    80004f70:	c3d5                	beqz	a5,80005014 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    80004f72:	4681                	li	a3,0
    80004f74:	4601                	li	a2,0
    80004f76:	4589                	li	a1,2
    80004f78:	f5040513          	addi	a0,s0,-176
    80004f7c:	aa9ff0ef          	jal	80004a24 <create>
    80004f80:	84aa                	mv	s1,a0
    if(ip == 0){
    80004f82:	c541                	beqz	a0,8000500a <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80004f84:	04449703          	lh	a4,68(s1)
    80004f88:	478d                	li	a5,3
    80004f8a:	00f71763          	bne	a4,a5,80004f98 <sys_open+0x5e>
    80004f8e:	0464d703          	lhu	a4,70(s1)
    80004f92:	47a5                	li	a5,9
    80004f94:	0ae7ed63          	bltu	a5,a4,8000504e <sys_open+0x114>
    80004f98:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80004f9a:	fd7fe0ef          	jal	80003f70 <filealloc>
    80004f9e:	892a                	mv	s2,a0
    80004fa0:	c179                	beqz	a0,80005066 <sys_open+0x12c>
    80004fa2:	ed4e                	sd	s3,152(sp)
    80004fa4:	a43ff0ef          	jal	800049e6 <fdalloc>
    80004fa8:	89aa                	mv	s3,a0
    80004faa:	0a054a63          	bltz	a0,8000505e <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80004fae:	04449703          	lh	a4,68(s1)
    80004fb2:	478d                	li	a5,3
    80004fb4:	0cf70263          	beq	a4,a5,80005078 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80004fb8:	4789                	li	a5,2
    80004fba:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80004fbe:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80004fc2:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80004fc6:	f4c42783          	lw	a5,-180(s0)
    80004fca:	0017c713          	xori	a4,a5,1
    80004fce:	8b05                	andi	a4,a4,1
    80004fd0:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80004fd4:	0037f713          	andi	a4,a5,3
    80004fd8:	00e03733          	snez	a4,a4
    80004fdc:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80004fe0:	4007f793          	andi	a5,a5,1024
    80004fe4:	c791                	beqz	a5,80004ff0 <sys_open+0xb6>
    80004fe6:	04449703          	lh	a4,68(s1)
    80004fea:	4789                	li	a5,2
    80004fec:	08f70d63          	beq	a4,a5,80005086 <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    80004ff0:	8526                	mv	a0,s1
    80004ff2:	adafe0ef          	jal	800032cc <iunlock>
  end_op();
    80004ff6:	c7dfe0ef          	jal	80003c72 <end_op>

  return fd;
    80004ffa:	854e                	mv	a0,s3
    80004ffc:	74aa                	ld	s1,168(sp)
    80004ffe:	790a                	ld	s2,160(sp)
    80005000:	69ea                	ld	s3,152(sp)
}
    80005002:	70ea                	ld	ra,184(sp)
    80005004:	744a                	ld	s0,176(sp)
    80005006:	6129                	addi	sp,sp,192
    80005008:	8082                	ret
      end_op();
    8000500a:	c69fe0ef          	jal	80003c72 <end_op>
      return -1;
    8000500e:	557d                	li	a0,-1
    80005010:	74aa                	ld	s1,168(sp)
    80005012:	bfc5                	j	80005002 <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    80005014:	f5040513          	addi	a0,s0,-176
    80005018:	a1dfe0ef          	jal	80003a34 <namei>
    8000501c:	84aa                	mv	s1,a0
    8000501e:	c11d                	beqz	a0,80005044 <sys_open+0x10a>
    ilock(ip);
    80005020:	9fefe0ef          	jal	8000321e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005024:	04449703          	lh	a4,68(s1)
    80005028:	4785                	li	a5,1
    8000502a:	f4f71de3          	bne	a4,a5,80004f84 <sys_open+0x4a>
    8000502e:	f4c42783          	lw	a5,-180(s0)
    80005032:	d3bd                	beqz	a5,80004f98 <sys_open+0x5e>
      iunlockput(ip);
    80005034:	8526                	mv	a0,s1
    80005036:	bf2fe0ef          	jal	80003428 <iunlockput>
      end_op();
    8000503a:	c39fe0ef          	jal	80003c72 <end_op>
      return -1;
    8000503e:	557d                	li	a0,-1
    80005040:	74aa                	ld	s1,168(sp)
    80005042:	b7c1                	j	80005002 <sys_open+0xc8>
      end_op();
    80005044:	c2ffe0ef          	jal	80003c72 <end_op>
      return -1;
    80005048:	557d                	li	a0,-1
    8000504a:	74aa                	ld	s1,168(sp)
    8000504c:	bf5d                	j	80005002 <sys_open+0xc8>
    iunlockput(ip);
    8000504e:	8526                	mv	a0,s1
    80005050:	bd8fe0ef          	jal	80003428 <iunlockput>
    end_op();
    80005054:	c1ffe0ef          	jal	80003c72 <end_op>
    return -1;
    80005058:	557d                	li	a0,-1
    8000505a:	74aa                	ld	s1,168(sp)
    8000505c:	b75d                	j	80005002 <sys_open+0xc8>
      fileclose(f);
    8000505e:	854a                	mv	a0,s2
    80005060:	fb5fe0ef          	jal	80004014 <fileclose>
    80005064:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80005066:	8526                	mv	a0,s1
    80005068:	bc0fe0ef          	jal	80003428 <iunlockput>
    end_op();
    8000506c:	c07fe0ef          	jal	80003c72 <end_op>
    return -1;
    80005070:	557d                	li	a0,-1
    80005072:	74aa                	ld	s1,168(sp)
    80005074:	790a                	ld	s2,160(sp)
    80005076:	b771                	j	80005002 <sys_open+0xc8>
    f->type = FD_DEVICE;
    80005078:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000507c:	04649783          	lh	a5,70(s1)
    80005080:	02f91223          	sh	a5,36(s2)
    80005084:	bf3d                	j	80004fc2 <sys_open+0x88>
    itrunc(ip);
    80005086:	8526                	mv	a0,s1
    80005088:	a84fe0ef          	jal	8000330c <itrunc>
    8000508c:	b795                	j	80004ff0 <sys_open+0xb6>

000000008000508e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000508e:	7175                	addi	sp,sp,-144
    80005090:	e506                	sd	ra,136(sp)
    80005092:	e122                	sd	s0,128(sp)
    80005094:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005096:	b73fe0ef          	jal	80003c08 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000509a:	08000613          	li	a2,128
    8000509e:	f7040593          	addi	a1,s0,-144
    800050a2:	4501                	li	a0,0
    800050a4:	facfd0ef          	jal	80002850 <argstr>
    800050a8:	02054363          	bltz	a0,800050ce <sys_mkdir+0x40>
    800050ac:	4681                	li	a3,0
    800050ae:	4601                	li	a2,0
    800050b0:	4585                	li	a1,1
    800050b2:	f7040513          	addi	a0,s0,-144
    800050b6:	96fff0ef          	jal	80004a24 <create>
    800050ba:	c911                	beqz	a0,800050ce <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800050bc:	b6cfe0ef          	jal	80003428 <iunlockput>
  end_op();
    800050c0:	bb3fe0ef          	jal	80003c72 <end_op>
  return 0;
    800050c4:	4501                	li	a0,0
}
    800050c6:	60aa                	ld	ra,136(sp)
    800050c8:	640a                	ld	s0,128(sp)
    800050ca:	6149                	addi	sp,sp,144
    800050cc:	8082                	ret
    end_op();
    800050ce:	ba5fe0ef          	jal	80003c72 <end_op>
    return -1;
    800050d2:	557d                	li	a0,-1
    800050d4:	bfcd                	j	800050c6 <sys_mkdir+0x38>

00000000800050d6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800050d6:	7135                	addi	sp,sp,-160
    800050d8:	ed06                	sd	ra,152(sp)
    800050da:	e922                	sd	s0,144(sp)
    800050dc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800050de:	b2bfe0ef          	jal	80003c08 <begin_op>
  argint(1, &major);
    800050e2:	f6c40593          	addi	a1,s0,-148
    800050e6:	4505                	li	a0,1
    800050e8:	f30fd0ef          	jal	80002818 <argint>
  argint(2, &minor);
    800050ec:	f6840593          	addi	a1,s0,-152
    800050f0:	4509                	li	a0,2
    800050f2:	f26fd0ef          	jal	80002818 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800050f6:	08000613          	li	a2,128
    800050fa:	f7040593          	addi	a1,s0,-144
    800050fe:	4501                	li	a0,0
    80005100:	f50fd0ef          	jal	80002850 <argstr>
    80005104:	02054563          	bltz	a0,8000512e <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005108:	f6841683          	lh	a3,-152(s0)
    8000510c:	f6c41603          	lh	a2,-148(s0)
    80005110:	458d                	li	a1,3
    80005112:	f7040513          	addi	a0,s0,-144
    80005116:	90fff0ef          	jal	80004a24 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000511a:	c911                	beqz	a0,8000512e <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000511c:	b0cfe0ef          	jal	80003428 <iunlockput>
  end_op();
    80005120:	b53fe0ef          	jal	80003c72 <end_op>
  return 0;
    80005124:	4501                	li	a0,0
}
    80005126:	60ea                	ld	ra,152(sp)
    80005128:	644a                	ld	s0,144(sp)
    8000512a:	610d                	addi	sp,sp,160
    8000512c:	8082                	ret
    end_op();
    8000512e:	b45fe0ef          	jal	80003c72 <end_op>
    return -1;
    80005132:	557d                	li	a0,-1
    80005134:	bfcd                	j	80005126 <sys_mknod+0x50>

0000000080005136 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005136:	7135                	addi	sp,sp,-160
    80005138:	ed06                	sd	ra,152(sp)
    8000513a:	e922                	sd	s0,144(sp)
    8000513c:	e14a                	sd	s2,128(sp)
    8000513e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005140:	fc4fc0ef          	jal	80001904 <myproc>
    80005144:	892a                	mv	s2,a0
  
  begin_op();
    80005146:	ac3fe0ef          	jal	80003c08 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000514a:	08000613          	li	a2,128
    8000514e:	f6040593          	addi	a1,s0,-160
    80005152:	4501                	li	a0,0
    80005154:	efcfd0ef          	jal	80002850 <argstr>
    80005158:	04054363          	bltz	a0,8000519e <sys_chdir+0x68>
    8000515c:	e526                	sd	s1,136(sp)
    8000515e:	f6040513          	addi	a0,s0,-160
    80005162:	8d3fe0ef          	jal	80003a34 <namei>
    80005166:	84aa                	mv	s1,a0
    80005168:	c915                	beqz	a0,8000519c <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    8000516a:	8b4fe0ef          	jal	8000321e <ilock>
  if(ip->type != T_DIR){
    8000516e:	04449703          	lh	a4,68(s1)
    80005172:	4785                	li	a5,1
    80005174:	02f71963          	bne	a4,a5,800051a6 <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005178:	8526                	mv	a0,s1
    8000517a:	952fe0ef          	jal	800032cc <iunlock>
  iput(p->cwd);
    8000517e:	15093503          	ld	a0,336(s2)
    80005182:	a1efe0ef          	jal	800033a0 <iput>
  end_op();
    80005186:	aedfe0ef          	jal	80003c72 <end_op>
  p->cwd = ip;
    8000518a:	14993823          	sd	s1,336(s2)
  return 0;
    8000518e:	4501                	li	a0,0
    80005190:	64aa                	ld	s1,136(sp)
}
    80005192:	60ea                	ld	ra,152(sp)
    80005194:	644a                	ld	s0,144(sp)
    80005196:	690a                	ld	s2,128(sp)
    80005198:	610d                	addi	sp,sp,160
    8000519a:	8082                	ret
    8000519c:	64aa                	ld	s1,136(sp)
    end_op();
    8000519e:	ad5fe0ef          	jal	80003c72 <end_op>
    return -1;
    800051a2:	557d                	li	a0,-1
    800051a4:	b7fd                	j	80005192 <sys_chdir+0x5c>
    iunlockput(ip);
    800051a6:	8526                	mv	a0,s1
    800051a8:	a80fe0ef          	jal	80003428 <iunlockput>
    end_op();
    800051ac:	ac7fe0ef          	jal	80003c72 <end_op>
    return -1;
    800051b0:	557d                	li	a0,-1
    800051b2:	64aa                	ld	s1,136(sp)
    800051b4:	bff9                	j	80005192 <sys_chdir+0x5c>

00000000800051b6 <sys_exec>:

uint64
sys_exec(void)
{
    800051b6:	7121                	addi	sp,sp,-448
    800051b8:	ff06                	sd	ra,440(sp)
    800051ba:	fb22                	sd	s0,432(sp)
    800051bc:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800051be:	e4840593          	addi	a1,s0,-440
    800051c2:	4505                	li	a0,1
    800051c4:	e70fd0ef          	jal	80002834 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800051c8:	08000613          	li	a2,128
    800051cc:	f5040593          	addi	a1,s0,-176
    800051d0:	4501                	li	a0,0
    800051d2:	e7efd0ef          	jal	80002850 <argstr>
    800051d6:	87aa                	mv	a5,a0
    return -1;
    800051d8:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800051da:	0c07c463          	bltz	a5,800052a2 <sys_exec+0xec>
    800051de:	f726                	sd	s1,424(sp)
    800051e0:	f34a                	sd	s2,416(sp)
    800051e2:	ef4e                	sd	s3,408(sp)
    800051e4:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800051e6:	10000613          	li	a2,256
    800051ea:	4581                	li	a1,0
    800051ec:	e5040513          	addi	a0,s0,-432
    800051f0:	ae5fb0ef          	jal	80000cd4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800051f4:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800051f8:	89a6                	mv	s3,s1
    800051fa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800051fc:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005200:	00391513          	slli	a0,s2,0x3
    80005204:	e4040593          	addi	a1,s0,-448
    80005208:	e4843783          	ld	a5,-440(s0)
    8000520c:	953e                	add	a0,a0,a5
    8000520e:	d80fd0ef          	jal	8000278e <fetchaddr>
    80005212:	02054663          	bltz	a0,8000523e <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80005216:	e4043783          	ld	a5,-448(s0)
    8000521a:	c3a9                	beqz	a5,8000525c <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000521c:	915fb0ef          	jal	80000b30 <kalloc>
    80005220:	85aa                	mv	a1,a0
    80005222:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005226:	cd01                	beqz	a0,8000523e <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005228:	6605                	lui	a2,0x1
    8000522a:	e4043503          	ld	a0,-448(s0)
    8000522e:	daafd0ef          	jal	800027d8 <fetchstr>
    80005232:	00054663          	bltz	a0,8000523e <sys_exec+0x88>
    if(i >= NELEM(argv)){
    80005236:	0905                	addi	s2,s2,1
    80005238:	09a1                	addi	s3,s3,8
    8000523a:	fd4913e3          	bne	s2,s4,80005200 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000523e:	f5040913          	addi	s2,s0,-176
    80005242:	6088                	ld	a0,0(s1)
    80005244:	c931                	beqz	a0,80005298 <sys_exec+0xe2>
    kfree(argv[i]);
    80005246:	809fb0ef          	jal	80000a4e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000524a:	04a1                	addi	s1,s1,8
    8000524c:	ff249be3          	bne	s1,s2,80005242 <sys_exec+0x8c>
  return -1;
    80005250:	557d                	li	a0,-1
    80005252:	74ba                	ld	s1,424(sp)
    80005254:	791a                	ld	s2,416(sp)
    80005256:	69fa                	ld	s3,408(sp)
    80005258:	6a5a                	ld	s4,400(sp)
    8000525a:	a0a1                	j	800052a2 <sys_exec+0xec>
      argv[i] = 0;
    8000525c:	0009079b          	sext.w	a5,s2
    80005260:	078e                	slli	a5,a5,0x3
    80005262:	fd078793          	addi	a5,a5,-48
    80005266:	97a2                	add	a5,a5,s0
    80005268:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    8000526c:	e5040593          	addi	a1,s0,-432
    80005270:	f5040513          	addi	a0,s0,-176
    80005274:	ba8ff0ef          	jal	8000461c <kexec>
    80005278:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000527a:	f5040993          	addi	s3,s0,-176
    8000527e:	6088                	ld	a0,0(s1)
    80005280:	c511                	beqz	a0,8000528c <sys_exec+0xd6>
    kfree(argv[i]);
    80005282:	fccfb0ef          	jal	80000a4e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005286:	04a1                	addi	s1,s1,8
    80005288:	ff349be3          	bne	s1,s3,8000527e <sys_exec+0xc8>
  return ret;
    8000528c:	854a                	mv	a0,s2
    8000528e:	74ba                	ld	s1,424(sp)
    80005290:	791a                	ld	s2,416(sp)
    80005292:	69fa                	ld	s3,408(sp)
    80005294:	6a5a                	ld	s4,400(sp)
    80005296:	a031                	j	800052a2 <sys_exec+0xec>
  return -1;
    80005298:	557d                	li	a0,-1
    8000529a:	74ba                	ld	s1,424(sp)
    8000529c:	791a                	ld	s2,416(sp)
    8000529e:	69fa                	ld	s3,408(sp)
    800052a0:	6a5a                	ld	s4,400(sp)
}
    800052a2:	70fa                	ld	ra,440(sp)
    800052a4:	745a                	ld	s0,432(sp)
    800052a6:	6139                	addi	sp,sp,448
    800052a8:	8082                	ret

00000000800052aa <sys_pipe>:

uint64
sys_pipe(void)
{
    800052aa:	7139                	addi	sp,sp,-64
    800052ac:	fc06                	sd	ra,56(sp)
    800052ae:	f822                	sd	s0,48(sp)
    800052b0:	f426                	sd	s1,40(sp)
    800052b2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800052b4:	e50fc0ef          	jal	80001904 <myproc>
    800052b8:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800052ba:	fd840593          	addi	a1,s0,-40
    800052be:	4501                	li	a0,0
    800052c0:	d74fd0ef          	jal	80002834 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800052c4:	fc840593          	addi	a1,s0,-56
    800052c8:	fd040513          	addi	a0,s0,-48
    800052cc:	852ff0ef          	jal	8000431e <pipealloc>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800052d2:	0a054463          	bltz	a0,8000537a <sys_pipe+0xd0>
  fd0 = -1;
    800052d6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800052da:	fd043503          	ld	a0,-48(s0)
    800052de:	f08ff0ef          	jal	800049e6 <fdalloc>
    800052e2:	fca42223          	sw	a0,-60(s0)
    800052e6:	08054163          	bltz	a0,80005368 <sys_pipe+0xbe>
    800052ea:	fc843503          	ld	a0,-56(s0)
    800052ee:	ef8ff0ef          	jal	800049e6 <fdalloc>
    800052f2:	fca42023          	sw	a0,-64(s0)
    800052f6:	06054063          	bltz	a0,80005356 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800052fa:	4691                	li	a3,4
    800052fc:	fc440613          	addi	a2,s0,-60
    80005300:	fd843583          	ld	a1,-40(s0)
    80005304:	68a8                	ld	a0,80(s1)
    80005306:	b12fc0ef          	jal	80001618 <copyout>
    8000530a:	00054e63          	bltz	a0,80005326 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000530e:	4691                	li	a3,4
    80005310:	fc040613          	addi	a2,s0,-64
    80005314:	fd843583          	ld	a1,-40(s0)
    80005318:	0591                	addi	a1,a1,4
    8000531a:	68a8                	ld	a0,80(s1)
    8000531c:	afcfc0ef          	jal	80001618 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005320:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005322:	04055c63          	bgez	a0,8000537a <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005326:	fc442783          	lw	a5,-60(s0)
    8000532a:	07e9                	addi	a5,a5,26
    8000532c:	078e                	slli	a5,a5,0x3
    8000532e:	97a6                	add	a5,a5,s1
    80005330:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005334:	fc042783          	lw	a5,-64(s0)
    80005338:	07e9                	addi	a5,a5,26
    8000533a:	078e                	slli	a5,a5,0x3
    8000533c:	94be                	add	s1,s1,a5
    8000533e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005342:	fd043503          	ld	a0,-48(s0)
    80005346:	ccffe0ef          	jal	80004014 <fileclose>
    fileclose(wf);
    8000534a:	fc843503          	ld	a0,-56(s0)
    8000534e:	cc7fe0ef          	jal	80004014 <fileclose>
    return -1;
    80005352:	57fd                	li	a5,-1
    80005354:	a01d                	j	8000537a <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005356:	fc442783          	lw	a5,-60(s0)
    8000535a:	0007c763          	bltz	a5,80005368 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000535e:	07e9                	addi	a5,a5,26
    80005360:	078e                	slli	a5,a5,0x3
    80005362:	97a6                	add	a5,a5,s1
    80005364:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005368:	fd043503          	ld	a0,-48(s0)
    8000536c:	ca9fe0ef          	jal	80004014 <fileclose>
    fileclose(wf);
    80005370:	fc843503          	ld	a0,-56(s0)
    80005374:	ca1fe0ef          	jal	80004014 <fileclose>
    return -1;
    80005378:	57fd                	li	a5,-1
}
    8000537a:	853e                	mv	a0,a5
    8000537c:	70e2                	ld	ra,56(sp)
    8000537e:	7442                	ld	s0,48(sp)
    80005380:	74a2                	ld	s1,40(sp)
    80005382:	6121                	addi	sp,sp,64
    80005384:	8082                	ret
	...

0000000080005390 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005390:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005392:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005394:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005396:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005398:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000539a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000539c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000539e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800053a0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800053a2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800053a4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800053a6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800053a8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800053aa:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800053ac:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800053ae:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800053b0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800053b2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800053b4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800053b6:	ae8fd0ef          	jal	8000269e <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800053ba:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800053bc:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800053be:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800053c0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800053c2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800053c4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800053c6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800053c8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800053ca:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800053cc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800053ce:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800053d0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800053d2:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    800053d4:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800053d6:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800053d8:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800053da:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    800053dc:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    800053de:	10200073          	sret
	...

00000000800053ee <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800053ee:	1141                	addi	sp,sp,-16
    800053f0:	e422                	sd	s0,8(sp)
    800053f2:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800053f4:	0c0007b7          	lui	a5,0xc000
    800053f8:	4705                	li	a4,1
    800053fa:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800053fc:	0c0007b7          	lui	a5,0xc000
    80005400:	c3d8                	sw	a4,4(a5)
}
    80005402:	6422                	ld	s0,8(sp)
    80005404:	0141                	addi	sp,sp,16
    80005406:	8082                	ret

0000000080005408 <plicinithart>:

void
plicinithart(void)
{
    80005408:	1141                	addi	sp,sp,-16
    8000540a:	e406                	sd	ra,8(sp)
    8000540c:	e022                	sd	s0,0(sp)
    8000540e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005410:	cc8fc0ef          	jal	800018d8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005414:	0085171b          	slliw	a4,a0,0x8
    80005418:	0c0027b7          	lui	a5,0xc002
    8000541c:	97ba                	add	a5,a5,a4
    8000541e:	40200713          	li	a4,1026
    80005422:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005426:	00d5151b          	slliw	a0,a0,0xd
    8000542a:	0c2017b7          	lui	a5,0xc201
    8000542e:	97aa                	add	a5,a5,a0
    80005430:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005434:	60a2                	ld	ra,8(sp)
    80005436:	6402                	ld	s0,0(sp)
    80005438:	0141                	addi	sp,sp,16
    8000543a:	8082                	ret

000000008000543c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000543c:	1141                	addi	sp,sp,-16
    8000543e:	e406                	sd	ra,8(sp)
    80005440:	e022                	sd	s0,0(sp)
    80005442:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005444:	c94fc0ef          	jal	800018d8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005448:	00d5151b          	slliw	a0,a0,0xd
    8000544c:	0c2017b7          	lui	a5,0xc201
    80005450:	97aa                	add	a5,a5,a0
  return irq;
}
    80005452:	43c8                	lw	a0,4(a5)
    80005454:	60a2                	ld	ra,8(sp)
    80005456:	6402                	ld	s0,0(sp)
    80005458:	0141                	addi	sp,sp,16
    8000545a:	8082                	ret

000000008000545c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000545c:	1101                	addi	sp,sp,-32
    8000545e:	ec06                	sd	ra,24(sp)
    80005460:	e822                	sd	s0,16(sp)
    80005462:	e426                	sd	s1,8(sp)
    80005464:	1000                	addi	s0,sp,32
    80005466:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005468:	c70fc0ef          	jal	800018d8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000546c:	00d5151b          	slliw	a0,a0,0xd
    80005470:	0c2017b7          	lui	a5,0xc201
    80005474:	97aa                	add	a5,a5,a0
    80005476:	c3c4                	sw	s1,4(a5)
}
    80005478:	60e2                	ld	ra,24(sp)
    8000547a:	6442                	ld	s0,16(sp)
    8000547c:	64a2                	ld	s1,8(sp)
    8000547e:	6105                	addi	sp,sp,32
    80005480:	8082                	ret

0000000080005482 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005482:	1141                	addi	sp,sp,-16
    80005484:	e406                	sd	ra,8(sp)
    80005486:	e022                	sd	s0,0(sp)
    80005488:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000548a:	479d                	li	a5,7
    8000548c:	04a7ca63          	blt	a5,a0,800054e0 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005490:	0001b797          	auipc	a5,0x1b
    80005494:	60878793          	addi	a5,a5,1544 # 80020a98 <disk>
    80005498:	97aa                	add	a5,a5,a0
    8000549a:	0187c783          	lbu	a5,24(a5)
    8000549e:	e7b9                	bnez	a5,800054ec <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800054a0:	00451693          	slli	a3,a0,0x4
    800054a4:	0001b797          	auipc	a5,0x1b
    800054a8:	5f478793          	addi	a5,a5,1524 # 80020a98 <disk>
    800054ac:	6398                	ld	a4,0(a5)
    800054ae:	9736                	add	a4,a4,a3
    800054b0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800054b4:	6398                	ld	a4,0(a5)
    800054b6:	9736                	add	a4,a4,a3
    800054b8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800054bc:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800054c0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800054c4:	97aa                	add	a5,a5,a0
    800054c6:	4705                	li	a4,1
    800054c8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800054cc:	0001b517          	auipc	a0,0x1b
    800054d0:	5e450513          	addi	a0,a0,1508 # 80020ab0 <disk+0x18>
    800054d4:	a8dfc0ef          	jal	80001f60 <wakeup>
}
    800054d8:	60a2                	ld	ra,8(sp)
    800054da:	6402                	ld	s0,0(sp)
    800054dc:	0141                	addi	sp,sp,16
    800054de:	8082                	ret
    panic("free_desc 1");
    800054e0:	00002517          	auipc	a0,0x2
    800054e4:	13850513          	addi	a0,a0,312 # 80007618 <etext+0x618>
    800054e8:	b2afb0ef          	jal	80000812 <panic>
    panic("free_desc 2");
    800054ec:	00002517          	auipc	a0,0x2
    800054f0:	13c50513          	addi	a0,a0,316 # 80007628 <etext+0x628>
    800054f4:	b1efb0ef          	jal	80000812 <panic>

00000000800054f8 <virtio_disk_init>:
{
    800054f8:	1101                	addi	sp,sp,-32
    800054fa:	ec06                	sd	ra,24(sp)
    800054fc:	e822                	sd	s0,16(sp)
    800054fe:	e426                	sd	s1,8(sp)
    80005500:	e04a                	sd	s2,0(sp)
    80005502:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005504:	00002597          	auipc	a1,0x2
    80005508:	13458593          	addi	a1,a1,308 # 80007638 <etext+0x638>
    8000550c:	0001b517          	auipc	a0,0x1b
    80005510:	6b450513          	addi	a0,a0,1716 # 80020bc0 <disk+0x128>
    80005514:	e6cfb0ef          	jal	80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005518:	100017b7          	lui	a5,0x10001
    8000551c:	4398                	lw	a4,0(a5)
    8000551e:	2701                	sext.w	a4,a4
    80005520:	747277b7          	lui	a5,0x74727
    80005524:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005528:	18f71063          	bne	a4,a5,800056a8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000552c:	100017b7          	lui	a5,0x10001
    80005530:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005532:	439c                	lw	a5,0(a5)
    80005534:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005536:	4709                	li	a4,2
    80005538:	16e79863          	bne	a5,a4,800056a8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000553c:	100017b7          	lui	a5,0x10001
    80005540:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005542:	439c                	lw	a5,0(a5)
    80005544:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005546:	16e79163          	bne	a5,a4,800056a8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000554a:	100017b7          	lui	a5,0x10001
    8000554e:	47d8                	lw	a4,12(a5)
    80005550:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005552:	554d47b7          	lui	a5,0x554d4
    80005556:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000555a:	14f71763          	bne	a4,a5,800056a8 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000555e:	100017b7          	lui	a5,0x10001
    80005562:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005566:	4705                	li	a4,1
    80005568:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000556a:	470d                	li	a4,3
    8000556c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000556e:	10001737          	lui	a4,0x10001
    80005572:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005574:	c7ffe737          	lui	a4,0xc7ffe
    80005578:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd5b57>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000557c:	8ef9                	and	a3,a3,a4
    8000557e:	10001737          	lui	a4,0x10001
    80005582:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005584:	472d                	li	a4,11
    80005586:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005588:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    8000558c:	439c                	lw	a5,0(a5)
    8000558e:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005592:	8ba1                	andi	a5,a5,8
    80005594:	12078063          	beqz	a5,800056b4 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005598:	100017b7          	lui	a5,0x10001
    8000559c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800055a0:	100017b7          	lui	a5,0x10001
    800055a4:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800055a8:	439c                	lw	a5,0(a5)
    800055aa:	2781                	sext.w	a5,a5
    800055ac:	10079a63          	bnez	a5,800056c0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800055b0:	100017b7          	lui	a5,0x10001
    800055b4:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800055b8:	439c                	lw	a5,0(a5)
    800055ba:	2781                	sext.w	a5,a5
  if(max == 0)
    800055bc:	10078863          	beqz	a5,800056cc <virtio_disk_init+0x1d4>
  if(max < NUM)
    800055c0:	471d                	li	a4,7
    800055c2:	10f77b63          	bgeu	a4,a5,800056d8 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800055c6:	d6afb0ef          	jal	80000b30 <kalloc>
    800055ca:	0001b497          	auipc	s1,0x1b
    800055ce:	4ce48493          	addi	s1,s1,1230 # 80020a98 <disk>
    800055d2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800055d4:	d5cfb0ef          	jal	80000b30 <kalloc>
    800055d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800055da:	d56fb0ef          	jal	80000b30 <kalloc>
    800055de:	87aa                	mv	a5,a0
    800055e0:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800055e2:	6088                	ld	a0,0(s1)
    800055e4:	10050063          	beqz	a0,800056e4 <virtio_disk_init+0x1ec>
    800055e8:	0001b717          	auipc	a4,0x1b
    800055ec:	4b873703          	ld	a4,1208(a4) # 80020aa0 <disk+0x8>
    800055f0:	0e070a63          	beqz	a4,800056e4 <virtio_disk_init+0x1ec>
    800055f4:	0e078863          	beqz	a5,800056e4 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    800055f8:	6605                	lui	a2,0x1
    800055fa:	4581                	li	a1,0
    800055fc:	ed8fb0ef          	jal	80000cd4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005600:	0001b497          	auipc	s1,0x1b
    80005604:	49848493          	addi	s1,s1,1176 # 80020a98 <disk>
    80005608:	6605                	lui	a2,0x1
    8000560a:	4581                	li	a1,0
    8000560c:	6488                	ld	a0,8(s1)
    8000560e:	ec6fb0ef          	jal	80000cd4 <memset>
  memset(disk.used, 0, PGSIZE);
    80005612:	6605                	lui	a2,0x1
    80005614:	4581                	li	a1,0
    80005616:	6888                	ld	a0,16(s1)
    80005618:	ebcfb0ef          	jal	80000cd4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000561c:	100017b7          	lui	a5,0x10001
    80005620:	4721                	li	a4,8
    80005622:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005624:	4098                	lw	a4,0(s1)
    80005626:	100017b7          	lui	a5,0x10001
    8000562a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000562e:	40d8                	lw	a4,4(s1)
    80005630:	100017b7          	lui	a5,0x10001
    80005634:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005638:	649c                	ld	a5,8(s1)
    8000563a:	0007869b          	sext.w	a3,a5
    8000563e:	10001737          	lui	a4,0x10001
    80005642:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005646:	9781                	srai	a5,a5,0x20
    80005648:	10001737          	lui	a4,0x10001
    8000564c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005650:	689c                	ld	a5,16(s1)
    80005652:	0007869b          	sext.w	a3,a5
    80005656:	10001737          	lui	a4,0x10001
    8000565a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000565e:	9781                	srai	a5,a5,0x20
    80005660:	10001737          	lui	a4,0x10001
    80005664:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005668:	10001737          	lui	a4,0x10001
    8000566c:	4785                	li	a5,1
    8000566e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80005670:	00f48c23          	sb	a5,24(s1)
    80005674:	00f48ca3          	sb	a5,25(s1)
    80005678:	00f48d23          	sb	a5,26(s1)
    8000567c:	00f48da3          	sb	a5,27(s1)
    80005680:	00f48e23          	sb	a5,28(s1)
    80005684:	00f48ea3          	sb	a5,29(s1)
    80005688:	00f48f23          	sb	a5,30(s1)
    8000568c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005690:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005694:	100017b7          	lui	a5,0x10001
    80005698:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    8000569c:	60e2                	ld	ra,24(sp)
    8000569e:	6442                	ld	s0,16(sp)
    800056a0:	64a2                	ld	s1,8(sp)
    800056a2:	6902                	ld	s2,0(sp)
    800056a4:	6105                	addi	sp,sp,32
    800056a6:	8082                	ret
    panic("could not find virtio disk");
    800056a8:	00002517          	auipc	a0,0x2
    800056ac:	fa050513          	addi	a0,a0,-96 # 80007648 <etext+0x648>
    800056b0:	962fb0ef          	jal	80000812 <panic>
    panic("virtio disk FEATURES_OK unset");
    800056b4:	00002517          	auipc	a0,0x2
    800056b8:	fb450513          	addi	a0,a0,-76 # 80007668 <etext+0x668>
    800056bc:	956fb0ef          	jal	80000812 <panic>
    panic("virtio disk should not be ready");
    800056c0:	00002517          	auipc	a0,0x2
    800056c4:	fc850513          	addi	a0,a0,-56 # 80007688 <etext+0x688>
    800056c8:	94afb0ef          	jal	80000812 <panic>
    panic("virtio disk has no queue 0");
    800056cc:	00002517          	auipc	a0,0x2
    800056d0:	fdc50513          	addi	a0,a0,-36 # 800076a8 <etext+0x6a8>
    800056d4:	93efb0ef          	jal	80000812 <panic>
    panic("virtio disk max queue too short");
    800056d8:	00002517          	auipc	a0,0x2
    800056dc:	ff050513          	addi	a0,a0,-16 # 800076c8 <etext+0x6c8>
    800056e0:	932fb0ef          	jal	80000812 <panic>
    panic("virtio disk kalloc");
    800056e4:	00002517          	auipc	a0,0x2
    800056e8:	00450513          	addi	a0,a0,4 # 800076e8 <etext+0x6e8>
    800056ec:	926fb0ef          	jal	80000812 <panic>

00000000800056f0 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800056f0:	7159                	addi	sp,sp,-112
    800056f2:	f486                	sd	ra,104(sp)
    800056f4:	f0a2                	sd	s0,96(sp)
    800056f6:	eca6                	sd	s1,88(sp)
    800056f8:	e8ca                	sd	s2,80(sp)
    800056fa:	e4ce                	sd	s3,72(sp)
    800056fc:	e0d2                	sd	s4,64(sp)
    800056fe:	fc56                	sd	s5,56(sp)
    80005700:	f85a                	sd	s6,48(sp)
    80005702:	f45e                	sd	s7,40(sp)
    80005704:	f062                	sd	s8,32(sp)
    80005706:	ec66                	sd	s9,24(sp)
    80005708:	1880                	addi	s0,sp,112
    8000570a:	8a2a                	mv	s4,a0
    8000570c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000570e:	00c52c83          	lw	s9,12(a0)
    80005712:	001c9c9b          	slliw	s9,s9,0x1
    80005716:	1c82                	slli	s9,s9,0x20
    80005718:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000571c:	0001b517          	auipc	a0,0x1b
    80005720:	4a450513          	addi	a0,a0,1188 # 80020bc0 <disk+0x128>
    80005724:	cdcfb0ef          	jal	80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80005728:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000572a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000572c:	0001bb17          	auipc	s6,0x1b
    80005730:	36cb0b13          	addi	s6,s6,876 # 80020a98 <disk>
  for(int i = 0; i < 3; i++){
    80005734:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005736:	0001bc17          	auipc	s8,0x1b
    8000573a:	48ac0c13          	addi	s8,s8,1162 # 80020bc0 <disk+0x128>
    8000573e:	a8b9                	j	8000579c <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005740:	00fb0733          	add	a4,s6,a5
    80005744:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005748:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000574a:	0207c563          	bltz	a5,80005774 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    8000574e:	2905                	addiw	s2,s2,1
    80005750:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005752:	05590963          	beq	s2,s5,800057a4 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005756:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005758:	0001b717          	auipc	a4,0x1b
    8000575c:	34070713          	addi	a4,a4,832 # 80020a98 <disk>
    80005760:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005762:	01874683          	lbu	a3,24(a4)
    80005766:	fee9                	bnez	a3,80005740 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005768:	2785                	addiw	a5,a5,1
    8000576a:	0705                	addi	a4,a4,1
    8000576c:	fe979be3          	bne	a5,s1,80005762 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005770:	57fd                	li	a5,-1
    80005772:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005774:	01205d63          	blez	s2,8000578e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005778:	f9042503          	lw	a0,-112(s0)
    8000577c:	d07ff0ef          	jal	80005482 <free_desc>
      for(int j = 0; j < i; j++)
    80005780:	4785                	li	a5,1
    80005782:	0127d663          	bge	a5,s2,8000578e <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005786:	f9442503          	lw	a0,-108(s0)
    8000578a:	cf9ff0ef          	jal	80005482 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000578e:	85e2                	mv	a1,s8
    80005790:	0001b517          	auipc	a0,0x1b
    80005794:	32050513          	addi	a0,a0,800 # 80020ab0 <disk+0x18>
    80005798:	f7cfc0ef          	jal	80001f14 <sleep>
  for(int i = 0; i < 3; i++){
    8000579c:	f9040613          	addi	a2,s0,-112
    800057a0:	894e                	mv	s2,s3
    800057a2:	bf55                	j	80005756 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800057a4:	f9042503          	lw	a0,-112(s0)
    800057a8:	00451693          	slli	a3,a0,0x4

  if(write)
    800057ac:	0001b797          	auipc	a5,0x1b
    800057b0:	2ec78793          	addi	a5,a5,748 # 80020a98 <disk>
    800057b4:	00a50713          	addi	a4,a0,10
    800057b8:	0712                	slli	a4,a4,0x4
    800057ba:	973e                	add	a4,a4,a5
    800057bc:	01703633          	snez	a2,s7
    800057c0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800057c2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800057c6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800057ca:	6398                	ld	a4,0(a5)
    800057cc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800057ce:	0a868613          	addi	a2,a3,168
    800057d2:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800057d4:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800057d6:	6390                	ld	a2,0(a5)
    800057d8:	00d605b3          	add	a1,a2,a3
    800057dc:	4741                	li	a4,16
    800057de:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800057e0:	4805                	li	a6,1
    800057e2:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    800057e6:	f9442703          	lw	a4,-108(s0)
    800057ea:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800057ee:	0712                	slli	a4,a4,0x4
    800057f0:	963a                	add	a2,a2,a4
    800057f2:	058a0593          	addi	a1,s4,88
    800057f6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800057f8:	0007b883          	ld	a7,0(a5)
    800057fc:	9746                	add	a4,a4,a7
    800057fe:	40000613          	li	a2,1024
    80005802:	c710                	sw	a2,8(a4)
  if(write)
    80005804:	001bb613          	seqz	a2,s7
    80005808:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000580c:	00166613          	ori	a2,a2,1
    80005810:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005814:	f9842583          	lw	a1,-104(s0)
    80005818:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000581c:	00250613          	addi	a2,a0,2
    80005820:	0612                	slli	a2,a2,0x4
    80005822:	963e                	add	a2,a2,a5
    80005824:	577d                	li	a4,-1
    80005826:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000582a:	0592                	slli	a1,a1,0x4
    8000582c:	98ae                	add	a7,a7,a1
    8000582e:	03068713          	addi	a4,a3,48
    80005832:	973e                	add	a4,a4,a5
    80005834:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005838:	6398                	ld	a4,0(a5)
    8000583a:	972e                	add	a4,a4,a1
    8000583c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005840:	4689                	li	a3,2
    80005842:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005846:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000584a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    8000584e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005852:	6794                	ld	a3,8(a5)
    80005854:	0026d703          	lhu	a4,2(a3)
    80005858:	8b1d                	andi	a4,a4,7
    8000585a:	0706                	slli	a4,a4,0x1
    8000585c:	96ba                	add	a3,a3,a4
    8000585e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005862:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005866:	6798                	ld	a4,8(a5)
    80005868:	00275783          	lhu	a5,2(a4)
    8000586c:	2785                	addiw	a5,a5,1
    8000586e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005872:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005876:	100017b7          	lui	a5,0x10001
    8000587a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000587e:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005882:	0001b917          	auipc	s2,0x1b
    80005886:	33e90913          	addi	s2,s2,830 # 80020bc0 <disk+0x128>
  while(b->disk == 1) {
    8000588a:	4485                	li	s1,1
    8000588c:	01079a63          	bne	a5,a6,800058a0 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005890:	85ca                	mv	a1,s2
    80005892:	8552                	mv	a0,s4
    80005894:	e80fc0ef          	jal	80001f14 <sleep>
  while(b->disk == 1) {
    80005898:	004a2783          	lw	a5,4(s4)
    8000589c:	fe978ae3          	beq	a5,s1,80005890 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    800058a0:	f9042903          	lw	s2,-112(s0)
    800058a4:	00290713          	addi	a4,s2,2
    800058a8:	0712                	slli	a4,a4,0x4
    800058aa:	0001b797          	auipc	a5,0x1b
    800058ae:	1ee78793          	addi	a5,a5,494 # 80020a98 <disk>
    800058b2:	97ba                	add	a5,a5,a4
    800058b4:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800058b8:	0001b997          	auipc	s3,0x1b
    800058bc:	1e098993          	addi	s3,s3,480 # 80020a98 <disk>
    800058c0:	00491713          	slli	a4,s2,0x4
    800058c4:	0009b783          	ld	a5,0(s3)
    800058c8:	97ba                	add	a5,a5,a4
    800058ca:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800058ce:	854a                	mv	a0,s2
    800058d0:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800058d4:	bafff0ef          	jal	80005482 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800058d8:	8885                	andi	s1,s1,1
    800058da:	f0fd                	bnez	s1,800058c0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800058dc:	0001b517          	auipc	a0,0x1b
    800058e0:	2e450513          	addi	a0,a0,740 # 80020bc0 <disk+0x128>
    800058e4:	bb4fb0ef          	jal	80000c98 <release>
}
    800058e8:	70a6                	ld	ra,104(sp)
    800058ea:	7406                	ld	s0,96(sp)
    800058ec:	64e6                	ld	s1,88(sp)
    800058ee:	6946                	ld	s2,80(sp)
    800058f0:	69a6                	ld	s3,72(sp)
    800058f2:	6a06                	ld	s4,64(sp)
    800058f4:	7ae2                	ld	s5,56(sp)
    800058f6:	7b42                	ld	s6,48(sp)
    800058f8:	7ba2                	ld	s7,40(sp)
    800058fa:	7c02                	ld	s8,32(sp)
    800058fc:	6ce2                	ld	s9,24(sp)
    800058fe:	6165                	addi	sp,sp,112
    80005900:	8082                	ret

0000000080005902 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005902:	1101                	addi	sp,sp,-32
    80005904:	ec06                	sd	ra,24(sp)
    80005906:	e822                	sd	s0,16(sp)
    80005908:	e426                	sd	s1,8(sp)
    8000590a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000590c:	0001b497          	auipc	s1,0x1b
    80005910:	18c48493          	addi	s1,s1,396 # 80020a98 <disk>
    80005914:	0001b517          	auipc	a0,0x1b
    80005918:	2ac50513          	addi	a0,a0,684 # 80020bc0 <disk+0x128>
    8000591c:	ae4fb0ef          	jal	80000c00 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005920:	100017b7          	lui	a5,0x10001
    80005924:	53b8                	lw	a4,96(a5)
    80005926:	8b0d                	andi	a4,a4,3
    80005928:	100017b7          	lui	a5,0x10001
    8000592c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    8000592e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005932:	689c                	ld	a5,16(s1)
    80005934:	0204d703          	lhu	a4,32(s1)
    80005938:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    8000593c:	04f70663          	beq	a4,a5,80005988 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005940:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005944:	6898                	ld	a4,16(s1)
    80005946:	0204d783          	lhu	a5,32(s1)
    8000594a:	8b9d                	andi	a5,a5,7
    8000594c:	078e                	slli	a5,a5,0x3
    8000594e:	97ba                	add	a5,a5,a4
    80005950:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005952:	00278713          	addi	a4,a5,2
    80005956:	0712                	slli	a4,a4,0x4
    80005958:	9726                	add	a4,a4,s1
    8000595a:	01074703          	lbu	a4,16(a4)
    8000595e:	e321                	bnez	a4,8000599e <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005960:	0789                	addi	a5,a5,2
    80005962:	0792                	slli	a5,a5,0x4
    80005964:	97a6                	add	a5,a5,s1
    80005966:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005968:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000596c:	df4fc0ef          	jal	80001f60 <wakeup>

    disk.used_idx += 1;
    80005970:	0204d783          	lhu	a5,32(s1)
    80005974:	2785                	addiw	a5,a5,1
    80005976:	17c2                	slli	a5,a5,0x30
    80005978:	93c1                	srli	a5,a5,0x30
    8000597a:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000597e:	6898                	ld	a4,16(s1)
    80005980:	00275703          	lhu	a4,2(a4)
    80005984:	faf71ee3          	bne	a4,a5,80005940 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005988:	0001b517          	auipc	a0,0x1b
    8000598c:	23850513          	addi	a0,a0,568 # 80020bc0 <disk+0x128>
    80005990:	b08fb0ef          	jal	80000c98 <release>
}
    80005994:	60e2                	ld	ra,24(sp)
    80005996:	6442                	ld	s0,16(sp)
    80005998:	64a2                	ld	s1,8(sp)
    8000599a:	6105                	addi	sp,sp,32
    8000599c:	8082                	ret
      panic("virtio_disk_intr status");
    8000599e:	00002517          	auipc	a0,0x2
    800059a2:	d6250513          	addi	a0,a0,-670 # 80007700 <etext+0x700>
    800059a6:	e6dfa0ef          	jal	80000812 <panic>

00000000800059aa <cslog_init>:
  safestrcpy(e->name, p->name, CS_NM);
}

void
cslog_init(void)
{
    800059aa:	1141                	addi	sp,sp,-16
    800059ac:	e406                	sd	ra,8(sp)
    800059ae:	e022                	sd	s0,0(sp)
    800059b0:	0800                	addi	s0,sp,16
  ringbuf_init(&cs_rb, "cslog", sizeof(struct cs_event));
    800059b2:	03000613          	li	a2,48
    800059b6:	00002597          	auipc	a1,0x2
    800059ba:	d6258593          	addi	a1,a1,-670 # 80007718 <etext+0x718>
    800059be:	0001b517          	auipc	a0,0x1b
    800059c2:	21a50513          	addi	a0,a0,538 # 80020bd8 <cs_rb>
    800059c6:	1b2000ef          	jal	80005b78 <ringbuf_init>
}
    800059ca:	60a2                	ld	ra,8(sp)
    800059cc:	6402                	ld	s0,0(sp)
    800059ce:	0141                	addi	sp,sp,16
    800059d0:	8082                	ret

00000000800059d2 <cslog_push>:

void
cslog_push(struct cs_event *e)
{
    800059d2:	1141                	addi	sp,sp,-16
    800059d4:	e406                	sd	ra,8(sp)
    800059d6:	e022                	sd	s0,0(sp)
    800059d8:	0800                	addi	s0,sp,16
    800059da:	85aa                	mv	a1,a0
  e->seq = ++cs_seq;
    800059dc:	00002717          	auipc	a4,0x2
    800059e0:	eb470713          	addi	a4,a4,-332 # 80007890 <cs_seq>
    800059e4:	631c                	ld	a5,0(a4)
    800059e6:	0785                	addi	a5,a5,1
    800059e8:	e31c                	sd	a5,0(a4)
    800059ea:	e11c                	sd	a5,0(a0)
  ringbuf_push(&cs_rb, e);
    800059ec:	0001b517          	auipc	a0,0x1b
    800059f0:	1ec50513          	addi	a0,a0,492 # 80020bd8 <cs_rb>
    800059f4:	1b8000ef          	jal	80005bac <ringbuf_push>
}
    800059f8:	60a2                	ld	ra,8(sp)
    800059fa:	6402                	ld	s0,0(sp)
    800059fc:	0141                	addi	sp,sp,16
    800059fe:	8082                	ret

0000000080005a00 <cslog_read_many>:

int
cslog_read_many(struct cs_event *out, int max)
{
    80005a00:	1141                	addi	sp,sp,-16
    80005a02:	e406                	sd	ra,8(sp)
    80005a04:	e022                	sd	s0,0(sp)
    80005a06:	0800                	addi	s0,sp,16
    80005a08:	862e                	mv	a2,a1
  return ringbuf_read_many(&cs_rb, out, max);
    80005a0a:	85aa                	mv	a1,a0
    80005a0c:	0001b517          	auipc	a0,0x1b
    80005a10:	1cc50513          	addi	a0,a0,460 # 80020bd8 <cs_rb>
    80005a14:	204000ef          	jal	80005c18 <ringbuf_read_many>
}
    80005a18:	60a2                	ld	ra,8(sp)
    80005a1a:	6402                	ld	s0,0(sp)
    80005a1c:	0141                	addi	sp,sp,16
    80005a1e:	8082                	ret

0000000080005a20 <cslog_run_start>:

void
cslog_run_start(struct proc *p)
{
  if(p == 0) return;
    80005a20:	c14d                	beqz	a0,80005ac2 <cslog_run_start+0xa2>
{
    80005a22:	715d                	addi	sp,sp,-80
    80005a24:	e486                	sd	ra,72(sp)
    80005a26:	e0a2                	sd	s0,64(sp)
    80005a28:	fc26                	sd	s1,56(sp)
    80005a2a:	0880                	addi	s0,sp,80
    80005a2c:	84aa                	mv	s1,a0
  if(p->pid <= 0) return;
    80005a2e:	591c                	lw	a5,48(a0)
    80005a30:	00f05563          	blez	a5,80005a3a <cslog_run_start+0x1a>
  if(p->name[0] == 0) return;
    80005a34:	15854783          	lbu	a5,344(a0)
    80005a38:	e791                	bnez	a5,80005a44 <cslog_run_start+0x24>

  struct cs_event e;
  fill_from_proc(&e, p);
  e.type = CS_RUN_START;
  cslog_push(&e);
    80005a3a:	60a6                	ld	ra,72(sp)
    80005a3c:	6406                	ld	s0,64(sp)
    80005a3e:	74e2                	ld	s1,56(sp)
    80005a40:	6161                	addi	sp,sp,80
    80005a42:	8082                	ret
    80005a44:	f84a                	sd	s2,48(sp)
  if(strncmp(p->name, "cscat", 5) == 0) return;
    80005a46:	15850913          	addi	s2,a0,344
    80005a4a:	4615                	li	a2,5
    80005a4c:	00002597          	auipc	a1,0x2
    80005a50:	cd458593          	addi	a1,a1,-812 # 80007720 <etext+0x720>
    80005a54:	854a                	mv	a0,s2
    80005a56:	b4afb0ef          	jal	80000da0 <strncmp>
    80005a5a:	e119                	bnez	a0,80005a60 <cslog_run_start+0x40>
    80005a5c:	7942                	ld	s2,48(sp)
    80005a5e:	bff1                	j	80005a3a <cslog_run_start+0x1a>
  if(strncmp(p->name, "csexport", 8) == 0) return;
    80005a60:	4621                	li	a2,8
    80005a62:	00002597          	auipc	a1,0x2
    80005a66:	cc658593          	addi	a1,a1,-826 # 80007728 <etext+0x728>
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	b34fb0ef          	jal	80000da0 <strncmp>
    80005a70:	e119                	bnez	a0,80005a76 <cslog_run_start+0x56>
    80005a72:	7942                	ld	s2,48(sp)
    80005a74:	b7d9                	j	80005a3a <cslog_run_start+0x1a>
  memset(e, 0, sizeof(*e));
    80005a76:	03000613          	li	a2,48
    80005a7a:	4581                	li	a1,0
    80005a7c:	fb040513          	addi	a0,s0,-80
    80005a80:	a54fb0ef          	jal	80000cd4 <memset>
  e->ticks = ticks;
    80005a84:	00002797          	auipc	a5,0x2
    80005a88:	e047a783          	lw	a5,-508(a5) # 80007888 <ticks>
    80005a8c:	faf42c23          	sw	a5,-72(s0)
  e->cpu   = cpuid();
    80005a90:	e49fb0ef          	jal	800018d8 <cpuid>
    80005a94:	faa42e23          	sw	a0,-68(s0)
  e->pid   = p->pid;
    80005a98:	589c                	lw	a5,48(s1)
    80005a9a:	fcf42223          	sw	a5,-60(s0)
  e->state = p->state;
    80005a9e:	4c9c                	lw	a5,24(s1)
    80005aa0:	fcf42423          	sw	a5,-56(s0)
  safestrcpy(e->name, p->name, CS_NM);
    80005aa4:	4641                	li	a2,16
    80005aa6:	85ca                	mv	a1,s2
    80005aa8:	fcc40513          	addi	a0,s0,-52
    80005aac:	b66fb0ef          	jal	80000e12 <safestrcpy>
  e.type = CS_RUN_START;
    80005ab0:	4785                	li	a5,1
    80005ab2:	fcf42023          	sw	a5,-64(s0)
  cslog_push(&e);
    80005ab6:	fb040513          	addi	a0,s0,-80
    80005aba:	f19ff0ef          	jal	800059d2 <cslog_push>
    80005abe:	7942                	ld	s2,48(sp)
    80005ac0:	bfad                	j	80005a3a <cslog_run_start+0x1a>
    80005ac2:	8082                	ret

0000000080005ac4 <sys_csread>:
#include "cslog.h"


uint64
sys_csread(void)
{
    80005ac4:	81010113          	addi	sp,sp,-2032
    80005ac8:	7e113423          	sd	ra,2024(sp)
    80005acc:	7e813023          	sd	s0,2016(sp)
    80005ad0:	7c913c23          	sd	s1,2008(sp)
    80005ad4:	7d213823          	sd	s2,2000(sp)
    80005ad8:	7f010413          	addi	s0,sp,2032
    80005adc:	bb010113          	addi	sp,sp,-1104
  uint64 uaddr = 0;
    80005ae0:	fc043c23          	sd	zero,-40(s0)
  int max = 0;
    80005ae4:	fc042a23          	sw	zero,-44(s0)

  // ✅ عندك argaddr/argint void، فبنستدعيهم بدون if
  argaddr(0, &uaddr);
    80005ae8:	fd840593          	addi	a1,s0,-40
    80005aec:	4501                	li	a0,0
    80005aee:	d47fc0ef          	jal	80002834 <argaddr>
  argint(1, &max);
    80005af2:	fd440593          	addi	a1,s0,-44
    80005af6:	4505                	li	a0,1
    80005af8:	d21fc0ef          	jal	80002818 <argint>

  if(max <= 0) return 0;
    80005afc:	fd442783          	lw	a5,-44(s0)
    80005b00:	4501                	li	a0,0
    80005b02:	04f05c63          	blez	a5,80005b5a <sys_csread+0x96>
  if(max > 64) max = 64;
    80005b06:	04000713          	li	a4,64
    80005b0a:	00f75663          	bge	a4,a5,80005b16 <sys_csread+0x52>
    80005b0e:	04000793          	li	a5,64
    80005b12:	fcf42a23          	sw	a5,-44(s0)

  struct cs_event tmp[64];
  int n = cslog_read_many(tmp, max);
    80005b16:	77fd                	lui	a5,0xfffff
    80005b18:	3d078793          	addi	a5,a5,976 # fffffffffffff3d0 <end+0xffffffff7ffd67c8>
    80005b1c:	97a2                	add	a5,a5,s0
    80005b1e:	797d                	lui	s2,0xfffff
    80005b20:	3c890713          	addi	a4,s2,968 # fffffffffffff3c8 <end+0xffffffff7ffd67c0>
    80005b24:	9722                	add	a4,a4,s0
    80005b26:	e31c                	sd	a5,0(a4)
    80005b28:	fd442583          	lw	a1,-44(s0)
    80005b2c:	6308                	ld	a0,0(a4)
    80005b2e:	ed3ff0ef          	jal	80005a00 <cslog_read_many>
    80005b32:	84aa                	mv	s1,a0

  int bytes = n * (int)sizeof(struct cs_event);
  if(copyout(myproc()->pagetable, uaddr, (char*)tmp, bytes) < 0)
    80005b34:	dd1fb0ef          	jal	80001904 <myproc>
  int bytes = n * (int)sizeof(struct cs_event);
    80005b38:	0014969b          	slliw	a3,s1,0x1
    80005b3c:	9ea5                	addw	a3,a3,s1
  if(copyout(myproc()->pagetable, uaddr, (char*)tmp, bytes) < 0)
    80005b3e:	0046969b          	slliw	a3,a3,0x4
    80005b42:	3c890793          	addi	a5,s2,968
    80005b46:	97a2                	add	a5,a5,s0
    80005b48:	6390                	ld	a2,0(a5)
    80005b4a:	fd843583          	ld	a1,-40(s0)
    80005b4e:	6928                	ld	a0,80(a0)
    80005b50:	ac9fb0ef          	jal	80001618 <copyout>
    80005b54:	02054063          	bltz	a0,80005b74 <sys_csread+0xb0>
    return -1;

  return n;
    80005b58:	8526                	mv	a0,s1
}
    80005b5a:	45010113          	addi	sp,sp,1104
    80005b5e:	7e813083          	ld	ra,2024(sp)
    80005b62:	7e013403          	ld	s0,2016(sp)
    80005b66:	7d813483          	ld	s1,2008(sp)
    80005b6a:	7d013903          	ld	s2,2000(sp)
    80005b6e:	7f010113          	addi	sp,sp,2032
    80005b72:	8082                	ret
    return -1;
    80005b74:	557d                	li	a0,-1
    80005b76:	b7d5                	j	80005b5a <sys_csread+0x96>

0000000080005b78 <ringbuf_init>:
  return (void *)(rb->buf + idx * rb->elem_size);
}

void
ringbuf_init(struct ringbuf *rb, char *name, uint elem_size)
{
    80005b78:	1101                	addi	sp,sp,-32
    80005b7a:	ec06                	sd	ra,24(sp)
    80005b7c:	e822                	sd	s0,16(sp)
    80005b7e:	e426                	sd	s1,8(sp)
    80005b80:	e04a                	sd	s2,0(sp)
    80005b82:	1000                	addi	s0,sp,32
    80005b84:	84aa                	mv	s1,a0
    80005b86:	8932                	mv	s2,a2
  initlock(&rb->lock, name);
    80005b88:	ff9fa0ef          	jal	80000b80 <initlock>
  rb->head = 0;
    80005b8c:	0004ac23          	sw	zero,24(s1)
  rb->tail = 0;
    80005b90:	0004ae23          	sw	zero,28(s1)
  rb->count = 0;
    80005b94:	0204a023          	sw	zero,32(s1)
  rb->seq = 0;
    80005b98:	0204b423          	sd	zero,40(s1)
  rb->elem_size = elem_size;
    80005b9c:	0324a223          	sw	s2,36(s1)
}
    80005ba0:	60e2                	ld	ra,24(sp)
    80005ba2:	6442                	ld	s0,16(sp)
    80005ba4:	64a2                	ld	s1,8(sp)
    80005ba6:	6902                	ld	s2,0(sp)
    80005ba8:	6105                	addi	sp,sp,32
    80005baa:	8082                	ret

0000000080005bac <ringbuf_push>:

int
ringbuf_push(struct ringbuf *rb, void *elem)
{
    80005bac:	1101                	addi	sp,sp,-32
    80005bae:	ec06                	sd	ra,24(sp)
    80005bb0:	e822                	sd	s0,16(sp)
    80005bb2:	e426                	sd	s1,8(sp)
    80005bb4:	e04a                	sd	s2,0(sp)
    80005bb6:	1000                	addi	s0,sp,32
    80005bb8:	84aa                	mv	s1,a0
    80005bba:	892e                	mv	s2,a1
  acquire(&rb->lock);
    80005bbc:	844fb0ef          	jal	80000c00 <acquire>

  if(rb->count == RB_CAP){
    80005bc0:	5098                	lw	a4,32(s1)
    80005bc2:	20000793          	li	a5,512
    80005bc6:	04f70063          	beq	a4,a5,80005c06 <ringbuf_push+0x5a>
  return (void *)(rb->buf + idx * rb->elem_size);
    80005bca:	50d0                	lw	a2,36(s1)
    80005bcc:	03048513          	addi	a0,s1,48
    80005bd0:	4c9c                	lw	a5,24(s1)
    80005bd2:	02c787bb          	mulw	a5,a5,a2
    80005bd6:	1782                	slli	a5,a5,0x20
    80005bd8:	9381                	srli	a5,a5,0x20
    rb->tail = (rb->tail + 1) % RB_CAP;
    rb->count--;
  }

  memmove(slot_ptr(rb, rb->head), elem, rb->elem_size);
    80005bda:	85ca                	mv	a1,s2
    80005bdc:	953e                	add	a0,a0,a5
    80005bde:	952fb0ef          	jal	80000d30 <memmove>
  rb->head = (rb->head + 1) % RB_CAP;
    80005be2:	4c9c                	lw	a5,24(s1)
    80005be4:	2785                	addiw	a5,a5,1
    80005be6:	1ff7f793          	andi	a5,a5,511
    80005bea:	cc9c                	sw	a5,24(s1)
  rb->count++;
    80005bec:	509c                	lw	a5,32(s1)
    80005bee:	2785                	addiw	a5,a5,1
    80005bf0:	d09c                	sw	a5,32(s1)

  release(&rb->lock);
    80005bf2:	8526                	mv	a0,s1
    80005bf4:	8a4fb0ef          	jal	80000c98 <release>
  return 0;
}
    80005bf8:	4501                	li	a0,0
    80005bfa:	60e2                	ld	ra,24(sp)
    80005bfc:	6442                	ld	s0,16(sp)
    80005bfe:	64a2                	ld	s1,8(sp)
    80005c00:	6902                	ld	s2,0(sp)
    80005c02:	6105                	addi	sp,sp,32
    80005c04:	8082                	ret
    rb->tail = (rb->tail + 1) % RB_CAP;
    80005c06:	4cdc                	lw	a5,28(s1)
    80005c08:	2785                	addiw	a5,a5,1
    80005c0a:	1ff7f793          	andi	a5,a5,511
    80005c0e:	ccdc                	sw	a5,28(s1)
    rb->count--;
    80005c10:	1ff00793          	li	a5,511
    80005c14:	d09c                	sw	a5,32(s1)
    80005c16:	bf55                	j	80005bca <ringbuf_push+0x1e>

0000000080005c18 <ringbuf_read_many>:

int
ringbuf_read_many(struct ringbuf *rb, void *out, int max)
{
    80005c18:	7139                	addi	sp,sp,-64
    80005c1a:	fc06                	sd	ra,56(sp)
    80005c1c:	f822                	sd	s0,48(sp)
    80005c1e:	f04a                	sd	s2,32(sp)
    80005c20:	0080                	addi	s0,sp,64
  int n = 0;
  char *dst = (char *)out;

  if(max <= 0)
    return 0;
    80005c22:	4901                	li	s2,0
  if(max <= 0)
    80005c24:	06c05163          	blez	a2,80005c86 <ringbuf_read_many+0x6e>
    80005c28:	f426                	sd	s1,40(sp)
    80005c2a:	ec4e                	sd	s3,24(sp)
    80005c2c:	e852                	sd	s4,16(sp)
    80005c2e:	e456                	sd	s5,8(sp)
    80005c30:	84aa                	mv	s1,a0
    80005c32:	8a2e                	mv	s4,a1
    80005c34:	89b2                	mv	s3,a2

  acquire(&rb->lock);
    80005c36:	fcbfa0ef          	jal	80000c00 <acquire>
  int n = 0;
    80005c3a:	4901                	li	s2,0
  return (void *)(rb->buf + idx * rb->elem_size);
    80005c3c:	03048a93          	addi	s5,s1,48
  while(n < max && rb->count > 0){
    80005c40:	509c                	lw	a5,32(s1)
    80005c42:	cb9d                	beqz	a5,80005c78 <ringbuf_read_many+0x60>
    memmove(dst + n * rb->elem_size, slot_ptr(rb, rb->tail), rb->elem_size);
    80005c44:	50d0                	lw	a2,36(s1)
  return (void *)(rb->buf + idx * rb->elem_size);
    80005c46:	4ccc                	lw	a1,28(s1)
    80005c48:	02c585bb          	mulw	a1,a1,a2
    80005c4c:	1582                	slli	a1,a1,0x20
    80005c4e:	9181                	srli	a1,a1,0x20
    memmove(dst + n * rb->elem_size, slot_ptr(rb, rb->tail), rb->elem_size);
    80005c50:	02c9053b          	mulw	a0,s2,a2
    80005c54:	1502                	slli	a0,a0,0x20
    80005c56:	9101                	srli	a0,a0,0x20
    80005c58:	95d6                	add	a1,a1,s5
    80005c5a:	9552                	add	a0,a0,s4
    80005c5c:	8d4fb0ef          	jal	80000d30 <memmove>
    rb->tail = (rb->tail + 1) % RB_CAP;
    80005c60:	4cdc                	lw	a5,28(s1)
    80005c62:	2785                	addiw	a5,a5,1
    80005c64:	1ff7f793          	andi	a5,a5,511
    80005c68:	ccdc                	sw	a5,28(s1)
    rb->count--;
    80005c6a:	509c                	lw	a5,32(s1)
    80005c6c:	37fd                	addiw	a5,a5,-1
    80005c6e:	d09c                	sw	a5,32(s1)
    n++;
    80005c70:	2905                	addiw	s2,s2,1
  while(n < max && rb->count > 0){
    80005c72:	fd2997e3          	bne	s3,s2,80005c40 <ringbuf_read_many+0x28>
    80005c76:	894e                	mv	s2,s3
  }
  release(&rb->lock);
    80005c78:	8526                	mv	a0,s1
    80005c7a:	81efb0ef          	jal	80000c98 <release>

  return n;
    80005c7e:	74a2                	ld	s1,40(sp)
    80005c80:	69e2                	ld	s3,24(sp)
    80005c82:	6a42                	ld	s4,16(sp)
    80005c84:	6aa2                	ld	s5,8(sp)
    80005c86:	854a                	mv	a0,s2
    80005c88:	70e2                	ld	ra,56(sp)
    80005c8a:	7442                	ld	s0,48(sp)
    80005c8c:	7902                	ld	s2,32(sp)
    80005c8e:	6121                	addi	sp,sp,64
    80005c90:	8082                	ret
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
