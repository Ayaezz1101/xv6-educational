
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	0d010113          	addi	sp,sp,208 # 8000a0d0 <stack0>
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
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ff97997>
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
    800000e6:	00012517          	auipc	a0,0x12
    800000ea:	fea50513          	addi	a0,a0,-22 # 800120d0 <conswlock>
    800000ee:	33b040ef          	jal	80004c28 <acquiresleep>

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
    8000011e:	1a0020ef          	jal	800022be <either_copyin>
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
    80000162:	00012517          	auipc	a0,0x12
    80000166:	f6e50513          	addi	a0,a0,-146 # 800120d0 <conswlock>
    8000016a:	305040ef          	jal	80004c6e <releasesleep>
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
    800001a0:	00012517          	auipc	a0,0x12
    800001a4:	f6050513          	addi	a0,a0,-160 # 80012100 <cons>
    800001a8:	259000ef          	jal	80000c00 <acquire>

  while(n > 0){
    while(cons.r == cons.w){
    800001ac:	00012497          	auipc	s1,0x12
    800001b0:	f2448493          	addi	s1,s1,-220 # 800120d0 <conswlock>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	00012997          	auipc	s3,0x12
    800001b8:	f4c98993          	addi	s3,s3,-180 # 80012100 <cons>
    800001bc:	00012917          	auipc	s2,0x12
    800001c0:	fdc90913          	addi	s2,s2,-36 # 80012198 <cons+0x98>
  while(n > 0){
    800001c4:	0b405e63          	blez	s4,80000280 <consoleread+0x100>
    while(cons.r == cons.w){
    800001c8:	0c84a783          	lw	a5,200(s1)
    800001cc:	0cc4a703          	lw	a4,204(s1)
    800001d0:	0af71363          	bne	a4,a5,80000276 <consoleread+0xf6>
      if(killed(myproc())){
    800001d4:	734010ef          	jal	80001908 <myproc>
    800001d8:	779010ef          	jal	80002150 <killed>
    800001dc:	e12d                	bnez	a0,8000023e <consoleread+0xbe>
      sleep(&cons.r, &cons.lock);
    800001de:	85ce                	mv	a1,s3
    800001e0:	854a                	mv	a0,s2
    800001e2:	537010ef          	jal	80001f18 <sleep>
    while(cons.r == cons.w){
    800001e6:	0c84a783          	lw	a5,200(s1)
    800001ea:	0cc4a703          	lw	a4,204(s1)
    800001ee:	fef703e3          	beq	a4,a5,800001d4 <consoleread+0x54>
    800001f2:	e862                	sd	s8,16(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001f4:	00012717          	auipc	a4,0x12
    800001f8:	edc70713          	addi	a4,a4,-292 # 800120d0 <conswlock>
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
    80000226:	04e020ef          	jal	80002274 <either_copyout>
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
    8000023e:	00012517          	auipc	a0,0x12
    80000242:	ec250513          	addi	a0,a0,-318 # 80012100 <cons>
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
    8000026a:	00012717          	auipc	a4,0x12
    8000026e:	f2f72723          	sw	a5,-210(a4) # 80012198 <cons+0x98>
    80000272:	6c42                	ld	s8,16(sp)
    80000274:	a031                	j	80000280 <consoleread+0x100>
    80000276:	e862                	sd	s8,16(sp)
    80000278:	bfb5                	j	800001f4 <consoleread+0x74>
    8000027a:	6c42                	ld	s8,16(sp)
    8000027c:	a011                	j	80000280 <consoleread+0x100>
    8000027e:	6c42                	ld	s8,16(sp)
  release(&cons.lock);
    80000280:	00012517          	auipc	a0,0x12
    80000284:	e8050513          	addi	a0,a0,-384 # 80012100 <cons>
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
    800002d4:	00012517          	auipc	a0,0x12
    800002d8:	e2c50513          	addi	a0,a0,-468 # 80012100 <cons>
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
    800002f6:	012020ef          	jal	80002308 <procdump>
      }
    }
    break;
  }

  release(&cons.lock);
    800002fa:	00012517          	auipc	a0,0x12
    800002fe:	e0650513          	addi	a0,a0,-506 # 80012100 <cons>
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
    80000318:	00012717          	auipc	a4,0x12
    8000031c:	db870713          	addi	a4,a4,-584 # 800120d0 <conswlock>
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
    8000033e:	00012797          	auipc	a5,0x12
    80000342:	d9278793          	addi	a5,a5,-622 # 800120d0 <conswlock>
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
    8000036c:	00012797          	auipc	a5,0x12
    80000370:	e2c7a783          	lw	a5,-468(a5) # 80012198 <cons+0x98>
    80000374:	9f1d                	subw	a4,a4,a5
    80000376:	08000793          	li	a5,128
    8000037a:	f8f710e3          	bne	a4,a5,800002fa <consoleintr+0x32>
    8000037e:	a07d                	j	8000042c <consoleintr+0x164>
    80000380:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000382:	00012717          	auipc	a4,0x12
    80000386:	d4e70713          	addi	a4,a4,-690 # 800120d0 <conswlock>
    8000038a:	0d072783          	lw	a5,208(a4)
    8000038e:	0cc72703          	lw	a4,204(a4)
          cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n'){
    80000392:	00012497          	auipc	s1,0x12
    80000396:	d3e48493          	addi	s1,s1,-706 # 800120d0 <conswlock>
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
    800003d4:	00012717          	auipc	a4,0x12
    800003d8:	cfc70713          	addi	a4,a4,-772 # 800120d0 <conswlock>
    800003dc:	0d072783          	lw	a5,208(a4)
    800003e0:	0cc72703          	lw	a4,204(a4)
    800003e4:	f0f70be3          	beq	a4,a5,800002fa <consoleintr+0x32>
      cons.e--;
    800003e8:	37fd                	addiw	a5,a5,-1
    800003ea:	00012717          	auipc	a4,0x12
    800003ee:	daf72b23          	sw	a5,-586(a4) # 800121a0 <cons+0xa0>
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
    80000408:	00012797          	auipc	a5,0x12
    8000040c:	cc878793          	addi	a5,a5,-824 # 800120d0 <conswlock>
    80000410:	0d07a703          	lw	a4,208(a5)
    80000414:	0017069b          	addiw	a3,a4,1
    80000418:	0006861b          	sext.w	a2,a3
    8000041c:	0cd7a823          	sw	a3,208(a5)
    80000420:	07f77713          	andi	a4,a4,127
    80000424:	97ba                	add	a5,a5,a4
    80000426:	4729                	li	a4,10
    80000428:	04e78423          	sb	a4,72(a5)
        cons.w = cons.e;
    8000042c:	00012797          	auipc	a5,0x12
    80000430:	d6c7a823          	sw	a2,-656(a5) # 8001219c <cons+0x9c>
        wakeup(&cons.r);
    80000434:	00012517          	auipc	a0,0x12
    80000438:	d6450513          	addi	a0,a0,-668 # 80012198 <cons+0x98>
    8000043c:	329010ef          	jal	80001f64 <wakeup>
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
    8000044a:	00009597          	auipc	a1,0x9
    8000044e:	bb658593          	addi	a1,a1,-1098 # 80009000 <etext>
    80000452:	00012517          	auipc	a0,0x12
    80000456:	cae50513          	addi	a0,a0,-850 # 80012100 <cons>
    8000045a:	726000ef          	jal	80000b80 <initlock>
  initsleeplock(&conswlock, "consw");
    8000045e:	00009597          	auipc	a1,0x9
    80000462:	baa58593          	addi	a1,a1,-1110 # 80009008 <etext+0x8>
    80000466:	00012517          	auipc	a0,0x12
    8000046a:	c6a50513          	addi	a0,a0,-918 # 800120d0 <conswlock>
    8000046e:	784040ef          	jal	80004bf2 <initsleeplock>

  uartinit();
    80000472:	400000ef          	jal	80000872 <uartinit>

  devsw[CONSOLE].read = consoleread;
    80000476:	00022797          	auipc	a5,0x22
    8000047a:	5fa78793          	addi	a5,a5,1530 # 80022a70 <devsw>
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
    800004b0:	0000a617          	auipc	a2,0xa
    800004b4:	ab060613          	addi	a2,a2,-1360 # 80009f60 <digits>
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
    8000054a:	0000a797          	auipc	a5,0xa
    8000054e:	b4a7a783          	lw	a5,-1206(a5) # 8000a094 <panicking>
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
    80000592:	00012517          	auipc	a0,0x12
    80000596:	c1650513          	addi	a0,a0,-1002 # 800121a8 <pr>
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
    8000075a:	0000ab97          	auipc	s7,0xa
    8000075e:	806b8b93          	addi	s7,s7,-2042 # 80009f60 <digits>
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
    800007ba:	00009917          	auipc	s2,0x9
    800007be:	85690913          	addi	s2,s2,-1962 # 80009010 <etext+0x10>
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
    800007ee:	0000a797          	auipc	a5,0xa
    800007f2:	8a67a783          	lw	a5,-1882(a5) # 8000a094 <panicking>
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
    80000804:	00012517          	auipc	a0,0x12
    80000808:	9a450513          	addi	a0,a0,-1628 # 800121a8 <pr>
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
    80000822:	0000a797          	auipc	a5,0xa
    80000826:	8727a923          	sw	s2,-1934(a5) # 8000a094 <panicking>
  printf("panic: ");
    8000082a:	00008517          	auipc	a0,0x8
    8000082e:	7ee50513          	addi	a0,a0,2030 # 80009018 <etext+0x18>
    80000832:	cfbff0ef          	jal	8000052c <printf>
  printf("%s\n", s);
    80000836:	85a6                	mv	a1,s1
    80000838:	00008517          	auipc	a0,0x8
    8000083c:	7e850513          	addi	a0,a0,2024 # 80009020 <etext+0x20>
    80000840:	cedff0ef          	jal	8000052c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000844:	0000a797          	auipc	a5,0xa
    80000848:	8527a623          	sw	s2,-1972(a5) # 8000a090 <panicked>
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
    80000856:	00008597          	auipc	a1,0x8
    8000085a:	7d258593          	addi	a1,a1,2002 # 80009028 <etext+0x28>
    8000085e:	00012517          	auipc	a0,0x12
    80000862:	94a50513          	addi	a0,a0,-1718 # 800121a8 <pr>
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
    800008ae:	00008597          	auipc	a1,0x8
    800008b2:	78258593          	addi	a1,a1,1922 # 80009030 <etext+0x30>
    800008b6:	00012517          	auipc	a0,0x12
    800008ba:	90a50513          	addi	a0,a0,-1782 # 800121c0 <tx_lock>
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
    800008da:	00012517          	auipc	a0,0x12
    800008de:	8e650513          	addi	a0,a0,-1818 # 800121c0 <tx_lock>
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
    800008f8:	00009497          	auipc	s1,0x9
    800008fc:	7a448493          	addi	s1,s1,1956 # 8000a09c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    80000900:	00012997          	auipc	s3,0x12
    80000904:	8c098993          	addi	s3,s3,-1856 # 800121c0 <tx_lock>
    80000908:	00009917          	auipc	s2,0x9
    8000090c:	79090913          	addi	s2,s2,1936 # 8000a098 <tx_chan>
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
    8000091c:	5fc010ef          	jal	80001f18 <sleep>
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
    80000946:	00012517          	auipc	a0,0x12
    8000094a:	87a50513          	addi	a0,a0,-1926 # 800121c0 <tx_lock>
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
    8000096a:	00009797          	auipc	a5,0x9
    8000096e:	72a7a783          	lw	a5,1834(a5) # 8000a094 <panicking>
    80000972:	cf95                	beqz	a5,800009ae <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000974:	00009797          	auipc	a5,0x9
    80000978:	71c7a783          	lw	a5,1820(a5) # 8000a090 <panicked>
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
    8000099a:	00009797          	auipc	a5,0x9
    8000099e:	6fa7a783          	lw	a5,1786(a5) # 8000a094 <panicking>
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
    800009f6:	00011517          	auipc	a0,0x11
    800009fa:	7ca50513          	addi	a0,a0,1994 # 800121c0 <tx_lock>
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
    80000a12:	00011517          	auipc	a0,0x11
    80000a16:	7ae50513          	addi	a0,a0,1966 # 800121c0 <tx_lock>
    80000a1a:	27e000ef          	jal	80000c98 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a1e:	54fd                	li	s1,-1
    80000a20:	a831                	j	80000a3c <uartintr+0x5a>
    tx_busy = 0;
    80000a22:	00009797          	auipc	a5,0x9
    80000a26:	6607ad23          	sw	zero,1658(a5) # 8000a09c <tx_busy>
    wakeup(&tx_chan);
    80000a2a:	00009517          	auipc	a0,0x9
    80000a2e:	66e50513          	addi	a0,a0,1646 # 8000a098 <tx_chan>
    80000a32:	532010ef          	jal	80001f64 <wakeup>
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
    80000a62:	00066797          	auipc	a5,0x66
    80000a66:	40678793          	addi	a5,a5,1030 # 80066e68 <end>
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
    80000a7e:	00011917          	auipc	s2,0x11
    80000a82:	75a90913          	addi	s2,s2,1882 # 800121d8 <kmem>
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
    80000aa8:	00008517          	auipc	a0,0x8
    80000aac:	59050513          	addi	a0,a0,1424 # 80009038 <etext+0x38>
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
    80000b04:	00008597          	auipc	a1,0x8
    80000b08:	53c58593          	addi	a1,a1,1340 # 80009040 <etext+0x40>
    80000b0c:	00011517          	auipc	a0,0x11
    80000b10:	6cc50513          	addi	a0,a0,1740 # 800121d8 <kmem>
    80000b14:	06c000ef          	jal	80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b18:	45c5                	li	a1,17
    80000b1a:	05ee                	slli	a1,a1,0x1b
    80000b1c:	00066517          	auipc	a0,0x66
    80000b20:	34c50513          	addi	a0,a0,844 # 80066e68 <end>
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
    80000b3a:	00011497          	auipc	s1,0x11
    80000b3e:	69e48493          	addi	s1,s1,1694 # 800121d8 <kmem>
    80000b42:	8526                	mv	a0,s1
    80000b44:	0bc000ef          	jal	80000c00 <acquire>
  r = kmem.freelist;
    80000b48:	6c84                	ld	s1,24(s1)
  if(r)
    80000b4a:	c485                	beqz	s1,80000b72 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b4c:	609c                	ld	a5,0(s1)
    80000b4e:	00011517          	auipc	a0,0x11
    80000b52:	68a50513          	addi	a0,a0,1674 # 800121d8 <kmem>
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
    80000b72:	00011517          	auipc	a0,0x11
    80000b76:	66650513          	addi	a0,a0,1638 # 800121d8 <kmem>
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
    80000baa:	543000ef          	jal	800018ec <mycpu>
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
    80000bd8:	515000ef          	jal	800018ec <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	cb99                	beqz	a5,80000bf4 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be0:	50d000ef          	jal	800018ec <mycpu>
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
    80000bf4:	4f9000ef          	jal	800018ec <mycpu>
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
    80000c28:	4c5000ef          	jal	800018ec <mycpu>
    80000c2c:	e888                	sd	a0,16(s1)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    panic("acquire");
    80000c38:	00008517          	auipc	a0,0x8
    80000c3c:	41050513          	addi	a0,a0,1040 # 80009048 <etext+0x48>
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
    80000c4c:	4a1000ef          	jal	800018ec <mycpu>
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
    80000c80:	00008517          	auipc	a0,0x8
    80000c84:	3d050513          	addi	a0,a0,976 # 80009050 <etext+0x50>
    80000c88:	b8bff0ef          	jal	80000812 <panic>
    panic("pop_off");
    80000c8c:	00008517          	auipc	a0,0x8
    80000c90:	3dc50513          	addi	a0,a0,988 # 80009068 <etext+0x68>
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
    80000cc8:	00008517          	auipc	a0,0x8
    80000ccc:	3a850513          	addi	a0,a0,936 # 80009070 <etext+0x70>
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
    80000d48:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ff98199>
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
    80000e76:	267000ef          	jal	800018dc <cpuid>
    fslog_init();
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7a:	00009717          	auipc	a4,0x9
    80000e7e:	22670713          	addi	a4,a4,550 # 8000a0a0 <started>
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
    80000e8e:	24f000ef          	jal	800018dc <cpuid>
    80000e92:	85aa                	mv	a1,a0
    80000e94:	00008517          	auipc	a0,0x8
    80000e98:	1fc50513          	addi	a0,a0,508 # 80009090 <etext+0x90>
    80000e9c:	e90ff0ef          	jal	8000052c <printf>
    kvminithart();    // turn on paging
    80000ea0:	088000ef          	jal	80000f28 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ea4:	596010ef          	jal	8000243a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ea8:	690050ef          	jal	80006538 <plicinithart>
  }

  scheduler();        
    80000eac:	6cf000ef          	jal	80001d7a <scheduler>
    consoleinit();
    80000eb0:	d92ff0ef          	jal	80000442 <consoleinit>
    printfinit();
    80000eb4:	99bff0ef          	jal	8000084e <printfinit>
    printf("\n");
    80000eb8:	00008517          	auipc	a0,0x8
    80000ebc:	1e850513          	addi	a0,a0,488 # 800090a0 <etext+0xa0>
    80000ec0:	e6cff0ef          	jal	8000052c <printf>
    printf("xv6 kernel is booting\n");
    80000ec4:	00008517          	auipc	a0,0x8
    80000ec8:	1b450513          	addi	a0,a0,436 # 80009078 <etext+0x78>
    80000ecc:	e60ff0ef          	jal	8000052c <printf>
    printf("\n");
    80000ed0:	00008517          	auipc	a0,0x8
    80000ed4:	1d050513          	addi	a0,a0,464 # 800090a0 <etext+0xa0>
    80000ed8:	e54ff0ef          	jal	8000052c <printf>
    kinit();         // physical page allocator
    80000edc:	c21ff0ef          	jal	80000afc <kinit>
    kvminit();       // create kernel page table
    80000ee0:	2d2000ef          	jal	800011b2 <kvminit>
    kvminithart();   // turn on paging
    80000ee4:	044000ef          	jal	80000f28 <kvminithart>
    procinit();      // process table
    80000ee8:	13f000ef          	jal	80001826 <procinit>
    trapinit();      // trap vectors
    80000eec:	52a010ef          	jal	80002416 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ef0:	54a010ef          	jal	8000243a <trapinithart>
    plicinit();      // set up interrupt controller
    80000ef4:	62a050ef          	jal	8000651e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ef8:	640050ef          	jal	80006538 <plicinithart>
    binit();         // buffer cache
    80000efc:	4c3010ef          	jal	80002bbe <binit>
    iinit();         // inode table
    80000f00:	7ba020ef          	jal	800036ba <iinit>
    fileinit();      // file table
    80000f04:	73b030ef          	jal	80004e3e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f08:	720050ef          	jal	80006628 <virtio_disk_init>
    cslog_init();
    80000f0c:	3cf050ef          	jal	80006ada <cslog_init>
    fslog_init();
    80000f10:	725050ef          	jal	80006e34 <fslog_init>
    userinit();      // first user process
    80000f14:	4bb000ef          	jal	80001bce <userinit>
    __sync_synchronize();
    80000f18:	0ff0000f          	fence
    started = 1;
    80000f1c:	4785                	li	a5,1
    80000f1e:	00009717          	auipc	a4,0x9
    80000f22:	18f72123          	sw	a5,386(a4) # 8000a0a0 <started>
    80000f26:	b759                	j	80000eac <main+0x3e>

0000000080000f28 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f28:	1141                	addi	sp,sp,-16
    80000f2a:	e422                	sd	s0,8(sp)
    80000f2c:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f2e:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f32:	00009797          	auipc	a5,0x9
    80000f36:	1767b783          	ld	a5,374(a5) # 8000a0a8 <kernel_pagetable>
    80000f3a:	83b1                	srli	a5,a5,0xc
    80000f3c:	577d                	li	a4,-1
    80000f3e:	177e                	slli	a4,a4,0x3f
    80000f40:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f42:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f46:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f4a:	6422                	ld	s0,8(sp)
    80000f4c:	0141                	addi	sp,sp,16
    80000f4e:	8082                	ret

0000000080000f50 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f50:	7139                	addi	sp,sp,-64
    80000f52:	fc06                	sd	ra,56(sp)
    80000f54:	f822                	sd	s0,48(sp)
    80000f56:	f426                	sd	s1,40(sp)
    80000f58:	f04a                	sd	s2,32(sp)
    80000f5a:	ec4e                	sd	s3,24(sp)
    80000f5c:	e852                	sd	s4,16(sp)
    80000f5e:	e456                	sd	s5,8(sp)
    80000f60:	e05a                	sd	s6,0(sp)
    80000f62:	0080                	addi	s0,sp,64
    80000f64:	84aa                	mv	s1,a0
    80000f66:	89ae                	mv	s3,a1
    80000f68:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f6a:	57fd                	li	a5,-1
    80000f6c:	83e9                	srli	a5,a5,0x1a
    80000f6e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f70:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f72:	02b7fc63          	bgeu	a5,a1,80000faa <walk+0x5a>
    panic("walk");
    80000f76:	00008517          	auipc	a0,0x8
    80000f7a:	13250513          	addi	a0,a0,306 # 800090a8 <etext+0xa8>
    80000f7e:	895ff0ef          	jal	80000812 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f82:	060a8263          	beqz	s5,80000fe6 <walk+0x96>
    80000f86:	babff0ef          	jal	80000b30 <kalloc>
    80000f8a:	84aa                	mv	s1,a0
    80000f8c:	c139                	beqz	a0,80000fd2 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f8e:	6605                	lui	a2,0x1
    80000f90:	4581                	li	a1,0
    80000f92:	d43ff0ef          	jal	80000cd4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f96:	00c4d793          	srli	a5,s1,0xc
    80000f9a:	07aa                	slli	a5,a5,0xa
    80000f9c:	0017e793          	ori	a5,a5,1
    80000fa0:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000fa4:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ff9818f>
    80000fa6:	036a0063          	beq	s4,s6,80000fc6 <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000faa:	0149d933          	srl	s2,s3,s4
    80000fae:	1ff97913          	andi	s2,s2,511
    80000fb2:	090e                	slli	s2,s2,0x3
    80000fb4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000fb6:	00093483          	ld	s1,0(s2)
    80000fba:	0014f793          	andi	a5,s1,1
    80000fbe:	d3f1                	beqz	a5,80000f82 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000fc0:	80a9                	srli	s1,s1,0xa
    80000fc2:	04b2                	slli	s1,s1,0xc
    80000fc4:	b7c5                	j	80000fa4 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000fc6:	00c9d513          	srli	a0,s3,0xc
    80000fca:	1ff57513          	andi	a0,a0,511
    80000fce:	050e                	slli	a0,a0,0x3
    80000fd0:	9526                	add	a0,a0,s1
}
    80000fd2:	70e2                	ld	ra,56(sp)
    80000fd4:	7442                	ld	s0,48(sp)
    80000fd6:	74a2                	ld	s1,40(sp)
    80000fd8:	7902                	ld	s2,32(sp)
    80000fda:	69e2                	ld	s3,24(sp)
    80000fdc:	6a42                	ld	s4,16(sp)
    80000fde:	6aa2                	ld	s5,8(sp)
    80000fe0:	6b02                	ld	s6,0(sp)
    80000fe2:	6121                	addi	sp,sp,64
    80000fe4:	8082                	ret
        return 0;
    80000fe6:	4501                	li	a0,0
    80000fe8:	b7ed                	j	80000fd2 <walk+0x82>

0000000080000fea <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	00b7f463          	bgeu	a5,a1,80000ff6 <walkaddr+0xc>
    return 0;
    80000ff2:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000ff4:	8082                	ret
{
    80000ff6:	1141                	addi	sp,sp,-16
    80000ff8:	e406                	sd	ra,8(sp)
    80000ffa:	e022                	sd	s0,0(sp)
    80000ffc:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000ffe:	4601                	li	a2,0
    80001000:	f51ff0ef          	jal	80000f50 <walk>
  if(pte == 0)
    80001004:	c105                	beqz	a0,80001024 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80001006:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001008:	0117f693          	andi	a3,a5,17
    8000100c:	4745                	li	a4,17
    return 0;
    8000100e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001010:	00e68663          	beq	a3,a4,8000101c <walkaddr+0x32>
}
    80001014:	60a2                	ld	ra,8(sp)
    80001016:	6402                	ld	s0,0(sp)
    80001018:	0141                	addi	sp,sp,16
    8000101a:	8082                	ret
  pa = PTE2PA(*pte);
    8000101c:	83a9                	srli	a5,a5,0xa
    8000101e:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001022:	bfcd                	j	80001014 <walkaddr+0x2a>
    return 0;
    80001024:	4501                	li	a0,0
    80001026:	b7fd                	j	80001014 <walkaddr+0x2a>

0000000080001028 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001028:	715d                	addi	sp,sp,-80
    8000102a:	e486                	sd	ra,72(sp)
    8000102c:	e0a2                	sd	s0,64(sp)
    8000102e:	fc26                	sd	s1,56(sp)
    80001030:	f84a                	sd	s2,48(sp)
    80001032:	f44e                	sd	s3,40(sp)
    80001034:	f052                	sd	s4,32(sp)
    80001036:	ec56                	sd	s5,24(sp)
    80001038:	e85a                	sd	s6,16(sp)
    8000103a:	e45e                	sd	s7,8(sp)
    8000103c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000103e:	03459793          	slli	a5,a1,0x34
    80001042:	e7a9                	bnez	a5,8000108c <mappages+0x64>
    80001044:	8aaa                	mv	s5,a0
    80001046:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    80001048:	03461793          	slli	a5,a2,0x34
    8000104c:	e7b1                	bnez	a5,80001098 <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    8000104e:	ca39                	beqz	a2,800010a4 <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001050:	77fd                	lui	a5,0xfffff
    80001052:	963e                	add	a2,a2,a5
    80001054:	00b609b3          	add	s3,a2,a1
  a = va;
    80001058:	892e                	mv	s2,a1
    8000105a:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000105e:	6b85                	lui	s7,0x1
    80001060:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001064:	4605                	li	a2,1
    80001066:	85ca                	mv	a1,s2
    80001068:	8556                	mv	a0,s5
    8000106a:	ee7ff0ef          	jal	80000f50 <walk>
    8000106e:	c539                	beqz	a0,800010bc <mappages+0x94>
    if(*pte & PTE_V)
    80001070:	611c                	ld	a5,0(a0)
    80001072:	8b85                	andi	a5,a5,1
    80001074:	ef95                	bnez	a5,800010b0 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001076:	80b1                	srli	s1,s1,0xc
    80001078:	04aa                	slli	s1,s1,0xa
    8000107a:	0164e4b3          	or	s1,s1,s6
    8000107e:	0014e493          	ori	s1,s1,1
    80001082:	e104                	sd	s1,0(a0)
    if(a == last)
    80001084:	05390863          	beq	s2,s3,800010d4 <mappages+0xac>
    a += PGSIZE;
    80001088:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000108a:	bfd9                	j	80001060 <mappages+0x38>
    panic("mappages: va not aligned");
    8000108c:	00008517          	auipc	a0,0x8
    80001090:	02450513          	addi	a0,a0,36 # 800090b0 <etext+0xb0>
    80001094:	f7eff0ef          	jal	80000812 <panic>
    panic("mappages: size not aligned");
    80001098:	00008517          	auipc	a0,0x8
    8000109c:	03850513          	addi	a0,a0,56 # 800090d0 <etext+0xd0>
    800010a0:	f72ff0ef          	jal	80000812 <panic>
    panic("mappages: size");
    800010a4:	00008517          	auipc	a0,0x8
    800010a8:	04c50513          	addi	a0,a0,76 # 800090f0 <etext+0xf0>
    800010ac:	f66ff0ef          	jal	80000812 <panic>
      panic("mappages: remap");
    800010b0:	00008517          	auipc	a0,0x8
    800010b4:	05050513          	addi	a0,a0,80 # 80009100 <etext+0x100>
    800010b8:	f5aff0ef          	jal	80000812 <panic>
      return -1;
    800010bc:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010be:	60a6                	ld	ra,72(sp)
    800010c0:	6406                	ld	s0,64(sp)
    800010c2:	74e2                	ld	s1,56(sp)
    800010c4:	7942                	ld	s2,48(sp)
    800010c6:	79a2                	ld	s3,40(sp)
    800010c8:	7a02                	ld	s4,32(sp)
    800010ca:	6ae2                	ld	s5,24(sp)
    800010cc:	6b42                	ld	s6,16(sp)
    800010ce:	6ba2                	ld	s7,8(sp)
    800010d0:	6161                	addi	sp,sp,80
    800010d2:	8082                	ret
  return 0;
    800010d4:	4501                	li	a0,0
    800010d6:	b7e5                	j	800010be <mappages+0x96>

00000000800010d8 <kvmmap>:
{
    800010d8:	1141                	addi	sp,sp,-16
    800010da:	e406                	sd	ra,8(sp)
    800010dc:	e022                	sd	s0,0(sp)
    800010de:	0800                	addi	s0,sp,16
    800010e0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010e2:	86b2                	mv	a3,a2
    800010e4:	863e                	mv	a2,a5
    800010e6:	f43ff0ef          	jal	80001028 <mappages>
    800010ea:	e509                	bnez	a0,800010f4 <kvmmap+0x1c>
}
    800010ec:	60a2                	ld	ra,8(sp)
    800010ee:	6402                	ld	s0,0(sp)
    800010f0:	0141                	addi	sp,sp,16
    800010f2:	8082                	ret
    panic("kvmmap");
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	01c50513          	addi	a0,a0,28 # 80009110 <etext+0x110>
    800010fc:	f16ff0ef          	jal	80000812 <panic>

0000000080001100 <kvmmake>:
{
    80001100:	1101                	addi	sp,sp,-32
    80001102:	ec06                	sd	ra,24(sp)
    80001104:	e822                	sd	s0,16(sp)
    80001106:	e426                	sd	s1,8(sp)
    80001108:	e04a                	sd	s2,0(sp)
    8000110a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000110c:	a25ff0ef          	jal	80000b30 <kalloc>
    80001110:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001112:	6605                	lui	a2,0x1
    80001114:	4581                	li	a1,0
    80001116:	bbfff0ef          	jal	80000cd4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000111a:	4719                	li	a4,6
    8000111c:	6685                	lui	a3,0x1
    8000111e:	10000637          	lui	a2,0x10000
    80001122:	100005b7          	lui	a1,0x10000
    80001126:	8526                	mv	a0,s1
    80001128:	fb1ff0ef          	jal	800010d8 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000112c:	4719                	li	a4,6
    8000112e:	6685                	lui	a3,0x1
    80001130:	10001637          	lui	a2,0x10001
    80001134:	100015b7          	lui	a1,0x10001
    80001138:	8526                	mv	a0,s1
    8000113a:	f9fff0ef          	jal	800010d8 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    8000113e:	4719                	li	a4,6
    80001140:	040006b7          	lui	a3,0x4000
    80001144:	0c000637          	lui	a2,0xc000
    80001148:	0c0005b7          	lui	a1,0xc000
    8000114c:	8526                	mv	a0,s1
    8000114e:	f8bff0ef          	jal	800010d8 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001152:	00008917          	auipc	s2,0x8
    80001156:	eae90913          	addi	s2,s2,-338 # 80009000 <etext>
    8000115a:	4729                	li	a4,10
    8000115c:	80008697          	auipc	a3,0x80008
    80001160:	ea468693          	addi	a3,a3,-348 # 9000 <_entry-0x7fff7000>
    80001164:	4605                	li	a2,1
    80001166:	067e                	slli	a2,a2,0x1f
    80001168:	85b2                	mv	a1,a2
    8000116a:	8526                	mv	a0,s1
    8000116c:	f6dff0ef          	jal	800010d8 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001170:	46c5                	li	a3,17
    80001172:	06ee                	slli	a3,a3,0x1b
    80001174:	4719                	li	a4,6
    80001176:	412686b3          	sub	a3,a3,s2
    8000117a:	864a                	mv	a2,s2
    8000117c:	85ca                	mv	a1,s2
    8000117e:	8526                	mv	a0,s1
    80001180:	f59ff0ef          	jal	800010d8 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001184:	4729                	li	a4,10
    80001186:	6685                	lui	a3,0x1
    80001188:	00007617          	auipc	a2,0x7
    8000118c:	e7860613          	addi	a2,a2,-392 # 80008000 <_trampoline>
    80001190:	040005b7          	lui	a1,0x4000
    80001194:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001196:	05b2                	slli	a1,a1,0xc
    80001198:	8526                	mv	a0,s1
    8000119a:	f3fff0ef          	jal	800010d8 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000119e:	8526                	mv	a0,s1
    800011a0:	5ee000ef          	jal	8000178e <proc_mapstacks>
}
    800011a4:	8526                	mv	a0,s1
    800011a6:	60e2                	ld	ra,24(sp)
    800011a8:	6442                	ld	s0,16(sp)
    800011aa:	64a2                	ld	s1,8(sp)
    800011ac:	6902                	ld	s2,0(sp)
    800011ae:	6105                	addi	sp,sp,32
    800011b0:	8082                	ret

00000000800011b2 <kvminit>:
{
    800011b2:	1141                	addi	sp,sp,-16
    800011b4:	e406                	sd	ra,8(sp)
    800011b6:	e022                	sd	s0,0(sp)
    800011b8:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800011ba:	f47ff0ef          	jal	80001100 <kvmmake>
    800011be:	00009797          	auipc	a5,0x9
    800011c2:	eea7b523          	sd	a0,-278(a5) # 8000a0a8 <kernel_pagetable>
}
    800011c6:	60a2                	ld	ra,8(sp)
    800011c8:	6402                	ld	s0,0(sp)
    800011ca:	0141                	addi	sp,sp,16
    800011cc:	8082                	ret

00000000800011ce <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800011ce:	1101                	addi	sp,sp,-32
    800011d0:	ec06                	sd	ra,24(sp)
    800011d2:	e822                	sd	s0,16(sp)
    800011d4:	e426                	sd	s1,8(sp)
    800011d6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800011d8:	959ff0ef          	jal	80000b30 <kalloc>
    800011dc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011de:	c509                	beqz	a0,800011e8 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011e0:	6605                	lui	a2,0x1
    800011e2:	4581                	li	a1,0
    800011e4:	af1ff0ef          	jal	80000cd4 <memset>
  return pagetable;
}
    800011e8:	8526                	mv	a0,s1
    800011ea:	60e2                	ld	ra,24(sp)
    800011ec:	6442                	ld	s0,16(sp)
    800011ee:	64a2                	ld	s1,8(sp)
    800011f0:	6105                	addi	sp,sp,32
    800011f2:	8082                	ret

00000000800011f4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011f4:	7139                	addi	sp,sp,-64
    800011f6:	fc06                	sd	ra,56(sp)
    800011f8:	f822                	sd	s0,48(sp)
    800011fa:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011fc:	03459793          	slli	a5,a1,0x34
    80001200:	e38d                	bnez	a5,80001222 <uvmunmap+0x2e>
    80001202:	f04a                	sd	s2,32(sp)
    80001204:	ec4e                	sd	s3,24(sp)
    80001206:	e852                	sd	s4,16(sp)
    80001208:	e456                	sd	s5,8(sp)
    8000120a:	e05a                	sd	s6,0(sp)
    8000120c:	8a2a                	mv	s4,a0
    8000120e:	892e                	mv	s2,a1
    80001210:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001212:	0632                	slli	a2,a2,0xc
    80001214:	00b609b3          	add	s3,a2,a1
    80001218:	6b05                	lui	s6,0x1
    8000121a:	0535f963          	bgeu	a1,s3,8000126c <uvmunmap+0x78>
    8000121e:	f426                	sd	s1,40(sp)
    80001220:	a015                	j	80001244 <uvmunmap+0x50>
    80001222:	f426                	sd	s1,40(sp)
    80001224:	f04a                	sd	s2,32(sp)
    80001226:	ec4e                	sd	s3,24(sp)
    80001228:	e852                	sd	s4,16(sp)
    8000122a:	e456                	sd	s5,8(sp)
    8000122c:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    8000122e:	00008517          	auipc	a0,0x8
    80001232:	eea50513          	addi	a0,a0,-278 # 80009118 <etext+0x118>
    80001236:	ddcff0ef          	jal	80000812 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    8000123a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000123e:	995a                	add	s2,s2,s6
    80001240:	03397563          	bgeu	s2,s3,8000126a <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001244:	4601                	li	a2,0
    80001246:	85ca                	mv	a1,s2
    80001248:	8552                	mv	a0,s4
    8000124a:	d07ff0ef          	jal	80000f50 <walk>
    8000124e:	84aa                	mv	s1,a0
    80001250:	d57d                	beqz	a0,8000123e <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001252:	611c                	ld	a5,0(a0)
    80001254:	0017f713          	andi	a4,a5,1
    80001258:	d37d                	beqz	a4,8000123e <uvmunmap+0x4a>
    if(do_free){
    8000125a:	fe0a80e3          	beqz	s5,8000123a <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    8000125e:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001260:	00c79513          	slli	a0,a5,0xc
    80001264:	feaff0ef          	jal	80000a4e <kfree>
    80001268:	bfc9                	j	8000123a <uvmunmap+0x46>
    8000126a:	74a2                	ld	s1,40(sp)
    8000126c:	7902                	ld	s2,32(sp)
    8000126e:	69e2                	ld	s3,24(sp)
    80001270:	6a42                	ld	s4,16(sp)
    80001272:	6aa2                	ld	s5,8(sp)
    80001274:	6b02                	ld	s6,0(sp)
  }
}
    80001276:	70e2                	ld	ra,56(sp)
    80001278:	7442                	ld	s0,48(sp)
    8000127a:	6121                	addi	sp,sp,64
    8000127c:	8082                	ret

000000008000127e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000127e:	1101                	addi	sp,sp,-32
    80001280:	ec06                	sd	ra,24(sp)
    80001282:	e822                	sd	s0,16(sp)
    80001284:	e426                	sd	s1,8(sp)
    80001286:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001288:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000128a:	00b67d63          	bgeu	a2,a1,800012a4 <uvmdealloc+0x26>
    8000128e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001290:	6785                	lui	a5,0x1
    80001292:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001294:	00f60733          	add	a4,a2,a5
    80001298:	76fd                	lui	a3,0xfffff
    8000129a:	8f75                	and	a4,a4,a3
    8000129c:	97ae                	add	a5,a5,a1
    8000129e:	8ff5                	and	a5,a5,a3
    800012a0:	00f76863          	bltu	a4,a5,800012b0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800012a4:	8526                	mv	a0,s1
    800012a6:	60e2                	ld	ra,24(sp)
    800012a8:	6442                	ld	s0,16(sp)
    800012aa:	64a2                	ld	s1,8(sp)
    800012ac:	6105                	addi	sp,sp,32
    800012ae:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800012b0:	8f99                	sub	a5,a5,a4
    800012b2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800012b4:	4685                	li	a3,1
    800012b6:	0007861b          	sext.w	a2,a5
    800012ba:	85ba                	mv	a1,a4
    800012bc:	f39ff0ef          	jal	800011f4 <uvmunmap>
    800012c0:	b7d5                	j	800012a4 <uvmdealloc+0x26>

00000000800012c2 <uvmalloc>:
  if(newsz < oldsz)
    800012c2:	08b66f63          	bltu	a2,a1,80001360 <uvmalloc+0x9e>
{
    800012c6:	7139                	addi	sp,sp,-64
    800012c8:	fc06                	sd	ra,56(sp)
    800012ca:	f822                	sd	s0,48(sp)
    800012cc:	ec4e                	sd	s3,24(sp)
    800012ce:	e852                	sd	s4,16(sp)
    800012d0:	e456                	sd	s5,8(sp)
    800012d2:	0080                	addi	s0,sp,64
    800012d4:	8aaa                	mv	s5,a0
    800012d6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800012d8:	6785                	lui	a5,0x1
    800012da:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012dc:	95be                	add	a1,a1,a5
    800012de:	77fd                	lui	a5,0xfffff
    800012e0:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012e4:	08c9f063          	bgeu	s3,a2,80001364 <uvmalloc+0xa2>
    800012e8:	f426                	sd	s1,40(sp)
    800012ea:	f04a                	sd	s2,32(sp)
    800012ec:	e05a                	sd	s6,0(sp)
    800012ee:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012f0:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012f4:	83dff0ef          	jal	80000b30 <kalloc>
    800012f8:	84aa                	mv	s1,a0
    if(mem == 0){
    800012fa:	c515                	beqz	a0,80001326 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012fc:	6605                	lui	a2,0x1
    800012fe:	4581                	li	a1,0
    80001300:	9d5ff0ef          	jal	80000cd4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001304:	875a                	mv	a4,s6
    80001306:	86a6                	mv	a3,s1
    80001308:	6605                	lui	a2,0x1
    8000130a:	85ca                	mv	a1,s2
    8000130c:	8556                	mv	a0,s5
    8000130e:	d1bff0ef          	jal	80001028 <mappages>
    80001312:	e915                	bnez	a0,80001346 <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001314:	6785                	lui	a5,0x1
    80001316:	993e                	add	s2,s2,a5
    80001318:	fd496ee3          	bltu	s2,s4,800012f4 <uvmalloc+0x32>
  return newsz;
    8000131c:	8552                	mv	a0,s4
    8000131e:	74a2                	ld	s1,40(sp)
    80001320:	7902                	ld	s2,32(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	a811                	j	80001338 <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    80001326:	864e                	mv	a2,s3
    80001328:	85ca                	mv	a1,s2
    8000132a:	8556                	mv	a0,s5
    8000132c:	f53ff0ef          	jal	8000127e <uvmdealloc>
      return 0;
    80001330:	4501                	li	a0,0
    80001332:	74a2                	ld	s1,40(sp)
    80001334:	7902                	ld	s2,32(sp)
    80001336:	6b02                	ld	s6,0(sp)
}
    80001338:	70e2                	ld	ra,56(sp)
    8000133a:	7442                	ld	s0,48(sp)
    8000133c:	69e2                	ld	s3,24(sp)
    8000133e:	6a42                	ld	s4,16(sp)
    80001340:	6aa2                	ld	s5,8(sp)
    80001342:	6121                	addi	sp,sp,64
    80001344:	8082                	ret
      kfree(mem);
    80001346:	8526                	mv	a0,s1
    80001348:	f06ff0ef          	jal	80000a4e <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000134c:	864e                	mv	a2,s3
    8000134e:	85ca                	mv	a1,s2
    80001350:	8556                	mv	a0,s5
    80001352:	f2dff0ef          	jal	8000127e <uvmdealloc>
      return 0;
    80001356:	4501                	li	a0,0
    80001358:	74a2                	ld	s1,40(sp)
    8000135a:	7902                	ld	s2,32(sp)
    8000135c:	6b02                	ld	s6,0(sp)
    8000135e:	bfe9                	j	80001338 <uvmalloc+0x76>
    return oldsz;
    80001360:	852e                	mv	a0,a1
}
    80001362:	8082                	ret
  return newsz;
    80001364:	8532                	mv	a0,a2
    80001366:	bfc9                	j	80001338 <uvmalloc+0x76>

0000000080001368 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
    80001378:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000137a:	84aa                	mv	s1,a0
    8000137c:	6905                	lui	s2,0x1
    8000137e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001380:	4985                	li	s3,1
    80001382:	a819                	j	80001398 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001384:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001386:	00c79513          	slli	a0,a5,0xc
    8000138a:	fdfff0ef          	jal	80001368 <freewalk>
      pagetable[i] = 0;
    8000138e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001392:	04a1                	addi	s1,s1,8
    80001394:	01248f63          	beq	s1,s2,800013b2 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    80001398:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000139a:	00f7f713          	andi	a4,a5,15
    8000139e:	ff3703e3          	beq	a4,s3,80001384 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800013a2:	8b85                	andi	a5,a5,1
    800013a4:	d7fd                	beqz	a5,80001392 <freewalk+0x2a>
      panic("freewalk: leaf");
    800013a6:	00008517          	auipc	a0,0x8
    800013aa:	d8a50513          	addi	a0,a0,-630 # 80009130 <etext+0x130>
    800013ae:	c64ff0ef          	jal	80000812 <panic>
    }
  }
  kfree((void*)pagetable);
    800013b2:	8552                	mv	a0,s4
    800013b4:	e9aff0ef          	jal	80000a4e <kfree>
}
    800013b8:	70a2                	ld	ra,40(sp)
    800013ba:	7402                	ld	s0,32(sp)
    800013bc:	64e2                	ld	s1,24(sp)
    800013be:	6942                	ld	s2,16(sp)
    800013c0:	69a2                	ld	s3,8(sp)
    800013c2:	6a02                	ld	s4,0(sp)
    800013c4:	6145                	addi	sp,sp,48
    800013c6:	8082                	ret

00000000800013c8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
    800013d2:	84aa                	mv	s1,a0
  if(sz > 0)
    800013d4:	e989                	bnez	a1,800013e6 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013d6:	8526                	mv	a0,s1
    800013d8:	f91ff0ef          	jal	80001368 <freewalk>
}
    800013dc:	60e2                	ld	ra,24(sp)
    800013de:	6442                	ld	s0,16(sp)
    800013e0:	64a2                	ld	s1,8(sp)
    800013e2:	6105                	addi	sp,sp,32
    800013e4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013e6:	6785                	lui	a5,0x1
    800013e8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013ea:	95be                	add	a1,a1,a5
    800013ec:	4685                	li	a3,1
    800013ee:	00c5d613          	srli	a2,a1,0xc
    800013f2:	4581                	li	a1,0
    800013f4:	e01ff0ef          	jal	800011f4 <uvmunmap>
    800013f8:	bff9                	j	800013d6 <uvmfree+0xe>

00000000800013fa <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013fa:	ce49                	beqz	a2,80001494 <uvmcopy+0x9a>
{
    800013fc:	715d                	addi	sp,sp,-80
    800013fe:	e486                	sd	ra,72(sp)
    80001400:	e0a2                	sd	s0,64(sp)
    80001402:	fc26                	sd	s1,56(sp)
    80001404:	f84a                	sd	s2,48(sp)
    80001406:	f44e                	sd	s3,40(sp)
    80001408:	f052                	sd	s4,32(sp)
    8000140a:	ec56                	sd	s5,24(sp)
    8000140c:	e85a                	sd	s6,16(sp)
    8000140e:	e45e                	sd	s7,8(sp)
    80001410:	0880                	addi	s0,sp,80
    80001412:	8aaa                	mv	s5,a0
    80001414:	8b2e                	mv	s6,a1
    80001416:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001418:	4481                	li	s1,0
    8000141a:	a029                	j	80001424 <uvmcopy+0x2a>
    8000141c:	6785                	lui	a5,0x1
    8000141e:	94be                	add	s1,s1,a5
    80001420:	0544fe63          	bgeu	s1,s4,8000147c <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    80001424:	4601                	li	a2,0
    80001426:	85a6                	mv	a1,s1
    80001428:	8556                	mv	a0,s5
    8000142a:	b27ff0ef          	jal	80000f50 <walk>
    8000142e:	d57d                	beqz	a0,8000141c <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    80001430:	6118                	ld	a4,0(a0)
    80001432:	00177793          	andi	a5,a4,1
    80001436:	d3fd                	beqz	a5,8000141c <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    80001438:	00a75593          	srli	a1,a4,0xa
    8000143c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001440:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001444:	eecff0ef          	jal	80000b30 <kalloc>
    80001448:	89aa                	mv	s3,a0
    8000144a:	c105                	beqz	a0,8000146a <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000144c:	6605                	lui	a2,0x1
    8000144e:	85de                	mv	a1,s7
    80001450:	8e1ff0ef          	jal	80000d30 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001454:	874a                	mv	a4,s2
    80001456:	86ce                	mv	a3,s3
    80001458:	6605                	lui	a2,0x1
    8000145a:	85a6                	mv	a1,s1
    8000145c:	855a                	mv	a0,s6
    8000145e:	bcbff0ef          	jal	80001028 <mappages>
    80001462:	dd4d                	beqz	a0,8000141c <uvmcopy+0x22>
      kfree(mem);
    80001464:	854e                	mv	a0,s3
    80001466:	de8ff0ef          	jal	80000a4e <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000146a:	4685                	li	a3,1
    8000146c:	00c4d613          	srli	a2,s1,0xc
    80001470:	4581                	li	a1,0
    80001472:	855a                	mv	a0,s6
    80001474:	d81ff0ef          	jal	800011f4 <uvmunmap>
  return -1;
    80001478:	557d                	li	a0,-1
    8000147a:	a011                	j	8000147e <uvmcopy+0x84>
  return 0;
    8000147c:	4501                	li	a0,0
}
    8000147e:	60a6                	ld	ra,72(sp)
    80001480:	6406                	ld	s0,64(sp)
    80001482:	74e2                	ld	s1,56(sp)
    80001484:	7942                	ld	s2,48(sp)
    80001486:	79a2                	ld	s3,40(sp)
    80001488:	7a02                	ld	s4,32(sp)
    8000148a:	6ae2                	ld	s5,24(sp)
    8000148c:	6b42                	ld	s6,16(sp)
    8000148e:	6ba2                	ld	s7,8(sp)
    80001490:	6161                	addi	sp,sp,80
    80001492:	8082                	ret
  return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	8082                	ret

0000000080001498 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001498:	1141                	addi	sp,sp,-16
    8000149a:	e406                	sd	ra,8(sp)
    8000149c:	e022                	sd	s0,0(sp)
    8000149e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800014a0:	4601                	li	a2,0
    800014a2:	aafff0ef          	jal	80000f50 <walk>
  if(pte == 0)
    800014a6:	c901                	beqz	a0,800014b6 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800014a8:	611c                	ld	a5,0(a0)
    800014aa:	9bbd                	andi	a5,a5,-17
    800014ac:	e11c                	sd	a5,0(a0)
}
    800014ae:	60a2                	ld	ra,8(sp)
    800014b0:	6402                	ld	s0,0(sp)
    800014b2:	0141                	addi	sp,sp,16
    800014b4:	8082                	ret
    panic("uvmclear");
    800014b6:	00008517          	auipc	a0,0x8
    800014ba:	c8a50513          	addi	a0,a0,-886 # 80009140 <etext+0x140>
    800014be:	b54ff0ef          	jal	80000812 <panic>

00000000800014c2 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800014c2:	c6dd                	beqz	a3,80001570 <copyinstr+0xae>
{
    800014c4:	715d                	addi	sp,sp,-80
    800014c6:	e486                	sd	ra,72(sp)
    800014c8:	e0a2                	sd	s0,64(sp)
    800014ca:	fc26                	sd	s1,56(sp)
    800014cc:	f84a                	sd	s2,48(sp)
    800014ce:	f44e                	sd	s3,40(sp)
    800014d0:	f052                	sd	s4,32(sp)
    800014d2:	ec56                	sd	s5,24(sp)
    800014d4:	e85a                	sd	s6,16(sp)
    800014d6:	e45e                	sd	s7,8(sp)
    800014d8:	0880                	addi	s0,sp,80
    800014da:	8a2a                	mv	s4,a0
    800014dc:	8b2e                	mv	s6,a1
    800014de:	8bb2                	mv	s7,a2
    800014e0:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014e2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014e4:	6985                	lui	s3,0x1
    800014e6:	a825                	j	8000151e <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014e8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014ec:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014ee:	37fd                	addiw	a5,a5,-1
    800014f0:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014f4:	60a6                	ld	ra,72(sp)
    800014f6:	6406                	ld	s0,64(sp)
    800014f8:	74e2                	ld	s1,56(sp)
    800014fa:	7942                	ld	s2,48(sp)
    800014fc:	79a2                	ld	s3,40(sp)
    800014fe:	7a02                	ld	s4,32(sp)
    80001500:	6ae2                	ld	s5,24(sp)
    80001502:	6b42                	ld	s6,16(sp)
    80001504:	6ba2                	ld	s7,8(sp)
    80001506:	6161                	addi	sp,sp,80
    80001508:	8082                	ret
    8000150a:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    8000150e:	9742                	add	a4,a4,a6
      --max;
    80001510:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    80001514:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001518:	04e58463          	beq	a1,a4,80001560 <copyinstr+0x9e>
{
    8000151c:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    8000151e:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001522:	85a6                	mv	a1,s1
    80001524:	8552                	mv	a0,s4
    80001526:	ac5ff0ef          	jal	80000fea <walkaddr>
    if(pa0 == 0)
    8000152a:	cd0d                	beqz	a0,80001564 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000152c:	417486b3          	sub	a3,s1,s7
    80001530:	96ce                	add	a3,a3,s3
    if(n > max)
    80001532:	00d97363          	bgeu	s2,a3,80001538 <copyinstr+0x76>
    80001536:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001538:	955e                	add	a0,a0,s7
    8000153a:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000153c:	c695                	beqz	a3,80001568 <copyinstr+0xa6>
    8000153e:	87da                	mv	a5,s6
    80001540:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001542:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001546:	96da                	add	a3,a3,s6
    80001548:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000154a:	00f60733          	add	a4,a2,a5
    8000154e:	00074703          	lbu	a4,0(a4)
    80001552:	db59                	beqz	a4,800014e8 <copyinstr+0x26>
        *dst = *p;
    80001554:	00e78023          	sb	a4,0(a5)
      dst++;
    80001558:	0785                	addi	a5,a5,1
    while(n > 0){
    8000155a:	fed797e3          	bne	a5,a3,80001548 <copyinstr+0x86>
    8000155e:	b775                	j	8000150a <copyinstr+0x48>
    80001560:	4781                	li	a5,0
    80001562:	b771                	j	800014ee <copyinstr+0x2c>
      return -1;
    80001564:	557d                	li	a0,-1
    80001566:	b779                	j	800014f4 <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    80001568:	6b85                	lui	s7,0x1
    8000156a:	9ba6                	add	s7,s7,s1
    8000156c:	87da                	mv	a5,s6
    8000156e:	b77d                	j	8000151c <copyinstr+0x5a>
  int got_null = 0;
    80001570:	4781                	li	a5,0
  if(got_null){
    80001572:	37fd                	addiw	a5,a5,-1
    80001574:	0007851b          	sext.w	a0,a5
}
    80001578:	8082                	ret

000000008000157a <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    8000157a:	1141                	addi	sp,sp,-16
    8000157c:	e406                	sd	ra,8(sp)
    8000157e:	e022                	sd	s0,0(sp)
    80001580:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001582:	4601                	li	a2,0
    80001584:	9cdff0ef          	jal	80000f50 <walk>
  if (pte == 0) {
    80001588:	c519                	beqz	a0,80001596 <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    8000158a:	6108                	ld	a0,0(a0)
    8000158c:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    8000158e:	60a2                	ld	ra,8(sp)
    80001590:	6402                	ld	s0,0(sp)
    80001592:	0141                	addi	sp,sp,16
    80001594:	8082                	ret
    return 0;
    80001596:	4501                	li	a0,0
    80001598:	bfdd                	j	8000158e <ismapped+0x14>

000000008000159a <vmfault>:
{
    8000159a:	7179                	addi	sp,sp,-48
    8000159c:	f406                	sd	ra,40(sp)
    8000159e:	f022                	sd	s0,32(sp)
    800015a0:	ec26                	sd	s1,24(sp)
    800015a2:	e44e                	sd	s3,8(sp)
    800015a4:	1800                	addi	s0,sp,48
    800015a6:	89aa                	mv	s3,a0
    800015a8:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    800015aa:	35e000ef          	jal	80001908 <myproc>
  if (va >= p->sz)
    800015ae:	653c                	ld	a5,72(a0)
    800015b0:	00f4ea63          	bltu	s1,a5,800015c4 <vmfault+0x2a>
    return 0;
    800015b4:	4981                	li	s3,0
}
    800015b6:	854e                	mv	a0,s3
    800015b8:	70a2                	ld	ra,40(sp)
    800015ba:	7402                	ld	s0,32(sp)
    800015bc:	64e2                	ld	s1,24(sp)
    800015be:	69a2                	ld	s3,8(sp)
    800015c0:	6145                	addi	sp,sp,48
    800015c2:	8082                	ret
    800015c4:	e84a                	sd	s2,16(sp)
    800015c6:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    800015c8:	77fd                	lui	a5,0xfffff
    800015ca:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    800015cc:	85a6                	mv	a1,s1
    800015ce:	854e                	mv	a0,s3
    800015d0:	fabff0ef          	jal	8000157a <ismapped>
    return 0;
    800015d4:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015d6:	c119                	beqz	a0,800015dc <vmfault+0x42>
    800015d8:	6942                	ld	s2,16(sp)
    800015da:	bff1                	j	800015b6 <vmfault+0x1c>
    800015dc:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015de:	d52ff0ef          	jal	80000b30 <kalloc>
    800015e2:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015e4:	c90d                	beqz	a0,80001616 <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015e6:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015e8:	6605                	lui	a2,0x1
    800015ea:	4581                	li	a1,0
    800015ec:	ee8ff0ef          	jal	80000cd4 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015f0:	4759                	li	a4,22
    800015f2:	86d2                	mv	a3,s4
    800015f4:	6605                	lui	a2,0x1
    800015f6:	85a6                	mv	a1,s1
    800015f8:	05093503          	ld	a0,80(s2)
    800015fc:	a2dff0ef          	jal	80001028 <mappages>
    80001600:	e501                	bnez	a0,80001608 <vmfault+0x6e>
    80001602:	6942                	ld	s2,16(sp)
    80001604:	6a02                	ld	s4,0(sp)
    80001606:	bf45                	j	800015b6 <vmfault+0x1c>
    kfree((void *)mem);
    80001608:	8552                	mv	a0,s4
    8000160a:	c44ff0ef          	jal	80000a4e <kfree>
    return 0;
    8000160e:	4981                	li	s3,0
    80001610:	6942                	ld	s2,16(sp)
    80001612:	6a02                	ld	s4,0(sp)
    80001614:	b74d                	j	800015b6 <vmfault+0x1c>
    80001616:	6942                	ld	s2,16(sp)
    80001618:	6a02                	ld	s4,0(sp)
    8000161a:	bf71                	j	800015b6 <vmfault+0x1c>

000000008000161c <copyout>:
  while(len > 0){
    8000161c:	c2cd                	beqz	a3,800016be <copyout+0xa2>
{
    8000161e:	711d                	addi	sp,sp,-96
    80001620:	ec86                	sd	ra,88(sp)
    80001622:	e8a2                	sd	s0,80(sp)
    80001624:	e4a6                	sd	s1,72(sp)
    80001626:	f852                	sd	s4,48(sp)
    80001628:	f05a                	sd	s6,32(sp)
    8000162a:	ec5e                	sd	s7,24(sp)
    8000162c:	e862                	sd	s8,16(sp)
    8000162e:	1080                	addi	s0,sp,96
    80001630:	8c2a                	mv	s8,a0
    80001632:	8b2e                	mv	s6,a1
    80001634:	8bb2                	mv	s7,a2
    80001636:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001638:	74fd                	lui	s1,0xfffff
    8000163a:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    8000163c:	57fd                	li	a5,-1
    8000163e:	83e9                	srli	a5,a5,0x1a
    80001640:	0897e163          	bltu	a5,s1,800016c2 <copyout+0xa6>
    80001644:	e0ca                	sd	s2,64(sp)
    80001646:	fc4e                	sd	s3,56(sp)
    80001648:	f456                	sd	s5,40(sp)
    8000164a:	e466                	sd	s9,8(sp)
    8000164c:	e06a                	sd	s10,0(sp)
    8000164e:	6d05                	lui	s10,0x1
    80001650:	8cbe                	mv	s9,a5
    80001652:	a015                	j	80001676 <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001654:	409b0533          	sub	a0,s6,s1
    80001658:	0009861b          	sext.w	a2,s3
    8000165c:	85de                	mv	a1,s7
    8000165e:	954a                	add	a0,a0,s2
    80001660:	ed0ff0ef          	jal	80000d30 <memmove>
    len -= n;
    80001664:	413a0a33          	sub	s4,s4,s3
    src += n;
    80001668:	9bce                	add	s7,s7,s3
  while(len > 0){
    8000166a:	040a0363          	beqz	s4,800016b0 <copyout+0x94>
    if(va0 >= MAXVA)
    8000166e:	055cec63          	bltu	s9,s5,800016c6 <copyout+0xaa>
    80001672:	84d6                	mv	s1,s5
    80001674:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    80001676:	85a6                	mv	a1,s1
    80001678:	8562                	mv	a0,s8
    8000167a:	971ff0ef          	jal	80000fea <walkaddr>
    8000167e:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001680:	e901                	bnez	a0,80001690 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001682:	4601                	li	a2,0
    80001684:	85a6                	mv	a1,s1
    80001686:	8562                	mv	a0,s8
    80001688:	f13ff0ef          	jal	8000159a <vmfault>
    8000168c:	892a                	mv	s2,a0
    8000168e:	c139                	beqz	a0,800016d4 <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001690:	4601                	li	a2,0
    80001692:	85a6                	mv	a1,s1
    80001694:	8562                	mv	a0,s8
    80001696:	8bbff0ef          	jal	80000f50 <walk>
    if((*pte & PTE_W) == 0)
    8000169a:	611c                	ld	a5,0(a0)
    8000169c:	8b91                	andi	a5,a5,4
    8000169e:	c3b1                	beqz	a5,800016e2 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    800016a0:	01a48ab3          	add	s5,s1,s10
    800016a4:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    800016a8:	fb3a76e3          	bgeu	s4,s3,80001654 <copyout+0x38>
    800016ac:	89d2                	mv	s3,s4
    800016ae:	b75d                	j	80001654 <copyout+0x38>
  return 0;
    800016b0:	4501                	li	a0,0
    800016b2:	6906                	ld	s2,64(sp)
    800016b4:	79e2                	ld	s3,56(sp)
    800016b6:	7aa2                	ld	s5,40(sp)
    800016b8:	6ca2                	ld	s9,8(sp)
    800016ba:	6d02                	ld	s10,0(sp)
    800016bc:	a80d                	j	800016ee <copyout+0xd2>
    800016be:	4501                	li	a0,0
}
    800016c0:	8082                	ret
      return -1;
    800016c2:	557d                	li	a0,-1
    800016c4:	a02d                	j	800016ee <copyout+0xd2>
    800016c6:	557d                	li	a0,-1
    800016c8:	6906                	ld	s2,64(sp)
    800016ca:	79e2                	ld	s3,56(sp)
    800016cc:	7aa2                	ld	s5,40(sp)
    800016ce:	6ca2                	ld	s9,8(sp)
    800016d0:	6d02                	ld	s10,0(sp)
    800016d2:	a831                	j	800016ee <copyout+0xd2>
        return -1;
    800016d4:	557d                	li	a0,-1
    800016d6:	6906                	ld	s2,64(sp)
    800016d8:	79e2                	ld	s3,56(sp)
    800016da:	7aa2                	ld	s5,40(sp)
    800016dc:	6ca2                	ld	s9,8(sp)
    800016de:	6d02                	ld	s10,0(sp)
    800016e0:	a039                	j	800016ee <copyout+0xd2>
      return -1;
    800016e2:	557d                	li	a0,-1
    800016e4:	6906                	ld	s2,64(sp)
    800016e6:	79e2                	ld	s3,56(sp)
    800016e8:	7aa2                	ld	s5,40(sp)
    800016ea:	6ca2                	ld	s9,8(sp)
    800016ec:	6d02                	ld	s10,0(sp)
}
    800016ee:	60e6                	ld	ra,88(sp)
    800016f0:	6446                	ld	s0,80(sp)
    800016f2:	64a6                	ld	s1,72(sp)
    800016f4:	7a42                	ld	s4,48(sp)
    800016f6:	7b02                	ld	s6,32(sp)
    800016f8:	6be2                	ld	s7,24(sp)
    800016fa:	6c42                	ld	s8,16(sp)
    800016fc:	6125                	addi	sp,sp,96
    800016fe:	8082                	ret

0000000080001700 <copyin>:
  while(len > 0){
    80001700:	c6c9                	beqz	a3,8000178a <copyin+0x8a>
{
    80001702:	715d                	addi	sp,sp,-80
    80001704:	e486                	sd	ra,72(sp)
    80001706:	e0a2                	sd	s0,64(sp)
    80001708:	fc26                	sd	s1,56(sp)
    8000170a:	f84a                	sd	s2,48(sp)
    8000170c:	f44e                	sd	s3,40(sp)
    8000170e:	f052                	sd	s4,32(sp)
    80001710:	ec56                	sd	s5,24(sp)
    80001712:	e85a                	sd	s6,16(sp)
    80001714:	e45e                	sd	s7,8(sp)
    80001716:	e062                	sd	s8,0(sp)
    80001718:	0880                	addi	s0,sp,80
    8000171a:	8baa                	mv	s7,a0
    8000171c:	8aae                	mv	s5,a1
    8000171e:	8932                	mv	s2,a2
    80001720:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001722:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001724:	6b05                	lui	s6,0x1
    80001726:	a035                	j	80001752 <copyin+0x52>
    80001728:	412984b3          	sub	s1,s3,s2
    8000172c:	94da                	add	s1,s1,s6
    if(n > len)
    8000172e:	009a7363          	bgeu	s4,s1,80001734 <copyin+0x34>
    80001732:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001734:	413905b3          	sub	a1,s2,s3
    80001738:	0004861b          	sext.w	a2,s1
    8000173c:	95aa                	add	a1,a1,a0
    8000173e:	8556                	mv	a0,s5
    80001740:	df0ff0ef          	jal	80000d30 <memmove>
    len -= n;
    80001744:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001748:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000174a:	01698933          	add	s2,s3,s6
  while(len > 0){
    8000174e:	020a0163          	beqz	s4,80001770 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001752:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001756:	85ce                	mv	a1,s3
    80001758:	855e                	mv	a0,s7
    8000175a:	891ff0ef          	jal	80000fea <walkaddr>
    if(pa0 == 0) {
    8000175e:	f569                	bnez	a0,80001728 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001760:	4601                	li	a2,0
    80001762:	85ce                	mv	a1,s3
    80001764:	855e                	mv	a0,s7
    80001766:	e35ff0ef          	jal	8000159a <vmfault>
    8000176a:	fd5d                	bnez	a0,80001728 <copyin+0x28>
        return -1;
    8000176c:	557d                	li	a0,-1
    8000176e:	a011                	j	80001772 <copyin+0x72>
  return 0;
    80001770:	4501                	li	a0,0
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret
  return 0;
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret

000000008000178e <proc_mapstacks>:
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl) {
    8000178e:	7139                	addi	sp,sp,-64
    80001790:	fc06                	sd	ra,56(sp)
    80001792:	f822                	sd	s0,48(sp)
    80001794:	f426                	sd	s1,40(sp)
    80001796:	f04a                	sd	s2,32(sp)
    80001798:	ec4e                	sd	s3,24(sp)
    8000179a:	e852                	sd	s4,16(sp)
    8000179c:	e456                	sd	s5,8(sp)
    8000179e:	e05a                	sd	s6,0(sp)
    800017a0:	0080                	addi	s0,sp,64
    800017a2:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++) {
    800017a4:	00011497          	auipc	s1,0x11
    800017a8:	e8448493          	addi	s1,s1,-380 # 80012628 <proc>
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800017ac:	8b26                	mv	s6,s1
    800017ae:	03eb2937          	lui	s2,0x3eb2
    800017b2:	a1f90913          	addi	s2,s2,-1505 # 3eb1a1f <_entry-0x7c14e5e1>
    800017b6:	0932                	slli	s2,s2,0xc
    800017b8:	58d90913          	addi	s2,s2,1421
    800017bc:	0932                	slli	s2,s2,0xc
    800017be:	0fb90913          	addi	s2,s2,251
    800017c2:	0936                	slli	s2,s2,0xd
    800017c4:	8d190913          	addi	s2,s2,-1839
    800017c8:	040009b7          	lui	s3,0x4000
    800017cc:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    800017ce:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++) {
    800017d0:	00017a97          	auipc	s5,0x17
    800017d4:	058a8a93          	addi	s5,s5,88 # 80018828 <tickslock>
    char *pa = kalloc();
    800017d8:	b58ff0ef          	jal	80000b30 <kalloc>
    800017dc:	862a                	mv	a2,a0
    if (pa == 0)
    800017de:	cd15                	beqz	a0,8000181a <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int)(p - proc));
    800017e0:	416485b3          	sub	a1,s1,s6
    800017e4:	858d                	srai	a1,a1,0x3
    800017e6:	032585b3          	mul	a1,a1,s2
    800017ea:	2585                	addiw	a1,a1,1
    800017ec:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017f0:	4719                	li	a4,6
    800017f2:	6685                	lui	a3,0x1
    800017f4:	40b985b3          	sub	a1,s3,a1
    800017f8:	8552                	mv	a0,s4
    800017fa:	8dfff0ef          	jal	800010d8 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++) {
    800017fe:	18848493          	addi	s1,s1,392
    80001802:	fd549be3          	bne	s1,s5,800017d8 <proc_mapstacks+0x4a>
  }
}
    80001806:	70e2                	ld	ra,56(sp)
    80001808:	7442                	ld	s0,48(sp)
    8000180a:	74a2                	ld	s1,40(sp)
    8000180c:	7902                	ld	s2,32(sp)
    8000180e:	69e2                	ld	s3,24(sp)
    80001810:	6a42                	ld	s4,16(sp)
    80001812:	6aa2                	ld	s5,8(sp)
    80001814:	6b02                	ld	s6,0(sp)
    80001816:	6121                	addi	sp,sp,64
    80001818:	8082                	ret
      panic("kalloc");
    8000181a:	00008517          	auipc	a0,0x8
    8000181e:	93650513          	addi	a0,a0,-1738 # 80009150 <etext+0x150>
    80001822:	ff1fe0ef          	jal	80000812 <panic>

0000000080001826 <procinit>:

// initialize the proc table.
void procinit(void) {
    80001826:	7139                	addi	sp,sp,-64
    80001828:	fc06                	sd	ra,56(sp)
    8000182a:	f822                	sd	s0,48(sp)
    8000182c:	f426                	sd	s1,40(sp)
    8000182e:	f04a                	sd	s2,32(sp)
    80001830:	ec4e                	sd	s3,24(sp)
    80001832:	e852                	sd	s4,16(sp)
    80001834:	e456                	sd	s5,8(sp)
    80001836:	e05a                	sd	s6,0(sp)
    80001838:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    8000183a:	00008597          	auipc	a1,0x8
    8000183e:	91e58593          	addi	a1,a1,-1762 # 80009158 <etext+0x158>
    80001842:	00011517          	auipc	a0,0x11
    80001846:	9b650513          	addi	a0,a0,-1610 # 800121f8 <pid_lock>
    8000184a:	b36ff0ef          	jal	80000b80 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000184e:	00008597          	auipc	a1,0x8
    80001852:	91258593          	addi	a1,a1,-1774 # 80009160 <etext+0x160>
    80001856:	00011517          	auipc	a0,0x11
    8000185a:	9ba50513          	addi	a0,a0,-1606 # 80012210 <wait_lock>
    8000185e:	b22ff0ef          	jal	80000b80 <initlock>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001862:	00011497          	auipc	s1,0x11
    80001866:	dc648493          	addi	s1,s1,-570 # 80012628 <proc>
    initlock(&p->lock, "proc");
    8000186a:	00008b17          	auipc	s6,0x8
    8000186e:	906b0b13          	addi	s6,s6,-1786 # 80009170 <etext+0x170>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001872:	8aa6                	mv	s5,s1
    80001874:	03eb2937          	lui	s2,0x3eb2
    80001878:	a1f90913          	addi	s2,s2,-1505 # 3eb1a1f <_entry-0x7c14e5e1>
    8000187c:	0932                	slli	s2,s2,0xc
    8000187e:	58d90913          	addi	s2,s2,1421
    80001882:	0932                	slli	s2,s2,0xc
    80001884:	0fb90913          	addi	s2,s2,251
    80001888:	0936                	slli	s2,s2,0xd
    8000188a:	8d190913          	addi	s2,s2,-1839
    8000188e:	040009b7          	lui	s3,0x4000
    80001892:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001894:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++) {
    80001896:	00017a17          	auipc	s4,0x17
    8000189a:	f92a0a13          	addi	s4,s4,-110 # 80018828 <tickslock>
    initlock(&p->lock, "proc");
    8000189e:	85da                	mv	a1,s6
    800018a0:	8526                	mv	a0,s1
    800018a2:	adeff0ef          	jal	80000b80 <initlock>
    p->state = UNUSED;
    800018a6:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    800018aa:	415487b3          	sub	a5,s1,s5
    800018ae:	878d                	srai	a5,a5,0x3
    800018b0:	032787b3          	mul	a5,a5,s2
    800018b4:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ff98199>
    800018b6:	00d7979b          	slliw	a5,a5,0xd
    800018ba:	40f987b3          	sub	a5,s3,a5
    800018be:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++) {
    800018c0:	18848493          	addi	s1,s1,392
    800018c4:	fd449de3          	bne	s1,s4,8000189e <procinit+0x78>
  }
}
    800018c8:	70e2                	ld	ra,56(sp)
    800018ca:	7442                	ld	s0,48(sp)
    800018cc:	74a2                	ld	s1,40(sp)
    800018ce:	7902                	ld	s2,32(sp)
    800018d0:	69e2                	ld	s3,24(sp)
    800018d2:	6a42                	ld	s4,16(sp)
    800018d4:	6aa2                	ld	s5,8(sp)
    800018d6:	6b02                	ld	s6,0(sp)
    800018d8:	6121                	addi	sp,sp,64
    800018da:	8082                	ret

00000000800018dc <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid() {
    800018dc:	1141                	addi	sp,sp,-16
    800018de:	e422                	sd	s0,8(sp)
    800018e0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018e2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018e4:	2501                	sext.w	a0,a0
    800018e6:	6422                	ld	s0,8(sp)
    800018e8:	0141                	addi	sp,sp,16
    800018ea:	8082                	ret

00000000800018ec <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *mycpu(void) {
    800018ec:	1141                	addi	sp,sp,-16
    800018ee:	e422                	sd	s0,8(sp)
    800018f0:	0800                	addi	s0,sp,16
    800018f2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018f4:	2781                	sext.w	a5,a5
    800018f6:	079e                	slli	a5,a5,0x7
  return c;
}
    800018f8:	00011517          	auipc	a0,0x11
    800018fc:	93050513          	addi	a0,a0,-1744 # 80012228 <cpus>
    80001900:	953e                	add	a0,a0,a5
    80001902:	6422                	ld	s0,8(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret

0000000080001908 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *myproc(void) {
    80001908:	1101                	addi	sp,sp,-32
    8000190a:	ec06                	sd	ra,24(sp)
    8000190c:	e822                	sd	s0,16(sp)
    8000190e:	e426                	sd	s1,8(sp)
    80001910:	1000                	addi	s0,sp,32
  push_off();
    80001912:	aaeff0ef          	jal	80000bc0 <push_off>
    80001916:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001918:	2781                	sext.w	a5,a5
    8000191a:	079e                	slli	a5,a5,0x7
    8000191c:	00011717          	auipc	a4,0x11
    80001920:	8dc70713          	addi	a4,a4,-1828 # 800121f8 <pid_lock>
    80001924:	97ba                	add	a5,a5,a4
    80001926:	7b84                	ld	s1,48(a5)
  pop_off();
    80001928:	b1cff0ef          	jal	80000c44 <pop_off>
  return p;
}
    8000192c:	8526                	mv	a0,s1
    8000192e:	60e2                	ld	ra,24(sp)
    80001930:	6442                	ld	s0,16(sp)
    80001932:	64a2                	ld	s1,8(sp)
    80001934:	6105                	addi	sp,sp,32
    80001936:	8082                	ret

0000000080001938 <forkret>:
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void) {
    80001938:	7179                	addi	sp,sp,-48
    8000193a:	f406                	sd	ra,40(sp)
    8000193c:	f022                	sd	s0,32(sp)
    8000193e:	ec26                	sd	s1,24(sp)
    80001940:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001942:	fc7ff0ef          	jal	80001908 <myproc>
    80001946:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    80001948:	b50ff0ef          	jal	80000c98 <release>

  if (first) {
    8000194c:	00008797          	auipc	a5,0x8
    80001950:	7347a783          	lw	a5,1844(a5) # 8000a080 <first.1>
    80001954:	cf8d                	beqz	a5,8000198e <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    80001956:	4505                	li	a0,1
    80001958:	356020ef          	jal	80003cae <fsinit>

    first = 0;
    8000195c:	00008797          	auipc	a5,0x8
    80001960:	7207a223          	sw	zero,1828(a5) # 8000a080 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    80001964:	0ff0000f          	fence

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){"/init", 0});
    80001968:	00008517          	auipc	a0,0x8
    8000196c:	81050513          	addi	a0,a0,-2032 # 80009178 <etext+0x178>
    80001970:	fca43823          	sd	a0,-48(s0)
    80001974:	fc043c23          	sd	zero,-40(s0)
    80001978:	fd040593          	addi	a1,s0,-48
    8000197c:	43f030ef          	jal	800055ba <kexec>
    80001980:	6cbc                	ld	a5,88(s1)
    80001982:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    80001984:	6cbc                	ld	a5,88(s1)
    80001986:	7bb8                	ld	a4,112(a5)
    80001988:	57fd                	li	a5,-1
    8000198a:	02f70d63          	beq	a4,a5,800019c4 <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    8000198e:	2c5000ef          	jal	80002452 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001992:	68a8                	ld	a0,80(s1)
    80001994:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80001996:	04000737          	lui	a4,0x4000
    8000199a:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000199c:	0732                	slli	a4,a4,0xc
    8000199e:	00006797          	auipc	a5,0x6
    800019a2:	6fe78793          	addi	a5,a5,1790 # 8000809c <userret>
    800019a6:	00006697          	auipc	a3,0x6
    800019aa:	65a68693          	addi	a3,a3,1626 # 80008000 <_trampoline>
    800019ae:	8f95                	sub	a5,a5,a3
    800019b0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800019b2:	577d                	li	a4,-1
    800019b4:	177e                	slli	a4,a4,0x3f
    800019b6:	8d59                	or	a0,a0,a4
    800019b8:	9782                	jalr	a5
}
    800019ba:	70a2                	ld	ra,40(sp)
    800019bc:	7402                	ld	s0,32(sp)
    800019be:	64e2                	ld	s1,24(sp)
    800019c0:	6145                	addi	sp,sp,48
    800019c2:	8082                	ret
      panic("exec");
    800019c4:	00007517          	auipc	a0,0x7
    800019c8:	7bc50513          	addi	a0,a0,1980 # 80009180 <etext+0x180>
    800019cc:	e47fe0ef          	jal	80000812 <panic>

00000000800019d0 <allocpid>:
int allocpid() {
    800019d0:	1101                	addi	sp,sp,-32
    800019d2:	ec06                	sd	ra,24(sp)
    800019d4:	e822                	sd	s0,16(sp)
    800019d6:	e426                	sd	s1,8(sp)
    800019d8:	e04a                	sd	s2,0(sp)
    800019da:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019dc:	00011917          	auipc	s2,0x11
    800019e0:	81c90913          	addi	s2,s2,-2020 # 800121f8 <pid_lock>
    800019e4:	854a                	mv	a0,s2
    800019e6:	a1aff0ef          	jal	80000c00 <acquire>
  pid = nextpid;
    800019ea:	00008797          	auipc	a5,0x8
    800019ee:	69a78793          	addi	a5,a5,1690 # 8000a084 <nextpid>
    800019f2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019f4:	0014871b          	addiw	a4,s1,1
    800019f8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019fa:	854a                	mv	a0,s2
    800019fc:	a9cff0ef          	jal	80000c98 <release>
}
    80001a00:	8526                	mv	a0,s1
    80001a02:	60e2                	ld	ra,24(sp)
    80001a04:	6442                	ld	s0,16(sp)
    80001a06:	64a2                	ld	s1,8(sp)
    80001a08:	6902                	ld	s2,0(sp)
    80001a0a:	6105                	addi	sp,sp,32
    80001a0c:	8082                	ret

0000000080001a0e <proc_pagetable>:
pagetable_t proc_pagetable(struct proc *p) {
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	e04a                	sd	s2,0(sp)
    80001a18:	1000                	addi	s0,sp,32
    80001a1a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a1c:	fb2ff0ef          	jal	800011ce <uvmcreate>
    80001a20:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a22:	cd05                	beqz	a0,80001a5a <proc_pagetable+0x4c>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline,
    80001a24:	4729                	li	a4,10
    80001a26:	00006697          	auipc	a3,0x6
    80001a2a:	5da68693          	addi	a3,a3,1498 # 80008000 <_trampoline>
    80001a2e:	6605                	lui	a2,0x1
    80001a30:	040005b7          	lui	a1,0x4000
    80001a34:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a36:	05b2                	slli	a1,a1,0xc
    80001a38:	df0ff0ef          	jal	80001028 <mappages>
    80001a3c:	02054663          	bltz	a0,80001a68 <proc_pagetable+0x5a>
  if (mappages(pagetable, TRAPFRAME, PGSIZE, (uint64)(p->trapframe),
    80001a40:	4719                	li	a4,6
    80001a42:	05893683          	ld	a3,88(s2)
    80001a46:	6605                	lui	a2,0x1
    80001a48:	020005b7          	lui	a1,0x2000
    80001a4c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a4e:	05b6                	slli	a1,a1,0xd
    80001a50:	8526                	mv	a0,s1
    80001a52:	dd6ff0ef          	jal	80001028 <mappages>
    80001a56:	00054f63          	bltz	a0,80001a74 <proc_pagetable+0x66>
}
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	60e2                	ld	ra,24(sp)
    80001a5e:	6442                	ld	s0,16(sp)
    80001a60:	64a2                	ld	s1,8(sp)
    80001a62:	6902                	ld	s2,0(sp)
    80001a64:	6105                	addi	sp,sp,32
    80001a66:	8082                	ret
    uvmfree(pagetable, 0);
    80001a68:	4581                	li	a1,0
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	95dff0ef          	jal	800013c8 <uvmfree>
    return 0;
    80001a70:	4481                	li	s1,0
    80001a72:	b7e5                	j	80001a5a <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a74:	4681                	li	a3,0
    80001a76:	4605                	li	a2,1
    80001a78:	040005b7          	lui	a1,0x4000
    80001a7c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a7e:	05b2                	slli	a1,a1,0xc
    80001a80:	8526                	mv	a0,s1
    80001a82:	f72ff0ef          	jal	800011f4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a86:	4581                	li	a1,0
    80001a88:	8526                	mv	a0,s1
    80001a8a:	93fff0ef          	jal	800013c8 <uvmfree>
    return 0;
    80001a8e:	4481                	li	s1,0
    80001a90:	b7e9                	j	80001a5a <proc_pagetable+0x4c>

0000000080001a92 <proc_freepagetable>:
void proc_freepagetable(pagetable_t pagetable, uint64 sz) {
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	e04a                	sd	s2,0(sp)
    80001a9c:	1000                	addi	s0,sp,32
    80001a9e:	84aa                	mv	s1,a0
    80001aa0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aa2:	4681                	li	a3,0
    80001aa4:	4605                	li	a2,1
    80001aa6:	040005b7          	lui	a1,0x4000
    80001aaa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aac:	05b2                	slli	a1,a1,0xc
    80001aae:	f46ff0ef          	jal	800011f4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ab2:	4681                	li	a3,0
    80001ab4:	4605                	li	a2,1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	f34ff0ef          	jal	800011f4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ac4:	85ca                	mv	a1,s2
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	901ff0ef          	jal	800013c8 <uvmfree>
}
    80001acc:	60e2                	ld	ra,24(sp)
    80001ace:	6442                	ld	s0,16(sp)
    80001ad0:	64a2                	ld	s1,8(sp)
    80001ad2:	6902                	ld	s2,0(sp)
    80001ad4:	6105                	addi	sp,sp,32
    80001ad6:	8082                	ret

0000000080001ad8 <freeproc>:
static void freeproc(struct proc *p) {
    80001ad8:	1101                	addi	sp,sp,-32
    80001ada:	ec06                	sd	ra,24(sp)
    80001adc:	e822                	sd	s0,16(sp)
    80001ade:	e426                	sd	s1,8(sp)
    80001ae0:	1000                	addi	s0,sp,32
    80001ae2:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001ae4:	6d28                	ld	a0,88(a0)
    80001ae6:	c119                	beqz	a0,80001aec <freeproc+0x14>
    kfree((void *)p->trapframe);
    80001ae8:	f67fe0ef          	jal	80000a4e <kfree>
  p->trapframe = 0;
    80001aec:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001af0:	68a8                	ld	a0,80(s1)
    80001af2:	c501                	beqz	a0,80001afa <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001af4:	64ac                	ld	a1,72(s1)
    80001af6:	f9dff0ef          	jal	80001a92 <proc_freepagetable>
  p->pagetable = 0;
    80001afa:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001afe:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b02:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b06:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b0a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b0e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b12:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b16:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b1a:	0004ac23          	sw	zero,24(s1)
}
    80001b1e:	60e2                	ld	ra,24(sp)
    80001b20:	6442                	ld	s0,16(sp)
    80001b22:	64a2                	ld	s1,8(sp)
    80001b24:	6105                	addi	sp,sp,32
    80001b26:	8082                	ret

0000000080001b28 <allocproc>:
static struct proc *allocproc(void) {
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++) {
    80001b34:	00011497          	auipc	s1,0x11
    80001b38:	af448493          	addi	s1,s1,-1292 # 80012628 <proc>
    80001b3c:	00017917          	auipc	s2,0x17
    80001b40:	cec90913          	addi	s2,s2,-788 # 80018828 <tickslock>
    acquire(&p->lock);
    80001b44:	8526                	mv	a0,s1
    80001b46:	8baff0ef          	jal	80000c00 <acquire>
    if (p->state == UNUSED) {
    80001b4a:	4c9c                	lw	a5,24(s1)
    80001b4c:	cb91                	beqz	a5,80001b60 <allocproc+0x38>
      release(&p->lock);
    80001b4e:	8526                	mv	a0,s1
    80001b50:	948ff0ef          	jal	80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001b54:	18848493          	addi	s1,s1,392
    80001b58:	ff2496e3          	bne	s1,s2,80001b44 <allocproc+0x1c>
  return 0;
    80001b5c:	4481                	li	s1,0
    80001b5e:	a089                	j	80001ba0 <allocproc+0x78>
  p->pid = allocpid();
    80001b60:	e71ff0ef          	jal	800019d0 <allocpid>
    80001b64:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b66:	4785                	li	a5,1
    80001b68:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0) {
    80001b6a:	fc7fe0ef          	jal	80000b30 <kalloc>
    80001b6e:	892a                	mv	s2,a0
    80001b70:	eca8                	sd	a0,88(s1)
    80001b72:	cd15                	beqz	a0,80001bae <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001b74:	8526                	mv	a0,s1
    80001b76:	e99ff0ef          	jal	80001a0e <proc_pagetable>
    80001b7a:	892a                	mv	s2,a0
    80001b7c:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0) {
    80001b7e:	c121                	beqz	a0,80001bbe <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001b80:	07000613          	li	a2,112
    80001b84:	4581                	li	a1,0
    80001b86:	06048513          	addi	a0,s1,96
    80001b8a:	94aff0ef          	jal	80000cd4 <memset>
  p->context.ra = (uint64)forkret;
    80001b8e:	00000797          	auipc	a5,0x0
    80001b92:	daa78793          	addi	a5,a5,-598 # 80001938 <forkret>
    80001b96:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b98:	60bc                	ld	a5,64(s1)
    80001b9a:	6705                	lui	a4,0x1
    80001b9c:	97ba                	add	a5,a5,a4
    80001b9e:	f4bc                	sd	a5,104(s1)
}
    80001ba0:	8526                	mv	a0,s1
    80001ba2:	60e2                	ld	ra,24(sp)
    80001ba4:	6442                	ld	s0,16(sp)
    80001ba6:	64a2                	ld	s1,8(sp)
    80001ba8:	6902                	ld	s2,0(sp)
    80001baa:	6105                	addi	sp,sp,32
    80001bac:	8082                	ret
    freeproc(p);
    80001bae:	8526                	mv	a0,s1
    80001bb0:	f29ff0ef          	jal	80001ad8 <freeproc>
    release(&p->lock);
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	8e2ff0ef          	jal	80000c98 <release>
    return 0;
    80001bba:	84ca                	mv	s1,s2
    80001bbc:	b7d5                	j	80001ba0 <allocproc+0x78>
    freeproc(p);
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	f19ff0ef          	jal	80001ad8 <freeproc>
    release(&p->lock);
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	8d2ff0ef          	jal	80000c98 <release>
    return 0;
    80001bca:	84ca                	mv	s1,s2
    80001bcc:	bfd1                	j	80001ba0 <allocproc+0x78>

0000000080001bce <userinit>:
void userinit(void) {
    80001bce:	1101                	addi	sp,sp,-32
    80001bd0:	ec06                	sd	ra,24(sp)
    80001bd2:	e822                	sd	s0,16(sp)
    80001bd4:	e426                	sd	s1,8(sp)
    80001bd6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001bd8:	f51ff0ef          	jal	80001b28 <allocproc>
    80001bdc:	84aa                	mv	s1,a0
  initproc = p;
    80001bde:	00008797          	auipc	a5,0x8
    80001be2:	4ca7b923          	sd	a0,1234(a5) # 8000a0b0 <initproc>
  p->cwd = namei("/");
    80001be6:	00007517          	auipc	a0,0x7
    80001bea:	5a250513          	addi	a0,a0,1442 # 80009188 <etext+0x188>
    80001bee:	75e020ef          	jal	8000434c <namei>
    80001bf2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001bf6:	478d                	li	a5,3
    80001bf8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	89cff0ef          	jal	80000c98 <release>
}
    80001c00:	60e2                	ld	ra,24(sp)
    80001c02:	6442                	ld	s0,16(sp)
    80001c04:	64a2                	ld	s1,8(sp)
    80001c06:	6105                	addi	sp,sp,32
    80001c08:	8082                	ret

0000000080001c0a <growproc>:
int growproc(int n) {
    80001c0a:	1101                	addi	sp,sp,-32
    80001c0c:	ec06                	sd	ra,24(sp)
    80001c0e:	e822                	sd	s0,16(sp)
    80001c10:	e426                	sd	s1,8(sp)
    80001c12:	e04a                	sd	s2,0(sp)
    80001c14:	1000                	addi	s0,sp,32
    80001c16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001c18:	cf1ff0ef          	jal	80001908 <myproc>
    80001c1c:	892a                	mv	s2,a0
  sz = p->sz;
    80001c1e:	652c                	ld	a1,72(a0)
  if (n > 0) {
    80001c20:	02905963          	blez	s1,80001c52 <growproc+0x48>
    if (sz + n > TRAPFRAME) {
    80001c24:	00b48633          	add	a2,s1,a1
    80001c28:	020007b7          	lui	a5,0x2000
    80001c2c:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001c2e:	07b6                	slli	a5,a5,0xd
    80001c30:	02c7ea63          	bltu	a5,a2,80001c64 <growproc+0x5a>
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c34:	4691                	li	a3,4
    80001c36:	6928                	ld	a0,80(a0)
    80001c38:	e8aff0ef          	jal	800012c2 <uvmalloc>
    80001c3c:	85aa                	mv	a1,a0
    80001c3e:	c50d                	beqz	a0,80001c68 <growproc+0x5e>
  p->sz = sz;
    80001c40:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c44:	4501                	li	a0,0
}
    80001c46:	60e2                	ld	ra,24(sp)
    80001c48:	6442                	ld	s0,16(sp)
    80001c4a:	64a2                	ld	s1,8(sp)
    80001c4c:	6902                	ld	s2,0(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret
  } else if (n < 0) {
    80001c52:	fe04d7e3          	bgez	s1,80001c40 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c56:	00b48633          	add	a2,s1,a1
    80001c5a:	6928                	ld	a0,80(a0)
    80001c5c:	e22ff0ef          	jal	8000127e <uvmdealloc>
    80001c60:	85aa                	mv	a1,a0
    80001c62:	bff9                	j	80001c40 <growproc+0x36>
      return -1;
    80001c64:	557d                	li	a0,-1
    80001c66:	b7c5                	j	80001c46 <growproc+0x3c>
      return -1;
    80001c68:	557d                	li	a0,-1
    80001c6a:	bff1                	j	80001c46 <growproc+0x3c>

0000000080001c6c <kfork>:
int kfork(void) {
    80001c6c:	7139                	addi	sp,sp,-64
    80001c6e:	fc06                	sd	ra,56(sp)
    80001c70:	f822                	sd	s0,48(sp)
    80001c72:	f04a                	sd	s2,32(sp)
    80001c74:	e456                	sd	s5,8(sp)
    80001c76:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c78:	c91ff0ef          	jal	80001908 <myproc>
    80001c7c:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0) {
    80001c7e:	eabff0ef          	jal	80001b28 <allocproc>
    80001c82:	0e050a63          	beqz	a0,80001d76 <kfork+0x10a>
    80001c86:	e852                	sd	s4,16(sp)
    80001c88:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0) {
    80001c8a:	048ab603          	ld	a2,72(s5)
    80001c8e:	692c                	ld	a1,80(a0)
    80001c90:	050ab503          	ld	a0,80(s5)
    80001c94:	f66ff0ef          	jal	800013fa <uvmcopy>
    80001c98:	04054a63          	bltz	a0,80001cec <kfork+0x80>
    80001c9c:	f426                	sd	s1,40(sp)
    80001c9e:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001ca0:	048ab783          	ld	a5,72(s5)
    80001ca4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001ca8:	058ab683          	ld	a3,88(s5)
    80001cac:	87b6                	mv	a5,a3
    80001cae:	058a3703          	ld	a4,88(s4)
    80001cb2:	12068693          	addi	a3,a3,288
    80001cb6:	0007b803          	ld	a6,0(a5)
    80001cba:	6788                	ld	a0,8(a5)
    80001cbc:	6b8c                	ld	a1,16(a5)
    80001cbe:	6f90                	ld	a2,24(a5)
    80001cc0:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001cc4:	e708                	sd	a0,8(a4)
    80001cc6:	eb0c                	sd	a1,16(a4)
    80001cc8:	ef10                	sd	a2,24(a4)
    80001cca:	02078793          	addi	a5,a5,32
    80001cce:	02070713          	addi	a4,a4,32
    80001cd2:	fed792e3          	bne	a5,a3,80001cb6 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001cd6:	058a3783          	ld	a5,88(s4)
    80001cda:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001cde:	0d0a8493          	addi	s1,s5,208
    80001ce2:	0d0a0913          	addi	s2,s4,208
    80001ce6:	150a8993          	addi	s3,s5,336
    80001cea:	a831                	j	80001d06 <kfork+0x9a>
    freeproc(np);
    80001cec:	8552                	mv	a0,s4
    80001cee:	debff0ef          	jal	80001ad8 <freeproc>
    release(&np->lock);
    80001cf2:	8552                	mv	a0,s4
    80001cf4:	fa5fe0ef          	jal	80000c98 <release>
    return -1;
    80001cf8:	597d                	li	s2,-1
    80001cfa:	6a42                	ld	s4,16(sp)
    80001cfc:	a0b5                	j	80001d68 <kfork+0xfc>
  for (i = 0; i < NOFILE; i++)
    80001cfe:	04a1                	addi	s1,s1,8
    80001d00:	0921                	addi	s2,s2,8
    80001d02:	01348963          	beq	s1,s3,80001d14 <kfork+0xa8>
    if (p->ofile[i])
    80001d06:	6088                	ld	a0,0(s1)
    80001d08:	d97d                	beqz	a0,80001cfe <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001d0a:	1b6030ef          	jal	80004ec0 <filedup>
    80001d0e:	00a93023          	sd	a0,0(s2)
    80001d12:	b7f5                	j	80001cfe <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001d14:	150ab503          	ld	a0,336(s5)
    80001d18:	379010ef          	jal	80003890 <idup>
    80001d1c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001d20:	4641                	li	a2,16
    80001d22:	158a8593          	addi	a1,s5,344
    80001d26:	158a0513          	addi	a0,s4,344
    80001d2a:	8e8ff0ef          	jal	80000e12 <safestrcpy>
  pid = np->pid;
    80001d2e:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001d32:	8552                	mv	a0,s4
    80001d34:	f65fe0ef          	jal	80000c98 <release>
  acquire(&wait_lock);
    80001d38:	00010497          	auipc	s1,0x10
    80001d3c:	4d848493          	addi	s1,s1,1240 # 80012210 <wait_lock>
    80001d40:	8526                	mv	a0,s1
    80001d42:	ebffe0ef          	jal	80000c00 <acquire>
  np->parent = p;
    80001d46:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d4a:	8526                	mv	a0,s1
    80001d4c:	f4dfe0ef          	jal	80000c98 <release>
  acquire(&np->lock);
    80001d50:	8552                	mv	a0,s4
    80001d52:	eaffe0ef          	jal	80000c00 <acquire>
  np->state = RUNNABLE;
    80001d56:	478d                	li	a5,3
    80001d58:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d5c:	8552                	mv	a0,s4
    80001d5e:	f3bfe0ef          	jal	80000c98 <release>
  return pid;
    80001d62:	74a2                	ld	s1,40(sp)
    80001d64:	69e2                	ld	s3,24(sp)
    80001d66:	6a42                	ld	s4,16(sp)
}
    80001d68:	854a                	mv	a0,s2
    80001d6a:	70e2                	ld	ra,56(sp)
    80001d6c:	7442                	ld	s0,48(sp)
    80001d6e:	7902                	ld	s2,32(sp)
    80001d70:	6aa2                	ld	s5,8(sp)
    80001d72:	6121                	addi	sp,sp,64
    80001d74:	8082                	ret
    return -1;
    80001d76:	597d                	li	s2,-1
    80001d78:	bfc5                	j	80001d68 <kfork+0xfc>

0000000080001d7a <scheduler>:
void scheduler(void) {
    80001d7a:	715d                	addi	sp,sp,-80
    80001d7c:	e486                	sd	ra,72(sp)
    80001d7e:	e0a2                	sd	s0,64(sp)
    80001d80:	fc26                	sd	s1,56(sp)
    80001d82:	f84a                	sd	s2,48(sp)
    80001d84:	f44e                	sd	s3,40(sp)
    80001d86:	f052                	sd	s4,32(sp)
    80001d88:	ec56                	sd	s5,24(sp)
    80001d8a:	e85a                	sd	s6,16(sp)
    80001d8c:	e45e                	sd	s7,8(sp)
    80001d8e:	e062                	sd	s8,0(sp)
    80001d90:	0880                	addi	s0,sp,80
    80001d92:	8792                	mv	a5,tp
  int id = r_tp();
    80001d94:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d96:	00779b13          	slli	s6,a5,0x7
    80001d9a:	00010717          	auipc	a4,0x10
    80001d9e:	45e70713          	addi	a4,a4,1118 # 800121f8 <pid_lock>
    80001da2:	975a                	add	a4,a4,s6
    80001da4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001da8:	00010717          	auipc	a4,0x10
    80001dac:	48870713          	addi	a4,a4,1160 # 80012230 <cpus+0x8>
    80001db0:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001db2:	4c11                	li	s8,4
        c->proc = p;
    80001db4:	079e                	slli	a5,a5,0x7
    80001db6:	00010a17          	auipc	s4,0x10
    80001dba:	442a0a13          	addi	s4,s4,1090 # 800121f8 <pid_lock>
    80001dbe:	9a3e                	add	s4,s4,a5
        found = 1;
    80001dc0:	4b85                	li	s7,1
    for (p = proc; p < &proc[NPROC]; p++) {
    80001dc2:	00017997          	auipc	s3,0x17
    80001dc6:	a6698993          	addi	s3,s3,-1434 # 80018828 <tickslock>
    80001dca:	a091                	j	80001e0e <scheduler+0x94>
      release(&p->lock);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	ecbfe0ef          	jal	80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80001dd2:	18848493          	addi	s1,s1,392
    80001dd6:	03348863          	beq	s1,s3,80001e06 <scheduler+0x8c>
      acquire(&p->lock);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	e25fe0ef          	jal	80000c00 <acquire>
      if (p->state == RUNNABLE) {
    80001de0:	4c9c                	lw	a5,24(s1)
    80001de2:	ff2795e3          	bne	a5,s2,80001dcc <scheduler+0x52>
        p->state = RUNNING;
    80001de6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001dea:	029a3823          	sd	s1,48(s4)
        cslog_run_start(p);
    80001dee:	8526                	mv	a0,s1
    80001df0:	575040ef          	jal	80006b64 <cslog_run_start>
        swtch(&c->context, &p->context);
    80001df4:	06048593          	addi	a1,s1,96
    80001df8:	855a                	mv	a0,s6
    80001dfa:	5b2000ef          	jal	800023ac <swtch>
        c->proc = 0;
    80001dfe:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001e02:	8ade                	mv	s5,s7
    80001e04:	b7e1                	j	80001dcc <scheduler+0x52>
    if (found == 0) {
    80001e06:	000a9463          	bnez	s5,80001e0e <scheduler+0x94>
      asm volatile("wfi");
    80001e0a:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e12:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e16:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001e1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e20:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001e24:	4a81                	li	s5,0
    for (p = proc; p < &proc[NPROC]; p++) {
    80001e26:	00011497          	auipc	s1,0x11
    80001e2a:	80248493          	addi	s1,s1,-2046 # 80012628 <proc>
      if (p->state == RUNNABLE) {
    80001e2e:	490d                	li	s2,3
    80001e30:	b76d                	j	80001dda <scheduler+0x60>

0000000080001e32 <sched>:
void sched(void) {
    80001e32:	7179                	addi	sp,sp,-48
    80001e34:	f406                	sd	ra,40(sp)
    80001e36:	f022                	sd	s0,32(sp)
    80001e38:	ec26                	sd	s1,24(sp)
    80001e3a:	e84a                	sd	s2,16(sp)
    80001e3c:	e44e                	sd	s3,8(sp)
    80001e3e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e40:	ac9ff0ef          	jal	80001908 <myproc>
    80001e44:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001e46:	d51fe0ef          	jal	80000b96 <holding>
    80001e4a:	c92d                	beqz	a0,80001ebc <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e4c:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001e4e:	2781                	sext.w	a5,a5
    80001e50:	079e                	slli	a5,a5,0x7
    80001e52:	00010717          	auipc	a4,0x10
    80001e56:	3a670713          	addi	a4,a4,934 # 800121f8 <pid_lock>
    80001e5a:	97ba                	add	a5,a5,a4
    80001e5c:	0a87a703          	lw	a4,168(a5)
    80001e60:	4785                	li	a5,1
    80001e62:	06f71363          	bne	a4,a5,80001ec8 <sched+0x96>
  if (p->state == RUNNING)
    80001e66:	4c98                	lw	a4,24(s1)
    80001e68:	4791                	li	a5,4
    80001e6a:	06f70563          	beq	a4,a5,80001ed4 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e72:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001e74:	e7b5                	bnez	a5,80001ee0 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e76:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e78:	00010917          	auipc	s2,0x10
    80001e7c:	38090913          	addi	s2,s2,896 # 800121f8 <pid_lock>
    80001e80:	2781                	sext.w	a5,a5
    80001e82:	079e                	slli	a5,a5,0x7
    80001e84:	97ca                	add	a5,a5,s2
    80001e86:	0ac7a983          	lw	s3,172(a5)
    80001e8a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e8c:	2781                	sext.w	a5,a5
    80001e8e:	079e                	slli	a5,a5,0x7
    80001e90:	00010597          	auipc	a1,0x10
    80001e94:	3a058593          	addi	a1,a1,928 # 80012230 <cpus+0x8>
    80001e98:	95be                	add	a1,a1,a5
    80001e9a:	06048513          	addi	a0,s1,96
    80001e9e:	50e000ef          	jal	800023ac <swtch>
    80001ea2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ea4:	2781                	sext.w	a5,a5
    80001ea6:	079e                	slli	a5,a5,0x7
    80001ea8:	993e                	add	s2,s2,a5
    80001eaa:	0b392623          	sw	s3,172(s2)
}
    80001eae:	70a2                	ld	ra,40(sp)
    80001eb0:	7402                	ld	s0,32(sp)
    80001eb2:	64e2                	ld	s1,24(sp)
    80001eb4:	6942                	ld	s2,16(sp)
    80001eb6:	69a2                	ld	s3,8(sp)
    80001eb8:	6145                	addi	sp,sp,48
    80001eba:	8082                	ret
    panic("sched p->lock");
    80001ebc:	00007517          	auipc	a0,0x7
    80001ec0:	2d450513          	addi	a0,a0,724 # 80009190 <etext+0x190>
    80001ec4:	94ffe0ef          	jal	80000812 <panic>
    panic("sched locks");
    80001ec8:	00007517          	auipc	a0,0x7
    80001ecc:	2d850513          	addi	a0,a0,728 # 800091a0 <etext+0x1a0>
    80001ed0:	943fe0ef          	jal	80000812 <panic>
    panic("sched RUNNING");
    80001ed4:	00007517          	auipc	a0,0x7
    80001ed8:	2dc50513          	addi	a0,a0,732 # 800091b0 <etext+0x1b0>
    80001edc:	937fe0ef          	jal	80000812 <panic>
    panic("sched interruptible");
    80001ee0:	00007517          	auipc	a0,0x7
    80001ee4:	2e050513          	addi	a0,a0,736 # 800091c0 <etext+0x1c0>
    80001ee8:	92bfe0ef          	jal	80000812 <panic>

0000000080001eec <yield>:
void yield(void) {
    80001eec:	1101                	addi	sp,sp,-32
    80001eee:	ec06                	sd	ra,24(sp)
    80001ef0:	e822                	sd	s0,16(sp)
    80001ef2:	e426                	sd	s1,8(sp)
    80001ef4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001ef6:	a13ff0ef          	jal	80001908 <myproc>
    80001efa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001efc:	d05fe0ef          	jal	80000c00 <acquire>
  p->state = RUNNABLE;
    80001f00:	478d                	li	a5,3
    80001f02:	cc9c                	sw	a5,24(s1)
  sched();
    80001f04:	f2fff0ef          	jal	80001e32 <sched>
  release(&p->lock);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	d8ffe0ef          	jal	80000c98 <release>
}
    80001f0e:	60e2                	ld	ra,24(sp)
    80001f10:	6442                	ld	s0,16(sp)
    80001f12:	64a2                	ld	s1,8(sp)
    80001f14:	6105                	addi	sp,sp,32
    80001f16:	8082                	ret

0000000080001f18 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void sleep(void *chan, struct spinlock *lk) {
    80001f18:	7179                	addi	sp,sp,-48
    80001f1a:	f406                	sd	ra,40(sp)
    80001f1c:	f022                	sd	s0,32(sp)
    80001f1e:	ec26                	sd	s1,24(sp)
    80001f20:	e84a                	sd	s2,16(sp)
    80001f22:	e44e                	sd	s3,8(sp)
    80001f24:	1800                	addi	s0,sp,48
    80001f26:	89aa                	mv	s3,a0
    80001f28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f2a:	9dfff0ef          	jal	80001908 <myproc>
    80001f2e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80001f30:	cd1fe0ef          	jal	80000c00 <acquire>
  release(lk);
    80001f34:	854a                	mv	a0,s2
    80001f36:	d63fe0ef          	jal	80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80001f3a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001f3e:	4789                	li	a5,2
    80001f40:	cc9c                	sw	a5,24(s1)

  sched();
    80001f42:	ef1ff0ef          	jal	80001e32 <sched>

  // Tidy up.
  p->chan = 0;
    80001f46:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	d4dfe0ef          	jal	80000c98 <release>
  acquire(lk);
    80001f50:	854a                	mv	a0,s2
    80001f52:	caffe0ef          	jal	80000c00 <acquire>
}
    80001f56:	70a2                	ld	ra,40(sp)
    80001f58:	7402                	ld	s0,32(sp)
    80001f5a:	64e2                	ld	s1,24(sp)
    80001f5c:	6942                	ld	s2,16(sp)
    80001f5e:	69a2                	ld	s3,8(sp)
    80001f60:	6145                	addi	sp,sp,48
    80001f62:	8082                	ret

0000000080001f64 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void wakeup(void *chan) {
    80001f64:	7139                	addi	sp,sp,-64
    80001f66:	fc06                	sd	ra,56(sp)
    80001f68:	f822                	sd	s0,48(sp)
    80001f6a:	f426                	sd	s1,40(sp)
    80001f6c:	f04a                	sd	s2,32(sp)
    80001f6e:	ec4e                	sd	s3,24(sp)
    80001f70:	e852                	sd	s4,16(sp)
    80001f72:	e456                	sd	s5,8(sp)
    80001f74:	0080                	addi	s0,sp,64
    80001f76:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++) {
    80001f78:	00010497          	auipc	s1,0x10
    80001f7c:	6b048493          	addi	s1,s1,1712 # 80012628 <proc>
    if (p != myproc()) {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan) {
    80001f80:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001f82:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f84:	00017917          	auipc	s2,0x17
    80001f88:	8a490913          	addi	s2,s2,-1884 # 80018828 <tickslock>
    80001f8c:	a801                	j	80001f9c <wakeup+0x38>
      }
      release(&p->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	d09fe0ef          	jal	80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f94:	18848493          	addi	s1,s1,392
    80001f98:	03248263          	beq	s1,s2,80001fbc <wakeup+0x58>
    if (p != myproc()) {
    80001f9c:	96dff0ef          	jal	80001908 <myproc>
    80001fa0:	fea48ae3          	beq	s1,a0,80001f94 <wakeup+0x30>
      acquire(&p->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	c5bfe0ef          	jal	80000c00 <acquire>
      if (p->state == SLEEPING && p->chan == chan) {
    80001faa:	4c9c                	lw	a5,24(s1)
    80001fac:	ff3791e3          	bne	a5,s3,80001f8e <wakeup+0x2a>
    80001fb0:	709c                	ld	a5,32(s1)
    80001fb2:	fd479ee3          	bne	a5,s4,80001f8e <wakeup+0x2a>
        p->state = RUNNABLE;
    80001fb6:	0154ac23          	sw	s5,24(s1)
    80001fba:	bfd1                	j	80001f8e <wakeup+0x2a>
    }
  }
}
    80001fbc:	70e2                	ld	ra,56(sp)
    80001fbe:	7442                	ld	s0,48(sp)
    80001fc0:	74a2                	ld	s1,40(sp)
    80001fc2:	7902                	ld	s2,32(sp)
    80001fc4:	69e2                	ld	s3,24(sp)
    80001fc6:	6a42                	ld	s4,16(sp)
    80001fc8:	6aa2                	ld	s5,8(sp)
    80001fca:	6121                	addi	sp,sp,64
    80001fcc:	8082                	ret

0000000080001fce <reparent>:
void reparent(struct proc *p) {
    80001fce:	7179                	addi	sp,sp,-48
    80001fd0:	f406                	sd	ra,40(sp)
    80001fd2:	f022                	sd	s0,32(sp)
    80001fd4:	ec26                	sd	s1,24(sp)
    80001fd6:	e84a                	sd	s2,16(sp)
    80001fd8:	e44e                	sd	s3,8(sp)
    80001fda:	e052                	sd	s4,0(sp)
    80001fdc:	1800                	addi	s0,sp,48
    80001fde:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    80001fe0:	00010497          	auipc	s1,0x10
    80001fe4:	64848493          	addi	s1,s1,1608 # 80012628 <proc>
      pp->parent = initproc;
    80001fe8:	00008a17          	auipc	s4,0x8
    80001fec:	0c8a0a13          	addi	s4,s4,200 # 8000a0b0 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    80001ff0:	00017997          	auipc	s3,0x17
    80001ff4:	83898993          	addi	s3,s3,-1992 # 80018828 <tickslock>
    80001ff8:	a029                	j	80002002 <reparent+0x34>
    80001ffa:	18848493          	addi	s1,s1,392
    80001ffe:	01348b63          	beq	s1,s3,80002014 <reparent+0x46>
    if (pp->parent == p) {
    80002002:	7c9c                	ld	a5,56(s1)
    80002004:	ff279be3          	bne	a5,s2,80001ffa <reparent+0x2c>
      pp->parent = initproc;
    80002008:	000a3503          	ld	a0,0(s4)
    8000200c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000200e:	f57ff0ef          	jal	80001f64 <wakeup>
    80002012:	b7e5                	j	80001ffa <reparent+0x2c>
}
    80002014:	70a2                	ld	ra,40(sp)
    80002016:	7402                	ld	s0,32(sp)
    80002018:	64e2                	ld	s1,24(sp)
    8000201a:	6942                	ld	s2,16(sp)
    8000201c:	69a2                	ld	s3,8(sp)
    8000201e:	6a02                	ld	s4,0(sp)
    80002020:	6145                	addi	sp,sp,48
    80002022:	8082                	ret

0000000080002024 <kexit>:
void kexit(int status) {
    80002024:	7179                	addi	sp,sp,-48
    80002026:	f406                	sd	ra,40(sp)
    80002028:	f022                	sd	s0,32(sp)
    8000202a:	ec26                	sd	s1,24(sp)
    8000202c:	e84a                	sd	s2,16(sp)
    8000202e:	e44e                	sd	s3,8(sp)
    80002030:	e052                	sd	s4,0(sp)
    80002032:	1800                	addi	s0,sp,48
    80002034:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002036:	8d3ff0ef          	jal	80001908 <myproc>
    8000203a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000203c:	00008797          	auipc	a5,0x8
    80002040:	0747b783          	ld	a5,116(a5) # 8000a0b0 <initproc>
    80002044:	0d050493          	addi	s1,a0,208
    80002048:	15050913          	addi	s2,a0,336
    8000204c:	00a79f63          	bne	a5,a0,8000206a <kexit+0x46>
    panic("init exiting");
    80002050:	00007517          	auipc	a0,0x7
    80002054:	18850513          	addi	a0,a0,392 # 800091d8 <etext+0x1d8>
    80002058:	fbafe0ef          	jal	80000812 <panic>
      fileclose(f);
    8000205c:	6c5020ef          	jal	80004f20 <fileclose>
      p->ofile[fd] = 0;
    80002060:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++) {
    80002064:	04a1                	addi	s1,s1,8
    80002066:	01248563          	beq	s1,s2,80002070 <kexit+0x4c>
    if (p->ofile[fd]) {
    8000206a:	6088                	ld	a0,0(s1)
    8000206c:	f965                	bnez	a0,8000205c <kexit+0x38>
    8000206e:	bfdd                	j	80002064 <kexit+0x40>
  begin_op();
    80002070:	726020ef          	jal	80004796 <begin_op>
  iput(p->cwd);
    80002074:	1509b503          	ld	a0,336(s3)
    80002078:	281010ef          	jal	80003af8 <iput>
  end_op();
    8000207c:	039020ef          	jal	800048b4 <end_op>
  p->cwd = 0;
    80002080:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002084:	00010497          	auipc	s1,0x10
    80002088:	18c48493          	addi	s1,s1,396 # 80012210 <wait_lock>
    8000208c:	8526                	mv	a0,s1
    8000208e:	b73fe0ef          	jal	80000c00 <acquire>
  reparent(p);
    80002092:	854e                	mv	a0,s3
    80002094:	f3bff0ef          	jal	80001fce <reparent>
  wakeup(p->parent);
    80002098:	0389b503          	ld	a0,56(s3)
    8000209c:	ec9ff0ef          	jal	80001f64 <wakeup>
  acquire(&p->lock);
    800020a0:	854e                	mv	a0,s3
    800020a2:	b5ffe0ef          	jal	80000c00 <acquire>
  p->xstate = status;
    800020a6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800020aa:	4795                	li	a5,5
    800020ac:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800020b0:	8526                	mv	a0,s1
    800020b2:	be7fe0ef          	jal	80000c98 <release>
  sched();
    800020b6:	d7dff0ef          	jal	80001e32 <sched>
  panic("zombie exit");
    800020ba:	00007517          	auipc	a0,0x7
    800020be:	12e50513          	addi	a0,a0,302 # 800091e8 <etext+0x1e8>
    800020c2:	f50fe0ef          	jal	80000812 <panic>

00000000800020c6 <kkill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kkill(int pid) {
    800020c6:	7179                	addi	sp,sp,-48
    800020c8:	f406                	sd	ra,40(sp)
    800020ca:	f022                	sd	s0,32(sp)
    800020cc:	ec26                	sd	s1,24(sp)
    800020ce:	e84a                	sd	s2,16(sp)
    800020d0:	e44e                	sd	s3,8(sp)
    800020d2:	1800                	addi	s0,sp,48
    800020d4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++) {
    800020d6:	00010497          	auipc	s1,0x10
    800020da:	55248493          	addi	s1,s1,1362 # 80012628 <proc>
    800020de:	00016997          	auipc	s3,0x16
    800020e2:	74a98993          	addi	s3,s3,1866 # 80018828 <tickslock>
    acquire(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	b19fe0ef          	jal	80000c00 <acquire>
    if (p->pid == pid) {
    800020ec:	589c                	lw	a5,48(s1)
    800020ee:	01278b63          	beq	a5,s2,80002104 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	ba5fe0ef          	jal	80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    800020f8:	18848493          	addi	s1,s1,392
    800020fc:	ff3495e3          	bne	s1,s3,800020e6 <kkill+0x20>
  }
  return -1;
    80002100:	557d                	li	a0,-1
    80002102:	a819                	j	80002118 <kkill+0x52>
      p->killed = 1;
    80002104:	4785                	li	a5,1
    80002106:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING) {
    80002108:	4c98                	lw	a4,24(s1)
    8000210a:	4789                	li	a5,2
    8000210c:	00f70d63          	beq	a4,a5,80002126 <kkill+0x60>
      release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	b87fe0ef          	jal	80000c98 <release>
      return 0;
    80002116:	4501                	li	a0,0
}
    80002118:	70a2                	ld	ra,40(sp)
    8000211a:	7402                	ld	s0,32(sp)
    8000211c:	64e2                	ld	s1,24(sp)
    8000211e:	6942                	ld	s2,16(sp)
    80002120:	69a2                	ld	s3,8(sp)
    80002122:	6145                	addi	sp,sp,48
    80002124:	8082                	ret
        p->state = RUNNABLE;
    80002126:	478d                	li	a5,3
    80002128:	cc9c                	sw	a5,24(s1)
    8000212a:	b7dd                	j	80002110 <kkill+0x4a>

000000008000212c <setkilled>:

void setkilled(struct proc *p) {
    8000212c:	1101                	addi	sp,sp,-32
    8000212e:	ec06                	sd	ra,24(sp)
    80002130:	e822                	sd	s0,16(sp)
    80002132:	e426                	sd	s1,8(sp)
    80002134:	1000                	addi	s0,sp,32
    80002136:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002138:	ac9fe0ef          	jal	80000c00 <acquire>
  p->killed = 1;
    8000213c:	4785                	li	a5,1
    8000213e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002140:	8526                	mv	a0,s1
    80002142:	b57fe0ef          	jal	80000c98 <release>
}
    80002146:	60e2                	ld	ra,24(sp)
    80002148:	6442                	ld	s0,16(sp)
    8000214a:	64a2                	ld	s1,8(sp)
    8000214c:	6105                	addi	sp,sp,32
    8000214e:	8082                	ret

0000000080002150 <killed>:

int killed(struct proc *p) {
    80002150:	1101                	addi	sp,sp,-32
    80002152:	ec06                	sd	ra,24(sp)
    80002154:	e822                	sd	s0,16(sp)
    80002156:	e426                	sd	s1,8(sp)
    80002158:	e04a                	sd	s2,0(sp)
    8000215a:	1000                	addi	s0,sp,32
    8000215c:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000215e:	aa3fe0ef          	jal	80000c00 <acquire>
  k = p->killed;
    80002162:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	b31fe0ef          	jal	80000c98 <release>
  return k;
}
    8000216c:	854a                	mv	a0,s2
    8000216e:	60e2                	ld	ra,24(sp)
    80002170:	6442                	ld	s0,16(sp)
    80002172:	64a2                	ld	s1,8(sp)
    80002174:	6902                	ld	s2,0(sp)
    80002176:	6105                	addi	sp,sp,32
    80002178:	8082                	ret

000000008000217a <kwait>:
int kwait(uint64 addr) {
    8000217a:	715d                	addi	sp,sp,-80
    8000217c:	e486                	sd	ra,72(sp)
    8000217e:	e0a2                	sd	s0,64(sp)
    80002180:	fc26                	sd	s1,56(sp)
    80002182:	f84a                	sd	s2,48(sp)
    80002184:	f44e                	sd	s3,40(sp)
    80002186:	f052                	sd	s4,32(sp)
    80002188:	ec56                	sd	s5,24(sp)
    8000218a:	e85a                	sd	s6,16(sp)
    8000218c:	e45e                	sd	s7,8(sp)
    8000218e:	e062                	sd	s8,0(sp)
    80002190:	0880                	addi	s0,sp,80
    80002192:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002194:	f74ff0ef          	jal	80001908 <myproc>
    80002198:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000219a:	00010517          	auipc	a0,0x10
    8000219e:	07650513          	addi	a0,a0,118 # 80012210 <wait_lock>
    800021a2:	a5ffe0ef          	jal	80000c00 <acquire>
    havekids = 0;
    800021a6:	4b81                	li	s7,0
        if (pp->state == ZOMBIE) {
    800021a8:	4a15                	li	s4,5
        havekids = 1;
    800021aa:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800021ac:	00016997          	auipc	s3,0x16
    800021b0:	67c98993          	addi	s3,s3,1660 # 80018828 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800021b4:	00010c17          	auipc	s8,0x10
    800021b8:	05cc0c13          	addi	s8,s8,92 # 80012210 <wait_lock>
    800021bc:	a871                	j	80002258 <kwait+0xde>
          pid = pp->pid;
    800021be:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800021c2:	000b0c63          	beqz	s6,800021da <kwait+0x60>
    800021c6:	4691                	li	a3,4
    800021c8:	02c48613          	addi	a2,s1,44
    800021cc:	85da                	mv	a1,s6
    800021ce:	05093503          	ld	a0,80(s2)
    800021d2:	c4aff0ef          	jal	8000161c <copyout>
    800021d6:	02054b63          	bltz	a0,8000220c <kwait+0x92>
          freeproc(pp);
    800021da:	8526                	mv	a0,s1
    800021dc:	8fdff0ef          	jal	80001ad8 <freeproc>
          release(&pp->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	ab7fe0ef          	jal	80000c98 <release>
          release(&wait_lock);
    800021e6:	00010517          	auipc	a0,0x10
    800021ea:	02a50513          	addi	a0,a0,42 # 80012210 <wait_lock>
    800021ee:	aabfe0ef          	jal	80000c98 <release>
}
    800021f2:	854e                	mv	a0,s3
    800021f4:	60a6                	ld	ra,72(sp)
    800021f6:	6406                	ld	s0,64(sp)
    800021f8:	74e2                	ld	s1,56(sp)
    800021fa:	7942                	ld	s2,48(sp)
    800021fc:	79a2                	ld	s3,40(sp)
    800021fe:	7a02                	ld	s4,32(sp)
    80002200:	6ae2                	ld	s5,24(sp)
    80002202:	6b42                	ld	s6,16(sp)
    80002204:	6ba2                	ld	s7,8(sp)
    80002206:	6c02                	ld	s8,0(sp)
    80002208:	6161                	addi	sp,sp,80
    8000220a:	8082                	ret
            release(&pp->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	a8bfe0ef          	jal	80000c98 <release>
            release(&wait_lock);
    80002212:	00010517          	auipc	a0,0x10
    80002216:	ffe50513          	addi	a0,a0,-2 # 80012210 <wait_lock>
    8000221a:	a7ffe0ef          	jal	80000c98 <release>
            return -1;
    8000221e:	59fd                	li	s3,-1
    80002220:	bfc9                	j	800021f2 <kwait+0x78>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    80002222:	18848493          	addi	s1,s1,392
    80002226:	03348063          	beq	s1,s3,80002246 <kwait+0xcc>
      if (pp->parent == p) {
    8000222a:	7c9c                	ld	a5,56(s1)
    8000222c:	ff279be3          	bne	a5,s2,80002222 <kwait+0xa8>
        acquire(&pp->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	9cffe0ef          	jal	80000c00 <acquire>
        if (pp->state == ZOMBIE) {
    80002236:	4c9c                	lw	a5,24(s1)
    80002238:	f94783e3          	beq	a5,s4,800021be <kwait+0x44>
        release(&pp->lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	a5bfe0ef          	jal	80000c98 <release>
        havekids = 1;
    80002242:	8756                	mv	a4,s5
    80002244:	bff9                	j	80002222 <kwait+0xa8>
    if (!havekids || killed(p)) {
    80002246:	cf19                	beqz	a4,80002264 <kwait+0xea>
    80002248:	854a                	mv	a0,s2
    8000224a:	f07ff0ef          	jal	80002150 <killed>
    8000224e:	e919                	bnez	a0,80002264 <kwait+0xea>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002250:	85e2                	mv	a1,s8
    80002252:	854a                	mv	a0,s2
    80002254:	cc5ff0ef          	jal	80001f18 <sleep>
    havekids = 0;
    80002258:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    8000225a:	00010497          	auipc	s1,0x10
    8000225e:	3ce48493          	addi	s1,s1,974 # 80012628 <proc>
    80002262:	b7e1                	j	8000222a <kwait+0xb0>
      release(&wait_lock);
    80002264:	00010517          	auipc	a0,0x10
    80002268:	fac50513          	addi	a0,a0,-84 # 80012210 <wait_lock>
    8000226c:	a2dfe0ef          	jal	80000c98 <release>
      return -1;
    80002270:	59fd                	li	s3,-1
    80002272:	b741                	j	800021f2 <kwait+0x78>

0000000080002274 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    80002274:	7179                	addi	sp,sp,-48
    80002276:	f406                	sd	ra,40(sp)
    80002278:	f022                	sd	s0,32(sp)
    8000227a:	ec26                	sd	s1,24(sp)
    8000227c:	e84a                	sd	s2,16(sp)
    8000227e:	e44e                	sd	s3,8(sp)
    80002280:	e052                	sd	s4,0(sp)
    80002282:	1800                	addi	s0,sp,48
    80002284:	84aa                	mv	s1,a0
    80002286:	892e                	mv	s2,a1
    80002288:	89b2                	mv	s3,a2
    8000228a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000228c:	e7cff0ef          	jal	80001908 <myproc>
  if (user_dst) {
    80002290:	cc99                	beqz	s1,800022ae <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002292:	86d2                	mv	a3,s4
    80002294:	864e                	mv	a2,s3
    80002296:	85ca                	mv	a1,s2
    80002298:	6928                	ld	a0,80(a0)
    8000229a:	b82ff0ef          	jal	8000161c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000229e:	70a2                	ld	ra,40(sp)
    800022a0:	7402                	ld	s0,32(sp)
    800022a2:	64e2                	ld	s1,24(sp)
    800022a4:	6942                	ld	s2,16(sp)
    800022a6:	69a2                	ld	s3,8(sp)
    800022a8:	6a02                	ld	s4,0(sp)
    800022aa:	6145                	addi	sp,sp,48
    800022ac:	8082                	ret
    memmove((char *)dst, src, len);
    800022ae:	000a061b          	sext.w	a2,s4
    800022b2:	85ce                	mv	a1,s3
    800022b4:	854a                	mv	a0,s2
    800022b6:	a7bfe0ef          	jal	80000d30 <memmove>
    return 0;
    800022ba:	8526                	mv	a0,s1
    800022bc:	b7cd                	j	8000229e <either_copyout+0x2a>

00000000800022be <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    800022be:	7179                	addi	sp,sp,-48
    800022c0:	f406                	sd	ra,40(sp)
    800022c2:	f022                	sd	s0,32(sp)
    800022c4:	ec26                	sd	s1,24(sp)
    800022c6:	e84a                	sd	s2,16(sp)
    800022c8:	e44e                	sd	s3,8(sp)
    800022ca:	e052                	sd	s4,0(sp)
    800022cc:	1800                	addi	s0,sp,48
    800022ce:	892a                	mv	s2,a0
    800022d0:	84ae                	mv	s1,a1
    800022d2:	89b2                	mv	s3,a2
    800022d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022d6:	e32ff0ef          	jal	80001908 <myproc>
  if (user_src) {
    800022da:	cc99                	beqz	s1,800022f8 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800022dc:	86d2                	mv	a3,s4
    800022de:	864e                	mv	a2,s3
    800022e0:	85ca                	mv	a1,s2
    800022e2:	6928                	ld	a0,80(a0)
    800022e4:	c1cff0ef          	jal	80001700 <copyin>
  } else {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800022e8:	70a2                	ld	ra,40(sp)
    800022ea:	7402                	ld	s0,32(sp)
    800022ec:	64e2                	ld	s1,24(sp)
    800022ee:	6942                	ld	s2,16(sp)
    800022f0:	69a2                	ld	s3,8(sp)
    800022f2:	6a02                	ld	s4,0(sp)
    800022f4:	6145                	addi	sp,sp,48
    800022f6:	8082                	ret
    memmove(dst, (char *)src, len);
    800022f8:	000a061b          	sext.w	a2,s4
    800022fc:	85ce                	mv	a1,s3
    800022fe:	854a                	mv	a0,s2
    80002300:	a31fe0ef          	jal	80000d30 <memmove>
    return 0;
    80002304:	8526                	mv	a0,s1
    80002306:	b7cd                	j	800022e8 <either_copyin+0x2a>

0000000080002308 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void) {
    80002308:	715d                	addi	sp,sp,-80
    8000230a:	e486                	sd	ra,72(sp)
    8000230c:	e0a2                	sd	s0,64(sp)
    8000230e:	fc26                	sd	s1,56(sp)
    80002310:	f84a                	sd	s2,48(sp)
    80002312:	f44e                	sd	s3,40(sp)
    80002314:	f052                	sd	s4,32(sp)
    80002316:	ec56                	sd	s5,24(sp)
    80002318:	e85a                	sd	s6,16(sp)
    8000231a:	e45e                	sd	s7,8(sp)
    8000231c:	0880                	addi	s0,sp,80
      [UNUSED] "unused",   [USED] "used",      [SLEEPING] "sleep ",
      [RUNNABLE] "runble", [RUNNING] "run   ", [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000231e:	00007517          	auipc	a0,0x7
    80002322:	d8250513          	addi	a0,a0,-638 # 800090a0 <etext+0xa0>
    80002326:	a06fe0ef          	jal	8000052c <printf>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000232a:	00010497          	auipc	s1,0x10
    8000232e:	45648493          	addi	s1,s1,1110 # 80012780 <proc+0x158>
    80002332:	00016917          	auipc	s2,0x16
    80002336:	64e90913          	addi	s2,s2,1614 # 80018980 <bcache+0x140>
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000233a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000233c:	00007997          	auipc	s3,0x7
    80002340:	ebc98993          	addi	s3,s3,-324 # 800091f8 <etext+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002344:	00007a97          	auipc	s5,0x7
    80002348:	ebca8a93          	addi	s5,s5,-324 # 80009200 <etext+0x200>
    printf("\n");
    8000234c:	00007a17          	auipc	s4,0x7
    80002350:	d54a0a13          	addi	s4,s4,-684 # 800090a0 <etext+0xa0>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002354:	00008b97          	auipc	s7,0x8
    80002358:	c24b8b93          	addi	s7,s7,-988 # 80009f78 <states.0>
    8000235c:	a829                	j	80002376 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    8000235e:	ed86a583          	lw	a1,-296(a3)
    80002362:	8556                	mv	a0,s5
    80002364:	9c8fe0ef          	jal	8000052c <printf>
    printf("\n");
    80002368:	8552                	mv	a0,s4
    8000236a:	9c2fe0ef          	jal	8000052c <printf>
  for (p = proc; p < &proc[NPROC]; p++) {
    8000236e:	18848493          	addi	s1,s1,392
    80002372:	03248263          	beq	s1,s2,80002396 <procdump+0x8e>
    if (p->state == UNUSED)
    80002376:	86a6                	mv	a3,s1
    80002378:	ec04a783          	lw	a5,-320(s1)
    8000237c:	dbed                	beqz	a5,8000236e <procdump+0x66>
      state = "???";
    8000237e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002380:	fcfb6fe3          	bltu	s6,a5,8000235e <procdump+0x56>
    80002384:	02079713          	slli	a4,a5,0x20
    80002388:	01d75793          	srli	a5,a4,0x1d
    8000238c:	97de                	add	a5,a5,s7
    8000238e:	6390                	ld	a2,0(a5)
    80002390:	f679                	bnez	a2,8000235e <procdump+0x56>
      state = "???";
    80002392:	864e                	mv	a2,s3
    80002394:	b7e9                	j	8000235e <procdump+0x56>
  }
}
    80002396:	60a6                	ld	ra,72(sp)
    80002398:	6406                	ld	s0,64(sp)
    8000239a:	74e2                	ld	s1,56(sp)
    8000239c:	7942                	ld	s2,48(sp)
    8000239e:	79a2                	ld	s3,40(sp)
    800023a0:	7a02                	ld	s4,32(sp)
    800023a2:	6ae2                	ld	s5,24(sp)
    800023a4:	6b42                	ld	s6,16(sp)
    800023a6:	6ba2                	ld	s7,8(sp)
    800023a8:	6161                	addi	sp,sp,80
    800023aa:	8082                	ret

00000000800023ac <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    800023ac:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    800023b0:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    800023b4:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    800023b6:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    800023b8:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    800023bc:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    800023c0:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    800023c4:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    800023c8:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    800023cc:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    800023d0:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    800023d4:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    800023d8:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    800023dc:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    800023e0:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    800023e4:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    800023e8:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    800023ea:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    800023ec:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    800023f0:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    800023f4:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800023f8:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800023fc:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002400:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002404:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002408:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    8000240c:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002410:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002414:	8082                	ret

0000000080002416 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002416:	1141                	addi	sp,sp,-16
    80002418:	e406                	sd	ra,8(sp)
    8000241a:	e022                	sd	s0,0(sp)
    8000241c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000241e:	00007597          	auipc	a1,0x7
    80002422:	e2258593          	addi	a1,a1,-478 # 80009240 <etext+0x240>
    80002426:	00016517          	auipc	a0,0x16
    8000242a:	40250513          	addi	a0,a0,1026 # 80018828 <tickslock>
    8000242e:	f52fe0ef          	jal	80000b80 <initlock>
}
    80002432:	60a2                	ld	ra,8(sp)
    80002434:	6402                	ld	s0,0(sp)
    80002436:	0141                	addi	sp,sp,16
    80002438:	8082                	ret

000000008000243a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000243a:	1141                	addi	sp,sp,-16
    8000243c:	e422                	sd	s0,8(sp)
    8000243e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002440:	00004797          	auipc	a5,0x4
    80002444:	08078793          	addi	a5,a5,128 # 800064c0 <kernelvec>
    80002448:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000244c:	6422                	ld	s0,8(sp)
    8000244e:	0141                	addi	sp,sp,16
    80002450:	8082                	ret

0000000080002452 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80002452:	1141                	addi	sp,sp,-16
    80002454:	e406                	sd	ra,8(sp)
    80002456:	e022                	sd	s0,0(sp)
    80002458:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000245a:	caeff0ef          	jal	80001908 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000245e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002462:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002464:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002468:	04000737          	lui	a4,0x4000
    8000246c:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000246e:	0732                	slli	a4,a4,0xc
    80002470:	00006797          	auipc	a5,0x6
    80002474:	b9078793          	addi	a5,a5,-1136 # 80008000 <_trampoline>
    80002478:	00006697          	auipc	a3,0x6
    8000247c:	b8868693          	addi	a3,a3,-1144 # 80008000 <_trampoline>
    80002480:	8f95                	sub	a5,a5,a3
    80002482:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002484:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002488:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000248a:	18002773          	csrr	a4,satp
    8000248e:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002490:	6d38                	ld	a4,88(a0)
    80002492:	613c                	ld	a5,64(a0)
    80002494:	6685                	lui	a3,0x1
    80002496:	97b6                	add	a5,a5,a3
    80002498:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000249a:	6d3c                	ld	a5,88(a0)
    8000249c:	00000717          	auipc	a4,0x0
    800024a0:	0f870713          	addi	a4,a4,248 # 80002594 <usertrap>
    800024a4:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800024a6:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800024a8:	8712                	mv	a4,tp
    800024aa:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024ac:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800024b0:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800024b4:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024b8:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800024bc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800024be:	6f9c                	ld	a5,24(a5)
    800024c0:	14179073          	csrw	sepc,a5
}
    800024c4:	60a2                	ld	ra,8(sp)
    800024c6:	6402                	ld	s0,0(sp)
    800024c8:	0141                	addi	sp,sp,16
    800024ca:	8082                	ret

00000000800024cc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800024cc:	1101                	addi	sp,sp,-32
    800024ce:	ec06                	sd	ra,24(sp)
    800024d0:	e822                	sd	s0,16(sp)
    800024d2:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    800024d4:	c08ff0ef          	jal	800018dc <cpuid>
    800024d8:	cd11                	beqz	a0,800024f4 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    800024da:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    800024de:	000f4737          	lui	a4,0xf4
    800024e2:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    800024e6:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    800024e8:	14d79073          	csrw	stimecmp,a5
}
    800024ec:	60e2                	ld	ra,24(sp)
    800024ee:	6442                	ld	s0,16(sp)
    800024f0:	6105                	addi	sp,sp,32
    800024f2:	8082                	ret
    800024f4:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    800024f6:	00016497          	auipc	s1,0x16
    800024fa:	33248493          	addi	s1,s1,818 # 80018828 <tickslock>
    800024fe:	8526                	mv	a0,s1
    80002500:	f00fe0ef          	jal	80000c00 <acquire>
    ticks++;
    80002504:	00008517          	auipc	a0,0x8
    80002508:	bb450513          	addi	a0,a0,-1100 # 8000a0b8 <ticks>
    8000250c:	411c                	lw	a5,0(a0)
    8000250e:	2785                	addiw	a5,a5,1
    80002510:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002512:	a53ff0ef          	jal	80001f64 <wakeup>
    release(&tickslock);
    80002516:	8526                	mv	a0,s1
    80002518:	f80fe0ef          	jal	80000c98 <release>
    8000251c:	64a2                	ld	s1,8(sp)
    8000251e:	bf75                	j	800024da <clockintr+0xe>

0000000080002520 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002520:	1101                	addi	sp,sp,-32
    80002522:	ec06                	sd	ra,24(sp)
    80002524:	e822                	sd	s0,16(sp)
    80002526:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002528:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    8000252c:	57fd                	li	a5,-1
    8000252e:	17fe                	slli	a5,a5,0x3f
    80002530:	07a5                	addi	a5,a5,9
    80002532:	00f70c63          	beq	a4,a5,8000254a <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    80002536:	57fd                	li	a5,-1
    80002538:	17fe                	slli	a5,a5,0x3f
    8000253a:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    8000253c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    8000253e:	04f70763          	beq	a4,a5,8000258c <devintr+0x6c>
  }
}
    80002542:	60e2                	ld	ra,24(sp)
    80002544:	6442                	ld	s0,16(sp)
    80002546:	6105                	addi	sp,sp,32
    80002548:	8082                	ret
    8000254a:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    8000254c:	020040ef          	jal	8000656c <plic_claim>
    80002550:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002552:	47a9                	li	a5,10
    80002554:	00f50963          	beq	a0,a5,80002566 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    80002558:	4785                	li	a5,1
    8000255a:	00f50963          	beq	a0,a5,8000256c <devintr+0x4c>
    return 1;
    8000255e:	4505                	li	a0,1
    } else if(irq){
    80002560:	e889                	bnez	s1,80002572 <devintr+0x52>
    80002562:	64a2                	ld	s1,8(sp)
    80002564:	bff9                	j	80002542 <devintr+0x22>
      uartintr();
    80002566:	c7cfe0ef          	jal	800009e2 <uartintr>
    if(irq)
    8000256a:	a819                	j	80002580 <devintr+0x60>
      virtio_disk_intr();
    8000256c:	4c6040ef          	jal	80006a32 <virtio_disk_intr>
    if(irq)
    80002570:	a801                	j	80002580 <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    80002572:	85a6                	mv	a1,s1
    80002574:	00007517          	auipc	a0,0x7
    80002578:	cd450513          	addi	a0,a0,-812 # 80009248 <etext+0x248>
    8000257c:	fb1fd0ef          	jal	8000052c <printf>
      plic_complete(irq);
    80002580:	8526                	mv	a0,s1
    80002582:	00a040ef          	jal	8000658c <plic_complete>
    return 1;
    80002586:	4505                	li	a0,1
    80002588:	64a2                	ld	s1,8(sp)
    8000258a:	bf65                	j	80002542 <devintr+0x22>
    clockintr();
    8000258c:	f41ff0ef          	jal	800024cc <clockintr>
    return 2;
    80002590:	4509                	li	a0,2
    80002592:	bf45                	j	80002542 <devintr+0x22>

0000000080002594 <usertrap>:
{
    80002594:	1101                	addi	sp,sp,-32
    80002596:	ec06                	sd	ra,24(sp)
    80002598:	e822                	sd	s0,16(sp)
    8000259a:	e426                	sd	s1,8(sp)
    8000259c:	e04a                	sd	s2,0(sp)
    8000259e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025a0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800025a4:	1007f793          	andi	a5,a5,256
    800025a8:	eba5                	bnez	a5,80002618 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025aa:	00004797          	auipc	a5,0x4
    800025ae:	f1678793          	addi	a5,a5,-234 # 800064c0 <kernelvec>
    800025b2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800025b6:	b52ff0ef          	jal	80001908 <myproc>
    800025ba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800025bc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025be:	14102773          	csrr	a4,sepc
    800025c2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025c4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800025c8:	47a1                	li	a5,8
    800025ca:	04f70d63          	beq	a4,a5,80002624 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    800025ce:	f53ff0ef          	jal	80002520 <devintr>
    800025d2:	892a                	mv	s2,a0
    800025d4:	e945                	bnez	a0,80002684 <usertrap+0xf0>
    800025d6:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800025da:	47bd                	li	a5,15
    800025dc:	08f70863          	beq	a4,a5,8000266c <usertrap+0xd8>
    800025e0:	14202773          	csrr	a4,scause
    800025e4:	47b5                	li	a5,13
    800025e6:	08f70363          	beq	a4,a5,8000266c <usertrap+0xd8>
    800025ea:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    800025ee:	5890                	lw	a2,48(s1)
    800025f0:	00007517          	auipc	a0,0x7
    800025f4:	c9850513          	addi	a0,a0,-872 # 80009288 <etext+0x288>
    800025f8:	f35fd0ef          	jal	8000052c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002600:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002604:	00007517          	auipc	a0,0x7
    80002608:	cb450513          	addi	a0,a0,-844 # 800092b8 <etext+0x2b8>
    8000260c:	f21fd0ef          	jal	8000052c <printf>
    setkilled(p);
    80002610:	8526                	mv	a0,s1
    80002612:	b1bff0ef          	jal	8000212c <setkilled>
    80002616:	a035                	j	80002642 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002618:	00007517          	auipc	a0,0x7
    8000261c:	c5050513          	addi	a0,a0,-944 # 80009268 <etext+0x268>
    80002620:	9f2fe0ef          	jal	80000812 <panic>
    if(killed(p))
    80002624:	b2dff0ef          	jal	80002150 <killed>
    80002628:	ed15                	bnez	a0,80002664 <usertrap+0xd0>
    p->trapframe->epc += 4;
    8000262a:	6cb8                	ld	a4,88(s1)
    8000262c:	6f1c                	ld	a5,24(a4)
    8000262e:	0791                	addi	a5,a5,4
    80002630:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002632:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002636:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000263a:	10079073          	csrw	sstatus,a5
    syscall();
    8000263e:	246000ef          	jal	80002884 <syscall>
  if(killed(p))
    80002642:	8526                	mv	a0,s1
    80002644:	b0dff0ef          	jal	80002150 <killed>
    80002648:	e139                	bnez	a0,8000268e <usertrap+0xfa>
  prepare_return();
    8000264a:	e09ff0ef          	jal	80002452 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    8000264e:	68a8                	ld	a0,80(s1)
    80002650:	8131                	srli	a0,a0,0xc
    80002652:	57fd                	li	a5,-1
    80002654:	17fe                	slli	a5,a5,0x3f
    80002656:	8d5d                	or	a0,a0,a5
}
    80002658:	60e2                	ld	ra,24(sp)
    8000265a:	6442                	ld	s0,16(sp)
    8000265c:	64a2                	ld	s1,8(sp)
    8000265e:	6902                	ld	s2,0(sp)
    80002660:	6105                	addi	sp,sp,32
    80002662:	8082                	ret
      kexit(-1);
    80002664:	557d                	li	a0,-1
    80002666:	9bfff0ef          	jal	80002024 <kexit>
    8000266a:	b7c1                	j	8000262a <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000266c:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002670:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002674:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    80002676:	00163613          	seqz	a2,a2
    8000267a:	68a8                	ld	a0,80(s1)
    8000267c:	f1ffe0ef          	jal	8000159a <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002680:	f169                	bnez	a0,80002642 <usertrap+0xae>
    80002682:	b7a5                	j	800025ea <usertrap+0x56>
  if(killed(p))
    80002684:	8526                	mv	a0,s1
    80002686:	acbff0ef          	jal	80002150 <killed>
    8000268a:	c511                	beqz	a0,80002696 <usertrap+0x102>
    8000268c:	a011                	j	80002690 <usertrap+0xfc>
    8000268e:	4901                	li	s2,0
    kexit(-1);
    80002690:	557d                	li	a0,-1
    80002692:	993ff0ef          	jal	80002024 <kexit>
  if(which_dev == 2)
    80002696:	4789                	li	a5,2
    80002698:	faf919e3          	bne	s2,a5,8000264a <usertrap+0xb6>
    yield();
    8000269c:	851ff0ef          	jal	80001eec <yield>
    800026a0:	b76d                	j	8000264a <usertrap+0xb6>

00000000800026a2 <kerneltrap>:
{
    800026a2:	7179                	addi	sp,sp,-48
    800026a4:	f406                	sd	ra,40(sp)
    800026a6:	f022                	sd	s0,32(sp)
    800026a8:	ec26                	sd	s1,24(sp)
    800026aa:	e84a                	sd	s2,16(sp)
    800026ac:	e44e                	sd	s3,8(sp)
    800026ae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026b0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026b8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800026bc:	1004f793          	andi	a5,s1,256
    800026c0:	c795                	beqz	a5,800026ec <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026c6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800026c8:	eb85                	bnez	a5,800026f8 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    800026ca:	e57ff0ef          	jal	80002520 <devintr>
    800026ce:	c91d                	beqz	a0,80002704 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    800026d0:	4789                	li	a5,2
    800026d2:	04f50a63          	beq	a0,a5,80002726 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026d6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026da:	10049073          	csrw	sstatus,s1
}
    800026de:	70a2                	ld	ra,40(sp)
    800026e0:	7402                	ld	s0,32(sp)
    800026e2:	64e2                	ld	s1,24(sp)
    800026e4:	6942                	ld	s2,16(sp)
    800026e6:	69a2                	ld	s3,8(sp)
    800026e8:	6145                	addi	sp,sp,48
    800026ea:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800026ec:	00007517          	auipc	a0,0x7
    800026f0:	bf450513          	addi	a0,a0,-1036 # 800092e0 <etext+0x2e0>
    800026f4:	91efe0ef          	jal	80000812 <panic>
    panic("kerneltrap: interrupts enabled");
    800026f8:	00007517          	auipc	a0,0x7
    800026fc:	c1050513          	addi	a0,a0,-1008 # 80009308 <etext+0x308>
    80002700:	912fe0ef          	jal	80000812 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002704:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002708:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    8000270c:	85ce                	mv	a1,s3
    8000270e:	00007517          	auipc	a0,0x7
    80002712:	c1a50513          	addi	a0,a0,-998 # 80009328 <etext+0x328>
    80002716:	e17fd0ef          	jal	8000052c <printf>
    panic("kerneltrap");
    8000271a:	00007517          	auipc	a0,0x7
    8000271e:	c3650513          	addi	a0,a0,-970 # 80009350 <etext+0x350>
    80002722:	8f0fe0ef          	jal	80000812 <panic>
  if(which_dev == 2 && myproc() != 0)
    80002726:	9e2ff0ef          	jal	80001908 <myproc>
    8000272a:	d555                	beqz	a0,800026d6 <kerneltrap+0x34>
    yield();
    8000272c:	fc0ff0ef          	jal	80001eec <yield>
    80002730:	b75d                	j	800026d6 <kerneltrap+0x34>

0000000080002732 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002732:	1101                	addi	sp,sp,-32
    80002734:	ec06                	sd	ra,24(sp)
    80002736:	e822                	sd	s0,16(sp)
    80002738:	e426                	sd	s1,8(sp)
    8000273a:	1000                	addi	s0,sp,32
    8000273c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000273e:	9caff0ef          	jal	80001908 <myproc>
  switch (n) {
    80002742:	4795                	li	a5,5
    80002744:	0497e163          	bltu	a5,s1,80002786 <argraw+0x54>
    80002748:	048a                	slli	s1,s1,0x2
    8000274a:	00008717          	auipc	a4,0x8
    8000274e:	85e70713          	addi	a4,a4,-1954 # 80009fa8 <states.0+0x30>
    80002752:	94ba                	add	s1,s1,a4
    80002754:	409c                	lw	a5,0(s1)
    80002756:	97ba                	add	a5,a5,a4
    80002758:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000275a:	6d3c                	ld	a5,88(a0)
    8000275c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000275e:	60e2                	ld	ra,24(sp)
    80002760:	6442                	ld	s0,16(sp)
    80002762:	64a2                	ld	s1,8(sp)
    80002764:	6105                	addi	sp,sp,32
    80002766:	8082                	ret
    return p->trapframe->a1;
    80002768:	6d3c                	ld	a5,88(a0)
    8000276a:	7fa8                	ld	a0,120(a5)
    8000276c:	bfcd                	j	8000275e <argraw+0x2c>
    return p->trapframe->a2;
    8000276e:	6d3c                	ld	a5,88(a0)
    80002770:	63c8                	ld	a0,128(a5)
    80002772:	b7f5                	j	8000275e <argraw+0x2c>
    return p->trapframe->a3;
    80002774:	6d3c                	ld	a5,88(a0)
    80002776:	67c8                	ld	a0,136(a5)
    80002778:	b7dd                	j	8000275e <argraw+0x2c>
    return p->trapframe->a4;
    8000277a:	6d3c                	ld	a5,88(a0)
    8000277c:	6bc8                	ld	a0,144(a5)
    8000277e:	b7c5                	j	8000275e <argraw+0x2c>
    return p->trapframe->a5;
    80002780:	6d3c                	ld	a5,88(a0)
    80002782:	6fc8                	ld	a0,152(a5)
    80002784:	bfe9                	j	8000275e <argraw+0x2c>
  panic("argraw");
    80002786:	00007517          	auipc	a0,0x7
    8000278a:	bda50513          	addi	a0,a0,-1062 # 80009360 <etext+0x360>
    8000278e:	884fe0ef          	jal	80000812 <panic>

0000000080002792 <fetchaddr>:
{
    80002792:	1101                	addi	sp,sp,-32
    80002794:	ec06                	sd	ra,24(sp)
    80002796:	e822                	sd	s0,16(sp)
    80002798:	e426                	sd	s1,8(sp)
    8000279a:	e04a                	sd	s2,0(sp)
    8000279c:	1000                	addi	s0,sp,32
    8000279e:	84aa                	mv	s1,a0
    800027a0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800027a2:	966ff0ef          	jal	80001908 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800027a6:	653c                	ld	a5,72(a0)
    800027a8:	02f4f663          	bgeu	s1,a5,800027d4 <fetchaddr+0x42>
    800027ac:	00848713          	addi	a4,s1,8
    800027b0:	02e7e463          	bltu	a5,a4,800027d8 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800027b4:	46a1                	li	a3,8
    800027b6:	8626                	mv	a2,s1
    800027b8:	85ca                	mv	a1,s2
    800027ba:	6928                	ld	a0,80(a0)
    800027bc:	f45fe0ef          	jal	80001700 <copyin>
    800027c0:	00a03533          	snez	a0,a0
    800027c4:	40a00533          	neg	a0,a0
}
    800027c8:	60e2                	ld	ra,24(sp)
    800027ca:	6442                	ld	s0,16(sp)
    800027cc:	64a2                	ld	s1,8(sp)
    800027ce:	6902                	ld	s2,0(sp)
    800027d0:	6105                	addi	sp,sp,32
    800027d2:	8082                	ret
    return -1;
    800027d4:	557d                	li	a0,-1
    800027d6:	bfcd                	j	800027c8 <fetchaddr+0x36>
    800027d8:	557d                	li	a0,-1
    800027da:	b7fd                	j	800027c8 <fetchaddr+0x36>

00000000800027dc <fetchstr>:
{
    800027dc:	7179                	addi	sp,sp,-48
    800027de:	f406                	sd	ra,40(sp)
    800027e0:	f022                	sd	s0,32(sp)
    800027e2:	ec26                	sd	s1,24(sp)
    800027e4:	e84a                	sd	s2,16(sp)
    800027e6:	e44e                	sd	s3,8(sp)
    800027e8:	1800                	addi	s0,sp,48
    800027ea:	892a                	mv	s2,a0
    800027ec:	84ae                	mv	s1,a1
    800027ee:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800027f0:	918ff0ef          	jal	80001908 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800027f4:	86ce                	mv	a3,s3
    800027f6:	864a                	mv	a2,s2
    800027f8:	85a6                	mv	a1,s1
    800027fa:	6928                	ld	a0,80(a0)
    800027fc:	cc7fe0ef          	jal	800014c2 <copyinstr>
    80002800:	00054c63          	bltz	a0,80002818 <fetchstr+0x3c>
  return strlen(buf);
    80002804:	8526                	mv	a0,s1
    80002806:	e3efe0ef          	jal	80000e44 <strlen>
}
    8000280a:	70a2                	ld	ra,40(sp)
    8000280c:	7402                	ld	s0,32(sp)
    8000280e:	64e2                	ld	s1,24(sp)
    80002810:	6942                	ld	s2,16(sp)
    80002812:	69a2                	ld	s3,8(sp)
    80002814:	6145                	addi	sp,sp,48
    80002816:	8082                	ret
    return -1;
    80002818:	557d                	li	a0,-1
    8000281a:	bfc5                	j	8000280a <fetchstr+0x2e>

000000008000281c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000281c:	1101                	addi	sp,sp,-32
    8000281e:	ec06                	sd	ra,24(sp)
    80002820:	e822                	sd	s0,16(sp)
    80002822:	e426                	sd	s1,8(sp)
    80002824:	1000                	addi	s0,sp,32
    80002826:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002828:	f0bff0ef          	jal	80002732 <argraw>
    8000282c:	c088                	sw	a0,0(s1)
}
    8000282e:	60e2                	ld	ra,24(sp)
    80002830:	6442                	ld	s0,16(sp)
    80002832:	64a2                	ld	s1,8(sp)
    80002834:	6105                	addi	sp,sp,32
    80002836:	8082                	ret

0000000080002838 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002838:	1101                	addi	sp,sp,-32
    8000283a:	ec06                	sd	ra,24(sp)
    8000283c:	e822                	sd	s0,16(sp)
    8000283e:	e426                	sd	s1,8(sp)
    80002840:	1000                	addi	s0,sp,32
    80002842:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002844:	eefff0ef          	jal	80002732 <argraw>
    80002848:	e088                	sd	a0,0(s1)
}
    8000284a:	60e2                	ld	ra,24(sp)
    8000284c:	6442                	ld	s0,16(sp)
    8000284e:	64a2                	ld	s1,8(sp)
    80002850:	6105                	addi	sp,sp,32
    80002852:	8082                	ret

0000000080002854 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002854:	7179                	addi	sp,sp,-48
    80002856:	f406                	sd	ra,40(sp)
    80002858:	f022                	sd	s0,32(sp)
    8000285a:	ec26                	sd	s1,24(sp)
    8000285c:	e84a                	sd	s2,16(sp)
    8000285e:	1800                	addi	s0,sp,48
    80002860:	84ae                	mv	s1,a1
    80002862:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002864:	fd840593          	addi	a1,s0,-40
    80002868:	fd1ff0ef          	jal	80002838 <argaddr>
  return fetchstr(addr, buf, max);
    8000286c:	864a                	mv	a2,s2
    8000286e:	85a6                	mv	a1,s1
    80002870:	fd843503          	ld	a0,-40(s0)
    80002874:	f69ff0ef          	jal	800027dc <fetchstr>
}
    80002878:	70a2                	ld	ra,40(sp)
    8000287a:	7402                	ld	s0,32(sp)
    8000287c:	64e2                	ld	s1,24(sp)
    8000287e:	6942                	ld	s2,16(sp)
    80002880:	6145                	addi	sp,sp,48
    80002882:	8082                	ret

0000000080002884 <syscall>:

};

void
syscall(void)
{
    80002884:	1101                	addi	sp,sp,-32
    80002886:	ec06                	sd	ra,24(sp)
    80002888:	e822                	sd	s0,16(sp)
    8000288a:	e426                	sd	s1,8(sp)
    8000288c:	e04a                	sd	s2,0(sp)
    8000288e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002890:	878ff0ef          	jal	80001908 <myproc>
    80002894:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002896:	05853903          	ld	s2,88(a0)
    8000289a:	0a893783          	ld	a5,168(s2)
    8000289e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800028a2:	37fd                	addiw	a5,a5,-1
    800028a4:	4759                	li	a4,22
    800028a6:	00f76f63          	bltu	a4,a5,800028c4 <syscall+0x40>
    800028aa:	00369713          	slli	a4,a3,0x3
    800028ae:	00007797          	auipc	a5,0x7
    800028b2:	71278793          	addi	a5,a5,1810 # 80009fc0 <syscalls>
    800028b6:	97ba                	add	a5,a5,a4
    800028b8:	639c                	ld	a5,0(a5)
    800028ba:	c789                	beqz	a5,800028c4 <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800028bc:	9782                	jalr	a5
    800028be:	06a93823          	sd	a0,112(s2)
    800028c2:	a829                	j	800028dc <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800028c4:	15848613          	addi	a2,s1,344
    800028c8:	588c                	lw	a1,48(s1)
    800028ca:	00007517          	auipc	a0,0x7
    800028ce:	a9e50513          	addi	a0,a0,-1378 # 80009368 <etext+0x368>
    800028d2:	c5bfd0ef          	jal	8000052c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800028d6:	6cbc                	ld	a5,88(s1)
    800028d8:	577d                	li	a4,-1
    800028da:	fbb8                	sd	a4,112(a5)
  }
}
    800028dc:	60e2                	ld	ra,24(sp)
    800028de:	6442                	ld	s0,16(sp)
    800028e0:	64a2                	ld	s1,8(sp)
    800028e2:	6902                	ld	s2,0(sp)
    800028e4:	6105                	addi	sp,sp,32
    800028e6:	8082                	ret

00000000800028e8 <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    800028e8:	1101                	addi	sp,sp,-32
    800028ea:	ec06                	sd	ra,24(sp)
    800028ec:	e822                	sd	s0,16(sp)
    800028ee:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800028f0:	fec40593          	addi	a1,s0,-20
    800028f4:	4501                	li	a0,0
    800028f6:	f27ff0ef          	jal	8000281c <argint>
  kexit(n);
    800028fa:	fec42503          	lw	a0,-20(s0)
    800028fe:	f26ff0ef          	jal	80002024 <kexit>
  return 0;  // not reached
}
    80002902:	4501                	li	a0,0
    80002904:	60e2                	ld	ra,24(sp)
    80002906:	6442                	ld	s0,16(sp)
    80002908:	6105                	addi	sp,sp,32
    8000290a:	8082                	ret

000000008000290c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000290c:	1141                	addi	sp,sp,-16
    8000290e:	e406                	sd	ra,8(sp)
    80002910:	e022                	sd	s0,0(sp)
    80002912:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002914:	ff5fe0ef          	jal	80001908 <myproc>
}
    80002918:	5908                	lw	a0,48(a0)
    8000291a:	60a2                	ld	ra,8(sp)
    8000291c:	6402                	ld	s0,0(sp)
    8000291e:	0141                	addi	sp,sp,16
    80002920:	8082                	ret

0000000080002922 <sys_fork>:

uint64
sys_fork(void)
{
    80002922:	1141                	addi	sp,sp,-16
    80002924:	e406                	sd	ra,8(sp)
    80002926:	e022                	sd	s0,0(sp)
    80002928:	0800                	addi	s0,sp,16
  return kfork();
    8000292a:	b42ff0ef          	jal	80001c6c <kfork>
}
    8000292e:	60a2                	ld	ra,8(sp)
    80002930:	6402                	ld	s0,0(sp)
    80002932:	0141                	addi	sp,sp,16
    80002934:	8082                	ret

0000000080002936 <sys_wait>:

uint64
sys_wait(void)
{
    80002936:	1101                	addi	sp,sp,-32
    80002938:	ec06                	sd	ra,24(sp)
    8000293a:	e822                	sd	s0,16(sp)
    8000293c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000293e:	fe840593          	addi	a1,s0,-24
    80002942:	4501                	li	a0,0
    80002944:	ef5ff0ef          	jal	80002838 <argaddr>
  return kwait(p);
    80002948:	fe843503          	ld	a0,-24(s0)
    8000294c:	82fff0ef          	jal	8000217a <kwait>
}
    80002950:	60e2                	ld	ra,24(sp)
    80002952:	6442                	ld	s0,16(sp)
    80002954:	6105                	addi	sp,sp,32
    80002956:	8082                	ret

0000000080002958 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002958:	7179                	addi	sp,sp,-48
    8000295a:	f406                	sd	ra,40(sp)
    8000295c:	f022                	sd	s0,32(sp)
    8000295e:	ec26                	sd	s1,24(sp)
    80002960:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002962:	fd840593          	addi	a1,s0,-40
    80002966:	4501                	li	a0,0
    80002968:	eb5ff0ef          	jal	8000281c <argint>
  argint(1, &t);
    8000296c:	fdc40593          	addi	a1,s0,-36
    80002970:	4505                	li	a0,1
    80002972:	eabff0ef          	jal	8000281c <argint>
  addr = myproc()->sz;
    80002976:	f93fe0ef          	jal	80001908 <myproc>
    8000297a:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    8000297c:	fdc42703          	lw	a4,-36(s0)
    80002980:	4785                	li	a5,1
    80002982:	02f70763          	beq	a4,a5,800029b0 <sys_sbrk+0x58>
    80002986:	fd842783          	lw	a5,-40(s0)
    8000298a:	0207c363          	bltz	a5,800029b0 <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    8000298e:	97a6                	add	a5,a5,s1
    80002990:	0297ee63          	bltu	a5,s1,800029cc <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002994:	02000737          	lui	a4,0x2000
    80002998:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    8000299a:	0736                	slli	a4,a4,0xd
    8000299c:	02f76a63          	bltu	a4,a5,800029d0 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    800029a0:	f69fe0ef          	jal	80001908 <myproc>
    800029a4:	fd842703          	lw	a4,-40(s0)
    800029a8:	653c                	ld	a5,72(a0)
    800029aa:	97ba                	add	a5,a5,a4
    800029ac:	e53c                	sd	a5,72(a0)
    800029ae:	a039                	j	800029bc <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    800029b0:	fd842503          	lw	a0,-40(s0)
    800029b4:	a56ff0ef          	jal	80001c0a <growproc>
    800029b8:	00054863          	bltz	a0,800029c8 <sys_sbrk+0x70>
  }
  return addr;
}
    800029bc:	8526                	mv	a0,s1
    800029be:	70a2                	ld	ra,40(sp)
    800029c0:	7402                	ld	s0,32(sp)
    800029c2:	64e2                	ld	s1,24(sp)
    800029c4:	6145                	addi	sp,sp,48
    800029c6:	8082                	ret
      return -1;
    800029c8:	54fd                	li	s1,-1
    800029ca:	bfcd                	j	800029bc <sys_sbrk+0x64>
      return -1;
    800029cc:	54fd                	li	s1,-1
    800029ce:	b7fd                	j	800029bc <sys_sbrk+0x64>
      return -1;
    800029d0:	54fd                	li	s1,-1
    800029d2:	b7ed                	j	800029bc <sys_sbrk+0x64>

00000000800029d4 <sys_pause>:

uint64
sys_pause(void)
{
    800029d4:	7139                	addi	sp,sp,-64
    800029d6:	fc06                	sd	ra,56(sp)
    800029d8:	f822                	sd	s0,48(sp)
    800029da:	f04a                	sd	s2,32(sp)
    800029dc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800029de:	fcc40593          	addi	a1,s0,-52
    800029e2:	4501                	li	a0,0
    800029e4:	e39ff0ef          	jal	8000281c <argint>
  if(n < 0)
    800029e8:	fcc42783          	lw	a5,-52(s0)
    800029ec:	0607c763          	bltz	a5,80002a5a <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    800029f0:	00016517          	auipc	a0,0x16
    800029f4:	e3850513          	addi	a0,a0,-456 # 80018828 <tickslock>
    800029f8:	a08fe0ef          	jal	80000c00 <acquire>
  ticks0 = ticks;
    800029fc:	00007917          	auipc	s2,0x7
    80002a00:	6bc92903          	lw	s2,1724(s2) # 8000a0b8 <ticks>
  while(ticks - ticks0 < n){
    80002a04:	fcc42783          	lw	a5,-52(s0)
    80002a08:	cf8d                	beqz	a5,80002a42 <sys_pause+0x6e>
    80002a0a:	f426                	sd	s1,40(sp)
    80002a0c:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a0e:	00016997          	auipc	s3,0x16
    80002a12:	e1a98993          	addi	s3,s3,-486 # 80018828 <tickslock>
    80002a16:	00007497          	auipc	s1,0x7
    80002a1a:	6a248493          	addi	s1,s1,1698 # 8000a0b8 <ticks>
    if(killed(myproc())){
    80002a1e:	eebfe0ef          	jal	80001908 <myproc>
    80002a22:	f2eff0ef          	jal	80002150 <killed>
    80002a26:	ed0d                	bnez	a0,80002a60 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002a28:	85ce                	mv	a1,s3
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	cecff0ef          	jal	80001f18 <sleep>
  while(ticks - ticks0 < n){
    80002a30:	409c                	lw	a5,0(s1)
    80002a32:	412787bb          	subw	a5,a5,s2
    80002a36:	fcc42703          	lw	a4,-52(s0)
    80002a3a:	fee7e2e3          	bltu	a5,a4,80002a1e <sys_pause+0x4a>
    80002a3e:	74a2                	ld	s1,40(sp)
    80002a40:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002a42:	00016517          	auipc	a0,0x16
    80002a46:	de650513          	addi	a0,a0,-538 # 80018828 <tickslock>
    80002a4a:	a4efe0ef          	jal	80000c98 <release>
  return 0;
    80002a4e:	4501                	li	a0,0
}
    80002a50:	70e2                	ld	ra,56(sp)
    80002a52:	7442                	ld	s0,48(sp)
    80002a54:	7902                	ld	s2,32(sp)
    80002a56:	6121                	addi	sp,sp,64
    80002a58:	8082                	ret
    n = 0;
    80002a5a:	fc042623          	sw	zero,-52(s0)
    80002a5e:	bf49                	j	800029f0 <sys_pause+0x1c>
      release(&tickslock);
    80002a60:	00016517          	auipc	a0,0x16
    80002a64:	dc850513          	addi	a0,a0,-568 # 80018828 <tickslock>
    80002a68:	a30fe0ef          	jal	80000c98 <release>
      return -1;
    80002a6c:	557d                	li	a0,-1
    80002a6e:	74a2                	ld	s1,40(sp)
    80002a70:	69e2                	ld	s3,24(sp)
    80002a72:	bff9                	j	80002a50 <sys_pause+0x7c>

0000000080002a74 <sys_kill>:

uint64
sys_kill(void)
{
    80002a74:	1101                	addi	sp,sp,-32
    80002a76:	ec06                	sd	ra,24(sp)
    80002a78:	e822                	sd	s0,16(sp)
    80002a7a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002a7c:	fec40593          	addi	a1,s0,-20
    80002a80:	4501                	li	a0,0
    80002a82:	d9bff0ef          	jal	8000281c <argint>
  return kkill(pid);
    80002a86:	fec42503          	lw	a0,-20(s0)
    80002a8a:	e3cff0ef          	jal	800020c6 <kkill>
}
    80002a8e:	60e2                	ld	ra,24(sp)
    80002a90:	6442                	ld	s0,16(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002aa0:	00016517          	auipc	a0,0x16
    80002aa4:	d8850513          	addi	a0,a0,-632 # 80018828 <tickslock>
    80002aa8:	958fe0ef          	jal	80000c00 <acquire>
  xticks = ticks;
    80002aac:	00007497          	auipc	s1,0x7
    80002ab0:	60c4a483          	lw	s1,1548(s1) # 8000a0b8 <ticks>
  release(&tickslock);
    80002ab4:	00016517          	auipc	a0,0x16
    80002ab8:	d7450513          	addi	a0,a0,-652 # 80018828 <tickslock>
    80002abc:	9dcfe0ef          	jal	80000c98 <release>
  return xticks;
}
    80002ac0:	02049513          	slli	a0,s1,0x20
    80002ac4:	9101                	srli	a0,a0,0x20
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret

0000000080002ad0 <bcache_report>:
} bcache;

static int buf_id(struct buf *b);

// --- الدالة المساعدة الجديدة للتقرير ---
void bcache_report(char* op, struct buf *b, int old_ref, int old_val,  char* det) {
    80002ad0:	cb010113          	addi	sp,sp,-848
    80002ad4:	34113423          	sd	ra,840(sp)
    80002ad8:	34813023          	sd	s0,832(sp)
    80002adc:	32913c23          	sd	s1,824(sp)
    80002ae0:	33213823          	sd	s2,816(sp)
    80002ae4:	33313423          	sd	s3,808(sp)
    80002ae8:	33413023          	sd	s4,800(sp)
    80002aec:	31513c23          	sd	s5,792(sp)
    80002af0:	0e80                	addi	s0,sp,848
    80002af2:	8aaa                	mv	s5,a0
    80002af4:	84ae                	mv	s1,a1
    80002af6:	8a32                	mv	s4,a2
    80002af8:	89b6                	mv	s3,a3
    80002afa:	893a                	mv	s2,a4
    struct fs_event e;
    memset(&e, 0, sizeof(e));
    80002afc:	31000613          	li	a2,784
    80002b00:	4581                	li	a1,0
    80002b02:	cb040513          	addi	a0,s0,-848
    80002b06:	9cefe0ef          	jal	80000cd4 <memset>
    e.ticks = ticks; 
    80002b0a:	00007797          	auipc	a5,0x7
    80002b0e:	5ae7a783          	lw	a5,1454(a5) # 8000a0b8 <ticks>
    80002b12:	caf42c23          	sw	a5,-840(s0)
    e.pid = myproc() ? myproc()->pid : 0;
    80002b16:	df3fe0ef          	jal	80001908 <myproc>
    80002b1a:	4781                	li	a5,0
    80002b1c:	c501                	beqz	a0,80002b24 <bcache_report+0x54>
    80002b1e:	debfe0ef          	jal	80001908 <myproc>
    80002b22:	591c                	lw	a5,48(a0)
    80002b24:	caf42e23          	sw	a5,-836(s0)
    e.type = LAYER_BCACHE;
    80002b28:	4785                	li	a5,1
    80002b2a:	ccf42023          	sw	a5,-832(s0)
    safestrcpy(e.op_name, op, 16);
    80002b2e:	4641                	li	a2,16
    80002b30:	85d6                	mv	a1,s5
    80002b32:	cc440513          	addi	a0,s0,-828
    80002b36:	adcfe0ef          	jal	80000e12 <safestrcpy>
}

static int
buf_id(struct buf *b)
{
  return (int)(b - bcache.buf);
    80002b3a:	00016797          	auipc	a5,0x16
    80002b3e:	d1e78793          	addi	a5,a5,-738 # 80018858 <bcache+0x18>
    80002b42:	40f487b3          	sub	a5,s1,a5
    80002b46:	4037d513          	srai	a0,a5,0x3
    80002b4a:	003af7b7          	lui	a5,0x3af
    80002b4e:	f6d78793          	addi	a5,a5,-147 # 3aef6d <_entry-0x7fc51093>
    80002b52:	07b2                	slli	a5,a5,0xc
    80002b54:	a9778793          	addi	a5,a5,-1385
    80002b58:	07be                	slli	a5,a5,0xf
    80002b5a:	2c378793          	addi	a5,a5,707
    80002b5e:	07b6                	slli	a5,a5,0xd
    80002b60:	72378793          	addi	a5,a5,1827
    80002b64:	02f507b3          	mul	a5,a0,a5
    80002b68:	ccf42c23          	sw	a5,-808(s0)
    e.blockno = b->blockno;
    80002b6c:	44dc                	lw	a5,12(s1)
    80002b6e:	ccf42a23          	sw	a5,-812(s0)
    e.refcnt = b->refcnt;
    80002b72:	40bc                	lw	a5,64(s1)
    80002b74:	ccf42e23          	sw	a5,-804(s0)
    e.old_refcnt = old_ref;
    80002b78:	cf442023          	sw	s4,-800(s0)
    e.valid = b->valid;
    80002b7c:	409c                	lw	a5,0(s1)
    80002b7e:	cef42223          	sw	a5,-796(s0)
    e.old_valid = old_val;
    80002b82:	cf342423          	sw	s3,-792(s0)
    safestrcpy(e.details, det, 128);
    80002b86:	08000613          	li	a2,128
    80002b8a:	85ca                	mv	a1,s2
    80002b8c:	f3c40513          	addi	a0,s0,-196
    80002b90:	a82fe0ef          	jal	80000e12 <safestrcpy>
    fslog_push(&e);
    80002b94:	cb040513          	addi	a0,s0,-848
    80002b98:	2c4040ef          	jal	80006e5c <fslog_push>
}
    80002b9c:	34813083          	ld	ra,840(sp)
    80002ba0:	34013403          	ld	s0,832(sp)
    80002ba4:	33813483          	ld	s1,824(sp)
    80002ba8:	33013903          	ld	s2,816(sp)
    80002bac:	32813983          	ld	s3,808(sp)
    80002bb0:	32013a03          	ld	s4,800(sp)
    80002bb4:	31813a83          	ld	s5,792(sp)
    80002bb8:	35010113          	addi	sp,sp,848
    80002bbc:	8082                	ret

0000000080002bbe <binit>:
{
    80002bbe:	7179                	addi	sp,sp,-48
    80002bc0:	f406                	sd	ra,40(sp)
    80002bc2:	f022                	sd	s0,32(sp)
    80002bc4:	ec26                	sd	s1,24(sp)
    80002bc6:	e84a                	sd	s2,16(sp)
    80002bc8:	e44e                	sd	s3,8(sp)
    80002bca:	e052                	sd	s4,0(sp)
    80002bcc:	1800                	addi	s0,sp,48
  initlock(&bcache.lock, "bcache");
    80002bce:	00006597          	auipc	a1,0x6
    80002bd2:	7ba58593          	addi	a1,a1,1978 # 80009388 <etext+0x388>
    80002bd6:	00016517          	auipc	a0,0x16
    80002bda:	c6a50513          	addi	a0,a0,-918 # 80018840 <bcache>
    80002bde:	fa3fd0ef          	jal	80000b80 <initlock>
  bcache.head.prev = &bcache.head;
    80002be2:	0001e797          	auipc	a5,0x1e
    80002be6:	c5e78793          	addi	a5,a5,-930 # 80020840 <bcache+0x8000>
    80002bea:	0001e717          	auipc	a4,0x1e
    80002bee:	ebe70713          	addi	a4,a4,-322 # 80020aa8 <bcache+0x8268>
    80002bf2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002bf6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002bfa:	00016497          	auipc	s1,0x16
    80002bfe:	c5e48493          	addi	s1,s1,-930 # 80018858 <bcache+0x18>
    b->next = bcache.head.next;
    80002c02:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002c04:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002c06:	00006a17          	auipc	s4,0x6
    80002c0a:	78aa0a13          	addi	s4,s4,1930 # 80009390 <etext+0x390>
    b->next = bcache.head.next;
    80002c0e:	2b893783          	ld	a5,696(s2)
    80002c12:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002c14:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002c18:	85d2                	mv	a1,s4
    80002c1a:	01048513          	addi	a0,s1,16
    80002c1e:	7d5010ef          	jal	80004bf2 <initsleeplock>
    bcache.head.next->prev = b;
    80002c22:	2b893783          	ld	a5,696(s2)
    80002c26:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002c28:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002c2c:	45848493          	addi	s1,s1,1112
    80002c30:	fd349fe3          	bne	s1,s3,80002c0e <binit+0x50>
}
    80002c34:	70a2                	ld	ra,40(sp)
    80002c36:	7402                	ld	s0,32(sp)
    80002c38:	64e2                	ld	s1,24(sp)
    80002c3a:	6942                	ld	s2,16(sp)
    80002c3c:	69a2                	ld	s3,8(sp)
    80002c3e:	6a02                	ld	s4,0(sp)
    80002c40:	6145                	addi	sp,sp,48
    80002c42:	8082                	ret

0000000080002c44 <bread>:
{
    80002c44:	7179                	addi	sp,sp,-48
    80002c46:	f406                	sd	ra,40(sp)
    80002c48:	f022                	sd	s0,32(sp)
    80002c4a:	ec26                	sd	s1,24(sp)
    80002c4c:	e84a                	sd	s2,16(sp)
    80002c4e:	e44e                	sd	s3,8(sp)
    80002c50:	1800                	addi	s0,sp,48
    80002c52:	892a                	mv	s2,a0
    80002c54:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002c56:	00016517          	auipc	a0,0x16
    80002c5a:	bea50513          	addi	a0,a0,-1046 # 80018840 <bcache>
    80002c5e:	fa3fd0ef          	jal	80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002c62:	0001e497          	auipc	s1,0x1e
    80002c66:	e964b483          	ld	s1,-362(s1) # 80020af8 <bcache+0x82b8>
    80002c6a:	0001e797          	auipc	a5,0x1e
    80002c6e:	e3e78793          	addi	a5,a5,-450 # 80020aa8 <bcache+0x8268>
    80002c72:	04f48863          	beq	s1,a5,80002cc2 <bread+0x7e>
    80002c76:	873e                	mv	a4,a5
    80002c78:	a021                	j	80002c80 <bread+0x3c>
    80002c7a:	68a4                	ld	s1,80(s1)
    80002c7c:	04e48363          	beq	s1,a4,80002cc2 <bread+0x7e>
    if(b->dev == dev && b->blockno == blockno){
    80002c80:	449c                	lw	a5,8(s1)
    80002c82:	ff279ce3          	bne	a5,s2,80002c7a <bread+0x36>
    80002c86:	44dc                	lw	a5,12(s1)
    80002c88:	ff3799e3          	bne	a5,s3,80002c7a <bread+0x36>
      int old_ref = b->refcnt;
    80002c8c:	40b0                	lw	a2,64(s1)
      b->refcnt++;
    80002c8e:	0016079b          	addiw	a5,a2,1
    80002c92:	c0bc                	sw	a5,64(s1)
      bcache_report("BGET_HIT", b, old_ref, b->valid, "HIT: Buffer found in cache");
    80002c94:	00006717          	auipc	a4,0x6
    80002c98:	70470713          	addi	a4,a4,1796 # 80009398 <etext+0x398>
    80002c9c:	4094                	lw	a3,0(s1)
    80002c9e:	85a6                	mv	a1,s1
    80002ca0:	00006517          	auipc	a0,0x6
    80002ca4:	71850513          	addi	a0,a0,1816 # 800093b8 <etext+0x3b8>
    80002ca8:	e29ff0ef          	jal	80002ad0 <bcache_report>
      release(&bcache.lock);
    80002cac:	00016517          	auipc	a0,0x16
    80002cb0:	b9450513          	addi	a0,a0,-1132 # 80018840 <bcache>
    80002cb4:	fe5fd0ef          	jal	80000c98 <release>
      acquiresleep(&b->lock);
    80002cb8:	01048513          	addi	a0,s1,16
    80002cbc:	76d010ef          	jal	80004c28 <acquiresleep>
      return b;
    80002cc0:	a0b5                	j	80002d2c <bread+0xe8>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002cc2:	0001e497          	auipc	s1,0x1e
    80002cc6:	e2e4b483          	ld	s1,-466(s1) # 80020af0 <bcache+0x82b0>
    80002cca:	0001e797          	auipc	a5,0x1e
    80002cce:	dde78793          	addi	a5,a5,-546 # 80020aa8 <bcache+0x8268>
    80002cd2:	00f48863          	beq	s1,a5,80002ce2 <bread+0x9e>
    80002cd6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002cd8:	40bc                	lw	a5,64(s1)
    80002cda:	cb91                	beqz	a5,80002cee <bread+0xaa>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002cdc:	64a4                	ld	s1,72(s1)
    80002cde:	fee49de3          	bne	s1,a4,80002cd8 <bread+0x94>
  panic("bget: no buffers");
    80002ce2:	00006517          	auipc	a0,0x6
    80002ce6:	71650513          	addi	a0,a0,1814 # 800093f8 <etext+0x3f8>
    80002cea:	b29fd0ef          	jal	80000812 <panic>
  int old_val = b->valid;
    80002cee:	4094                	lw	a3,0(s1)
  b->dev = dev;
    80002cf0:	0124a423          	sw	s2,8(s1)
  b->blockno = blockno;
    80002cf4:	0134a623          	sw	s3,12(s1)
  b->valid = 0;
    80002cf8:	0004a023          	sw	zero,0(s1)
  b->refcnt = 1;   
    80002cfc:	4785                	li	a5,1
    80002cfe:	c0bc                	sw	a5,64(s1)
  bcache_report("BGET_MISS", b, old_ref, old_val, "MISS: Evicting LRU buffer");
    80002d00:	00006717          	auipc	a4,0x6
    80002d04:	6c870713          	addi	a4,a4,1736 # 800093c8 <etext+0x3c8>
    80002d08:	4601                	li	a2,0
    80002d0a:	85a6                	mv	a1,s1
    80002d0c:	00006517          	auipc	a0,0x6
    80002d10:	6dc50513          	addi	a0,a0,1756 # 800093e8 <etext+0x3e8>
    80002d14:	dbdff0ef          	jal	80002ad0 <bcache_report>
      release(&bcache.lock);
    80002d18:	00016517          	auipc	a0,0x16
    80002d1c:	b2850513          	addi	a0,a0,-1240 # 80018840 <bcache>
    80002d20:	f79fd0ef          	jal	80000c98 <release>
      acquiresleep(&b->lock);
    80002d24:	01048513          	addi	a0,s1,16
    80002d28:	701010ef          	jal	80004c28 <acquiresleep>
  if(!b->valid) {
    80002d2c:	409c                	lw	a5,0(s1)
    80002d2e:	cb89                	beqz	a5,80002d40 <bread+0xfc>
}
    80002d30:	8526                	mv	a0,s1
    80002d32:	70a2                	ld	ra,40(sp)
    80002d34:	7402                	ld	s0,32(sp)
    80002d36:	64e2                	ld	s1,24(sp)
    80002d38:	6942                	ld	s2,16(sp)
    80002d3a:	69a2                	ld	s3,8(sp)
    80002d3c:	6145                	addi	sp,sp,48
    80002d3e:	8082                	ret
  bcache_report("BREAD_START", b, b->refcnt, old_valid, "Reading from disk...");
    80002d40:	00006717          	auipc	a4,0x6
    80002d44:	6d070713          	addi	a4,a4,1744 # 80009410 <etext+0x410>
    80002d48:	4681                	li	a3,0
    80002d4a:	40b0                	lw	a2,64(s1)
    80002d4c:	85a6                	mv	a1,s1
    80002d4e:	00006517          	auipc	a0,0x6
    80002d52:	6da50513          	addi	a0,a0,1754 # 80009428 <etext+0x428>
    80002d56:	d7bff0ef          	jal	80002ad0 <bcache_report>
    virtio_disk_rw(b, 0);
    80002d5a:	4581                	li	a1,0
    80002d5c:	8526                	mv	a0,s1
    80002d5e:	2c3030ef          	jal	80006820 <virtio_disk_rw>
    b->valid = 1;
    80002d62:	4785                	li	a5,1
    80002d64:	c09c                	sw	a5,0(s1)
  bcache_report("BREAD_END", b, b->refcnt, b->valid, "Read finished: Valid=1");
    80002d66:	00006717          	auipc	a4,0x6
    80002d6a:	6d270713          	addi	a4,a4,1746 # 80009438 <etext+0x438>
    80002d6e:	4685                	li	a3,1
    80002d70:	40b0                	lw	a2,64(s1)
    80002d72:	85a6                	mv	a1,s1
    80002d74:	00006517          	auipc	a0,0x6
    80002d78:	6dc50513          	addi	a0,a0,1756 # 80009450 <etext+0x450>
    80002d7c:	d55ff0ef          	jal	80002ad0 <bcache_report>
  return b;
    80002d80:	bf45                	j	80002d30 <bread+0xec>

0000000080002d82 <bwrite>:
{
    80002d82:	1101                	addi	sp,sp,-32
    80002d84:	ec06                	sd	ra,24(sp)
    80002d86:	e822                	sd	s0,16(sp)
    80002d88:	e426                	sd	s1,8(sp)
    80002d8a:	e04a                	sd	s2,0(sp)
    80002d8c:	1000                	addi	s0,sp,32
    80002d8e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002d90:	0541                	addi	a0,a0,16
    80002d92:	715010ef          	jal	80004ca6 <holdingsleep>
    80002d96:	cd05                	beqz	a0,80002dce <bwrite+0x4c>
  int old_valid = b->valid;
    80002d98:	0004a903          	lw	s2,0(s1)
  virtio_disk_rw(b, 1);
    80002d9c:	4585                	li	a1,1
    80002d9e:	8526                	mv	a0,s1
    80002da0:	281030ef          	jal	80006820 <virtio_disk_rw>
  b->disk = 0;
    80002da4:	0004a223          	sw	zero,4(s1)
  bcache_report("BWRITE", b, b->refcnt, old_valid, "Writing buffer to disk");
    80002da8:	00006717          	auipc	a4,0x6
    80002dac:	6c070713          	addi	a4,a4,1728 # 80009468 <etext+0x468>
    80002db0:	86ca                	mv	a3,s2
    80002db2:	40b0                	lw	a2,64(s1)
    80002db4:	85a6                	mv	a1,s1
    80002db6:	00006517          	auipc	a0,0x6
    80002dba:	6ca50513          	addi	a0,a0,1738 # 80009480 <etext+0x480>
    80002dbe:	d13ff0ef          	jal	80002ad0 <bcache_report>
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	64a2                	ld	s1,8(sp)
    80002dc8:	6902                	ld	s2,0(sp)
    80002dca:	6105                	addi	sp,sp,32
    80002dcc:	8082                	ret
    panic("bwrite");
    80002dce:	00006517          	auipc	a0,0x6
    80002dd2:	69250513          	addi	a0,a0,1682 # 80009460 <etext+0x460>
    80002dd6:	a3dfd0ef          	jal	80000812 <panic>

0000000080002dda <brelse>:
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	e04a                	sd	s2,0(sp)
    80002de4:	1000                	addi	s0,sp,32
    80002de6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002de8:	01050913          	addi	s2,a0,16
    80002dec:	854a                	mv	a0,s2
    80002dee:	6b9010ef          	jal	80004ca6 <holdingsleep>
    80002df2:	cd35                	beqz	a0,80002e6e <brelse+0x94>
  releasesleep(&b->lock);
    80002df4:	854a                	mv	a0,s2
    80002df6:	679010ef          	jal	80004c6e <releasesleep>
  acquire(&bcache.lock);
    80002dfa:	00016517          	auipc	a0,0x16
    80002dfe:	a4650513          	addi	a0,a0,-1466 # 80018840 <bcache>
    80002e02:	dfffd0ef          	jal	80000c00 <acquire>
  int old_ref = b->refcnt;
    80002e06:	40b0                	lw	a2,64(s1)
  b->refcnt--;
    80002e08:	fff6079b          	addiw	a5,a2,-1
    80002e0c:	c0bc                	sw	a5,64(s1)
  bcache_report("BRELEASE", b, old_ref, old_valid, "Released buffer");
    80002e0e:	00006717          	auipc	a4,0x6
    80002e12:	68270713          	addi	a4,a4,1666 # 80009490 <etext+0x490>
    80002e16:	4094                	lw	a3,0(s1)
    80002e18:	85a6                	mv	a1,s1
    80002e1a:	00006517          	auipc	a0,0x6
    80002e1e:	68650513          	addi	a0,a0,1670 # 800094a0 <etext+0x4a0>
    80002e22:	cafff0ef          	jal	80002ad0 <bcache_report>
  if (b->refcnt == 0) {
    80002e26:	40bc                	lw	a5,64(s1)
    80002e28:	e79d                	bnez	a5,80002e56 <brelse+0x7c>
    b->next->prev = b->prev;
    80002e2a:	68b8                	ld	a4,80(s1)
    80002e2c:	64bc                	ld	a5,72(s1)
    80002e2e:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002e30:	68b8                	ld	a4,80(s1)
    80002e32:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002e34:	0001e797          	auipc	a5,0x1e
    80002e38:	a0c78793          	addi	a5,a5,-1524 # 80020840 <bcache+0x8000>
    80002e3c:	2b87b703          	ld	a4,696(a5)
    80002e40:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002e42:	0001e717          	auipc	a4,0x1e
    80002e46:	c6670713          	addi	a4,a4,-922 # 80020aa8 <bcache+0x8268>
    80002e4a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002e4c:	2b87b703          	ld	a4,696(a5)
    80002e50:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002e52:	2a97bc23          	sd	s1,696(a5)
  release(&bcache.lock);
    80002e56:	00016517          	auipc	a0,0x16
    80002e5a:	9ea50513          	addi	a0,a0,-1558 # 80018840 <bcache>
    80002e5e:	e3bfd0ef          	jal	80000c98 <release>
}
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6902                	ld	s2,0(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret
    panic("brelse");
    80002e6e:	00006517          	auipc	a0,0x6
    80002e72:	61a50513          	addi	a0,a0,1562 # 80009488 <etext+0x488>
    80002e76:	99dfd0ef          	jal	80000812 <panic>

0000000080002e7a <bpin>:
bpin(struct buf *b) {
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	1000                	addi	s0,sp,32
    80002e84:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002e86:	00016517          	auipc	a0,0x16
    80002e8a:	9ba50513          	addi	a0,a0,-1606 # 80018840 <bcache>
    80002e8e:	d73fd0ef          	jal	80000c00 <acquire>
  int old_ref = b->refcnt;
    80002e92:	40b0                	lw	a2,64(s1)
  b->refcnt++;
    80002e94:	0016079b          	addiw	a5,a2,1
    80002e98:	c0bc                	sw	a5,64(s1)
  bcache_report("BPIN", b, old_ref, old_valid, "Pinned buffer"); 
    80002e9a:	00006717          	auipc	a4,0x6
    80002e9e:	61670713          	addi	a4,a4,1558 # 800094b0 <etext+0x4b0>
    80002ea2:	4094                	lw	a3,0(s1)
    80002ea4:	85a6                	mv	a1,s1
    80002ea6:	00006517          	auipc	a0,0x6
    80002eaa:	61a50513          	addi	a0,a0,1562 # 800094c0 <etext+0x4c0>
    80002eae:	c23ff0ef          	jal	80002ad0 <bcache_report>
  release(&bcache.lock);
    80002eb2:	00016517          	auipc	a0,0x16
    80002eb6:	98e50513          	addi	a0,a0,-1650 # 80018840 <bcache>
    80002eba:	ddffd0ef          	jal	80000c98 <release>
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <bunpin>:
bunpin(struct buf *b) {
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	1000                	addi	s0,sp,32
    80002ed2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002ed4:	00016517          	auipc	a0,0x16
    80002ed8:	96c50513          	addi	a0,a0,-1684 # 80018840 <bcache>
    80002edc:	d25fd0ef          	jal	80000c00 <acquire>
  int old_ref = b->refcnt;
    80002ee0:	40b0                	lw	a2,64(s1)
  b->refcnt--;
    80002ee2:	fff6079b          	addiw	a5,a2,-1
    80002ee6:	c0bc                	sw	a5,64(s1)
  bcache_report("BUNPIN",b, old_ref, old_valid, "Unpinned buffer");
    80002ee8:	00006717          	auipc	a4,0x6
    80002eec:	5e070713          	addi	a4,a4,1504 # 800094c8 <etext+0x4c8>
    80002ef0:	4094                	lw	a3,0(s1)
    80002ef2:	85a6                	mv	a1,s1
    80002ef4:	00006517          	auipc	a0,0x6
    80002ef8:	5e450513          	addi	a0,a0,1508 # 800094d8 <etext+0x4d8>
    80002efc:	bd5ff0ef          	jal	80002ad0 <bcache_report>
  release(&bcache.lock);
    80002f00:	00016517          	auipc	a0,0x16
    80002f04:	94050513          	addi	a0,a0,-1728 # 80018840 <bcache>
    80002f08:	d91fd0ef          	jal	80000c98 <release>
}
    80002f0c:	60e2                	ld	ra,24(sp)
    80002f0e:	6442                	ld	s0,16(sp)
    80002f10:	64a2                	ld	s1,8(sp)
    80002f12:	6105                	addi	sp,sp,32
    80002f14:	8082                	ret

0000000080002f16 <dir_report>:
    struct inode *dp,
    char *name,
    uint target,
    uint off,
    char *details
){
    80002f16:	cb010113          	addi	sp,sp,-848
    80002f1a:	34113423          	sd	ra,840(sp)
    80002f1e:	34813023          	sd	s0,832(sp)
    80002f22:	32913c23          	sd	s1,824(sp)
    80002f26:	33213823          	sd	s2,816(sp)
    80002f2a:	33313423          	sd	s3,808(sp)
    80002f2e:	33413023          	sd	s4,800(sp)
    80002f32:	31513c23          	sd	s5,792(sp)
    80002f36:	31613823          	sd	s6,784(sp)
    80002f3a:	0e80                	addi	s0,sp,848
    80002f3c:	8b2a                	mv	s6,a0
    80002f3e:	84ae                	mv	s1,a1
    80002f40:	8932                	mv	s2,a2
    80002f42:	8ab6                	mv	s5,a3
    80002f44:	8a3a                	mv	s4,a4
    80002f46:	89be                	mv	s3,a5
    struct fs_event e;

    memset(&e, 0, sizeof(e));
    80002f48:	31000613          	li	a2,784
    80002f4c:	4581                	li	a1,0
    80002f4e:	cb040513          	addi	a0,s0,-848
    80002f52:	d83fd0ef          	jal	80000cd4 <memset>

    e.ticks = ticks;
    80002f56:	00007797          	auipc	a5,0x7
    80002f5a:	1627a783          	lw	a5,354(a5) # 8000a0b8 <ticks>
    80002f5e:	caf42c23          	sw	a5,-840(s0)
    e.pid = myproc() ? myproc()->pid : 0;
    80002f62:	9a7fe0ef          	jal	80001908 <myproc>
    80002f66:	4781                	li	a5,0
    80002f68:	c501                	beqz	a0,80002f70 <dir_report+0x5a>
    80002f6a:	99ffe0ef          	jal	80001908 <myproc>
    80002f6e:	591c                	lw	a5,48(a0)
    80002f70:	caf42e23          	sw	a5,-836(s0)

    e.type = LAYER_DIR;
    80002f74:	4795                	li	a5,5
    80002f76:	ccf42023          	sw	a5,-832(s0)

    safestrcpy(e.op_name, op, sizeof(e.op_name));
    80002f7a:	4641                	li	a2,16
    80002f7c:	85da                	mv	a1,s6
    80002f7e:	cc440513          	addi	a0,s0,-828
    80002f82:	e91fd0ef          	jal	80000e12 <safestrcpy>

    if(name)
    80002f86:	00090863          	beqz	s2,80002f96 <dir_report+0x80>
        safestrcpy(e.name, name, sizeof(e.name));
    80002f8a:	4651                	li	a2,20
    80002f8c:	85ca                	mv	a1,s2
    80002f8e:	e5840513          	addi	a0,s0,-424
    80002f92:	e81fd0ef          	jal	80000e12 <safestrcpy>

    e.parent_inum = dp ? dp->inum : -1;
    80002f96:	57fd                	li	a5,-1
    80002f98:	c091                	beqz	s1,80002f9c <dir_report+0x86>
    80002f9a:	40dc                	lw	a5,4(s1)
    80002f9c:	e6f42623          	sw	a5,-404(s0)
    e.target_inum = target;
    80002fa0:	e7542823          	sw	s5,-400(s0)
    e.offset = off;
    80002fa4:	e7442a23          	sw	s4,-396(s0)

    safestrcpy(e.details, details, sizeof(e.details));
    80002fa8:	08000613          	li	a2,128
    80002fac:	85ce                	mv	a1,s3
    80002fae:	f3c40513          	addi	a0,s0,-196
    80002fb2:	e61fd0ef          	jal	80000e12 <safestrcpy>

    fslog_push(&e);
    80002fb6:	cb040513          	addi	a0,s0,-848
    80002fba:	6a3030ef          	jal	80006e5c <fslog_push>
}
    80002fbe:	34813083          	ld	ra,840(sp)
    80002fc2:	34013403          	ld	s0,832(sp)
    80002fc6:	33813483          	ld	s1,824(sp)
    80002fca:	33013903          	ld	s2,816(sp)
    80002fce:	32813983          	ld	s3,808(sp)
    80002fd2:	32013a03          	ld	s4,800(sp)
    80002fd6:	31813a83          	ld	s5,792(sp)
    80002fda:	31013b03          	ld	s6,784(sp)
    80002fde:	35010113          	addi	sp,sp,848
    80002fe2:	8082                	ret

0000000080002fe4 <path_report>:
    char *path,
    char *elem,
    char *cwd,
    struct inode *ip,
    char *details
){
    80002fe4:	ca010113          	addi	sp,sp,-864
    80002fe8:	34113c23          	sd	ra,856(sp)
    80002fec:	34813823          	sd	s0,848(sp)
    80002ff0:	34913423          	sd	s1,840(sp)
    80002ff4:	35213023          	sd	s2,832(sp)
    80002ff8:	33313c23          	sd	s3,824(sp)
    80002ffc:	33413823          	sd	s4,816(sp)
    80003000:	33513423          	sd	s5,808(sp)
    80003004:	33613023          	sd	s6,800(sp)
    80003008:	31713c23          	sd	s7,792(sp)
    8000300c:	1680                	addi	s0,sp,864
    8000300e:	8b2a                	mv	s6,a0
    80003010:	8bae                	mv	s7,a1
    80003012:	8a32                	mv	s4,a2
    80003014:	89b6                	mv	s3,a3
    80003016:	8aba                	mv	s5,a4
    80003018:	84be                	mv	s1,a5
    8000301a:	8942                	mv	s2,a6
    struct fs_event e;

    memset(&e, 0, sizeof(e));
    8000301c:	31000613          	li	a2,784
    80003020:	4581                	li	a1,0
    80003022:	ca040513          	addi	a0,s0,-864
    80003026:	caffd0ef          	jal	80000cd4 <memset>

    e.ticks = ticks;
    8000302a:	00007797          	auipc	a5,0x7
    8000302e:	08e7a783          	lw	a5,142(a5) # 8000a0b8 <ticks>
    80003032:	caf42423          	sw	a5,-856(s0)
    e.pid = myproc() ? myproc()->pid : 0;
    80003036:	8d3fe0ef          	jal	80001908 <myproc>
    8000303a:	4781                	li	a5,0
    8000303c:	c501                	beqz	a0,80003044 <path_report+0x60>
    8000303e:	8cbfe0ef          	jal	80001908 <myproc>
    80003042:	591c                	lw	a5,48(a0)
    80003044:	caf42623          	sw	a5,-852(s0)

    e.type = LAYER_PATH;
    80003048:	4799                	li	a5,6
    8000304a:	caf42823          	sw	a5,-848(s0)

    if(op)
    8000304e:	000b8863          	beqz	s7,8000305e <path_report+0x7a>
        safestrcpy(e.op_name, op, sizeof(e.op_name));
    80003052:	4641                	li	a2,16
    80003054:	85de                	mv	a1,s7
    80003056:	cb440513          	addi	a0,s0,-844
    8000305a:	db9fd0ef          	jal	80000e12 <safestrcpy>

    if(syscall)
    8000305e:	000b0963          	beqz	s6,80003070 <path_report+0x8c>
        safestrcpy(e.syscall, syscall, sizeof(e.syscall));
    80003062:	02000613          	li	a2,32
    80003066:	85da                	mv	a1,s6
    80003068:	da840513          	addi	a0,s0,-600
    8000306c:	da7fd0ef          	jal	80000e12 <safestrcpy>

    if(cwd)
    80003070:	000a8963          	beqz	s5,80003082 <path_report+0x9e>
        safestrcpy(e.cwd, cwd, sizeof(e.cwd));
    80003074:	08000613          	li	a2,128
    80003078:	85d6                	mv	a1,s5
    8000307a:	d2840513          	addi	a0,s0,-728
    8000307e:	d95fd0ef          	jal	80000e12 <safestrcpy>

    if(path)
    80003082:	000a0963          	beqz	s4,80003094 <path_report+0xb0>
        safestrcpy(e.path, path, sizeof(e.path));
    80003086:	08000613          	li	a2,128
    8000308a:	85d2                	mv	a1,s4
    8000308c:	dc840513          	addi	a0,s0,-568
    80003090:	d83fd0ef          	jal	80000e12 <safestrcpy>

    if(elem)
    80003094:	00098863          	beqz	s3,800030a4 <path_report+0xc0>
        safestrcpy(e.name, elem, sizeof(e.name));
    80003098:	4651                	li	a2,20
    8000309a:	85ce                	mv	a1,s3
    8000309c:	e4840513          	addi	a0,s0,-440
    800030a0:	d73fd0ef          	jal	80000e12 <safestrcpy>

    e.parent_inum = ip ? ip->inum : -1;
    800030a4:	57fd                	li	a5,-1
    800030a6:	c091                	beqz	s1,800030aa <path_report+0xc6>
    800030a8:	40dc                	lw	a5,4(s1)
    800030aa:	e4f42e23          	sw	a5,-420(s0)

    if(details)
    800030ae:	00090963          	beqz	s2,800030c0 <path_report+0xdc>
        safestrcpy(e.details, details, sizeof(e.details));
    800030b2:	08000613          	li	a2,128
    800030b6:	85ca                	mv	a1,s2
    800030b8:	f2c40513          	addi	a0,s0,-212
    800030bc:	d57fd0ef          	jal	80000e12 <safestrcpy>

    fslog_push(&e);
    800030c0:	ca040513          	addi	a0,s0,-864
    800030c4:	599030ef          	jal	80006e5c <fslog_push>
}
    800030c8:	35813083          	ld	ra,856(sp)
    800030cc:	35013403          	ld	s0,848(sp)
    800030d0:	34813483          	ld	s1,840(sp)
    800030d4:	34013903          	ld	s2,832(sp)
    800030d8:	33813983          	ld	s3,824(sp)
    800030dc:	33013a03          	ld	s4,816(sp)
    800030e0:	32813a83          	ld	s5,808(sp)
    800030e4:	32013b03          	ld	s6,800(sp)
    800030e8:	31813b83          	ld	s7,792(sp)
    800030ec:	36010113          	addi	sp,sp,864
    800030f0:	8082                	ret

00000000800030f2 <balloc_report>:
void balloc_report(char* op, int blockno, int old_bit, int new_bit, char* det) {
    800030f2:	cb010113          	addi	sp,sp,-848
    800030f6:	34113423          	sd	ra,840(sp)
    800030fa:	34813023          	sd	s0,832(sp)
    800030fe:	32913c23          	sd	s1,824(sp)
    80003102:	33213823          	sd	s2,816(sp)
    80003106:	33313423          	sd	s3,808(sp)
    8000310a:	33413023          	sd	s4,800(sp)
    8000310e:	31513c23          	sd	s5,792(sp)
    80003112:	0e80                	addi	s0,sp,848
    80003114:	8aaa                	mv	s5,a0
    80003116:	8a2e                	mv	s4,a1
    80003118:	89b2                	mv	s3,a2
    8000311a:	8936                	mv	s2,a3
    8000311c:	84ba                	mv	s1,a4
    memset(&e, 0, sizeof(e));
    8000311e:	31000613          	li	a2,784
    80003122:	4581                	li	a1,0
    80003124:	cb040513          	addi	a0,s0,-848
    80003128:	badfd0ef          	jal	80000cd4 <memset>
    e.ticks = ticks;
    8000312c:	00007797          	auipc	a5,0x7
    80003130:	f8c7a783          	lw	a5,-116(a5) # 8000a0b8 <ticks>
    80003134:	caf42c23          	sw	a5,-840(s0)
    e.pid = myproc() ? myproc()->pid : 0;
    80003138:	fd0fe0ef          	jal	80001908 <myproc>
    8000313c:	4781                	li	a5,0
    8000313e:	c501                	beqz	a0,80003146 <balloc_report+0x54>
    80003140:	fc8fe0ef          	jal	80001908 <myproc>
    80003144:	591c                	lw	a5,48(a0)
    80003146:	caf42e23          	sw	a5,-836(s0)
    e.type = LAYER_BALLOC;
    8000314a:	478d                	li	a5,3
    8000314c:	ccf42023          	sw	a5,-832(s0)
    safestrcpy(e.op_name, op, 16);
    80003150:	4641                	li	a2,16
    80003152:	85d6                	mv	a1,s5
    80003154:	cc440513          	addi	a0,s0,-828
    80003158:	cbbfd0ef          	jal	80000e12 <safestrcpy>
    e.blockno = blockno;
    8000315c:	cd442a23          	sw	s4,-812(s0)
    e.old_bit = old_bit;
    80003160:	d1342423          	sw	s3,-760(s0)
    e.bit = new_bit;
    80003164:	d1242223          	sw	s2,-764(s0)
    safestrcpy(e.details, det, 128);
    80003168:	08000613          	li	a2,128
    8000316c:	85a6                	mv	a1,s1
    8000316e:	f3c40513          	addi	a0,s0,-196
    80003172:	ca1fd0ef          	jal	80000e12 <safestrcpy>
    fslog_push(&e);
    80003176:	cb040513          	addi	a0,s0,-848
    8000317a:	4e3030ef          	jal	80006e5c <fslog_push>
}
    8000317e:	34813083          	ld	ra,840(sp)
    80003182:	34013403          	ld	s0,832(sp)
    80003186:	33813483          	ld	s1,824(sp)
    8000318a:	33013903          	ld	s2,816(sp)
    8000318e:	32813983          	ld	s3,808(sp)
    80003192:	32013a03          	ld	s4,800(sp)
    80003196:	31813a83          	ld	s5,792(sp)
    8000319a:	35010113          	addi	sp,sp,848
    8000319e:	8082                	ret

00000000800031a0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	e04a                	sd	s2,0(sp)
    800031aa:	1000                	addi	s0,sp,32
    800031ac:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ae:	00d5d59b          	srliw	a1,a1,0xd
    800031b2:	0001e797          	auipc	a5,0x1e
    800031b6:	d6a7a783          	lw	a5,-662(a5) # 80020f1c <sb+0x1c>
    800031ba:	9dbd                	addw	a1,a1,a5
    800031bc:	a89ff0ef          	jal	80002c44 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031c0:	0074f793          	andi	a5,s1,7
    800031c4:	4705                	li	a4,1
    800031c6:	00f7173b          	sllw	a4,a4,a5
  if((bp->data[bi/8] & m) == 0)
    800031ca:	03349793          	slli	a5,s1,0x33
    800031ce:	93d9                	srli	a5,a5,0x36
    800031d0:	00f506b3          	add	a3,a0,a5
    800031d4:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    800031d8:	00d77633          	and	a2,a4,a3
    800031dc:	c229                	beqz	a2,8000321e <bfree+0x7e>
    800031de:	892a                	mv	s2,a0
    panic("freeing free block");
  int old_bit = 1;
  bp->data[bi/8] &= ~m;
    800031e0:	97aa                	add	a5,a5,a0
    800031e2:	fff74713          	not	a4,a4
    800031e6:	8ef9                	and	a3,a3,a4
    800031e8:	04d78c23          	sb	a3,88(a5)
  balloc_report("BFREE", b, old_bit, 0, "Freed block");
    800031ec:	00006717          	auipc	a4,0x6
    800031f0:	30c70713          	addi	a4,a4,780 # 800094f8 <etext+0x4f8>
    800031f4:	4681                	li	a3,0
    800031f6:	4605                	li	a2,1
    800031f8:	85a6                	mv	a1,s1
    800031fa:	00006517          	auipc	a0,0x6
    800031fe:	30e50513          	addi	a0,a0,782 # 80009508 <etext+0x508>
    80003202:	ef1ff0ef          	jal	800030f2 <balloc_report>
  log_write(bp);
    80003206:	854a                	mv	a0,s2
    80003208:	103010ef          	jal	80004b0a <log_write>
  brelse(bp);
    8000320c:	854a                	mv	a0,s2
    8000320e:	bcdff0ef          	jal	80002dda <brelse>
}
    80003212:	60e2                	ld	ra,24(sp)
    80003214:	6442                	ld	s0,16(sp)
    80003216:	64a2                	ld	s1,8(sp)
    80003218:	6902                	ld	s2,0(sp)
    8000321a:	6105                	addi	sp,sp,32
    8000321c:	8082                	ret
    panic("freeing free block");
    8000321e:	00006517          	auipc	a0,0x6
    80003222:	2c250513          	addi	a0,a0,706 # 800094e0 <etext+0x4e0>
    80003226:	decfd0ef          	jal	80000812 <panic>

000000008000322a <balloc>:
{
    8000322a:	711d                	addi	sp,sp,-96
    8000322c:	ec86                	sd	ra,88(sp)
    8000322e:	e8a2                	sd	s0,80(sp)
    80003230:	e4a6                	sd	s1,72(sp)
    80003232:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003234:	0001e797          	auipc	a5,0x1e
    80003238:	cd07a783          	lw	a5,-816(a5) # 80020f04 <sb+0x4>
    8000323c:	10078c63          	beqz	a5,80003354 <balloc+0x12a>
    80003240:	e0ca                	sd	s2,64(sp)
    80003242:	fc4e                	sd	s3,56(sp)
    80003244:	f852                	sd	s4,48(sp)
    80003246:	f456                	sd	s5,40(sp)
    80003248:	f05a                	sd	s6,32(sp)
    8000324a:	ec5e                	sd	s7,24(sp)
    8000324c:	e862                	sd	s8,16(sp)
    8000324e:	e466                	sd	s9,8(sp)
    80003250:	8baa                	mv	s7,a0
    80003252:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003254:	0001eb17          	auipc	s6,0x1e
    80003258:	cacb0b13          	addi	s6,s6,-852 # 80020f00 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000325e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003260:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003262:	6c89                	lui	s9,0x2
    80003264:	a059                	j	800032ea <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003266:	97ca                	add	a5,a5,s2
    80003268:	8e55                	or	a2,a2,a3
    8000326a:	04c78c23          	sb	a2,88(a5)
        balloc_report("BALLOC", b + bi, old_bit, 1, "Allocated block");
    8000326e:	00006717          	auipc	a4,0x6
    80003272:	2a270713          	addi	a4,a4,674 # 80009510 <etext+0x510>
    80003276:	4685                	li	a3,1
    80003278:	4601                	li	a2,0
    8000327a:	85a6                	mv	a1,s1
    8000327c:	00006517          	auipc	a0,0x6
    80003280:	2a450513          	addi	a0,a0,676 # 80009520 <etext+0x520>
    80003284:	e6fff0ef          	jal	800030f2 <balloc_report>
        log_write(bp);
    80003288:	854a                	mv	a0,s2
    8000328a:	081010ef          	jal	80004b0a <log_write>
        brelse(bp);
    8000328e:	854a                	mv	a0,s2
    80003290:	b4bff0ef          	jal	80002dda <brelse>
  bp = bread(dev, bno);
    80003294:	85a6                	mv	a1,s1
    80003296:	855e                	mv	a0,s7
    80003298:	9adff0ef          	jal	80002c44 <bread>
    8000329c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000329e:	40000613          	li	a2,1024
    800032a2:	4581                	li	a1,0
    800032a4:	05850513          	addi	a0,a0,88
    800032a8:	a2dfd0ef          	jal	80000cd4 <memset>
  log_write(bp);
    800032ac:	854a                	mv	a0,s2
    800032ae:	05d010ef          	jal	80004b0a <log_write>
  brelse(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	b27ff0ef          	jal	80002dda <brelse>
}
    800032b8:	6906                	ld	s2,64(sp)
    800032ba:	79e2                	ld	s3,56(sp)
    800032bc:	7a42                	ld	s4,48(sp)
    800032be:	7aa2                	ld	s5,40(sp)
    800032c0:	7b02                	ld	s6,32(sp)
    800032c2:	6be2                	ld	s7,24(sp)
    800032c4:	6c42                	ld	s8,16(sp)
    800032c6:	6ca2                	ld	s9,8(sp)
}
    800032c8:	8526                	mv	a0,s1
    800032ca:	60e6                	ld	ra,88(sp)
    800032cc:	6446                	ld	s0,80(sp)
    800032ce:	64a6                	ld	s1,72(sp)
    800032d0:	6125                	addi	sp,sp,96
    800032d2:	8082                	ret
    brelse(bp);
    800032d4:	854a                	mv	a0,s2
    800032d6:	b05ff0ef          	jal	80002dda <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032da:	015c87bb          	addw	a5,s9,s5
    800032de:	00078a9b          	sext.w	s5,a5
    800032e2:	004b2703          	lw	a4,4(s6)
    800032e6:	04eaff63          	bgeu	s5,a4,80003344 <balloc+0x11a>
    bp = bread(dev, BBLOCK(b, sb));
    800032ea:	41fad79b          	sraiw	a5,s5,0x1f
    800032ee:	0137d79b          	srliw	a5,a5,0x13
    800032f2:	015787bb          	addw	a5,a5,s5
    800032f6:	40d7d79b          	sraiw	a5,a5,0xd
    800032fa:	01cb2583          	lw	a1,28(s6)
    800032fe:	9dbd                	addw	a1,a1,a5
    80003300:	855e                	mv	a0,s7
    80003302:	943ff0ef          	jal	80002c44 <bread>
    80003306:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003308:	004b2503          	lw	a0,4(s6)
    8000330c:	000a849b          	sext.w	s1,s5
    80003310:	8762                	mv	a4,s8
    80003312:	fca4f1e3          	bgeu	s1,a0,800032d4 <balloc+0xaa>
      m = 1 << (bi % 8);
    80003316:	00777693          	andi	a3,a4,7
    8000331a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){
    8000331e:	41f7579b          	sraiw	a5,a4,0x1f
    80003322:	01d7d79b          	srliw	a5,a5,0x1d
    80003326:	9fb9                	addw	a5,a5,a4
    80003328:	4037d79b          	sraiw	a5,a5,0x3
    8000332c:	00f90633          	add	a2,s2,a5
    80003330:	05864603          	lbu	a2,88(a2)
    80003334:	00c6f5b3          	and	a1,a3,a2
    80003338:	d59d                	beqz	a1,80003266 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333a:	2705                	addiw	a4,a4,1
    8000333c:	2485                	addiw	s1,s1,1
    8000333e:	fd471ae3          	bne	a4,s4,80003312 <balloc+0xe8>
    80003342:	bf49                	j	800032d4 <balloc+0xaa>
    80003344:	6906                	ld	s2,64(sp)
    80003346:	79e2                	ld	s3,56(sp)
    80003348:	7a42                	ld	s4,48(sp)
    8000334a:	7aa2                	ld	s5,40(sp)
    8000334c:	7b02                	ld	s6,32(sp)
    8000334e:	6be2                	ld	s7,24(sp)
    80003350:	6c42                	ld	s8,16(sp)
    80003352:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003354:	00006517          	auipc	a0,0x6
    80003358:	1d450513          	addi	a0,a0,468 # 80009528 <etext+0x528>
    8000335c:	9d0fd0ef          	jal	8000052c <printf>
  return 0;
    80003360:	4481                	li	s1,0
    80003362:	b79d                	j	800032c8 <balloc+0x9e>

0000000080003364 <inode_report>:
{
    80003364:	ca010113          	addi	sp,sp,-864
    80003368:	34113c23          	sd	ra,856(sp)
    8000336c:	34813823          	sd	s0,848(sp)
    80003370:	34913423          	sd	s1,840(sp)
    80003374:	35213023          	sd	s2,832(sp)
    80003378:	33313c23          	sd	s3,824(sp)
    8000337c:	33413823          	sd	s4,816(sp)
    80003380:	33513423          	sd	s5,808(sp)
    80003384:	33613023          	sd	s6,800(sp)
    80003388:	31713c23          	sd	s7,792(sp)
    8000338c:	31813823          	sd	s8,784(sp)
    80003390:	1680                	addi	s0,sp,864
    80003392:	8c2a                	mv	s8,a0
    80003394:	84ae                	mv	s1,a1
    80003396:	8bb2                	mv	s7,a2
    80003398:	8b36                	mv	s6,a3
    8000339a:	8aba                	mv	s5,a4
    8000339c:	8a3e                	mv	s4,a5
    8000339e:	89c2                	mv	s3,a6
    800033a0:	8946                	mv	s2,a7
  memset(&e, 0, sizeof(e));
    800033a2:	31000613          	li	a2,784
    800033a6:	4581                	li	a1,0
    800033a8:	ca040513          	addi	a0,s0,-864
    800033ac:	929fd0ef          	jal	80000cd4 <memset>
  e.ticks = ticks;
    800033b0:	00007797          	auipc	a5,0x7
    800033b4:	d087a783          	lw	a5,-760(a5) # 8000a0b8 <ticks>
    800033b8:	caf42423          	sw	a5,-856(s0)
  e.pid = myproc() ? myproc()->pid : 0;
    800033bc:	d4cfe0ef          	jal	80001908 <myproc>
    800033c0:	4781                	li	a5,0
    800033c2:	c501                	beqz	a0,800033ca <inode_report+0x66>
    800033c4:	d44fe0ef          	jal	80001908 <myproc>
    800033c8:	591c                	lw	a5,48(a0)
    800033ca:	caf42623          	sw	a5,-852(s0)
  e.type = LAYER_INODE;
    800033ce:	4791                	li	a5,4
    800033d0:	caf42823          	sw	a5,-848(s0)
  safestrcpy(e.op_name, op, 16);
    800033d4:	4641                	li	a2,16
    800033d6:	85e2                	mv	a1,s8
    800033d8:	cb440513          	addi	a0,s0,-844
    800033dc:	a37fd0ef          	jal	80000e12 <safestrcpy>
  e.inum = ip->inum;
    800033e0:	40dc                	lw	a5,4(s1)
    800033e2:	cef42e23          	sw	a5,-772(s0)
  e.ref = ip->ref;
    800033e6:	449c                	lw	a5,8(s1)
    800033e8:	d0f42023          	sw	a5,-768(s0)
  e.old_ref = old_ref;
    800033ec:	d1742223          	sw	s7,-764(s0)
  e.valid_inode = ip->valid;
    800033f0:	40bc                	lw	a5,64(s1)
    800033f2:	d0f42423          	sw	a5,-760(s0)
  e.old_valid_inode = old_valid;
    800033f6:	d1642623          	sw	s6,-756(s0)
  e.inode_type = ip->type;
    800033fa:	04449783          	lh	a5,68(s1)
    800033fe:	d0f42823          	sw	a5,-752(s0)
  e.old_type_inode = old_type;
    80003402:	d1542a23          	sw	s5,-748(s0)
  e.size = ip->size;
    80003406:	44fc                	lw	a5,76(s1)
    80003408:	d0f42c23          	sw	a5,-744(s0)
  e.old_size = old_size;
    8000340c:	d1442e23          	sw	s4,-740(s0)
  e.locked = holdingsleep(&ip->lock);
    80003410:	01048513          	addi	a0,s1,16
    80003414:	093010ef          	jal	80004ca6 <holdingsleep>
    80003418:	d2a42023          	sw	a0,-736(s0)
  e.old_locked = old_locked;
    8000341c:	d3342223          	sw	s3,-732(s0)
  safestrcpy(e.details, det, 128);
    80003420:	08000613          	li	a2,128
    80003424:	85ca                	mv	a1,s2
    80003426:	f2c40513          	addi	a0,s0,-212
    8000342a:	9e9fd0ef          	jal	80000e12 <safestrcpy>
  fslog_push(&e);
    8000342e:	ca040513          	addi	a0,s0,-864
    80003432:	22b030ef          	jal	80006e5c <fslog_push>
}
    80003436:	35813083          	ld	ra,856(sp)
    8000343a:	35013403          	ld	s0,848(sp)
    8000343e:	34813483          	ld	s1,840(sp)
    80003442:	34013903          	ld	s2,832(sp)
    80003446:	33813983          	ld	s3,824(sp)
    8000344a:	33013a03          	ld	s4,816(sp)
    8000344e:	32813a83          	ld	s5,808(sp)
    80003452:	32013b03          	ld	s6,800(sp)
    80003456:	31813b83          	ld	s7,792(sp)
    8000345a:	31013c03          	ld	s8,784(sp)
    8000345e:	36010113          	addi	sp,sp,864
    80003462:	8082                	ret

0000000080003464 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
    80003464:	7139                	addi	sp,sp,-64
    80003466:	fc06                	sd	ra,56(sp)
    80003468:	f822                	sd	s0,48(sp)
    8000346a:	f426                	sd	s1,40(sp)
    8000346c:	f04a                	sd	s2,32(sp)
    8000346e:	ec4e                	sd	s3,24(sp)
    80003470:	e852                	sd	s4,16(sp)
    80003472:	e456                	sd	s5,8(sp)
    80003474:	0080                	addi	s0,sp,64
    80003476:	8a2a                	mv	s4,a0
    80003478:	8aae                	mv	s5,a1
  struct inode *ip, *empty;

  acquire(&itable.lock);
    8000347a:	0001e517          	auipc	a0,0x1e
    8000347e:	aa650513          	addi	a0,a0,-1370 # 80020f20 <itable>
    80003482:	f7efd0ef          	jal	80000c00 <acquire>

  // Is the inode already in the table?
  empty = 0;
    80003486:	4981                	li	s3,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003488:	0001e497          	auipc	s1,0x1e
    8000348c:	ab048493          	addi	s1,s1,-1360 # 80020f38 <itable+0x18>
    80003490:	0001f717          	auipc	a4,0x1f
    80003494:	53870713          	addi	a4,a4,1336 # 800229c8 <log>
    80003498:	a039                	j	800034a6 <iget+0x42>
      holdingsleep(&ip->lock),
      "Inode found in cache");
      release(&itable.lock);
      return ip;
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349a:	06098563          	beqz	s3,80003504 <iget+0xa0>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349e:	08848493          	addi	s1,s1,136
    800034a2:	06e48563          	beq	s1,a4,8000350c <iget+0xa8>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a6:	0084a903          	lw	s2,8(s1)
    800034aa:	ff2058e3          	blez	s2,8000349a <iget+0x36>
    800034ae:	409c                	lw	a5,0(s1)
    800034b0:	ff4795e3          	bne	a5,s4,8000349a <iget+0x36>
    800034b4:	40dc                	lw	a5,4(s1)
    800034b6:	ff5792e3          	bne	a5,s5,8000349a <iget+0x36>
      ip->ref++;
    800034ba:	0019079b          	addiw	a5,s2,1
    800034be:	c49c                	sw	a5,8(s1)
       inode_report("IGET_HIT", ip,
    800034c0:	0404a983          	lw	s3,64(s1)
    800034c4:	04449a03          	lh	s4,68(s1)
    800034c8:	04c4aa83          	lw	s5,76(s1)
    800034cc:	01048513          	addi	a0,s1,16
    800034d0:	7d6010ef          	jal	80004ca6 <holdingsleep>
    800034d4:	00006897          	auipc	a7,0x6
    800034d8:	06c88893          	addi	a7,a7,108 # 80009540 <etext+0x540>
    800034dc:	882a                	mv	a6,a0
    800034de:	87d6                	mv	a5,s5
    800034e0:	8752                	mv	a4,s4
    800034e2:	86ce                	mv	a3,s3
    800034e4:	864a                	mv	a2,s2
    800034e6:	85a6                	mv	a1,s1
    800034e8:	00006517          	auipc	a0,0x6
    800034ec:	07050513          	addi	a0,a0,112 # 80009558 <etext+0x558>
    800034f0:	e75ff0ef          	jal	80003364 <inode_report>
      release(&itable.lock);
    800034f4:	0001e517          	auipc	a0,0x1e
    800034f8:	a2c50513          	addi	a0,a0,-1492 # 80020f20 <itable>
    800034fc:	f9cfd0ef          	jal	80000c98 <release>
      return ip;
    80003500:	89a6                	mv	s3,s1
    80003502:	a0b1                	j	8000354e <iget+0xea>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003504:	f8091de3          	bnez	s2,8000349e <iget+0x3a>
      empty = ip;
    80003508:	89a6                	mv	s3,s1
    8000350a:	bf51                	j	8000349e <iget+0x3a>
  }

  // Recycle an inode entry.
  if(empty == 0)
    8000350c:	04098b63          	beqz	s3,80003562 <iget+0xfe>
    panic("iget: no inodes");

  ip = empty;
  ip->dev = dev;
    80003510:	0149a023          	sw	s4,0(s3)
  ip->inum = inum;
    80003514:	0159a223          	sw	s5,4(s3)
  ip->ref = 1;
    80003518:	4785                	li	a5,1
    8000351a:	00f9a423          	sw	a5,8(s3)
  ip->valid = 0;
    8000351e:	0409a023          	sw	zero,64(s3)
  inode_report("IGET_NEW", ip,
    80003522:	00006897          	auipc	a7,0x6
    80003526:	05688893          	addi	a7,a7,86 # 80009578 <etext+0x578>
    8000352a:	4801                	li	a6,0
    8000352c:	4781                	li	a5,0
    8000352e:	4701                	li	a4,0
    80003530:	4681                	li	a3,0
    80003532:	4601                	li	a2,0
    80003534:	85ce                	mv	a1,s3
    80003536:	00006517          	auipc	a0,0x6
    8000353a:	06250513          	addi	a0,a0,98 # 80009598 <etext+0x598>
    8000353e:	e27ff0ef          	jal	80003364 <inode_report>
    0, 0,
    0, 0,
    0,
    "Allocated new inode in table");
  release(&itable.lock);
    80003542:	0001e517          	auipc	a0,0x1e
    80003546:	9de50513          	addi	a0,a0,-1570 # 80020f20 <itable>
    8000354a:	f4efd0ef          	jal	80000c98 <release>

  return ip;
}
    8000354e:	854e                	mv	a0,s3
    80003550:	70e2                	ld	ra,56(sp)
    80003552:	7442                	ld	s0,48(sp)
    80003554:	74a2                	ld	s1,40(sp)
    80003556:	7902                	ld	s2,32(sp)
    80003558:	69e2                	ld	s3,24(sp)
    8000355a:	6a42                	ld	s4,16(sp)
    8000355c:	6aa2                	ld	s5,8(sp)
    8000355e:	6121                	addi	sp,sp,64
    80003560:	8082                	ret
    panic("iget: no inodes");
    80003562:	00006517          	auipc	a0,0x6
    80003566:	00650513          	addi	a0,a0,6 # 80009568 <etext+0x568>
    8000356a:	aa8fd0ef          	jal	80000812 <panic>

000000008000356e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000356e:	7179                	addi	sp,sp,-48
    80003570:	f406                	sd	ra,40(sp)
    80003572:	f022                	sd	s0,32(sp)
    80003574:	ec26                	sd	s1,24(sp)
    80003576:	e84a                	sd	s2,16(sp)
    80003578:	e44e                	sd	s3,8(sp)
    8000357a:	1800                	addi	s0,sp,48
    8000357c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000357e:	47ad                	li	a5,11
    80003580:	04b7ea63          	bltu	a5,a1,800035d4 <bmap+0x66>
    if((addr = ip->addrs[bn]) == 0){
    80003584:	02059793          	slli	a5,a1,0x20
    80003588:	01e7d593          	srli	a1,a5,0x1e
    8000358c:	00b504b3          	add	s1,a0,a1
    80003590:	0504a983          	lw	s3,80(s1)
    80003594:	0c099263          	bnez	s3,80003658 <bmap+0xea>
      addr = balloc(ip->dev);
    80003598:	4108                	lw	a0,0(a0)
    8000359a:	c91ff0ef          	jal	8000322a <balloc>
    8000359e:	0005099b          	sext.w	s3,a0

      inode_report("BMAP_ALLOC_DIRECT", ip,
    800035a2:	00006897          	auipc	a7,0x6
    800035a6:	00688893          	addi	a7,a7,6 # 800095a8 <etext+0x5a8>
    800035aa:	4805                	li	a6,1
    800035ac:	04c92783          	lw	a5,76(s2)
    800035b0:	04491703          	lh	a4,68(s2)
    800035b4:	04092683          	lw	a3,64(s2)
    800035b8:	00892603          	lw	a2,8(s2)
    800035bc:	85ca                	mv	a1,s2
    800035be:	00006517          	auipc	a0,0x6
    800035c2:	00250513          	addi	a0,a0,2 # 800095c0 <etext+0x5c0>
    800035c6:	d9fff0ef          	jal	80003364 <inode_report>
        ip->valid,
        ip->type,
        ip->size,
        1,
        "Allocated direct block");
      if(addr == 0)
    800035ca:	08098763          	beqz	s3,80003658 <bmap+0xea>
        return 0;
      ip->addrs[bn] = addr;
    800035ce:	0534a823          	sw	s3,80(s1)
    800035d2:	a059                	j	80003658 <bmap+0xea>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035d4:	ff45849b          	addiw	s1,a1,-12
    800035d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035dc:	0ff00793          	li	a5,255
    800035e0:	0ce7e663          	bltu	a5,a4,800036ac <bmap+0x13e>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035e4:	08052983          	lw	s3,128(a0)
    800035e8:	04099163          	bnez	s3,8000362a <bmap+0xbc>
      addr = balloc(ip->dev);
    800035ec:	4108                	lw	a0,0(a0)
    800035ee:	c3dff0ef          	jal	8000322a <balloc>
    800035f2:	0005099b          	sext.w	s3,a0
      inode_report("BMAP_ALLOC_INDIRECT", ip,
    800035f6:	00006897          	auipc	a7,0x6
    800035fa:	fe288893          	addi	a7,a7,-30 # 800095d8 <etext+0x5d8>
    800035fe:	4805                	li	a6,1
    80003600:	04c92783          	lw	a5,76(s2)
    80003604:	04491703          	lh	a4,68(s2)
    80003608:	04092683          	lw	a3,64(s2)
    8000360c:	00892603          	lw	a2,8(s2)
    80003610:	85ca                	mv	a1,s2
    80003612:	00006517          	auipc	a0,0x6
    80003616:	fe650513          	addi	a0,a0,-26 # 800095f8 <etext+0x5f8>
    8000361a:	d4bff0ef          	jal	80003364 <inode_report>
        ip->valid,
        ip->type,
        ip->size,
        1,
        "Allocated indirect block table");
      if(addr == 0)
    8000361e:	02098d63          	beqz	s3,80003658 <bmap+0xea>
    80003622:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003624:	09392023          	sw	s3,128(s2)
    80003628:	a011                	j	8000362c <bmap+0xbe>
    8000362a:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    8000362c:	85ce                	mv	a1,s3
    8000362e:	00092503          	lw	a0,0(s2)
    80003632:	e12ff0ef          	jal	80002c44 <bread>
    80003636:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003638:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000363c:	02049713          	slli	a4,s1,0x20
    80003640:	01e75593          	srli	a1,a4,0x1e
    80003644:	00b784b3          	add	s1,a5,a1
    80003648:	0004a983          	lw	s3,0(s1)
    8000364c:	00098e63          	beqz	s3,80003668 <bmap+0xfa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003650:	8552                	mv	a0,s4
    80003652:	f88ff0ef          	jal	80002dda <brelse>
    return addr;
    80003656:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003658:	854e                	mv	a0,s3
    8000365a:	70a2                	ld	ra,40(sp)
    8000365c:	7402                	ld	s0,32(sp)
    8000365e:	64e2                	ld	s1,24(sp)
    80003660:	6942                	ld	s2,16(sp)
    80003662:	69a2                	ld	s3,8(sp)
    80003664:	6145                	addi	sp,sp,48
    80003666:	8082                	ret
      inode_report("BMAP_ALLOC_DATA", ip,
    80003668:	00006897          	auipc	a7,0x6
    8000366c:	fa888893          	addi	a7,a7,-88 # 80009610 <etext+0x610>
    80003670:	4805                	li	a6,1
    80003672:	04c92783          	lw	a5,76(s2)
    80003676:	04491703          	lh	a4,68(s2)
    8000367a:	04092683          	lw	a3,64(s2)
    8000367e:	00892603          	lw	a2,8(s2)
    80003682:	85ca                	mv	a1,s2
    80003684:	00006517          	auipc	a0,0x6
    80003688:	fac50513          	addi	a0,a0,-84 # 80009630 <etext+0x630>
    8000368c:	cd9ff0ef          	jal	80003364 <inode_report>
      addr = balloc(ip->dev);
    80003690:	00092503          	lw	a0,0(s2)
    80003694:	b97ff0ef          	jal	8000322a <balloc>
    80003698:	0005099b          	sext.w	s3,a0
      if(addr){
    8000369c:	fa098ae3          	beqz	s3,80003650 <bmap+0xe2>
        a[bn] = addr;
    800036a0:	0134a023          	sw	s3,0(s1)
        log_write(bp);
    800036a4:	8552                	mv	a0,s4
    800036a6:	464010ef          	jal	80004b0a <log_write>
    800036aa:	b75d                	j	80003650 <bmap+0xe2>
    800036ac:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    800036ae:	00006517          	auipc	a0,0x6
    800036b2:	f9250513          	addi	a0,a0,-110 # 80009640 <etext+0x640>
    800036b6:	95cfd0ef          	jal	80000812 <panic>

00000000800036ba <iinit>:
{
    800036ba:	7179                	addi	sp,sp,-48
    800036bc:	f406                	sd	ra,40(sp)
    800036be:	f022                	sd	s0,32(sp)
    800036c0:	ec26                	sd	s1,24(sp)
    800036c2:	e84a                	sd	s2,16(sp)
    800036c4:	e44e                	sd	s3,8(sp)
    800036c6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036c8:	00006597          	auipc	a1,0x6
    800036cc:	f9058593          	addi	a1,a1,-112 # 80009658 <etext+0x658>
    800036d0:	0001e517          	auipc	a0,0x1e
    800036d4:	85050513          	addi	a0,a0,-1968 # 80020f20 <itable>
    800036d8:	ca8fd0ef          	jal	80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036dc:	0001e497          	auipc	s1,0x1e
    800036e0:	86c48493          	addi	s1,s1,-1940 # 80020f48 <itable+0x28>
    800036e4:	0001f997          	auipc	s3,0x1f
    800036e8:	2f498993          	addi	s3,s3,756 # 800229d8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036ec:	00006917          	auipc	s2,0x6
    800036f0:	ffc90913          	addi	s2,s2,-4 # 800096e8 <etext+0x6e8>
    800036f4:	85ca                	mv	a1,s2
    800036f6:	8526                	mv	a0,s1
    800036f8:	4fa010ef          	jal	80004bf2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036fc:	08848493          	addi	s1,s1,136
    80003700:	ff349ae3          	bne	s1,s3,800036f4 <iinit+0x3a>
}
    80003704:	70a2                	ld	ra,40(sp)
    80003706:	7402                	ld	s0,32(sp)
    80003708:	64e2                	ld	s1,24(sp)
    8000370a:	6942                	ld	s2,16(sp)
    8000370c:	69a2                	ld	s3,8(sp)
    8000370e:	6145                	addi	sp,sp,48
    80003710:	8082                	ret

0000000080003712 <ialloc>:
{
    80003712:	7139                	addi	sp,sp,-64
    80003714:	fc06                	sd	ra,56(sp)
    80003716:	f822                	sd	s0,48(sp)
    80003718:	f04a                	sd	s2,32(sp)
    8000371a:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    8000371c:	0001d717          	auipc	a4,0x1d
    80003720:	7f072703          	lw	a4,2032(a4) # 80020f0c <sb+0xc>
    80003724:	4785                	li	a5,1
    80003726:	04e7fe63          	bgeu	a5,a4,80003782 <ialloc+0x70>
    8000372a:	f426                	sd	s1,40(sp)
    8000372c:	ec4e                	sd	s3,24(sp)
    8000372e:	e852                	sd	s4,16(sp)
    80003730:	e456                	sd	s5,8(sp)
    80003732:	e05a                	sd	s6,0(sp)
    80003734:	8aaa                	mv	s5,a0
    80003736:	8b2e                	mv	s6,a1
    80003738:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000373a:	0001da17          	auipc	s4,0x1d
    8000373e:	7c6a0a13          	addi	s4,s4,1990 # 80020f00 <sb>
    80003742:	00495593          	srli	a1,s2,0x4
    80003746:	018a2783          	lw	a5,24(s4)
    8000374a:	9dbd                	addw	a1,a1,a5
    8000374c:	8556                	mv	a0,s5
    8000374e:	cf6ff0ef          	jal	80002c44 <bread>
    80003752:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003754:	05850993          	addi	s3,a0,88
    80003758:	00f97793          	andi	a5,s2,15
    8000375c:	079a                	slli	a5,a5,0x6
    8000375e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003760:	00099783          	lh	a5,0(s3)
    80003764:	cf85                	beqz	a5,8000379c <ialloc+0x8a>
    brelse(bp);
    80003766:	e74ff0ef          	jal	80002dda <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000376a:	0905                	addi	s2,s2,1
    8000376c:	00ca2703          	lw	a4,12(s4)
    80003770:	0009079b          	sext.w	a5,s2
    80003774:	fce7e7e3          	bltu	a5,a4,80003742 <ialloc+0x30>
    80003778:	74a2                	ld	s1,40(sp)
    8000377a:	69e2                	ld	s3,24(sp)
    8000377c:	6a42                	ld	s4,16(sp)
    8000377e:	6aa2                	ld	s5,8(sp)
    80003780:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003782:	00006517          	auipc	a0,0x6
    80003786:	efe50513          	addi	a0,a0,-258 # 80009680 <etext+0x680>
    8000378a:	da3fc0ef          	jal	8000052c <printf>
  return 0;
    8000378e:	4901                	li	s2,0
}
    80003790:	854a                	mv	a0,s2
    80003792:	70e2                	ld	ra,56(sp)
    80003794:	7442                	ld	s0,48(sp)
    80003796:	7902                	ld	s2,32(sp)
    80003798:	6121                	addi	sp,sp,64
    8000379a:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000379c:	04000613          	li	a2,64
    800037a0:	4581                	li	a1,0
    800037a2:	854e                	mv	a0,s3
    800037a4:	d30fd0ef          	jal	80000cd4 <memset>
      dip->type = type;
    800037a8:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037ac:	8526                	mv	a0,s1
    800037ae:	35c010ef          	jal	80004b0a <log_write>
      struct inode *ip = iget(dev, inum);
    800037b2:	0009059b          	sext.w	a1,s2
    800037b6:	8556                	mv	a0,s5
    800037b8:	cadff0ef          	jal	80003464 <iget>
    800037bc:	892a                	mv	s2,a0
      inode_report("IALLOC", ip,
    800037be:	00006897          	auipc	a7,0x6
    800037c2:	ea288893          	addi	a7,a7,-350 # 80009660 <etext+0x660>
    800037c6:	4801                	li	a6,0
    800037c8:	4781                	li	a5,0
    800037ca:	4701                	li	a4,0
    800037cc:	4681                	li	a3,0
    800037ce:	4601                	li	a2,0
    800037d0:	85aa                	mv	a1,a0
    800037d2:	00006517          	auipc	a0,0x6
    800037d6:	ea650513          	addi	a0,a0,-346 # 80009678 <etext+0x678>
    800037da:	b8bff0ef          	jal	80003364 <inode_report>
      brelse(bp);
    800037de:	8526                	mv	a0,s1
    800037e0:	dfaff0ef          	jal	80002dda <brelse>
      return ip;
    800037e4:	74a2                	ld	s1,40(sp)
    800037e6:	69e2                	ld	s3,24(sp)
    800037e8:	6a42                	ld	s4,16(sp)
    800037ea:	6aa2                	ld	s5,8(sp)
    800037ec:	6b02                	ld	s6,0(sp)
    800037ee:	b74d                	j	80003790 <ialloc+0x7e>

00000000800037f0 <iupdate>:
{
    800037f0:	1101                	addi	sp,sp,-32
    800037f2:	ec06                	sd	ra,24(sp)
    800037f4:	e822                	sd	s0,16(sp)
    800037f6:	e426                	sd	s1,8(sp)
    800037f8:	e04a                	sd	s2,0(sp)
    800037fa:	1000                	addi	s0,sp,32
    800037fc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fe:	415c                	lw	a5,4(a0)
    80003800:	0047d79b          	srliw	a5,a5,0x4
    80003804:	0001d597          	auipc	a1,0x1d
    80003808:	7145a583          	lw	a1,1812(a1) # 80020f18 <sb+0x18>
    8000380c:	9dbd                	addw	a1,a1,a5
    8000380e:	4108                	lw	a0,0(a0)
    80003810:	c34ff0ef          	jal	80002c44 <bread>
    80003814:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003816:	05850793          	addi	a5,a0,88
    8000381a:	40d8                	lw	a4,4(s1)
    8000381c:	8b3d                	andi	a4,a4,15
    8000381e:	071a                	slli	a4,a4,0x6
    80003820:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003822:	04449703          	lh	a4,68(s1)
    80003826:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000382a:	04649703          	lh	a4,70(s1)
    8000382e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003832:	04849703          	lh	a4,72(s1)
    80003836:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000383a:	04a49703          	lh	a4,74(s1)
    8000383e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003842:	44f8                	lw	a4,76(s1)
    80003844:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003846:	03400613          	li	a2,52
    8000384a:	05048593          	addi	a1,s1,80
    8000384e:	00c78513          	addi	a0,a5,12
    80003852:	cdefd0ef          	jal	80000d30 <memmove>
  inode_report("IUPDATE", ip,
    80003856:	00006897          	auipc	a7,0x6
    8000385a:	e4288893          	addi	a7,a7,-446 # 80009698 <etext+0x698>
    8000385e:	4805                	li	a6,1
    80003860:	44fc                	lw	a5,76(s1)
    80003862:	04449703          	lh	a4,68(s1)
    80003866:	40b4                	lw	a3,64(s1)
    80003868:	4490                	lw	a2,8(s1)
    8000386a:	85a6                	mv	a1,s1
    8000386c:	00006517          	auipc	a0,0x6
    80003870:	e4450513          	addi	a0,a0,-444 # 800096b0 <etext+0x6b0>
    80003874:	af1ff0ef          	jal	80003364 <inode_report>
  log_write(bp);
    80003878:	854a                	mv	a0,s2
    8000387a:	290010ef          	jal	80004b0a <log_write>
  brelse(bp);
    8000387e:	854a                	mv	a0,s2
    80003880:	d5aff0ef          	jal	80002dda <brelse>
}
    80003884:	60e2                	ld	ra,24(sp)
    80003886:	6442                	ld	s0,16(sp)
    80003888:	64a2                	ld	s1,8(sp)
    8000388a:	6902                	ld	s2,0(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret

0000000080003890 <idup>:
{
    80003890:	1101                	addi	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	1000                	addi	s0,sp,32
    8000389a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000389c:	0001d517          	auipc	a0,0x1d
    800038a0:	68450513          	addi	a0,a0,1668 # 80020f20 <itable>
    800038a4:	b5cfd0ef          	jal	80000c00 <acquire>
  int old_ref = ip->ref;
    800038a8:	4490                	lw	a2,8(s1)
  ip->ref++;
    800038aa:	0016079b          	addiw	a5,a2,1
    800038ae:	c49c                	sw	a5,8(s1)
  inode_report("IDUP", ip,
    800038b0:	00006897          	auipc	a7,0x6
    800038b4:	e0888893          	addi	a7,a7,-504 # 800096b8 <etext+0x6b8>
    800038b8:	4801                	li	a6,0
    800038ba:	44fc                	lw	a5,76(s1)
    800038bc:	04449703          	lh	a4,68(s1)
    800038c0:	40b4                	lw	a3,64(s1)
    800038c2:	85a6                	mv	a1,s1
    800038c4:	00006517          	auipc	a0,0x6
    800038c8:	e0c50513          	addi	a0,a0,-500 # 800096d0 <etext+0x6d0>
    800038cc:	a99ff0ef          	jal	80003364 <inode_report>
  release(&itable.lock);
    800038d0:	0001d517          	auipc	a0,0x1d
    800038d4:	65050513          	addi	a0,a0,1616 # 80020f20 <itable>
    800038d8:	bc0fd0ef          	jal	80000c98 <release>
}
    800038dc:	8526                	mv	a0,s1
    800038de:	60e2                	ld	ra,24(sp)
    800038e0:	6442                	ld	s0,16(sp)
    800038e2:	64a2                	ld	s1,8(sp)
    800038e4:	6105                	addi	sp,sp,32
    800038e6:	8082                	ret

00000000800038e8 <ilock>:
{
    800038e8:	1101                	addi	sp,sp,-32
    800038ea:	ec06                	sd	ra,24(sp)
    800038ec:	e822                	sd	s0,16(sp)
    800038ee:	e426                	sd	s1,8(sp)
    800038f0:	e04a                	sd	s2,0(sp)
    800038f2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038f4:	c139                	beqz	a0,8000393a <ilock+0x52>
    800038f6:	84aa                	mv	s1,a0
    800038f8:	451c                	lw	a5,8(a0)
    800038fa:	04f05063          	blez	a5,8000393a <ilock+0x52>
   int old_valid = ip->valid;
    800038fe:	04052903          	lw	s2,64(a0)
  acquiresleep(&ip->lock);
    80003902:	0541                	addi	a0,a0,16
    80003904:	324010ef          	jal	80004c28 <acquiresleep>
  inode_report("ILOCK_ACQUIRE", ip,
    80003908:	00006897          	auipc	a7,0x6
    8000390c:	dd888893          	addi	a7,a7,-552 # 800096e0 <etext+0x6e0>
    80003910:	4801                	li	a6,0
    80003912:	44fc                	lw	a5,76(s1)
    80003914:	04449703          	lh	a4,68(s1)
    80003918:	86ca                	mv	a3,s2
    8000391a:	4490                	lw	a2,8(s1)
    8000391c:	85a6                	mv	a1,s1
    8000391e:	00006517          	auipc	a0,0x6
    80003922:	dd250513          	addi	a0,a0,-558 # 800096f0 <etext+0x6f0>
    80003926:	a3fff0ef          	jal	80003364 <inode_report>
  if(ip->valid == 0){
    8000392a:	40bc                	lw	a5,64(s1)
    8000392c:	cf89                	beqz	a5,80003946 <ilock+0x5e>
}
    8000392e:	60e2                	ld	ra,24(sp)
    80003930:	6442                	ld	s0,16(sp)
    80003932:	64a2                	ld	s1,8(sp)
    80003934:	6902                	ld	s2,0(sp)
    80003936:	6105                	addi	sp,sp,32
    80003938:	8082                	ret
    panic("ilock");
    8000393a:	00006517          	auipc	a0,0x6
    8000393e:	d9e50513          	addi	a0,a0,-610 # 800096d8 <etext+0x6d8>
    80003942:	ed1fc0ef          	jal	80000812 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003946:	40dc                	lw	a5,4(s1)
    80003948:	0047d79b          	srliw	a5,a5,0x4
    8000394c:	0001d597          	auipc	a1,0x1d
    80003950:	5cc5a583          	lw	a1,1484(a1) # 80020f18 <sb+0x18>
    80003954:	9dbd                	addw	a1,a1,a5
    80003956:	4088                	lw	a0,0(s1)
    80003958:	aecff0ef          	jal	80002c44 <bread>
    8000395c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395e:	05850593          	addi	a1,a0,88
    80003962:	40dc                	lw	a5,4(s1)
    80003964:	8bbd                	andi	a5,a5,15
    80003966:	079a                	slli	a5,a5,0x6
    80003968:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000396a:	00059783          	lh	a5,0(a1)
    8000396e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003972:	00259783          	lh	a5,2(a1)
    80003976:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000397a:	00459783          	lh	a5,4(a1)
    8000397e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003982:	00659783          	lh	a5,6(a1)
    80003986:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000398a:	459c                	lw	a5,8(a1)
    8000398c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000398e:	03400613          	li	a2,52
    80003992:	05b1                	addi	a1,a1,12
    80003994:	05048513          	addi	a0,s1,80
    80003998:	b98fd0ef          	jal	80000d30 <memmove>
    brelse(bp);
    8000399c:	854a                	mv	a0,s2
    8000399e:	c3cff0ef          	jal	80002dda <brelse>
    ip->valid = 1;
    800039a2:	4785                	li	a5,1
    800039a4:	c0bc                	sw	a5,64(s1)
    inode_report("ILOCK_LOAD", ip,
    800039a6:	00006897          	auipc	a7,0x6
    800039aa:	d5a88893          	addi	a7,a7,-678 # 80009700 <etext+0x700>
    800039ae:	4805                	li	a6,1
    800039b0:	44fc                	lw	a5,76(s1)
    800039b2:	04449703          	lh	a4,68(s1)
    800039b6:	4681                	li	a3,0
    800039b8:	4490                	lw	a2,8(s1)
    800039ba:	85a6                	mv	a1,s1
    800039bc:	00006517          	auipc	a0,0x6
    800039c0:	d5c50513          	addi	a0,a0,-676 # 80009718 <etext+0x718>
    800039c4:	9a1ff0ef          	jal	80003364 <inode_report>
    if(ip->type == 0)
    800039c8:	04449783          	lh	a5,68(s1)
    800039cc:	f3ad                	bnez	a5,8000392e <ilock+0x46>
      panic("ilock: no type");
    800039ce:	00006517          	auipc	a0,0x6
    800039d2:	d5a50513          	addi	a0,a0,-678 # 80009728 <etext+0x728>
    800039d6:	e3dfc0ef          	jal	80000812 <panic>

00000000800039da <iunlock>:
{
    800039da:	1101                	addi	sp,sp,-32
    800039dc:	ec06                	sd	ra,24(sp)
    800039de:	e822                	sd	s0,16(sp)
    800039e0:	e426                	sd	s1,8(sp)
    800039e2:	e04a                	sd	s2,0(sp)
    800039e4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039e6:	c529                	beqz	a0,80003a30 <iunlock+0x56>
    800039e8:	84aa                	mv	s1,a0
    800039ea:	01050913          	addi	s2,a0,16
    800039ee:	854a                	mv	a0,s2
    800039f0:	2b6010ef          	jal	80004ca6 <holdingsleep>
    800039f4:	cd15                	beqz	a0,80003a30 <iunlock+0x56>
    800039f6:	449c                	lw	a5,8(s1)
    800039f8:	02f05c63          	blez	a5,80003a30 <iunlock+0x56>
  releasesleep(&ip->lock);
    800039fc:	854a                	mv	a0,s2
    800039fe:	270010ef          	jal	80004c6e <releasesleep>
  inode_report("IUNLOCK", ip,
    80003a02:	00006897          	auipc	a7,0x6
    80003a06:	d3e88893          	addi	a7,a7,-706 # 80009740 <etext+0x740>
    80003a0a:	4805                	li	a6,1
    80003a0c:	44fc                	lw	a5,76(s1)
    80003a0e:	04449703          	lh	a4,68(s1)
    80003a12:	40b4                	lw	a3,64(s1)
    80003a14:	4490                	lw	a2,8(s1)
    80003a16:	85a6                	mv	a1,s1
    80003a18:	00006517          	auipc	a0,0x6
    80003a1c:	d3850513          	addi	a0,a0,-712 # 80009750 <etext+0x750>
    80003a20:	945ff0ef          	jal	80003364 <inode_report>
}
    80003a24:	60e2                	ld	ra,24(sp)
    80003a26:	6442                	ld	s0,16(sp)
    80003a28:	64a2                	ld	s1,8(sp)
    80003a2a:	6902                	ld	s2,0(sp)
    80003a2c:	6105                	addi	sp,sp,32
    80003a2e:	8082                	ret
    panic("iunlock");
    80003a30:	00006517          	auipc	a0,0x6
    80003a34:	d0850513          	addi	a0,a0,-760 # 80009738 <etext+0x738>
    80003a38:	ddbfc0ef          	jal	80000812 <panic>

0000000080003a3c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a3c:	7179                	addi	sp,sp,-48
    80003a3e:	f406                	sd	ra,40(sp)
    80003a40:	f022                	sd	s0,32(sp)
    80003a42:	ec26                	sd	s1,24(sp)
    80003a44:	e84a                	sd	s2,16(sp)
    80003a46:	e44e                	sd	s3,8(sp)
    80003a48:	1800                	addi	s0,sp,48
    80003a4a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a4c:	05050493          	addi	s1,a0,80
    80003a50:	08050913          	addi	s2,a0,128
    80003a54:	a021                	j	80003a5c <itrunc+0x20>
    80003a56:	0491                	addi	s1,s1,4
    80003a58:	01248b63          	beq	s1,s2,80003a6e <itrunc+0x32>
    if(ip->addrs[i]){
    80003a5c:	408c                	lw	a1,0(s1)
    80003a5e:	dde5                	beqz	a1,80003a56 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80003a60:	0009a503          	lw	a0,0(s3)
    80003a64:	f3cff0ef          	jal	800031a0 <bfree>
      ip->addrs[i] = 0;
    80003a68:	0004a023          	sw	zero,0(s1)
    80003a6c:	b7ed                	j	80003a56 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a6e:	0809a583          	lw	a1,128(s3)
    80003a72:	e1a9                	bnez	a1,80003ab4 <itrunc+0x78>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  int old_size = ip->size;
    80003a74:	04c9a783          	lw	a5,76(s3)

  ip->size = 0;
    80003a78:	0409a623          	sw	zero,76(s3)

  inode_report("ITRUNC", ip,
    80003a7c:	00006897          	auipc	a7,0x6
    80003a80:	cdc88893          	addi	a7,a7,-804 # 80009758 <etext+0x758>
    80003a84:	4805                	li	a6,1
    80003a86:	04499703          	lh	a4,68(s3)
    80003a8a:	0409a683          	lw	a3,64(s3)
    80003a8e:	0089a603          	lw	a2,8(s3)
    80003a92:	85ce                	mv	a1,s3
    80003a94:	00006517          	auipc	a0,0x6
    80003a98:	cdc50513          	addi	a0,a0,-804 # 80009770 <etext+0x770>
    80003a9c:	8c9ff0ef          	jal	80003364 <inode_report>
    ip->ref, ip->valid,
    ip->type, old_size,
    1,
    "Truncating inode data");
  iupdate(ip);
    80003aa0:	854e                	mv	a0,s3
    80003aa2:	d4fff0ef          	jal	800037f0 <iupdate>
}
    80003aa6:	70a2                	ld	ra,40(sp)
    80003aa8:	7402                	ld	s0,32(sp)
    80003aaa:	64e2                	ld	s1,24(sp)
    80003aac:	6942                	ld	s2,16(sp)
    80003aae:	69a2                	ld	s3,8(sp)
    80003ab0:	6145                	addi	sp,sp,48
    80003ab2:	8082                	ret
    80003ab4:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ab6:	0009a503          	lw	a0,0(s3)
    80003aba:	98aff0ef          	jal	80002c44 <bread>
    80003abe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ac0:	05850493          	addi	s1,a0,88
    80003ac4:	45850913          	addi	s2,a0,1112
    80003ac8:	a021                	j	80003ad0 <itrunc+0x94>
    80003aca:	0491                	addi	s1,s1,4
    80003acc:	01248963          	beq	s1,s2,80003ade <itrunc+0xa2>
      if(a[j])
    80003ad0:	408c                	lw	a1,0(s1)
    80003ad2:	dde5                	beqz	a1,80003aca <itrunc+0x8e>
        bfree(ip->dev, a[j]);
    80003ad4:	0009a503          	lw	a0,0(s3)
    80003ad8:	ec8ff0ef          	jal	800031a0 <bfree>
    80003adc:	b7fd                	j	80003aca <itrunc+0x8e>
    brelse(bp);
    80003ade:	8552                	mv	a0,s4
    80003ae0:	afaff0ef          	jal	80002dda <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ae4:	0809a583          	lw	a1,128(s3)
    80003ae8:	0009a503          	lw	a0,0(s3)
    80003aec:	eb4ff0ef          	jal	800031a0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003af0:	0809a023          	sw	zero,128(s3)
    80003af4:	6a02                	ld	s4,0(sp)
    80003af6:	bfbd                	j	80003a74 <itrunc+0x38>

0000000080003af8 <iput>:
{
    80003af8:	1101                	addi	sp,sp,-32
    80003afa:	ec06                	sd	ra,24(sp)
    80003afc:	e822                	sd	s0,16(sp)
    80003afe:	e426                	sd	s1,8(sp)
    80003b00:	1000                	addi	s0,sp,32
    80003b02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b04:	0001d517          	auipc	a0,0x1d
    80003b08:	41c50513          	addi	a0,a0,1052 # 80020f20 <itable>
    80003b0c:	8f4fd0ef          	jal	80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b10:	4498                	lw	a4,8(s1)
    80003b12:	4785                	li	a5,1
    80003b14:	04f70163          	beq	a4,a5,80003b56 <iput+0x5e>
  int old_ref = ip->ref;
    80003b18:	4490                	lw	a2,8(s1)
  ip->ref--;
    80003b1a:	fff6079b          	addiw	a5,a2,-1
    80003b1e:	c49c                	sw	a5,8(s1)
  inode_report("IPUT", ip,
    80003b20:	00006897          	auipc	a7,0x6
    80003b24:	c8088893          	addi	a7,a7,-896 # 800097a0 <etext+0x7a0>
    80003b28:	4801                	li	a6,0
    80003b2a:	44fc                	lw	a5,76(s1)
    80003b2c:	04449703          	lh	a4,68(s1)
    80003b30:	40b4                	lw	a3,64(s1)
    80003b32:	85a6                	mv	a1,s1
    80003b34:	00006517          	auipc	a0,0x6
    80003b38:	c7c50513          	addi	a0,a0,-900 # 800097b0 <etext+0x7b0>
    80003b3c:	829ff0ef          	jal	80003364 <inode_report>
  release(&itable.lock);
    80003b40:	0001d517          	auipc	a0,0x1d
    80003b44:	3e050513          	addi	a0,a0,992 # 80020f20 <itable>
    80003b48:	950fd0ef          	jal	80000c98 <release>
}
    80003b4c:	60e2                	ld	ra,24(sp)
    80003b4e:	6442                	ld	s0,16(sp)
    80003b50:	64a2                	ld	s1,8(sp)
    80003b52:	6105                	addi	sp,sp,32
    80003b54:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b56:	40bc                	lw	a5,64(s1)
    80003b58:	d3e1                	beqz	a5,80003b18 <iput+0x20>
    80003b5a:	04a49783          	lh	a5,74(s1)
    80003b5e:	ffcd                	bnez	a5,80003b18 <iput+0x20>
    80003b60:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003b62:	01048913          	addi	s2,s1,16
    80003b66:	854a                	mv	a0,s2
    80003b68:	0c0010ef          	jal	80004c28 <acquiresleep>
    release(&itable.lock);
    80003b6c:	0001d517          	auipc	a0,0x1d
    80003b70:	3b450513          	addi	a0,a0,948 # 80020f20 <itable>
    80003b74:	924fd0ef          	jal	80000c98 <release>
    itrunc(ip);
    80003b78:	8526                	mv	a0,s1
    80003b7a:	ec3ff0ef          	jal	80003a3c <itrunc>
    ip->type = 0;
    80003b7e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b82:	8526                	mv	a0,s1
    80003b84:	c6dff0ef          	jal	800037f0 <iupdate>
    ip->valid = 0;
    80003b88:	0404a023          	sw	zero,64(s1)
    inode_report("IPUT_FREE", ip,
    80003b8c:	00006897          	auipc	a7,0x6
    80003b90:	bec88893          	addi	a7,a7,-1044 # 80009778 <etext+0x778>
    80003b94:	4805                	li	a6,1
    80003b96:	44fc                	lw	a5,76(s1)
    80003b98:	04449703          	lh	a4,68(s1)
    80003b9c:	4681                	li	a3,0
    80003b9e:	4490                	lw	a2,8(s1)
    80003ba0:	85a6                	mv	a1,s1
    80003ba2:	00006517          	auipc	a0,0x6
    80003ba6:	bee50513          	addi	a0,a0,-1042 # 80009790 <etext+0x790>
    80003baa:	fbaff0ef          	jal	80003364 <inode_report>
    releasesleep(&ip->lock);
    80003bae:	854a                	mv	a0,s2
    80003bb0:	0be010ef          	jal	80004c6e <releasesleep>
    acquire(&itable.lock);
    80003bb4:	0001d517          	auipc	a0,0x1d
    80003bb8:	36c50513          	addi	a0,a0,876 # 80020f20 <itable>
    80003bbc:	844fd0ef          	jal	80000c00 <acquire>
    80003bc0:	6902                	ld	s2,0(sp)
    80003bc2:	bf99                	j	80003b18 <iput+0x20>

0000000080003bc4 <iunlockput>:
{
    80003bc4:	1101                	addi	sp,sp,-32
    80003bc6:	ec06                	sd	ra,24(sp)
    80003bc8:	e822                	sd	s0,16(sp)
    80003bca:	e426                	sd	s1,8(sp)
    80003bcc:	1000                	addi	s0,sp,32
    80003bce:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd0:	e0bff0ef          	jal	800039da <iunlock>
  iput(ip);
    80003bd4:	8526                	mv	a0,s1
    80003bd6:	f23ff0ef          	jal	80003af8 <iput>
}
    80003bda:	60e2                	ld	ra,24(sp)
    80003bdc:	6442                	ld	s0,16(sp)
    80003bde:	64a2                	ld	s1,8(sp)
    80003be0:	6105                	addi	sp,sp,32
    80003be2:	8082                	ret

0000000080003be4 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003be4:	0001d717          	auipc	a4,0x1d
    80003be8:	32872703          	lw	a4,808(a4) # 80020f0c <sb+0xc>
    80003bec:	4785                	li	a5,1
    80003bee:	0ae7ff63          	bgeu	a5,a4,80003cac <ireclaim+0xc8>
{
    80003bf2:	7139                	addi	sp,sp,-64
    80003bf4:	fc06                	sd	ra,56(sp)
    80003bf6:	f822                	sd	s0,48(sp)
    80003bf8:	f426                	sd	s1,40(sp)
    80003bfa:	f04a                	sd	s2,32(sp)
    80003bfc:	ec4e                	sd	s3,24(sp)
    80003bfe:	e852                	sd	s4,16(sp)
    80003c00:	e456                	sd	s5,8(sp)
    80003c02:	e05a                	sd	s6,0(sp)
    80003c04:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003c06:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003c08:	00050a1b          	sext.w	s4,a0
    80003c0c:	0001da97          	auipc	s5,0x1d
    80003c10:	2f4a8a93          	addi	s5,s5,756 # 80020f00 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    80003c14:	00006b17          	auipc	s6,0x6
    80003c18:	ba4b0b13          	addi	s6,s6,-1116 # 800097b8 <etext+0x7b8>
    80003c1c:	a099                	j	80003c62 <ireclaim+0x7e>
    80003c1e:	85ce                	mv	a1,s3
    80003c20:	855a                	mv	a0,s6
    80003c22:	90bfc0ef          	jal	8000052c <printf>
      ip = iget(dev, inum);
    80003c26:	85ce                	mv	a1,s3
    80003c28:	8552                	mv	a0,s4
    80003c2a:	83bff0ef          	jal	80003464 <iget>
    80003c2e:	89aa                	mv	s3,a0
    brelse(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	9a8ff0ef          	jal	80002dda <brelse>
    if (ip) {
    80003c36:	00098f63          	beqz	s3,80003c54 <ireclaim+0x70>
      begin_op();
    80003c3a:	35d000ef          	jal	80004796 <begin_op>
      ilock(ip);
    80003c3e:	854e                	mv	a0,s3
    80003c40:	ca9ff0ef          	jal	800038e8 <ilock>
      iunlock(ip);
    80003c44:	854e                	mv	a0,s3
    80003c46:	d95ff0ef          	jal	800039da <iunlock>
      iput(ip);
    80003c4a:	854e                	mv	a0,s3
    80003c4c:	eadff0ef          	jal	80003af8 <iput>
      end_op();
    80003c50:	465000ef          	jal	800048b4 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003c54:	0485                	addi	s1,s1,1
    80003c56:	00caa703          	lw	a4,12(s5)
    80003c5a:	0004879b          	sext.w	a5,s1
    80003c5e:	02e7fd63          	bgeu	a5,a4,80003c98 <ireclaim+0xb4>
    80003c62:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003c66:	0044d593          	srli	a1,s1,0x4
    80003c6a:	018aa783          	lw	a5,24(s5)
    80003c6e:	9dbd                	addw	a1,a1,a5
    80003c70:	8552                	mv	a0,s4
    80003c72:	fd3fe0ef          	jal	80002c44 <bread>
    80003c76:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003c78:	05850793          	addi	a5,a0,88
    80003c7c:	00f9f713          	andi	a4,s3,15
    80003c80:	071a                	slli	a4,a4,0x6
    80003c82:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003c84:	00079703          	lh	a4,0(a5)
    80003c88:	c701                	beqz	a4,80003c90 <ireclaim+0xac>
    80003c8a:	00679783          	lh	a5,6(a5)
    80003c8e:	dbc1                	beqz	a5,80003c1e <ireclaim+0x3a>
    brelse(bp);
    80003c90:	854a                	mv	a0,s2
    80003c92:	948ff0ef          	jal	80002dda <brelse>
    if (ip) {
    80003c96:	bf7d                	j	80003c54 <ireclaim+0x70>
}
    80003c98:	70e2                	ld	ra,56(sp)
    80003c9a:	7442                	ld	s0,48(sp)
    80003c9c:	74a2                	ld	s1,40(sp)
    80003c9e:	7902                	ld	s2,32(sp)
    80003ca0:	69e2                	ld	s3,24(sp)
    80003ca2:	6a42                	ld	s4,16(sp)
    80003ca4:	6aa2                	ld	s5,8(sp)
    80003ca6:	6b02                	ld	s6,0(sp)
    80003ca8:	6121                	addi	sp,sp,64
    80003caa:	8082                	ret
    80003cac:	8082                	ret

0000000080003cae <fsinit>:
fsinit(int dev) {
    80003cae:	7179                	addi	sp,sp,-48
    80003cb0:	f406                	sd	ra,40(sp)
    80003cb2:	f022                	sd	s0,32(sp)
    80003cb4:	ec26                	sd	s1,24(sp)
    80003cb6:	e84a                	sd	s2,16(sp)
    80003cb8:	e44e                	sd	s3,8(sp)
    80003cba:	1800                	addi	s0,sp,48
    80003cbc:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003cbe:	4585                	li	a1,1
    80003cc0:	f85fe0ef          	jal	80002c44 <bread>
    80003cc4:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003cc6:	0001d997          	auipc	s3,0x1d
    80003cca:	23a98993          	addi	s3,s3,570 # 80020f00 <sb>
    80003cce:	02000613          	li	a2,32
    80003cd2:	05850593          	addi	a1,a0,88
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	858fd0ef          	jal	80000d30 <memmove>
  brelse(bp);
    80003cdc:	854a                	mv	a0,s2
    80003cde:	8fcff0ef          	jal	80002dda <brelse>
  if(sb.magic != FSMAGIC)
    80003ce2:	0009a703          	lw	a4,0(s3)
    80003ce6:	102037b7          	lui	a5,0x10203
    80003cea:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cee:	02f71363          	bne	a4,a5,80003d14 <fsinit+0x66>
  initlog(dev, &sb);
    80003cf2:	0001d597          	auipc	a1,0x1d
    80003cf6:	20e58593          	addi	a1,a1,526 # 80020f00 <sb>
    80003cfa:	8526                	mv	a0,s1
    80003cfc:	145000ef          	jal	80004640 <initlog>
  ireclaim(dev);
    80003d00:	8526                	mv	a0,s1
    80003d02:	ee3ff0ef          	jal	80003be4 <ireclaim>
}
    80003d06:	70a2                	ld	ra,40(sp)
    80003d08:	7402                	ld	s0,32(sp)
    80003d0a:	64e2                	ld	s1,24(sp)
    80003d0c:	6942                	ld	s2,16(sp)
    80003d0e:	69a2                	ld	s3,8(sp)
    80003d10:	6145                	addi	sp,sp,48
    80003d12:	8082                	ret
    panic("invalid file system");
    80003d14:	00006517          	auipc	a0,0x6
    80003d18:	ac450513          	addi	a0,a0,-1340 # 800097d8 <etext+0x7d8>
    80003d1c:	af7fc0ef          	jal	80000812 <panic>

0000000080003d20 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d20:	1141                	addi	sp,sp,-16
    80003d22:	e422                	sd	s0,8(sp)
    80003d24:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d26:	411c                	lw	a5,0(a0)
    80003d28:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d2a:	415c                	lw	a5,4(a0)
    80003d2c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d2e:	04451783          	lh	a5,68(a0)
    80003d32:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d36:	04a51783          	lh	a5,74(a0)
    80003d3a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d3e:	04c56783          	lwu	a5,76(a0)
    80003d42:	e99c                	sd	a5,16(a1)
}
    80003d44:	6422                	ld	s0,8(sp)
    80003d46:	0141                	addi	sp,sp,16
    80003d48:	8082                	ret

0000000080003d4a <readi>:
// Caller must hold ip->lock.
// If user_dst==1, then dst is a user virtual address;
// otherwise, dst is a kernel address.
int
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
    80003d4a:	7119                	addi	sp,sp,-128
    80003d4c:	fc86                	sd	ra,120(sp)
    80003d4e:	f8a2                	sd	s0,112(sp)
    80003d50:	0100                	addi	s0,sp,128
    80003d52:	f8b43423          	sd	a1,-120(s0)
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d56:	457c                	lw	a5,76(a0)
    80003d58:	10d7ea63          	bltu	a5,a3,80003e6c <readi+0x122>
    80003d5c:	f4a6                	sd	s1,104(sp)
    80003d5e:	f0ca                	sd	s2,96(sp)
    80003d60:	e0da                	sd	s6,64(sp)
    80003d62:	fc5e                	sd	s7,56(sp)
    80003d64:	84aa                	mv	s1,a0
    80003d66:	8b32                	mv	s6,a2
    80003d68:	8936                	mv	s2,a3
    80003d6a:	8bba                	mv	s7,a4
    80003d6c:	9f35                	addw	a4,a4,a3
    return 0;
    80003d6e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d70:	10d76063          	bltu	a4,a3,80003e70 <readi+0x126>
    80003d74:	e8d2                	sd	s4,80(sp)
  if(off + n > ip->size)
    80003d76:	00e7f463          	bgeu	a5,a4,80003d7e <readi+0x34>
    n = ip->size - off;
    80003d7a:	40d78bbb          	subw	s7,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7e:	0c0b8463          	beqz	s7,80003e46 <readi+0xfc>
    80003d82:	ecce                	sd	s3,88(sp)
    80003d84:	e4d6                	sd	s5,72(sp)
    80003d86:	f862                	sd	s8,48(sp)
    80003d88:	f466                	sd	s9,40(sp)
    80003d8a:	f06a                	sd	s10,32(sp)
    80003d8c:	ec6e                	sd	s11,24(sp)
    80003d8e:	4a01                	li	s4,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d90:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d94:	5cfd                	li	s9,-1
      brelse(bp);
      tot = -1;
      break;
    }
    inode_report("READI", ip,
    80003d96:	00006d97          	auipc	s11,0x6
    80003d9a:	a5ad8d93          	addi	s11,s11,-1446 # 800097f0 <etext+0x7f0>
    80003d9e:	a881                	j	80003dee <readi+0xa4>
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003da0:	020a9c13          	slli	s8,s5,0x20
    80003da4:	020c5c13          	srli	s8,s8,0x20
    80003da8:	05898613          	addi	a2,s3,88
    80003dac:	86e2                	mv	a3,s8
    80003dae:	963a                	add	a2,a2,a4
    80003db0:	85da                	mv	a1,s6
    80003db2:	f8843503          	ld	a0,-120(s0)
    80003db6:	cbefe0ef          	jal	80002274 <either_copyout>
    80003dba:	07950463          	beq	a0,s9,80003e22 <readi+0xd8>
    inode_report("READI", ip,
    80003dbe:	88ee                	mv	a7,s11
    80003dc0:	4805                	li	a6,1
    80003dc2:	44fc                	lw	a5,76(s1)
    80003dc4:	04449703          	lh	a4,68(s1)
    80003dc8:	40b4                	lw	a3,64(s1)
    80003dca:	4490                	lw	a2,8(s1)
    80003dcc:	85a6                	mv	a1,s1
    80003dce:	00006517          	auipc	a0,0x6
    80003dd2:	a3a50513          	addi	a0,a0,-1478 # 80009808 <etext+0x808>
    80003dd6:	d8eff0ef          	jal	80003364 <inode_report>
      ip->ref, ip->valid,
      ip->type, ip->size,
      1,
      "Reading from inode");
    brelse(bp);
    80003dda:	854e                	mv	a0,s3
    80003ddc:	ffffe0ef          	jal	80002dda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de0:	014a8a3b          	addw	s4,s5,s4
    80003de4:	012a893b          	addw	s2,s5,s2
    80003de8:	9b62                	add	s6,s6,s8
    80003dea:	057a7763          	bgeu	s4,s7,80003e38 <readi+0xee>
    uint addr = bmap(ip, off/BSIZE);
    80003dee:	00a9559b          	srliw	a1,s2,0xa
    80003df2:	8526                	mv	a0,s1
    80003df4:	f7aff0ef          	jal	8000356e <bmap>
    80003df8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003dfc:	c5b9                	beqz	a1,80003e4a <readi+0x100>
    bp = bread(ip->dev, addr);
    80003dfe:	4088                	lw	a0,0(s1)
    80003e00:	e45fe0ef          	jal	80002c44 <bread>
    80003e04:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e06:	3ff97713          	andi	a4,s2,1023
    80003e0a:	40ed07bb          	subw	a5,s10,a4
    80003e0e:	414b86bb          	subw	a3,s7,s4
    80003e12:	8abe                	mv	s5,a5
    80003e14:	2781                	sext.w	a5,a5
    80003e16:	0006861b          	sext.w	a2,a3
    80003e1a:	f8f673e3          	bgeu	a2,a5,80003da0 <readi+0x56>
    80003e1e:	8ab6                	mv	s5,a3
    80003e20:	b741                	j	80003da0 <readi+0x56>
      brelse(bp);
    80003e22:	854e                	mv	a0,s3
    80003e24:	fb7fe0ef          	jal	80002dda <brelse>
      tot = -1;
    80003e28:	5a7d                	li	s4,-1
      break;
    80003e2a:	69e6                	ld	s3,88(sp)
    80003e2c:	6aa6                	ld	s5,72(sp)
    80003e2e:	7c42                	ld	s8,48(sp)
    80003e30:	7ca2                	ld	s9,40(sp)
    80003e32:	7d02                	ld	s10,32(sp)
    80003e34:	6de2                	ld	s11,24(sp)
    80003e36:	a005                	j	80003e56 <readi+0x10c>
    80003e38:	69e6                	ld	s3,88(sp)
    80003e3a:	6aa6                	ld	s5,72(sp)
    80003e3c:	7c42                	ld	s8,48(sp)
    80003e3e:	7ca2                	ld	s9,40(sp)
    80003e40:	7d02                	ld	s10,32(sp)
    80003e42:	6de2                	ld	s11,24(sp)
    80003e44:	a809                	j	80003e56 <readi+0x10c>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e46:	8a5e                	mv	s4,s7
    80003e48:	a039                	j	80003e56 <readi+0x10c>
    80003e4a:	69e6                	ld	s3,88(sp)
    80003e4c:	6aa6                	ld	s5,72(sp)
    80003e4e:	7c42                	ld	s8,48(sp)
    80003e50:	7ca2                	ld	s9,40(sp)
    80003e52:	7d02                	ld	s10,32(sp)
    80003e54:	6de2                	ld	s11,24(sp)
  }
  return tot;
    80003e56:	000a051b          	sext.w	a0,s4
    80003e5a:	74a6                	ld	s1,104(sp)
    80003e5c:	7906                	ld	s2,96(sp)
    80003e5e:	6a46                	ld	s4,80(sp)
    80003e60:	6b06                	ld	s6,64(sp)
    80003e62:	7be2                	ld	s7,56(sp)
}
    80003e64:	70e6                	ld	ra,120(sp)
    80003e66:	7446                	ld	s0,112(sp)
    80003e68:	6109                	addi	sp,sp,128
    80003e6a:	8082                	ret
    return 0;
    80003e6c:	4501                	li	a0,0
    80003e6e:	bfdd                	j	80003e64 <readi+0x11a>
    80003e70:	74a6                	ld	s1,104(sp)
    80003e72:	7906                	ld	s2,96(sp)
    80003e74:	6b06                	ld	s6,64(sp)
    80003e76:	7be2                	ld	s7,56(sp)
    80003e78:	b7f5                	j	80003e64 <readi+0x11a>

0000000080003e7a <writei>:
// Returns the number of bytes successfully written.
// If the return value is less than the requested n,
// there was an error of some kind.
int
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
    80003e7a:	7119                	addi	sp,sp,-128
    80003e7c:	fc86                	sd	ra,120(sp)
    80003e7e:	f8a2                	sd	s0,112(sp)
    80003e80:	f862                	sd	s8,48(sp)
    80003e82:	0100                	addi	s0,sp,128
    80003e84:	8c3a                	mv	s8,a4
  uint tot, m;
  struct buf *bp;
  int old_size = ip->size;
    80003e86:	457c                	lw	a5,76(a0)
    80003e88:	0007871b          	sext.w	a4,a5
    80003e8c:	f8e43423          	sd	a4,-120(s0)
  if(off > ip->size || off + n < off)
    80003e90:	10d7ee63          	bltu	a5,a3,80003fac <writei+0x132>
    80003e94:	f0ca                	sd	s2,96(sp)
    80003e96:	e4d6                	sd	s5,72(sp)
    80003e98:	e0da                	sd	s6,64(sp)
    80003e9a:	f466                	sd	s9,40(sp)
    80003e9c:	8b2a                	mv	s6,a0
    80003e9e:	8cae                	mv	s9,a1
    80003ea0:	8ab2                	mv	s5,a2
    80003ea2:	8936                	mv	s2,a3
    80003ea4:	018687bb          	addw	a5,a3,s8
    80003ea8:	10d7e463          	bltu	a5,a3,80003fb0 <writei+0x136>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eac:	00043737          	lui	a4,0x43
    80003eb0:	10f76663          	bltu	a4,a5,80003fbc <writei+0x142>
    80003eb4:	e8d2                	sd	s4,80(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eb6:	0e0c0363          	beqz	s8,80003f9c <writei+0x122>
    80003eba:	f4a6                	sd	s1,104(sp)
    80003ebc:	ecce                	sd	s3,88(sp)
    80003ebe:	fc5e                	sd	s7,56(sp)
    80003ec0:	f06a                	sd	s10,32(sp)
    80003ec2:	ec6e                	sd	s11,24(sp)
    80003ec4:	4a01                	li	s4,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec6:	40000d93          	li	s11,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eca:	5d7d                	li	s10,-1
    80003ecc:	a825                	j	80003f04 <writei+0x8a>
    80003ece:	02099b93          	slli	s7,s3,0x20
    80003ed2:	020bdb93          	srli	s7,s7,0x20
    80003ed6:	05848513          	addi	a0,s1,88
    80003eda:	86de                	mv	a3,s7
    80003edc:	8656                	mv	a2,s5
    80003ede:	85e6                	mv	a1,s9
    80003ee0:	953a                	add	a0,a0,a4
    80003ee2:	bdcfe0ef          	jal	800022be <either_copyin>
    80003ee6:	05a50a63          	beq	a0,s10,80003f3a <writei+0xc0>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003eea:	8526                	mv	a0,s1
    80003eec:	41f000ef          	jal	80004b0a <log_write>
    brelse(bp);
    80003ef0:	8526                	mv	a0,s1
    80003ef2:	ee9fe0ef          	jal	80002dda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef6:	01498a3b          	addw	s4,s3,s4
    80003efa:	0129893b          	addw	s2,s3,s2
    80003efe:	9ade                	add	s5,s5,s7
    80003f00:	058a7063          	bgeu	s4,s8,80003f40 <writei+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    80003f04:	00a9559b          	srliw	a1,s2,0xa
    80003f08:	855a                	mv	a0,s6
    80003f0a:	e64ff0ef          	jal	8000356e <bmap>
    80003f0e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f12:	c59d                	beqz	a1,80003f40 <writei+0xc6>
    bp = bread(ip->dev, addr);
    80003f14:	000b2503          	lw	a0,0(s6)
    80003f18:	d2dfe0ef          	jal	80002c44 <bread>
    80003f1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f1e:	3ff97713          	andi	a4,s2,1023
    80003f22:	40ed87bb          	subw	a5,s11,a4
    80003f26:	414c06bb          	subw	a3,s8,s4
    80003f2a:	89be                	mv	s3,a5
    80003f2c:	2781                	sext.w	a5,a5
    80003f2e:	0006861b          	sext.w	a2,a3
    80003f32:	f8f67ee3          	bgeu	a2,a5,80003ece <writei+0x54>
    80003f36:	89b6                	mv	s3,a3
    80003f38:	bf59                	j	80003ece <writei+0x54>
      brelse(bp);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	e9ffe0ef          	jal	80002dda <brelse>
  }

  if(off > ip->size)
    80003f40:	04cb2783          	lw	a5,76(s6)
    80003f44:	0527fe63          	bgeu	a5,s2,80003fa0 <writei+0x126>
    ip->size = off;
    80003f48:	052b2623          	sw	s2,76(s6)
    80003f4c:	74a6                	ld	s1,104(sp)
    80003f4e:	69e6                	ld	s3,88(sp)
    80003f50:	7be2                	ld	s7,56(sp)
    80003f52:	7d02                	ld	s10,32(sp)
    80003f54:	6de2                	ld	s11,24(sp)
  inode_report("WRITEI", ip,
    80003f56:	00006897          	auipc	a7,0x6
    80003f5a:	8ba88893          	addi	a7,a7,-1862 # 80009810 <etext+0x810>
    80003f5e:	4805                	li	a6,1
    80003f60:	f8843783          	ld	a5,-120(s0)
    80003f64:	044b1703          	lh	a4,68(s6)
    80003f68:	040b2683          	lw	a3,64(s6)
    80003f6c:	008b2603          	lw	a2,8(s6)
    80003f70:	85da                	mv	a1,s6
    80003f72:	00006517          	auipc	a0,0x6
    80003f76:	8b650513          	addi	a0,a0,-1866 # 80009828 <etext+0x828>
    80003f7a:	beaff0ef          	jal	80003364 <inode_report>
    "Writing to inode");

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f7e:	855a                	mv	a0,s6
    80003f80:	871ff0ef          	jal	800037f0 <iupdate>

  return tot;
    80003f84:	000a051b          	sext.w	a0,s4
    80003f88:	7906                	ld	s2,96(sp)
    80003f8a:	6a46                	ld	s4,80(sp)
    80003f8c:	6aa6                	ld	s5,72(sp)
    80003f8e:	6b06                	ld	s6,64(sp)
    80003f90:	7ca2                	ld	s9,40(sp)
}
    80003f92:	70e6                	ld	ra,120(sp)
    80003f94:	7446                	ld	s0,112(sp)
    80003f96:	7c42                	ld	s8,48(sp)
    80003f98:	6109                	addi	sp,sp,128
    80003f9a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f9c:	8a62                	mv	s4,s8
    80003f9e:	bf65                	j	80003f56 <writei+0xdc>
    80003fa0:	74a6                	ld	s1,104(sp)
    80003fa2:	69e6                	ld	s3,88(sp)
    80003fa4:	7be2                	ld	s7,56(sp)
    80003fa6:	7d02                	ld	s10,32(sp)
    80003fa8:	6de2                	ld	s11,24(sp)
    80003faa:	b775                	j	80003f56 <writei+0xdc>
    return -1;
    80003fac:	557d                	li	a0,-1
    80003fae:	b7d5                	j	80003f92 <writei+0x118>
    80003fb0:	557d                	li	a0,-1
    80003fb2:	7906                	ld	s2,96(sp)
    80003fb4:	6aa6                	ld	s5,72(sp)
    80003fb6:	6b06                	ld	s6,64(sp)
    80003fb8:	7ca2                	ld	s9,40(sp)
    80003fba:	bfe1                	j	80003f92 <writei+0x118>
    return -1;
    80003fbc:	557d                	li	a0,-1
    80003fbe:	7906                	ld	s2,96(sp)
    80003fc0:	6aa6                	ld	s5,72(sp)
    80003fc2:	6b06                	ld	s6,64(sp)
    80003fc4:	7ca2                	ld	s9,40(sp)
    80003fc6:	b7f1                	j	80003f92 <writei+0x118>

0000000080003fc8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fc8:	1141                	addi	sp,sp,-16
    80003fca:	e406                	sd	ra,8(sp)
    80003fcc:	e022                	sd	s0,0(sp)
    80003fce:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fd0:	4639                	li	a2,14
    80003fd2:	dcffc0ef          	jal	80000da0 <strncmp>
}
    80003fd6:	60a2                	ld	ra,8(sp)
    80003fd8:	6402                	ld	s0,0(sp)
    80003fda:	0141                	addi	sp,sp,16
    80003fdc:	8082                	ret

0000000080003fde <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fde:	7139                	addi	sp,sp,-64
    80003fe0:	fc06                	sd	ra,56(sp)
    80003fe2:	f822                	sd	s0,48(sp)
    80003fe4:	f426                	sd	s1,40(sp)
    80003fe6:	f04a                	sd	s2,32(sp)
    80003fe8:	ec4e                	sd	s3,24(sp)
    80003fea:	e852                	sd	s4,16(sp)
    80003fec:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR){
    80003fee:	04451703          	lh	a4,68(a0)
    80003ff2:	4785                	li	a5,1
    80003ff4:	02f71f63          	bne	a4,a5,80004032 <dirlookup+0x54>
    80003ff8:	892a                	mv	s2,a0
    80003ffa:	89ae                	mv	s3,a1
    80003ffc:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");
  }
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ffe:	457c                	lw	a5,76(a0)
    80004000:	4481                	li	s1,0
    80004002:	eba9                	bnez	a5,80004054 <dirlookup+0x76>
        "Directory entry found"
      );
      return iget(dp->dev, inum);
    }
  }
  dir_report(
    80004004:	00006797          	auipc	a5,0x6
    80004008:	87c78793          	addi	a5,a5,-1924 # 80009880 <etext+0x880>
    8000400c:	577d                	li	a4,-1
    8000400e:	56fd                	li	a3,-1
    80004010:	864e                	mv	a2,s3
    80004012:	85ca                	mv	a1,s2
    80004014:	00006517          	auipc	a0,0x6
    80004018:	88c50513          	addi	a0,a0,-1908 # 800098a0 <etext+0x8a0>
    8000401c:	efbfe0ef          	jal	80002f16 <dir_report>
    name,
    -1,
    -1,
    "Directory entry not found"
  );
  return 0;
    80004020:	4501                	li	a0,0
}
    80004022:	70e2                	ld	ra,56(sp)
    80004024:	7442                	ld	s0,48(sp)
    80004026:	74a2                	ld	s1,40(sp)
    80004028:	7902                	ld	s2,32(sp)
    8000402a:	69e2                	ld	s3,24(sp)
    8000402c:	6a42                	ld	s4,16(sp)
    8000402e:	6121                	addi	sp,sp,64
    80004030:	8082                	ret
    panic("dirlookup not DIR");
    80004032:	00005517          	auipc	a0,0x5
    80004036:	7fe50513          	addi	a0,a0,2046 # 80009830 <etext+0x830>
    8000403a:	fd8fc0ef          	jal	80000812 <panic>
      panic("dirlookup read");
    8000403e:	00006517          	auipc	a0,0x6
    80004042:	80a50513          	addi	a0,a0,-2038 # 80009848 <etext+0x848>
    80004046:	fccfc0ef          	jal	80000812 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404a:	24c1                	addiw	s1,s1,16
    8000404c:	04c92783          	lw	a5,76(s2)
    80004050:	faf4fae3          	bgeu	s1,a5,80004004 <dirlookup+0x26>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004054:	4741                	li	a4,16
    80004056:	86a6                	mv	a3,s1
    80004058:	fc040613          	addi	a2,s0,-64
    8000405c:	4581                	li	a1,0
    8000405e:	854a                	mv	a0,s2
    80004060:	cebff0ef          	jal	80003d4a <readi>
    80004064:	47c1                	li	a5,16
    80004066:	fcf51ce3          	bne	a0,a5,8000403e <dirlookup+0x60>
    if(de.inum == 0)
    8000406a:	fc045783          	lhu	a5,-64(s0)
    8000406e:	dff1                	beqz	a5,8000404a <dirlookup+0x6c>
    if(namecmp(name, de.name) == 0){
    80004070:	fc240593          	addi	a1,s0,-62
    80004074:	854e                	mv	a0,s3
    80004076:	f53ff0ef          	jal	80003fc8 <namecmp>
    8000407a:	f961                	bnez	a0,8000404a <dirlookup+0x6c>
      if(poff)
    8000407c:	000a0463          	beqz	s4,80004084 <dirlookup+0xa6>
        *poff = off;
    80004080:	009a2023          	sw	s1,0(s4)
      inum = de.inum;
    80004084:	fc045a03          	lhu	s4,-64(s0)
      dir_report(
    80004088:	00005797          	auipc	a5,0x5
    8000408c:	7d078793          	addi	a5,a5,2000 # 80009858 <etext+0x858>
    80004090:	8726                	mv	a4,s1
    80004092:	86d2                	mv	a3,s4
    80004094:	864e                	mv	a2,s3
    80004096:	85ca                	mv	a1,s2
    80004098:	00005517          	auipc	a0,0x5
    8000409c:	7d850513          	addi	a0,a0,2008 # 80009870 <etext+0x870>
    800040a0:	e77fe0ef          	jal	80002f16 <dir_report>
      return iget(dp->dev, inum);
    800040a4:	85d2                	mv	a1,s4
    800040a6:	00092503          	lw	a0,0(s2)
    800040aa:	bbaff0ef          	jal	80003464 <iget>
    800040ae:	bf95                	j	80004022 <dirlookup+0x44>

00000000800040b0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040b0:	711d                	addi	sp,sp,-96
    800040b2:	ec86                	sd	ra,88(sp)
    800040b4:	e8a2                	sd	s0,80(sp)
    800040b6:	e4a6                	sd	s1,72(sp)
    800040b8:	e0ca                	sd	s2,64(sp)
    800040ba:	fc4e                	sd	s3,56(sp)
    800040bc:	f852                	sd	s4,48(sp)
    800040be:	f456                	sd	s5,40(sp)
    800040c0:	f05a                	sd	s6,32(sp)
    800040c2:	ec5e                	sd	s7,24(sp)
    800040c4:	e862                	sd	s8,16(sp)
    800040c6:	e466                	sd	s9,8(sp)
    800040c8:	1080                	addi	s0,sp,96
    800040ca:	84aa                	mv	s1,a0
    800040cc:	8b2e                	mv	s6,a1
    800040ce:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040d0:	00054703          	lbu	a4,0(a0)
    800040d4:	02f00793          	li	a5,47
    800040d8:	00f70e63          	beq	a4,a5,800040f4 <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040dc:	82dfd0ef          	jal	80001908 <myproc>
    800040e0:	15053503          	ld	a0,336(a0)
    800040e4:	facff0ef          	jal	80003890 <idup>
    800040e8:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040ea:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040ee:	4c35                	li	s8,13
  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040f0:	4b85                	li	s7,1
    800040f2:	a871                	j	8000418e <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    800040f4:	4585                	li	a1,1
    800040f6:	4505                	li	a0,1
    800040f8:	b6cff0ef          	jal	80003464 <iget>
    800040fc:	8a2a                	mv	s4,a0
    800040fe:	b7f5                	j	800040ea <namex+0x3a>
      iunlockput(ip);
    80004100:	8552                	mv	a0,s4
    80004102:	ac3ff0ef          	jal	80003bc4 <iunlockput>
      
      return 0;
    80004106:	4a01                	li	s4,0
    myproc() ? "Process CWD" : "Root", // تم الإصلاح هنا بتمرير نوع السلسلة النصية المناسب بدلاً من الـ inode pointer
    ip,
    "Path resolved successfully"
  );
  return ip;
}
    80004108:	8552                	mv	a0,s4
    8000410a:	60e6                	ld	ra,88(sp)
    8000410c:	6446                	ld	s0,80(sp)
    8000410e:	64a6                	ld	s1,72(sp)
    80004110:	6906                	ld	s2,64(sp)
    80004112:	79e2                	ld	s3,56(sp)
    80004114:	7a42                	ld	s4,48(sp)
    80004116:	7aa2                	ld	s5,40(sp)
    80004118:	7b02                	ld	s6,32(sp)
    8000411a:	6be2                	ld	s7,24(sp)
    8000411c:	6c42                	ld	s8,16(sp)
    8000411e:	6ca2                	ld	s9,8(sp)
    80004120:	6125                	addi	sp,sp,96
    80004122:	8082                	ret
      iunlock(ip);
    80004124:	8552                	mv	a0,s4
    80004126:	8b5ff0ef          	jal	800039da <iunlock>
      return ip;
    8000412a:	bff9                	j	80004108 <namex+0x58>
      iunlockput(ip);
    8000412c:	8552                	mv	a0,s4
    8000412e:	a97ff0ef          	jal	80003bc4 <iunlockput>
      return 0;
    80004132:	8a4e                	mv	s4,s3
    80004134:	bfd1                	j	80004108 <namex+0x58>
  len = path - s;
    80004136:	40998633          	sub	a2,s3,s1
    8000413a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000413e:	099c5063          	bge	s8,s9,800041be <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80004142:	4639                	li	a2,14
    80004144:	85a6                	mv	a1,s1
    80004146:	8556                	mv	a0,s5
    80004148:	be9fc0ef          	jal	80000d30 <memmove>
    8000414c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000414e:	0004c783          	lbu	a5,0(s1)
    80004152:	01279763          	bne	a5,s2,80004160 <namex+0xb0>
    path++;
    80004156:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004158:	0004c783          	lbu	a5,0(s1)
    8000415c:	ff278de3          	beq	a5,s2,80004156 <namex+0xa6>
    ilock(ip);
    80004160:	8552                	mv	a0,s4
    80004162:	f86ff0ef          	jal	800038e8 <ilock>
    if(ip->type != T_DIR){
    80004166:	044a1783          	lh	a5,68(s4)
    8000416a:	f9779be3          	bne	a5,s7,80004100 <namex+0x50>
    if(nameiparent && *path == '\0'){
    8000416e:	000b0563          	beqz	s6,80004178 <namex+0xc8>
    80004172:	0004c783          	lbu	a5,0(s1)
    80004176:	d7dd                	beqz	a5,80004124 <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004178:	4601                	li	a2,0
    8000417a:	85d6                	mv	a1,s5
    8000417c:	8552                	mv	a0,s4
    8000417e:	e61ff0ef          	jal	80003fde <dirlookup>
    80004182:	89aa                	mv	s3,a0
    80004184:	d545                	beqz	a0,8000412c <namex+0x7c>
    iunlockput(ip);
    80004186:	8552                	mv	a0,s4
    80004188:	a3dff0ef          	jal	80003bc4 <iunlockput>
    ip = next;
    8000418c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000418e:	0004c783          	lbu	a5,0(s1)
    80004192:	01279763          	bne	a5,s2,800041a0 <namex+0xf0>
    path++;
    80004196:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004198:	0004c783          	lbu	a5,0(s1)
    8000419c:	ff278de3          	beq	a5,s2,80004196 <namex+0xe6>
  if(*path == 0)
    800041a0:	cb8d                	beqz	a5,800041d2 <namex+0x122>
  while(*path != '/' && *path != 0)
    800041a2:	0004c783          	lbu	a5,0(s1)
    800041a6:	89a6                	mv	s3,s1
  len = path - s;
    800041a8:	4c81                	li	s9,0
    800041aa:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800041ac:	01278963          	beq	a5,s2,800041be <namex+0x10e>
    800041b0:	d3d9                	beqz	a5,80004136 <namex+0x86>
    path++;
    800041b2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041b4:	0009c783          	lbu	a5,0(s3)
    800041b8:	ff279ce3          	bne	a5,s2,800041b0 <namex+0x100>
    800041bc:	bfad                	j	80004136 <namex+0x86>
    memmove(name, s, len);
    800041be:	2601                	sext.w	a2,a2
    800041c0:	85a6                	mv	a1,s1
    800041c2:	8556                	mv	a0,s5
    800041c4:	b6dfc0ef          	jal	80000d30 <memmove>
    name[len] = 0;
    800041c8:	9cd6                	add	s9,s9,s5
    800041ca:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800041ce:	84ce                	mv	s1,s3
    800041d0:	bfbd                	j	8000414e <namex+0x9e>
  if(nameiparent){
    800041d2:	040b1763          	bnez	s6,80004220 <namex+0x170>
    myproc() ? myproc()->current_syscall : "",
    800041d6:	f32fd0ef          	jal	80001908 <myproc>
  path_report(
    800041da:	00006497          	auipc	s1,0x6
    800041de:	9a648493          	addi	s1,s1,-1626 # 80009b80 <etext+0xb80>
    800041e2:	c509                	beqz	a0,800041ec <namex+0x13c>
    myproc() ? myproc()->current_syscall : "",
    800041e4:	f24fd0ef          	jal	80001908 <myproc>
  path_report(
    800041e8:	16850493          	addi	s1,a0,360
    myproc() ? "Process CWD" : "Root", // تم الإصلاح هنا بتمرير نوع السلسلة النصية المناسب بدلاً من الـ inode pointer
    800041ec:	f1cfd0ef          	jal	80001908 <myproc>
  path_report(
    800041f0:	00005717          	auipc	a4,0x5
    800041f4:	6d070713          	addi	a4,a4,1744 # 800098c0 <etext+0x8c0>
    800041f8:	c509                	beqz	a0,80004202 <namex+0x152>
    800041fa:	00005717          	auipc	a4,0x5
    800041fe:	6b670713          	addi	a4,a4,1718 # 800098b0 <etext+0x8b0>
    80004202:	00005817          	auipc	a6,0x5
    80004206:	6ee80813          	addi	a6,a6,1774 # 800098f0 <etext+0x8f0>
    8000420a:	87d2                	mv	a5,s4
    8000420c:	86d6                	mv	a3,s5
    8000420e:	4601                	li	a2,0
    80004210:	00005597          	auipc	a1,0x5
    80004214:	70058593          	addi	a1,a1,1792 # 80009910 <etext+0x910>
    80004218:	8526                	mv	a0,s1
    8000421a:	dcbfe0ef          	jal	80002fe4 <path_report>
  return ip;
    8000421e:	b5ed                	j	80004108 <namex+0x58>
      myproc() ? myproc()->current_syscall : "",
    80004220:	ee8fd0ef          	jal	80001908 <myproc>
    path_report(
    80004224:	00006497          	auipc	s1,0x6
    80004228:	95c48493          	addi	s1,s1,-1700 # 80009b80 <etext+0xb80>
    8000422c:	c509                	beqz	a0,80004236 <namex+0x186>
      myproc() ? myproc()->current_syscall : "",
    8000422e:	edafd0ef          	jal	80001908 <myproc>
    path_report(
    80004232:	16850493          	addi	s1,a0,360
      myproc() ? "Process CWD" : "Root", // تم الإصلاح هنا بتمرير نوع السلسلة النصية المناسب بدلاً من الـ inode pointer
    80004236:	ed2fd0ef          	jal	80001908 <myproc>
    path_report(
    8000423a:	00005717          	auipc	a4,0x5
    8000423e:	68670713          	addi	a4,a4,1670 # 800098c0 <etext+0x8c0>
    80004242:	c509                	beqz	a0,8000424c <namex+0x19c>
    80004244:	00005717          	auipc	a4,0x5
    80004248:	66c70713          	addi	a4,a4,1644 # 800098b0 <etext+0x8b0>
    8000424c:	00005817          	auipc	a6,0x5
    80004250:	67c80813          	addi	a6,a6,1660 # 800098c8 <etext+0x8c8>
    80004254:	87d2                	mv	a5,s4
    80004256:	86d6                	mv	a3,s5
    80004258:	4601                	li	a2,0
    8000425a:	00005597          	auipc	a1,0x5
    8000425e:	68658593          	addi	a1,a1,1670 # 800098e0 <etext+0x8e0>
    80004262:	8526                	mv	a0,s1
    80004264:	d81fe0ef          	jal	80002fe4 <path_report>
    iput(ip);
    80004268:	8552                	mv	a0,s4
    8000426a:	88fff0ef          	jal	80003af8 <iput>
    return 0;
    8000426e:	4a01                	li	s4,0
    80004270:	bd61                	j	80004108 <namex+0x58>

0000000080004272 <dirlink>:
{
    80004272:	7139                	addi	sp,sp,-64
    80004274:	fc06                	sd	ra,56(sp)
    80004276:	f822                	sd	s0,48(sp)
    80004278:	f04a                	sd	s2,32(sp)
    8000427a:	ec4e                	sd	s3,24(sp)
    8000427c:	e852                	sd	s4,16(sp)
    8000427e:	0080                	addi	s0,sp,64
    80004280:	892a                	mv	s2,a0
    80004282:	89ae                	mv	s3,a1
    80004284:	8a32                	mv	s4,a2
  dir_report(
    80004286:	00005797          	auipc	a5,0x5
    8000428a:	69a78793          	addi	a5,a5,1690 # 80009920 <etext+0x920>
    8000428e:	577d                	li	a4,-1
    80004290:	86b2                	mv	a3,a2
    80004292:	862e                	mv	a2,a1
    80004294:	85aa                	mv	a1,a0
    80004296:	00005517          	auipc	a0,0x5
    8000429a:	6aa50513          	addi	a0,a0,1706 # 80009940 <etext+0x940>
    8000429e:	c79fe0ef          	jal	80002f16 <dir_report>
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042a2:	4601                	li	a2,0
    800042a4:	85ce                	mv	a1,s3
    800042a6:	854a                	mv	a0,s2
    800042a8:	d37ff0ef          	jal	80003fde <dirlookup>
    800042ac:	e159                	bnez	a0,80004332 <dirlink+0xc0>
    800042ae:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b0:	04c92483          	lw	s1,76(s2)
    800042b4:	c48d                	beqz	s1,800042de <dirlink+0x6c>
    800042b6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b8:	4741                	li	a4,16
    800042ba:	86a6                	mv	a3,s1
    800042bc:	fc040613          	addi	a2,s0,-64
    800042c0:	4581                	li	a1,0
    800042c2:	854a                	mv	a0,s2
    800042c4:	a87ff0ef          	jal	80003d4a <readi>
    800042c8:	47c1                	li	a5,16
    800042ca:	06f51863          	bne	a0,a5,8000433a <dirlink+0xc8>
    if(de.inum == 0)
    800042ce:	fc045783          	lhu	a5,-64(s0)
    800042d2:	c791                	beqz	a5,800042de <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d4:	24c1                	addiw	s1,s1,16
    800042d6:	04c92783          	lw	a5,76(s2)
    800042da:	fcf4efe3          	bltu	s1,a5,800042b8 <dirlink+0x46>
  strncpy(de.name, name, DIRSIZ);
    800042de:	4639                	li	a2,14
    800042e0:	85ce                	mv	a1,s3
    800042e2:	fc240513          	addi	a0,s0,-62
    800042e6:	af1fc0ef          	jal	80000dd6 <strncpy>
  de.inum = inum;
    800042ea:	fd441023          	sh	s4,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ee:	4741                	li	a4,16
    800042f0:	86a6                	mv	a3,s1
    800042f2:	fc040613          	addi	a2,s0,-64
    800042f6:	4581                	li	a1,0
    800042f8:	854a                	mv	a0,s2
    800042fa:	b81ff0ef          	jal	80003e7a <writei>
    800042fe:	47c1                	li	a5,16
    80004300:	04f51363          	bne	a0,a5,80004346 <dirlink+0xd4>
  dir_report(
    80004304:	00005797          	auipc	a5,0x5
    80004308:	65c78793          	addi	a5,a5,1628 # 80009960 <etext+0x960>
    8000430c:	8726                	mv	a4,s1
    8000430e:	86d2                	mv	a3,s4
    80004310:	864e                	mv	a2,s3
    80004312:	85ca                	mv	a1,s2
    80004314:	00005517          	auipc	a0,0x5
    80004318:	66450513          	addi	a0,a0,1636 # 80009978 <etext+0x978>
    8000431c:	bfbfe0ef          	jal	80002f16 <dir_report>
  return 0;
    80004320:	4501                	li	a0,0
    80004322:	74a2                	ld	s1,40(sp)
}
    80004324:	70e2                	ld	ra,56(sp)
    80004326:	7442                	ld	s0,48(sp)
    80004328:	7902                	ld	s2,32(sp)
    8000432a:	69e2                	ld	s3,24(sp)
    8000432c:	6a42                	ld	s4,16(sp)
    8000432e:	6121                	addi	sp,sp,64
    80004330:	8082                	ret
    iput(ip);
    80004332:	fc6ff0ef          	jal	80003af8 <iput>
    return -1;
    80004336:	557d                	li	a0,-1
    80004338:	b7f5                	j	80004324 <dirlink+0xb2>
      panic("dirlink read");
    8000433a:	00005517          	auipc	a0,0x5
    8000433e:	61650513          	addi	a0,a0,1558 # 80009950 <etext+0x950>
    80004342:	cd0fc0ef          	jal	80000812 <panic>
    return -1;
    80004346:	557d                	li	a0,-1
    80004348:	74a2                	ld	s1,40(sp)
    8000434a:	bfe9                	j	80004324 <dirlink+0xb2>

000000008000434c <namei>:

struct inode*
namei(char *path)
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004354:	fe040613          	addi	a2,s0,-32
    80004358:	4581                	li	a1,0
    8000435a:	d57ff0ef          	jal	800040b0 <namex>
}
    8000435e:	60e2                	ld	ra,24(sp)
    80004360:	6442                	ld	s0,16(sp)
    80004362:	6105                	addi	sp,sp,32
    80004364:	8082                	ret

0000000080004366 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004366:	1141                	addi	sp,sp,-16
    80004368:	e406                	sd	ra,8(sp)
    8000436a:	e022                	sd	s0,0(sp)
    8000436c:	0800                	addi	s0,sp,16
    8000436e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004370:	4585                	li	a1,1
    80004372:	d3fff0ef          	jal	800040b0 <namex>
    80004376:	60a2                	ld	ra,8(sp)
    80004378:	6402                	ld	s0,0(sp)
    8000437a:	0141                	addi	sp,sp,16
    8000437c:	8082                	ret

000000008000437e <log_get_state>:
  int committing;
};

static struct log_state
log_get_state(void)
{
    8000437e:	1101                	addi	sp,sp,-32
    80004380:	ec22                	sd	s0,24(sp)
    80004382:	1000                	addi	s0,sp,32
  struct log_state s;
  s.n = log.lh.n;
  s.out = log.outstanding;
    80004384:	0001e697          	auipc	a3,0x1e
    80004388:	64468693          	addi	a3,a3,1604 # 800229c8 <log>
  s.committing = log.committing;
  return s;
    8000438c:	0286e503          	lwu	a0,40(a3)
    80004390:	57fd                	li	a5,-1
    80004392:	9381                	srli	a5,a5,0x20
    80004394:	01c6e703          	lwu	a4,28(a3)
    80004398:	1702                	slli	a4,a4,0x20
    8000439a:	8d7d                	and	a0,a0,a5
    8000439c:	0206e583          	lwu	a1,32(a3)
}
    800043a0:	8d59                	or	a0,a0,a4
    800043a2:	8dfd                	and	a1,a1,a5
    800043a4:	6462                	ld	s0,24(sp)
    800043a6:	6105                	addi	sp,sp,32
    800043a8:	8082                	ret

00000000800043aa <log_report>:
void log_report(char *op, int bno, struct log_state old, char *desc)
{
    800043aa:	ca010113          	addi	sp,sp,-864
    800043ae:	34113c23          	sd	ra,856(sp)
    800043b2:	34813823          	sd	s0,848(sp)
    800043b6:	34913423          	sd	s1,840(sp)
    800043ba:	35213023          	sd	s2,832(sp)
    800043be:	33313c23          	sd	s3,824(sp)
    800043c2:	1680                	addi	s0,sp,864
    800043c4:	892a                	mv	s2,a0
    800043c6:	89ae                	mv	s3,a1
    800043c8:	cac43023          	sd	a2,-864(s0)
    800043cc:	cad43423          	sd	a3,-856(s0)
    800043d0:	84ba                	mv	s1,a4
  struct fs_event e;
  memset(&e, 0, sizeof(e));
    800043d2:	31000613          	li	a2,784
    800043d6:	4581                	li	a1,0
    800043d8:	cc040513          	addi	a0,s0,-832
    800043dc:	8f9fc0ef          	jal	80000cd4 <memset>

  struct log_state now = log_get_state();
    800043e0:	f9fff0ef          	jal	8000437e <log_get_state>
    800043e4:	caa42823          	sw	a0,-848(s0)
    800043e8:	02055793          	srli	a5,a0,0x20
    800043ec:	caf42a23          	sw	a5,-844(s0)
    800043f0:	cab42c23          	sw	a1,-840(s0)

  e.ticks = ticks;
    800043f4:	00006797          	auipc	a5,0x6
    800043f8:	cc47a783          	lw	a5,-828(a5) # 8000a0b8 <ticks>
    800043fc:	ccf42423          	sw	a5,-824(s0)
  e.pid = myproc() ? myproc()->pid : 0;
    80004400:	d08fd0ef          	jal	80001908 <myproc>
    80004404:	4781                	li	a5,0
    80004406:	c501                	beqz	a0,8000440e <log_report+0x64>
    80004408:	d00fd0ef          	jal	80001908 <myproc>
    8000440c:	591c                	lw	a5,48(a0)
    8000440e:	ccf42623          	sw	a5,-820(s0)
  e.type = LAYER_LOG;
    80004412:	4789                	li	a5,2
    80004414:	ccf42823          	sw	a5,-816(s0)
  e.blockno = bno;
    80004418:	cf342223          	sw	s3,-796(s0)

  // before
  e.old_log_n = old.n;
    8000441c:	ca042783          	lw	a5,-864(s0)
    80004420:	d0f42023          	sw	a5,-768(s0)
  e.old_outstanding = old.out;
    80004424:	ca442783          	lw	a5,-860(s0)
    80004428:	d0f42423          	sw	a5,-760(s0)
  e.old_committing = old.committing;
    8000442c:	ca842783          	lw	a5,-856(s0)
    80004430:	d0f42823          	sw	a5,-752(s0)

  // after
  e.log_n = now.n;
    80004434:	cb042783          	lw	a5,-848(s0)
    80004438:	cef42e23          	sw	a5,-772(s0)
  e.outstanding = now.out;
    8000443c:	cb442783          	lw	a5,-844(s0)
    80004440:	d0f42223          	sw	a5,-764(s0)
  e.committing = now.committing;
    80004444:	cb842783          	lw	a5,-840(s0)
    80004448:	d0f42623          	sw	a5,-756(s0)

  safestrcpy(e.op_name, op, 16);
    8000444c:	4641                	li	a2,16
    8000444e:	85ca                	mv	a1,s2
    80004450:	cd440513          	addi	a0,s0,-812
    80004454:	9bffc0ef          	jal	80000e12 <safestrcpy>
  safestrcpy(e.details, desc, 128);
    80004458:	08000613          	li	a2,128
    8000445c:	85a6                	mv	a1,s1
    8000445e:	f4c40513          	addi	a0,s0,-180
    80004462:	9b1fc0ef          	jal	80000e12 <safestrcpy>

  fslog_push(&e);
    80004466:	cc040513          	addi	a0,s0,-832
    8000446a:	1f3020ef          	jal	80006e5c <fslog_push>
}
    8000446e:	35813083          	ld	ra,856(sp)
    80004472:	35013403          	ld	s0,848(sp)
    80004476:	34813483          	ld	s1,840(sp)
    8000447a:	34013903          	ld	s2,832(sp)
    8000447e:	33813983          	ld	s3,824(sp)
    80004482:	36010113          	addi	sp,sp,864
    80004486:	8082                	ret

0000000080004488 <install_trans>:
}

static void
install_trans(int recovering)
{
  for (int tail = 0; tail < log.lh.n; tail++) {
    80004488:	0001e797          	auipc	a5,0x1e
    8000448c:	5687a783          	lw	a5,1384(a5) # 800229f0 <log+0x28>
    80004490:	12f05063          	blez	a5,800045b0 <install_trans+0x128>
{
    80004494:	7159                	addi	sp,sp,-112
    80004496:	f486                	sd	ra,104(sp)
    80004498:	f0a2                	sd	s0,96(sp)
    8000449a:	eca6                	sd	s1,88(sp)
    8000449c:	e8ca                	sd	s2,80(sp)
    8000449e:	e4ce                	sd	s3,72(sp)
    800044a0:	e0d2                	sd	s4,64(sp)
    800044a2:	fc56                	sd	s5,56(sp)
    800044a4:	f85a                	sd	s6,48(sp)
    800044a6:	f45e                	sd	s7,40(sp)
    800044a8:	f062                	sd	s8,32(sp)
    800044aa:	ec66                	sd	s9,24(sp)
    800044ac:	e86a                	sd	s10,16(sp)
    800044ae:	1880                	addi	s0,sp,112
    800044b0:	8b2a                	mv	s6,a0
    800044b2:	0001ea97          	auipc	s5,0x1e
    800044b6:	542a8a93          	addi	s5,s5,1346 # 800229f4 <log+0x2c>
  for (int tail = 0; tail < log.lh.n; tail++) {
    800044ba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1);
    800044bc:	0001e997          	auipc	s3,0x1e
    800044c0:	50c98993          	addi	s3,s3,1292 # 800229c8 <log>
    struct log_state old = log_get_state();

    if (recovering)
      log_report("RECOVER_BLK", log.lh.block[tail], old, "Recover block");
    else
      log_report("INSTALL_BLK", log.lh.block[tail], old, "Install block");
    800044c4:	00005d17          	auipc	s10,0x5
    800044c8:	4e4d0d13          	addi	s10,s10,1252 # 800099a8 <etext+0x9a8>
    800044cc:	00005c97          	auipc	s9,0x5
    800044d0:	4ecc8c93          	addi	s9,s9,1260 # 800099b8 <etext+0x9b8>
      log_report("RECOVER_BLK", log.lh.block[tail], old, "Recover block");
    800044d4:	00005c17          	auipc	s8,0x5
    800044d8:	4b4c0c13          	addi	s8,s8,1204 # 80009988 <etext+0x988>
    800044dc:	00005b97          	auipc	s7,0x5
    800044e0:	4bcb8b93          	addi	s7,s7,1212 # 80009998 <etext+0x998>
    800044e4:	a0a9                	j	8000452e <install_trans+0xa6>
      log_report("INSTALL_BLK", log.lh.block[tail], old, "Install block");
    800044e6:	876a                	mv	a4,s10
    800044e8:	f9043603          	ld	a2,-112(s0)
    800044ec:	f9843683          	ld	a3,-104(s0)
    800044f0:	000aa583          	lw	a1,0(s5)
    800044f4:	8566                	mv	a0,s9
    800044f6:	eb5ff0ef          	jal	800043aa <log_report>

    memmove(dbuf->data, lbuf->data, BSIZE);
    800044fa:	40000613          	li	a2,1024
    800044fe:	05890593          	addi	a1,s2,88
    80004502:	05848513          	addi	a0,s1,88
    80004506:	82bfc0ef          	jal	80000d30 <memmove>
    bwrite(dbuf);
    8000450a:	8526                	mv	a0,s1
    8000450c:	877fe0ef          	jal	80002d82 <bwrite>

    if (!recovering)
      bunpin(dbuf);
    80004510:	8526                	mv	a0,s1
    80004512:	9b7fe0ef          	jal	80002ec8 <bunpin>

    brelse(lbuf);
    80004516:	854a                	mv	a0,s2
    80004518:	8c3fe0ef          	jal	80002dda <brelse>
    brelse(dbuf);
    8000451c:	8526                	mv	a0,s1
    8000451e:	8bdfe0ef          	jal	80002dda <brelse>
  for (int tail = 0; tail < log.lh.n; tail++) {
    80004522:	2a05                	addiw	s4,s4,1
    80004524:	0a91                	addi	s5,s5,4
    80004526:	0289a783          	lw	a5,40(s3)
    8000452a:	06fa5563          	bge	s4,a5,80004594 <install_trans+0x10c>
    struct buf *lbuf = bread(log.dev, log.start+tail+1);
    8000452e:	0189a583          	lw	a1,24(s3)
    80004532:	014585bb          	addw	a1,a1,s4
    80004536:	2585                	addiw	a1,a1,1
    80004538:	0249a503          	lw	a0,36(s3)
    8000453c:	f08fe0ef          	jal	80002c44 <bread>
    80004540:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]);
    80004542:	000aa583          	lw	a1,0(s5)
    80004546:	0249a503          	lw	a0,36(s3)
    8000454a:	efafe0ef          	jal	80002c44 <bread>
    8000454e:	84aa                	mv	s1,a0
    struct log_state old = log_get_state();
    80004550:	e2fff0ef          	jal	8000437e <log_get_state>
    80004554:	f8a42823          	sw	a0,-112(s0)
    80004558:	02055793          	srli	a5,a0,0x20
    8000455c:	f8f42a23          	sw	a5,-108(s0)
    80004560:	f8b42c23          	sw	a1,-104(s0)
    if (recovering)
    80004564:	f80b01e3          	beqz	s6,800044e6 <install_trans+0x5e>
      log_report("RECOVER_BLK", log.lh.block[tail], old, "Recover block");
    80004568:	8762                	mv	a4,s8
    8000456a:	f9043603          	ld	a2,-112(s0)
    8000456e:	f9843683          	ld	a3,-104(s0)
    80004572:	000aa583          	lw	a1,0(s5)
    80004576:	855e                	mv	a0,s7
    80004578:	e33ff0ef          	jal	800043aa <log_report>
    memmove(dbuf->data, lbuf->data, BSIZE);
    8000457c:	40000613          	li	a2,1024
    80004580:	05890593          	addi	a1,s2,88
    80004584:	05848513          	addi	a0,s1,88
    80004588:	fa8fc0ef          	jal	80000d30 <memmove>
    bwrite(dbuf);
    8000458c:	8526                	mv	a0,s1
    8000458e:	ff4fe0ef          	jal	80002d82 <bwrite>
    if (!recovering)
    80004592:	b751                	j	80004516 <install_trans+0x8e>
  }
}
    80004594:	70a6                	ld	ra,104(sp)
    80004596:	7406                	ld	s0,96(sp)
    80004598:	64e6                	ld	s1,88(sp)
    8000459a:	6946                	ld	s2,80(sp)
    8000459c:	69a6                	ld	s3,72(sp)
    8000459e:	6a06                	ld	s4,64(sp)
    800045a0:	7ae2                	ld	s5,56(sp)
    800045a2:	7b42                	ld	s6,48(sp)
    800045a4:	7ba2                	ld	s7,40(sp)
    800045a6:	7c02                	ld	s8,32(sp)
    800045a8:	6ce2                	ld	s9,24(sp)
    800045aa:	6d42                	ld	s10,16(sp)
    800045ac:	6165                	addi	sp,sp,112
    800045ae:	8082                	ret
    800045b0:	8082                	ret

00000000800045b2 <write_head>:
{
    800045b2:	7179                	addi	sp,sp,-48
    800045b4:	f406                	sd	ra,40(sp)
    800045b6:	f022                	sd	s0,32(sp)
    800045b8:	ec26                	sd	s1,24(sp)
    800045ba:	e84a                	sd	s2,16(sp)
    800045bc:	1800                	addi	s0,sp,48
  struct buf *buf = bread(log.dev, log.start);
    800045be:	0001e917          	auipc	s2,0x1e
    800045c2:	40a90913          	addi	s2,s2,1034 # 800229c8 <log>
    800045c6:	01892583          	lw	a1,24(s2)
    800045ca:	02492503          	lw	a0,36(s2)
    800045ce:	e76fe0ef          	jal	80002c44 <bread>
    800045d2:	84aa                	mv	s1,a0
  struct log_state old = log_get_state();
    800045d4:	dabff0ef          	jal	8000437e <log_get_state>
    800045d8:	fca42823          	sw	a0,-48(s0)
    800045dc:	9101                	srli	a0,a0,0x20
    800045de:	fca42a23          	sw	a0,-44(s0)
    800045e2:	fcb42c23          	sw	a1,-40(s0)
  hb->n = log.lh.n;
    800045e6:	02892603          	lw	a2,40(s2)
    800045ea:	ccb0                	sw	a2,88(s1)
  for (int i = 0; i < log.lh.n; i++)
    800045ec:	00c05f63          	blez	a2,8000460a <write_head+0x58>
    800045f0:	0001e717          	auipc	a4,0x1e
    800045f4:	40470713          	addi	a4,a4,1028 # 800229f4 <log+0x2c>
    800045f8:	87a6                	mv	a5,s1
    800045fa:	060a                	slli	a2,a2,0x2
    800045fc:	9626                	add	a2,a2,s1
    hb->block[i] = log.lh.block[i];
    800045fe:	4314                	lw	a3,0(a4)
    80004600:	cff4                	sw	a3,92(a5)
  for (int i = 0; i < log.lh.n; i++)
    80004602:	0711                	addi	a4,a4,4
    80004604:	0791                	addi	a5,a5,4
    80004606:	fec79ce3          	bne	a5,a2,800045fe <write_head+0x4c>
  bwrite(buf);
    8000460a:	8526                	mv	a0,s1
    8000460c:	f76fe0ef          	jal	80002d82 <bwrite>
  log_report("WRITE_HEAD", 0, old, "Write log header to disk");
    80004610:	00005717          	auipc	a4,0x5
    80004614:	3b870713          	addi	a4,a4,952 # 800099c8 <etext+0x9c8>
    80004618:	fd043603          	ld	a2,-48(s0)
    8000461c:	fd843683          	ld	a3,-40(s0)
    80004620:	4581                	li	a1,0
    80004622:	00005517          	auipc	a0,0x5
    80004626:	3c650513          	addi	a0,a0,966 # 800099e8 <etext+0x9e8>
    8000462a:	d81ff0ef          	jal	800043aa <log_report>
  brelse(buf);
    8000462e:	8526                	mv	a0,s1
    80004630:	faafe0ef          	jal	80002dda <brelse>
}
    80004634:	70a2                	ld	ra,40(sp)
    80004636:	7402                	ld	s0,32(sp)
    80004638:	64e2                	ld	s1,24(sp)
    8000463a:	6942                	ld	s2,16(sp)
    8000463c:	6145                	addi	sp,sp,48
    8000463e:	8082                	ret

0000000080004640 <initlog>:
{
    80004640:	715d                	addi	sp,sp,-80
    80004642:	e486                	sd	ra,72(sp)
    80004644:	e0a2                	sd	s0,64(sp)
    80004646:	fc26                	sd	s1,56(sp)
    80004648:	f84a                	sd	s2,48(sp)
    8000464a:	f44e                	sd	s3,40(sp)
    8000464c:	0880                	addi	s0,sp,80
    8000464e:	892a                	mv	s2,a0
    80004650:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004652:	0001e497          	auipc	s1,0x1e
    80004656:	37648493          	addi	s1,s1,886 # 800229c8 <log>
    8000465a:	00005597          	auipc	a1,0x5
    8000465e:	39e58593          	addi	a1,a1,926 # 800099f8 <etext+0x9f8>
    80004662:	8526                	mv	a0,s1
    80004664:	d1cfc0ef          	jal	80000b80 <initlock>
  log.start = sb->logstart;
    80004668:	0149a783          	lw	a5,20(s3)
    8000466c:	cc9c                	sw	a5,24(s1)
  log.dev = dev;
    8000466e:	0324a223          	sw	s2,36(s1)
  struct log_state old = log_get_state();
    80004672:	d0dff0ef          	jal	8000437e <log_get_state>
    80004676:	fca42023          	sw	a0,-64(s0)
    8000467a:	9101                	srli	a0,a0,0x20
    8000467c:	fca42223          	sw	a0,-60(s0)
    80004680:	fcb42423          	sw	a1,-56(s0)
  log_report("INIT_LOG", 0, old, "Initialize log system");
    80004684:	00005717          	auipc	a4,0x5
    80004688:	37c70713          	addi	a4,a4,892 # 80009a00 <etext+0xa00>
    8000468c:	fc043603          	ld	a2,-64(s0)
    80004690:	fc843683          	ld	a3,-56(s0)
    80004694:	4581                	li	a1,0
    80004696:	00005517          	auipc	a0,0x5
    8000469a:	38250513          	addi	a0,a0,898 # 80009a18 <etext+0xa18>
    8000469e:	d0dff0ef          	jal	800043aa <log_report>
  struct buf *buf = bread(log.dev, log.start);
    800046a2:	4c8c                	lw	a1,24(s1)
    800046a4:	50c8                	lw	a0,36(s1)
    800046a6:	d9efe0ef          	jal	80002c44 <bread>
    800046aa:	892a                	mv	s2,a0
  struct log_state old = log_get_state();
    800046ac:	cd3ff0ef          	jal	8000437e <log_get_state>
    800046b0:	faa42823          	sw	a0,-80(s0)
    800046b4:	02055793          	srli	a5,a0,0x20
    800046b8:	faf42a23          	sw	a5,-76(s0)
    800046bc:	fab42c23          	sw	a1,-72(s0)
  log.lh.n = lh->n;
    800046c0:	05892603          	lw	a2,88(s2)
    800046c4:	d490                	sw	a2,40(s1)
  for (int i = 0; i < log.lh.n; i++)
    800046c6:	00c05f63          	blez	a2,800046e4 <initlog+0xa4>
    800046ca:	87ca                	mv	a5,s2
    800046cc:	0001e717          	auipc	a4,0x1e
    800046d0:	32870713          	addi	a4,a4,808 # 800229f4 <log+0x2c>
    800046d4:	060a                	slli	a2,a2,0x2
    800046d6:	964a                	add	a2,a2,s2
    log.lh.block[i] = lh->block[i];
    800046d8:	4ff4                	lw	a3,92(a5)
    800046da:	c314                	sw	a3,0(a4)
  for (int i = 0; i < log.lh.n; i++)
    800046dc:	0791                	addi	a5,a5,4
    800046de:	0711                	addi	a4,a4,4
    800046e0:	fec79ce3          	bne	a5,a2,800046d8 <initlog+0x98>
  log_report("READ_HEAD", 0, old, "Read log header from disk");
    800046e4:	00005717          	auipc	a4,0x5
    800046e8:	34470713          	addi	a4,a4,836 # 80009a28 <etext+0xa28>
    800046ec:	fb043603          	ld	a2,-80(s0)
    800046f0:	fb843683          	ld	a3,-72(s0)
    800046f4:	4581                	li	a1,0
    800046f6:	00005517          	auipc	a0,0x5
    800046fa:	35250513          	addi	a0,a0,850 # 80009a48 <etext+0xa48>
    800046fe:	cadff0ef          	jal	800043aa <log_report>
  brelse(buf);
    80004702:	854a                	mv	a0,s2
    80004704:	ed6fe0ef          	jal	80002dda <brelse>
static void
recover_from_log(void)
{
  read_head();

  if (log.lh.n > 0) {
    80004708:	0001e797          	auipc	a5,0x1e
    8000470c:	2e87a783          	lw	a5,744(a5) # 800229f0 <log+0x28>
    80004710:	00f04963          	bgtz	a5,80004722 <initlog+0xe2>
}
    80004714:	60a6                	ld	ra,72(sp)
    80004716:	6406                	ld	s0,64(sp)
    80004718:	74e2                	ld	s1,56(sp)
    8000471a:	7942                	ld	s2,48(sp)
    8000471c:	79a2                	ld	s3,40(sp)
    8000471e:	6161                	addi	sp,sp,80
    80004720:	8082                	ret
    struct log_state old = log_get_state();
    80004722:	c5dff0ef          	jal	8000437e <log_get_state>
    80004726:	faa42823          	sw	a0,-80(s0)
    8000472a:	9101                	srli	a0,a0,0x20
    8000472c:	faa42a23          	sw	a0,-76(s0)
    80004730:	fab42c23          	sw	a1,-72(s0)

    log_report("RECOVER_START", 0, old, "Start recovery");
    80004734:	00005717          	auipc	a4,0x5
    80004738:	32470713          	addi	a4,a4,804 # 80009a58 <etext+0xa58>
    8000473c:	fb043603          	ld	a2,-80(s0)
    80004740:	fb843683          	ld	a3,-72(s0)
    80004744:	4581                	li	a1,0
    80004746:	00005517          	auipc	a0,0x5
    8000474a:	32250513          	addi	a0,a0,802 # 80009a68 <etext+0xa68>
    8000474e:	c5dff0ef          	jal	800043aa <log_report>

    install_trans(1);
    80004752:	4505                	li	a0,1
    80004754:	d35ff0ef          	jal	80004488 <install_trans>

    old = log_get_state();
    80004758:	c27ff0ef          	jal	8000437e <log_get_state>
    8000475c:	faa42823          	sw	a0,-80(s0)
    80004760:	9101                	srli	a0,a0,0x20
    80004762:	faa42a23          	sw	a0,-76(s0)
    80004766:	fab42c23          	sw	a1,-72(s0)
    log.lh.n = 0;
    8000476a:	0001e797          	auipc	a5,0x1e
    8000476e:	2807a323          	sw	zero,646(a5) # 800229f0 <log+0x28>
    write_head();
    80004772:	e41ff0ef          	jal	800045b2 <write_head>

    log_report("RECOVER_DONE", 0, old, "Recovery done");
    80004776:	00005717          	auipc	a4,0x5
    8000477a:	30270713          	addi	a4,a4,770 # 80009a78 <etext+0xa78>
    8000477e:	fb043603          	ld	a2,-80(s0)
    80004782:	fb843683          	ld	a3,-72(s0)
    80004786:	4581                	li	a1,0
    80004788:	00005517          	auipc	a0,0x5
    8000478c:	30050513          	addi	a0,a0,768 # 80009a88 <etext+0xa88>
    80004790:	c1bff0ef          	jal	800043aa <log_report>
}
    80004794:	b741                	j	80004714 <initlog+0xd4>

0000000080004796 <begin_op>:
  }
}

void
begin_op(void)
{
    80004796:	711d                	addi	sp,sp,-96
    80004798:	ec86                	sd	ra,88(sp)
    8000479a:	e8a2                	sd	s0,80(sp)
    8000479c:	e4a6                	sd	s1,72(sp)
    8000479e:	e0ca                	sd	s2,64(sp)
    800047a0:	fc4e                	sd	s3,56(sp)
    800047a2:	f852                	sd	s4,48(sp)
    800047a4:	f456                	sd	s5,40(sp)
    800047a6:	f05a                	sd	s6,32(sp)
    800047a8:	ec5e                	sd	s7,24(sp)
    800047aa:	1080                	addi	s0,sp,96
  acquire(&log.lock);
    800047ac:	0001e517          	auipc	a0,0x1e
    800047b0:	21c50513          	addi	a0,a0,540 # 800229c8 <log>
    800047b4:	c4cfc0ef          	jal	80000c00 <acquire>

  while (1) {
    if (log.committing) {
    800047b8:	0001e497          	auipc	s1,0x1e
    800047bc:	21048493          	addi	s1,s1,528 # 800229c8 <log>
      struct log_state old = log_get_state();
      log_report("WAIT_COMMIT", 0, old, "Waiting for commit");
      sleep(&log, &log.lock);

    } else if (log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS) {
    800047c0:	4979                	li	s2,30
      struct log_state old = log_get_state();
      log_report("WAIT_SPACE", 0, old, "Waiting for log space");
    800047c2:	00005a17          	auipc	s4,0x5
    800047c6:	2fea0a13          	addi	s4,s4,766 # 80009ac0 <etext+0xac0>
    800047ca:	00005997          	auipc	s3,0x5
    800047ce:	30e98993          	addi	s3,s3,782 # 80009ad8 <etext+0xad8>
      log_report("WAIT_COMMIT", 0, old, "Waiting for commit");
    800047d2:	00005b17          	auipc	s6,0x5
    800047d6:	2c6b0b13          	addi	s6,s6,710 # 80009a98 <etext+0xa98>
    800047da:	00005a97          	auipc	s5,0x5
    800047de:	2d6a8a93          	addi	s5,s5,726 # 80009ab0 <etext+0xab0>
    800047e2:	a03d                	j	80004810 <begin_op+0x7a>
      struct log_state old = log_get_state();
    800047e4:	b9bff0ef          	jal	8000437e <log_get_state>
    800047e8:	faa42023          	sw	a0,-96(s0)
    800047ec:	9101                	srli	a0,a0,0x20
    800047ee:	faa42223          	sw	a0,-92(s0)
    800047f2:	fab42423          	sw	a1,-88(s0)
      log_report("WAIT_COMMIT", 0, old, "Waiting for commit");
    800047f6:	875a                	mv	a4,s6
    800047f8:	fa043603          	ld	a2,-96(s0)
    800047fc:	fa843683          	ld	a3,-88(s0)
    80004800:	4581                	li	a1,0
    80004802:	8556                	mv	a0,s5
    80004804:	ba7ff0ef          	jal	800043aa <log_report>
      sleep(&log, &log.lock);
    80004808:	85a6                	mv	a1,s1
    8000480a:	8526                	mv	a0,s1
    8000480c:	f0cfd0ef          	jal	80001f18 <sleep>
    if (log.committing) {
    80004810:	509c                	lw	a5,32(s1)
    80004812:	fbe9                	bnez	a5,800047e4 <begin_op+0x4e>
    } else if (log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS) {
    80004814:	01c4ab83          	lw	s7,28(s1)
    80004818:	2b85                	addiw	s7,s7,1
    8000481a:	002b979b          	slliw	a5,s7,0x2
    8000481e:	017787bb          	addw	a5,a5,s7
    80004822:	0017979b          	slliw	a5,a5,0x1
    80004826:	5498                	lw	a4,40(s1)
    80004828:	9fb9                	addw	a5,a5,a4
    8000482a:	02f95963          	bge	s2,a5,8000485c <begin_op+0xc6>
      struct log_state old = log_get_state();
    8000482e:	b51ff0ef          	jal	8000437e <log_get_state>
    80004832:	faa42023          	sw	a0,-96(s0)
    80004836:	9101                	srli	a0,a0,0x20
    80004838:	faa42223          	sw	a0,-92(s0)
    8000483c:	fab42423          	sw	a1,-88(s0)
      log_report("WAIT_SPACE", 0, old, "Waiting for log space");
    80004840:	8752                	mv	a4,s4
    80004842:	fa043603          	ld	a2,-96(s0)
    80004846:	fa843683          	ld	a3,-88(s0)
    8000484a:	4581                	li	a1,0
    8000484c:	854e                	mv	a0,s3
    8000484e:	b5dff0ef          	jal	800043aa <log_report>
      sleep(&log, &log.lock);
    80004852:	85a6                	mv	a1,s1
    80004854:	8526                	mv	a0,s1
    80004856:	ec2fd0ef          	jal	80001f18 <sleep>
    8000485a:	bf5d                	j	80004810 <begin_op+0x7a>

    } else {
      struct log_state old = log_get_state();
    8000485c:	b23ff0ef          	jal	8000437e <log_get_state>
    80004860:	faa42023          	sw	a0,-96(s0)
    80004864:	9101                	srli	a0,a0,0x20
    80004866:	faa42223          	sw	a0,-92(s0)
    8000486a:	fab42423          	sw	a1,-88(s0)

      log.outstanding++;
    8000486e:	0001e497          	auipc	s1,0x1e
    80004872:	15a48493          	addi	s1,s1,346 # 800229c8 <log>
    80004876:	0174ae23          	sw	s7,28(s1)

      log_report("BEGIN_OP", 0, old, "Begin operation");
    8000487a:	00005717          	auipc	a4,0x5
    8000487e:	26e70713          	addi	a4,a4,622 # 80009ae8 <etext+0xae8>
    80004882:	fa043603          	ld	a2,-96(s0)
    80004886:	fa843683          	ld	a3,-88(s0)
    8000488a:	4581                	li	a1,0
    8000488c:	00005517          	auipc	a0,0x5
    80004890:	26c50513          	addi	a0,a0,620 # 80009af8 <etext+0xaf8>
    80004894:	b17ff0ef          	jal	800043aa <log_report>

      release(&log.lock);
    80004898:	8526                	mv	a0,s1
    8000489a:	bfefc0ef          	jal	80000c98 <release>
      break;
    }
  }
}
    8000489e:	60e6                	ld	ra,88(sp)
    800048a0:	6446                	ld	s0,80(sp)
    800048a2:	64a6                	ld	s1,72(sp)
    800048a4:	6906                	ld	s2,64(sp)
    800048a6:	79e2                	ld	s3,56(sp)
    800048a8:	7a42                	ld	s4,48(sp)
    800048aa:	7aa2                	ld	s5,40(sp)
    800048ac:	7b02                	ld	s6,32(sp)
    800048ae:	6be2                	ld	s7,24(sp)
    800048b0:	6125                	addi	sp,sp,96
    800048b2:	8082                	ret

00000000800048b4 <end_op>:

void
end_op(void)
{
    800048b4:	7119                	addi	sp,sp,-128
    800048b6:	fc86                	sd	ra,120(sp)
    800048b8:	f8a2                	sd	s0,112(sp)
    800048ba:	f4a6                	sd	s1,104(sp)
    800048bc:	f0ca                	sd	s2,96(sp)
    800048be:	0100                	addi	s0,sp,128
  int do_commit = 0;

  acquire(&log.lock);
    800048c0:	0001e497          	auipc	s1,0x1e
    800048c4:	10848493          	addi	s1,s1,264 # 800229c8 <log>
    800048c8:	8526                	mv	a0,s1
    800048ca:	b36fc0ef          	jal	80000c00 <acquire>

  struct log_state old = log_get_state();
    800048ce:	ab1ff0ef          	jal	8000437e <log_get_state>
    800048d2:	faa42023          	sw	a0,-96(s0)
    800048d6:	9101                	srli	a0,a0,0x20
    800048d8:	faa42223          	sw	a0,-92(s0)
    800048dc:	fab42423          	sw	a1,-88(s0)

  log.outstanding--;
    800048e0:	4cdc                	lw	a5,28(s1)
    800048e2:	37fd                	addiw	a5,a5,-1
    800048e4:	0007891b          	sext.w	s2,a5
    800048e8:	ccdc                	sw	a5,28(s1)

  if (log.outstanding == 0) {
    800048ea:	08091163          	bnez	s2,8000496c <end_op+0xb8>
    do_commit = 1;
    log.committing = 1;
    800048ee:	4785                	li	a5,1
    800048f0:	d09c                	sw	a5,32(s1)

    log_report("PRE_COMMIT", 0, old, "Start committing");
    800048f2:	00005717          	auipc	a4,0x5
    800048f6:	21670713          	addi	a4,a4,534 # 80009b08 <etext+0xb08>
    800048fa:	fa043603          	ld	a2,-96(s0)
    800048fe:	fa843683          	ld	a3,-88(s0)
    80004902:	4581                	li	a1,0
    80004904:	00005517          	auipc	a0,0x5
    80004908:	21c50513          	addi	a0,a0,540 # 80009b20 <etext+0xb20>
    8000490c:	a9fff0ef          	jal	800043aa <log_report>
  } else {
    log_report("END_OP", 0, old, "End operation");
    wakeup(&log);
  }

  release(&log.lock);
    80004910:	8526                	mv	a0,s1
    80004912:	b86fc0ef          	jal	80000c98 <release>
}

static void
commit(void)
{
  if (log.lh.n > 0) {
    80004916:	549c                	lw	a5,40(s1)
    80004918:	08f04963          	bgtz	a5,800049aa <end_op+0xf6>
    acquire(&log.lock);
    8000491c:	0001e497          	auipc	s1,0x1e
    80004920:	0ac48493          	addi	s1,s1,172 # 800229c8 <log>
    80004924:	8526                	mv	a0,s1
    80004926:	adafc0ef          	jal	80000c00 <acquire>
    old = log_get_state();
    8000492a:	a55ff0ef          	jal	8000437e <log_get_state>
    8000492e:	faa42023          	sw	a0,-96(s0)
    80004932:	9101                	srli	a0,a0,0x20
    80004934:	faa42223          	sw	a0,-92(s0)
    80004938:	fab42423          	sw	a1,-88(s0)
    log.committing = 0;
    8000493c:	0204a023          	sw	zero,32(s1)
    log_report("FINAL_RELEASE", 0, old, "Commit finished");
    80004940:	00005717          	auipc	a4,0x5
    80004944:	28070713          	addi	a4,a4,640 # 80009bc0 <etext+0xbc0>
    80004948:	fa043603          	ld	a2,-96(s0)
    8000494c:	fa843683          	ld	a3,-88(s0)
    80004950:	4581                	li	a1,0
    80004952:	00005517          	auipc	a0,0x5
    80004956:	27e50513          	addi	a0,a0,638 # 80009bd0 <etext+0xbd0>
    8000495a:	a51ff0ef          	jal	800043aa <log_report>
    wakeup(&log);
    8000495e:	8526                	mv	a0,s1
    80004960:	e04fd0ef          	jal	80001f64 <wakeup>
    release(&log.lock);
    80004964:	8526                	mv	a0,s1
    80004966:	b32fc0ef          	jal	80000c98 <release>
}
    8000496a:	a815                	j	8000499e <end_op+0xea>
    log_report("END_OP", 0, old, "End operation");
    8000496c:	00005717          	auipc	a4,0x5
    80004970:	1c470713          	addi	a4,a4,452 # 80009b30 <etext+0xb30>
    80004974:	fa043603          	ld	a2,-96(s0)
    80004978:	fa843683          	ld	a3,-88(s0)
    8000497c:	4581                	li	a1,0
    8000497e:	00005517          	auipc	a0,0x5
    80004982:	1c250513          	addi	a0,a0,450 # 80009b40 <etext+0xb40>
    80004986:	a25ff0ef          	jal	800043aa <log_report>
    wakeup(&log);
    8000498a:	0001e497          	auipc	s1,0x1e
    8000498e:	03e48493          	addi	s1,s1,62 # 800229c8 <log>
    80004992:	8526                	mv	a0,s1
    80004994:	dd0fd0ef          	jal	80001f64 <wakeup>
  release(&log.lock);
    80004998:	8526                	mv	a0,s1
    8000499a:	afefc0ef          	jal	80000c98 <release>
}
    8000499e:	70e6                	ld	ra,120(sp)
    800049a0:	7446                	ld	s0,112(sp)
    800049a2:	74a6                	ld	s1,104(sp)
    800049a4:	7906                	ld	s2,96(sp)
    800049a6:	6109                	addi	sp,sp,128
    800049a8:	8082                	ret
    struct log_state old = log_get_state();
    800049aa:	9d5ff0ef          	jal	8000437e <log_get_state>
    800049ae:	f8a42023          	sw	a0,-128(s0)
    800049b2:	9101                	srli	a0,a0,0x20
    800049b4:	f8a42223          	sw	a0,-124(s0)
    800049b8:	f8b42423          	sw	a1,-120(s0)

    log_report("COMMIT_START", 0, old, "Commit start");
    800049bc:	00005717          	auipc	a4,0x5
    800049c0:	18c70713          	addi	a4,a4,396 # 80009b48 <etext+0xb48>
    800049c4:	f8043603          	ld	a2,-128(s0)
    800049c8:	f8843683          	ld	a3,-120(s0)
    800049cc:	4581                	li	a1,0
    800049ce:	00005517          	auipc	a0,0x5
    800049d2:	18a50513          	addi	a0,a0,394 # 80009b58 <etext+0xb58>
    800049d6:	9d5ff0ef          	jal	800043aa <log_report>
  for (int tail = 0; tail < log.lh.n; tail++) {
    800049da:	0001e797          	auipc	a5,0x1e
    800049de:	0167a783          	lw	a5,22(a5) # 800229f0 <log+0x28>
    800049e2:	0af05863          	blez	a5,80004a92 <end_op+0x1de>
    800049e6:	ecce                	sd	s3,88(sp)
    800049e8:	e8d2                	sd	s4,80(sp)
    800049ea:	e4d6                	sd	s5,72(sp)
    800049ec:	e0da                	sd	s6,64(sp)
    800049ee:	fc5e                	sd	s7,56(sp)
    800049f0:	0001ea97          	auipc	s5,0x1e
    800049f4:	004a8a93          	addi	s5,s5,4 # 800229f4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1);
    800049f8:	0001ea17          	auipc	s4,0x1e
    800049fc:	fd0a0a13          	addi	s4,s4,-48 # 800229c8 <log>
    log_report("LOG_SYNC", log.lh.block[tail], old, "Write to log");
    80004a00:	00005b97          	auipc	s7,0x5
    80004a04:	168b8b93          	addi	s7,s7,360 # 80009b68 <etext+0xb68>
    80004a08:	00005b17          	auipc	s6,0x5
    80004a0c:	170b0b13          	addi	s6,s6,368 # 80009b78 <etext+0xb78>
    struct buf *to = bread(log.dev, log.start+tail+1);
    80004a10:	018a2583          	lw	a1,24(s4)
    80004a14:	012585bb          	addw	a1,a1,s2
    80004a18:	2585                	addiw	a1,a1,1
    80004a1a:	024a2503          	lw	a0,36(s4)
    80004a1e:	a26fe0ef          	jal	80002c44 <bread>
    80004a22:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]);
    80004a24:	000aa583          	lw	a1,0(s5)
    80004a28:	024a2503          	lw	a0,36(s4)
    80004a2c:	a18fe0ef          	jal	80002c44 <bread>
    80004a30:	89aa                	mv	s3,a0
    struct log_state old = log_get_state();
    80004a32:	94dff0ef          	jal	8000437e <log_get_state>
    80004a36:	f8a42823          	sw	a0,-112(s0)
    80004a3a:	02055793          	srli	a5,a0,0x20
    80004a3e:	f8f42a23          	sw	a5,-108(s0)
    80004a42:	f8b42c23          	sw	a1,-104(s0)
    log_report("LOG_SYNC", log.lh.block[tail], old, "Write to log");
    80004a46:	875e                	mv	a4,s7
    80004a48:	f9043603          	ld	a2,-112(s0)
    80004a4c:	f9843683          	ld	a3,-104(s0)
    80004a50:	000aa583          	lw	a1,0(s5)
    80004a54:	855a                	mv	a0,s6
    80004a56:	955ff0ef          	jal	800043aa <log_report>
    memmove(to->data, from->data, BSIZE);
    80004a5a:	40000613          	li	a2,1024
    80004a5e:	05898593          	addi	a1,s3,88
    80004a62:	05848513          	addi	a0,s1,88
    80004a66:	acafc0ef          	jal	80000d30 <memmove>
    bwrite(to);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	b16fe0ef          	jal	80002d82 <bwrite>
    brelse(from);
    80004a70:	854e                	mv	a0,s3
    80004a72:	b68fe0ef          	jal	80002dda <brelse>
    brelse(to);
    80004a76:	8526                	mv	a0,s1
    80004a78:	b62fe0ef          	jal	80002dda <brelse>
  for (int tail = 0; tail < log.lh.n; tail++) {
    80004a7c:	2905                	addiw	s2,s2,1
    80004a7e:	0a91                	addi	s5,s5,4
    80004a80:	028a2783          	lw	a5,40(s4)
    80004a84:	f8f946e3          	blt	s2,a5,80004a10 <end_op+0x15c>
    80004a88:	69e6                	ld	s3,88(sp)
    80004a8a:	6a46                	ld	s4,80(sp)
    80004a8c:	6aa6                	ld	s5,72(sp)
    80004a8e:	6b06                	ld	s6,64(sp)
    80004a90:	7be2                	ld	s7,56(sp)

    write_log();
    write_head();
    80004a92:	b21ff0ef          	jal	800045b2 <write_head>

    old = log_get_state();
    80004a96:	8e9ff0ef          	jal	8000437e <log_get_state>
    80004a9a:	f8a42023          	sw	a0,-128(s0)
    80004a9e:	9101                	srli	a0,a0,0x20
    80004aa0:	f8a42223          	sw	a0,-124(s0)
    80004aa4:	f8b42423          	sw	a1,-120(s0)
    log_report("WRITE_HEAD", 0, old, "Header committed");
    80004aa8:	00005717          	auipc	a4,0x5
    80004aac:	0e070713          	addi	a4,a4,224 # 80009b88 <etext+0xb88>
    80004ab0:	f8043603          	ld	a2,-128(s0)
    80004ab4:	f8843683          	ld	a3,-120(s0)
    80004ab8:	4581                	li	a1,0
    80004aba:	00005517          	auipc	a0,0x5
    80004abe:	f2e50513          	addi	a0,a0,-210 # 800099e8 <etext+0x9e8>
    80004ac2:	8e9ff0ef          	jal	800043aa <log_report>

    install_trans(0);
    80004ac6:	4501                	li	a0,0
    80004ac8:	9c1ff0ef          	jal	80004488 <install_trans>

    old = log_get_state();
    80004acc:	8b3ff0ef          	jal	8000437e <log_get_state>
    80004ad0:	f8a42023          	sw	a0,-128(s0)
    80004ad4:	9101                	srli	a0,a0,0x20
    80004ad6:	f8a42223          	sw	a0,-124(s0)
    80004ada:	f8b42423          	sw	a1,-120(s0)
    log.lh.n = 0;
    80004ade:	0001e797          	auipc	a5,0x1e
    80004ae2:	f007a923          	sw	zero,-238(a5) # 800229f0 <log+0x28>
    write_head();
    80004ae6:	acdff0ef          	jal	800045b2 <write_head>

    log_report("COMMIT_DONE", 0, old, "Commit done");
    80004aea:	00005717          	auipc	a4,0x5
    80004aee:	0b670713          	addi	a4,a4,182 # 80009ba0 <etext+0xba0>
    80004af2:	f8043603          	ld	a2,-128(s0)
    80004af6:	f8843683          	ld	a3,-120(s0)
    80004afa:	4581                	li	a1,0
    80004afc:	00005517          	auipc	a0,0x5
    80004b00:	0b450513          	addi	a0,a0,180 # 80009bb0 <etext+0xbb0>
    80004b04:	8a7ff0ef          	jal	800043aa <log_report>
    80004b08:	bd11                	j	8000491c <end_op+0x68>

0000000080004b0a <log_write>:
  }
}

void
log_write(struct buf *b)
{
    80004b0a:	7179                	addi	sp,sp,-48
    80004b0c:	f406                	sd	ra,40(sp)
    80004b0e:	f022                	sd	s0,32(sp)
    80004b10:	ec26                	sd	s1,24(sp)
    80004b12:	e84a                	sd	s2,16(sp)
    80004b14:	1800                	addi	s0,sp,48
    80004b16:	84aa                	mv	s1,a0
  acquire(&log.lock);
    80004b18:	0001e917          	auipc	s2,0x1e
    80004b1c:	eb090913          	addi	s2,s2,-336 # 800229c8 <log>
    80004b20:	854a                	mv	a0,s2
    80004b22:	8defc0ef          	jal	80000c00 <acquire>

  struct log_state old = log_get_state();
    80004b26:	859ff0ef          	jal	8000437e <log_get_state>
    80004b2a:	fca42823          	sw	a0,-48(s0)
    80004b2e:	02055793          	srli	a5,a0,0x20
    80004b32:	fcf42a23          	sw	a5,-44(s0)
    80004b36:	fcb42c23          	sw	a1,-40(s0)

  int i;
  for (i = 0; i < log.lh.n; i++) {
    80004b3a:	02892603          	lw	a2,40(s2)
    80004b3e:	06c05263          	blez	a2,80004ba2 <log_write+0x98>
    if (log.lh.block[i] == b->blockno)
    80004b42:	44cc                	lw	a1,12(s1)
    80004b44:	0001e717          	auipc	a4,0x1e
    80004b48:	eb070713          	addi	a4,a4,-336 # 800229f4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80004b4c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)
    80004b4e:	4314                	lw	a3,0(a4)
    80004b50:	04b68a63          	beq	a3,a1,80004ba4 <log_write+0x9a>
  for (i = 0; i < log.lh.n; i++) {
    80004b54:	2785                	addiw	a5,a5,1
    80004b56:	0711                	addi	a4,a4,4
    80004b58:	fec79be3          	bne	a5,a2,80004b4e <log_write+0x44>
      break;
  }

  log.lh.block[i] = b->blockno;
    80004b5c:	0621                	addi	a2,a2,8
    80004b5e:	060a                	slli	a2,a2,0x2
    80004b60:	0001e797          	auipc	a5,0x1e
    80004b64:	e6878793          	addi	a5,a5,-408 # 800229c8 <log>
    80004b68:	97b2                	add	a5,a5,a2
    80004b6a:	44d8                	lw	a4,12(s1)
    80004b6c:	c7d8                	sw	a4,12(a5)

  if (i == log.lh.n) {
    bpin(b);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	b0afe0ef          	jal	80002e7a <bpin>
    log.lh.n++;
    80004b74:	0001e717          	auipc	a4,0x1e
    80004b78:	e5470713          	addi	a4,a4,-428 # 800229c8 <log>
    80004b7c:	571c                	lw	a5,40(a4)
    80004b7e:	2785                	addiw	a5,a5,1
    80004b80:	d71c                	sw	a5,40(a4)

    log_report("LOG_WRITE", b->blockno, old, "Add block to log");
    80004b82:	00005717          	auipc	a4,0x5
    80004b86:	05e70713          	addi	a4,a4,94 # 80009be0 <etext+0xbe0>
    80004b8a:	fd043603          	ld	a2,-48(s0)
    80004b8e:	fd843683          	ld	a3,-40(s0)
    80004b92:	44cc                	lw	a1,12(s1)
    80004b94:	00005517          	auipc	a0,0x5
    80004b98:	06450513          	addi	a0,a0,100 # 80009bf8 <etext+0xbf8>
    80004b9c:	80fff0ef          	jal	800043aa <log_report>
    80004ba0:	a82d                	j	80004bda <log_write+0xd0>
  for (i = 0; i < log.lh.n; i++) {
    80004ba2:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004ba4:	00878693          	addi	a3,a5,8
    80004ba8:	068a                	slli	a3,a3,0x2
    80004baa:	0001e717          	auipc	a4,0x1e
    80004bae:	e1e70713          	addi	a4,a4,-482 # 800229c8 <log>
    80004bb2:	9736                	add	a4,a4,a3
    80004bb4:	44d4                	lw	a3,12(s1)
    80004bb6:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {
    80004bb8:	faf60be3          	beq	a2,a5,80004b6e <log_write+0x64>
  } else {
    log_report("LOG_MERGE", b->blockno, old, "Merge block");
    80004bbc:	00005717          	auipc	a4,0x5
    80004bc0:	04c70713          	addi	a4,a4,76 # 80009c08 <etext+0xc08>
    80004bc4:	fd043603          	ld	a2,-48(s0)
    80004bc8:	fd843683          	ld	a3,-40(s0)
    80004bcc:	44cc                	lw	a1,12(s1)
    80004bce:	00005517          	auipc	a0,0x5
    80004bd2:	04a50513          	addi	a0,a0,74 # 80009c18 <etext+0xc18>
    80004bd6:	fd4ff0ef          	jal	800043aa <log_report>
  }

  release(&log.lock);
    80004bda:	0001e517          	auipc	a0,0x1e
    80004bde:	dee50513          	addi	a0,a0,-530 # 800229c8 <log>
    80004be2:	8b6fc0ef          	jal	80000c98 <release>
    80004be6:	70a2                	ld	ra,40(sp)
    80004be8:	7402                	ld	s0,32(sp)
    80004bea:	64e2                	ld	s1,24(sp)
    80004bec:	6942                	ld	s2,16(sp)
    80004bee:	6145                	addi	sp,sp,48
    80004bf0:	8082                	ret

0000000080004bf2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004bf2:	1101                	addi	sp,sp,-32
    80004bf4:	ec06                	sd	ra,24(sp)
    80004bf6:	e822                	sd	s0,16(sp)
    80004bf8:	e426                	sd	s1,8(sp)
    80004bfa:	e04a                	sd	s2,0(sp)
    80004bfc:	1000                	addi	s0,sp,32
    80004bfe:	84aa                	mv	s1,a0
    80004c00:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c02:	00005597          	auipc	a1,0x5
    80004c06:	02658593          	addi	a1,a1,38 # 80009c28 <etext+0xc28>
    80004c0a:	0521                	addi	a0,a0,8
    80004c0c:	f75fb0ef          	jal	80000b80 <initlock>
  lk->name = name;
    80004c10:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c14:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c18:	0204a423          	sw	zero,40(s1)
}
    80004c1c:	60e2                	ld	ra,24(sp)
    80004c1e:	6442                	ld	s0,16(sp)
    80004c20:	64a2                	ld	s1,8(sp)
    80004c22:	6902                	ld	s2,0(sp)
    80004c24:	6105                	addi	sp,sp,32
    80004c26:	8082                	ret

0000000080004c28 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c28:	1101                	addi	sp,sp,-32
    80004c2a:	ec06                	sd	ra,24(sp)
    80004c2c:	e822                	sd	s0,16(sp)
    80004c2e:	e426                	sd	s1,8(sp)
    80004c30:	e04a                	sd	s2,0(sp)
    80004c32:	1000                	addi	s0,sp,32
    80004c34:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c36:	00850913          	addi	s2,a0,8
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	fc5fb0ef          	jal	80000c00 <acquire>
  while (lk->locked) {
    80004c40:	409c                	lw	a5,0(s1)
    80004c42:	c799                	beqz	a5,80004c50 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80004c44:	85ca                	mv	a1,s2
    80004c46:	8526                	mv	a0,s1
    80004c48:	ad0fd0ef          	jal	80001f18 <sleep>
  while (lk->locked) {
    80004c4c:	409c                	lw	a5,0(s1)
    80004c4e:	fbfd                	bnez	a5,80004c44 <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80004c50:	4785                	li	a5,1
    80004c52:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c54:	cb5fc0ef          	jal	80001908 <myproc>
    80004c58:	591c                	lw	a5,48(a0)
    80004c5a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c5c:	854a                	mv	a0,s2
    80004c5e:	83afc0ef          	jal	80000c98 <release>
}
    80004c62:	60e2                	ld	ra,24(sp)
    80004c64:	6442                	ld	s0,16(sp)
    80004c66:	64a2                	ld	s1,8(sp)
    80004c68:	6902                	ld	s2,0(sp)
    80004c6a:	6105                	addi	sp,sp,32
    80004c6c:	8082                	ret

0000000080004c6e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c6e:	1101                	addi	sp,sp,-32
    80004c70:	ec06                	sd	ra,24(sp)
    80004c72:	e822                	sd	s0,16(sp)
    80004c74:	e426                	sd	s1,8(sp)
    80004c76:	e04a                	sd	s2,0(sp)
    80004c78:	1000                	addi	s0,sp,32
    80004c7a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c7c:	00850913          	addi	s2,a0,8
    80004c80:	854a                	mv	a0,s2
    80004c82:	f7ffb0ef          	jal	80000c00 <acquire>
  lk->locked = 0;
    80004c86:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c8a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c8e:	8526                	mv	a0,s1
    80004c90:	ad4fd0ef          	jal	80001f64 <wakeup>
  release(&lk->lk);
    80004c94:	854a                	mv	a0,s2
    80004c96:	802fc0ef          	jal	80000c98 <release>
}
    80004c9a:	60e2                	ld	ra,24(sp)
    80004c9c:	6442                	ld	s0,16(sp)
    80004c9e:	64a2                	ld	s1,8(sp)
    80004ca0:	6902                	ld	s2,0(sp)
    80004ca2:	6105                	addi	sp,sp,32
    80004ca4:	8082                	ret

0000000080004ca6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ca6:	7179                	addi	sp,sp,-48
    80004ca8:	f406                	sd	ra,40(sp)
    80004caa:	f022                	sd	s0,32(sp)
    80004cac:	ec26                	sd	s1,24(sp)
    80004cae:	e84a                	sd	s2,16(sp)
    80004cb0:	1800                	addi	s0,sp,48
    80004cb2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004cb4:	00850913          	addi	s2,a0,8
    80004cb8:	854a                	mv	a0,s2
    80004cba:	f47fb0ef          	jal	80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cbe:	409c                	lw	a5,0(s1)
    80004cc0:	ef81                	bnez	a5,80004cd8 <holdingsleep+0x32>
    80004cc2:	4481                	li	s1,0
  release(&lk->lk);
    80004cc4:	854a                	mv	a0,s2
    80004cc6:	fd3fb0ef          	jal	80000c98 <release>
  return r;
}
    80004cca:	8526                	mv	a0,s1
    80004ccc:	70a2                	ld	ra,40(sp)
    80004cce:	7402                	ld	s0,32(sp)
    80004cd0:	64e2                	ld	s1,24(sp)
    80004cd2:	6942                	ld	s2,16(sp)
    80004cd4:	6145                	addi	sp,sp,48
    80004cd6:	8082                	ret
    80004cd8:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004cda:	0284a983          	lw	s3,40(s1)
    80004cde:	c2bfc0ef          	jal	80001908 <myproc>
    80004ce2:	5904                	lw	s1,48(a0)
    80004ce4:	413484b3          	sub	s1,s1,s3
    80004ce8:	0014b493          	seqz	s1,s1
    80004cec:	69a2                	ld	s3,8(sp)
    80004cee:	bfd9                	j	80004cc4 <holdingsleep+0x1e>

0000000080004cf0 <file_report>:
    char *op,
    struct file *f,
    int old_ref,
    int old_off,
    char *details
){
    80004cf0:	cb010113          	addi	sp,sp,-848
    80004cf4:	34113423          	sd	ra,840(sp)
    80004cf8:	34813023          	sd	s0,832(sp)
    80004cfc:	32913c23          	sd	s1,824(sp)
    80004d00:	33213823          	sd	s2,816(sp)
    80004d04:	33313423          	sd	s3,808(sp)
    80004d08:	33413023          	sd	s4,800(sp)
    80004d0c:	31513c23          	sd	s5,792(sp)
    80004d10:	0e80                	addi	s0,sp,848
    80004d12:	89aa                	mv	s3,a0
    80004d14:	84ae                	mv	s1,a1
    80004d16:	8a32                	mv	s4,a2
    80004d18:	8ab6                	mv	s5,a3
    80004d1a:	893a                	mv	s2,a4
    struct fs_event e;

    memset(&e, 0, sizeof(e));
    80004d1c:	31000613          	li	a2,784
    80004d20:	4581                	li	a1,0
    80004d22:	cb040513          	addi	a0,s0,-848
    80004d26:	faffb0ef          	jal	80000cd4 <memset>

    e.ticks = ticks;
    80004d2a:	00005797          	auipc	a5,0x5
    80004d2e:	38e7a783          	lw	a5,910(a5) # 8000a0b8 <ticks>
    80004d32:	caf42c23          	sw	a5,-840(s0)
    e.pid = myproc() ? myproc()->pid : 0;
    80004d36:	bd3fc0ef          	jal	80001908 <myproc>
    80004d3a:	4781                	li	a5,0
    80004d3c:	c501                	beqz	a0,80004d44 <file_report+0x54>
    80004d3e:	bcbfc0ef          	jal	80001908 <myproc>
    80004d42:	591c                	lw	a5,48(a0)
    80004d44:	caf42e23          	sw	a5,-836(s0)

    e.type = LAYER_FILE;
    80004d48:	479d                	li	a5,7
    80004d4a:	ccf42023          	sw	a5,-832(s0)

    safestrcpy(e.op_name, op, sizeof(e.op_name));
    80004d4e:	4641                	li	a2,16
    80004d50:	85ce                	mv	a1,s3
    80004d52:	cc440513          	addi	a0,s0,-828
    80004d56:	8bcfc0ef          	jal	80000e12 <safestrcpy>
    e.file_object_id = (uint64)f;
    80004d5a:	f2943823          	sd	s1,-208(s0)

    if(f){
    80004d5e:	c4b5                	beqz	s1,80004dca <file_report+0xda>
        e.file_type = f->type;
    80004d60:	409c                	lw	a5,0(s1)
    80004d62:	e6f42e23          	sw	a5,-388(s0)

        e.readable = f->readable;
    80004d66:	0084c703          	lbu	a4,8(s1)
    80004d6a:	e8e42823          	sw	a4,-368(s0)
        e.writable = f->writable;
    80004d6e:	0094c703          	lbu	a4,9(s1)
    80004d72:	e8e42a23          	sw	a4,-364(s0)

      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    80004d76:	4705                	li	a4,1
    80004d78:	08e78563          	beq	a5,a4,80004e02 <file_report+0x112>
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    80004d7c:	4709                	li	a4,2
    80004d7e:	08e78c63          	beq	a5,a4,80004e16 <file_report+0x126>
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    80004d82:	470d                	li	a4,3
    80004d84:	0ae78363          	beq	a5,a4,80004e2a <file_report+0x13a>
      else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));
    80004d88:	4641                	li	a2,16
    80004d8a:	00005597          	auipc	a1,0x5
    80004d8e:	ec658593          	addi	a1,a1,-314 # 80009c50 <etext+0xc50>
    80004d92:	e8040513          	addi	a0,s0,-384
    80004d96:	87cfc0ef          	jal	80000e12 <safestrcpy>

        e.file_ref = f->ref;
    80004d9a:	40dc                	lw	a5,4(s1)
    80004d9c:	e8f42c23          	sw	a5,-360(s0)
        e.old_file_ref = old_ref;
    80004da0:	e9442e23          	sw	s4,-356(s0)

        e.file_off = f->off;
    80004da4:	509c                	lw	a5,32(s1)
    80004da6:	eaf42023          	sw	a5,-352(s0)
        e.old_file_off = old_off;
    80004daa:	eb542223          	sw	s5,-348(s0)

        e.inum = f->ip ? f->ip->inum : -1;
    80004dae:	6c98                	ld	a4,24(s1)
    80004db0:	57fd                	li	a5,-1
    80004db2:	c311                	beqz	a4,80004db6 <file_report+0xc6>
    80004db4:	435c                	lw	a5,4(a4)
    80004db6:	d0f42623          	sw	a5,-756(s0)
        safestrcpy(e.path, f->path, MAXPATH);
    80004dba:	08000613          	li	a2,128
    80004dbe:	02648593          	addi	a1,s1,38
    80004dc2:	dd840513          	addi	a0,s0,-552
    80004dc6:	84cfc0ef          	jal	80000e12 <safestrcpy>
    }


    safestrcpy(e.details, details, sizeof(e.details));
    80004dca:	08000613          	li	a2,128
    80004dce:	85ca                	mv	a1,s2
    80004dd0:	f3c40513          	addi	a0,s0,-196
    80004dd4:	83efc0ef          	jal	80000e12 <safestrcpy>

    fslog_push(&e);}
    80004dd8:	cb040513          	addi	a0,s0,-848
    80004ddc:	080020ef          	jal	80006e5c <fslog_push>
    80004de0:	34813083          	ld	ra,840(sp)
    80004de4:	34013403          	ld	s0,832(sp)
    80004de8:	33813483          	ld	s1,824(sp)
    80004dec:	33013903          	ld	s2,816(sp)
    80004df0:	32813983          	ld	s3,808(sp)
    80004df4:	32013a03          	ld	s4,800(sp)
    80004df8:	31813a83          	ld	s5,792(sp)
    80004dfc:	35010113          	addi	sp,sp,848
    80004e00:	8082                	ret
      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    80004e02:	4641                	li	a2,16
    80004e04:	00005597          	auipc	a1,0x5
    80004e08:	e3458593          	addi	a1,a1,-460 # 80009c38 <etext+0xc38>
    80004e0c:	e8040513          	addi	a0,s0,-384
    80004e10:	802fc0ef          	jal	80000e12 <safestrcpy>
    80004e14:	b759                	j	80004d9a <file_report+0xaa>
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    80004e16:	4641                	li	a2,16
    80004e18:	00005597          	auipc	a1,0x5
    80004e1c:	e2858593          	addi	a1,a1,-472 # 80009c40 <etext+0xc40>
    80004e20:	e8040513          	addi	a0,s0,-384
    80004e24:	feffb0ef          	jal	80000e12 <safestrcpy>
    80004e28:	bf8d                	j	80004d9a <file_report+0xaa>
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    80004e2a:	4641                	li	a2,16
    80004e2c:	00005597          	auipc	a1,0x5
    80004e30:	e1c58593          	addi	a1,a1,-484 # 80009c48 <etext+0xc48>
    80004e34:	e8040513          	addi	a0,s0,-384
    80004e38:	fdbfb0ef          	jal	80000e12 <safestrcpy>
    80004e3c:	bfb9                	j	80004d9a <file_report+0xaa>

0000000080004e3e <fileinit>:

void
fileinit(void)
{
    80004e3e:	1141                	addi	sp,sp,-16
    80004e40:	e406                	sd	ra,8(sp)
    80004e42:	e022                	sd	s0,0(sp)
    80004e44:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e46:	00005597          	auipc	a1,0x5
    80004e4a:	e1258593          	addi	a1,a1,-494 # 80009c58 <etext+0xc58>
    80004e4e:	0001e517          	auipc	a0,0x1e
    80004e52:	cc250513          	addi	a0,a0,-830 # 80022b10 <ftable>
    80004e56:	d2bfb0ef          	jal	80000b80 <initlock>
}
    80004e5a:	60a2                	ld	ra,8(sp)
    80004e5c:	6402                	ld	s0,0(sp)
    80004e5e:	0141                	addi	sp,sp,16
    80004e60:	8082                	ret

0000000080004e62 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e62:	1101                	addi	sp,sp,-32
    80004e64:	ec06                	sd	ra,24(sp)
    80004e66:	e822                	sd	s0,16(sp)
    80004e68:	e426                	sd	s1,8(sp)
    80004e6a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e6c:	0001e517          	auipc	a0,0x1e
    80004e70:	ca450513          	addi	a0,a0,-860 # 80022b10 <ftable>
    80004e74:	d8dfb0ef          	jal	80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e78:	0001e497          	auipc	s1,0x1e
    80004e7c:	cb048493          	addi	s1,s1,-848 # 80022b28 <ftable+0x18>
    80004e80:	00022717          	auipc	a4,0x22
    80004e84:	e4870713          	addi	a4,a4,-440 # 80026cc8 <disk>
    if(f->ref == 0){
    80004e88:	40dc                	lw	a5,4(s1)
    80004e8a:	cf89                	beqz	a5,80004ea4 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e8c:	0a848493          	addi	s1,s1,168
    80004e90:	fee49ce3          	bne	s1,a4,80004e88 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e94:	0001e517          	auipc	a0,0x1e
    80004e98:	c7c50513          	addi	a0,a0,-900 # 80022b10 <ftable>
    80004e9c:	dfdfb0ef          	jal	80000c98 <release>
  return 0;
    80004ea0:	4481                	li	s1,0
    80004ea2:	a809                	j	80004eb4 <filealloc+0x52>
      f->ref = 1;
    80004ea4:	4785                	li	a5,1
    80004ea6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ea8:	0001e517          	auipc	a0,0x1e
    80004eac:	c6850513          	addi	a0,a0,-920 # 80022b10 <ftable>
    80004eb0:	de9fb0ef          	jal	80000c98 <release>
}
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	60e2                	ld	ra,24(sp)
    80004eb8:	6442                	ld	s0,16(sp)
    80004eba:	64a2                	ld	s1,8(sp)
    80004ebc:	6105                	addi	sp,sp,32
    80004ebe:	8082                	ret

0000000080004ec0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ec0:	1101                	addi	sp,sp,-32
    80004ec2:	ec06                	sd	ra,24(sp)
    80004ec4:	e822                	sd	s0,16(sp)
    80004ec6:	e426                	sd	s1,8(sp)
    80004ec8:	1000                	addi	s0,sp,32
    80004eca:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ecc:	0001e517          	auipc	a0,0x1e
    80004ed0:	c4450513          	addi	a0,a0,-956 # 80022b10 <ftable>
    80004ed4:	d2dfb0ef          	jal	80000c00 <acquire>
  if(f->ref < 1)
    80004ed8:	40d0                	lw	a2,4(s1)
    80004eda:	02c05d63          	blez	a2,80004f14 <filedup+0x54>
    panic("filedup");
  int old_ref = f->ref;
  f->ref++;
    80004ede:	0016079b          	addiw	a5,a2,1
    80004ee2:	c0dc                	sw	a5,4(s1)
  
  file_report(
    80004ee4:	00005717          	auipc	a4,0x5
    80004ee8:	d8470713          	addi	a4,a4,-636 # 80009c68 <etext+0xc68>
    80004eec:	5094                	lw	a3,32(s1)
    80004eee:	85a6                	mv	a1,s1
    80004ef0:	00005517          	auipc	a0,0x5
    80004ef4:	d9850513          	addi	a0,a0,-616 # 80009c88 <etext+0xc88>
    80004ef8:	df9ff0ef          	jal	80004cf0 <file_report>
    f,
    old_ref,
    f->off,
    "Duplicated file reference"
  );
  release(&ftable.lock);
    80004efc:	0001e517          	auipc	a0,0x1e
    80004f00:	c1450513          	addi	a0,a0,-1004 # 80022b10 <ftable>
    80004f04:	d95fb0ef          	jal	80000c98 <release>
  return f;
}
    80004f08:	8526                	mv	a0,s1
    80004f0a:	60e2                	ld	ra,24(sp)
    80004f0c:	6442                	ld	s0,16(sp)
    80004f0e:	64a2                	ld	s1,8(sp)
    80004f10:	6105                	addi	sp,sp,32
    80004f12:	8082                	ret
    panic("filedup");
    80004f14:	00005517          	auipc	a0,0x5
    80004f18:	d4c50513          	addi	a0,a0,-692 # 80009c60 <etext+0xc60>
    80004f1c:	8f7fb0ef          	jal	80000812 <panic>

0000000080004f20 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f20:	7139                	addi	sp,sp,-64
    80004f22:	fc06                	sd	ra,56(sp)
    80004f24:	f822                	sd	s0,48(sp)
    80004f26:	f426                	sd	s1,40(sp)
    80004f28:	0080                	addi	s0,sp,64
    80004f2a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004f2c:	0001e517          	auipc	a0,0x1e
    80004f30:	be450513          	addi	a0,a0,-1052 # 80022b10 <ftable>
    80004f34:	ccdfb0ef          	jal	80000c00 <acquire>
  if(f->ref < 1)
    80004f38:	40d0                	lw	a2,4(s1)
    80004f3a:	06c05863          	blez	a2,80004faa <fileclose+0x8a>
    panic("fileclose");
  int old_ref = f->ref;
  int old_off = f->off;
    80004f3e:	5094                	lw	a3,32(s1)
  
  
  if(--f->ref > 0){
    80004f40:	fff6079b          	addiw	a5,a2,-1
    80004f44:	0007871b          	sext.w	a4,a5
    80004f48:	c0dc                	sw	a5,4(s1)
    80004f4a:	06e04a63          	bgtz	a4,80004fbe <fileclose+0x9e>
    80004f4e:	f04a                	sd	s2,32(sp)
    80004f50:	ec4e                	sd	s3,24(sp)
    80004f52:	e852                	sd	s4,16(sp)
    80004f54:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  
  // في حال رغبنا بالتقرير عند الإغلاق النهائي والتصفير:
  file_report(
    80004f56:	00005717          	auipc	a4,0x5
    80004f5a:	d7270713          	addi	a4,a4,-654 # 80009cc8 <etext+0xcc8>
    80004f5e:	4605                	li	a2,1
    80004f60:	85a6                	mv	a1,s1
    80004f62:	00005517          	auipc	a0,0x5
    80004f66:	d8650513          	addi	a0,a0,-634 # 80009ce8 <etext+0xce8>
    80004f6a:	d87ff0ef          	jal	80004cf0 <file_report>
    old_ref,
    old_off,
    "File structure fully freed"
  );

  ff = *f;
    80004f6e:	0004a903          	lw	s2,0(s1)
    80004f72:	0094ca83          	lbu	s5,9(s1)
    80004f76:	0104ba03          	ld	s4,16(s1)
    80004f7a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f7e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f82:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f86:	0001e517          	auipc	a0,0x1e
    80004f8a:	b8a50513          	addi	a0,a0,-1142 # 80022b10 <ftable>
    80004f8e:	d0bfb0ef          	jal	80000c98 <release>

  if(ff.type == FD_PIPE){
    80004f92:	4785                	li	a5,1
    80004f94:	04f90b63          	beq	s2,a5,80004fea <fileclose+0xca>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f98:	3979                	addiw	s2,s2,-2
    80004f9a:	4785                	li	a5,1
    80004f9c:	0727f063          	bgeu	a5,s2,80004ffc <fileclose+0xdc>
    80004fa0:	7902                	ld	s2,32(sp)
    80004fa2:	69e2                	ld	s3,24(sp)
    80004fa4:	6a42                	ld	s4,16(sp)
    80004fa6:	6aa2                	ld	s5,8(sp)
    80004fa8:	a825                	j	80004fe0 <fileclose+0xc0>
    80004faa:	f04a                	sd	s2,32(sp)
    80004fac:	ec4e                	sd	s3,24(sp)
    80004fae:	e852                	sd	s4,16(sp)
    80004fb0:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80004fb2:	00005517          	auipc	a0,0x5
    80004fb6:	cde50513          	addi	a0,a0,-802 # 80009c90 <etext+0xc90>
    80004fba:	859fb0ef          	jal	80000812 <panic>
    file_report(
    80004fbe:	00005717          	auipc	a4,0x5
    80004fc2:	ce270713          	addi	a4,a4,-798 # 80009ca0 <etext+0xca0>
    80004fc6:	85a6                	mv	a1,s1
    80004fc8:	00005517          	auipc	a0,0x5
    80004fcc:	cf050513          	addi	a0,a0,-784 # 80009cb8 <etext+0xcb8>
    80004fd0:	d21ff0ef          	jal	80004cf0 <file_report>
    release(&ftable.lock);
    80004fd4:	0001e517          	auipc	a0,0x1e
    80004fd8:	b3c50513          	addi	a0,a0,-1220 # 80022b10 <ftable>
    80004fdc:	cbdfb0ef          	jal	80000c98 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80004fe0:	70e2                	ld	ra,56(sp)
    80004fe2:	7442                	ld	s0,48(sp)
    80004fe4:	74a2                	ld	s1,40(sp)
    80004fe6:	6121                	addi	sp,sp,64
    80004fe8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004fea:	85d6                	mv	a1,s5
    80004fec:	8552                	mv	a0,s4
    80004fee:	396000ef          	jal	80005384 <pipeclose>
    80004ff2:	7902                	ld	s2,32(sp)
    80004ff4:	69e2                	ld	s3,24(sp)
    80004ff6:	6a42                	ld	s4,16(sp)
    80004ff8:	6aa2                	ld	s5,8(sp)
    80004ffa:	b7dd                	j	80004fe0 <fileclose+0xc0>
    begin_op();
    80004ffc:	f9aff0ef          	jal	80004796 <begin_op>
    iput(ff.ip);
    80005000:	854e                	mv	a0,s3
    80005002:	af7fe0ef          	jal	80003af8 <iput>
    end_op();
    80005006:	8afff0ef          	jal	800048b4 <end_op>
    8000500a:	7902                	ld	s2,32(sp)
    8000500c:	69e2                	ld	s3,24(sp)
    8000500e:	6a42                	ld	s4,16(sp)
    80005010:	6aa2                	ld	s5,8(sp)
    80005012:	b7f9                	j	80004fe0 <fileclose+0xc0>

0000000080005014 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005014:	715d                	addi	sp,sp,-80
    80005016:	e486                	sd	ra,72(sp)
    80005018:	e0a2                	sd	s0,64(sp)
    8000501a:	fc26                	sd	s1,56(sp)
    8000501c:	f44e                	sd	s3,40(sp)
    8000501e:	0880                	addi	s0,sp,80
    80005020:	84aa                	mv	s1,a0
    80005022:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005024:	8e5fc0ef          	jal	80001908 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005028:	409c                	lw	a5,0(s1)
    8000502a:	37f9                	addiw	a5,a5,-2
    8000502c:	4705                	li	a4,1
    8000502e:	04f76063          	bltu	a4,a5,8000506e <filestat+0x5a>
    80005032:	f84a                	sd	s2,48(sp)
    80005034:	892a                	mv	s2,a0
    ilock(f->ip);
    80005036:	6c88                	ld	a0,24(s1)
    80005038:	8b1fe0ef          	jal	800038e8 <ilock>
    stati(f->ip, &st);
    8000503c:	fb840593          	addi	a1,s0,-72
    80005040:	6c88                	ld	a0,24(s1)
    80005042:	cdffe0ef          	jal	80003d20 <stati>
    iunlock(f->ip);
    80005046:	6c88                	ld	a0,24(s1)
    80005048:	993fe0ef          	jal	800039da <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000504c:	46e1                	li	a3,24
    8000504e:	fb840613          	addi	a2,s0,-72
    80005052:	85ce                	mv	a1,s3
    80005054:	05093503          	ld	a0,80(s2)
    80005058:	dc4fc0ef          	jal	8000161c <copyout>
    8000505c:	41f5551b          	sraiw	a0,a0,0x1f
    80005060:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80005062:	60a6                	ld	ra,72(sp)
    80005064:	6406                	ld	s0,64(sp)
    80005066:	74e2                	ld	s1,56(sp)
    80005068:	79a2                	ld	s3,40(sp)
    8000506a:	6161                	addi	sp,sp,80
    8000506c:	8082                	ret
  return -1;
    8000506e:	557d                	li	a0,-1
    80005070:	bfcd                	j	80005062 <filestat+0x4e>

0000000080005072 <fileread>:

// Read from file f.
// addr is a user virtual address.

int fileread(struct file *f, int fd, uint64 addr, int n)
{
    80005072:	7179                	addi	sp,sp,-48
    80005074:	f406                	sd	ra,40(sp)
    80005076:	f022                	sd	s0,32(sp)
    80005078:	e84a                	sd	s2,16(sp)
    8000507a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000507c:	00854783          	lbu	a5,8(a0)
    80005080:	c3f9                	beqz	a5,80005146 <fileread+0xd4>
    80005082:	ec26                	sd	s1,24(sp)
    80005084:	e44e                	sd	s3,8(sp)
    80005086:	84aa                	mv	s1,a0
    80005088:	89b2                	mv	s3,a2
    8000508a:	8936                	mv	s2,a3
    return -1;

  if(f->type == FD_PIPE){
    8000508c:	411c                	lw	a5,0(a0)
    8000508e:	4705                	li	a4,1
    80005090:	06e78463          	beq	a5,a4,800050f8 <fileread+0x86>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005094:	470d                	li	a4,3
    80005096:	06e78a63          	beq	a5,a4,8000510a <fileread+0x98>
    8000509a:	e052                	sd	s4,0(sp)
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000509c:	4709                	li	a4,2
    8000509e:	08e79e63          	bne	a5,a4,8000513a <fileread+0xc8>
    ilock(f->ip);
    800050a2:	6d08                	ld	a0,24(a0)
    800050a4:	845fe0ef          	jal	800038e8 <ilock>
    int old_off = f->off;
    800050a8:	5094                	lw	a3,32(s1)
    800050aa:	00068a1b          	sext.w	s4,a3

    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800050ae:	874a                	mv	a4,s2
    800050b0:	864e                	mv	a2,s3
    800050b2:	4585                	li	a1,1
    800050b4:	6c88                	ld	a0,24(s1)
    800050b6:	c95fe0ef          	jal	80003d4a <readi>
    800050ba:	892a                	mv	s2,a0
    800050bc:	00a05563          	blez	a0,800050c6 <fileread+0x54>
   
   { f->off += r;}
    800050c0:	509c                	lw	a5,32(s1)
    800050c2:	9fa9                	addw	a5,a5,a0
    800050c4:	d09c                	sw	a5,32(s1)
    file_report(
    800050c6:	00005717          	auipc	a4,0x5
    800050ca:	c3270713          	addi	a4,a4,-974 # 80009cf8 <etext+0xcf8>
    800050ce:	86d2                	mv	a3,s4
    800050d0:	40d0                	lw	a2,4(s1)
    800050d2:	85a6                	mv	a1,s1
    800050d4:	00005517          	auipc	a0,0x5
    800050d8:	c3450513          	addi	a0,a0,-972 # 80009d08 <etext+0xd08>
    800050dc:	c15ff0ef          	jal	80004cf0 <file_report>
    f,
    f->ref,
    old_off,
    "Read from file"
);
    iunlock(f->ip);
    800050e0:	6c88                	ld	a0,24(s1)
    800050e2:	8f9fe0ef          	jal	800039da <iunlock>
    800050e6:	64e2                	ld	s1,24(sp)
    800050e8:	69a2                	ld	s3,8(sp)
    800050ea:	6a02                	ld	s4,0(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800050ec:	854a                	mv	a0,s2
    800050ee:	70a2                	ld	ra,40(sp)
    800050f0:	7402                	ld	s0,32(sp)
    800050f2:	6942                	ld	s2,16(sp)
    800050f4:	6145                	addi	sp,sp,48
    800050f6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800050f8:	8636                	mv	a2,a3
    800050fa:	85ce                	mv	a1,s3
    800050fc:	6908                	ld	a0,16(a0)
    800050fe:	3c2000ef          	jal	800054c0 <piperead>
    80005102:	892a                	mv	s2,a0
    80005104:	64e2                	ld	s1,24(sp)
    80005106:	69a2                	ld	s3,8(sp)
    80005108:	b7d5                	j	800050ec <fileread+0x7a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000510a:	02451783          	lh	a5,36(a0)
    8000510e:	03079693          	slli	a3,a5,0x30
    80005112:	92c1                	srli	a3,a3,0x30
    80005114:	4725                	li	a4,9
    80005116:	02d76a63          	bltu	a4,a3,8000514a <fileread+0xd8>
    8000511a:	0792                	slli	a5,a5,0x4
    8000511c:	0001e717          	auipc	a4,0x1e
    80005120:	95470713          	addi	a4,a4,-1708 # 80022a70 <devsw>
    80005124:	97ba                	add	a5,a5,a4
    80005126:	639c                	ld	a5,0(a5)
    80005128:	c78d                	beqz	a5,80005152 <fileread+0xe0>
    r = devsw[f->major].read(1, addr, n);
    8000512a:	864a                	mv	a2,s2
    8000512c:	85ce                	mv	a1,s3
    8000512e:	4505                	li	a0,1
    80005130:	9782                	jalr	a5
    80005132:	892a                	mv	s2,a0
    80005134:	64e2                	ld	s1,24(sp)
    80005136:	69a2                	ld	s3,8(sp)
    80005138:	bf55                	j	800050ec <fileread+0x7a>
    panic("fileread");
    8000513a:	00005517          	auipc	a0,0x5
    8000513e:	bde50513          	addi	a0,a0,-1058 # 80009d18 <etext+0xd18>
    80005142:	ed0fb0ef          	jal	80000812 <panic>
    return -1;
    80005146:	597d                	li	s2,-1
    80005148:	b755                	j	800050ec <fileread+0x7a>
      return -1;
    8000514a:	597d                	li	s2,-1
    8000514c:	64e2                	ld	s1,24(sp)
    8000514e:	69a2                	ld	s3,8(sp)
    80005150:	bf71                	j	800050ec <fileread+0x7a>
    80005152:	597d                	li	s2,-1
    80005154:	64e2                	ld	s1,24(sp)
    80005156:	69a2                	ld	s3,8(sp)
    80005158:	bf51                	j	800050ec <fileread+0x7a>

000000008000515a <filewrite>:

int filewrite(struct file *f, int fd, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000515a:	00954783          	lbu	a5,9(a0)
    8000515e:	14078663          	beqz	a5,800052aa <filewrite+0x150>
{
    80005162:	7159                	addi	sp,sp,-112
    80005164:	f486                	sd	ra,104(sp)
    80005166:	f0a2                	sd	s0,96(sp)
    80005168:	eca6                	sd	s1,88(sp)
    8000516a:	e0d2                	sd	s4,64(sp)
    8000516c:	f45e                	sd	s7,40(sp)
    8000516e:	1880                	addi	s0,sp,112
    80005170:	84aa                	mv	s1,a0
    80005172:	8bb2                	mv	s7,a2
    80005174:	8a36                	mv	s4,a3
    return -1;

  if(f->type == FD_PIPE){
    80005176:	411c                	lw	a5,0(a0)
    80005178:	4705                	li	a4,1
    8000517a:	04e78263          	beq	a5,a4,800051be <filewrite+0x64>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000517e:	470d                	li	a4,3
    80005180:	04e78563          	beq	a5,a4,800051ca <filewrite+0x70>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005184:	4709                	li	a4,2
    80005186:	10e79463          	bne	a5,a4,8000528e <filewrite+0x134>
    8000518a:	e4ce                	sd	s3,72(sp)
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    int old_off;
    while(i < n){
    8000518c:	0cd05d63          	blez	a3,80005266 <filewrite+0x10c>
    80005190:	e8ca                	sd	s2,80(sp)
    80005192:	fc56                	sd	s5,56(sp)
    80005194:	f85a                	sd	s6,48(sp)
    80005196:	f062                	sd	s8,32(sp)
    80005198:	ec66                	sd	s9,24(sp)
    8000519a:	e86a                	sd	s10,16(sp)
    8000519c:	e46e                	sd	s11,8(sp)
    int i = 0;
    8000519e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800051a0:	6c05                	lui	s8,0x1
    800051a2:	c00c0c13          	addi	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800051a6:	6d85                	lui	s11,0x1
    800051a8:	c00d8d9b          	addiw	s11,s11,-1024 # c00 <_entry-0x7ffff400>
      begin_op();
      ilock(f->ip);
      old_off = f->off;
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
        f->off += r;
      file_report(
    800051ac:	00005d17          	auipc	s10,0x5
    800051b0:	b7cd0d13          	addi	s10,s10,-1156 # 80009d28 <etext+0xd28>
    800051b4:	00005c97          	auipc	s9,0x5
    800051b8:	b84c8c93          	addi	s9,s9,-1148 # 80009d38 <etext+0xd38>
    800051bc:	a069                	j	80005246 <filewrite+0xec>
    ret = pipewrite(f->pipe, addr, n);
    800051be:	8636                	mv	a2,a3
    800051c0:	85de                	mv	a1,s7
    800051c2:	6908                	ld	a0,16(a0)
    800051c4:	218000ef          	jal	800053dc <pipewrite>
    800051c8:	a865                	j	80005280 <filewrite+0x126>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051ca:	02451783          	lh	a5,36(a0)
    800051ce:	03079693          	slli	a3,a5,0x30
    800051d2:	92c1                	srli	a3,a3,0x30
    800051d4:	4725                	li	a4,9
    800051d6:	0cd76c63          	bltu	a4,a3,800052ae <filewrite+0x154>
    800051da:	0792                	slli	a5,a5,0x4
    800051dc:	0001e717          	auipc	a4,0x1e
    800051e0:	89470713          	addi	a4,a4,-1900 # 80022a70 <devsw>
    800051e4:	97ba                	add	a5,a5,a4
    800051e6:	679c                	ld	a5,8(a5)
    800051e8:	c7e9                	beqz	a5,800052b2 <filewrite+0x158>
    ret = devsw[f->major].write(1, addr, n);
    800051ea:	8652                	mv	a2,s4
    800051ec:	85de                	mv	a1,s7
    800051ee:	4505                	li	a0,1
    800051f0:	9782                	jalr	a5
    800051f2:	a079                	j	80005280 <filewrite+0x126>
      if(n1 > max)
    800051f4:	00090a9b          	sext.w	s5,s2
      begin_op();
    800051f8:	d9eff0ef          	jal	80004796 <begin_op>
      ilock(f->ip);
    800051fc:	6c88                	ld	a0,24(s1)
    800051fe:	eeafe0ef          	jal	800038e8 <ilock>
      old_off = f->off;
    80005202:	5094                	lw	a3,32(s1)
    80005204:	00068b1b          	sext.w	s6,a3
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005208:	8756                	mv	a4,s5
    8000520a:	01798633          	add	a2,s3,s7
    8000520e:	4585                	li	a1,1
    80005210:	6c88                	ld	a0,24(s1)
    80005212:	c69fe0ef          	jal	80003e7a <writei>
    80005216:	892a                	mv	s2,a0
    80005218:	00a05563          	blez	a0,80005222 <filewrite+0xc8>
        f->off += r;
    8000521c:	509c                	lw	a5,32(s1)
    8000521e:	9fa9                	addw	a5,a5,a0
    80005220:	d09c                	sw	a5,32(s1)
      file_report(
    80005222:	876a                	mv	a4,s10
    80005224:	86da                	mv	a3,s6
    80005226:	40d0                	lw	a2,4(s1)
    80005228:	85a6                	mv	a1,s1
    8000522a:	8566                	mv	a0,s9
    8000522c:	ac5ff0ef          	jal	80004cf0 <file_report>
    f,
    f->ref,
    old_off,
    "Write to file"
);
      iunlock(f->ip);
    80005230:	6c88                	ld	a0,24(s1)
    80005232:	fa8fe0ef          	jal	800039da <iunlock>
      end_op();
    80005236:	e7eff0ef          	jal	800048b4 <end_op>

      if(r != n1){
    8000523a:	032a9863          	bne	s5,s2,8000526a <filewrite+0x110>
        // error from writei
        break;
      }
      i += r;
    8000523e:	013909bb          	addw	s3,s2,s3
    while(i < n){
    80005242:	0149da63          	bge	s3,s4,80005256 <filewrite+0xfc>
      int n1 = n - i;
    80005246:	413a093b          	subw	s2,s4,s3
      if(n1 > max)
    8000524a:	0009079b          	sext.w	a5,s2
    8000524e:	fafc53e3          	bge	s8,a5,800051f4 <filewrite+0x9a>
    80005252:	896e                	mv	s2,s11
    80005254:	b745                	j	800051f4 <filewrite+0x9a>
    80005256:	6946                	ld	s2,80(sp)
    80005258:	7ae2                	ld	s5,56(sp)
    8000525a:	7b42                	ld	s6,48(sp)
    8000525c:	7c02                	ld	s8,32(sp)
    8000525e:	6ce2                	ld	s9,24(sp)
    80005260:	6d42                	ld	s10,16(sp)
    80005262:	6da2                	ld	s11,8(sp)
    80005264:	a811                	j	80005278 <filewrite+0x11e>
    int i = 0;
    80005266:	4981                	li	s3,0
    80005268:	a801                	j	80005278 <filewrite+0x11e>
    8000526a:	6946                	ld	s2,80(sp)
    8000526c:	7ae2                	ld	s5,56(sp)
    8000526e:	7b42                	ld	s6,48(sp)
    80005270:	7c02                	ld	s8,32(sp)
    80005272:	6ce2                	ld	s9,24(sp)
    80005274:	6d42                	ld	s10,16(sp)
    80005276:	6da2                	ld	s11,8(sp)
    }
    ret = (i == n ? n : -1);
    80005278:	033a1f63          	bne	s4,s3,800052b6 <filewrite+0x15c>
    8000527c:	8552                	mv	a0,s4
    8000527e:	69a6                	ld	s3,72(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005280:	70a6                	ld	ra,104(sp)
    80005282:	7406                	ld	s0,96(sp)
    80005284:	64e6                	ld	s1,88(sp)
    80005286:	6a06                	ld	s4,64(sp)
    80005288:	7ba2                	ld	s7,40(sp)
    8000528a:	6165                	addi	sp,sp,112
    8000528c:	8082                	ret
    8000528e:	e8ca                	sd	s2,80(sp)
    80005290:	e4ce                	sd	s3,72(sp)
    80005292:	fc56                	sd	s5,56(sp)
    80005294:	f85a                	sd	s6,48(sp)
    80005296:	f062                	sd	s8,32(sp)
    80005298:	ec66                	sd	s9,24(sp)
    8000529a:	e86a                	sd	s10,16(sp)
    8000529c:	e46e                	sd	s11,8(sp)
    panic("filewrite");
    8000529e:	00005517          	auipc	a0,0x5
    800052a2:	aaa50513          	addi	a0,a0,-1366 # 80009d48 <etext+0xd48>
    800052a6:	d6cfb0ef          	jal	80000812 <panic>
    return -1;
    800052aa:	557d                	li	a0,-1
}
    800052ac:	8082                	ret
      return -1;
    800052ae:	557d                	li	a0,-1
    800052b0:	bfc1                	j	80005280 <filewrite+0x126>
    800052b2:	557d                	li	a0,-1
    800052b4:	b7f1                	j	80005280 <filewrite+0x126>
    ret = (i == n ? n : -1);
    800052b6:	557d                	li	a0,-1
    800052b8:	69a6                	ld	s3,72(sp)
    800052ba:	b7d9                	j	80005280 <filewrite+0x126>

00000000800052bc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800052bc:	7179                	addi	sp,sp,-48
    800052be:	f406                	sd	ra,40(sp)
    800052c0:	f022                	sd	s0,32(sp)
    800052c2:	ec26                	sd	s1,24(sp)
    800052c4:	e052                	sd	s4,0(sp)
    800052c6:	1800                	addi	s0,sp,48
    800052c8:	84aa                	mv	s1,a0
    800052ca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800052cc:	0005b023          	sd	zero,0(a1)
    800052d0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800052d4:	b8fff0ef          	jal	80004e62 <filealloc>
    800052d8:	e088                	sd	a0,0(s1)
    800052da:	c549                	beqz	a0,80005364 <pipealloc+0xa8>
    800052dc:	b87ff0ef          	jal	80004e62 <filealloc>
    800052e0:	00aa3023          	sd	a0,0(s4)
    800052e4:	cd25                	beqz	a0,8000535c <pipealloc+0xa0>
    800052e6:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800052e8:	849fb0ef          	jal	80000b30 <kalloc>
    800052ec:	892a                	mv	s2,a0
    800052ee:	c12d                	beqz	a0,80005350 <pipealloc+0x94>
    800052f0:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800052f2:	4985                	li	s3,1
    800052f4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800052f8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800052fc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005300:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005304:	00005597          	auipc	a1,0x5
    80005308:	a5458593          	addi	a1,a1,-1452 # 80009d58 <etext+0xd58>
    8000530c:	875fb0ef          	jal	80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80005310:	609c                	ld	a5,0(s1)
    80005312:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005316:	609c                	ld	a5,0(s1)
    80005318:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000531c:	609c                	ld	a5,0(s1)
    8000531e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005322:	609c                	ld	a5,0(s1)
    80005324:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005328:	000a3783          	ld	a5,0(s4)
    8000532c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005330:	000a3783          	ld	a5,0(s4)
    80005334:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005338:	000a3783          	ld	a5,0(s4)
    8000533c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005340:	000a3783          	ld	a5,0(s4)
    80005344:	0127b823          	sd	s2,16(a5)
  return 0;
    80005348:	4501                	li	a0,0
    8000534a:	6942                	ld	s2,16(sp)
    8000534c:	69a2                	ld	s3,8(sp)
    8000534e:	a01d                	j	80005374 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005350:	6088                	ld	a0,0(s1)
    80005352:	c119                	beqz	a0,80005358 <pipealloc+0x9c>
    80005354:	6942                	ld	s2,16(sp)
    80005356:	a029                	j	80005360 <pipealloc+0xa4>
    80005358:	6942                	ld	s2,16(sp)
    8000535a:	a029                	j	80005364 <pipealloc+0xa8>
    8000535c:	6088                	ld	a0,0(s1)
    8000535e:	c10d                	beqz	a0,80005380 <pipealloc+0xc4>
    fileclose(*f0);
    80005360:	bc1ff0ef          	jal	80004f20 <fileclose>
  if(*f1)
    80005364:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005368:	557d                	li	a0,-1
  if(*f1)
    8000536a:	c789                	beqz	a5,80005374 <pipealloc+0xb8>
    fileclose(*f1);
    8000536c:	853e                	mv	a0,a5
    8000536e:	bb3ff0ef          	jal	80004f20 <fileclose>
  return -1;
    80005372:	557d                	li	a0,-1
}
    80005374:	70a2                	ld	ra,40(sp)
    80005376:	7402                	ld	s0,32(sp)
    80005378:	64e2                	ld	s1,24(sp)
    8000537a:	6a02                	ld	s4,0(sp)
    8000537c:	6145                	addi	sp,sp,48
    8000537e:	8082                	ret
  return -1;
    80005380:	557d                	li	a0,-1
    80005382:	bfcd                	j	80005374 <pipealloc+0xb8>

0000000080005384 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005384:	1101                	addi	sp,sp,-32
    80005386:	ec06                	sd	ra,24(sp)
    80005388:	e822                	sd	s0,16(sp)
    8000538a:	e426                	sd	s1,8(sp)
    8000538c:	e04a                	sd	s2,0(sp)
    8000538e:	1000                	addi	s0,sp,32
    80005390:	84aa                	mv	s1,a0
    80005392:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005394:	86dfb0ef          	jal	80000c00 <acquire>
  if(writable){
    80005398:	02090763          	beqz	s2,800053c6 <pipeclose+0x42>
    pi->writeopen = 0;
    8000539c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800053a0:	21848513          	addi	a0,s1,536
    800053a4:	bc1fc0ef          	jal	80001f64 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800053a8:	2204b783          	ld	a5,544(s1)
    800053ac:	e785                	bnez	a5,800053d4 <pipeclose+0x50>
    release(&pi->lock);
    800053ae:	8526                	mv	a0,s1
    800053b0:	8e9fb0ef          	jal	80000c98 <release>
    kfree((char*)pi);
    800053b4:	8526                	mv	a0,s1
    800053b6:	e98fb0ef          	jal	80000a4e <kfree>
  } else
    release(&pi->lock);
}
    800053ba:	60e2                	ld	ra,24(sp)
    800053bc:	6442                	ld	s0,16(sp)
    800053be:	64a2                	ld	s1,8(sp)
    800053c0:	6902                	ld	s2,0(sp)
    800053c2:	6105                	addi	sp,sp,32
    800053c4:	8082                	ret
    pi->readopen = 0;
    800053c6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800053ca:	21c48513          	addi	a0,s1,540
    800053ce:	b97fc0ef          	jal	80001f64 <wakeup>
    800053d2:	bfd9                	j	800053a8 <pipeclose+0x24>
    release(&pi->lock);
    800053d4:	8526                	mv	a0,s1
    800053d6:	8c3fb0ef          	jal	80000c98 <release>
}
    800053da:	b7c5                	j	800053ba <pipeclose+0x36>

00000000800053dc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800053dc:	711d                	addi	sp,sp,-96
    800053de:	ec86                	sd	ra,88(sp)
    800053e0:	e8a2                	sd	s0,80(sp)
    800053e2:	e4a6                	sd	s1,72(sp)
    800053e4:	e0ca                	sd	s2,64(sp)
    800053e6:	fc4e                	sd	s3,56(sp)
    800053e8:	f852                	sd	s4,48(sp)
    800053ea:	f456                	sd	s5,40(sp)
    800053ec:	1080                	addi	s0,sp,96
    800053ee:	84aa                	mv	s1,a0
    800053f0:	8aae                	mv	s5,a1
    800053f2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800053f4:	d14fc0ef          	jal	80001908 <myproc>
    800053f8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800053fa:	8526                	mv	a0,s1
    800053fc:	805fb0ef          	jal	80000c00 <acquire>
  while(i < n){
    80005400:	0b405a63          	blez	s4,800054b4 <pipewrite+0xd8>
    80005404:	f05a                	sd	s6,32(sp)
    80005406:	ec5e                	sd	s7,24(sp)
    80005408:	e862                	sd	s8,16(sp)
  int i = 0;
    8000540a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000540c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000540e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005412:	21c48b93          	addi	s7,s1,540
    80005416:	a81d                	j	8000544c <pipewrite+0x70>
      release(&pi->lock);
    80005418:	8526                	mv	a0,s1
    8000541a:	87ffb0ef          	jal	80000c98 <release>
      return -1;
    8000541e:	597d                	li	s2,-1
    80005420:	7b02                	ld	s6,32(sp)
    80005422:	6be2                	ld	s7,24(sp)
    80005424:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005426:	854a                	mv	a0,s2
    80005428:	60e6                	ld	ra,88(sp)
    8000542a:	6446                	ld	s0,80(sp)
    8000542c:	64a6                	ld	s1,72(sp)
    8000542e:	6906                	ld	s2,64(sp)
    80005430:	79e2                	ld	s3,56(sp)
    80005432:	7a42                	ld	s4,48(sp)
    80005434:	7aa2                	ld	s5,40(sp)
    80005436:	6125                	addi	sp,sp,96
    80005438:	8082                	ret
      wakeup(&pi->nread);
    8000543a:	8562                	mv	a0,s8
    8000543c:	b29fc0ef          	jal	80001f64 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005440:	85a6                	mv	a1,s1
    80005442:	855e                	mv	a0,s7
    80005444:	ad5fc0ef          	jal	80001f18 <sleep>
  while(i < n){
    80005448:	05495b63          	bge	s2,s4,8000549e <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    8000544c:	2204a783          	lw	a5,544(s1)
    80005450:	d7e1                	beqz	a5,80005418 <pipewrite+0x3c>
    80005452:	854e                	mv	a0,s3
    80005454:	cfdfc0ef          	jal	80002150 <killed>
    80005458:	f161                	bnez	a0,80005418 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000545a:	2184a783          	lw	a5,536(s1)
    8000545e:	21c4a703          	lw	a4,540(s1)
    80005462:	2007879b          	addiw	a5,a5,512
    80005466:	fcf70ae3          	beq	a4,a5,8000543a <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000546a:	4685                	li	a3,1
    8000546c:	01590633          	add	a2,s2,s5
    80005470:	faf40593          	addi	a1,s0,-81
    80005474:	0509b503          	ld	a0,80(s3)
    80005478:	a88fc0ef          	jal	80001700 <copyin>
    8000547c:	03650e63          	beq	a0,s6,800054b8 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005480:	21c4a783          	lw	a5,540(s1)
    80005484:	0017871b          	addiw	a4,a5,1
    80005488:	20e4ae23          	sw	a4,540(s1)
    8000548c:	1ff7f793          	andi	a5,a5,511
    80005490:	97a6                	add	a5,a5,s1
    80005492:	faf44703          	lbu	a4,-81(s0)
    80005496:	00e78c23          	sb	a4,24(a5)
      i++;
    8000549a:	2905                	addiw	s2,s2,1
    8000549c:	b775                	j	80005448 <pipewrite+0x6c>
    8000549e:	7b02                	ld	s6,32(sp)
    800054a0:	6be2                	ld	s7,24(sp)
    800054a2:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    800054a4:	21848513          	addi	a0,s1,536
    800054a8:	abdfc0ef          	jal	80001f64 <wakeup>
  release(&pi->lock);
    800054ac:	8526                	mv	a0,s1
    800054ae:	feafb0ef          	jal	80000c98 <release>
  return i;
    800054b2:	bf95                	j	80005426 <pipewrite+0x4a>
  int i = 0;
    800054b4:	4901                	li	s2,0
    800054b6:	b7fd                	j	800054a4 <pipewrite+0xc8>
    800054b8:	7b02                	ld	s6,32(sp)
    800054ba:	6be2                	ld	s7,24(sp)
    800054bc:	6c42                	ld	s8,16(sp)
    800054be:	b7dd                	j	800054a4 <pipewrite+0xc8>

00000000800054c0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800054c0:	715d                	addi	sp,sp,-80
    800054c2:	e486                	sd	ra,72(sp)
    800054c4:	e0a2                	sd	s0,64(sp)
    800054c6:	fc26                	sd	s1,56(sp)
    800054c8:	f84a                	sd	s2,48(sp)
    800054ca:	f44e                	sd	s3,40(sp)
    800054cc:	f052                	sd	s4,32(sp)
    800054ce:	ec56                	sd	s5,24(sp)
    800054d0:	0880                	addi	s0,sp,80
    800054d2:	84aa                	mv	s1,a0
    800054d4:	892e                	mv	s2,a1
    800054d6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800054d8:	c30fc0ef          	jal	80001908 <myproc>
    800054dc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800054de:	8526                	mv	a0,s1
    800054e0:	f20fb0ef          	jal	80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054e4:	2184a703          	lw	a4,536(s1)
    800054e8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054ec:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054f0:	02f71563          	bne	a4,a5,8000551a <piperead+0x5a>
    800054f4:	2244a783          	lw	a5,548(s1)
    800054f8:	cb85                	beqz	a5,80005528 <piperead+0x68>
    if(killed(pr)){
    800054fa:	8552                	mv	a0,s4
    800054fc:	c55fc0ef          	jal	80002150 <killed>
    80005500:	ed19                	bnez	a0,8000551e <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005502:	85a6                	mv	a1,s1
    80005504:	854e                	mv	a0,s3
    80005506:	a13fc0ef          	jal	80001f18 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000550a:	2184a703          	lw	a4,536(s1)
    8000550e:	21c4a783          	lw	a5,540(s1)
    80005512:	fef701e3          	beq	a4,a5,800054f4 <piperead+0x34>
    80005516:	e85a                	sd	s6,16(sp)
    80005518:	a809                	j	8000552a <piperead+0x6a>
    8000551a:	e85a                	sd	s6,16(sp)
    8000551c:	a039                	j	8000552a <piperead+0x6a>
      release(&pi->lock);
    8000551e:	8526                	mv	a0,s1
    80005520:	f78fb0ef          	jal	80000c98 <release>
      return -1;
    80005524:	59fd                	li	s3,-1
    80005526:	a8b9                	j	80005584 <piperead+0xc4>
    80005528:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000552a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000552c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000552e:	05505363          	blez	s5,80005574 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005532:	2184a783          	lw	a5,536(s1)
    80005536:	21c4a703          	lw	a4,540(s1)
    8000553a:	02f70d63          	beq	a4,a5,80005574 <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    8000553e:	1ff7f793          	andi	a5,a5,511
    80005542:	97a6                	add	a5,a5,s1
    80005544:	0187c783          	lbu	a5,24(a5)
    80005548:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000554c:	4685                	li	a3,1
    8000554e:	fbf40613          	addi	a2,s0,-65
    80005552:	85ca                	mv	a1,s2
    80005554:	050a3503          	ld	a0,80(s4)
    80005558:	8c4fc0ef          	jal	8000161c <copyout>
    8000555c:	03650e63          	beq	a0,s6,80005598 <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80005560:	2184a783          	lw	a5,536(s1)
    80005564:	2785                	addiw	a5,a5,1
    80005566:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000556a:	2985                	addiw	s3,s3,1
    8000556c:	0905                	addi	s2,s2,1
    8000556e:	fd3a92e3          	bne	s5,s3,80005532 <piperead+0x72>
    80005572:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005574:	21c48513          	addi	a0,s1,540
    80005578:	9edfc0ef          	jal	80001f64 <wakeup>
  release(&pi->lock);
    8000557c:	8526                	mv	a0,s1
    8000557e:	f1afb0ef          	jal	80000c98 <release>
    80005582:	6b42                	ld	s6,16(sp)
  return i;
}
    80005584:	854e                	mv	a0,s3
    80005586:	60a6                	ld	ra,72(sp)
    80005588:	6406                	ld	s0,64(sp)
    8000558a:	74e2                	ld	s1,56(sp)
    8000558c:	7942                	ld	s2,48(sp)
    8000558e:	79a2                	ld	s3,40(sp)
    80005590:	7a02                	ld	s4,32(sp)
    80005592:	6ae2                	ld	s5,24(sp)
    80005594:	6161                	addi	sp,sp,80
    80005596:	8082                	ret
      if(i == 0)
    80005598:	fc099ee3          	bnez	s3,80005574 <piperead+0xb4>
        i = -1;
    8000559c:	89aa                	mv	s3,a0
    8000559e:	bfd9                	j	80005574 <piperead+0xb4>

00000000800055a0 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    800055a0:	1141                	addi	sp,sp,-16
    800055a2:	e422                	sd	s0,8(sp)
    800055a4:	0800                	addi	s0,sp,16
    800055a6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800055a8:	8905                	andi	a0,a0,1
    800055aa:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800055ac:	8b89                	andi	a5,a5,2
    800055ae:	c399                	beqz	a5,800055b4 <flags2perm+0x14>
      perm |= PTE_W;
    800055b0:	00456513          	ori	a0,a0,4
    return perm;
}
    800055b4:	6422                	ld	s0,8(sp)
    800055b6:	0141                	addi	sp,sp,16
    800055b8:	8082                	ret

00000000800055ba <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    800055ba:	df010113          	addi	sp,sp,-528
    800055be:	20113423          	sd	ra,520(sp)
    800055c2:	20813023          	sd	s0,512(sp)
    800055c6:	ffa6                	sd	s1,504(sp)
    800055c8:	fbca                	sd	s2,496(sp)
    800055ca:	0c00                	addi	s0,sp,528
    800055cc:	892a                	mv	s2,a0
    800055ce:	dea43c23          	sd	a0,-520(s0)
    800055d2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800055d6:	b32fc0ef          	jal	80001908 <myproc>
    800055da:	84aa                	mv	s1,a0

  begin_op();
    800055dc:	9baff0ef          	jal	80004796 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800055e0:	854a                	mv	a0,s2
    800055e2:	d6bfe0ef          	jal	8000434c <namei>
    800055e6:	c931                	beqz	a0,8000563a <kexec+0x80>
    800055e8:	f3d2                	sd	s4,480(sp)
    800055ea:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800055ec:	afcfe0ef          	jal	800038e8 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800055f0:	04000713          	li	a4,64
    800055f4:	4681                	li	a3,0
    800055f6:	e5040613          	addi	a2,s0,-432
    800055fa:	4581                	li	a1,0
    800055fc:	8552                	mv	a0,s4
    800055fe:	f4cfe0ef          	jal	80003d4a <readi>
    80005602:	04000793          	li	a5,64
    80005606:	00f51a63          	bne	a0,a5,8000561a <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    8000560a:	e5042703          	lw	a4,-432(s0)
    8000560e:	464c47b7          	lui	a5,0x464c4
    80005612:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005616:	02f70663          	beq	a4,a5,80005642 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000561a:	8552                	mv	a0,s4
    8000561c:	da8fe0ef          	jal	80003bc4 <iunlockput>
    end_op();
    80005620:	a94ff0ef          	jal	800048b4 <end_op>
  }
  return -1;
    80005624:	557d                	li	a0,-1
    80005626:	7a1e                	ld	s4,480(sp)
}
    80005628:	20813083          	ld	ra,520(sp)
    8000562c:	20013403          	ld	s0,512(sp)
    80005630:	74fe                	ld	s1,504(sp)
    80005632:	795e                	ld	s2,496(sp)
    80005634:	21010113          	addi	sp,sp,528
    80005638:	8082                	ret
    end_op();
    8000563a:	a7aff0ef          	jal	800048b4 <end_op>
    return -1;
    8000563e:	557d                	li	a0,-1
    80005640:	b7e5                	j	80005628 <kexec+0x6e>
    80005642:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80005644:	8526                	mv	a0,s1
    80005646:	bc8fc0ef          	jal	80001a0e <proc_pagetable>
    8000564a:	8b2a                	mv	s6,a0
    8000564c:	2c050b63          	beqz	a0,80005922 <kexec+0x368>
    80005650:	f7ce                	sd	s3,488(sp)
    80005652:	efd6                	sd	s5,472(sp)
    80005654:	e7de                	sd	s7,456(sp)
    80005656:	e3e2                	sd	s8,448(sp)
    80005658:	ff66                	sd	s9,440(sp)
    8000565a:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000565c:	e7042d03          	lw	s10,-400(s0)
    80005660:	e8845783          	lhu	a5,-376(s0)
    80005664:	12078963          	beqz	a5,80005796 <kexec+0x1dc>
    80005668:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000566a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000566c:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    8000566e:	6c85                	lui	s9,0x1
    80005670:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005674:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80005678:	6a85                	lui	s5,0x1
    8000567a:	a085                	j	800056da <kexec+0x120>
      panic("loadseg: address should exist");
    8000567c:	00004517          	auipc	a0,0x4
    80005680:	6e450513          	addi	a0,a0,1764 # 80009d60 <etext+0xd60>
    80005684:	98efb0ef          	jal	80000812 <panic>
    if(sz - i < PGSIZE)
    80005688:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000568a:	8726                	mv	a4,s1
    8000568c:	012c06bb          	addw	a3,s8,s2
    80005690:	4581                	li	a1,0
    80005692:	8552                	mv	a0,s4
    80005694:	eb6fe0ef          	jal	80003d4a <readi>
    80005698:	2501                	sext.w	a0,a0
    8000569a:	24a49a63          	bne	s1,a0,800058ee <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    8000569e:	012a893b          	addw	s2,s5,s2
    800056a2:	03397363          	bgeu	s2,s3,800056c8 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    800056a6:	02091593          	slli	a1,s2,0x20
    800056aa:	9181                	srli	a1,a1,0x20
    800056ac:	95de                	add	a1,a1,s7
    800056ae:	855a                	mv	a0,s6
    800056b0:	93bfb0ef          	jal	80000fea <walkaddr>
    800056b4:	862a                	mv	a2,a0
    if(pa == 0)
    800056b6:	d179                	beqz	a0,8000567c <kexec+0xc2>
    if(sz - i < PGSIZE)
    800056b8:	412984bb          	subw	s1,s3,s2
    800056bc:	0004879b          	sext.w	a5,s1
    800056c0:	fcfcf4e3          	bgeu	s9,a5,80005688 <kexec+0xce>
    800056c4:	84d6                	mv	s1,s5
    800056c6:	b7c9                	j	80005688 <kexec+0xce>
    sz = sz1;
    800056c8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056cc:	2d85                	addiw	s11,s11,1
    800056ce:	038d0d1b          	addiw	s10,s10,56
    800056d2:	e8845783          	lhu	a5,-376(s0)
    800056d6:	08fdd063          	bge	s11,a5,80005756 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056da:	2d01                	sext.w	s10,s10
    800056dc:	03800713          	li	a4,56
    800056e0:	86ea                	mv	a3,s10
    800056e2:	e1840613          	addi	a2,s0,-488
    800056e6:	4581                	li	a1,0
    800056e8:	8552                	mv	a0,s4
    800056ea:	e60fe0ef          	jal	80003d4a <readi>
    800056ee:	03800793          	li	a5,56
    800056f2:	1cf51663          	bne	a0,a5,800058be <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    800056f6:	e1842783          	lw	a5,-488(s0)
    800056fa:	4705                	li	a4,1
    800056fc:	fce798e3          	bne	a5,a4,800056cc <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80005700:	e4043483          	ld	s1,-448(s0)
    80005704:	e3843783          	ld	a5,-456(s0)
    80005708:	1af4ef63          	bltu	s1,a5,800058c6 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000570c:	e2843783          	ld	a5,-472(s0)
    80005710:	94be                	add	s1,s1,a5
    80005712:	1af4ee63          	bltu	s1,a5,800058ce <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80005716:	df043703          	ld	a4,-528(s0)
    8000571a:	8ff9                	and	a5,a5,a4
    8000571c:	1a079d63          	bnez	a5,800058d6 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005720:	e1c42503          	lw	a0,-484(s0)
    80005724:	e7dff0ef          	jal	800055a0 <flags2perm>
    80005728:	86aa                	mv	a3,a0
    8000572a:	8626                	mv	a2,s1
    8000572c:	85ca                	mv	a1,s2
    8000572e:	855a                	mv	a0,s6
    80005730:	b93fb0ef          	jal	800012c2 <uvmalloc>
    80005734:	e0a43423          	sd	a0,-504(s0)
    80005738:	1a050363          	beqz	a0,800058de <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000573c:	e2843b83          	ld	s7,-472(s0)
    80005740:	e2042c03          	lw	s8,-480(s0)
    80005744:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005748:	00098463          	beqz	s3,80005750 <kexec+0x196>
    8000574c:	4901                	li	s2,0
    8000574e:	bfa1                	j	800056a6 <kexec+0xec>
    sz = sz1;
    80005750:	e0843903          	ld	s2,-504(s0)
    80005754:	bfa5                	j	800056cc <kexec+0x112>
    80005756:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80005758:	8552                	mv	a0,s4
    8000575a:	c6afe0ef          	jal	80003bc4 <iunlockput>
  end_op();
    8000575e:	956ff0ef          	jal	800048b4 <end_op>
  p = myproc();
    80005762:	9a6fc0ef          	jal	80001908 <myproc>
    80005766:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005768:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    8000576c:	6985                	lui	s3,0x1
    8000576e:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005770:	99ca                	add	s3,s3,s2
    80005772:	77fd                	lui	a5,0xfffff
    80005774:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80005778:	4691                	li	a3,4
    8000577a:	6609                	lui	a2,0x2
    8000577c:	964e                	add	a2,a2,s3
    8000577e:	85ce                	mv	a1,s3
    80005780:	855a                	mv	a0,s6
    80005782:	b41fb0ef          	jal	800012c2 <uvmalloc>
    80005786:	892a                	mv	s2,a0
    80005788:	e0a43423          	sd	a0,-504(s0)
    8000578c:	e519                	bnez	a0,8000579a <kexec+0x1e0>
  if(pagetable)
    8000578e:	e1343423          	sd	s3,-504(s0)
    80005792:	4a01                	li	s4,0
    80005794:	aab1                	j	800058f0 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005796:	4901                	li	s2,0
    80005798:	b7c1                	j	80005758 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    8000579a:	75f9                	lui	a1,0xffffe
    8000579c:	95aa                	add	a1,a1,a0
    8000579e:	855a                	mv	a0,s6
    800057a0:	cf9fb0ef          	jal	80001498 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800057a4:	7bfd                	lui	s7,0xfffff
    800057a6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800057a8:	e0043783          	ld	a5,-512(s0)
    800057ac:	6388                	ld	a0,0(a5)
    800057ae:	cd39                	beqz	a0,8000580c <kexec+0x252>
    800057b0:	e9040993          	addi	s3,s0,-368
    800057b4:	f9040c13          	addi	s8,s0,-112
    800057b8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800057ba:	e8afb0ef          	jal	80000e44 <strlen>
    800057be:	0015079b          	addiw	a5,a0,1
    800057c2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800057c6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800057ca:	11796e63          	bltu	s2,s7,800058e6 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800057ce:	e0043d03          	ld	s10,-512(s0)
    800057d2:	000d3a03          	ld	s4,0(s10)
    800057d6:	8552                	mv	a0,s4
    800057d8:	e6cfb0ef          	jal	80000e44 <strlen>
    800057dc:	0015069b          	addiw	a3,a0,1
    800057e0:	8652                	mv	a2,s4
    800057e2:	85ca                	mv	a1,s2
    800057e4:	855a                	mv	a0,s6
    800057e6:	e37fb0ef          	jal	8000161c <copyout>
    800057ea:	10054063          	bltz	a0,800058ea <kexec+0x330>
    ustack[argc] = sp;
    800057ee:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800057f2:	0485                	addi	s1,s1,1
    800057f4:	008d0793          	addi	a5,s10,8
    800057f8:	e0f43023          	sd	a5,-512(s0)
    800057fc:	008d3503          	ld	a0,8(s10)
    80005800:	c909                	beqz	a0,80005812 <kexec+0x258>
    if(argc >= MAXARG)
    80005802:	09a1                	addi	s3,s3,8
    80005804:	fb899be3          	bne	s3,s8,800057ba <kexec+0x200>
  ip = 0;
    80005808:	4a01                	li	s4,0
    8000580a:	a0dd                	j	800058f0 <kexec+0x336>
  sp = sz;
    8000580c:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005810:	4481                	li	s1,0
  ustack[argc] = 0;
    80005812:	00349793          	slli	a5,s1,0x3
    80005816:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ff98128>
    8000581a:	97a2                	add	a5,a5,s0
    8000581c:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005820:	00148693          	addi	a3,s1,1
    80005824:	068e                	slli	a3,a3,0x3
    80005826:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000582a:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000582e:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005832:	f5796ee3          	bltu	s2,s7,8000578e <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005836:	e9040613          	addi	a2,s0,-368
    8000583a:	85ca                	mv	a1,s2
    8000583c:	855a                	mv	a0,s6
    8000583e:	ddffb0ef          	jal	8000161c <copyout>
    80005842:	0e054263          	bltz	a0,80005926 <kexec+0x36c>
  p->trapframe->a1 = sp;
    80005846:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000584a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000584e:	df843783          	ld	a5,-520(s0)
    80005852:	0007c703          	lbu	a4,0(a5)
    80005856:	cf11                	beqz	a4,80005872 <kexec+0x2b8>
    80005858:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000585a:	02f00693          	li	a3,47
    8000585e:	a039                	j	8000586c <kexec+0x2b2>
      last = s+1;
    80005860:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005864:	0785                	addi	a5,a5,1
    80005866:	fff7c703          	lbu	a4,-1(a5)
    8000586a:	c701                	beqz	a4,80005872 <kexec+0x2b8>
    if(*s == '/')
    8000586c:	fed71ce3          	bne	a4,a3,80005864 <kexec+0x2aa>
    80005870:	bfc5                	j	80005860 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80005872:	4641                	li	a2,16
    80005874:	df843583          	ld	a1,-520(s0)
    80005878:	158a8513          	addi	a0,s5,344
    8000587c:	d96fb0ef          	jal	80000e12 <safestrcpy>
  oldpagetable = p->pagetable;
    80005880:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005884:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005888:	e0843783          	ld	a5,-504(s0)
    8000588c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80005890:	058ab783          	ld	a5,88(s5)
    80005894:	e6843703          	ld	a4,-408(s0)
    80005898:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000589a:	058ab783          	ld	a5,88(s5)
    8000589e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800058a2:	85e6                	mv	a1,s9
    800058a4:	9eefc0ef          	jal	80001a92 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800058a8:	0004851b          	sext.w	a0,s1
    800058ac:	79be                	ld	s3,488(sp)
    800058ae:	7a1e                	ld	s4,480(sp)
    800058b0:	6afe                	ld	s5,472(sp)
    800058b2:	6b5e                	ld	s6,464(sp)
    800058b4:	6bbe                	ld	s7,456(sp)
    800058b6:	6c1e                	ld	s8,448(sp)
    800058b8:	7cfa                	ld	s9,440(sp)
    800058ba:	7d5a                	ld	s10,432(sp)
    800058bc:	b3b5                	j	80005628 <kexec+0x6e>
    800058be:	e1243423          	sd	s2,-504(s0)
    800058c2:	7dba                	ld	s11,424(sp)
    800058c4:	a035                	j	800058f0 <kexec+0x336>
    800058c6:	e1243423          	sd	s2,-504(s0)
    800058ca:	7dba                	ld	s11,424(sp)
    800058cc:	a015                	j	800058f0 <kexec+0x336>
    800058ce:	e1243423          	sd	s2,-504(s0)
    800058d2:	7dba                	ld	s11,424(sp)
    800058d4:	a831                	j	800058f0 <kexec+0x336>
    800058d6:	e1243423          	sd	s2,-504(s0)
    800058da:	7dba                	ld	s11,424(sp)
    800058dc:	a811                	j	800058f0 <kexec+0x336>
    800058de:	e1243423          	sd	s2,-504(s0)
    800058e2:	7dba                	ld	s11,424(sp)
    800058e4:	a031                	j	800058f0 <kexec+0x336>
  ip = 0;
    800058e6:	4a01                	li	s4,0
    800058e8:	a021                	j	800058f0 <kexec+0x336>
    800058ea:	4a01                	li	s4,0
  if(pagetable)
    800058ec:	a011                	j	800058f0 <kexec+0x336>
    800058ee:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    800058f0:	e0843583          	ld	a1,-504(s0)
    800058f4:	855a                	mv	a0,s6
    800058f6:	99cfc0ef          	jal	80001a92 <proc_freepagetable>
  return -1;
    800058fa:	557d                	li	a0,-1
  if(ip){
    800058fc:	000a1b63          	bnez	s4,80005912 <kexec+0x358>
    80005900:	79be                	ld	s3,488(sp)
    80005902:	7a1e                	ld	s4,480(sp)
    80005904:	6afe                	ld	s5,472(sp)
    80005906:	6b5e                	ld	s6,464(sp)
    80005908:	6bbe                	ld	s7,456(sp)
    8000590a:	6c1e                	ld	s8,448(sp)
    8000590c:	7cfa                	ld	s9,440(sp)
    8000590e:	7d5a                	ld	s10,432(sp)
    80005910:	bb21                	j	80005628 <kexec+0x6e>
    80005912:	79be                	ld	s3,488(sp)
    80005914:	6afe                	ld	s5,472(sp)
    80005916:	6b5e                	ld	s6,464(sp)
    80005918:	6bbe                	ld	s7,456(sp)
    8000591a:	6c1e                	ld	s8,448(sp)
    8000591c:	7cfa                	ld	s9,440(sp)
    8000591e:	7d5a                	ld	s10,432(sp)
    80005920:	b9ed                	j	8000561a <kexec+0x60>
    80005922:	6b5e                	ld	s6,464(sp)
    80005924:	b9dd                	j	8000561a <kexec+0x60>
  sz = sz1;
    80005926:	e0843983          	ld	s3,-504(s0)
    8000592a:	b595                	j	8000578e <kexec+0x1d4>

000000008000592c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000592c:	1101                	addi	sp,sp,-32
    8000592e:	ec06                	sd	ra,24(sp)
    80005930:	e822                	sd	s0,16(sp)
    80005932:	e426                	sd	s1,8(sp)
    80005934:	1000                	addi	s0,sp,32
    80005936:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005938:	fd1fb0ef          	jal	80001908 <myproc>
    8000593c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000593e:	0d050793          	addi	a5,a0,208
    80005942:	4501                	li	a0,0
    80005944:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005946:	6398                	ld	a4,0(a5)
    80005948:	cb19                	beqz	a4,8000595e <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    8000594a:	2505                	addiw	a0,a0,1
    8000594c:	07a1                	addi	a5,a5,8
    8000594e:	fed51ce3          	bne	a0,a3,80005946 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005952:	557d                	li	a0,-1
}
    80005954:	60e2                	ld	ra,24(sp)
    80005956:	6442                	ld	s0,16(sp)
    80005958:	64a2                	ld	s1,8(sp)
    8000595a:	6105                	addi	sp,sp,32
    8000595c:	8082                	ret
      p->ofile[fd] = f;
    8000595e:	01a50793          	addi	a5,a0,26
    80005962:	078e                	slli	a5,a5,0x3
    80005964:	963e                	add	a2,a2,a5
    80005966:	e204                	sd	s1,0(a2)
      return fd;
    80005968:	b7f5                	j	80005954 <fdalloc+0x28>

000000008000596a <argfd>:
{
    8000596a:	7179                	addi	sp,sp,-48
    8000596c:	f406                	sd	ra,40(sp)
    8000596e:	f022                	sd	s0,32(sp)
    80005970:	ec26                	sd	s1,24(sp)
    80005972:	e84a                	sd	s2,16(sp)
    80005974:	1800                	addi	s0,sp,48
    80005976:	892e                	mv	s2,a1
    80005978:	84b2                	mv	s1,a2
  argint(n, &fd);
    8000597a:	fdc40593          	addi	a1,s0,-36
    8000597e:	e9ffc0ef          	jal	8000281c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005982:	fdc42703          	lw	a4,-36(s0)
    80005986:	47bd                	li	a5,15
    80005988:	02e7e963          	bltu	a5,a4,800059ba <argfd+0x50>
    8000598c:	f7dfb0ef          	jal	80001908 <myproc>
    80005990:	fdc42703          	lw	a4,-36(s0)
    80005994:	01a70793          	addi	a5,a4,26
    80005998:	078e                	slli	a5,a5,0x3
    8000599a:	953e                	add	a0,a0,a5
    8000599c:	611c                	ld	a5,0(a0)
    8000599e:	c385                	beqz	a5,800059be <argfd+0x54>
  if(pfd)
    800059a0:	00090463          	beqz	s2,800059a8 <argfd+0x3e>
    *pfd = fd;
    800059a4:	00e92023          	sw	a4,0(s2)
  return 0;
    800059a8:	4501                	li	a0,0
  if(pf)
    800059aa:	c091                	beqz	s1,800059ae <argfd+0x44>
    *pf = f;
    800059ac:	e09c                	sd	a5,0(s1)
}
    800059ae:	70a2                	ld	ra,40(sp)
    800059b0:	7402                	ld	s0,32(sp)
    800059b2:	64e2                	ld	s1,24(sp)
    800059b4:	6942                	ld	s2,16(sp)
    800059b6:	6145                	addi	sp,sp,48
    800059b8:	8082                	ret
    return -1;
    800059ba:	557d                	li	a0,-1
    800059bc:	bfcd                	j	800059ae <argfd+0x44>
    800059be:	557d                	li	a0,-1
    800059c0:	b7fd                	j	800059ae <argfd+0x44>

00000000800059c2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800059c2:	715d                	addi	sp,sp,-80
    800059c4:	e486                	sd	ra,72(sp)
    800059c6:	e0a2                	sd	s0,64(sp)
    800059c8:	fc26                	sd	s1,56(sp)
    800059ca:	f84a                	sd	s2,48(sp)
    800059cc:	f44e                	sd	s3,40(sp)
    800059ce:	ec56                	sd	s5,24(sp)
    800059d0:	e85a                	sd	s6,16(sp)
    800059d2:	0880                	addi	s0,sp,80
    800059d4:	8b2e                	mv	s6,a1
    800059d6:	89b2                	mv	s3,a2
    800059d8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800059da:	fb040593          	addi	a1,s0,-80
    800059de:	989fe0ef          	jal	80004366 <nameiparent>
    800059e2:	84aa                	mv	s1,a0
    800059e4:	10050a63          	beqz	a0,80005af8 <create+0x136>
    return 0;

  ilock(dp);
    800059e8:	f01fd0ef          	jal	800038e8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059ec:	4601                	li	a2,0
    800059ee:	fb040593          	addi	a1,s0,-80
    800059f2:	8526                	mv	a0,s1
    800059f4:	deafe0ef          	jal	80003fde <dirlookup>
    800059f8:	8aaa                	mv	s5,a0
    800059fa:	c129                	beqz	a0,80005a3c <create+0x7a>
    iunlockput(dp);
    800059fc:	8526                	mv	a0,s1
    800059fe:	9c6fe0ef          	jal	80003bc4 <iunlockput>
    ilock(ip);
    80005a02:	8556                	mv	a0,s5
    80005a04:	ee5fd0ef          	jal	800038e8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005a08:	4789                	li	a5,2
    80005a0a:	02fb1463          	bne	s6,a5,80005a32 <create+0x70>
    80005a0e:	044ad783          	lhu	a5,68(s5)
    80005a12:	37f9                	addiw	a5,a5,-2
    80005a14:	17c2                	slli	a5,a5,0x30
    80005a16:	93c1                	srli	a5,a5,0x30
    80005a18:	4705                	li	a4,1
    80005a1a:	00f76c63          	bltu	a4,a5,80005a32 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005a1e:	8556                	mv	a0,s5
    80005a20:	60a6                	ld	ra,72(sp)
    80005a22:	6406                	ld	s0,64(sp)
    80005a24:	74e2                	ld	s1,56(sp)
    80005a26:	7942                	ld	s2,48(sp)
    80005a28:	79a2                	ld	s3,40(sp)
    80005a2a:	6ae2                	ld	s5,24(sp)
    80005a2c:	6b42                	ld	s6,16(sp)
    80005a2e:	6161                	addi	sp,sp,80
    80005a30:	8082                	ret
    iunlockput(ip);
    80005a32:	8556                	mv	a0,s5
    80005a34:	990fe0ef          	jal	80003bc4 <iunlockput>
    return 0;
    80005a38:	4a81                	li	s5,0
    80005a3a:	b7d5                	j	80005a1e <create+0x5c>
    80005a3c:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005a3e:	85da                	mv	a1,s6
    80005a40:	4088                	lw	a0,0(s1)
    80005a42:	cd1fd0ef          	jal	80003712 <ialloc>
    80005a46:	8a2a                	mv	s4,a0
    80005a48:	cd15                	beqz	a0,80005a84 <create+0xc2>
  ilock(ip);
    80005a4a:	e9ffd0ef          	jal	800038e8 <ilock>
  ip->major = major;
    80005a4e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005a52:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005a56:	4905                	li	s2,1
    80005a58:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005a5c:	8552                	mv	a0,s4
    80005a5e:	d93fd0ef          	jal	800037f0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a62:	032b0763          	beq	s6,s2,80005a90 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a66:	004a2603          	lw	a2,4(s4)
    80005a6a:	fb040593          	addi	a1,s0,-80
    80005a6e:	8526                	mv	a0,s1
    80005a70:	803fe0ef          	jal	80004272 <dirlink>
    80005a74:	06054563          	bltz	a0,80005ade <create+0x11c>
  iunlockput(dp);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	94afe0ef          	jal	80003bc4 <iunlockput>
  return ip;
    80005a7e:	8ad2                	mv	s5,s4
    80005a80:	7a02                	ld	s4,32(sp)
    80005a82:	bf71                	j	80005a1e <create+0x5c>
    iunlockput(dp);
    80005a84:	8526                	mv	a0,s1
    80005a86:	93efe0ef          	jal	80003bc4 <iunlockput>
    return 0;
    80005a8a:	8ad2                	mv	s5,s4
    80005a8c:	7a02                	ld	s4,32(sp)
    80005a8e:	bf41                	j	80005a1e <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a90:	004a2603          	lw	a2,4(s4)
    80005a94:	00004597          	auipc	a1,0x4
    80005a98:	2ec58593          	addi	a1,a1,748 # 80009d80 <etext+0xd80>
    80005a9c:	8552                	mv	a0,s4
    80005a9e:	fd4fe0ef          	jal	80004272 <dirlink>
    80005aa2:	02054e63          	bltz	a0,80005ade <create+0x11c>
    80005aa6:	40d0                	lw	a2,4(s1)
    80005aa8:	00004597          	auipc	a1,0x4
    80005aac:	2e058593          	addi	a1,a1,736 # 80009d88 <etext+0xd88>
    80005ab0:	8552                	mv	a0,s4
    80005ab2:	fc0fe0ef          	jal	80004272 <dirlink>
    80005ab6:	02054463          	bltz	a0,80005ade <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005aba:	004a2603          	lw	a2,4(s4)
    80005abe:	fb040593          	addi	a1,s0,-80
    80005ac2:	8526                	mv	a0,s1
    80005ac4:	faefe0ef          	jal	80004272 <dirlink>
    80005ac8:	00054b63          	bltz	a0,80005ade <create+0x11c>
    dp->nlink++;  // for ".."
    80005acc:	04a4d783          	lhu	a5,74(s1)
    80005ad0:	2785                	addiw	a5,a5,1
    80005ad2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	d19fd0ef          	jal	800037f0 <iupdate>
    80005adc:	bf71                	j	80005a78 <create+0xb6>
  ip->nlink = 0;
    80005ade:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005ae2:	8552                	mv	a0,s4
    80005ae4:	d0dfd0ef          	jal	800037f0 <iupdate>
  iunlockput(ip);
    80005ae8:	8552                	mv	a0,s4
    80005aea:	8dafe0ef          	jal	80003bc4 <iunlockput>
  iunlockput(dp);
    80005aee:	8526                	mv	a0,s1
    80005af0:	8d4fe0ef          	jal	80003bc4 <iunlockput>
  return 0;
    80005af4:	7a02                	ld	s4,32(sp)
    80005af6:	b725                	j	80005a1e <create+0x5c>
    return 0;
    80005af8:	8aaa                	mv	s5,a0
    80005afa:	b715                	j	80005a1e <create+0x5c>

0000000080005afc <sys_dup>:
{
    80005afc:	7179                	addi	sp,sp,-48
    80005afe:	f406                	sd	ra,40(sp)
    80005b00:	f022                	sd	s0,32(sp)
    80005b02:	1800                	addi	s0,sp,48
    if(argfd(0, &oldfd, &f) < 0)
    80005b04:	fd840613          	addi	a2,s0,-40
    80005b08:	fd440593          	addi	a1,s0,-44
    80005b0c:	4501                	li	a0,0
    80005b0e:	e5dff0ef          	jal	8000596a <argfd>
        return -1;
    80005b12:	57fd                	li	a5,-1
    if(argfd(0, &oldfd, &f) < 0)
    80005b14:	02054c63          	bltz	a0,80005b4c <sys_dup+0x50>
    80005b18:	ec26                	sd	s1,24(sp)
    80005b1a:	e84a                	sd	s2,16(sp)
    if((newfd = fdalloc(f)) < 0)
    80005b1c:	fd843903          	ld	s2,-40(s0)
    80005b20:	854a                	mv	a0,s2
    80005b22:	e0bff0ef          	jal	8000592c <fdalloc>
    80005b26:	84aa                	mv	s1,a0
        return -1;
    80005b28:	57fd                	li	a5,-1
    if((newfd = fdalloc(f)) < 0)
    80005b2a:	02054663          	bltz	a0,80005b56 <sys_dup+0x5a>
    filedup(f);
    80005b2e:	854a                	mv	a0,s2
    80005b30:	b90ff0ef          	jal	80004ec0 <filedup>
        myproc()->pid,
    80005b34:	dd5fb0ef          	jal	80001908 <myproc>
    state_dup_file(
    80005b38:	86ca                	mv	a3,s2
    80005b3a:	8626                	mv	a2,s1
    80005b3c:	fd442583          	lw	a1,-44(s0)
    80005b40:	5908                	lw	a0,48(a0)
    80005b42:	61e010ef          	jal	80007160 <state_dup_file>
    return newfd;
    80005b46:	87a6                	mv	a5,s1
    80005b48:	64e2                	ld	s1,24(sp)
    80005b4a:	6942                	ld	s2,16(sp)
}
    80005b4c:	853e                	mv	a0,a5
    80005b4e:	70a2                	ld	ra,40(sp)
    80005b50:	7402                	ld	s0,32(sp)
    80005b52:	6145                	addi	sp,sp,48
    80005b54:	8082                	ret
    80005b56:	64e2                	ld	s1,24(sp)
    80005b58:	6942                	ld	s2,16(sp)
    80005b5a:	bfcd                	j	80005b4c <sys_dup+0x50>

0000000080005b5c <sys_read>:
{
    80005b5c:	7179                	addi	sp,sp,-48
    80005b5e:	f406                	sd	ra,40(sp)
    80005b60:	f022                	sd	s0,32(sp)
    80005b62:	1800                	addi	s0,sp,48
  if(argfd(0, &fd, &f) < 0)
    80005b64:	fe840613          	addi	a2,s0,-24
    80005b68:	fd440593          	addi	a1,s0,-44
    80005b6c:	4501                	li	a0,0
    80005b6e:	dfdff0ef          	jal	8000596a <argfd>
    80005b72:	87aa                	mv	a5,a0
    return -1;
    80005b74:	557d                	li	a0,-1
  if(argfd(0, &fd, &f) < 0)
    80005b76:	0407c263          	bltz	a5,80005bba <sys_read+0x5e>
  argaddr(1, &p);
    80005b7a:	fd840593          	addi	a1,s0,-40
    80005b7e:	4505                	li	a0,1
    80005b80:	cb9fc0ef          	jal	80002838 <argaddr>
  argint(2, &n);
    80005b84:	fe440593          	addi	a1,s0,-28
    80005b88:	4509                	li	a0,2
    80005b8a:	c93fc0ef          	jal	8000281c <argint>
  safestrcpy(myproc()->current_syscall,
    80005b8e:	d7bfb0ef          	jal	80001908 <myproc>
    80005b92:	02000613          	li	a2,32
    80005b96:	00004597          	auipc	a1,0x4
    80005b9a:	1fa58593          	addi	a1,a1,506 # 80009d90 <etext+0xd90>
    80005b9e:	16850513          	addi	a0,a0,360
    80005ba2:	a70fb0ef          	jal	80000e12 <safestrcpy>
  return fileread(f, fd, p, n);
    80005ba6:	fe442683          	lw	a3,-28(s0)
    80005baa:	fd843603          	ld	a2,-40(s0)
    80005bae:	fd442583          	lw	a1,-44(s0)
    80005bb2:	fe843503          	ld	a0,-24(s0)
    80005bb6:	cbcff0ef          	jal	80005072 <fileread>
}
    80005bba:	70a2                	ld	ra,40(sp)
    80005bbc:	7402                	ld	s0,32(sp)
    80005bbe:	6145                	addi	sp,sp,48
    80005bc0:	8082                	ret

0000000080005bc2 <sys_write>:
{
    80005bc2:	7179                	addi	sp,sp,-48
    80005bc4:	f406                	sd	ra,40(sp)
    80005bc6:	f022                	sd	s0,32(sp)
    80005bc8:	1800                	addi	s0,sp,48
  if(argfd(0, &fd , &f) < 0)
    80005bca:	fe840613          	addi	a2,s0,-24
    80005bce:	fd440593          	addi	a1,s0,-44
    80005bd2:	4501                	li	a0,0
    80005bd4:	d97ff0ef          	jal	8000596a <argfd>
    80005bd8:	87aa                	mv	a5,a0
    return -1;
    80005bda:	557d                	li	a0,-1
  if(argfd(0, &fd , &f) < 0)
    80005bdc:	0407c263          	bltz	a5,80005c20 <sys_write+0x5e>
  argaddr(1, &p);
    80005be0:	fd840593          	addi	a1,s0,-40
    80005be4:	4505                	li	a0,1
    80005be6:	c53fc0ef          	jal	80002838 <argaddr>
  argint(2, &n);
    80005bea:	fe440593          	addi	a1,s0,-28
    80005bee:	4509                	li	a0,2
    80005bf0:	c2dfc0ef          	jal	8000281c <argint>
  safestrcpy(myproc()->current_syscall,
    80005bf4:	d15fb0ef          	jal	80001908 <myproc>
    80005bf8:	02000613          	li	a2,32
    80005bfc:	00004597          	auipc	a1,0x4
    80005c00:	19c58593          	addi	a1,a1,412 # 80009d98 <etext+0xd98>
    80005c04:	16850513          	addi	a0,a0,360
    80005c08:	a0afb0ef          	jal	80000e12 <safestrcpy>
  return filewrite(f, fd, p, n);
    80005c0c:	fe442683          	lw	a3,-28(s0)
    80005c10:	fd843603          	ld	a2,-40(s0)
    80005c14:	fd442583          	lw	a1,-44(s0)
    80005c18:	fe843503          	ld	a0,-24(s0)
    80005c1c:	d3eff0ef          	jal	8000515a <filewrite>
}
    80005c20:	70a2                	ld	ra,40(sp)
    80005c22:	7402                	ld	s0,32(sp)
    80005c24:	6145                	addi	sp,sp,48
    80005c26:	8082                	ret

0000000080005c28 <sys_close>:
{
    80005c28:	7179                	addi	sp,sp,-48
    80005c2a:	f406                	sd	ra,40(sp)
    80005c2c:	f022                	sd	s0,32(sp)
    80005c2e:	1800                	addi	s0,sp,48
    if(argfd(0, &fd, &f) < 0)
    80005c30:	fd040613          	addi	a2,s0,-48
    80005c34:	fdc40593          	addi	a1,s0,-36
    80005c38:	4501                	li	a0,0
    80005c3a:	d31ff0ef          	jal	8000596a <argfd>
        return -1;
    80005c3e:	57fd                	li	a5,-1
    if(argfd(0, &fd, &f) < 0)
    80005c40:	02054d63          	bltz	a0,80005c7a <sys_close+0x52>
    80005c44:	ec26                	sd	s1,24(sp)
    80005c46:	e84a                	sd	s2,16(sp)
    myproc()->ofile[fd] = 0;
    80005c48:	cc1fb0ef          	jal	80001908 <myproc>
    80005c4c:	fdc42903          	lw	s2,-36(s0)
    80005c50:	01a90793          	addi	a5,s2,26
    80005c54:	078e                	slli	a5,a5,0x3
    80005c56:	953e                	add	a0,a0,a5
    80005c58:	00053023          	sd	zero,0(a0)
        myproc()->pid,
    80005c5c:	cadfb0ef          	jal	80001908 <myproc>
    state_remove_fd(
    80005c60:	fd043483          	ld	s1,-48(s0)
    80005c64:	8626                	mv	a2,s1
    80005c66:	85ca                	mv	a1,s2
    80005c68:	5908                	lw	a0,48(a0)
    80005c6a:	3ec010ef          	jal	80007056 <state_remove_fd>
    fileclose(f);
    80005c6e:	8526                	mv	a0,s1
    80005c70:	ab0ff0ef          	jal	80004f20 <fileclose>
    return 0;
    80005c74:	4781                	li	a5,0
    80005c76:	64e2                	ld	s1,24(sp)
    80005c78:	6942                	ld	s2,16(sp)
}
    80005c7a:	853e                	mv	a0,a5
    80005c7c:	70a2                	ld	ra,40(sp)
    80005c7e:	7402                	ld	s0,32(sp)
    80005c80:	6145                	addi	sp,sp,48
    80005c82:	8082                	ret

0000000080005c84 <sys_fstat>:
{
    80005c84:	1101                	addi	sp,sp,-32
    80005c86:	ec06                	sd	ra,24(sp)
    80005c88:	e822                	sd	s0,16(sp)
    80005c8a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005c8c:	fe040593          	addi	a1,s0,-32
    80005c90:	4505                	li	a0,1
    80005c92:	ba7fc0ef          	jal	80002838 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005c96:	fe840613          	addi	a2,s0,-24
    80005c9a:	4581                	li	a1,0
    80005c9c:	4501                	li	a0,0
    80005c9e:	ccdff0ef          	jal	8000596a <argfd>
    80005ca2:	87aa                	mv	a5,a0
    return -1;
    80005ca4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ca6:	0007c863          	bltz	a5,80005cb6 <sys_fstat+0x32>
  return filestat(f, st);
    80005caa:	fe043583          	ld	a1,-32(s0)
    80005cae:	fe843503          	ld	a0,-24(s0)
    80005cb2:	b62ff0ef          	jal	80005014 <filestat>
}
    80005cb6:	60e2                	ld	ra,24(sp)
    80005cb8:	6442                	ld	s0,16(sp)
    80005cba:	6105                	addi	sp,sp,32
    80005cbc:	8082                	ret

0000000080005cbe <sys_link>:
{
    80005cbe:	7169                	addi	sp,sp,-304
    80005cc0:	f606                	sd	ra,296(sp)
    80005cc2:	f222                	sd	s0,288(sp)
    80005cc4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cc6:	08000613          	li	a2,128
    80005cca:	ed040593          	addi	a1,s0,-304
    80005cce:	4501                	li	a0,0
    80005cd0:	b85fc0ef          	jal	80002854 <argstr>
    return -1;
    80005cd4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cd6:	0e054a63          	bltz	a0,80005dca <sys_link+0x10c>
    80005cda:	08000613          	li	a2,128
    80005cde:	f5040593          	addi	a1,s0,-176
    80005ce2:	4505                	li	a0,1
    80005ce4:	b71fc0ef          	jal	80002854 <argstr>
    return -1;
    80005ce8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cea:	0e054063          	bltz	a0,80005dca <sys_link+0x10c>
    80005cee:	ee26                	sd	s1,280(sp)
  safestrcpy(myproc()->current_syscall,
    80005cf0:	c19fb0ef          	jal	80001908 <myproc>
    80005cf4:	02000613          	li	a2,32
    80005cf8:	00004597          	auipc	a1,0x4
    80005cfc:	0a858593          	addi	a1,a1,168 # 80009da0 <etext+0xda0>
    80005d00:	16850513          	addi	a0,a0,360
    80005d04:	90efb0ef          	jal	80000e12 <safestrcpy>
  begin_op();
    80005d08:	a8ffe0ef          	jal	80004796 <begin_op>
  if((ip = namei(old)) == 0){
    80005d0c:	ed040513          	addi	a0,s0,-304
    80005d10:	e3cfe0ef          	jal	8000434c <namei>
    80005d14:	84aa                	mv	s1,a0
    80005d16:	c53d                	beqz	a0,80005d84 <sys_link+0xc6>
  ilock(ip);
    80005d18:	bd1fd0ef          	jal	800038e8 <ilock>
  if(ip->type == T_DIR){
    80005d1c:	04449703          	lh	a4,68(s1)
    80005d20:	4785                	li	a5,1
    80005d22:	06f70663          	beq	a4,a5,80005d8e <sys_link+0xd0>
    80005d26:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005d28:	04a4d783          	lhu	a5,74(s1)
    80005d2c:	2785                	addiw	a5,a5,1
    80005d2e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d32:	8526                	mv	a0,s1
    80005d34:	abdfd0ef          	jal	800037f0 <iupdate>
  iunlock(ip);
    80005d38:	8526                	mv	a0,s1
    80005d3a:	ca1fd0ef          	jal	800039da <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d3e:	fd040593          	addi	a1,s0,-48
    80005d42:	f5040513          	addi	a0,s0,-176
    80005d46:	e20fe0ef          	jal	80004366 <nameiparent>
    80005d4a:	892a                	mv	s2,a0
    80005d4c:	cd21                	beqz	a0,80005da4 <sys_link+0xe6>
  ilock(dp);
    80005d4e:	b9bfd0ef          	jal	800038e8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d52:	00092703          	lw	a4,0(s2)
    80005d56:	409c                	lw	a5,0(s1)
    80005d58:	04f71363          	bne	a4,a5,80005d9e <sys_link+0xe0>
    80005d5c:	40d0                	lw	a2,4(s1)
    80005d5e:	fd040593          	addi	a1,s0,-48
    80005d62:	854a                	mv	a0,s2
    80005d64:	d0efe0ef          	jal	80004272 <dirlink>
    80005d68:	02054b63          	bltz	a0,80005d9e <sys_link+0xe0>
  iunlockput(dp);
    80005d6c:	854a                	mv	a0,s2
    80005d6e:	e57fd0ef          	jal	80003bc4 <iunlockput>
  iput(ip);
    80005d72:	8526                	mv	a0,s1
    80005d74:	d85fd0ef          	jal	80003af8 <iput>
  end_op();
    80005d78:	b3dfe0ef          	jal	800048b4 <end_op>
  return 0;
    80005d7c:	4781                	li	a5,0
    80005d7e:	64f2                	ld	s1,280(sp)
    80005d80:	6952                	ld	s2,272(sp)
    80005d82:	a0a1                	j	80005dca <sys_link+0x10c>
    end_op();
    80005d84:	b31fe0ef          	jal	800048b4 <end_op>
    return -1;
    80005d88:	57fd                	li	a5,-1
    80005d8a:	64f2                	ld	s1,280(sp)
    80005d8c:	a83d                	j	80005dca <sys_link+0x10c>
    iunlockput(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	e35fd0ef          	jal	80003bc4 <iunlockput>
    end_op();
    80005d94:	b21fe0ef          	jal	800048b4 <end_op>
    return -1;
    80005d98:	57fd                	li	a5,-1
    80005d9a:	64f2                	ld	s1,280(sp)
    80005d9c:	a03d                	j	80005dca <sys_link+0x10c>
    iunlockput(dp);
    80005d9e:	854a                	mv	a0,s2
    80005da0:	e25fd0ef          	jal	80003bc4 <iunlockput>
  ilock(ip);
    80005da4:	8526                	mv	a0,s1
    80005da6:	b43fd0ef          	jal	800038e8 <ilock>
  ip->nlink--;
    80005daa:	04a4d783          	lhu	a5,74(s1)
    80005dae:	37fd                	addiw	a5,a5,-1
    80005db0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005db4:	8526                	mv	a0,s1
    80005db6:	a3bfd0ef          	jal	800037f0 <iupdate>
  iunlockput(ip);
    80005dba:	8526                	mv	a0,s1
    80005dbc:	e09fd0ef          	jal	80003bc4 <iunlockput>
  end_op();
    80005dc0:	af5fe0ef          	jal	800048b4 <end_op>
  return -1;
    80005dc4:	57fd                	li	a5,-1
    80005dc6:	64f2                	ld	s1,280(sp)
    80005dc8:	6952                	ld	s2,272(sp)
}
    80005dca:	853e                	mv	a0,a5
    80005dcc:	70b2                	ld	ra,296(sp)
    80005dce:	7412                	ld	s0,288(sp)
    80005dd0:	6155                	addi	sp,sp,304
    80005dd2:	8082                	ret

0000000080005dd4 <sys_unlink>:
{
    80005dd4:	7151                	addi	sp,sp,-240
    80005dd6:	f586                	sd	ra,232(sp)
    80005dd8:	f1a2                	sd	s0,224(sp)
    80005dda:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ddc:	08000613          	li	a2,128
    80005de0:	f3040593          	addi	a1,s0,-208
    80005de4:	4501                	li	a0,0
    80005de6:	a6ffc0ef          	jal	80002854 <argstr>
    80005dea:	16054c63          	bltz	a0,80005f62 <sys_unlink+0x18e>
    80005dee:	eda6                	sd	s1,216(sp)
  safestrcpy(myproc()->current_syscall,
    80005df0:	b19fb0ef          	jal	80001908 <myproc>
    80005df4:	02000613          	li	a2,32
    80005df8:	00004597          	auipc	a1,0x4
    80005dfc:	fb058593          	addi	a1,a1,-80 # 80009da8 <etext+0xda8>
    80005e00:	16850513          	addi	a0,a0,360
    80005e04:	80efb0ef          	jal	80000e12 <safestrcpy>
  begin_op();
    80005e08:	98ffe0ef          	jal	80004796 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e0c:	fb040593          	addi	a1,s0,-80
    80005e10:	f3040513          	addi	a0,s0,-208
    80005e14:	d52fe0ef          	jal	80004366 <nameiparent>
    80005e18:	84aa                	mv	s1,a0
    80005e1a:	c945                	beqz	a0,80005eca <sys_unlink+0xf6>
  ilock(dp);
    80005e1c:	acdfd0ef          	jal	800038e8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e20:	00004597          	auipc	a1,0x4
    80005e24:	f6058593          	addi	a1,a1,-160 # 80009d80 <etext+0xd80>
    80005e28:	fb040513          	addi	a0,s0,-80
    80005e2c:	99cfe0ef          	jal	80003fc8 <namecmp>
    80005e30:	10050e63          	beqz	a0,80005f4c <sys_unlink+0x178>
    80005e34:	00004597          	auipc	a1,0x4
    80005e38:	f5458593          	addi	a1,a1,-172 # 80009d88 <etext+0xd88>
    80005e3c:	fb040513          	addi	a0,s0,-80
    80005e40:	988fe0ef          	jal	80003fc8 <namecmp>
    80005e44:	10050463          	beqz	a0,80005f4c <sys_unlink+0x178>
    80005e48:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e4a:	f2c40613          	addi	a2,s0,-212
    80005e4e:	fb040593          	addi	a1,s0,-80
    80005e52:	8526                	mv	a0,s1
    80005e54:	98afe0ef          	jal	80003fde <dirlookup>
    80005e58:	892a                	mv	s2,a0
    80005e5a:	0e050863          	beqz	a0,80005f4a <sys_unlink+0x176>
  ilock(ip);
    80005e5e:	a8bfd0ef          	jal	800038e8 <ilock>
  if(ip->nlink < 1)
    80005e62:	04a91783          	lh	a5,74(s2)
    80005e66:	06f05763          	blez	a5,80005ed4 <sys_unlink+0x100>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e6a:	04491703          	lh	a4,68(s2)
    80005e6e:	4785                	li	a5,1
    80005e70:	06f70963          	beq	a4,a5,80005ee2 <sys_unlink+0x10e>
  memset(&de, 0, sizeof(de));
    80005e74:	4641                	li	a2,16
    80005e76:	4581                	li	a1,0
    80005e78:	fc040513          	addi	a0,s0,-64
    80005e7c:	e59fa0ef          	jal	80000cd4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e80:	4741                	li	a4,16
    80005e82:	f2c42683          	lw	a3,-212(s0)
    80005e86:	fc040613          	addi	a2,s0,-64
    80005e8a:	4581                	li	a1,0
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	fedfd0ef          	jal	80003e7a <writei>
    80005e92:	47c1                	li	a5,16
    80005e94:	08f51b63          	bne	a0,a5,80005f2a <sys_unlink+0x156>
  if(ip->type == T_DIR){
    80005e98:	04491703          	lh	a4,68(s2)
    80005e9c:	4785                	li	a5,1
    80005e9e:	08f70d63          	beq	a4,a5,80005f38 <sys_unlink+0x164>
  iunlockput(dp);
    80005ea2:	8526                	mv	a0,s1
    80005ea4:	d21fd0ef          	jal	80003bc4 <iunlockput>
  ip->nlink--;
    80005ea8:	04a95783          	lhu	a5,74(s2)
    80005eac:	37fd                	addiw	a5,a5,-1
    80005eae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005eb2:	854a                	mv	a0,s2
    80005eb4:	93dfd0ef          	jal	800037f0 <iupdate>
  iunlockput(ip);
    80005eb8:	854a                	mv	a0,s2
    80005eba:	d0bfd0ef          	jal	80003bc4 <iunlockput>
  end_op();
    80005ebe:	9f7fe0ef          	jal	800048b4 <end_op>
  return 0;
    80005ec2:	4501                	li	a0,0
    80005ec4:	64ee                	ld	s1,216(sp)
    80005ec6:	694e                	ld	s2,208(sp)
    80005ec8:	a849                	j	80005f5a <sys_unlink+0x186>
    end_op();
    80005eca:	9ebfe0ef          	jal	800048b4 <end_op>
    return -1;
    80005ece:	557d                	li	a0,-1
    80005ed0:	64ee                	ld	s1,216(sp)
    80005ed2:	a061                	j	80005f5a <sys_unlink+0x186>
    80005ed4:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005ed6:	00004517          	auipc	a0,0x4
    80005eda:	eda50513          	addi	a0,a0,-294 # 80009db0 <etext+0xdb0>
    80005ede:	935fa0ef          	jal	80000812 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ee2:	04c92703          	lw	a4,76(s2)
    80005ee6:	02000793          	li	a5,32
    80005eea:	f8e7f5e3          	bgeu	a5,a4,80005e74 <sys_unlink+0xa0>
    80005eee:	e5ce                	sd	s3,200(sp)
    80005ef0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ef4:	4741                	li	a4,16
    80005ef6:	86ce                	mv	a3,s3
    80005ef8:	f1840613          	addi	a2,s0,-232
    80005efc:	4581                	li	a1,0
    80005efe:	854a                	mv	a0,s2
    80005f00:	e4bfd0ef          	jal	80003d4a <readi>
    80005f04:	47c1                	li	a5,16
    80005f06:	00f51c63          	bne	a0,a5,80005f1e <sys_unlink+0x14a>
    if(de.inum != 0)
    80005f0a:	f1845783          	lhu	a5,-232(s0)
    80005f0e:	efa1                	bnez	a5,80005f66 <sys_unlink+0x192>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f10:	29c1                	addiw	s3,s3,16
    80005f12:	04c92783          	lw	a5,76(s2)
    80005f16:	fcf9efe3          	bltu	s3,a5,80005ef4 <sys_unlink+0x120>
    80005f1a:	69ae                	ld	s3,200(sp)
    80005f1c:	bfa1                	j	80005e74 <sys_unlink+0xa0>
      panic("isdirempty: readi");
    80005f1e:	00004517          	auipc	a0,0x4
    80005f22:	eaa50513          	addi	a0,a0,-342 # 80009dc8 <etext+0xdc8>
    80005f26:	8edfa0ef          	jal	80000812 <panic>
    80005f2a:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005f2c:	00004517          	auipc	a0,0x4
    80005f30:	eb450513          	addi	a0,a0,-332 # 80009de0 <etext+0xde0>
    80005f34:	8dffa0ef          	jal	80000812 <panic>
    dp->nlink--;
    80005f38:	04a4d783          	lhu	a5,74(s1)
    80005f3c:	37fd                	addiw	a5,a5,-1
    80005f3e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f42:	8526                	mv	a0,s1
    80005f44:	8adfd0ef          	jal	800037f0 <iupdate>
    80005f48:	bfa9                	j	80005ea2 <sys_unlink+0xce>
    80005f4a:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005f4c:	8526                	mv	a0,s1
    80005f4e:	c77fd0ef          	jal	80003bc4 <iunlockput>
  end_op();
    80005f52:	963fe0ef          	jal	800048b4 <end_op>
  return -1;
    80005f56:	557d                	li	a0,-1
    80005f58:	64ee                	ld	s1,216(sp)
}
    80005f5a:	70ae                	ld	ra,232(sp)
    80005f5c:	740e                	ld	s0,224(sp)
    80005f5e:	616d                	addi	sp,sp,240
    80005f60:	8082                	ret
    return -1;
    80005f62:	557d                	li	a0,-1
    80005f64:	bfdd                	j	80005f5a <sys_unlink+0x186>
    iunlockput(ip);
    80005f66:	854a                	mv	a0,s2
    80005f68:	c5dfd0ef          	jal	80003bc4 <iunlockput>
    goto bad;
    80005f6c:	694e                	ld	s2,208(sp)
    80005f6e:	69ae                	ld	s3,200(sp)
    80005f70:	bff1                	j	80005f4c <sys_unlink+0x178>

0000000080005f72 <sys_open>:

uint64
sys_open(void)
{
    80005f72:	7129                	addi	sp,sp,-320
    80005f74:	fe06                	sd	ra,312(sp)
    80005f76:	fa22                	sd	s0,304(sp)
    80005f78:	ee4e                	sd	s3,280(sp)
    80005f7a:	ea52                	sd	s4,272(sp)
    80005f7c:	0280                	addi	s0,sp,320
  char path[MAXPATH];
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;
  struct proc *p = myproc();
    80005f7e:	98bfb0ef          	jal	80001908 <myproc>
    80005f82:	8a2a                	mv	s4,a0

  argint(1, &omode);
    80005f84:	f4c40593          	addi	a1,s0,-180
    80005f88:	4505                	li	a0,1
    80005f8a:	893fc0ef          	jal	8000281c <argint>

  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f8e:	08000613          	li	a2,128
    80005f92:	f5040593          	addi	a1,s0,-176
    80005f96:	4501                	li	a0,0
    80005f98:	8bdfc0ef          	jal	80002854 <argstr>
    return -1;
    80005f9c:	59fd                	li	s3,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f9e:	10054363          	bltz	a0,800060a4 <sys_open+0x132>
    80005fa2:	f626                	sd	s1,296(sp)

  safestrcpy(
    myproc()->current_syscall,
    80005fa4:	965fb0ef          	jal	80001908 <myproc>
  safestrcpy(
    80005fa8:	02000613          	li	a2,32
    80005fac:	00004597          	auipc	a1,0x4
    80005fb0:	e4458593          	addi	a1,a1,-444 # 80009df0 <etext+0xdf0>
    80005fb4:	16850513          	addi	a0,a0,360
    80005fb8:	e5bfa0ef          	jal	80000e12 <safestrcpy>
    "OPEN",
    sizeof(myproc()->current_syscall)
  );

  begin_op();
    80005fbc:	fdafe0ef          	jal	80004796 <begin_op>

  if(omode & O_CREATE){
    80005fc0:	f4c42783          	lw	a5,-180(s0)
    80005fc4:	2007f793          	andi	a5,a5,512
    80005fc8:	0e078963          	beqz	a5,800060ba <sys_open+0x148>
    ip = create(path, T_FILE, 0, 0);
    80005fcc:	4681                	li	a3,0
    80005fce:	4601                	li	a2,0
    80005fd0:	4589                	li	a1,2
    80005fd2:	f5040513          	addi	a0,s0,-176
    80005fd6:	9edff0ef          	jal	800059c2 <create>
    80005fda:	84aa                	mv	s1,a0
    if(ip == 0){
    80005fdc:	c979                	beqz	a0,800060b2 <sys_open+0x140>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE &&
    80005fde:	04449703          	lh	a4,68(s1)
    80005fe2:	478d                	li	a5,3
    80005fe4:	00f71763          	bne	a4,a5,80005ff2 <sys_open+0x80>
    80005fe8:	0464d703          	lhu	a4,70(s1)
    80005fec:	47a5                	li	a5,9
    80005fee:	10e7e463          	bltu	a5,a4,800060f6 <sys_open+0x184>
    80005ff2:	f24a                	sd	s2,288(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f=filealloc())==0 ||
    80005ff4:	e6ffe0ef          	jal	80004e62 <filealloc>
    80005ff8:	892a                	mv	s2,a0
    80005ffa:	10050963          	beqz	a0,8000610c <sys_open+0x19a>
   (fd=fdalloc(f))<0){
    80005ffe:	92fff0ef          	jal	8000592c <fdalloc>
    80006002:	89aa                	mv	s3,a0
  if((f=filealloc())==0 ||
    80006004:	10054163          	bltz	a0,80006106 <sys_open+0x194>
    end_op();
    return -1;

  }

  if(path[0] == '/'){
    80006008:	f5044783          	lbu	a5,-176(s0)
    8000600c:	02f00713          	li	a4,47
    80006010:	10e78763          	beq	a5,a4,8000611e <sys_open+0x1ac>
    safestrcpy(f->path, path, MAXPATH);
} else {
    char full[MAXPATH];

    if(path[0] == '.'){
    80006014:	02e00713          	li	a4,46
    80006018:	10e78c63          	beq	a5,a4,80006130 <sys_open+0x1be>
        safestrcpy(full, "/", MAXPATH);
    } else {
        full[0] = '/';
    8000601c:	02f00793          	li	a5,47
    80006020:	ecf40423          	sb	a5,-312(s0)
        safestrcpy(full + 1, path, MAXPATH - 1);
    80006024:	07f00613          	li	a2,127
    80006028:	f5040593          	addi	a1,s0,-176
    8000602c:	ec940513          	addi	a0,s0,-311
    80006030:	de3fa0ef          	jal	80000e12 <safestrcpy>
    }

    safestrcpy(f->path, full, MAXPATH);
    80006034:	08000613          	li	a2,128
    80006038:	ec840593          	addi	a1,s0,-312
    8000603c:	02690513          	addi	a0,s2,38
    80006040:	dd3fa0ef          	jal	80000e12 <safestrcpy>
}

  if(ip->type == T_DEVICE){
    80006044:	04449703          	lh	a4,68(s1)
    80006048:	478d                	li	a5,3
    8000604a:	0ef70e63          	beq	a4,a5,80006146 <sys_open+0x1d4>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000604e:	4789                	li	a5,2
    80006050:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80006054:	02092023          	sw	zero,32(s2)
  }

  f->ip = ip;
    80006058:	00993c23          	sd	s1,24(s2)

  f->readable = !(omode & O_WRONLY);
    8000605c:	f4c42783          	lw	a5,-180(s0)
    80006060:	0017c713          	xori	a4,a5,1
    80006064:	8b05                	andi	a4,a4,1
    80006066:	00e90423          	sb	a4,8(s2)

  f->writable =
      (omode & O_WRONLY) ||
    8000606a:	0037f713          	andi	a4,a5,3
    8000606e:	00e03733          	snez	a4,a4
    80006072:	00e904a3          	sb	a4,9(s2)
      (omode & O_RDWR);

  if((omode & O_TRUNC) &&
    80006076:	4007f793          	andi	a5,a5,1024
    8000607a:	c791                	beqz	a5,80006086 <sys_open+0x114>
    8000607c:	04449703          	lh	a4,68(s1)
    80006080:	4789                	li	a5,2
    80006082:	0cf70963          	beq	a4,a5,80006154 <sys_open+0x1e2>
      ip->type == T_FILE){
    itrunc(ip);
  }

  iunlock(ip);
    80006086:	8526                	mv	a0,s1
    80006088:	953fd0ef          	jal	800039da <iunlock>
  end_op();
    8000608c:	829fe0ef          	jal	800048b4 <end_op>
  state_update_file(
    80006090:	f5040693          	addi	a3,s0,-176
    80006094:	864a                	mv	a2,s2
    80006096:	85ce                	mv	a1,s3
    80006098:	030a2503          	lw	a0,48(s4)
    8000609c:	693000ef          	jal	80006f2e <state_update_file>
    800060a0:	74b2                	ld	s1,296(sp)
    800060a2:	7912                	ld	s2,288(sp)
    fd,
    f,
    path
);
  return fd;
}
    800060a4:	854e                	mv	a0,s3
    800060a6:	70f2                	ld	ra,312(sp)
    800060a8:	7452                	ld	s0,304(sp)
    800060aa:	69f2                	ld	s3,280(sp)
    800060ac:	6a52                	ld	s4,272(sp)
    800060ae:	6131                	addi	sp,sp,320
    800060b0:	8082                	ret
      end_op();
    800060b2:	803fe0ef          	jal	800048b4 <end_op>
      return -1;
    800060b6:	74b2                	ld	s1,296(sp)
    800060b8:	b7f5                	j	800060a4 <sys_open+0x132>
    if((ip = namei(path)) == 0){
    800060ba:	f5040513          	addi	a0,s0,-176
    800060be:	a8efe0ef          	jal	8000434c <namei>
    800060c2:	84aa                	mv	s1,a0
    800060c4:	c505                	beqz	a0,800060ec <sys_open+0x17a>
    ilock(ip);
    800060c6:	823fd0ef          	jal	800038e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060ca:	04449703          	lh	a4,68(s1)
    800060ce:	4785                	li	a5,1
    800060d0:	f0f717e3          	bne	a4,a5,80005fde <sys_open+0x6c>
    800060d4:	f4c42783          	lw	a5,-180(s0)
    800060d8:	f0078de3          	beqz	a5,80005ff2 <sys_open+0x80>
      iunlockput(ip);
    800060dc:	8526                	mv	a0,s1
    800060de:	ae7fd0ef          	jal	80003bc4 <iunlockput>
      end_op();
    800060e2:	fd2fe0ef          	jal	800048b4 <end_op>
      return -1;
    800060e6:	59fd                	li	s3,-1
    800060e8:	74b2                	ld	s1,296(sp)
    800060ea:	bf6d                	j	800060a4 <sys_open+0x132>
      end_op();
    800060ec:	fc8fe0ef          	jal	800048b4 <end_op>
      return -1;
    800060f0:	59fd                	li	s3,-1
    800060f2:	74b2                	ld	s1,296(sp)
    800060f4:	bf45                	j	800060a4 <sys_open+0x132>
    iunlockput(ip);
    800060f6:	8526                	mv	a0,s1
    800060f8:	acdfd0ef          	jal	80003bc4 <iunlockput>
    end_op();
    800060fc:	fb8fe0ef          	jal	800048b4 <end_op>
    return -1;
    80006100:	59fd                	li	s3,-1
    80006102:	74b2                	ld	s1,296(sp)
    80006104:	b745                	j	800060a4 <sys_open+0x132>
        fileclose(f);
    80006106:	854a                	mv	a0,s2
    80006108:	e19fe0ef          	jal	80004f20 <fileclose>
    iunlockput(ip);
    8000610c:	8526                	mv	a0,s1
    8000610e:	ab7fd0ef          	jal	80003bc4 <iunlockput>
    end_op();
    80006112:	fa2fe0ef          	jal	800048b4 <end_op>
    return -1;
    80006116:	59fd                	li	s3,-1
    80006118:	74b2                	ld	s1,296(sp)
    8000611a:	7912                	ld	s2,288(sp)
    8000611c:	b761                	j	800060a4 <sys_open+0x132>
    safestrcpy(f->path, path, MAXPATH);
    8000611e:	08000613          	li	a2,128
    80006122:	f5040593          	addi	a1,s0,-176
    80006126:	02690513          	addi	a0,s2,38
    8000612a:	ce9fa0ef          	jal	80000e12 <safestrcpy>
    8000612e:	bf19                	j	80006044 <sys_open+0xd2>
        safestrcpy(full, "/", MAXPATH);
    80006130:	08000613          	li	a2,128
    80006134:	00003597          	auipc	a1,0x3
    80006138:	05458593          	addi	a1,a1,84 # 80009188 <etext+0x188>
    8000613c:	ec840513          	addi	a0,s0,-312
    80006140:	cd3fa0ef          	jal	80000e12 <safestrcpy>
    80006144:	bdc5                	j	80006034 <sys_open+0xc2>
    f->type = FD_DEVICE;
    80006146:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000614a:	04649783          	lh	a5,70(s1)
    8000614e:	02f91223          	sh	a5,36(s2)
    80006152:	b719                	j	80006058 <sys_open+0xe6>
    itrunc(ip);
    80006154:	8526                	mv	a0,s1
    80006156:	8e7fd0ef          	jal	80003a3c <itrunc>
    8000615a:	b735                	j	80006086 <sys_open+0x114>

000000008000615c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000615c:	7175                	addi	sp,sp,-144
    8000615e:	e506                	sd	ra,136(sp)
    80006160:	e122                	sd	s0,128(sp)
    80006162:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;
  
  safestrcpy(myproc()->current_syscall,
    80006164:	fa4fb0ef          	jal	80001908 <myproc>
    80006168:	02000613          	li	a2,32
    8000616c:	00004597          	auipc	a1,0x4
    80006170:	c8c58593          	addi	a1,a1,-884 # 80009df8 <etext+0xdf8>
    80006174:	16850513          	addi	a0,a0,360
    80006178:	c9bfa0ef          	jal	80000e12 <safestrcpy>
             "MKDIR",
             sizeof(myproc()->current_syscall));
  begin_op();
    8000617c:	e1afe0ef          	jal	80004796 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006180:	08000613          	li	a2,128
    80006184:	f7040593          	addi	a1,s0,-144
    80006188:	4501                	li	a0,0
    8000618a:	ecafc0ef          	jal	80002854 <argstr>
    8000618e:	02054363          	bltz	a0,800061b4 <sys_mkdir+0x58>
    80006192:	4681                	li	a3,0
    80006194:	4601                	li	a2,0
    80006196:	4585                	li	a1,1
    80006198:	f7040513          	addi	a0,s0,-144
    8000619c:	827ff0ef          	jal	800059c2 <create>
    800061a0:	c911                	beqz	a0,800061b4 <sys_mkdir+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061a2:	a23fd0ef          	jal	80003bc4 <iunlockput>
  end_op();
    800061a6:	f0efe0ef          	jal	800048b4 <end_op>
  return 0;
    800061aa:	4501                	li	a0,0
}
    800061ac:	60aa                	ld	ra,136(sp)
    800061ae:	640a                	ld	s0,128(sp)
    800061b0:	6149                	addi	sp,sp,144
    800061b2:	8082                	ret
    end_op();
    800061b4:	f00fe0ef          	jal	800048b4 <end_op>
    return -1;
    800061b8:	557d                	li	a0,-1
    800061ba:	bfcd                	j	800061ac <sys_mkdir+0x50>

00000000800061bc <sys_mknod>:

uint64
sys_mknod(void)
{
    800061bc:	7135                	addi	sp,sp,-160
    800061be:	ed06                	sd	ra,152(sp)
    800061c0:	e922                	sd	s0,144(sp)
    800061c2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800061c4:	dd2fe0ef          	jal	80004796 <begin_op>
  argint(1, &major);
    800061c8:	f6c40593          	addi	a1,s0,-148
    800061cc:	4505                	li	a0,1
    800061ce:	e4efc0ef          	jal	8000281c <argint>
  argint(2, &minor);
    800061d2:	f6840593          	addi	a1,s0,-152
    800061d6:	4509                	li	a0,2
    800061d8:	e44fc0ef          	jal	8000281c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061dc:	08000613          	li	a2,128
    800061e0:	f7040593          	addi	a1,s0,-144
    800061e4:	4501                	li	a0,0
    800061e6:	e6efc0ef          	jal	80002854 <argstr>
    800061ea:	02054563          	bltz	a0,80006214 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800061ee:	f6841683          	lh	a3,-152(s0)
    800061f2:	f6c41603          	lh	a2,-148(s0)
    800061f6:	458d                	li	a1,3
    800061f8:	f7040513          	addi	a0,s0,-144
    800061fc:	fc6ff0ef          	jal	800059c2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006200:	c911                	beqz	a0,80006214 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006202:	9c3fd0ef          	jal	80003bc4 <iunlockput>
  end_op();
    80006206:	eaefe0ef          	jal	800048b4 <end_op>
  return 0;
    8000620a:	4501                	li	a0,0
}
    8000620c:	60ea                	ld	ra,152(sp)
    8000620e:	644a                	ld	s0,144(sp)
    80006210:	610d                	addi	sp,sp,160
    80006212:	8082                	ret
    end_op();
    80006214:	ea0fe0ef          	jal	800048b4 <end_op>
    return -1;
    80006218:	557d                	li	a0,-1
    8000621a:	bfcd                	j	8000620c <sys_mknod+0x50>

000000008000621c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000621c:	7135                	addi	sp,sp,-160
    8000621e:	ed06                	sd	ra,152(sp)
    80006220:	e922                	sd	s0,144(sp)
    80006222:	e14a                	sd	s2,128(sp)
    80006224:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006226:	ee2fb0ef          	jal	80001908 <myproc>
    8000622a:	892a                	mv	s2,a0
  
  safestrcpy(myproc()->current_syscall,
    8000622c:	edcfb0ef          	jal	80001908 <myproc>
    80006230:	02000613          	li	a2,32
    80006234:	00004597          	auipc	a1,0x4
    80006238:	bcc58593          	addi	a1,a1,-1076 # 80009e00 <etext+0xe00>
    8000623c:	16850513          	addi	a0,a0,360
    80006240:	bd3fa0ef          	jal	80000e12 <safestrcpy>
             "CHDIR",
             sizeof(myproc()->current_syscall));
  begin_op();
    80006244:	d52fe0ef          	jal	80004796 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006248:	08000613          	li	a2,128
    8000624c:	f6040593          	addi	a1,s0,-160
    80006250:	4501                	li	a0,0
    80006252:	e02fc0ef          	jal	80002854 <argstr>
    80006256:	04054363          	bltz	a0,8000629c <sys_chdir+0x80>
    8000625a:	e526                	sd	s1,136(sp)
    8000625c:	f6040513          	addi	a0,s0,-160
    80006260:	8ecfe0ef          	jal	8000434c <namei>
    80006264:	84aa                	mv	s1,a0
    80006266:	c915                	beqz	a0,8000629a <sys_chdir+0x7e>
    end_op();
    return -1;
  }
  ilock(ip);
    80006268:	e80fd0ef          	jal	800038e8 <ilock>
  if(ip->type != T_DIR){
    8000626c:	04449703          	lh	a4,68(s1)
    80006270:	4785                	li	a5,1
    80006272:	02f71963          	bne	a4,a5,800062a4 <sys_chdir+0x88>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006276:	8526                	mv	a0,s1
    80006278:	f62fd0ef          	jal	800039da <iunlock>
  
  // 🔥 تصحيح: يجب بقاء الحذف البرمجي للـ cwd القديم داخل نطاق الـ FS Transaction
  iput(p->cwd);
    8000627c:	15093503          	ld	a0,336(s2)
    80006280:	879fd0ef          	jal	80003af8 <iput>
  p->cwd = ip;
    80006284:	14993823          	sd	s1,336(s2)
  end_op();
    80006288:	e2cfe0ef          	jal	800048b4 <end_op>
  
  return 0;
    8000628c:	4501                	li	a0,0
    8000628e:	64aa                	ld	s1,136(sp)
}
    80006290:	60ea                	ld	ra,152(sp)
    80006292:	644a                	ld	s0,144(sp)
    80006294:	690a                	ld	s2,128(sp)
    80006296:	610d                	addi	sp,sp,160
    80006298:	8082                	ret
    8000629a:	64aa                	ld	s1,136(sp)
    end_op();
    8000629c:	e18fe0ef          	jal	800048b4 <end_op>
    return -1;
    800062a0:	557d                	li	a0,-1
    800062a2:	b7fd                	j	80006290 <sys_chdir+0x74>
    iunlockput(ip);
    800062a4:	8526                	mv	a0,s1
    800062a6:	91ffd0ef          	jal	80003bc4 <iunlockput>
    end_op();
    800062aa:	e0afe0ef          	jal	800048b4 <end_op>
    return -1;
    800062ae:	557d                	li	a0,-1
    800062b0:	64aa                	ld	s1,136(sp)
    800062b2:	bff9                	j	80006290 <sys_chdir+0x74>

00000000800062b4 <sys_exec>:

uint64
sys_exec(void)
{
    800062b4:	7121                	addi	sp,sp,-448
    800062b6:	ff06                	sd	ra,440(sp)
    800062b8:	fb22                	sd	s0,432(sp)
    800062ba:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800062bc:	e4840593          	addi	a1,s0,-440
    800062c0:	4505                	li	a0,1
    800062c2:	d76fc0ef          	jal	80002838 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800062c6:	08000613          	li	a2,128
    800062ca:	f5040593          	addi	a1,s0,-176
    800062ce:	4501                	li	a0,0
    800062d0:	d84fc0ef          	jal	80002854 <argstr>
    800062d4:	87aa                	mv	a5,a0
    return -1;
    800062d6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800062d8:	0c07c463          	bltz	a5,800063a0 <sys_exec+0xec>
    800062dc:	f726                	sd	s1,424(sp)
    800062de:	f34a                	sd	s2,416(sp)
    800062e0:	ef4e                	sd	s3,408(sp)
    800062e2:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800062e4:	10000613          	li	a2,256
    800062e8:	4581                	li	a1,0
    800062ea:	e5040513          	addi	a0,s0,-432
    800062ee:	9e7fa0ef          	jal	80000cd4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062f2:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800062f6:	89a6                	mv	s3,s1
    800062f8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062fa:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062fe:	00391513          	slli	a0,s2,0x3
    80006302:	e4040593          	addi	a1,s0,-448
    80006306:	e4843783          	ld	a5,-440(s0)
    8000630a:	953e                	add	a0,a0,a5
    8000630c:	c86fc0ef          	jal	80002792 <fetchaddr>
    80006310:	02054663          	bltz	a0,8000633c <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80006314:	e4043783          	ld	a5,-448(s0)
    80006318:	c3a9                	beqz	a5,8000635a <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000631a:	817fa0ef          	jal	80000b30 <kalloc>
    8000631e:	85aa                	mv	a1,a0
    80006320:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006324:	cd01                	beqz	a0,8000633c <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006326:	6605                	lui	a2,0x1
    80006328:	e4043503          	ld	a0,-448(s0)
    8000632c:	cb0fc0ef          	jal	800027dc <fetchstr>
    80006330:	00054663          	bltz	a0,8000633c <sys_exec+0x88>
    if(i >= NELEM(argv)){
    80006334:	0905                	addi	s2,s2,1
    80006336:	09a1                	addi	s3,s3,8
    80006338:	fd4913e3          	bne	s2,s4,800062fe <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++) {
    8000633c:	f5040913          	addi	s2,s0,-176
    80006340:	6088                	ld	a0,0(s1)
    80006342:	c931                	beqz	a0,80006396 <sys_exec+0xe2>
    if(argv[i] != 0)
      kfree(argv[i]);
    80006344:	f0afa0ef          	jal	80000a4e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++) {
    80006348:	04a1                	addi	s1,s1,8
    8000634a:	ff249be3          	bne	s1,s2,80006340 <sys_exec+0x8c>
  }
  return -1;
    8000634e:	557d                	li	a0,-1
    80006350:	74ba                	ld	s1,424(sp)
    80006352:	791a                	ld	s2,416(sp)
    80006354:	69fa                	ld	s3,408(sp)
    80006356:	6a5a                	ld	s4,400(sp)
    80006358:	a0a1                	j	800063a0 <sys_exec+0xec>
      argv[i] = 0;
    8000635a:	0009079b          	sext.w	a5,s2
    8000635e:	078e                	slli	a5,a5,0x3
    80006360:	fd078793          	addi	a5,a5,-48
    80006364:	97a2                	add	a5,a5,s0
    80006366:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    8000636a:	e5040593          	addi	a1,s0,-432
    8000636e:	f5040513          	addi	a0,s0,-176
    80006372:	a48ff0ef          	jal	800055ba <kexec>
    80006376:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006378:	f5040993          	addi	s3,s0,-176
    8000637c:	6088                	ld	a0,0(s1)
    8000637e:	c511                	beqz	a0,8000638a <sys_exec+0xd6>
    kfree(argv[i]);
    80006380:	ecefa0ef          	jal	80000a4e <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006384:	04a1                	addi	s1,s1,8
    80006386:	ff349be3          	bne	s1,s3,8000637c <sys_exec+0xc8>
  return ret;
    8000638a:	854a                	mv	a0,s2
    8000638c:	74ba                	ld	s1,424(sp)
    8000638e:	791a                	ld	s2,416(sp)
    80006390:	69fa                	ld	s3,408(sp)
    80006392:	6a5a                	ld	s4,400(sp)
    80006394:	a031                	j	800063a0 <sys_exec+0xec>
  return -1;
    80006396:	557d                	li	a0,-1
    80006398:	74ba                	ld	s1,424(sp)
    8000639a:	791a                	ld	s2,416(sp)
    8000639c:	69fa                	ld	s3,408(sp)
    8000639e:	6a5a                	ld	s4,400(sp)
}
    800063a0:	70fa                	ld	ra,440(sp)
    800063a2:	745a                	ld	s0,432(sp)
    800063a4:	6139                	addi	sp,sp,448
    800063a6:	8082                	ret

00000000800063a8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800063a8:	7139                	addi	sp,sp,-64
    800063aa:	fc06                	sd	ra,56(sp)
    800063ac:	f822                	sd	s0,48(sp)
    800063ae:	f426                	sd	s1,40(sp)
    800063b0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800063b2:	d56fb0ef          	jal	80001908 <myproc>
    800063b6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800063b8:	fd840593          	addi	a1,s0,-40
    800063bc:	4501                	li	a0,0
    800063be:	c7afc0ef          	jal	80002838 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800063c2:	fc840593          	addi	a1,s0,-56
    800063c6:	fd040513          	addi	a0,s0,-48
    800063ca:	ef3fe0ef          	jal	800052bc <pipealloc>
    return -1;
    800063ce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063d0:	0a054463          	bltz	a0,80006478 <sys_pipe+0xd0>
  fd0 = -1;
    800063d4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063d8:	fd043503          	ld	a0,-48(s0)
    800063dc:	d50ff0ef          	jal	8000592c <fdalloc>
    800063e0:	fca42223          	sw	a0,-60(s0)
    800063e4:	08054163          	bltz	a0,80006466 <sys_pipe+0xbe>
    800063e8:	fc843503          	ld	a0,-56(s0)
    800063ec:	d40ff0ef          	jal	8000592c <fdalloc>
    800063f0:	fca42023          	sw	a0,-64(s0)
    800063f4:	06054063          	bltz	a0,80006454 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063f8:	4691                	li	a3,4
    800063fa:	fc440613          	addi	a2,s0,-60
    800063fe:	fd843583          	ld	a1,-40(s0)
    80006402:	68a8                	ld	a0,80(s1)
    80006404:	a18fb0ef          	jal	8000161c <copyout>
    80006408:	00054e63          	bltz	a0,80006424 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000640c:	4691                	li	a3,4
    8000640e:	fc040613          	addi	a2,s0,-64
    80006412:	fd843583          	ld	a1,-40(s0)
    80006416:	0591                	addi	a1,a1,4
    80006418:	68a8                	ld	a0,80(s1)
    8000641a:	a02fb0ef          	jal	8000161c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000641e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006420:	04055c63          	bgez	a0,80006478 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80006424:	fc442783          	lw	a5,-60(s0)
    80006428:	07e9                	addi	a5,a5,26
    8000642a:	078e                	slli	a5,a5,0x3
    8000642c:	97a6                	add	a5,a5,s1
    8000642e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006432:	fc042783          	lw	a5,-64(s0)
    80006436:	07e9                	addi	a5,a5,26
    80006438:	078e                	slli	a5,a5,0x3
    8000643a:	94be                	add	s1,s1,a5
    8000643c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006440:	fd043503          	ld	a0,-48(s0)
    80006444:	addfe0ef          	jal	80004f20 <fileclose>
    fileclose(wf);
    80006448:	fc843503          	ld	a0,-56(s0)
    8000644c:	ad5fe0ef          	jal	80004f20 <fileclose>
    return -1;
    80006450:	57fd                	li	a5,-1
    80006452:	a01d                	j	80006478 <sys_pipe+0xd0>
    if(fd0 >= 0)
    80006454:	fc442783          	lw	a5,-60(s0)
    80006458:	0007c763          	bltz	a5,80006466 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000645c:	07e9                	addi	a5,a5,26
    8000645e:	078e                	slli	a5,a5,0x3
    80006460:	97a6                	add	a5,a5,s1
    80006462:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006466:	fd043503          	ld	a0,-48(s0)
    8000646a:	ab7fe0ef          	jal	80004f20 <fileclose>
    fileclose(wf);
    8000646e:	fc843503          	ld	a0,-56(s0)
    80006472:	aaffe0ef          	jal	80004f20 <fileclose>
    return -1;
    80006476:	57fd                	li	a5,-1
}
    80006478:	853e                	mv	a0,a5
    8000647a:	70e2                	ld	ra,56(sp)
    8000647c:	7442                	ld	s0,48(sp)
    8000647e:	74a2                	ld	s1,40(sp)
    80006480:	6121                	addi	sp,sp,64
    80006482:	8082                	ret

0000000080006484 <sys_fsread>:

uint64
sys_fsread(void)
{
    80006484:	1101                	addi	sp,sp,-32
    80006486:	ec06                	sd	ra,24(sp)
    80006488:	e822                	sd	s0,16(sp)
    8000648a:	1000                	addi	s0,sp,32
  uint64 uaddr;
  int max;

  argaddr(0, &uaddr);   
    8000648c:	fe840593          	addi	a1,s0,-24
    80006490:	4501                	li	a0,0
    80006492:	ba6fc0ef          	jal	80002838 <argaddr>
  argint(1, &max);      
    80006496:	fe440593          	addi	a1,s0,-28
    8000649a:	4505                	li	a0,1
    8000649c:	b80fc0ef          	jal	8000281c <argint>

  return fslog_read_many((struct fs_event *)uaddr, max);
    800064a0:	fe442583          	lw	a1,-28(s0)
    800064a4:	fe843503          	ld	a0,-24(s0)
    800064a8:	1e3000ef          	jal	80006e8a <fslog_read_many>
    800064ac:	60e2                	ld	ra,24(sp)
    800064ae:	6442                	ld	s0,16(sp)
    800064b0:	6105                	addi	sp,sp,32
    800064b2:	8082                	ret
	...

00000000800064c0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800064c0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800064c2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800064c4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800064c6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800064c8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800064ca:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800064cc:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800064ce:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800064d0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800064d2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800064d4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800064d6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800064d8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800064da:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800064dc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800064de:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800064e0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800064e2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800064e4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800064e6:	9bcfc0ef          	jal	800026a2 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800064ea:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800064ec:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800064ee:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800064f0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800064f2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800064f4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800064f6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800064f8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800064fa:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800064fc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800064fe:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80006500:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80006502:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80006504:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80006506:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80006508:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000650a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000650c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000650e:	10200073          	sret
	...

000000008000651e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000651e:	1141                	addi	sp,sp,-16
    80006520:	e422                	sd	s0,8(sp)
    80006522:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006524:	0c0007b7          	lui	a5,0xc000
    80006528:	4705                	li	a4,1
    8000652a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000652c:	0c0007b7          	lui	a5,0xc000
    80006530:	c3d8                	sw	a4,4(a5)
}
    80006532:	6422                	ld	s0,8(sp)
    80006534:	0141                	addi	sp,sp,16
    80006536:	8082                	ret

0000000080006538 <plicinithart>:

void
plicinithart(void)
{
    80006538:	1141                	addi	sp,sp,-16
    8000653a:	e406                	sd	ra,8(sp)
    8000653c:	e022                	sd	s0,0(sp)
    8000653e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006540:	b9cfb0ef          	jal	800018dc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006544:	0085171b          	slliw	a4,a0,0x8
    80006548:	0c0027b7          	lui	a5,0xc002
    8000654c:	97ba                	add	a5,a5,a4
    8000654e:	40200713          	li	a4,1026
    80006552:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006556:	00d5151b          	slliw	a0,a0,0xd
    8000655a:	0c2017b7          	lui	a5,0xc201
    8000655e:	97aa                	add	a5,a5,a0
    80006560:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006564:	60a2                	ld	ra,8(sp)
    80006566:	6402                	ld	s0,0(sp)
    80006568:	0141                	addi	sp,sp,16
    8000656a:	8082                	ret

000000008000656c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000656c:	1141                	addi	sp,sp,-16
    8000656e:	e406                	sd	ra,8(sp)
    80006570:	e022                	sd	s0,0(sp)
    80006572:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006574:	b68fb0ef          	jal	800018dc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006578:	00d5151b          	slliw	a0,a0,0xd
    8000657c:	0c2017b7          	lui	a5,0xc201
    80006580:	97aa                	add	a5,a5,a0
  return irq;
}
    80006582:	43c8                	lw	a0,4(a5)
    80006584:	60a2                	ld	ra,8(sp)
    80006586:	6402                	ld	s0,0(sp)
    80006588:	0141                	addi	sp,sp,16
    8000658a:	8082                	ret

000000008000658c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000658c:	1101                	addi	sp,sp,-32
    8000658e:	ec06                	sd	ra,24(sp)
    80006590:	e822                	sd	s0,16(sp)
    80006592:	e426                	sd	s1,8(sp)
    80006594:	1000                	addi	s0,sp,32
    80006596:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006598:	b44fb0ef          	jal	800018dc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000659c:	00d5151b          	slliw	a0,a0,0xd
    800065a0:	0c2017b7          	lui	a5,0xc201
    800065a4:	97aa                	add	a5,a5,a0
    800065a6:	c3c4                	sw	s1,4(a5)
}
    800065a8:	60e2                	ld	ra,24(sp)
    800065aa:	6442                	ld	s0,16(sp)
    800065ac:	64a2                	ld	s1,8(sp)
    800065ae:	6105                	addi	sp,sp,32
    800065b0:	8082                	ret

00000000800065b2 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065b2:	1141                	addi	sp,sp,-16
    800065b4:	e406                	sd	ra,8(sp)
    800065b6:	e022                	sd	s0,0(sp)
    800065b8:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065ba:	479d                	li	a5,7
    800065bc:	04a7ca63          	blt	a5,a0,80006610 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    800065c0:	00020797          	auipc	a5,0x20
    800065c4:	70878793          	addi	a5,a5,1800 # 80026cc8 <disk>
    800065c8:	97aa                	add	a5,a5,a0
    800065ca:	0187c783          	lbu	a5,24(a5)
    800065ce:	e7b9                	bnez	a5,8000661c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800065d0:	00451693          	slli	a3,a0,0x4
    800065d4:	00020797          	auipc	a5,0x20
    800065d8:	6f478793          	addi	a5,a5,1780 # 80026cc8 <disk>
    800065dc:	6398                	ld	a4,0(a5)
    800065de:	9736                	add	a4,a4,a3
    800065e0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800065e4:	6398                	ld	a4,0(a5)
    800065e6:	9736                	add	a4,a4,a3
    800065e8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800065ec:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800065f0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800065f4:	97aa                	add	a5,a5,a0
    800065f6:	4705                	li	a4,1
    800065f8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800065fc:	00020517          	auipc	a0,0x20
    80006600:	6e450513          	addi	a0,a0,1764 # 80026ce0 <disk+0x18>
    80006604:	961fb0ef          	jal	80001f64 <wakeup>
}
    80006608:	60a2                	ld	ra,8(sp)
    8000660a:	6402                	ld	s0,0(sp)
    8000660c:	0141                	addi	sp,sp,16
    8000660e:	8082                	ret
    panic("free_desc 1");
    80006610:	00003517          	auipc	a0,0x3
    80006614:	7f850513          	addi	a0,a0,2040 # 80009e08 <etext+0xe08>
    80006618:	9fafa0ef          	jal	80000812 <panic>
    panic("free_desc 2");
    8000661c:	00003517          	auipc	a0,0x3
    80006620:	7fc50513          	addi	a0,a0,2044 # 80009e18 <etext+0xe18>
    80006624:	9eefa0ef          	jal	80000812 <panic>

0000000080006628 <virtio_disk_init>:
{
    80006628:	1101                	addi	sp,sp,-32
    8000662a:	ec06                	sd	ra,24(sp)
    8000662c:	e822                	sd	s0,16(sp)
    8000662e:	e426                	sd	s1,8(sp)
    80006630:	e04a                	sd	s2,0(sp)
    80006632:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006634:	00003597          	auipc	a1,0x3
    80006638:	7f458593          	addi	a1,a1,2036 # 80009e28 <etext+0xe28>
    8000663c:	00020517          	auipc	a0,0x20
    80006640:	7b450513          	addi	a0,a0,1972 # 80026df0 <disk+0x128>
    80006644:	d3cfa0ef          	jal	80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006648:	100017b7          	lui	a5,0x10001
    8000664c:	4398                	lw	a4,0(a5)
    8000664e:	2701                	sext.w	a4,a4
    80006650:	747277b7          	lui	a5,0x74727
    80006654:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006658:	18f71063          	bne	a4,a5,800067d8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000665c:	100017b7          	lui	a5,0x10001
    80006660:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80006662:	439c                	lw	a5,0(a5)
    80006664:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006666:	4709                	li	a4,2
    80006668:	16e79863          	bne	a5,a4,800067d8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000666c:	100017b7          	lui	a5,0x10001
    80006670:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80006672:	439c                	lw	a5,0(a5)
    80006674:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006676:	16e79163          	bne	a5,a4,800067d8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000667a:	100017b7          	lui	a5,0x10001
    8000667e:	47d8                	lw	a4,12(a5)
    80006680:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006682:	554d47b7          	lui	a5,0x554d4
    80006686:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000668a:	14f71763          	bne	a4,a5,800067d8 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000668e:	100017b7          	lui	a5,0x10001
    80006692:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006696:	4705                	li	a4,1
    80006698:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000669a:	470d                	li	a4,3
    8000669c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000669e:	10001737          	lui	a4,0x10001
    800066a2:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066a4:	c7ffe737          	lui	a4,0xc7ffe
    800066a8:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47f978f7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800066ac:	8ef9                	and	a3,a3,a4
    800066ae:	10001737          	lui	a4,0x10001
    800066b2:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066b4:	472d                	li	a4,11
    800066b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066b8:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800066bc:	439c                	lw	a5,0(a5)
    800066be:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800066c2:	8ba1                	andi	a5,a5,8
    800066c4:	12078063          	beqz	a5,800067e4 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800066c8:	100017b7          	lui	a5,0x10001
    800066cc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800066d0:	100017b7          	lui	a5,0x10001
    800066d4:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800066d8:	439c                	lw	a5,0(a5)
    800066da:	2781                	sext.w	a5,a5
    800066dc:	10079a63          	bnez	a5,800067f0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800066e0:	100017b7          	lui	a5,0x10001
    800066e4:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800066e8:	439c                	lw	a5,0(a5)
    800066ea:	2781                	sext.w	a5,a5
  if(max == 0)
    800066ec:	10078863          	beqz	a5,800067fc <virtio_disk_init+0x1d4>
  if(max < NUM)
    800066f0:	471d                	li	a4,7
    800066f2:	10f77b63          	bgeu	a4,a5,80006808 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800066f6:	c3afa0ef          	jal	80000b30 <kalloc>
    800066fa:	00020497          	auipc	s1,0x20
    800066fe:	5ce48493          	addi	s1,s1,1486 # 80026cc8 <disk>
    80006702:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006704:	c2cfa0ef          	jal	80000b30 <kalloc>
    80006708:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000670a:	c26fa0ef          	jal	80000b30 <kalloc>
    8000670e:	87aa                	mv	a5,a0
    80006710:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006712:	6088                	ld	a0,0(s1)
    80006714:	10050063          	beqz	a0,80006814 <virtio_disk_init+0x1ec>
    80006718:	00020717          	auipc	a4,0x20
    8000671c:	5b873703          	ld	a4,1464(a4) # 80026cd0 <disk+0x8>
    80006720:	0e070a63          	beqz	a4,80006814 <virtio_disk_init+0x1ec>
    80006724:	0e078863          	beqz	a5,80006814 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80006728:	6605                	lui	a2,0x1
    8000672a:	4581                	li	a1,0
    8000672c:	da8fa0ef          	jal	80000cd4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006730:	00020497          	auipc	s1,0x20
    80006734:	59848493          	addi	s1,s1,1432 # 80026cc8 <disk>
    80006738:	6605                	lui	a2,0x1
    8000673a:	4581                	li	a1,0
    8000673c:	6488                	ld	a0,8(s1)
    8000673e:	d96fa0ef          	jal	80000cd4 <memset>
  memset(disk.used, 0, PGSIZE);
    80006742:	6605                	lui	a2,0x1
    80006744:	4581                	li	a1,0
    80006746:	6888                	ld	a0,16(s1)
    80006748:	d8cfa0ef          	jal	80000cd4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000674c:	100017b7          	lui	a5,0x10001
    80006750:	4721                	li	a4,8
    80006752:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006754:	4098                	lw	a4,0(s1)
    80006756:	100017b7          	lui	a5,0x10001
    8000675a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000675e:	40d8                	lw	a4,4(s1)
    80006760:	100017b7          	lui	a5,0x10001
    80006764:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006768:	649c                	ld	a5,8(s1)
    8000676a:	0007869b          	sext.w	a3,a5
    8000676e:	10001737          	lui	a4,0x10001
    80006772:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006776:	9781                	srai	a5,a5,0x20
    80006778:	10001737          	lui	a4,0x10001
    8000677c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006780:	689c                	ld	a5,16(s1)
    80006782:	0007869b          	sext.w	a3,a5
    80006786:	10001737          	lui	a4,0x10001
    8000678a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000678e:	9781                	srai	a5,a5,0x20
    80006790:	10001737          	lui	a4,0x10001
    80006794:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006798:	10001737          	lui	a4,0x10001
    8000679c:	4785                	li	a5,1
    8000679e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    800067a0:	00f48c23          	sb	a5,24(s1)
    800067a4:	00f48ca3          	sb	a5,25(s1)
    800067a8:	00f48d23          	sb	a5,26(s1)
    800067ac:	00f48da3          	sb	a5,27(s1)
    800067b0:	00f48e23          	sb	a5,28(s1)
    800067b4:	00f48ea3          	sb	a5,29(s1)
    800067b8:	00f48f23          	sb	a5,30(s1)
    800067bc:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800067c0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800067c4:	100017b7          	lui	a5,0x10001
    800067c8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800067cc:	60e2                	ld	ra,24(sp)
    800067ce:	6442                	ld	s0,16(sp)
    800067d0:	64a2                	ld	s1,8(sp)
    800067d2:	6902                	ld	s2,0(sp)
    800067d4:	6105                	addi	sp,sp,32
    800067d6:	8082                	ret
    panic("could not find virtio disk");
    800067d8:	00003517          	auipc	a0,0x3
    800067dc:	66050513          	addi	a0,a0,1632 # 80009e38 <etext+0xe38>
    800067e0:	832fa0ef          	jal	80000812 <panic>
    panic("virtio disk FEATURES_OK unset");
    800067e4:	00003517          	auipc	a0,0x3
    800067e8:	67450513          	addi	a0,a0,1652 # 80009e58 <etext+0xe58>
    800067ec:	826fa0ef          	jal	80000812 <panic>
    panic("virtio disk should not be ready");
    800067f0:	00003517          	auipc	a0,0x3
    800067f4:	68850513          	addi	a0,a0,1672 # 80009e78 <etext+0xe78>
    800067f8:	81afa0ef          	jal	80000812 <panic>
    panic("virtio disk has no queue 0");
    800067fc:	00003517          	auipc	a0,0x3
    80006800:	69c50513          	addi	a0,a0,1692 # 80009e98 <etext+0xe98>
    80006804:	80efa0ef          	jal	80000812 <panic>
    panic("virtio disk max queue too short");
    80006808:	00003517          	auipc	a0,0x3
    8000680c:	6b050513          	addi	a0,a0,1712 # 80009eb8 <etext+0xeb8>
    80006810:	802fa0ef          	jal	80000812 <panic>
    panic("virtio disk kalloc");
    80006814:	00003517          	auipc	a0,0x3
    80006818:	6c450513          	addi	a0,a0,1732 # 80009ed8 <etext+0xed8>
    8000681c:	ff7f90ef          	jal	80000812 <panic>

0000000080006820 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006820:	7159                	addi	sp,sp,-112
    80006822:	f486                	sd	ra,104(sp)
    80006824:	f0a2                	sd	s0,96(sp)
    80006826:	eca6                	sd	s1,88(sp)
    80006828:	e8ca                	sd	s2,80(sp)
    8000682a:	e4ce                	sd	s3,72(sp)
    8000682c:	e0d2                	sd	s4,64(sp)
    8000682e:	fc56                	sd	s5,56(sp)
    80006830:	f85a                	sd	s6,48(sp)
    80006832:	f45e                	sd	s7,40(sp)
    80006834:	f062                	sd	s8,32(sp)
    80006836:	ec66                	sd	s9,24(sp)
    80006838:	1880                	addi	s0,sp,112
    8000683a:	8a2a                	mv	s4,a0
    8000683c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000683e:	00c52c83          	lw	s9,12(a0)
    80006842:	001c9c9b          	slliw	s9,s9,0x1
    80006846:	1c82                	slli	s9,s9,0x20
    80006848:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000684c:	00020517          	auipc	a0,0x20
    80006850:	5a450513          	addi	a0,a0,1444 # 80026df0 <disk+0x128>
    80006854:	bacfa0ef          	jal	80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80006858:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000685a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000685c:	00020b17          	auipc	s6,0x20
    80006860:	46cb0b13          	addi	s6,s6,1132 # 80026cc8 <disk>
  for(int i = 0; i < 3; i++){
    80006864:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006866:	00020c17          	auipc	s8,0x20
    8000686a:	58ac0c13          	addi	s8,s8,1418 # 80026df0 <disk+0x128>
    8000686e:	a8b9                	j	800068cc <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80006870:	00fb0733          	add	a4,s6,a5
    80006874:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006878:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000687a:	0207c563          	bltz	a5,800068a4 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    8000687e:	2905                	addiw	s2,s2,1
    80006880:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006882:	05590963          	beq	s2,s5,800068d4 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80006886:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006888:	00020717          	auipc	a4,0x20
    8000688c:	44070713          	addi	a4,a4,1088 # 80026cc8 <disk>
    80006890:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006892:	01874683          	lbu	a3,24(a4)
    80006896:	fee9                	bnez	a3,80006870 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80006898:	2785                	addiw	a5,a5,1
    8000689a:	0705                	addi	a4,a4,1
    8000689c:	fe979be3          	bne	a5,s1,80006892 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    800068a0:	57fd                	li	a5,-1
    800068a2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800068a4:	01205d63          	blez	s2,800068be <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    800068a8:	f9042503          	lw	a0,-112(s0)
    800068ac:	d07ff0ef          	jal	800065b2 <free_desc>
      for(int j = 0; j < i; j++)
    800068b0:	4785                	li	a5,1
    800068b2:	0127d663          	bge	a5,s2,800068be <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    800068b6:	f9442503          	lw	a0,-108(s0)
    800068ba:	cf9ff0ef          	jal	800065b2 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068be:	85e2                	mv	a1,s8
    800068c0:	00020517          	auipc	a0,0x20
    800068c4:	42050513          	addi	a0,a0,1056 # 80026ce0 <disk+0x18>
    800068c8:	e50fb0ef          	jal	80001f18 <sleep>
  for(int i = 0; i < 3; i++){
    800068cc:	f9040613          	addi	a2,s0,-112
    800068d0:	894e                	mv	s2,s3
    800068d2:	bf55                	j	80006886 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068d4:	f9042503          	lw	a0,-112(s0)
    800068d8:	00451693          	slli	a3,a0,0x4

  if(write)
    800068dc:	00020797          	auipc	a5,0x20
    800068e0:	3ec78793          	addi	a5,a5,1004 # 80026cc8 <disk>
    800068e4:	00a50713          	addi	a4,a0,10
    800068e8:	0712                	slli	a4,a4,0x4
    800068ea:	973e                	add	a4,a4,a5
    800068ec:	01703633          	snez	a2,s7
    800068f0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068f2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800068f6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068fa:	6398                	ld	a4,0(a5)
    800068fc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068fe:	0a868613          	addi	a2,a3,168
    80006902:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006904:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006906:	6390                	ld	a2,0(a5)
    80006908:	00d605b3          	add	a1,a2,a3
    8000690c:	4741                	li	a4,16
    8000690e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006910:	4805                	li	a6,1
    80006912:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80006916:	f9442703          	lw	a4,-108(s0)
    8000691a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000691e:	0712                	slli	a4,a4,0x4
    80006920:	963a                	add	a2,a2,a4
    80006922:	058a0593          	addi	a1,s4,88
    80006926:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006928:	0007b883          	ld	a7,0(a5)
    8000692c:	9746                	add	a4,a4,a7
    8000692e:	40000613          	li	a2,1024
    80006932:	c710                	sw	a2,8(a4)
  if(write)
    80006934:	001bb613          	seqz	a2,s7
    80006938:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000693c:	00166613          	ori	a2,a2,1
    80006940:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006944:	f9842583          	lw	a1,-104(s0)
    80006948:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000694c:	00250613          	addi	a2,a0,2
    80006950:	0612                	slli	a2,a2,0x4
    80006952:	963e                	add	a2,a2,a5
    80006954:	577d                	li	a4,-1
    80006956:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000695a:	0592                	slli	a1,a1,0x4
    8000695c:	98ae                	add	a7,a7,a1
    8000695e:	03068713          	addi	a4,a3,48
    80006962:	973e                	add	a4,a4,a5
    80006964:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006968:	6398                	ld	a4,0(a5)
    8000696a:	972e                	add	a4,a4,a1
    8000696c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006970:	4689                	li	a3,2
    80006972:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80006976:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000697a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    8000697e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006982:	6794                	ld	a3,8(a5)
    80006984:	0026d703          	lhu	a4,2(a3)
    80006988:	8b1d                	andi	a4,a4,7
    8000698a:	0706                	slli	a4,a4,0x1
    8000698c:	96ba                	add	a3,a3,a4
    8000698e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006992:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006996:	6798                	ld	a4,8(a5)
    80006998:	00275783          	lhu	a5,2(a4)
    8000699c:	2785                	addiw	a5,a5,1
    8000699e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069a2:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069a6:	100017b7          	lui	a5,0x10001
    800069aa:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800069ae:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800069b2:	00020917          	auipc	s2,0x20
    800069b6:	43e90913          	addi	s2,s2,1086 # 80026df0 <disk+0x128>
  while(b->disk == 1) {
    800069ba:	4485                	li	s1,1
    800069bc:	01079a63          	bne	a5,a6,800069d0 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    800069c0:	85ca                	mv	a1,s2
    800069c2:	8552                	mv	a0,s4
    800069c4:	d54fb0ef          	jal	80001f18 <sleep>
  while(b->disk == 1) {
    800069c8:	004a2783          	lw	a5,4(s4)
    800069cc:	fe978ae3          	beq	a5,s1,800069c0 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    800069d0:	f9042903          	lw	s2,-112(s0)
    800069d4:	00290713          	addi	a4,s2,2
    800069d8:	0712                	slli	a4,a4,0x4
    800069da:	00020797          	auipc	a5,0x20
    800069de:	2ee78793          	addi	a5,a5,750 # 80026cc8 <disk>
    800069e2:	97ba                	add	a5,a5,a4
    800069e4:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800069e8:	00020997          	auipc	s3,0x20
    800069ec:	2e098993          	addi	s3,s3,736 # 80026cc8 <disk>
    800069f0:	00491713          	slli	a4,s2,0x4
    800069f4:	0009b783          	ld	a5,0(s3)
    800069f8:	97ba                	add	a5,a5,a4
    800069fa:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800069fe:	854a                	mv	a0,s2
    80006a00:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a04:	bafff0ef          	jal	800065b2 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a08:	8885                	andi	s1,s1,1
    80006a0a:	f0fd                	bnez	s1,800069f0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a0c:	00020517          	auipc	a0,0x20
    80006a10:	3e450513          	addi	a0,a0,996 # 80026df0 <disk+0x128>
    80006a14:	a84fa0ef          	jal	80000c98 <release>
}
    80006a18:	70a6                	ld	ra,104(sp)
    80006a1a:	7406                	ld	s0,96(sp)
    80006a1c:	64e6                	ld	s1,88(sp)
    80006a1e:	6946                	ld	s2,80(sp)
    80006a20:	69a6                	ld	s3,72(sp)
    80006a22:	6a06                	ld	s4,64(sp)
    80006a24:	7ae2                	ld	s5,56(sp)
    80006a26:	7b42                	ld	s6,48(sp)
    80006a28:	7ba2                	ld	s7,40(sp)
    80006a2a:	7c02                	ld	s8,32(sp)
    80006a2c:	6ce2                	ld	s9,24(sp)
    80006a2e:	6165                	addi	sp,sp,112
    80006a30:	8082                	ret

0000000080006a32 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a32:	1101                	addi	sp,sp,-32
    80006a34:	ec06                	sd	ra,24(sp)
    80006a36:	e822                	sd	s0,16(sp)
    80006a38:	e426                	sd	s1,8(sp)
    80006a3a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a3c:	00020497          	auipc	s1,0x20
    80006a40:	28c48493          	addi	s1,s1,652 # 80026cc8 <disk>
    80006a44:	00020517          	auipc	a0,0x20
    80006a48:	3ac50513          	addi	a0,a0,940 # 80026df0 <disk+0x128>
    80006a4c:	9b4fa0ef          	jal	80000c00 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a50:	100017b7          	lui	a5,0x10001
    80006a54:	53b8                	lw	a4,96(a5)
    80006a56:	8b0d                	andi	a4,a4,3
    80006a58:	100017b7          	lui	a5,0x10001
    80006a5c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006a5e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a62:	689c                	ld	a5,16(s1)
    80006a64:	0204d703          	lhu	a4,32(s1)
    80006a68:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006a6c:	04f70663          	beq	a4,a5,80006ab8 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80006a70:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a74:	6898                	ld	a4,16(s1)
    80006a76:	0204d783          	lhu	a5,32(s1)
    80006a7a:	8b9d                	andi	a5,a5,7
    80006a7c:	078e                	slli	a5,a5,0x3
    80006a7e:	97ba                	add	a5,a5,a4
    80006a80:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a82:	00278713          	addi	a4,a5,2
    80006a86:	0712                	slli	a4,a4,0x4
    80006a88:	9726                	add	a4,a4,s1
    80006a8a:	01074703          	lbu	a4,16(a4)
    80006a8e:	e321                	bnez	a4,80006ace <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a90:	0789                	addi	a5,a5,2
    80006a92:	0792                	slli	a5,a5,0x4
    80006a94:	97a6                	add	a5,a5,s1
    80006a96:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a98:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a9c:	cc8fb0ef          	jal	80001f64 <wakeup>

    disk.used_idx += 1;
    80006aa0:	0204d783          	lhu	a5,32(s1)
    80006aa4:	2785                	addiw	a5,a5,1
    80006aa6:	17c2                	slli	a5,a5,0x30
    80006aa8:	93c1                	srli	a5,a5,0x30
    80006aaa:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006aae:	6898                	ld	a4,16(s1)
    80006ab0:	00275703          	lhu	a4,2(a4)
    80006ab4:	faf71ee3          	bne	a4,a5,80006a70 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006ab8:	00020517          	auipc	a0,0x20
    80006abc:	33850513          	addi	a0,a0,824 # 80026df0 <disk+0x128>
    80006ac0:	9d8fa0ef          	jal	80000c98 <release>
}
    80006ac4:	60e2                	ld	ra,24(sp)
    80006ac6:	6442                	ld	s0,16(sp)
    80006ac8:	64a2                	ld	s1,8(sp)
    80006aca:	6105                	addi	sp,sp,32
    80006acc:	8082                	ret
      panic("virtio_disk_intr status");
    80006ace:	00003517          	auipc	a0,0x3
    80006ad2:	42250513          	addi	a0,a0,1058 # 80009ef0 <etext+0xef0>
    80006ad6:	d3df90ef          	jal	80000812 <panic>

0000000080006ada <cslog_init>:
  safestrcpy(e->name, p->name, CS_NM);
}

void
cslog_init(void)
{
    80006ada:	1141                	addi	sp,sp,-16
    80006adc:	e406                	sd	ra,8(sp)
    80006ade:	e022                	sd	s0,0(sp)
    80006ae0:	0800                	addi	s0,sp,16
  ringbuf_init(&cs_rb, "cslog", sizeof(struct cs_event));
    80006ae2:	03000613          	li	a2,48
    80006ae6:	00003597          	auipc	a1,0x3
    80006aea:	42258593          	addi	a1,a1,1058 # 80009f08 <etext+0xf08>
    80006aee:	00020517          	auipc	a0,0x20
    80006af2:	31a50513          	addi	a0,a0,794 # 80026e08 <cs_rb>
    80006af6:	1c6000ef          	jal	80006cbc <ringbuf_init>
  printf("CS sizeof(cs_event)=%ld RB_MAX_ELEM=%d\n", sizeof(struct cs_event), RB_MAX_ELEM);
    80006afa:	10000613          	li	a2,256
    80006afe:	03000593          	li	a1,48
    80006b02:	00003517          	auipc	a0,0x3
    80006b06:	40e50513          	addi	a0,a0,1038 # 80009f10 <etext+0xf10>
    80006b0a:	a23f90ef          	jal	8000052c <printf>
}
    80006b0e:	60a2                	ld	ra,8(sp)
    80006b10:	6402                	ld	s0,0(sp)
    80006b12:	0141                	addi	sp,sp,16
    80006b14:	8082                	ret

0000000080006b16 <cslog_push>:

void
cslog_push(struct cs_event *e)
{
    80006b16:	1141                	addi	sp,sp,-16
    80006b18:	e406                	sd	ra,8(sp)
    80006b1a:	e022                	sd	s0,0(sp)
    80006b1c:	0800                	addi	s0,sp,16
    80006b1e:	85aa                	mv	a1,a0
  e->seq = ++cs_seq;
    80006b20:	00003717          	auipc	a4,0x3
    80006b24:	5a070713          	addi	a4,a4,1440 # 8000a0c0 <cs_seq>
    80006b28:	631c                	ld	a5,0(a4)
    80006b2a:	0785                	addi	a5,a5,1
    80006b2c:	e31c                	sd	a5,0(a4)
    80006b2e:	e11c                	sd	a5,0(a0)
  ringbuf_push(&cs_rb, e);
    80006b30:	00020517          	auipc	a0,0x20
    80006b34:	2d850513          	addi	a0,a0,728 # 80026e08 <cs_rb>
    80006b38:	1b8000ef          	jal	80006cf0 <ringbuf_push>
}
    80006b3c:	60a2                	ld	ra,8(sp)
    80006b3e:	6402                	ld	s0,0(sp)
    80006b40:	0141                	addi	sp,sp,16
    80006b42:	8082                	ret

0000000080006b44 <cslog_read_many>:

int
cslog_read_many(struct cs_event *out, int max)
{
    80006b44:	1141                	addi	sp,sp,-16
    80006b46:	e406                	sd	ra,8(sp)
    80006b48:	e022                	sd	s0,0(sp)
    80006b4a:	0800                	addi	s0,sp,16
    80006b4c:	862e                	mv	a2,a1
  return ringbuf_read_many(&cs_rb, out, max);
    80006b4e:	85aa                	mv	a1,a0
    80006b50:	00020517          	auipc	a0,0x20
    80006b54:	2b850513          	addi	a0,a0,696 # 80026e08 <cs_rb>
    80006b58:	204000ef          	jal	80006d5c <ringbuf_read_many>
}
    80006b5c:	60a2                	ld	ra,8(sp)
    80006b5e:	6402                	ld	s0,0(sp)
    80006b60:	0141                	addi	sp,sp,16
    80006b62:	8082                	ret

0000000080006b64 <cslog_run_start>:

void
cslog_run_start(struct proc *p)
{
  if(p == 0) return;
    80006b64:	c14d                	beqz	a0,80006c06 <cslog_run_start+0xa2>
{
    80006b66:	715d                	addi	sp,sp,-80
    80006b68:	e486                	sd	ra,72(sp)
    80006b6a:	e0a2                	sd	s0,64(sp)
    80006b6c:	fc26                	sd	s1,56(sp)
    80006b6e:	0880                	addi	s0,sp,80
    80006b70:	84aa                	mv	s1,a0
  if(p->pid <= 0) return;
    80006b72:	591c                	lw	a5,48(a0)
    80006b74:	00f05563          	blez	a5,80006b7e <cslog_run_start+0x1a>
  if(p->name[0] == 0) return;
    80006b78:	15854783          	lbu	a5,344(a0)
    80006b7c:	e791                	bnez	a5,80006b88 <cslog_run_start+0x24>

  struct cs_event e;
  fill_from_proc(&e, p);
  e.type = CS_RUN_START;
  cslog_push(&e);
    80006b7e:	60a6                	ld	ra,72(sp)
    80006b80:	6406                	ld	s0,64(sp)
    80006b82:	74e2                	ld	s1,56(sp)
    80006b84:	6161                	addi	sp,sp,80
    80006b86:	8082                	ret
    80006b88:	f84a                	sd	s2,48(sp)
  if(strncmp(p->name, "cscat", 5) == 0) return;
    80006b8a:	15850913          	addi	s2,a0,344
    80006b8e:	4615                	li	a2,5
    80006b90:	00003597          	auipc	a1,0x3
    80006b94:	3a858593          	addi	a1,a1,936 # 80009f38 <etext+0xf38>
    80006b98:	854a                	mv	a0,s2
    80006b9a:	a06fa0ef          	jal	80000da0 <strncmp>
    80006b9e:	e119                	bnez	a0,80006ba4 <cslog_run_start+0x40>
    80006ba0:	7942                	ld	s2,48(sp)
    80006ba2:	bff1                	j	80006b7e <cslog_run_start+0x1a>
  if(strncmp(p->name, "csexport", 8) == 0) return;
    80006ba4:	4621                	li	a2,8
    80006ba6:	00003597          	auipc	a1,0x3
    80006baa:	39a58593          	addi	a1,a1,922 # 80009f40 <etext+0xf40>
    80006bae:	854a                	mv	a0,s2
    80006bb0:	9f0fa0ef          	jal	80000da0 <strncmp>
    80006bb4:	e119                	bnez	a0,80006bba <cslog_run_start+0x56>
    80006bb6:	7942                	ld	s2,48(sp)
    80006bb8:	b7d9                	j	80006b7e <cslog_run_start+0x1a>
  memset(e, 0, sizeof(*e));
    80006bba:	03000613          	li	a2,48
    80006bbe:	4581                	li	a1,0
    80006bc0:	fb040513          	addi	a0,s0,-80
    80006bc4:	910fa0ef          	jal	80000cd4 <memset>
  e->ticks = ticks;
    80006bc8:	00003797          	auipc	a5,0x3
    80006bcc:	4f07a783          	lw	a5,1264(a5) # 8000a0b8 <ticks>
    80006bd0:	faf42c23          	sw	a5,-72(s0)
  e->cpu   = cpuid();
    80006bd4:	d09fa0ef          	jal	800018dc <cpuid>
    80006bd8:	faa42e23          	sw	a0,-68(s0)
  e->pid   = p->pid;
    80006bdc:	589c                	lw	a5,48(s1)
    80006bde:	fcf42223          	sw	a5,-60(s0)
  e->state = p->state;
    80006be2:	4c9c                	lw	a5,24(s1)
    80006be4:	fcf42423          	sw	a5,-56(s0)
  safestrcpy(e->name, p->name, CS_NM);
    80006be8:	4641                	li	a2,16
    80006bea:	85ca                	mv	a1,s2
    80006bec:	fcc40513          	addi	a0,s0,-52
    80006bf0:	a22fa0ef          	jal	80000e12 <safestrcpy>
  e.type = CS_RUN_START;
    80006bf4:	4785                	li	a5,1
    80006bf6:	fcf42023          	sw	a5,-64(s0)
  cslog_push(&e);
    80006bfa:	fb040513          	addi	a0,s0,-80
    80006bfe:	f19ff0ef          	jal	80006b16 <cslog_push>
    80006c02:	7942                	ld	s2,48(sp)
    80006c04:	bfad                	j	80006b7e <cslog_run_start+0x1a>
    80006c06:	8082                	ret

0000000080006c08 <sys_csread>:
#include "cslog.h"


uint64
sys_csread(void)
{
    80006c08:	81010113          	addi	sp,sp,-2032
    80006c0c:	7e113423          	sd	ra,2024(sp)
    80006c10:	7e813023          	sd	s0,2016(sp)
    80006c14:	7c913c23          	sd	s1,2008(sp)
    80006c18:	7d213823          	sd	s2,2000(sp)
    80006c1c:	7f010413          	addi	s0,sp,2032
    80006c20:	bb010113          	addi	sp,sp,-1104
  uint64 uaddr = 0;
    80006c24:	fc043c23          	sd	zero,-40(s0)
  int max = 0;
    80006c28:	fc042a23          	sw	zero,-44(s0)

  // ✅ عندك argaddr/argint void، فبنستدعيهم بدون if
  argaddr(0, &uaddr);
    80006c2c:	fd840593          	addi	a1,s0,-40
    80006c30:	4501                	li	a0,0
    80006c32:	c07fb0ef          	jal	80002838 <argaddr>
  argint(1, &max);
    80006c36:	fd440593          	addi	a1,s0,-44
    80006c3a:	4505                	li	a0,1
    80006c3c:	be1fb0ef          	jal	8000281c <argint>

  if(max <= 0) return 0;
    80006c40:	fd442783          	lw	a5,-44(s0)
    80006c44:	4501                	li	a0,0
    80006c46:	04f05c63          	blez	a5,80006c9e <sys_csread+0x96>
  if(max > 64) max = 64;
    80006c4a:	04000713          	li	a4,64
    80006c4e:	00f75663          	bge	a4,a5,80006c5a <sys_csread+0x52>
    80006c52:	04000793          	li	a5,64
    80006c56:	fcf42a23          	sw	a5,-44(s0)

  struct cs_event tmp[64];
  int n = cslog_read_many(tmp, max);
    80006c5a:	77fd                	lui	a5,0xfffff
    80006c5c:	3d078793          	addi	a5,a5,976 # fffffffffffff3d0 <end+0xffffffff7ff98568>
    80006c60:	97a2                	add	a5,a5,s0
    80006c62:	797d                	lui	s2,0xfffff
    80006c64:	3c890713          	addi	a4,s2,968 # fffffffffffff3c8 <end+0xffffffff7ff98560>
    80006c68:	9722                	add	a4,a4,s0
    80006c6a:	e31c                	sd	a5,0(a4)
    80006c6c:	fd442583          	lw	a1,-44(s0)
    80006c70:	6308                	ld	a0,0(a4)
    80006c72:	ed3ff0ef          	jal	80006b44 <cslog_read_many>
    80006c76:	84aa                	mv	s1,a0

  int bytes = n * (int)sizeof(struct cs_event);
  if(copyout(myproc()->pagetable, uaddr, (char*)tmp, bytes) < 0)
    80006c78:	c91fa0ef          	jal	80001908 <myproc>
  int bytes = n * (int)sizeof(struct cs_event);
    80006c7c:	0014969b          	slliw	a3,s1,0x1
    80006c80:	9ea5                	addw	a3,a3,s1
  if(copyout(myproc()->pagetable, uaddr, (char*)tmp, bytes) < 0)
    80006c82:	0046969b          	slliw	a3,a3,0x4
    80006c86:	3c890793          	addi	a5,s2,968
    80006c8a:	97a2                	add	a5,a5,s0
    80006c8c:	6390                	ld	a2,0(a5)
    80006c8e:	fd843583          	ld	a1,-40(s0)
    80006c92:	6928                	ld	a0,80(a0)
    80006c94:	989fa0ef          	jal	8000161c <copyout>
    80006c98:	02054063          	bltz	a0,80006cb8 <sys_csread+0xb0>
    return -1;

  return n;
    80006c9c:	8526                	mv	a0,s1
}
    80006c9e:	45010113          	addi	sp,sp,1104
    80006ca2:	7e813083          	ld	ra,2024(sp)
    80006ca6:	7e013403          	ld	s0,2016(sp)
    80006caa:	7d813483          	ld	s1,2008(sp)
    80006cae:	7d013903          	ld	s2,2000(sp)
    80006cb2:	7f010113          	addi	sp,sp,2032
    80006cb6:	8082                	ret
    return -1;
    80006cb8:	557d                	li	a0,-1
    80006cba:	b7d5                	j	80006c9e <sys_csread+0x96>

0000000080006cbc <ringbuf_init>:
  return (void *)(rb->buf + idx * rb->elem_size);
}

void
ringbuf_init(struct ringbuf *rb, char *name, uint elem_size)
{
    80006cbc:	1101                	addi	sp,sp,-32
    80006cbe:	ec06                	sd	ra,24(sp)
    80006cc0:	e822                	sd	s0,16(sp)
    80006cc2:	e426                	sd	s1,8(sp)
    80006cc4:	e04a                	sd	s2,0(sp)
    80006cc6:	1000                	addi	s0,sp,32
    80006cc8:	84aa                	mv	s1,a0
    80006cca:	8932                	mv	s2,a2
  initlock(&rb->lock, name);
    80006ccc:	eb5f90ef          	jal	80000b80 <initlock>
  rb->head = 0;
    80006cd0:	0004ac23          	sw	zero,24(s1)
  rb->tail = 0;
    80006cd4:	0004ae23          	sw	zero,28(s1)
  rb->count = 0;
    80006cd8:	0204a023          	sw	zero,32(s1)
  rb->seq = 0;
    80006cdc:	0204b423          	sd	zero,40(s1)
  rb->elem_size = elem_size;
    80006ce0:	0324a223          	sw	s2,36(s1)
}
    80006ce4:	60e2                	ld	ra,24(sp)
    80006ce6:	6442                	ld	s0,16(sp)
    80006ce8:	64a2                	ld	s1,8(sp)
    80006cea:	6902                	ld	s2,0(sp)
    80006cec:	6105                	addi	sp,sp,32
    80006cee:	8082                	ret

0000000080006cf0 <ringbuf_push>:

int
ringbuf_push(struct ringbuf *rb, void *elem)
{
    80006cf0:	1101                	addi	sp,sp,-32
    80006cf2:	ec06                	sd	ra,24(sp)
    80006cf4:	e822                	sd	s0,16(sp)
    80006cf6:	e426                	sd	s1,8(sp)
    80006cf8:	e04a                	sd	s2,0(sp)
    80006cfa:	1000                	addi	s0,sp,32
    80006cfc:	84aa                	mv	s1,a0
    80006cfe:	892e                	mv	s2,a1
  acquire(&rb->lock);
    80006d00:	f01f90ef          	jal	80000c00 <acquire>

  if(rb->count == RB_CAP){
    80006d04:	5098                	lw	a4,32(s1)
    80006d06:	20000793          	li	a5,512
    80006d0a:	04f70063          	beq	a4,a5,80006d4a <ringbuf_push+0x5a>
  return (void *)(rb->buf + idx * rb->elem_size);
    80006d0e:	50d0                	lw	a2,36(s1)
    80006d10:	03048513          	addi	a0,s1,48
    80006d14:	4c9c                	lw	a5,24(s1)
    80006d16:	02c787bb          	mulw	a5,a5,a2
    80006d1a:	1782                	slli	a5,a5,0x20
    80006d1c:	9381                	srli	a5,a5,0x20
    rb->tail = (rb->tail + 1) % RB_CAP;
    rb->count--;
  }

  memmove(slot_ptr(rb, rb->head), elem, rb->elem_size);
    80006d1e:	85ca                	mv	a1,s2
    80006d20:	953e                	add	a0,a0,a5
    80006d22:	80efa0ef          	jal	80000d30 <memmove>
  rb->head = (rb->head + 1) % RB_CAP;
    80006d26:	4c9c                	lw	a5,24(s1)
    80006d28:	2785                	addiw	a5,a5,1
    80006d2a:	1ff7f793          	andi	a5,a5,511
    80006d2e:	cc9c                	sw	a5,24(s1)
  rb->count++;
    80006d30:	509c                	lw	a5,32(s1)
    80006d32:	2785                	addiw	a5,a5,1
    80006d34:	d09c                	sw	a5,32(s1)

  release(&rb->lock);
    80006d36:	8526                	mv	a0,s1
    80006d38:	f61f90ef          	jal	80000c98 <release>
  return 0;
}
    80006d3c:	4501                	li	a0,0
    80006d3e:	60e2                	ld	ra,24(sp)
    80006d40:	6442                	ld	s0,16(sp)
    80006d42:	64a2                	ld	s1,8(sp)
    80006d44:	6902                	ld	s2,0(sp)
    80006d46:	6105                	addi	sp,sp,32
    80006d48:	8082                	ret
    rb->tail = (rb->tail + 1) % RB_CAP;
    80006d4a:	4cdc                	lw	a5,28(s1)
    80006d4c:	2785                	addiw	a5,a5,1
    80006d4e:	1ff7f793          	andi	a5,a5,511
    80006d52:	ccdc                	sw	a5,28(s1)
    rb->count--;
    80006d54:	1ff00793          	li	a5,511
    80006d58:	d09c                	sw	a5,32(s1)
    80006d5a:	bf55                	j	80006d0e <ringbuf_push+0x1e>

0000000080006d5c <ringbuf_read_many>:

int
ringbuf_read_many(struct ringbuf *rb, void *out, int max)
{
    80006d5c:	7139                	addi	sp,sp,-64
    80006d5e:	fc06                	sd	ra,56(sp)
    80006d60:	f822                	sd	s0,48(sp)
    80006d62:	f04a                	sd	s2,32(sp)
    80006d64:	0080                	addi	s0,sp,64
  int n = 0;
  char *dst = (char *)out;

  if(max <= 0)
    return 0;
    80006d66:	4901                	li	s2,0
  if(max <= 0)
    80006d68:	06c05163          	blez	a2,80006dca <ringbuf_read_many+0x6e>
    80006d6c:	f426                	sd	s1,40(sp)
    80006d6e:	ec4e                	sd	s3,24(sp)
    80006d70:	e852                	sd	s4,16(sp)
    80006d72:	e456                	sd	s5,8(sp)
    80006d74:	84aa                	mv	s1,a0
    80006d76:	8a2e                	mv	s4,a1
    80006d78:	89b2                	mv	s3,a2

  acquire(&rb->lock);
    80006d7a:	e87f90ef          	jal	80000c00 <acquire>
  int n = 0;
    80006d7e:	4901                	li	s2,0
  return (void *)(rb->buf + idx * rb->elem_size);
    80006d80:	03048a93          	addi	s5,s1,48
  while(n < max && rb->count > 0){
    80006d84:	509c                	lw	a5,32(s1)
    80006d86:	cb9d                	beqz	a5,80006dbc <ringbuf_read_many+0x60>
    memmove(dst + n * rb->elem_size, slot_ptr(rb, rb->tail), rb->elem_size);
    80006d88:	50d0                	lw	a2,36(s1)
  return (void *)(rb->buf + idx * rb->elem_size);
    80006d8a:	4ccc                	lw	a1,28(s1)
    80006d8c:	02c585bb          	mulw	a1,a1,a2
    80006d90:	1582                	slli	a1,a1,0x20
    80006d92:	9181                	srli	a1,a1,0x20
    memmove(dst + n * rb->elem_size, slot_ptr(rb, rb->tail), rb->elem_size);
    80006d94:	02c9053b          	mulw	a0,s2,a2
    80006d98:	1502                	slli	a0,a0,0x20
    80006d9a:	9101                	srli	a0,a0,0x20
    80006d9c:	95d6                	add	a1,a1,s5
    80006d9e:	9552                	add	a0,a0,s4
    80006da0:	f91f90ef          	jal	80000d30 <memmove>
    rb->tail = (rb->tail + 1) % RB_CAP;
    80006da4:	4cdc                	lw	a5,28(s1)
    80006da6:	2785                	addiw	a5,a5,1
    80006da8:	1ff7f793          	andi	a5,a5,511
    80006dac:	ccdc                	sw	a5,28(s1)
    rb->count--;
    80006dae:	509c                	lw	a5,32(s1)
    80006db0:	37fd                	addiw	a5,a5,-1
    80006db2:	d09c                	sw	a5,32(s1)
    n++;
    80006db4:	2905                	addiw	s2,s2,1
  while(n < max && rb->count > 0){
    80006db6:	fd2997e3          	bne	s3,s2,80006d84 <ringbuf_read_many+0x28>
    80006dba:	894e                	mv	s2,s3
  }
  release(&rb->lock);
    80006dbc:	8526                	mv	a0,s1
    80006dbe:	edbf90ef          	jal	80000c98 <release>

  return n;
    80006dc2:	74a2                	ld	s1,40(sp)
    80006dc4:	69e2                	ld	s3,24(sp)
    80006dc6:	6a42                	ld	s4,16(sp)
    80006dc8:	6aa2                	ld	s5,8(sp)
}
    80006dca:	854a                	mv	a0,s2
    80006dcc:	70e2                	ld	ra,56(sp)
    80006dce:	7442                	ld	s0,48(sp)
    80006dd0:	7902                	ld	s2,32(sp)
    80006dd2:	6121                	addi	sp,sp,64
    80006dd4:	8082                	ret

0000000080006dd6 <ringbuf_pop>:

int
ringbuf_pop(struct ringbuf *rb, void *dst)
{
    80006dd6:	1101                	addi	sp,sp,-32
    80006dd8:	ec06                	sd	ra,24(sp)
    80006dda:	e822                	sd	s0,16(sp)
    80006ddc:	e426                	sd	s1,8(sp)
    80006dde:	e04a                	sd	s2,0(sp)
    80006de0:	1000                	addi	s0,sp,32
    80006de2:	84aa                	mv	s1,a0
    80006de4:	892e                	mv	s2,a1
  acquire(&rb->lock);
    80006de6:	e1bf90ef          	jal	80000c00 <acquire>

  if(rb->count == 0){
    80006dea:	509c                	lw	a5,32(s1)
    80006dec:	cf9d                	beqz	a5,80006e2a <ringbuf_pop+0x54>
  return (void *)(rb->buf + idx * rb->elem_size);
    80006dee:	50d0                	lw	a2,36(s1)
    80006df0:	03048593          	addi	a1,s1,48
    80006df4:	4cdc                	lw	a5,28(s1)
    80006df6:	02c787bb          	mulw	a5,a5,a2
    80006dfa:	1782                	slli	a5,a5,0x20
    80006dfc:	9381                	srli	a5,a5,0x20
    release(&rb->lock);
    return -1;
  }

  memmove(dst, slot_ptr(rb, rb->tail), rb->elem_size);
    80006dfe:	95be                	add	a1,a1,a5
    80006e00:	854a                	mv	a0,s2
    80006e02:	f2ff90ef          	jal	80000d30 <memmove>
  rb->tail = (rb->tail + 1) % RB_CAP;
    80006e06:	4cdc                	lw	a5,28(s1)
    80006e08:	2785                	addiw	a5,a5,1
    80006e0a:	1ff7f793          	andi	a5,a5,511
    80006e0e:	ccdc                	sw	a5,28(s1)
  rb->count--;
    80006e10:	509c                	lw	a5,32(s1)
    80006e12:	37fd                	addiw	a5,a5,-1
    80006e14:	d09c                	sw	a5,32(s1)

  release(&rb->lock);
    80006e16:	8526                	mv	a0,s1
    80006e18:	e81f90ef          	jal	80000c98 <release>
  return 0;
    80006e1c:	4501                	li	a0,0
    80006e1e:	60e2                	ld	ra,24(sp)
    80006e20:	6442                	ld	s0,16(sp)
    80006e22:	64a2                	ld	s1,8(sp)
    80006e24:	6902                	ld	s2,0(sp)
    80006e26:	6105                	addi	sp,sp,32
    80006e28:	8082                	ret
    release(&rb->lock);
    80006e2a:	8526                	mv	a0,s1
    80006e2c:	e6df90ef          	jal	80000c98 <release>
    return -1;
    80006e30:	557d                	li	a0,-1
    80006e32:	b7f5                	j	80006e1e <ringbuf_pop+0x48>

0000000080006e34 <fslog_init>:
static struct ringbuf fs_rb;
static uint64 fs_seq = 0;

void
fslog_init(void)
{
    80006e34:	1141                	addi	sp,sp,-16
    80006e36:	e406                	sd	ra,8(sp)
    80006e38:	e022                	sd	s0,0(sp)
    80006e3a:	0800                	addi	s0,sp,16
  // تهيئة الـ ring buffer الخاص بـ أحداث نظام الملفات
  ringbuf_init(&fs_rb, "fslog", sizeof(struct fs_event));
    80006e3c:	31000613          	li	a2,784
    80006e40:	00003597          	auipc	a1,0x3
    80006e44:	11058593          	addi	a1,a1,272 # 80009f50 <etext+0xf50>
    80006e48:	00040517          	auipc	a0,0x40
    80006e4c:	ff050513          	addi	a0,a0,-16 # 80046e38 <fs_rb>
    80006e50:	e6dff0ef          	jal	80006cbc <ringbuf_init>
}
    80006e54:	60a2                	ld	ra,8(sp)
    80006e56:	6402                	ld	s0,0(sp)
    80006e58:	0141                	addi	sp,sp,16
    80006e5a:	8082                	ret

0000000080006e5c <fslog_push>:

void
fslog_push(struct fs_event *e)
{
    80006e5c:	1141                	addi	sp,sp,-16
    80006e5e:	e406                	sd	ra,8(sp)
    80006e60:	e022                	sd	s0,0(sp)
    80006e62:	0800                	addi	s0,sp,16
    80006e64:	85aa                	mv	a1,a0
  // إضافة رقم تسلسلي لكل حدث لترتيبها في الواجهة الرسومية
  e->seq = ++fs_seq;
    80006e66:	00003717          	auipc	a4,0x3
    80006e6a:	26270713          	addi	a4,a4,610 # 8000a0c8 <fs_seq>
    80006e6e:	631c                	ld	a5,0(a4)
    80006e70:	0785                	addi	a5,a5,1
    80006e72:	e31c                	sd	a5,0(a4)
    80006e74:	e11c                	sd	a5,0(a0)
  ringbuf_push(&fs_rb, e);
    80006e76:	00040517          	auipc	a0,0x40
    80006e7a:	fc250513          	addi	a0,a0,-62 # 80046e38 <fs_rb>
    80006e7e:	e73ff0ef          	jal	80006cf0 <ringbuf_push>
}
    80006e82:	60a2                	ld	ra,8(sp)
    80006e84:	6402                	ld	s0,0(sp)
    80006e86:	0141                	addi	sp,sp,16
    80006e88:	8082                	ret

0000000080006e8a <fslog_read_many>:

int
fslog_read_many(struct fs_event *out, int max)
{
    80006e8a:	cb010113          	addi	sp,sp,-848
    80006e8e:	34113423          	sd	ra,840(sp)
    80006e92:	34813023          	sd	s0,832(sp)
    80006e96:	32913c23          	sd	s1,824(sp)
    80006e9a:	33213823          	sd	s2,816(sp)
    80006e9e:	33313423          	sd	s3,808(sp)
    80006ea2:	0e80                	addi	s0,sp,848
    80006ea4:	84aa                	mv	s1,a0
    80006ea6:	89ae                	mv	s3,a1
  struct fs_event e;
  int count = 0;
  struct proc *p = myproc();
    80006ea8:	a61fa0ef          	jal	80001908 <myproc>
  
  while(count < max){
    80006eac:	05305863          	blez	s3,80006efc <fslog_read_many+0x72>
    80006eb0:	33413023          	sd	s4,800(sp)
    80006eb4:	31513c23          	sd	s5,792(sp)
    80006eb8:	8a2a                	mv	s4,a0
  int count = 0;
    80006eba:	4901                	li	s2,0
    if(ringbuf_pop(&fs_rb, &e) != 0)
    80006ebc:	00040a97          	auipc	s5,0x40
    80006ec0:	f7ca8a93          	addi	s5,s5,-132 # 80046e38 <fs_rb>
    80006ec4:	cb040593          	addi	a1,s0,-848
    80006ec8:	8556                	mv	a0,s5
    80006eca:	f0dff0ef          	jal	80006dd6 <ringbuf_pop>
    80006ece:	e90d                	bnez	a0,80006f00 <fslog_read_many+0x76>
      break;

    // نقل البيانات من مساحة النواة إلى مساحة المستخدم (User Space) ليعرضها الـ GUI
    uint64 dst = (uint64)out + count * sizeof(struct fs_event);
    if(copyout(p->pagetable, dst, (char *)&e, sizeof(struct fs_event)) < 0)
    80006ed0:	31000693          	li	a3,784
    80006ed4:	cb040613          	addi	a2,s0,-848
    80006ed8:	85a6                	mv	a1,s1
    80006eda:	050a3503          	ld	a0,80(s4)
    80006ede:	f3efa0ef          	jal	8000161c <copyout>
    80006ee2:	04054163          	bltz	a0,80006f24 <fslog_read_many+0x9a>
      break;
    count++;
    80006ee6:	2905                	addiw	s2,s2,1
  while(count < max){
    80006ee8:	31048493          	addi	s1,s1,784
    80006eec:	fd299ce3          	bne	s3,s2,80006ec4 <fslog_read_many+0x3a>
    80006ef0:	894e                	mv	s2,s3
    80006ef2:	32013a03          	ld	s4,800(sp)
    80006ef6:	31813a83          	ld	s5,792(sp)
    80006efa:	a039                	j	80006f08 <fslog_read_many+0x7e>
  int count = 0;
    80006efc:	4901                	li	s2,0
    80006efe:	a029                	j	80006f08 <fslog_read_many+0x7e>
    80006f00:	32013a03          	ld	s4,800(sp)
    80006f04:	31813a83          	ld	s5,792(sp)
  }
  return count;
}
    80006f08:	854a                	mv	a0,s2
    80006f0a:	34813083          	ld	ra,840(sp)
    80006f0e:	34013403          	ld	s0,832(sp)
    80006f12:	33813483          	ld	s1,824(sp)
    80006f16:	33013903          	ld	s2,816(sp)
    80006f1a:	32813983          	ld	s3,808(sp)
    80006f1e:	35010113          	addi	sp,sp,848
    80006f22:	8082                	ret
    80006f24:	32013a03          	ld	s4,800(sp)
    80006f28:	31813a83          	ld	s5,792(sp)
    80006f2c:	bff1                	j	80006f08 <fslog_read_many+0x7e>

0000000080006f2e <state_update_file>:
void
state_update_file(int pid, int fd, struct file *f, char *path)
{
    80006f2e:	cc010113          	addi	sp,sp,-832
    80006f32:	32113c23          	sd	ra,824(sp)
    80006f36:	32813823          	sd	s0,816(sp)
    80006f3a:	32913423          	sd	s1,808(sp)
    80006f3e:	33213023          	sd	s2,800(sp)
    80006f42:	31313c23          	sd	s3,792(sp)
    80006f46:	31413823          	sd	s4,784(sp)
    80006f4a:	0680                	addi	s0,sp,832
    80006f4c:	8a2a                	mv	s4,a0
    80006f4e:	89ae                	mv	s3,a1
    80006f50:	84b2                	mv	s1,a2
    80006f52:	8936                	mv	s2,a3
    struct fs_event e;
    memset(&e, 0, sizeof(e));
    80006f54:	31000613          	li	a2,784
    80006f58:	4581                	li	a1,0
    80006f5a:	cc040513          	addi	a0,s0,-832
    80006f5e:	d77f90ef          	jal	80000cd4 <memset>

    e.ticks = ticks;
    80006f62:	00003797          	auipc	a5,0x3
    80006f66:	1567a783          	lw	a5,342(a5) # 8000a0b8 <ticks>
    80006f6a:	ccf42423          	sw	a5,-824(s0)
    e.pid = pid;
    80006f6e:	cd442623          	sw	s4,-820(s0)
    e.type = LAYER_FILE;
    80006f72:	479d                	li	a5,7
    80006f74:	ccf42823          	sw	a5,-816(s0)

    safestrcpy(e.op_name, "OPEN", sizeof(e.op_name));
    80006f78:	4641                	li	a2,16
    80006f7a:	00003597          	auipc	a1,0x3
    80006f7e:	e7658593          	addi	a1,a1,-394 # 80009df0 <etext+0xdf0>
    80006f82:	cd440513          	addi	a0,s0,-812
    80006f86:	e8df90ef          	jal	80000e12 <safestrcpy>

    e.fd = fd;
    80006f8a:	e9342423          	sw	s3,-376(s0)
    e.file_object_id = (uint64)f;
    80006f8e:	f4943023          	sd	s1,-192(s0)

    e.file_type = f->type;
    80006f92:	409c                	lw	a5,0(s1)
    80006f94:	e8f42623          	sw	a5,-372(s0)
    e.file_ref = f->ref;
    80006f98:	40dc                	lw	a5,4(s1)
    80006f9a:	eaf42423          	sw	a5,-344(s0)
    e.file_off = f->off;
    80006f9e:	509c                	lw	a5,32(s1)
    80006fa0:	eaf42823          	sw	a5,-336(s0)
    e.file_inum = f->ip ? f->ip->inum : -1;
    80006fa4:	6c98                	ld	a4,24(s1)
    80006fa6:	57fd                	li	a5,-1
    80006fa8:	c311                	beqz	a4,80006fac <state_update_file+0x7e>
    80006faa:	435c                	lw	a5,4(a4)
    80006fac:	eaf42c23          	sw	a5,-328(s0)

    e.readable = f->readable;
    80006fb0:	0084c783          	lbu	a5,8(s1)
    80006fb4:	eaf42023          	sw	a5,-352(s0)
    e.writable = f->writable;
    80006fb8:	0094c783          	lbu	a5,9(s1)
    80006fbc:	eaf42223          	sw	a5,-348(s0)

    safestrcpy(e.path, path, MAXPATH);
    80006fc0:	08000613          	li	a2,128
    80006fc4:	85ca                	mv	a1,s2
    80006fc6:	de840513          	addi	a0,s0,-536
    80006fca:	e49f90ef          	jal	80000e12 <safestrcpy>

    // human-readable file type
    if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    80006fce:	409c                	lw	a5,0(s1)
    80006fd0:	4705                	li	a4,1
    80006fd2:	04e78463          	beq	a5,a4,8000701a <state_update_file+0xec>
    else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    80006fd6:	4709                	li	a4,2
    80006fd8:	04e78b63          	beq	a5,a4,8000702e <state_update_file+0x100>
    else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    80006fdc:	470d                	li	a4,3
    80006fde:	06e78263          	beq	a5,a4,80007042 <state_update_file+0x114>
    else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));
    80006fe2:	4641                	li	a2,16
    80006fe4:	00003597          	auipc	a1,0x3
    80006fe8:	c6c58593          	addi	a1,a1,-916 # 80009c50 <etext+0xc50>
    80006fec:	e9040513          	addi	a0,s0,-368
    80006ff0:	e23f90ef          	jal	80000e12 <safestrcpy>

    fslog_push(&e);
    80006ff4:	cc040513          	addi	a0,s0,-832
    80006ff8:	e65ff0ef          	jal	80006e5c <fslog_push>
}
    80006ffc:	33813083          	ld	ra,824(sp)
    80007000:	33013403          	ld	s0,816(sp)
    80007004:	32813483          	ld	s1,808(sp)
    80007008:	32013903          	ld	s2,800(sp)
    8000700c:	31813983          	ld	s3,792(sp)
    80007010:	31013a03          	ld	s4,784(sp)
    80007014:	34010113          	addi	sp,sp,832
    80007018:	8082                	ret
    if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    8000701a:	4641                	li	a2,16
    8000701c:	00003597          	auipc	a1,0x3
    80007020:	c1c58593          	addi	a1,a1,-996 # 80009c38 <etext+0xc38>
    80007024:	e9040513          	addi	a0,s0,-368
    80007028:	debf90ef          	jal	80000e12 <safestrcpy>
    8000702c:	b7e1                	j	80006ff4 <state_update_file+0xc6>
    else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    8000702e:	4641                	li	a2,16
    80007030:	00003597          	auipc	a1,0x3
    80007034:	c1058593          	addi	a1,a1,-1008 # 80009c40 <etext+0xc40>
    80007038:	e9040513          	addi	a0,s0,-368
    8000703c:	dd7f90ef          	jal	80000e12 <safestrcpy>
    80007040:	bf55                	j	80006ff4 <state_update_file+0xc6>
    else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    80007042:	4641                	li	a2,16
    80007044:	00003597          	auipc	a1,0x3
    80007048:	c0458593          	addi	a1,a1,-1020 # 80009c48 <etext+0xc48>
    8000704c:	e9040513          	addi	a0,s0,-368
    80007050:	dc3f90ef          	jal	80000e12 <safestrcpy>
    80007054:	b745                	j	80006ff4 <state_update_file+0xc6>

0000000080007056 <state_remove_fd>:

void
state_remove_fd(int pid, int fd , struct file *f)
{
    80007056:	cc010113          	addi	sp,sp,-832
    8000705a:	32113c23          	sd	ra,824(sp)
    8000705e:	32813823          	sd	s0,816(sp)
    80007062:	32913423          	sd	s1,808(sp)
    80007066:	33213023          	sd	s2,800(sp)
    8000706a:	31313c23          	sd	s3,792(sp)
    8000706e:	0680                	addi	s0,sp,832
    80007070:	89aa                	mv	s3,a0
    80007072:	892e                	mv	s2,a1
    80007074:	84b2                	mv	s1,a2
    struct fs_event e;
    memset(&e, 0, sizeof(e));
    80007076:	31000613          	li	a2,784
    8000707a:	4581                	li	a1,0
    8000707c:	cc040513          	addi	a0,s0,-832
    80007080:	c55f90ef          	jal	80000cd4 <memset>

    e.ticks = ticks;
    80007084:	00003797          	auipc	a5,0x3
    80007088:	0347a783          	lw	a5,52(a5) # 8000a0b8 <ticks>
    8000708c:	ccf42423          	sw	a5,-824(s0)
    e.pid = pid;
    80007090:	cd342623          	sw	s3,-820(s0)
    e.type = LAYER_FILE;
    80007094:	479d                	li	a5,7
    80007096:	ccf42823          	sw	a5,-816(s0)

    safestrcpy(e.op_name, "FILECLOSE", sizeof(e.op_name));
    8000709a:	4641                	li	a2,16
    8000709c:	00003597          	auipc	a1,0x3
    800070a0:	c1c58593          	addi	a1,a1,-996 # 80009cb8 <etext+0xcb8>
    800070a4:	cd440513          	addi	a0,s0,-812
    800070a8:	d6bf90ef          	jal	80000e12 <safestrcpy>

    e.fd = fd;
    800070ac:	e9242423          	sw	s2,-376(s0)
    e.file_object_id=(uint64)f;
    800070b0:	f4943023          	sd	s1,-192(s0)

    e.file_ref=f->ref;
    800070b4:	40dc                	lw	a5,4(s1)
    800070b6:	eaf42423          	sw	a5,-344(s0)

    e.file_off=f->off;
    800070ba:	509c                	lw	a5,32(s1)
    800070bc:	eaf42823          	sw	a5,-336(s0)

    e.file_inum=f->ip ? f->ip->inum : -1;
    800070c0:	6c98                	ld	a4,24(s1)
    800070c2:	57fd                	li	a5,-1
    800070c4:	c311                	beqz	a4,800070c8 <state_remove_fd+0x72>
    800070c6:	435c                	lw	a5,4(a4)
    800070c8:	eaf42c23          	sw	a5,-328(s0)

    safestrcpy(e.path,f->path,MAXPATH);
    800070cc:	08000613          	li	a2,128
    800070d0:	02648593          	addi	a1,s1,38
    800070d4:	de840513          	addi	a0,s0,-536
    800070d8:	d3bf90ef          	jal	80000e12 <safestrcpy>

    if(f){
      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    800070dc:	409c                	lw	a5,0(s1)
    800070de:	4705                	li	a4,1
    800070e0:	04e78263          	beq	a5,a4,80007124 <state_remove_fd+0xce>
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    800070e4:	4709                	li	a4,2
    800070e6:	04e78963          	beq	a5,a4,80007138 <state_remove_fd+0xe2>
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    800070ea:	470d                	li	a4,3
    800070ec:	06e78063          	beq	a5,a4,8000714c <state_remove_fd+0xf6>
      else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));
    800070f0:	4641                	li	a2,16
    800070f2:	00003597          	auipc	a1,0x3
    800070f6:	b5e58593          	addi	a1,a1,-1186 # 80009c50 <etext+0xc50>
    800070fa:	e9040513          	addi	a0,s0,-368
    800070fe:	d15f90ef          	jal	80000e12 <safestrcpy>
    }

    fslog_push(&e);
    80007102:	cc040513          	addi	a0,s0,-832
    80007106:	d57ff0ef          	jal	80006e5c <fslog_push>
}
    8000710a:	33813083          	ld	ra,824(sp)
    8000710e:	33013403          	ld	s0,816(sp)
    80007112:	32813483          	ld	s1,808(sp)
    80007116:	32013903          	ld	s2,800(sp)
    8000711a:	31813983          	ld	s3,792(sp)
    8000711e:	34010113          	addi	sp,sp,832
    80007122:	8082                	ret
      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    80007124:	4641                	li	a2,16
    80007126:	00003597          	auipc	a1,0x3
    8000712a:	b1258593          	addi	a1,a1,-1262 # 80009c38 <etext+0xc38>
    8000712e:	e9040513          	addi	a0,s0,-368
    80007132:	ce1f90ef          	jal	80000e12 <safestrcpy>
    80007136:	b7f1                	j	80007102 <state_remove_fd+0xac>
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    80007138:	4641                	li	a2,16
    8000713a:	00003597          	auipc	a1,0x3
    8000713e:	b0658593          	addi	a1,a1,-1274 # 80009c40 <etext+0xc40>
    80007142:	e9040513          	addi	a0,s0,-368
    80007146:	ccdf90ef          	jal	80000e12 <safestrcpy>
    8000714a:	bf65                	j	80007102 <state_remove_fd+0xac>
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    8000714c:	4641                	li	a2,16
    8000714e:	00003597          	auipc	a1,0x3
    80007152:	afa58593          	addi	a1,a1,-1286 # 80009c48 <etext+0xc48>
    80007156:	e9040513          	addi	a0,s0,-368
    8000715a:	cb9f90ef          	jal	80000e12 <safestrcpy>
    8000715e:	b755                	j	80007102 <state_remove_fd+0xac>

0000000080007160 <state_dup_file>:
void
state_dup_file(int pid, int oldfd, int newfd, struct file *f)
{
    80007160:	cc010113          	addi	sp,sp,-832
    80007164:	32113c23          	sd	ra,824(sp)
    80007168:	32813823          	sd	s0,816(sp)
    8000716c:	32913423          	sd	s1,808(sp)
    80007170:	33213023          	sd	s2,800(sp)
    80007174:	31313c23          	sd	s3,792(sp)
    80007178:	31413823          	sd	s4,784(sp)
    8000717c:	0680                	addi	s0,sp,832
    8000717e:	8a2a                	mv	s4,a0
    80007180:	89ae                	mv	s3,a1
    80007182:	8932                	mv	s2,a2
    80007184:	84b6                	mv	s1,a3
    struct fs_event e;
    memset(&e,0,sizeof(e));
    80007186:	31000613          	li	a2,784
    8000718a:	4581                	li	a1,0
    8000718c:	cc040513          	addi	a0,s0,-832
    80007190:	b45f90ef          	jal	80000cd4 <memset>

    e.ticks = ticks;
    80007194:	00003797          	auipc	a5,0x3
    80007198:	f247a783          	lw	a5,-220(a5) # 8000a0b8 <ticks>
    8000719c:	ccf42423          	sw	a5,-824(s0)
    e.pid = pid;
    800071a0:	cd442623          	sw	s4,-820(s0)
    e.type = LAYER_FILE;
    800071a4:	479d                	li	a5,7
    800071a6:	ccf42823          	sw	a5,-816(s0)

    safestrcpy(e.op_name,"DUP",sizeof(e.op_name));
    800071aa:	4641                	li	a2,16
    800071ac:	00003597          	auipc	a1,0x3
    800071b0:	dac58593          	addi	a1,a1,-596 # 80009f58 <etext+0xf58>
    800071b4:	cd440513          	addi	a0,s0,-812
    800071b8:	c5bf90ef          	jal	80000e12 <safestrcpy>

    e.old_fd = oldfd;
    800071bc:	f5342423          	sw	s3,-184(s0)
    e.fd = newfd;
    800071c0:	e9242423          	sw	s2,-376(s0)

    e.file_object_id = (uint64)f;
    800071c4:	f4943023          	sd	s1,-192(s0)

    if(f){
    800071c8:	c0bd                	beqz	s1,8000722e <state_dup_file+0xce>
        e.file_type = f->type;
    800071ca:	409c                	lw	a5,0(s1)
    800071cc:	e8f42623          	sw	a5,-372(s0)
        e.file_ref = f->ref;
    800071d0:	40dc                	lw	a5,4(s1)
    800071d2:	eaf42423          	sw	a5,-344(s0)
        e.file_off = f->off;
    800071d6:	509c                	lw	a5,32(s1)
    800071d8:	eaf42823          	sw	a5,-336(s0)
        e.file_inum = f->ip ? f->ip->inum : -1;
    800071dc:	6c98                	ld	a4,24(s1)
    800071de:	57fd                	li	a5,-1
    800071e0:	c311                	beqz	a4,800071e4 <state_dup_file+0x84>
    800071e2:	435c                	lw	a5,4(a4)
    800071e4:	eaf42c23          	sw	a5,-328(s0)
        e.readable = f->readable;
    800071e8:	0084c783          	lbu	a5,8(s1)
    800071ec:	eaf42023          	sw	a5,-352(s0)
        e.writable = f->writable;
    800071f0:	0094c783          	lbu	a5,9(s1)
    800071f4:	eaf42223          	sw	a5,-348(s0)
        safestrcpy(e.path,f->path,MAXPATH);
    800071f8:	08000613          	li	a2,128
    800071fc:	02648593          	addi	a1,s1,38
    80007200:	de840513          	addi	a0,s0,-536
    80007204:	c0ff90ef          	jal	80000e12 <safestrcpy>

      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    80007208:	409c                	lw	a5,0(s1)
    8000720a:	4705                	li	a4,1
    8000720c:	04e78463          	beq	a5,a4,80007254 <state_dup_file+0xf4>
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    80007210:	4709                	li	a4,2
    80007212:	04e78b63          	beq	a5,a4,80007268 <state_dup_file+0x108>
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    80007216:	470d                	li	a4,3
    80007218:	06e78263          	beq	a5,a4,8000727c <state_dup_file+0x11c>
      else safestrcpy(e.file_type_str, "NONE", sizeof(e.file_type_str));
    8000721c:	4641                	li	a2,16
    8000721e:	00003597          	auipc	a1,0x3
    80007222:	a3258593          	addi	a1,a1,-1486 # 80009c50 <etext+0xc50>
    80007226:	e9040513          	addi	a0,s0,-368
    8000722a:	be9f90ef          	jal	80000e12 <safestrcpy>
    }

    fslog_push(&e);
    8000722e:	cc040513          	addi	a0,s0,-832
    80007232:	c2bff0ef          	jal	80006e5c <fslog_push>
    80007236:	33813083          	ld	ra,824(sp)
    8000723a:	33013403          	ld	s0,816(sp)
    8000723e:	32813483          	ld	s1,808(sp)
    80007242:	32013903          	ld	s2,800(sp)
    80007246:	31813983          	ld	s3,792(sp)
    8000724a:	31013a03          	ld	s4,784(sp)
    8000724e:	34010113          	addi	sp,sp,832
    80007252:	8082                	ret
      if(f->type == FD_PIPE) safestrcpy(e.file_type_str, "PIPE", sizeof(e.file_type_str));
    80007254:	4641                	li	a2,16
    80007256:	00003597          	auipc	a1,0x3
    8000725a:	9e258593          	addi	a1,a1,-1566 # 80009c38 <etext+0xc38>
    8000725e:	e9040513          	addi	a0,s0,-368
    80007262:	bb1f90ef          	jal	80000e12 <safestrcpy>
    80007266:	b7e1                	j	8000722e <state_dup_file+0xce>
      else if(f->type == FD_INODE) safestrcpy(e.file_type_str, "INODE", sizeof(e.file_type_str));
    80007268:	4641                	li	a2,16
    8000726a:	00003597          	auipc	a1,0x3
    8000726e:	9d658593          	addi	a1,a1,-1578 # 80009c40 <etext+0xc40>
    80007272:	e9040513          	addi	a0,s0,-368
    80007276:	b9df90ef          	jal	80000e12 <safestrcpy>
    8000727a:	bf55                	j	8000722e <state_dup_file+0xce>
      else if(f->type == FD_DEVICE) safestrcpy(e.file_type_str, "DEVICE", sizeof(e.file_type_str));
    8000727c:	4641                	li	a2,16
    8000727e:	00003597          	auipc	a1,0x3
    80007282:	9ca58593          	addi	a1,a1,-1590 # 80009c48 <etext+0xc48>
    80007286:	e9040513          	addi	a0,s0,-368
    8000728a:	b89f90ef          	jal	80000e12 <safestrcpy>
    8000728e:	b745                	j	8000722e <state_dup_file+0xce>
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0)
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	9282                	jalr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0)
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
