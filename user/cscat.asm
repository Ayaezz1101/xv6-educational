
user/_cscat:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(void){
   0:	9d010113          	addi	sp,sp,-1584
   4:	62113423          	sd	ra,1576(sp)
   8:	62813023          	sd	s0,1568(sp)
   c:	60913c23          	sd	s1,1560(sp)
  10:	61213823          	sd	s2,1552(sp)
  14:	61313423          	sd	s3,1544(sp)
  18:	61413023          	sd	s4,1536(sp)
  1c:	63010413          	addi	s0,sp,1584
  struct cs_event ev[32];
  while(1){
    int n = csread(ev, 32);
    for(int i=0;i<n;i++){
      if(ev[i].type != CS_RUN_START) continue;
  20:	4985                	li	s3,1
      printf("seq=%ld tick=%d cpu=%d pid=%d name=%s state=%d\n",
  22:	00001a17          	auipc	s4,0x1
  26:	8cea0a13          	addi	s4,s4,-1842 # 8f0 <malloc+0x100>
    int n = csread(ev, 32);
  2a:	02000593          	li	a1,32
  2e:	9d040513          	addi	a0,s0,-1584
  32:	37a000ef          	jal	3ac <csread>
    for(int i=0;i<n;i++){
  36:	fea05ae3          	blez	a0,2a <main+0x2a>
  3a:	9ec40493          	addi	s1,s0,-1556
  3e:	00151913          	slli	s2,a0,0x1
  42:	992a                	add	s2,s2,a0
  44:	0912                	slli	s2,s2,0x4
  46:	9926                	add	s2,s2,s1
      if(ev[i].type != CS_RUN_START) continue;
  48:	ff44a783          	lw	a5,-12(s1)
  4c:	01378763          	beq	a5,s3,5a <main+0x5a>
    for(int i=0;i<n;i++){
  50:	03048493          	addi	s1,s1,48
  54:	ff249ae3          	bne	s1,s2,48 <main+0x48>
  58:	bfc9                	j	2a <main+0x2a>
      printf("seq=%ld tick=%d cpu=%d pid=%d name=%s state=%d\n",
  5a:	ffc4a803          	lw	a6,-4(s1)
  5e:	87a6                	mv	a5,s1
  60:	ff84a703          	lw	a4,-8(s1)
  64:	ff04a683          	lw	a3,-16(s1)
  68:	fec4a603          	lw	a2,-20(s1)
  6c:	fe44b583          	ld	a1,-28(s1)
  70:	8552                	mv	a0,s4
  72:	6ca000ef          	jal	73c <printf>
  76:	bfe9                	j	50 <main+0x50>

0000000000000078 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
  78:	1141                	addi	sp,sp,-16
  7a:	e406                	sd	ra,8(sp)
  7c:	e022                	sd	s0,0(sp)
  7e:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
  80:	f81ff0ef          	jal	0 <main>
  exit(r);
  84:	288000ef          	jal	30c <exit>

0000000000000088 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  88:	1141                	addi	sp,sp,-16
  8a:	e422                	sd	s0,8(sp)
  8c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  8e:	87aa                	mv	a5,a0
  90:	0585                	addi	a1,a1,1
  92:	0785                	addi	a5,a5,1
  94:	fff5c703          	lbu	a4,-1(a1)
  98:	fee78fa3          	sb	a4,-1(a5)
  9c:	fb75                	bnez	a4,90 <strcpy+0x8>
    ;
  return os;
}
  9e:	6422                	ld	s0,8(sp)
  a0:	0141                	addi	sp,sp,16
  a2:	8082                	ret

00000000000000a4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  a4:	1141                	addi	sp,sp,-16
  a6:	e422                	sd	s0,8(sp)
  a8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  aa:	00054783          	lbu	a5,0(a0)
  ae:	cb91                	beqz	a5,c2 <strcmp+0x1e>
  b0:	0005c703          	lbu	a4,0(a1)
  b4:	00f71763          	bne	a4,a5,c2 <strcmp+0x1e>
    p++, q++;
  b8:	0505                	addi	a0,a0,1
  ba:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  bc:	00054783          	lbu	a5,0(a0)
  c0:	fbe5                	bnez	a5,b0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  c2:	0005c503          	lbu	a0,0(a1)
}
  c6:	40a7853b          	subw	a0,a5,a0
  ca:	6422                	ld	s0,8(sp)
  cc:	0141                	addi	sp,sp,16
  ce:	8082                	ret

00000000000000d0 <strlen>:

uint
strlen(const char *s)
{
  d0:	1141                	addi	sp,sp,-16
  d2:	e422                	sd	s0,8(sp)
  d4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  d6:	00054783          	lbu	a5,0(a0)
  da:	cf91                	beqz	a5,f6 <strlen+0x26>
  dc:	0505                	addi	a0,a0,1
  de:	87aa                	mv	a5,a0
  e0:	86be                	mv	a3,a5
  e2:	0785                	addi	a5,a5,1
  e4:	fff7c703          	lbu	a4,-1(a5)
  e8:	ff65                	bnez	a4,e0 <strlen+0x10>
  ea:	40a6853b          	subw	a0,a3,a0
  ee:	2505                	addiw	a0,a0,1
    ;
  return n;
}
  f0:	6422                	ld	s0,8(sp)
  f2:	0141                	addi	sp,sp,16
  f4:	8082                	ret
  for(n = 0; s[n]; n++)
  f6:	4501                	li	a0,0
  f8:	bfe5                	j	f0 <strlen+0x20>

00000000000000fa <memset>:

void*
memset(void *dst, int c, uint n)
{
  fa:	1141                	addi	sp,sp,-16
  fc:	e422                	sd	s0,8(sp)
  fe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 100:	ca19                	beqz	a2,116 <memset+0x1c>
 102:	87aa                	mv	a5,a0
 104:	1602                	slli	a2,a2,0x20
 106:	9201                	srli	a2,a2,0x20
 108:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 10c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 110:	0785                	addi	a5,a5,1
 112:	fee79de3          	bne	a5,a4,10c <memset+0x12>
  }
  return dst;
}
 116:	6422                	ld	s0,8(sp)
 118:	0141                	addi	sp,sp,16
 11a:	8082                	ret

000000000000011c <strchr>:

char*
strchr(const char *s, char c)
{
 11c:	1141                	addi	sp,sp,-16
 11e:	e422                	sd	s0,8(sp)
 120:	0800                	addi	s0,sp,16
  for(; *s; s++)
 122:	00054783          	lbu	a5,0(a0)
 126:	cb99                	beqz	a5,13c <strchr+0x20>
    if(*s == c)
 128:	00f58763          	beq	a1,a5,136 <strchr+0x1a>
  for(; *s; s++)
 12c:	0505                	addi	a0,a0,1
 12e:	00054783          	lbu	a5,0(a0)
 132:	fbfd                	bnez	a5,128 <strchr+0xc>
      return (char*)s;
  return 0;
 134:	4501                	li	a0,0
}
 136:	6422                	ld	s0,8(sp)
 138:	0141                	addi	sp,sp,16
 13a:	8082                	ret
  return 0;
 13c:	4501                	li	a0,0
 13e:	bfe5                	j	136 <strchr+0x1a>

0000000000000140 <gets>:

char*
gets(char *buf, int max)
{
 140:	711d                	addi	sp,sp,-96
 142:	ec86                	sd	ra,88(sp)
 144:	e8a2                	sd	s0,80(sp)
 146:	e4a6                	sd	s1,72(sp)
 148:	e0ca                	sd	s2,64(sp)
 14a:	fc4e                	sd	s3,56(sp)
 14c:	f852                	sd	s4,48(sp)
 14e:	f456                	sd	s5,40(sp)
 150:	f05a                	sd	s6,32(sp)
 152:	ec5e                	sd	s7,24(sp)
 154:	1080                	addi	s0,sp,96
 156:	8baa                	mv	s7,a0
 158:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 15a:	892a                	mv	s2,a0
 15c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 15e:	4aa9                	li	s5,10
 160:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 162:	89a6                	mv	s3,s1
 164:	2485                	addiw	s1,s1,1
 166:	0344d663          	bge	s1,s4,192 <gets+0x52>
    cc = read(0, &c, 1);
 16a:	4605                	li	a2,1
 16c:	faf40593          	addi	a1,s0,-81
 170:	4501                	li	a0,0
 172:	1b2000ef          	jal	324 <read>
    if(cc < 1)
 176:	00a05e63          	blez	a0,192 <gets+0x52>
    buf[i++] = c;
 17a:	faf44783          	lbu	a5,-81(s0)
 17e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 182:	01578763          	beq	a5,s5,190 <gets+0x50>
 186:	0905                	addi	s2,s2,1
 188:	fd679de3          	bne	a5,s6,162 <gets+0x22>
    buf[i++] = c;
 18c:	89a6                	mv	s3,s1
 18e:	a011                	j	192 <gets+0x52>
 190:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 192:	99de                	add	s3,s3,s7
 194:	00098023          	sb	zero,0(s3)
  return buf;
}
 198:	855e                	mv	a0,s7
 19a:	60e6                	ld	ra,88(sp)
 19c:	6446                	ld	s0,80(sp)
 19e:	64a6                	ld	s1,72(sp)
 1a0:	6906                	ld	s2,64(sp)
 1a2:	79e2                	ld	s3,56(sp)
 1a4:	7a42                	ld	s4,48(sp)
 1a6:	7aa2                	ld	s5,40(sp)
 1a8:	7b02                	ld	s6,32(sp)
 1aa:	6be2                	ld	s7,24(sp)
 1ac:	6125                	addi	sp,sp,96
 1ae:	8082                	ret

00000000000001b0 <stat>:

int
stat(const char *n, struct stat *st)
{
 1b0:	1101                	addi	sp,sp,-32
 1b2:	ec06                	sd	ra,24(sp)
 1b4:	e822                	sd	s0,16(sp)
 1b6:	e04a                	sd	s2,0(sp)
 1b8:	1000                	addi	s0,sp,32
 1ba:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1bc:	4581                	li	a1,0
 1be:	18e000ef          	jal	34c <open>
  if(fd < 0)
 1c2:	02054263          	bltz	a0,1e6 <stat+0x36>
 1c6:	e426                	sd	s1,8(sp)
 1c8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ca:	85ca                	mv	a1,s2
 1cc:	198000ef          	jal	364 <fstat>
 1d0:	892a                	mv	s2,a0
  close(fd);
 1d2:	8526                	mv	a0,s1
 1d4:	160000ef          	jal	334 <close>
  return r;
 1d8:	64a2                	ld	s1,8(sp)
}
 1da:	854a                	mv	a0,s2
 1dc:	60e2                	ld	ra,24(sp)
 1de:	6442                	ld	s0,16(sp)
 1e0:	6902                	ld	s2,0(sp)
 1e2:	6105                	addi	sp,sp,32
 1e4:	8082                	ret
    return -1;
 1e6:	597d                	li	s2,-1
 1e8:	bfcd                	j	1da <stat+0x2a>

00000000000001ea <atoi>:

int
atoi(const char *s)
{
 1ea:	1141                	addi	sp,sp,-16
 1ec:	e422                	sd	s0,8(sp)
 1ee:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f0:	00054683          	lbu	a3,0(a0)
 1f4:	fd06879b          	addiw	a5,a3,-48
 1f8:	0ff7f793          	zext.b	a5,a5
 1fc:	4625                	li	a2,9
 1fe:	02f66863          	bltu	a2,a5,22e <atoi+0x44>
 202:	872a                	mv	a4,a0
  n = 0;
 204:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 206:	0705                	addi	a4,a4,1
 208:	0025179b          	slliw	a5,a0,0x2
 20c:	9fa9                	addw	a5,a5,a0
 20e:	0017979b          	slliw	a5,a5,0x1
 212:	9fb5                	addw	a5,a5,a3
 214:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 218:	00074683          	lbu	a3,0(a4)
 21c:	fd06879b          	addiw	a5,a3,-48
 220:	0ff7f793          	zext.b	a5,a5
 224:	fef671e3          	bgeu	a2,a5,206 <atoi+0x1c>
  return n;
}
 228:	6422                	ld	s0,8(sp)
 22a:	0141                	addi	sp,sp,16
 22c:	8082                	ret
  n = 0;
 22e:	4501                	li	a0,0
 230:	bfe5                	j	228 <atoi+0x3e>

0000000000000232 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 232:	1141                	addi	sp,sp,-16
 234:	e422                	sd	s0,8(sp)
 236:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 238:	02b57463          	bgeu	a0,a1,260 <memmove+0x2e>
    while(n-- > 0)
 23c:	00c05f63          	blez	a2,25a <memmove+0x28>
 240:	1602                	slli	a2,a2,0x20
 242:	9201                	srli	a2,a2,0x20
 244:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 248:	872a                	mv	a4,a0
      *dst++ = *src++;
 24a:	0585                	addi	a1,a1,1
 24c:	0705                	addi	a4,a4,1
 24e:	fff5c683          	lbu	a3,-1(a1)
 252:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 256:	fef71ae3          	bne	a4,a5,24a <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 25a:	6422                	ld	s0,8(sp)
 25c:	0141                	addi	sp,sp,16
 25e:	8082                	ret
    dst += n;
 260:	00c50733          	add	a4,a0,a2
    src += n;
 264:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 266:	fec05ae3          	blez	a2,25a <memmove+0x28>
 26a:	fff6079b          	addiw	a5,a2,-1
 26e:	1782                	slli	a5,a5,0x20
 270:	9381                	srli	a5,a5,0x20
 272:	fff7c793          	not	a5,a5
 276:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 278:	15fd                	addi	a1,a1,-1
 27a:	177d                	addi	a4,a4,-1
 27c:	0005c683          	lbu	a3,0(a1)
 280:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 284:	fee79ae3          	bne	a5,a4,278 <memmove+0x46>
 288:	bfc9                	j	25a <memmove+0x28>

000000000000028a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 28a:	1141                	addi	sp,sp,-16
 28c:	e422                	sd	s0,8(sp)
 28e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 290:	ca05                	beqz	a2,2c0 <memcmp+0x36>
 292:	fff6069b          	addiw	a3,a2,-1
 296:	1682                	slli	a3,a3,0x20
 298:	9281                	srli	a3,a3,0x20
 29a:	0685                	addi	a3,a3,1
 29c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 29e:	00054783          	lbu	a5,0(a0)
 2a2:	0005c703          	lbu	a4,0(a1)
 2a6:	00e79863          	bne	a5,a4,2b6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2aa:	0505                	addi	a0,a0,1
    p2++;
 2ac:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2ae:	fed518e3          	bne	a0,a3,29e <memcmp+0x14>
  }
  return 0;
 2b2:	4501                	li	a0,0
 2b4:	a019                	j	2ba <memcmp+0x30>
      return *p1 - *p2;
 2b6:	40e7853b          	subw	a0,a5,a4
}
 2ba:	6422                	ld	s0,8(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret
  return 0;
 2c0:	4501                	li	a0,0
 2c2:	bfe5                	j	2ba <memcmp+0x30>

00000000000002c4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2c4:	1141                	addi	sp,sp,-16
 2c6:	e406                	sd	ra,8(sp)
 2c8:	e022                	sd	s0,0(sp)
 2ca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2cc:	f67ff0ef          	jal	232 <memmove>
}
 2d0:	60a2                	ld	ra,8(sp)
 2d2:	6402                	ld	s0,0(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret

00000000000002d8 <sbrk>:

char *
sbrk(int n) {
 2d8:	1141                	addi	sp,sp,-16
 2da:	e406                	sd	ra,8(sp)
 2dc:	e022                	sd	s0,0(sp)
 2de:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 2e0:	4585                	li	a1,1
 2e2:	0b2000ef          	jal	394 <sys_sbrk>
}
 2e6:	60a2                	ld	ra,8(sp)
 2e8:	6402                	ld	s0,0(sp)
 2ea:	0141                	addi	sp,sp,16
 2ec:	8082                	ret

00000000000002ee <sbrklazy>:

char *
sbrklazy(int n) {
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e406                	sd	ra,8(sp)
 2f2:	e022                	sd	s0,0(sp)
 2f4:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 2f6:	4589                	li	a1,2
 2f8:	09c000ef          	jal	394 <sys_sbrk>
}
 2fc:	60a2                	ld	ra,8(sp)
 2fe:	6402                	ld	s0,0(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret

0000000000000304 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 304:	4885                	li	a7,1
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <exit>:
.global exit
exit:
 li a7, SYS_exit
 30c:	4889                	li	a7,2
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <wait>:
.global wait
wait:
 li a7, SYS_wait
 314:	488d                	li	a7,3
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 31c:	4891                	li	a7,4
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <read>:
.global read
read:
 li a7, SYS_read
 324:	4895                	li	a7,5
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <write>:
.global write
write:
 li a7, SYS_write
 32c:	48c1                	li	a7,16
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <close>:
.global close
close:
 li a7, SYS_close
 334:	48d5                	li	a7,21
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <kill>:
.global kill
kill:
 li a7, SYS_kill
 33c:	4899                	li	a7,6
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <exec>:
.global exec
exec:
 li a7, SYS_exec
 344:	489d                	li	a7,7
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <open>:
.global open
open:
 li a7, SYS_open
 34c:	48bd                	li	a7,15
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 354:	48c5                	li	a7,17
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 35c:	48c9                	li	a7,18
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 364:	48a1                	li	a7,8
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <link>:
.global link
link:
 li a7, SYS_link
 36c:	48cd                	li	a7,19
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 374:	48d1                	li	a7,20
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 37c:	48a5                	li	a7,9
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <dup>:
.global dup
dup:
 li a7, SYS_dup
 384:	48a9                	li	a7,10
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 38c:	48ad                	li	a7,11
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 394:	48b1                	li	a7,12
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <pause>:
.global pause
pause:
 li a7, SYS_pause
 39c:	48b5                	li	a7,13
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a4:	48b9                	li	a7,14
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <csread>:
.global csread
csread:
 li a7, SYS_csread
 3ac:	48d9                	li	a7,22
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3b4:	1101                	addi	sp,sp,-32
 3b6:	ec06                	sd	ra,24(sp)
 3b8:	e822                	sd	s0,16(sp)
 3ba:	1000                	addi	s0,sp,32
 3bc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3c0:	4605                	li	a2,1
 3c2:	fef40593          	addi	a1,s0,-17
 3c6:	f67ff0ef          	jal	32c <write>
}
 3ca:	60e2                	ld	ra,24(sp)
 3cc:	6442                	ld	s0,16(sp)
 3ce:	6105                	addi	sp,sp,32
 3d0:	8082                	ret

00000000000003d2 <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 3d2:	715d                	addi	sp,sp,-80
 3d4:	e486                	sd	ra,72(sp)
 3d6:	e0a2                	sd	s0,64(sp)
 3d8:	f84a                	sd	s2,48(sp)
 3da:	0880                	addi	s0,sp,80
 3dc:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 3de:	c299                	beqz	a3,3e4 <printint+0x12>
 3e0:	0805c363          	bltz	a1,466 <printint+0x94>
  neg = 0;
 3e4:	4881                	li	a7,0
 3e6:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 3ea:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 3ec:	00000517          	auipc	a0,0x0
 3f0:	53c50513          	addi	a0,a0,1340 # 928 <digits>
 3f4:	883e                	mv	a6,a5
 3f6:	2785                	addiw	a5,a5,1
 3f8:	02c5f733          	remu	a4,a1,a2
 3fc:	972a                	add	a4,a4,a0
 3fe:	00074703          	lbu	a4,0(a4)
 402:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 406:	872e                	mv	a4,a1
 408:	02c5d5b3          	divu	a1,a1,a2
 40c:	0685                	addi	a3,a3,1
 40e:	fec773e3          	bgeu	a4,a2,3f4 <printint+0x22>
  if(neg)
 412:	00088b63          	beqz	a7,428 <printint+0x56>
    buf[i++] = '-';
 416:	fd078793          	addi	a5,a5,-48
 41a:	97a2                	add	a5,a5,s0
 41c:	02d00713          	li	a4,45
 420:	fee78423          	sb	a4,-24(a5)
 424:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 428:	02f05a63          	blez	a5,45c <printint+0x8a>
 42c:	fc26                	sd	s1,56(sp)
 42e:	f44e                	sd	s3,40(sp)
 430:	fb840713          	addi	a4,s0,-72
 434:	00f704b3          	add	s1,a4,a5
 438:	fff70993          	addi	s3,a4,-1
 43c:	99be                	add	s3,s3,a5
 43e:	37fd                	addiw	a5,a5,-1
 440:	1782                	slli	a5,a5,0x20
 442:	9381                	srli	a5,a5,0x20
 444:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 448:	fff4c583          	lbu	a1,-1(s1)
 44c:	854a                	mv	a0,s2
 44e:	f67ff0ef          	jal	3b4 <putc>
  while(--i >= 0)
 452:	14fd                	addi	s1,s1,-1
 454:	ff349ae3          	bne	s1,s3,448 <printint+0x76>
 458:	74e2                	ld	s1,56(sp)
 45a:	79a2                	ld	s3,40(sp)
}
 45c:	60a6                	ld	ra,72(sp)
 45e:	6406                	ld	s0,64(sp)
 460:	7942                	ld	s2,48(sp)
 462:	6161                	addi	sp,sp,80
 464:	8082                	ret
    x = -xx;
 466:	40b005b3          	neg	a1,a1
    neg = 1;
 46a:	4885                	li	a7,1
    x = -xx;
 46c:	bfad                	j	3e6 <printint+0x14>

000000000000046e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 46e:	711d                	addi	sp,sp,-96
 470:	ec86                	sd	ra,88(sp)
 472:	e8a2                	sd	s0,80(sp)
 474:	e0ca                	sd	s2,64(sp)
 476:	1080                	addi	s0,sp,96
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 478:	0005c903          	lbu	s2,0(a1)
 47c:	28090663          	beqz	s2,708 <vprintf+0x29a>
 480:	e4a6                	sd	s1,72(sp)
 482:	fc4e                	sd	s3,56(sp)
 484:	f852                	sd	s4,48(sp)
 486:	f456                	sd	s5,40(sp)
 488:	f05a                	sd	s6,32(sp)
 48a:	ec5e                	sd	s7,24(sp)
 48c:	e862                	sd	s8,16(sp)
 48e:	e466                	sd	s9,8(sp)
 490:	8b2a                	mv	s6,a0
 492:	8a2e                	mv	s4,a1
 494:	8bb2                	mv	s7,a2
  state = 0;
 496:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 498:	4481                	li	s1,0
 49a:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 49c:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 4a0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 4a4:	06c00c93          	li	s9,108
 4a8:	a005                	j	4c8 <vprintf+0x5a>
        putc(fd, c0);
 4aa:	85ca                	mv	a1,s2
 4ac:	855a                	mv	a0,s6
 4ae:	f07ff0ef          	jal	3b4 <putc>
 4b2:	a019                	j	4b8 <vprintf+0x4a>
    } else if(state == '%'){
 4b4:	03598263          	beq	s3,s5,4d8 <vprintf+0x6a>
  for(i = 0; fmt[i]; i++){
 4b8:	2485                	addiw	s1,s1,1
 4ba:	8726                	mv	a4,s1
 4bc:	009a07b3          	add	a5,s4,s1
 4c0:	0007c903          	lbu	s2,0(a5)
 4c4:	22090a63          	beqz	s2,6f8 <vprintf+0x28a>
    c0 = fmt[i] & 0xff;
 4c8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4cc:	fe0994e3          	bnez	s3,4b4 <vprintf+0x46>
      if(c0 == '%'){
 4d0:	fd579de3          	bne	a5,s5,4aa <vprintf+0x3c>
        state = '%';
 4d4:	89be                	mv	s3,a5
 4d6:	b7cd                	j	4b8 <vprintf+0x4a>
      if(c0) c1 = fmt[i+1] & 0xff;
 4d8:	00ea06b3          	add	a3,s4,a4
 4dc:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 4e0:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 4e2:	c681                	beqz	a3,4ea <vprintf+0x7c>
 4e4:	9752                	add	a4,a4,s4
 4e6:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 4ea:	05878363          	beq	a5,s8,530 <vprintf+0xc2>
      } else if(c0 == 'l' && c1 == 'd'){
 4ee:	05978d63          	beq	a5,s9,548 <vprintf+0xda>
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 4f2:	07500713          	li	a4,117
 4f6:	0ee78763          	beq	a5,a4,5e4 <vprintf+0x176>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 4fa:	07800713          	li	a4,120
 4fe:	12e78963          	beq	a5,a4,630 <vprintf+0x1c2>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 502:	07000713          	li	a4,112
 506:	14e78e63          	beq	a5,a4,662 <vprintf+0x1f4>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 50a:	06300713          	li	a4,99
 50e:	18e78e63          	beq	a5,a4,6aa <vprintf+0x23c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 512:	07300713          	li	a4,115
 516:	1ae78463          	beq	a5,a4,6be <vprintf+0x250>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 51a:	02500713          	li	a4,37
 51e:	04e79563          	bne	a5,a4,568 <vprintf+0xfa>
        putc(fd, '%');
 522:	02500593          	li	a1,37
 526:	855a                	mv	a0,s6
 528:	e8dff0ef          	jal	3b4 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 52c:	4981                	li	s3,0
 52e:	b769                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, int), 10, 1);
 530:	008b8913          	addi	s2,s7,8
 534:	4685                	li	a3,1
 536:	4629                	li	a2,10
 538:	000ba583          	lw	a1,0(s7)
 53c:	855a                	mv	a0,s6
 53e:	e95ff0ef          	jal	3d2 <printint>
 542:	8bca                	mv	s7,s2
      state = 0;
 544:	4981                	li	s3,0
 546:	bf8d                	j	4b8 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'd'){
 548:	06400793          	li	a5,100
 54c:	02f68963          	beq	a3,a5,57e <vprintf+0x110>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 550:	06c00793          	li	a5,108
 554:	04f68263          	beq	a3,a5,598 <vprintf+0x12a>
      } else if(c0 == 'l' && c1 == 'u'){
 558:	07500793          	li	a5,117
 55c:	0af68063          	beq	a3,a5,5fc <vprintf+0x18e>
      } else if(c0 == 'l' && c1 == 'x'){
 560:	07800793          	li	a5,120
 564:	0ef68263          	beq	a3,a5,648 <vprintf+0x1da>
        putc(fd, '%');
 568:	02500593          	li	a1,37
 56c:	855a                	mv	a0,s6
 56e:	e47ff0ef          	jal	3b4 <putc>
        putc(fd, c0);
 572:	85ca                	mv	a1,s2
 574:	855a                	mv	a0,s6
 576:	e3fff0ef          	jal	3b4 <putc>
      state = 0;
 57a:	4981                	li	s3,0
 57c:	bf35                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 57e:	008b8913          	addi	s2,s7,8
 582:	4685                	li	a3,1
 584:	4629                	li	a2,10
 586:	000bb583          	ld	a1,0(s7)
 58a:	855a                	mv	a0,s6
 58c:	e47ff0ef          	jal	3d2 <printint>
        i += 1;
 590:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 592:	8bca                	mv	s7,s2
      state = 0;
 594:	4981                	li	s3,0
        i += 1;
 596:	b70d                	j	4b8 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 598:	06400793          	li	a5,100
 59c:	02f60763          	beq	a2,a5,5ca <vprintf+0x15c>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 5a0:	07500793          	li	a5,117
 5a4:	06f60963          	beq	a2,a5,616 <vprintf+0x1a8>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 5a8:	07800793          	li	a5,120
 5ac:	faf61ee3          	bne	a2,a5,568 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 5b0:	008b8913          	addi	s2,s7,8
 5b4:	4681                	li	a3,0
 5b6:	4641                	li	a2,16
 5b8:	000bb583          	ld	a1,0(s7)
 5bc:	855a                	mv	a0,s6
 5be:	e15ff0ef          	jal	3d2 <printint>
        i += 2;
 5c2:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 5c4:	8bca                	mv	s7,s2
      state = 0;
 5c6:	4981                	li	s3,0
        i += 2;
 5c8:	bdc5                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 5ca:	008b8913          	addi	s2,s7,8
 5ce:	4685                	li	a3,1
 5d0:	4629                	li	a2,10
 5d2:	000bb583          	ld	a1,0(s7)
 5d6:	855a                	mv	a0,s6
 5d8:	dfbff0ef          	jal	3d2 <printint>
        i += 2;
 5dc:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 5de:	8bca                	mv	s7,s2
      state = 0;
 5e0:	4981                	li	s3,0
        i += 2;
 5e2:	bdd9                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 5e4:	008b8913          	addi	s2,s7,8
 5e8:	4681                	li	a3,0
 5ea:	4629                	li	a2,10
 5ec:	000be583          	lwu	a1,0(s7)
 5f0:	855a                	mv	a0,s6
 5f2:	de1ff0ef          	jal	3d2 <printint>
 5f6:	8bca                	mv	s7,s2
      state = 0;
 5f8:	4981                	li	s3,0
 5fa:	bd7d                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5fc:	008b8913          	addi	s2,s7,8
 600:	4681                	li	a3,0
 602:	4629                	li	a2,10
 604:	000bb583          	ld	a1,0(s7)
 608:	855a                	mv	a0,s6
 60a:	dc9ff0ef          	jal	3d2 <printint>
        i += 1;
 60e:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 610:	8bca                	mv	s7,s2
      state = 0;
 612:	4981                	li	s3,0
        i += 1;
 614:	b555                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 616:	008b8913          	addi	s2,s7,8
 61a:	4681                	li	a3,0
 61c:	4629                	li	a2,10
 61e:	000bb583          	ld	a1,0(s7)
 622:	855a                	mv	a0,s6
 624:	dafff0ef          	jal	3d2 <printint>
        i += 2;
 628:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 62a:	8bca                	mv	s7,s2
      state = 0;
 62c:	4981                	li	s3,0
        i += 2;
 62e:	b569                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 630:	008b8913          	addi	s2,s7,8
 634:	4681                	li	a3,0
 636:	4641                	li	a2,16
 638:	000be583          	lwu	a1,0(s7)
 63c:	855a                	mv	a0,s6
 63e:	d95ff0ef          	jal	3d2 <printint>
 642:	8bca                	mv	s7,s2
      state = 0;
 644:	4981                	li	s3,0
 646:	bd8d                	j	4b8 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 648:	008b8913          	addi	s2,s7,8
 64c:	4681                	li	a3,0
 64e:	4641                	li	a2,16
 650:	000bb583          	ld	a1,0(s7)
 654:	855a                	mv	a0,s6
 656:	d7dff0ef          	jal	3d2 <printint>
        i += 1;
 65a:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 65c:	8bca                	mv	s7,s2
      state = 0;
 65e:	4981                	li	s3,0
        i += 1;
 660:	bda1                	j	4b8 <vprintf+0x4a>
 662:	e06a                	sd	s10,0(sp)
        printptr(fd, va_arg(ap, uint64));
 664:	008b8d13          	addi	s10,s7,8
 668:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 66c:	03000593          	li	a1,48
 670:	855a                	mv	a0,s6
 672:	d43ff0ef          	jal	3b4 <putc>
  putc(fd, 'x');
 676:	07800593          	li	a1,120
 67a:	855a                	mv	a0,s6
 67c:	d39ff0ef          	jal	3b4 <putc>
 680:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 682:	00000b97          	auipc	s7,0x0
 686:	2a6b8b93          	addi	s7,s7,678 # 928 <digits>
 68a:	03c9d793          	srli	a5,s3,0x3c
 68e:	97de                	add	a5,a5,s7
 690:	0007c583          	lbu	a1,0(a5)
 694:	855a                	mv	a0,s6
 696:	d1fff0ef          	jal	3b4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 69a:	0992                	slli	s3,s3,0x4
 69c:	397d                	addiw	s2,s2,-1
 69e:	fe0916e3          	bnez	s2,68a <vprintf+0x21c>
        printptr(fd, va_arg(ap, uint64));
 6a2:	8bea                	mv	s7,s10
      state = 0;
 6a4:	4981                	li	s3,0
 6a6:	6d02                	ld	s10,0(sp)
 6a8:	bd01                	j	4b8 <vprintf+0x4a>
        putc(fd, va_arg(ap, uint32));
 6aa:	008b8913          	addi	s2,s7,8
 6ae:	000bc583          	lbu	a1,0(s7)
 6b2:	855a                	mv	a0,s6
 6b4:	d01ff0ef          	jal	3b4 <putc>
 6b8:	8bca                	mv	s7,s2
      state = 0;
 6ba:	4981                	li	s3,0
 6bc:	bbf5                	j	4b8 <vprintf+0x4a>
        if((s = va_arg(ap, char*)) == 0)
 6be:	008b8993          	addi	s3,s7,8
 6c2:	000bb903          	ld	s2,0(s7)
 6c6:	00090f63          	beqz	s2,6e4 <vprintf+0x276>
        for(; *s; s++)
 6ca:	00094583          	lbu	a1,0(s2)
 6ce:	c195                	beqz	a1,6f2 <vprintf+0x284>
          putc(fd, *s);
 6d0:	855a                	mv	a0,s6
 6d2:	ce3ff0ef          	jal	3b4 <putc>
        for(; *s; s++)
 6d6:	0905                	addi	s2,s2,1
 6d8:	00094583          	lbu	a1,0(s2)
 6dc:	f9f5                	bnez	a1,6d0 <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 6de:	8bce                	mv	s7,s3
      state = 0;
 6e0:	4981                	li	s3,0
 6e2:	bbd9                	j	4b8 <vprintf+0x4a>
          s = "(null)";
 6e4:	00000917          	auipc	s2,0x0
 6e8:	23c90913          	addi	s2,s2,572 # 920 <malloc+0x130>
        for(; *s; s++)
 6ec:	02800593          	li	a1,40
 6f0:	b7c5                	j	6d0 <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 6f2:	8bce                	mv	s7,s3
      state = 0;
 6f4:	4981                	li	s3,0
 6f6:	b3c9                	j	4b8 <vprintf+0x4a>
 6f8:	64a6                	ld	s1,72(sp)
 6fa:	79e2                	ld	s3,56(sp)
 6fc:	7a42                	ld	s4,48(sp)
 6fe:	7aa2                	ld	s5,40(sp)
 700:	7b02                	ld	s6,32(sp)
 702:	6be2                	ld	s7,24(sp)
 704:	6c42                	ld	s8,16(sp)
 706:	6ca2                	ld	s9,8(sp)
    }
  }
}
 708:	60e6                	ld	ra,88(sp)
 70a:	6446                	ld	s0,80(sp)
 70c:	6906                	ld	s2,64(sp)
 70e:	6125                	addi	sp,sp,96
 710:	8082                	ret

