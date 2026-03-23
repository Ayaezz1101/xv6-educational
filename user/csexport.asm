
user/_csexport:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <append_char>:
#include "kernel/types.h"
#include "user/user.h"

#define OUTBUF_SZ 256

static void append_char(char *buf, int *pos, int max, char c) {
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  if (*pos < max - 1) {
   6:	419c                	lw	a5,0(a1)
   8:	367d                	addiw	a2,a2,-1
   a:	00c7d863          	bge	a5,a2,1a <append_char+0x1a>
    buf[*pos] = c;
   e:	953e                	add	a0,a0,a5
  10:	00d50023          	sb	a3,0(a0)
    (*pos)++;
  14:	419c                	lw	a5,0(a1)
  16:	2785                	addiw	a5,a5,1
  18:	c19c                	sw	a5,0(a1)
  }
}
  1a:	6422                	ld	s0,8(sp)
  1c:	0141                	addi	sp,sp,16
  1e:	8082                	ret

0000000000000020 <append_str>:

static void append_str(char *buf, int *pos, int max, const char *s) {
  20:	7179                	addi	sp,sp,-48
  22:	f406                	sd	ra,40(sp)
  24:	f022                	sd	s0,32(sp)
  26:	ec26                	sd	s1,24(sp)
  28:	e84a                	sd	s2,16(sp)
  2a:	e44e                	sd	s3,8(sp)
  2c:	e052                	sd	s4,0(sp)
  2e:	1800                	addi	s0,sp,48
  30:	8a2a                	mv	s4,a0
  32:	89ae                	mv	s3,a1
  34:	8932                	mv	s2,a2
  36:	84b6                	mv	s1,a3
  while (*s) {
  38:	0006c683          	lbu	a3,0(a3)
  3c:	ca91                	beqz	a3,50 <append_str+0x30>
    append_char(buf, pos, max, *s);
  3e:	864a                	mv	a2,s2
  40:	85ce                	mv	a1,s3
  42:	8552                	mv	a0,s4
  44:	fbdff0ef          	jal	0 <append_char>
    s++;
  48:	0485                	addi	s1,s1,1
  while (*s) {
  4a:	0004c683          	lbu	a3,0(s1)
  4e:	fae5                	bnez	a3,3e <append_str+0x1e>
  }
}
  50:	70a2                	ld	ra,40(sp)
  52:	7402                	ld	s0,32(sp)
  54:	64e2                	ld	s1,24(sp)
  56:	6942                	ld	s2,16(sp)
  58:	69a2                	ld	s3,8(sp)
  5a:	6a02                	ld	s4,0(sp)
  5c:	6145                	addi	sp,sp,48
  5e:	8082                	ret

0000000000000060 <append_uint>:

static void append_uint(char *buf, int *pos, int max, uint x) {
  60:	715d                	addi	sp,sp,-80
  62:	e486                	sd	ra,72(sp)
  64:	e0a2                	sd	s0,64(sp)
  66:	f84a                	sd	s2,48(sp)
  68:	f44e                	sd	s3,40(sp)
  6a:	f052                	sd	s4,32(sp)
  6c:	0880                	addi	s0,sp,80
  6e:	892a                	mv	s2,a0
  70:	89ae                	mv	s3,a1
  72:	8a32                	mv	s4,a2
  char tmp[16];
  int n = 0;

  if (x == 0) {
  74:	ca91                	beqz	a3,88 <append_uint+0x28>
  76:	ec56                	sd	s5,24(sp)
  78:	fb040a93          	addi	s5,s0,-80
  7c:	fc040513          	addi	a0,s0,-64
  80:	87d6                	mv	a5,s5
    append_char(buf, pos, max, '0');
    return;
  }

  while (x > 0 && n < (int)sizeof(tmp)) {
    tmp[n++] = '0' + (x % 10);
  82:	4629                	li	a2,10
  while (x > 0 && n < (int)sizeof(tmp)) {
  84:	45a5                	li	a1,9
  86:	a039                	j	94 <append_uint+0x34>
    append_char(buf, pos, max, '0');
  88:	03000693          	li	a3,48
  8c:	f75ff0ef          	jal	0 <append_char>
    return;
  90:	a08d                	j	f2 <append_uint+0x92>
  92:	87ba                	mv	a5,a4
    tmp[n++] = '0' + (x % 10);
  94:	02c6f73b          	remuw	a4,a3,a2
  98:	0307071b          	addiw	a4,a4,48
  9c:	00e78023          	sb	a4,0(a5)
    x /= 10;
  a0:	0006871b          	sext.w	a4,a3
  a4:	02c6d6bb          	divuw	a3,a3,a2
  while (x > 0 && n < (int)sizeof(tmp)) {
  a8:	00e5f663          	bgeu	a1,a4,b4 <append_uint+0x54>
  ac:	00178713          	addi	a4,a5,1
  b0:	fea711e3          	bne	a4,a0,92 <append_uint+0x32>
  b4:	415787bb          	subw	a5,a5,s5
  b8:	2785                	addiw	a5,a5,1
    tmp[n++] = '0' + (x % 10);
  ba:	0007871b          	sext.w	a4,a5
  }

  while (n > 0) {
  be:	04e05163          	blez	a4,100 <append_uint+0xa0>
  c2:	fc26                	sd	s1,56(sp)
  c4:	fb040693          	addi	a3,s0,-80
  c8:	00e684b3          	add	s1,a3,a4
  cc:	1afd                	addi	s5,s5,-1
  ce:	9aba                	add	s5,s5,a4
  d0:	37fd                	addiw	a5,a5,-1
  d2:	1782                	slli	a5,a5,0x20
  d4:	9381                	srli	a5,a5,0x20
  d6:	40fa8ab3          	sub	s5,s5,a5
    append_char(buf, pos, max, tmp[--n]);
  da:	fff4c683          	lbu	a3,-1(s1)
  de:	8652                	mv	a2,s4
  e0:	85ce                	mv	a1,s3
  e2:	854a                	mv	a0,s2
  e4:	f1dff0ef          	jal	0 <append_char>
  while (n > 0) {
  e8:	14fd                	addi	s1,s1,-1
  ea:	ff5498e3          	bne	s1,s5,da <append_uint+0x7a>
  ee:	74e2                	ld	s1,56(sp)
  f0:	6ae2                	ld	s5,24(sp)
  }
}
  f2:	60a6                	ld	ra,72(sp)
  f4:	6406                	ld	s0,64(sp)
  f6:	7942                	ld	s2,48(sp)
  f8:	79a2                	ld	s3,40(sp)
  fa:	7a02                	ld	s4,32(sp)
  fc:	6161                	addi	sp,sp,80
  fe:	8082                	ret
 100:	6ae2                	ld	s5,24(sp)
 102:	bfc5                	j	f2 <append_uint+0x92>

0000000000000104 <append_int>:

static void append_int(char *buf, int *pos, int max, int x) {
 104:	7179                	addi	sp,sp,-48
 106:	f406                	sd	ra,40(sp)
 108:	f022                	sd	s0,32(sp)
 10a:	ec26                	sd	s1,24(sp)
 10c:	e84a                	sd	s2,16(sp)
 10e:	e44e                	sd	s3,8(sp)
 110:	e052                	sd	s4,0(sp)
 112:	1800                	addi	s0,sp,48
 114:	892a                	mv	s2,a0
 116:	89ae                	mv	s3,a1
 118:	8a32                	mv	s4,a2
 11a:	84b6                	mv	s1,a3
  if (x < 0) {
 11c:	0206c063          	bltz	a3,13c <append_int+0x38>
    append_char(buf, pos, max, '-');
    x = -x;
  }
  append_uint(buf, pos, max, (uint)x);
 120:	86a6                	mv	a3,s1
 122:	8652                	mv	a2,s4
 124:	85ce                	mv	a1,s3
 126:	854a                	mv	a0,s2
 128:	f39ff0ef          	jal	60 <append_uint>
}
 12c:	70a2                	ld	ra,40(sp)
 12e:	7402                	ld	s0,32(sp)
 130:	64e2                	ld	s1,24(sp)
 132:	6942                	ld	s2,16(sp)
 134:	69a2                	ld	s3,8(sp)
 136:	6a02                	ld	s4,0(sp)
 138:	6145                	addi	sp,sp,48
 13a:	8082                	ret
    append_char(buf, pos, max, '-');
 13c:	02d00693          	li	a3,45
 140:	ec1ff0ef          	jal	0 <append_char>
    x = -x;
 144:	409004bb          	negw	s1,s1
 148:	bfe1                	j	120 <append_int+0x1c>

000000000000014a <main>:
  append_str(buf, &pos, OUTBUF_SZ, ",\"type\":\"ON_CPU\"}\n");

  write(1, buf, pos);
}

int main(void) {
 14a:	81010113          	addi	sp,sp,-2032
 14e:	7e113423          	sd	ra,2024(sp)
 152:	7e813023          	sd	s0,2016(sp)
 156:	7c913c23          	sd	s1,2008(sp)
 15a:	7d213823          	sd	s2,2000(sp)
 15e:	7d313423          	sd	s3,1992(sp)
 162:	7d413023          	sd	s4,1984(sp)
 166:	7b513c23          	sd	s5,1976(sp)
 16a:	7b613823          	sd	s6,1968(sp)
 16e:	7b713423          	sd	s7,1960(sp)
 172:	7b813023          	sd	s8,1952(sp)
 176:	79913c23          	sd	s9,1944(sp)
 17a:	79a13823          	sd	s10,1936(sp)
 17e:	79b13423          	sd	s11,1928(sp)
 182:	7f010413          	addi	s0,sp,2032
 186:	a6010113          	addi	sp,sp,-1440
  struct cs_event ev[64];

  while (1) {
    int n = csread(ev, 64);
 18a:	77fd                	lui	a5,0xfffff
 18c:	39078793          	addi	a5,a5,912 # fffffffffffff390 <base+0xffffffffffffe380>
 190:	97a2                	add	a5,a5,s0
 192:	777d                	lui	a4,0xfffff
 194:	27870713          	addi	a4,a4,632 # fffffffffffff278 <base+0xffffffffffffe268>
 198:	9722                	add	a4,a4,s0
 19a:	e31c                	sd	a5,0(a4)

    for (int i = 0; i < n; i++) {
      if (ev[i].type != CS_RUN_START)
 19c:	4d05                	li	s10,1
  int pos = 0;
 19e:	7dfd                	lui	s11,0xfffff
 1a0:	f90d8793          	addi	a5,s11,-112 # ffffffffffffef90 <base+0xffffffffffffdf80>
 1a4:	00878db3          	add	s11,a5,s0
  append_str(buf, &pos, OUTBUF_SZ, "EV {\"seq\":");
 1a8:	7afd                	lui	s5,0xfffff
 1aa:	28ca8793          	addi	a5,s5,652 # fffffffffffff28c <base+0xffffffffffffe27c>
 1ae:	00878ab3          	add	s5,a5,s0
 1b2:	79fd                	lui	s3,0xfffff
 1b4:	29098793          	addi	a5,s3,656 # fffffffffffff290 <base+0xffffffffffffe280>
 1b8:	008789b3          	add	s3,a5,s0
 1bc:	a811                	j	1d0 <main+0x86>
      if (ev[i].type != CS_RUN_START)
 1be:	8cd2                	mv	s9,s4
 1c0:	ff4a2783          	lw	a5,-12(s4)
 1c4:	03a78d63          	beq	a5,s10,1fe <main+0xb4>
    for (int i = 0; i < n; i++) {
 1c8:	030a0a13          	addi	s4,s4,48
 1cc:	ff6a19e3          	bne	s4,s6,1be <main+0x74>
    int n = csread(ev, 64);
 1d0:	04000593          	li	a1,64
 1d4:	74fd                	lui	s1,0xfffff
 1d6:	27848793          	addi	a5,s1,632 # fffffffffffff278 <base+0xffffffffffffe268>
 1da:	97a2                	add	a5,a5,s0
 1dc:	6388                	ld	a0,0(a5)
 1de:	4b6000ef          	jal	694 <csread>
    for (int i = 0; i < n; i++) {
 1e2:	fea057e3          	blez	a0,1d0 <main+0x86>
 1e6:	27848793          	addi	a5,s1,632
 1ea:	97a2                	add	a5,a5,s0
 1ec:	639c                	ld	a5,0(a5)
 1ee:	01c78a13          	addi	s4,a5,28
 1f2:	00151b13          	slli	s6,a0,0x1
 1f6:	9b2a                	add	s6,s6,a0
 1f8:	0b12                	slli	s6,s6,0x4
 1fa:	9b52                	add	s6,s6,s4
 1fc:	b7c9                	j	1be <main+0x74>
  int pos = 0;
 1fe:	2e0dae23          	sw	zero,764(s11)
  append_str(buf, &pos, OUTBUF_SZ, "EV {\"seq\":");
 202:	00001697          	auipc	a3,0x1
 206:	9ce68693          	addi	a3,a3,-1586 # bd0 <malloc+0xf8>
 20a:	10000613          	li	a2,256
 20e:	85d6                	mv	a1,s5
 210:	854e                	mv	a0,s3
 212:	e0fff0ef          	jal	20 <append_str>
  append_uint(buf, &pos, OUTBUF_SZ, (uint)e->seq);
 216:	fe4a2683          	lw	a3,-28(s4)
 21a:	10000613          	li	a2,256
 21e:	85d6                	mv	a1,s5
 220:	854e                	mv	a0,s3
 222:	e3fff0ef          	jal	60 <append_uint>
  append_str(buf, &pos, OUTBUF_SZ, ",\"tick\":");
 226:	00001697          	auipc	a3,0x1
 22a:	9ba68693          	addi	a3,a3,-1606 # be0 <malloc+0x108>
 22e:	10000613          	li	a2,256
 232:	85d6                	mv	a1,s5
 234:	854e                	mv	a0,s3
 236:	debff0ef          	jal	20 <append_str>
  append_uint(buf, &pos, OUTBUF_SZ, e->ticks);
 23a:	feca2683          	lw	a3,-20(s4)
 23e:	10000613          	li	a2,256
 242:	85d6                	mv	a1,s5
 244:	854e                	mv	a0,s3
 246:	e1bff0ef          	jal	60 <append_uint>
  append_str(buf, &pos, OUTBUF_SZ, ",\"cpu\":");
 24a:	00001697          	auipc	a3,0x1
 24e:	9a668693          	addi	a3,a3,-1626 # bf0 <malloc+0x118>
 252:	10000613          	li	a2,256
 256:	85d6                	mv	a1,s5
 258:	854e                	mv	a0,s3
 25a:	dc7ff0ef          	jal	20 <append_str>
  append_int(buf, &pos, OUTBUF_SZ, e->cpu);
 25e:	ff0a2683          	lw	a3,-16(s4)
 262:	10000613          	li	a2,256
 266:	85d6                	mv	a1,s5
 268:	854e                	mv	a0,s3
 26a:	e9bff0ef          	jal	104 <append_int>
  append_str(buf, &pos, OUTBUF_SZ, ",\"pid\":");
 26e:	00001697          	auipc	a3,0x1
 272:	98a68693          	addi	a3,a3,-1654 # bf8 <malloc+0x120>
 276:	10000613          	li	a2,256
 27a:	85d6                	mv	a1,s5
 27c:	854e                	mv	a0,s3
 27e:	da3ff0ef          	jal	20 <append_str>
  append_int(buf, &pos, OUTBUF_SZ, e->pid);
 282:	ff8a2683          	lw	a3,-8(s4)
 286:	10000613          	li	a2,256
 28a:	85d6                	mv	a1,s5
 28c:	854e                	mv	a0,s3
 28e:	e77ff0ef          	jal	104 <append_int>
  append_str(buf, &pos, OUTBUF_SZ, ",\"name\":\"");
 292:	00001697          	auipc	a3,0x1
 296:	96e68693          	addi	a3,a3,-1682 # c00 <malloc+0x128>
 29a:	10000613          	li	a2,256
 29e:	85d6                	mv	a1,s5
 2a0:	854e                	mv	a0,s3
 2a2:	d7fff0ef          	jal	20 <append_str>
  while (*s) {
 2a6:	000a4483          	lbu	s1,0(s4)
 2aa:	ccb1                	beqz	s1,306 <main+0x1bc>
 2ac:	8952                	mv	s2,s4
    if (c == '"' || c == '\\') {
 2ae:	02200b93          	li	s7,34
    } else if (c >= 32 && c < 127) {
 2b2:	05e00c13          	li	s8,94
 2b6:	a01d                	j	2dc <main+0x192>
      append_char(buf, pos, max, '\\');
 2b8:	05c00693          	li	a3,92
 2bc:	10000613          	li	a2,256
 2c0:	85d6                	mv	a1,s5
 2c2:	854e                	mv	a0,s3
 2c4:	d3dff0ef          	jal	0 <append_char>
      append_char(buf, pos, max, c);
 2c8:	86a6                	mv	a3,s1
 2ca:	10000613          	li	a2,256
 2ce:	85d6                	mv	a1,s5
 2d0:	854e                	mv	a0,s3
 2d2:	d2fff0ef          	jal	0 <append_char>
  while (*s) {
 2d6:	00094483          	lbu	s1,0(s2)
 2da:	c495                	beqz	s1,306 <main+0x1bc>
    char c = *s++;
 2dc:	0905                	addi	s2,s2,1
    if (c == '"' || c == '\\') {
 2de:	fd748de3          	beq	s1,s7,2b8 <main+0x16e>
 2e2:	05c00793          	li	a5,92
 2e6:	fcf489e3          	beq	s1,a5,2b8 <main+0x16e>
    } else if (c >= 32 && c < 127) {
 2ea:	fe04879b          	addiw	a5,s1,-32
 2ee:	0ff7f793          	zext.b	a5,a5
 2f2:	fefc62e3          	bltu	s8,a5,2d6 <main+0x18c>
      append_char(buf, pos, max, c);
 2f6:	86a6                	mv	a3,s1
 2f8:	10000613          	li	a2,256
 2fc:	85d6                	mv	a1,s5
 2fe:	854e                	mv	a0,s3
 300:	d01ff0ef          	jal	0 <append_char>
 304:	bfc9                	j	2d6 <main+0x18c>
  append_str(buf, &pos, OUTBUF_SZ, "\"");
 306:	00001697          	auipc	a3,0x1
 30a:	90268693          	addi	a3,a3,-1790 # c08 <malloc+0x130>
 30e:	10000613          	li	a2,256
 312:	85d6                	mv	a1,s5
 314:	854e                	mv	a0,s3
 316:	d0bff0ef          	jal	20 <append_str>
  append_str(buf, &pos, OUTBUF_SZ, ",\"state\":");
 31a:	00001697          	auipc	a3,0x1
 31e:	8f668693          	addi	a3,a3,-1802 # c10 <malloc+0x138>
 322:	10000613          	li	a2,256
 326:	85d6                	mv	a1,s5
 328:	854e                	mv	a0,s3
 32a:	cf7ff0ef          	jal	20 <append_str>
  append_int(buf, &pos, OUTBUF_SZ, e->state);
 32e:	ffcca683          	lw	a3,-4(s9)
 332:	10000613          	li	a2,256
 336:	85d6                	mv	a1,s5
 338:	854e                	mv	a0,s3
 33a:	dcbff0ef          	jal	104 <append_int>
  append_str(buf, &pos, OUTBUF_SZ, ",\"type\":\"ON_CPU\"}\n");
 33e:	00001697          	auipc	a3,0x1
 342:	8e268693          	addi	a3,a3,-1822 # c20 <malloc+0x148>
 346:	10000613          	li	a2,256
 34a:	85d6                	mv	a1,s5
 34c:	854e                	mv	a0,s3
 34e:	cd3ff0ef          	jal	20 <append_str>
  write(1, buf, pos);
 352:	2fcda603          	lw	a2,764(s11)
 356:	85ce                	mv	a1,s3
 358:	856a                	mv	a0,s10
 35a:	2ba000ef          	jal	614 <write>
}
 35e:	b5ad                	j	1c8 <main+0x7e>

0000000000000360 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 360:	1141                	addi	sp,sp,-16
 362:	e406                	sd	ra,8(sp)
 364:	e022                	sd	s0,0(sp)
 366:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 368:	de3ff0ef          	jal	14a <main>
  exit(r);
 36c:	288000ef          	jal	5f4 <exit>

0000000000000370 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 370:	1141                	addi	sp,sp,-16
 372:	e422                	sd	s0,8(sp)
 374:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 376:	87aa                	mv	a5,a0
 378:	0585                	addi	a1,a1,1
 37a:	0785                	addi	a5,a5,1
 37c:	fff5c703          	lbu	a4,-1(a1)
 380:	fee78fa3          	sb	a4,-1(a5)
 384:	fb75                	bnez	a4,378 <strcpy+0x8>
    ;
  return os;
}
 386:	6422                	ld	s0,8(sp)
 388:	0141                	addi	sp,sp,16
 38a:	8082                	ret

000000000000038c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 38c:	1141                	addi	sp,sp,-16
 38e:	e422                	sd	s0,8(sp)
 390:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 392:	00054783          	lbu	a5,0(a0)
 396:	cb91                	beqz	a5,3aa <strcmp+0x1e>
 398:	0005c703          	lbu	a4,0(a1)
 39c:	00f71763          	bne	a4,a5,3aa <strcmp+0x1e>
    p++, q++;
 3a0:	0505                	addi	a0,a0,1
 3a2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 3a4:	00054783          	lbu	a5,0(a0)
 3a8:	fbe5                	bnez	a5,398 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 3aa:	0005c503          	lbu	a0,0(a1)
}
 3ae:	40a7853b          	subw	a0,a5,a0
 3b2:	6422                	ld	s0,8(sp)
 3b4:	0141                	addi	sp,sp,16
 3b6:	8082                	ret

00000000000003b8 <strlen>:

uint
strlen(const char *s)
{
 3b8:	1141                	addi	sp,sp,-16
 3ba:	e422                	sd	s0,8(sp)
 3bc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 3be:	00054783          	lbu	a5,0(a0)
 3c2:	cf91                	beqz	a5,3de <strlen+0x26>
 3c4:	0505                	addi	a0,a0,1
 3c6:	87aa                	mv	a5,a0
 3c8:	86be                	mv	a3,a5
 3ca:	0785                	addi	a5,a5,1
 3cc:	fff7c703          	lbu	a4,-1(a5)
 3d0:	ff65                	bnez	a4,3c8 <strlen+0x10>
 3d2:	40a6853b          	subw	a0,a3,a0
 3d6:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 3d8:	6422                	ld	s0,8(sp)
 3da:	0141                	addi	sp,sp,16
 3dc:	8082                	ret
  for(n = 0; s[n]; n++)
 3de:	4501                	li	a0,0
 3e0:	bfe5                	j	3d8 <strlen+0x20>

00000000000003e2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3e2:	1141                	addi	sp,sp,-16
 3e4:	e422                	sd	s0,8(sp)
 3e6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3e8:	ca19                	beqz	a2,3fe <memset+0x1c>
 3ea:	87aa                	mv	a5,a0
 3ec:	1602                	slli	a2,a2,0x20
 3ee:	9201                	srli	a2,a2,0x20
 3f0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3f4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3f8:	0785                	addi	a5,a5,1
 3fa:	fee79de3          	bne	a5,a4,3f4 <memset+0x12>
  }
  return dst;
}
 3fe:	6422                	ld	s0,8(sp)
 400:	0141                	addi	sp,sp,16
 402:	8082                	ret

0000000000000404 <strchr>:

char*
strchr(const char *s, char c)
{
 404:	1141                	addi	sp,sp,-16
 406:	e422                	sd	s0,8(sp)
 408:	0800                	addi	s0,sp,16
  for(; *s; s++)
 40a:	00054783          	lbu	a5,0(a0)
 40e:	cb99                	beqz	a5,424 <strchr+0x20>
    if(*s == c)
 410:	00f58763          	beq	a1,a5,41e <strchr+0x1a>
  for(; *s; s++)
 414:	0505                	addi	a0,a0,1
 416:	00054783          	lbu	a5,0(a0)
 41a:	fbfd                	bnez	a5,410 <strchr+0xc>
      return (char*)s;
  return 0;
 41c:	4501                	li	a0,0
}
 41e:	6422                	ld	s0,8(sp)
 420:	0141                	addi	sp,sp,16
 422:	8082                	ret
  return 0;
 424:	4501                	li	a0,0
 426:	bfe5                	j	41e <strchr+0x1a>

0000000000000428 <gets>:

char*
gets(char *buf, int max)
{
 428:	711d                	addi	sp,sp,-96
 42a:	ec86                	sd	ra,88(sp)
 42c:	e8a2                	sd	s0,80(sp)
 42e:	e4a6                	sd	s1,72(sp)
 430:	e0ca                	sd	s2,64(sp)
 432:	fc4e                	sd	s3,56(sp)
 434:	f852                	sd	s4,48(sp)
 436:	f456                	sd	s5,40(sp)
 438:	f05a                	sd	s6,32(sp)
 43a:	ec5e                	sd	s7,24(sp)
 43c:	1080                	addi	s0,sp,96
 43e:	8baa                	mv	s7,a0
 440:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 442:	892a                	mv	s2,a0
 444:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 446:	4aa9                	li	s5,10
 448:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 44a:	89a6                	mv	s3,s1
 44c:	2485                	addiw	s1,s1,1
 44e:	0344d663          	bge	s1,s4,47a <gets+0x52>
    cc = read(0, &c, 1);
 452:	4605                	li	a2,1
 454:	faf40593          	addi	a1,s0,-81
 458:	4501                	li	a0,0
 45a:	1b2000ef          	jal	60c <read>
    if(cc < 1)
 45e:	00a05e63          	blez	a0,47a <gets+0x52>
    buf[i++] = c;
 462:	faf44783          	lbu	a5,-81(s0)
 466:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 46a:	01578763          	beq	a5,s5,478 <gets+0x50>
 46e:	0905                	addi	s2,s2,1
 470:	fd679de3          	bne	a5,s6,44a <gets+0x22>
    buf[i++] = c;
 474:	89a6                	mv	s3,s1
 476:	a011                	j	47a <gets+0x52>
 478:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 47a:	99de                	add	s3,s3,s7
 47c:	00098023          	sb	zero,0(s3)
  return buf;
}
 480:	855e                	mv	a0,s7
 482:	60e6                	ld	ra,88(sp)
 484:	6446                	ld	s0,80(sp)
 486:	64a6                	ld	s1,72(sp)
 488:	6906                	ld	s2,64(sp)
 48a:	79e2                	ld	s3,56(sp)
 48c:	7a42                	ld	s4,48(sp)
 48e:	7aa2                	ld	s5,40(sp)
 490:	7b02                	ld	s6,32(sp)
 492:	6be2                	ld	s7,24(sp)
 494:	6125                	addi	sp,sp,96
 496:	8082                	ret

0000000000000498 <stat>:

int
stat(const char *n, struct stat *st)
{
 498:	1101                	addi	sp,sp,-32
 49a:	ec06                	sd	ra,24(sp)
 49c:	e822                	sd	s0,16(sp)
 49e:	e04a                	sd	s2,0(sp)
 4a0:	1000                	addi	s0,sp,32
 4a2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 4a4:	4581                	li	a1,0
 4a6:	18e000ef          	jal	634 <open>
  if(fd < 0)
 4aa:	02054263          	bltz	a0,4ce <stat+0x36>
 4ae:	e426                	sd	s1,8(sp)
 4b0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 4b2:	85ca                	mv	a1,s2
 4b4:	198000ef          	jal	64c <fstat>
 4b8:	892a                	mv	s2,a0
  close(fd);
 4ba:	8526                	mv	a0,s1
 4bc:	160000ef          	jal	61c <close>
  return r;
 4c0:	64a2                	ld	s1,8(sp)
}
 4c2:	854a                	mv	a0,s2
 4c4:	60e2                	ld	ra,24(sp)
 4c6:	6442                	ld	s0,16(sp)
 4c8:	6902                	ld	s2,0(sp)
 4ca:	6105                	addi	sp,sp,32
 4cc:	8082                	ret
    return -1;
 4ce:	597d                	li	s2,-1
 4d0:	bfcd                	j	4c2 <stat+0x2a>

00000000000004d2 <atoi>:

int
atoi(const char *s)
{
 4d2:	1141                	addi	sp,sp,-16
 4d4:	e422                	sd	s0,8(sp)
 4d6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4d8:	00054683          	lbu	a3,0(a0)
 4dc:	fd06879b          	addiw	a5,a3,-48
 4e0:	0ff7f793          	zext.b	a5,a5
 4e4:	4625                	li	a2,9
 4e6:	02f66863          	bltu	a2,a5,516 <atoi+0x44>
 4ea:	872a                	mv	a4,a0
  n = 0;
 4ec:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 4ee:	0705                	addi	a4,a4,1
 4f0:	0025179b          	slliw	a5,a0,0x2
 4f4:	9fa9                	addw	a5,a5,a0
 4f6:	0017979b          	slliw	a5,a5,0x1
 4fa:	9fb5                	addw	a5,a5,a3
 4fc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 500:	00074683          	lbu	a3,0(a4)
 504:	fd06879b          	addiw	a5,a3,-48
 508:	0ff7f793          	zext.b	a5,a5
 50c:	fef671e3          	bgeu	a2,a5,4ee <atoi+0x1c>
  return n;
}
 510:	6422                	ld	s0,8(sp)
 512:	0141                	addi	sp,sp,16
 514:	8082                	ret
  n = 0;
 516:	4501                	li	a0,0
 518:	bfe5                	j	510 <atoi+0x3e>

000000000000051a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 51a:	1141                	addi	sp,sp,-16
 51c:	e422                	sd	s0,8(sp)
 51e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 520:	02b57463          	bgeu	a0,a1,548 <memmove+0x2e>
    while(n-- > 0)
 524:	00c05f63          	blez	a2,542 <memmove+0x28>
 528:	1602                	slli	a2,a2,0x20
 52a:	9201                	srli	a2,a2,0x20
 52c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 530:	872a                	mv	a4,a0
      *dst++ = *src++;
 532:	0585                	addi	a1,a1,1
 534:	0705                	addi	a4,a4,1
 536:	fff5c683          	lbu	a3,-1(a1)
 53a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 53e:	fef71ae3          	bne	a4,a5,532 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 542:	6422                	ld	s0,8(sp)
 544:	0141                	addi	sp,sp,16
 546:	8082                	ret
    dst += n;
 548:	00c50733          	add	a4,a0,a2
    src += n;
 54c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 54e:	fec05ae3          	blez	a2,542 <memmove+0x28>
 552:	fff6079b          	addiw	a5,a2,-1
 556:	1782                	slli	a5,a5,0x20
 558:	9381                	srli	a5,a5,0x20
 55a:	fff7c793          	not	a5,a5
 55e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 560:	15fd                	addi	a1,a1,-1
 562:	177d                	addi	a4,a4,-1
 564:	0005c683          	lbu	a3,0(a1)
 568:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 56c:	fee79ae3          	bne	a5,a4,560 <memmove+0x46>
 570:	bfc9                	j	542 <memmove+0x28>

0000000000000572 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 572:	1141                	addi	sp,sp,-16
 574:	e422                	sd	s0,8(sp)
 576:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 578:	ca05                	beqz	a2,5a8 <memcmp+0x36>
 57a:	fff6069b          	addiw	a3,a2,-1
 57e:	1682                	slli	a3,a3,0x20
 580:	9281                	srli	a3,a3,0x20
 582:	0685                	addi	a3,a3,1
 584:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 586:	00054783          	lbu	a5,0(a0)
 58a:	0005c703          	lbu	a4,0(a1)
 58e:	00e79863          	bne	a5,a4,59e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 592:	0505                	addi	a0,a0,1
    p2++;
 594:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 596:	fed518e3          	bne	a0,a3,586 <memcmp+0x14>
  }
  return 0;
 59a:	4501                	li	a0,0
 59c:	a019                	j	5a2 <memcmp+0x30>
      return *p1 - *p2;
 59e:	40e7853b          	subw	a0,a5,a4
}
 5a2:	6422                	ld	s0,8(sp)
 5a4:	0141                	addi	sp,sp,16
 5a6:	8082                	ret
  return 0;
 5a8:	4501                	li	a0,0
 5aa:	bfe5                	j	5a2 <memcmp+0x30>

00000000000005ac <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 5ac:	1141                	addi	sp,sp,-16
 5ae:	e406                	sd	ra,8(sp)
 5b0:	e022                	sd	s0,0(sp)
 5b2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 5b4:	f67ff0ef          	jal	51a <memmove>
}
 5b8:	60a2                	ld	ra,8(sp)
 5ba:	6402                	ld	s0,0(sp)
 5bc:	0141                	addi	sp,sp,16
 5be:	8082                	ret

00000000000005c0 <sbrk>:

char *
sbrk(int n) {
 5c0:	1141                	addi	sp,sp,-16
 5c2:	e406                	sd	ra,8(sp)
 5c4:	e022                	sd	s0,0(sp)
 5c6:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 5c8:	4585                	li	a1,1
 5ca:	0b2000ef          	jal	67c <sys_sbrk>
}
 5ce:	60a2                	ld	ra,8(sp)
 5d0:	6402                	ld	s0,0(sp)
 5d2:	0141                	addi	sp,sp,16
 5d4:	8082                	ret

00000000000005d6 <sbrklazy>:

char *
sbrklazy(int n) {
 5d6:	1141                	addi	sp,sp,-16
 5d8:	e406                	sd	ra,8(sp)
 5da:	e022                	sd	s0,0(sp)
 5dc:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 5de:	4589                	li	a1,2
 5e0:	09c000ef          	jal	67c <sys_sbrk>
}
 5e4:	60a2                	ld	ra,8(sp)
 5e6:	6402                	ld	s0,0(sp)
 5e8:	0141                	addi	sp,sp,16
 5ea:	8082                	ret

00000000000005ec <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5ec:	4885                	li	a7,1
 ecall
 5ee:	00000073          	ecall
 ret
 5f2:	8082                	ret

00000000000005f4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5f4:	4889                	li	a7,2
 ecall
 5f6:	00000073          	ecall
 ret
 5fa:	8082                	ret

00000000000005fc <wait>:
.global wait
wait:
 li a7, SYS_wait
 5fc:	488d                	li	a7,3
 ecall
 5fe:	00000073          	ecall
 ret
 602:	8082                	ret

0000000000000604 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 604:	4891                	li	a7,4
 ecall
 606:	00000073          	ecall
 ret
 60a:	8082                	ret

000000000000060c <read>:
.global read
read:
 li a7, SYS_read
 60c:	4895                	li	a7,5
 ecall
 60e:	00000073          	ecall
 ret
 612:	8082                	ret

0000000000000614 <write>:
.global write
write:
 li a7, SYS_write
 614:	48c1                	li	a7,16
 ecall
 616:	00000073          	ecall
 ret
 61a:	8082                	ret

000000000000061c <close>:
.global close
close:
 li a7, SYS_close
 61c:	48d5                	li	a7,21
 ecall
 61e:	00000073          	ecall
 ret
 622:	8082                	ret

0000000000000624 <kill>:
.global kill
kill:
 li a7, SYS_kill
 624:	4899                	li	a7,6
 ecall
 626:	00000073          	ecall
 ret
 62a:	8082                	ret

000000000000062c <exec>:
.global exec
exec:
 li a7, SYS_exec
 62c:	489d                	li	a7,7
 ecall
 62e:	00000073          	ecall
 ret
 632:	8082                	ret

0000000000000634 <open>:
.global open
open:
 li a7, SYS_open
 634:	48bd                	li	a7,15
 ecall
 636:	00000073          	ecall
 ret
 63a:	8082                	ret

000000000000063c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 63c:	48c5                	li	a7,17
 ecall
 63e:	00000073          	ecall
 ret
 642:	8082                	ret

0000000000000644 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 644:	48c9                	li	a7,18
 ecall
 646:	00000073          	ecall
 ret
 64a:	8082                	ret

000000000000064c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 64c:	48a1                	li	a7,8
 ecall
 64e:	00000073          	ecall
 ret
 652:	8082                	ret

0000000000000654 <link>:
.global link
link:
 li a7, SYS_link
 654:	48cd                	li	a7,19
 ecall
 656:	00000073          	ecall
 ret
 65a:	8082                	ret

000000000000065c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 65c:	48d1                	li	a7,20
 ecall
 65e:	00000073          	ecall
 ret
 662:	8082                	ret

0000000000000664 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 664:	48a5                	li	a7,9
 ecall
 666:	00000073          	ecall
 ret
 66a:	8082                	ret

000000000000066c <dup>:
.global dup
dup:
 li a7, SYS_dup
 66c:	48a9                	li	a7,10
 ecall
 66e:	00000073          	ecall
 ret
 672:	8082                	ret

0000000000000674 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 674:	48ad                	li	a7,11
 ecall
 676:	00000073          	ecall
 ret
 67a:	8082                	ret

000000000000067c <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 67c:	48b1                	li	a7,12
 ecall
 67e:	00000073          	ecall
 ret
 682:	8082                	ret

0000000000000684 <pause>:
.global pause
pause:
 li a7, SYS_pause
 684:	48b5                	li	a7,13
 ecall
 686:	00000073          	ecall
 ret
 68a:	8082                	ret

000000000000068c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 68c:	48b9                	li	a7,14
 ecall
 68e:	00000073          	ecall
 ret
 692:	8082                	ret

0000000000000694 <csread>:
.global csread
csread:
 li a7, SYS_csread
 694:	48d9                	li	a7,22
 ecall
 696:	00000073          	ecall
 ret
 69a:	8082                	ret

000000000000069c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 69c:	1101                	addi	sp,sp,-32
 69e:	ec06                	sd	ra,24(sp)
 6a0:	e822                	sd	s0,16(sp)
 6a2:	1000                	addi	s0,sp,32
 6a4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 6a8:	4605                	li	a2,1
 6aa:	fef40593          	addi	a1,s0,-17
 6ae:	f67ff0ef          	jal	614 <write>
}
 6b2:	60e2                	ld	ra,24(sp)
 6b4:	6442                	ld	s0,16(sp)
 6b6:	6105                	addi	sp,sp,32
 6b8:	8082                	ret

00000000000006ba <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 6ba:	715d                	addi	sp,sp,-80
 6bc:	e486                	sd	ra,72(sp)
 6be:	e0a2                	sd	s0,64(sp)
 6c0:	f84a                	sd	s2,48(sp)
 6c2:	0880                	addi	s0,sp,80
 6c4:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 6c6:	c299                	beqz	a3,6cc <printint+0x12>
 6c8:	0805c363          	bltz	a1,74e <printint+0x94>
  neg = 0;
 6cc:	4881                	li	a7,0
 6ce:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 6d2:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 6d4:	00000517          	auipc	a0,0x0
 6d8:	56c50513          	addi	a0,a0,1388 # c40 <digits>
 6dc:	883e                	mv	a6,a5
 6de:	2785                	addiw	a5,a5,1
 6e0:	02c5f733          	remu	a4,a1,a2
 6e4:	972a                	add	a4,a4,a0
 6e6:	00074703          	lbu	a4,0(a4)
 6ea:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 6ee:	872e                	mv	a4,a1
 6f0:	02c5d5b3          	divu	a1,a1,a2
 6f4:	0685                	addi	a3,a3,1
 6f6:	fec773e3          	bgeu	a4,a2,6dc <printint+0x22>
  if(neg)
 6fa:	00088b63          	beqz	a7,710 <printint+0x56>
    buf[i++] = '-';
 6fe:	fd078793          	addi	a5,a5,-48
 702:	97a2                	add	a5,a5,s0
 704:	02d00713          	li	a4,45
 708:	fee78423          	sb	a4,-24(a5)
 70c:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 710:	02f05a63          	blez	a5,744 <printint+0x8a>
 714:	fc26                	sd	s1,56(sp)
 716:	f44e                	sd	s3,40(sp)
 718:	fb840713          	addi	a4,s0,-72
 71c:	00f704b3          	add	s1,a4,a5
 720:	fff70993          	addi	s3,a4,-1
 724:	99be                	add	s3,s3,a5
 726:	37fd                	addiw	a5,a5,-1
 728:	1782                	slli	a5,a5,0x20
 72a:	9381                	srli	a5,a5,0x20
 72c:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 730:	fff4c583          	lbu	a1,-1(s1)
 734:	854a                	mv	a0,s2
 736:	f67ff0ef          	jal	69c <putc>
  while(--i >= 0)
 73a:	14fd                	addi	s1,s1,-1
 73c:	ff349ae3          	bne	s1,s3,730 <printint+0x76>
 740:	74e2                	ld	s1,56(sp)
 742:	79a2                	ld	s3,40(sp)
}
 744:	60a6                	ld	ra,72(sp)
 746:	6406                	ld	s0,64(sp)
 748:	7942                	ld	s2,48(sp)
 74a:	6161                	addi	sp,sp,80
 74c:	8082                	ret
    x = -xx;
 74e:	40b005b3          	neg	a1,a1
    neg = 1;
 752:	4885                	li	a7,1
    x = -xx;
 754:	bfad                	j	6ce <printint+0x14>

0000000000000756 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 756:	711d                	addi	sp,sp,-96
 758:	ec86                	sd	ra,88(sp)
 75a:	e8a2                	sd	s0,80(sp)
 75c:	e0ca                	sd	s2,64(sp)
 75e:	1080                	addi	s0,sp,96
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 760:	0005c903          	lbu	s2,0(a1)
 764:	28090663          	beqz	s2,9f0 <vprintf+0x29a>
 768:	e4a6                	sd	s1,72(sp)
 76a:	fc4e                	sd	s3,56(sp)
 76c:	f852                	sd	s4,48(sp)
 76e:	f456                	sd	s5,40(sp)
 770:	f05a                	sd	s6,32(sp)
 772:	ec5e                	sd	s7,24(sp)
 774:	e862                	sd	s8,16(sp)
 776:	e466                	sd	s9,8(sp)
 778:	8b2a                	mv	s6,a0
 77a:	8a2e                	mv	s4,a1
 77c:	8bb2                	mv	s7,a2
  state = 0;
 77e:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 780:	4481                	li	s1,0
 782:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 784:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 788:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 78c:	06c00c93          	li	s9,108
 790:	a005                	j	7b0 <vprintf+0x5a>
        putc(fd, c0);
 792:	85ca                	mv	a1,s2
 794:	855a                	mv	a0,s6
 796:	f07ff0ef          	jal	69c <putc>
 79a:	a019                	j	7a0 <vprintf+0x4a>
    } else if(state == '%'){
 79c:	03598263          	beq	s3,s5,7c0 <vprintf+0x6a>
  for(i = 0; fmt[i]; i++){
 7a0:	2485                	addiw	s1,s1,1
 7a2:	8726                	mv	a4,s1
 7a4:	009a07b3          	add	a5,s4,s1
 7a8:	0007c903          	lbu	s2,0(a5)
 7ac:	22090a63          	beqz	s2,9e0 <vprintf+0x28a>
    c0 = fmt[i] & 0xff;
 7b0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 7b4:	fe0994e3          	bnez	s3,79c <vprintf+0x46>
      if(c0 == '%'){
 7b8:	fd579de3          	bne	a5,s5,792 <vprintf+0x3c>
        state = '%';
 7bc:	89be                	mv	s3,a5
 7be:	b7cd                	j	7a0 <vprintf+0x4a>
      if(c0) c1 = fmt[i+1] & 0xff;
 7c0:	00ea06b3          	add	a3,s4,a4
 7c4:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 7c8:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 7ca:	c681                	beqz	a3,7d2 <vprintf+0x7c>
 7cc:	9752                	add	a4,a4,s4
 7ce:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 7d2:	05878363          	beq	a5,s8,818 <vprintf+0xc2>
      } else if(c0 == 'l' && c1 == 'd'){
 7d6:	05978d63          	beq	a5,s9,830 <vprintf+0xda>
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 7da:	07500713          	li	a4,117
 7de:	0ee78763          	beq	a5,a4,8cc <vprintf+0x176>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 7e2:	07800713          	li	a4,120
 7e6:	12e78963          	beq	a5,a4,918 <vprintf+0x1c2>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 7ea:	07000713          	li	a4,112
 7ee:	14e78e63          	beq	a5,a4,94a <vprintf+0x1f4>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 7f2:	06300713          	li	a4,99
 7f6:	18e78e63          	beq	a5,a4,992 <vprintf+0x23c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 7fa:	07300713          	li	a4,115
 7fe:	1ae78463          	beq	a5,a4,9a6 <vprintf+0x250>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 802:	02500713          	li	a4,37
 806:	04e79563          	bne	a5,a4,850 <vprintf+0xfa>
        putc(fd, '%');
 80a:	02500593          	li	a1,37
 80e:	855a                	mv	a0,s6
 810:	e8dff0ef          	jal	69c <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 814:	4981                	li	s3,0
 816:	b769                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, int), 10, 1);
 818:	008b8913          	addi	s2,s7,8
 81c:	4685                	li	a3,1
 81e:	4629                	li	a2,10
 820:	000ba583          	lw	a1,0(s7)
 824:	855a                	mv	a0,s6
 826:	e95ff0ef          	jal	6ba <printint>
 82a:	8bca                	mv	s7,s2
      state = 0;
 82c:	4981                	li	s3,0
 82e:	bf8d                	j	7a0 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'd'){
 830:	06400793          	li	a5,100
 834:	02f68963          	beq	a3,a5,866 <vprintf+0x110>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 838:	06c00793          	li	a5,108
 83c:	04f68263          	beq	a3,a5,880 <vprintf+0x12a>
      } else if(c0 == 'l' && c1 == 'u'){
 840:	07500793          	li	a5,117
 844:	0af68063          	beq	a3,a5,8e4 <vprintf+0x18e>
      } else if(c0 == 'l' && c1 == 'x'){
 848:	07800793          	li	a5,120
 84c:	0ef68263          	beq	a3,a5,930 <vprintf+0x1da>
        putc(fd, '%');
 850:	02500593          	li	a1,37
 854:	855a                	mv	a0,s6
 856:	e47ff0ef          	jal	69c <putc>
        putc(fd, c0);
 85a:	85ca                	mv	a1,s2
 85c:	855a                	mv	a0,s6
 85e:	e3fff0ef          	jal	69c <putc>
      state = 0;
 862:	4981                	li	s3,0
 864:	bf35                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 866:	008b8913          	addi	s2,s7,8
 86a:	4685                	li	a3,1
 86c:	4629                	li	a2,10
 86e:	000bb583          	ld	a1,0(s7)
 872:	855a                	mv	a0,s6
 874:	e47ff0ef          	jal	6ba <printint>
        i += 1;
 878:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 87a:	8bca                	mv	s7,s2
      state = 0;
 87c:	4981                	li	s3,0
        i += 1;
 87e:	b70d                	j	7a0 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 880:	06400793          	li	a5,100
 884:	02f60763          	beq	a2,a5,8b2 <vprintf+0x15c>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 888:	07500793          	li	a5,117
 88c:	06f60963          	beq	a2,a5,8fe <vprintf+0x1a8>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 890:	07800793          	li	a5,120
 894:	faf61ee3          	bne	a2,a5,850 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 898:	008b8913          	addi	s2,s7,8
 89c:	4681                	li	a3,0
 89e:	4641                	li	a2,16
 8a0:	000bb583          	ld	a1,0(s7)
 8a4:	855a                	mv	a0,s6
 8a6:	e15ff0ef          	jal	6ba <printint>
        i += 2;
 8aa:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 8ac:	8bca                	mv	s7,s2
      state = 0;
 8ae:	4981                	li	s3,0
        i += 2;
 8b0:	bdc5                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 8b2:	008b8913          	addi	s2,s7,8
 8b6:	4685                	li	a3,1
 8b8:	4629                	li	a2,10
 8ba:	000bb583          	ld	a1,0(s7)
 8be:	855a                	mv	a0,s6
 8c0:	dfbff0ef          	jal	6ba <printint>
        i += 2;
 8c4:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 8c6:	8bca                	mv	s7,s2
      state = 0;
 8c8:	4981                	li	s3,0
        i += 2;
 8ca:	bdd9                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 8cc:	008b8913          	addi	s2,s7,8
 8d0:	4681                	li	a3,0
 8d2:	4629                	li	a2,10
 8d4:	000be583          	lwu	a1,0(s7)
 8d8:	855a                	mv	a0,s6
 8da:	de1ff0ef          	jal	6ba <printint>
 8de:	8bca                	mv	s7,s2
      state = 0;
 8e0:	4981                	li	s3,0
 8e2:	bd7d                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 8e4:	008b8913          	addi	s2,s7,8
 8e8:	4681                	li	a3,0
 8ea:	4629                	li	a2,10
 8ec:	000bb583          	ld	a1,0(s7)
 8f0:	855a                	mv	a0,s6
 8f2:	dc9ff0ef          	jal	6ba <printint>
        i += 1;
 8f6:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 8f8:	8bca                	mv	s7,s2
      state = 0;
 8fa:	4981                	li	s3,0
        i += 1;
 8fc:	b555                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 8fe:	008b8913          	addi	s2,s7,8
 902:	4681                	li	a3,0
 904:	4629                	li	a2,10
 906:	000bb583          	ld	a1,0(s7)
 90a:	855a                	mv	a0,s6
 90c:	dafff0ef          	jal	6ba <printint>
        i += 2;
 910:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 912:	8bca                	mv	s7,s2
      state = 0;
 914:	4981                	li	s3,0
        i += 2;
 916:	b569                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 918:	008b8913          	addi	s2,s7,8
 91c:	4681                	li	a3,0
 91e:	4641                	li	a2,16
 920:	000be583          	lwu	a1,0(s7)
 924:	855a                	mv	a0,s6
 926:	d95ff0ef          	jal	6ba <printint>
 92a:	8bca                	mv	s7,s2
      state = 0;
 92c:	4981                	li	s3,0
 92e:	bd8d                	j	7a0 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 930:	008b8913          	addi	s2,s7,8
 934:	4681                	li	a3,0
 936:	4641                	li	a2,16
 938:	000bb583          	ld	a1,0(s7)
 93c:	855a                	mv	a0,s6
 93e:	d7dff0ef          	jal	6ba <printint>
        i += 1;
 942:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 944:	8bca                	mv	s7,s2
      state = 0;
 946:	4981                	li	s3,0
        i += 1;
 948:	bda1                	j	7a0 <vprintf+0x4a>
 94a:	e06a                	sd	s10,0(sp)
        printptr(fd, va_arg(ap, uint64));
 94c:	008b8d13          	addi	s10,s7,8
 950:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 954:	03000593          	li	a1,48
 958:	855a                	mv	a0,s6
 95a:	d43ff0ef          	jal	69c <putc>
  putc(fd, 'x');
 95e:	07800593          	li	a1,120
 962:	855a                	mv	a0,s6
 964:	d39ff0ef          	jal	69c <putc>
 968:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 96a:	00000b97          	auipc	s7,0x0
 96e:	2d6b8b93          	addi	s7,s7,726 # c40 <digits>
 972:	03c9d793          	srli	a5,s3,0x3c
 976:	97de                	add	a5,a5,s7
 978:	0007c583          	lbu	a1,0(a5)
 97c:	855a                	mv	a0,s6
 97e:	d1fff0ef          	jal	69c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 982:	0992                	slli	s3,s3,0x4
 984:	397d                	addiw	s2,s2,-1
 986:	fe0916e3          	bnez	s2,972 <vprintf+0x21c>
        printptr(fd, va_arg(ap, uint64));
 98a:	8bea                	mv	s7,s10
      state = 0;
 98c:	4981                	li	s3,0
 98e:	6d02                	ld	s10,0(sp)
 990:	bd01                	j	7a0 <vprintf+0x4a>
        putc(fd, va_arg(ap, uint32));
 992:	008b8913          	addi	s2,s7,8
 996:	000bc583          	lbu	a1,0(s7)
 99a:	855a                	mv	a0,s6
 99c:	d01ff0ef          	jal	69c <putc>
 9a0:	8bca                	mv	s7,s2
      state = 0;
 9a2:	4981                	li	s3,0
 9a4:	bbf5                	j	7a0 <vprintf+0x4a>
        if((s = va_arg(ap, char*)) == 0)
 9a6:	008b8993          	addi	s3,s7,8
 9aa:	000bb903          	ld	s2,0(s7)
 9ae:	00090f63          	beqz	s2,9cc <vprintf+0x276>
        for(; *s; s++)
 9b2:	00094583          	lbu	a1,0(s2)
 9b6:	c195                	beqz	a1,9da <vprintf+0x284>
          putc(fd, *s);
 9b8:	855a                	mv	a0,s6
 9ba:	ce3ff0ef          	jal	69c <putc>
        for(; *s; s++)
 9be:	0905                	addi	s2,s2,1
 9c0:	00094583          	lbu	a1,0(s2)
 9c4:	f9f5                	bnez	a1,9b8 <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 9c6:	8bce                	mv	s7,s3
      state = 0;
 9c8:	4981                	li	s3,0
 9ca:	bbd9                	j	7a0 <vprintf+0x4a>
          s = "(null)";
 9cc:	00000917          	auipc	s2,0x0
 9d0:	26c90913          	addi	s2,s2,620 # c38 <malloc+0x160>
        for(; *s; s++)
 9d4:	02800593          	li	a1,40
 9d8:	b7c5                	j	9b8 <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 9da:	8bce                	mv	s7,s3
      state = 0;
 9dc:	4981                	li	s3,0
 9de:	b3c9                	j	7a0 <vprintf+0x4a>
 9e0:	64a6                	ld	s1,72(sp)
 9e2:	79e2                	ld	s3,56(sp)
 9e4:	7a42                	ld	s4,48(sp)
 9e6:	7aa2                	ld	s5,40(sp)
 9e8:	7b02                	ld	s6,32(sp)
 9ea:	6be2                	ld	s7,24(sp)
 9ec:	6c42                	ld	s8,16(sp)
 9ee:	6ca2                	ld	s9,8(sp)
    }
  }
}
 9f0:	60e6                	ld	ra,88(sp)
 9f2:	6446                	ld	s0,80(sp)
 9f4:	6906                	ld	s2,64(sp)
 9f6:	6125                	addi	sp,sp,96
 9f8:	8082                	ret

00000000000009fa <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 9fa:	715d                	addi	sp,sp,-80
 9fc:	ec06                	sd	ra,24(sp)
 9fe:	e822                	sd	s0,16(sp)
 a00:	1000                	addi	s0,sp,32
 a02:	e010                	sd	a2,0(s0)
 a04:	e414                	sd	a3,8(s0)
 a06:	e818                	sd	a4,16(s0)
 a08:	ec1c                	sd	a5,24(s0)
 a0a:	03043023          	sd	a6,32(s0)
 a0e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a12:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a16:	8622                	mv	a2,s0
 a18:	d3fff0ef          	jal	756 <vprintf>
}
 a1c:	60e2                	ld	ra,24(sp)
 a1e:	6442                	ld	s0,16(sp)
 a20:	6161                	addi	sp,sp,80
 a22:	8082                	ret

0000000000000a24 <printf>:

void
printf(const char *fmt, ...)
{
 a24:	711d                	addi	sp,sp,-96
 a26:	ec06                	sd	ra,24(sp)
 a28:	e822                	sd	s0,16(sp)
 a2a:	1000                	addi	s0,sp,32
 a2c:	e40c                	sd	a1,8(s0)
 a2e:	e810                	sd	a2,16(s0)
 a30:	ec14                	sd	a3,24(s0)
 a32:	f018                	sd	a4,32(s0)
 a34:	f41c                	sd	a5,40(s0)
 a36:	03043823          	sd	a6,48(s0)
 a3a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a3e:	00840613          	addi	a2,s0,8
 a42:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a46:	85aa                	mv	a1,a0
 a48:	4505                	li	a0,1
 a4a:	d0dff0ef          	jal	756 <vprintf>
}
 a4e:	60e2                	ld	ra,24(sp)
 a50:	6442                	ld	s0,16(sp)
 a52:	6125                	addi	sp,sp,96
 a54:	8082                	ret