0000000000000712 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 712:	715d                	addi	sp,sp,-80
 714:	ec06                	sd	ra,24(sp)
 716:	e822                	sd	s0,16(sp)
 718:	1000                	addi	s0,sp,32
 71a:	e010                	sd	a2,0(s0)
 71c:	e414                	sd	a3,8(s0)
 71e:	e818                	sd	a4,16(s0)
 720:	ec1c                	sd	a5,24(s0)
 722:	03043023          	sd	a6,32(s0)
 726:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 72a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 72e:	8622                	mv	a2,s0
 730:	d3fff0ef          	jal	46e <vprintf>
}
 734:	60e2                	ld	ra,24(sp)
 736:	6442                	ld	s0,16(sp)
 738:	6161                	addi	sp,sp,80
 73a:	8082                	ret

000000000000073c <printf>:

void
printf(const char *fmt, ...)
{
 73c:	711d                	addi	sp,sp,-96
 73e:	ec06                	sd	ra,24(sp)
 740:	e822                	sd	s0,16(sp)
 742:	1000                	addi	s0,sp,32
 744:	e40c                	sd	a1,8(s0)
 746:	e810                	sd	a2,16(s0)
 748:	ec14                	sd	a3,24(s0)
 74a:	f018                	sd	a4,32(s0)
 74c:	f41c                	sd	a5,40(s0)
 74e:	03043823          	sd	a6,48(s0)
 752:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 756:	00840613          	addi	a2,s0,8
 75a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 75e:	85aa                	mv	a1,a0
 760:	4505                	li	a0,1
 762:	d0dff0ef          	jal	46e <vprintf>
}
 766:	60e2                	ld	ra,24(sp)
 768:	6442                	ld	s0,16(sp)
 76a:	6125                	addi	sp,sp,96
 76c:	8082                	ret

000000000000076e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 76e:	1141                	addi	sp,sp,-16
 770:	e422                	sd	s0,8(sp)
 772:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 774:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 778:	00001797          	auipc	a5,0x1
 77c:	8887b783          	ld	a5,-1912(a5) # 1000 <freep>
 780:	a02d                	j	7aa <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 782:	4618                	lw	a4,8(a2)
 784:	9f2d                	addw	a4,a4,a1
 786:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 78a:	6398                	ld	a4,0(a5)
 78c:	6310                	ld	a2,0(a4)
 78e:	a83d                	j	7cc <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 790:	ff852703          	lw	a4,-8(a0)
 794:	9f31                	addw	a4,a4,a2
 796:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 798:	ff053683          	ld	a3,-16(a0)
 79c:	a091                	j	7e0 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 79e:	6398                	ld	a4,0(a5)
 7a0:	00e7e463          	bltu	a5,a4,7a8 <free+0x3a>
 7a4:	00e6ea63          	bltu	a3,a4,7b8 <free+0x4a>
{
 7a8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7aa:	fed7fae3          	bgeu	a5,a3,79e <free+0x30>
 7ae:	6398                	ld	a4,0(a5)
 7b0:	00e6e463          	bltu	a3,a4,7b8 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7b4:	fee7eae3          	bltu	a5,a4,7a8 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 7b8:	ff852583          	lw	a1,-8(a0)
 7bc:	6390                	ld	a2,0(a5)
 7be:	02059813          	slli	a6,a1,0x20
 7c2:	01c85713          	srli	a4,a6,0x1c
 7c6:	9736                	add	a4,a4,a3
 7c8:	fae60de3          	beq	a2,a4,782 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 7cc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7d0:	4790                	lw	a2,8(a5)
 7d2:	02061593          	slli	a1,a2,0x20
 7d6:	01c5d713          	srli	a4,a1,0x1c
 7da:	973e                	add	a4,a4,a5
 7dc:	fae68ae3          	beq	a3,a4,790 <free+0x22>
    p->s.ptr = bp->s.ptr;
 7e0:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7e2:	00001717          	auipc	a4,0x1
 7e6:	80f73f23          	sd	a5,-2018(a4) # 1000 <freep>
}
 7ea:	6422                	ld	s0,8(sp)
 7ec:	0141                	addi	sp,sp,16
 7ee:	8082                	ret