0000000000000a56 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a56:	1141                	addi	sp,sp,-16
 a58:	e422                	sd	s0,8(sp)
 a5a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a5c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a60:	00000797          	auipc	a5,0x0
 a64:	5a07b783          	ld	a5,1440(a5) # 1000 <freep>
 a68:	a02d                	j	a92 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 a6a:	4618                	lw	a4,8(a2)
 a6c:	9f2d                	addw	a4,a4,a1
 a6e:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 a72:	6398                	ld	a4,0(a5)
 a74:	6310                	ld	a2,0(a4)
 a76:	a83d                	j	ab4 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 a78:	ff852703          	lw	a4,-8(a0)
 a7c:	9f31                	addw	a4,a4,a2
 a7e:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 a80:	ff053683          	ld	a3,-16(a0)
 a84:	a091                	j	ac8 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a86:	6398                	ld	a4,0(a5)
 a88:	00e7e463          	bltu	a5,a4,a90 <free+0x3a>
 a8c:	00e6ea63          	bltu	a3,a4,aa0 <free+0x4a>
{
 a90:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a92:	fed7fae3          	bgeu	a5,a3,a86 <free+0x30>
 a96:	6398                	ld	a4,0(a5)
 a98:	00e6e463          	bltu	a3,a4,aa0 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a9c:	fee7eae3          	bltu	a5,a4,a90 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 aa0:	ff852583          	lw	a1,-8(a0)
 aa4:	6390                	ld	a2,0(a5)
 aa6:	02059813          	slli	a6,a1,0x20
 aaa:	01c85713          	srli	a4,a6,0x1c
 aae:	9736                	add	a4,a4,a3
 ab0:	fae60de3          	beq	a2,a4,a6a <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 ab4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 ab8:	4790                	lw	a2,8(a5)
 aba:	02061593          	slli	a1,a2,0x20
 abe:	01c5d713          	srli	a4,a1,0x1c
 ac2:	973e                	add	a4,a4,a5
 ac4:	fae68ae3          	beq	a3,a4,a78 <free+0x22>
    p->s.ptr = bp->s.ptr;
 ac8:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 aca:	00000717          	auipc	a4,0x0
 ace:	52f73b23          	sd	a5,1334(a4) # 1000 <freep>
}
 ad2:	6422                	ld	s0,8(sp)
 ad4:	0141                	addi	sp,sp,16
 ad6:	8082                	ret