00000000000007f0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7f0:	7139                	addi	sp,sp,-64
 7f2:	fc06                	sd	ra,56(sp)
 7f4:	f822                	sd	s0,48(sp)
 7f6:	f426                	sd	s1,40(sp)
 7f8:	ec4e                	sd	s3,24(sp)
 7fa:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7fc:	02051493          	slli	s1,a0,0x20
 800:	9081                	srli	s1,s1,0x20
 802:	04bd                	addi	s1,s1,15
 804:	8091                	srli	s1,s1,0x4
 806:	0014899b          	addiw	s3,s1,1
 80a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 80c:	00000517          	auipc	a0,0x0
 810:	7f453503          	ld	a0,2036(a0) # 1000 <freep>
 814:	c915                	beqz	a0,848 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 816:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 818:	4798                	lw	a4,8(a5)
 81a:	08977a63          	bgeu	a4,s1,8ae <malloc+0xbe>
 81e:	f04a                	sd	s2,32(sp)
 820:	e852                	sd	s4,16(sp)
 822:	e456                	sd	s5,8(sp)
 824:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 826:	8a4e                	mv	s4,s3
 828:	0009871b          	sext.w	a4,s3
 82c:	6685                	lui	a3,0x1
 82e:	00d77363          	bgeu	a4,a3,834 <malloc+0x44>
 832:	6a05                	lui	s4,0x1
 834:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 838:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 83c:	00000917          	auipc	s2,0x0
 840:	7c490913          	addi	s2,s2,1988 # 1000 <freep>
  if(p == SBRK_ERROR)
 844:	5afd                	li	s5,-1
 846:	a081                	j	886 <malloc+0x96>
 848:	f04a                	sd	s2,32(sp)
 84a:	e852                	sd	s4,16(sp)
 84c:	e456                	sd	s5,8(sp)
 84e:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 850:	00000797          	auipc	a5,0x0
 854:	7c078793          	addi	a5,a5,1984 # 1010 <base>
 858:	00000717          	auipc	a4,0x0
 85c:	7af73423          	sd	a5,1960(a4) # 1000 <freep>
 860:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 862:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 866:	b7c1                	j	826 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 868:	6398                	ld	a4,0(a5)
 86a:	e118                	sd	a4,0(a0)
 86c:	a8a9                	j	8c6 <malloc+0xd6>
  hp->s.size = nu;
 86e:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 872:	0541                	addi	a0,a0,16
 874:	efbff0ef          	jal	76e <free>
  return freep;
 878:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 87c:	c12d                	beqz	a0,8de <malloc+0xee>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 87e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 880:	4798                	lw	a4,8(a5)
 882:	02977263          	bgeu	a4,s1,8a6 <malloc+0xb6>
    if(p == freep)
 886:	00093703          	ld	a4,0(s2)
 88a:	853e                	mv	a0,a5
 88c:	fef719e3          	bne	a4,a5,87e <malloc+0x8e>
  p = sbrk(nu * sizeof(Header));
 890:	8552                	mv	a0,s4
 892:	a47ff0ef          	jal	2d8 <sbrk>
  if(p == SBRK_ERROR)
 896:	fd551ce3          	bne	a0,s5,86e <malloc+0x7e>
        return 0;
 89a:	4501                	li	a0,0
 89c:	7902                	ld	s2,32(sp)
 89e:	6a42                	ld	s4,16(sp)
 8a0:	6aa2                	ld	s5,8(sp)
 8a2:	6b02                	ld	s6,0(sp)
 8a4:	a03d                	j	8d2 <malloc+0xe2>
 8a6:	7902                	ld	s2,32(sp)
 8a8:	6a42                	ld	s4,16(sp)
 8aa:	6aa2                	ld	s5,8(sp)
 8ac:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 8ae:	fae48de3          	beq	s1,a4,868 <malloc+0x78>
        p->s.size -= nunits;
 8b2:	4137073b          	subw	a4,a4,s3
 8b6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8b8:	02071693          	slli	a3,a4,0x20
 8bc:	01c6d713          	srli	a4,a3,0x1c
 8c0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8c2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8c6:	00000717          	auipc	a4,0x0
 8ca:	72a73d23          	sd	a0,1850(a4) # 1000 <freep>
      return (void*)(p + 1);
 8ce:	01078513          	addi	a0,a5,16
  }
}
 8d2:	70e2                	ld	ra,56(sp)
 8d4:	7442                	ld	s0,48(sp)
 8d6:	74a2                	ld	s1,40(sp)
 8d8:	69e2                	ld	s3,24(sp)
 8da:	6121                	addi	sp,sp,64
 8dc:	8082                	ret
 8de:	7902                	ld	s2,32(sp)
 8e0:	6a42                	ld	s4,16(sp)
 8e2:	6aa2                	ld	s5,8(sp)
 8e4:	6b02                	ld	s6,0(sp)
 8e6:	b7f5                	j	8d2 <malloc+0xe2>