0000000000000ad8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 ad8:	7139                	addi	sp,sp,-64
 ada:	fc06                	sd	ra,56(sp)
 adc:	f822                	sd	s0,48(sp)
 ade:	f426                	sd	s1,40(sp)
 ae0:	ec4e                	sd	s3,24(sp)
 ae2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 ae4:	02051493          	slli	s1,a0,0x20
 ae8:	9081                	srli	s1,s1,0x20
 aea:	04bd                	addi	s1,s1,15
 aec:	8091                	srli	s1,s1,0x4
 aee:	0014899b          	addiw	s3,s1,1
 af2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 af4:	00000517          	auipc	a0,0x0
 af8:	50c53503          	ld	a0,1292(a0) # 1000 <freep>
 afc:	c915                	beqz	a0,b30 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 afe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b00:	4798                	lw	a4,8(a5)
 b02:	08977a63          	bgeu	a4,s1,b96 <malloc+0xbe>
 b06:	f04a                	sd	s2,32(sp)
 b08:	e852                	sd	s4,16(sp)
 b0a:	e456                	sd	s5,8(sp)
 b0c:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 b0e:	8a4e                	mv	s4,s3
 b10:	0009871b          	sext.w	a4,s3
 b14:	6685                	lui	a3,0x1
 b16:	00d77363          	bgeu	a4,a3,b1c <malloc+0x44>
 b1a:	6a05                	lui	s4,0x1
 b1c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b20:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b24:	00000917          	auipc	s2,0x0
 b28:	4dc90913          	addi	s2,s2,1244 # 1000 <freep>
  if(p == SBRK_ERROR)
 b2c:	5afd                	li	s5,-1
 b2e:	a081                	j	b6e <malloc+0x96>
 b30:	f04a                	sd	s2,32(sp)
 b32:	e852                	sd	s4,16(sp)
 b34:	e456                	sd	s5,8(sp)
 b36:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 b38:	00000797          	auipc	a5,0x0
 b3c:	4d878793          	addi	a5,a5,1240 # 1010 <base>
 b40:	00000717          	auipc	a4,0x0
 b44:	4cf73023          	sd	a5,1216(a4) # 1000 <freep>
 b48:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b4a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b4e:	b7c1                	j	b0e <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 b50:	6398                	ld	a4,0(a5)
 b52:	e118                	sd	a4,0(a0)
 b54:	a8a9                	j	bae <malloc+0xd6>
  hp->s.size = nu;
 b56:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 b5a:	0541                	addi	a0,a0,16
 b5c:	efbff0ef          	jal	a56 <free>
  return freep;
 b60:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 b64:	c12d                	beqz	a0,bc6 <malloc+0xee>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b66:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b68:	4798                	lw	a4,8(a5)
 b6a:	02977263          	bgeu	a4,s1,b8e <malloc+0xb6>
    if(p == freep)
 b6e:	00093703          	ld	a4,0(s2)
 b72:	853e                	mv	a0,a5
 b74:	fef719e3          	bne	a4,a5,b66 <malloc+0x8e>
  p = sbrk(nu * sizeof(Header));
 b78:	8552                	mv	a0,s4
 b7a:	a47ff0ef          	jal	5c0 <sbrk>
  if(p == SBRK_ERROR)
 b7e:	fd551ce3          	bne	a0,s5,b56 <malloc+0x7e>
        return 0;
 b82:	4501                	li	a0,0
 b84:	7902                	ld	s2,32(sp)
 b86:	6a42                	ld	s4,16(sp)
 b88:	6aa2                	ld	s5,8(sp)
 b8a:	6b02                	ld	s6,0(sp)
 b8c:	a03d                	j	bba <malloc+0xe2>
 b8e:	7902                	ld	s2,32(sp)
 b90:	6a42                	ld	s4,16(sp)
 b92:	6aa2                	ld	s5,8(sp)
 b94:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 b96:	fae48de3          	beq	s1,a4,b50 <malloc+0x78>
        p->s.size -= nunits;
 b9a:	4137073b          	subw	a4,a4,s3
 b9e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 ba0:	02071693          	slli	a3,a4,0x20
 ba4:	01c6d713          	srli	a4,a3,0x1c
 ba8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 baa:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 bae:	00000717          	auipc	a4,0x0
 bb2:	44a73923          	sd	a0,1106(a4) # 1000 <freep>
      return (void*)(p + 1);
 bb6:	01078513          	addi	a0,a5,16
  }
}
 bba:	70e2                	ld	ra,56(sp)
 bbc:	7442                	ld	s0,48(sp)
 bbe:	74a2                	ld	s1,40(sp)
 bc0:	69e2                	ld	s3,24(sp)
 bc2:	6121                	addi	sp,sp,64
 bc4:	8082                	ret
 bc6:	7902                	ld	s2,32(sp)
 bc8:	6a42                	ld	s4,16(sp)
 bca:	6aa2                	ld	s5,8(sp)
 bcc:	6b02                	ld	s6,0(sp)
 bce:	b7f5                	j	bba <malloc+0xe2>
