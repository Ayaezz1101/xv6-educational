<<<<<<<<< LOCAL VERSION

user/_fsexport:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <append_str>:

static void append_char(char *buf, int *pos, char c) {
    if (*pos < OUTBUF_SZ - 1) buf[(*pos)++] = c;
}

static void append_str(char *buf, int *pos, const char *s) {
       0:	1141                	addi	sp,sp,-16
       2:	e422                	sd	s0,8(sp)
       4:	0800                	addi	s0,sp,16
    while (*s && *pos < OUTBUF_SZ - 1) buf[(*pos)++] = *s++;
       6:	00064783          	lbu	a5,0(a2)
       a:	3fe00693          	li	a3,1022
       e:	c385                	beqz	a5,2e <append_str+0x2e>
      10:	419c                	lw	a5,0(a1)
      12:	00f6ce63          	blt	a3,a5,2e <append_str+0x2e>
      16:	0605                	addi	a2,a2,1
      18:	0017871b          	addiw	a4,a5,1
      1c:	c198                	sw	a4,0(a1)
      1e:	fff64703          	lbu	a4,-1(a2)
      22:	97aa                	add	a5,a5,a0
      24:	00e78023          	sb	a4,0(a5)
      28:	00064783          	lbu	a5,0(a2)
      2c:	f3f5                	bnez	a5,10 <append_str+0x10>
}
      2e:	6422                	ld	s0,8(sp)
      30:	0141                	addi	sp,sp,16
      32:	8082                	ret

0000000000000034 <append_uint>:

static void append_uint(char *buf, int *pos, uint x) {
      34:	1101                	addi	sp,sp,-32
      36:	ec22                	sd	s0,24(sp)
      38:	1000                	addi	s0,sp,32
    char tmp[16]; int n = 0;
    if (x == 0) { buf[(*pos)++] = '0'; return; }
      3a:	fe040813          	addi	a6,s0,-32
      3e:	87c2                	mv	a5,a6
    while (x > 0) { tmp[n++] = '0' + (x % 10); x /= 10; }
      40:	46a9                	li	a3,10
      42:	4325                	li	t1,9
    if (x == 0) { buf[(*pos)++] = '0'; return; }
      44:	c225                	beqz	a2,a4 <append_uint+0x70>
    while (x > 0) { tmp[n++] = '0' + (x % 10); x /= 10; }
      46:	02d6773b          	remuw	a4,a2,a3
      4a:	0307071b          	addiw	a4,a4,48
      4e:	00e78023          	sb	a4,0(a5)
      52:	0006089b          	sext.w	a7,a2
      56:	02d6563b          	divuw	a2,a2,a3
      5a:	873e                	mv	a4,a5
      5c:	0785                	addi	a5,a5,1
      5e:	ff1364e3          	bltu	t1,a7,46 <append_uint+0x12>
      62:	4107073b          	subw	a4,a4,a6
      66:	0017079b          	addiw	a5,a4,1
      6a:	0007861b          	sext.w	a2,a5
    while (n > 0) buf[(*pos)++] = tmp[--n];
      6e:	02c05863          	blez	a2,9e <append_uint+0x6a>
      72:	fe040713          	addi	a4,s0,-32
      76:	9732                	add	a4,a4,a2
      78:	fff80693          	addi	a3,a6,-1
      7c:	96b2                	add	a3,a3,a2
      7e:	37fd                	addiw	a5,a5,-1
      80:	1782                	slli	a5,a5,0x20
      82:	9381                	srli	a5,a5,0x20
      84:	8e9d                	sub	a3,a3,a5
      86:	419c                	lw	a5,0(a1)
      88:	0017861b          	addiw	a2,a5,1
      8c:	c190                	sw	a2,0(a1)
      8e:	97aa                	add	a5,a5,a0
      90:	fff74603          	lbu	a2,-1(a4)
      94:	00c78023          	sb	a2,0(a5)
      98:	177d                	addi	a4,a4,-1
      9a:	fed716e3          	bne	a4,a3,86 <append_uint+0x52>
}
      9e:	6462                	ld	s0,24(sp)
      a0:	6105                	addi	sp,sp,32
      a2:	8082                	ret
    if (x == 0) { buf[(*pos)++] = '0'; return; }
      a4:	419c                	lw	a5,0(a1)
      a6:	0017871b          	addiw	a4,a5,1
      aa:	c198                	sw	a4,0(a1)
      ac:	97aa                	add	a5,a5,a0
      ae:	03000713          	li	a4,48
      b2:	00e78023          	sb	a4,0(a5)
      b6:	b7e5                	j	9e <append_uint+0x6a>

00000000000000b8 <append_int>:

static void append_int(char *buf, int *pos, int x) {
      b8:	1141                	addi	sp,sp,-16
      ba:	e406                	sd	ra,8(sp)
      bc:	e022                	sd	s0,0(sp)
      be:	0800                	addi	s0,sp,16
    if (x < 0) { append_char(buf, pos, '-'); x = -x; }
      c0:	00064863          	bltz	a2,d0 <append_int+0x18>
    append_uint(buf, pos, (uint)x);
      c4:	f71ff0ef          	jal	34 <append_uint>
}
      c8:	60a2                	ld	ra,8(sp)
      ca:	6402                	ld	s0,0(sp)
      cc:	0141                	addi	sp,sp,16
      ce:	8082                	ret
    if (*pos < OUTBUF_SZ - 1) buf[(*pos)++] = c;
      d0:	419c                	lw	a5,0(a1)
      d2:	3fe00713          	li	a4,1022
      d6:	00f74a63          	blt	a4,a5,ea <append_int+0x32>
      da:	0017871b          	addiw	a4,a5,1
      de:	c198                	sw	a4,0(a1)
      e0:	97aa                	add	a5,a5,a0
      e2:	02d00713          	li	a4,45
      e6:	00e78023          	sb	a4,0(a5)
    if (x < 0) { append_char(buf, pos, '-'); x = -x; }
      ea:	40c0063b          	negw	a2,a2
      ee:	bfd9                	j	c4 <append_int+0xc>

00000000000000f0 <print_change>:

static void print_change(char *buf, int *pos, const char *name, int oldv, int newv) {
    if(oldv != newv){
      f0:	00e69363          	bne	a3,a4,f6 <print_change+0x6>
      f4:	8082                	ret
static void print_change(char *buf, int *pos, const char *name, int oldv, int newv) {
      f6:	7139                	addi	sp,sp,-64
      f8:	fc06                	sd	ra,56(sp)
      fa:	f822                	sd	s0,48(sp)
      fc:	f426                	sd	s1,40(sp)
      fe:	f04a                	sd	s2,32(sp)
     100:	ec4e                	sd	s3,24(sp)
     102:	e852                	sd	s4,16(sp)
     104:	e456                	sd	s5,8(sp)
     106:	0080                	addi	s0,sp,64
     108:	84aa                	mv	s1,a0
     10a:	892e                	mv	s2,a1
     10c:	8ab2                	mv	s5,a2
     10e:	8a36                	mv	s4,a3
     110:	89ba                	mv	s3,a4
        append_str(buf, pos, "\"");
     112:	00001617          	auipc	a2,0x1
     116:	7ee60613          	addi	a2,a2,2030 # 1900 <malloc+0x104>
     11a:	ee7ff0ef          	jal	0 <append_str>
        append_str(buf, pos, name);
     11e:	8656                	mv	a2,s5
     120:	85ca                	mv	a1,s2
     122:	8526                	mv	a0,s1
     124:	eddff0ef          	jal	0 <append_str>
        append_str(buf, pos, "\":\"");
     128:	00001617          	auipc	a2,0x1
     12c:	7e060613          	addi	a2,a2,2016 # 1908 <malloc+0x10c>
     130:	85ca                	mv	a1,s2
     132:	8526                	mv	a0,s1
     134:	ecdff0ef          	jal	0 <append_str>
        append_int(buf, pos, oldv);
     138:	8652                	mv	a2,s4
     13a:	85ca                	mv	a1,s2
     13c:	8526                	mv	a0,s1
     13e:	f7bff0ef          	jal	b8 <append_int>
        append_str(buf, pos, "->");
     142:	00001617          	auipc	a2,0x1
     146:	7ce60613          	addi	a2,a2,1998 # 1910 <malloc+0x114>
     14a:	85ca                	mv	a1,s2
     14c:	8526                	mv	a0,s1
     14e:	eb3ff0ef          	jal	0 <append_str>
        append_int(buf, pos, newv);
     152:	864e                	mv	a2,s3
     154:	85ca                	mv	a1,s2
     156:	8526                	mv	a0,s1
     158:	f61ff0ef          	jal	b8 <append_int>
        append_str(buf, pos, "\",");
     15c:	00001617          	auipc	a2,0x1
     160:	7bc60613          	addi	a2,a2,1980 # 1918 <malloc+0x11c>
     164:	85ca                	mv	a1,s2
     166:	8526                	mv	a0,s1
     168:	e99ff0ef          	jal	0 <append_str>
    }
}
     16c:	70e2                	ld	ra,56(sp)
     16e:	7442                	ld	s0,48(sp)
     170:	74a2                	ld	s1,40(sp)
     172:	7902                	ld	s2,32(sp)
     174:	69e2                	ld	s3,24(sp)
     176:	6a42                	ld	s4,16(sp)
     178:	6aa2                	ld	s5,8(sp)
     17a:	6121                	addi	sp,sp,64
     17c:	8082                	ret

000000000000017e <print_fs_event>:
static void print_fs_event(const struct fs_event *e) {
     17e:	b9010113          	addi	sp,sp,-1136
     182:	46113423          	sd	ra,1128(sp)
     186:	46813023          	sd	s0,1120(sp)
     18a:	44913c23          	sd	s1,1112(sp)
     18e:	45213823          	sd	s2,1104(sp)
     192:	47010413          	addi	s0,sp,1136
     196:	84aa                	mv	s1,a0
    char buf[OUTBUF_SZ];
    int pos = 0;
     198:	ba042e23          	sw	zero,-1092(s0)

    append_str(buf, &pos, "{");
     19c:	00001617          	auipc	a2,0x1
     1a0:	78460613          	addi	a2,a2,1924 # 1920 <malloc+0x124>
     1a4:	bbc40593          	addi	a1,s0,-1092
     1a8:	bc040513          	addi	a0,s0,-1088
     1ac:	e55ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"seq\":");
     1b0:	00001617          	auipc	a2,0x1
     1b4:	77860613          	addi	a2,a2,1912 # 1928 <malloc+0x12c>
     1b8:	bbc40593          	addi	a1,s0,-1092
     1bc:	bc040513          	addi	a0,s0,-1088
     1c0:	e41ff0ef          	jal	0 <append_str>
    append_uint(buf, &pos, e->seq);
     1c4:	4090                	lw	a2,0(s1)
     1c6:	bbc40593          	addi	a1,s0,-1092
     1ca:	bc040513          	addi	a0,s0,-1088
     1ce:	e67ff0ef          	jal	34 <append_uint>
    append_str(buf, &pos, ",");
     1d2:	00001617          	auipc	a2,0x1
     1d6:	75e60613          	addi	a2,a2,1886 # 1930 <malloc+0x134>
     1da:	bbc40593          	addi	a1,s0,-1092
     1de:	bc040513          	addi	a0,s0,-1088
     1e2:	e1fff0ef          	jal	0 <append_str>

    append_str(buf, &pos, "\"tick\":"); append_uint(buf, &pos, e->ticks);
     1e6:	00001617          	auipc	a2,0x1
     1ea:	75260613          	addi	a2,a2,1874 # 1938 <malloc+0x13c>
     1ee:	bbc40593          	addi	a1,s0,-1092
     1f2:	bc040513          	addi	a0,s0,-1088
     1f6:	e0bff0ef          	jal	0 <append_str>
     1fa:	4490                	lw	a2,8(s1)
     1fc:	bbc40593          	addi	a1,s0,-1092
     200:	bc040513          	addi	a0,s0,-1088
     204:	e31ff0ef          	jal	34 <append_uint>
    append_str(buf, &pos, ",\"pid\":"); append_int(buf, &pos, e->pid);
     208:	00001617          	auipc	a2,0x1
     20c:	73860613          	addi	a2,a2,1848 # 1940 <malloc+0x144>
     210:	bbc40593          	addi	a1,s0,-1092
     214:	bc040513          	addi	a0,s0,-1088
     218:	de9ff0ef          	jal	0 <append_str>
     21c:	44d0                	lw	a2,12(s1)
     21e:	bbc40593          	addi	a1,s0,-1092
     222:	bc040513          	addi	a0,s0,-1088
     226:	e93ff0ef          	jal	b8 <append_int>

    append_str(buf, &pos, ",\"layer\":\"");
     22a:	00001617          	auipc	a2,0x1
     22e:	71e60613          	addi	a2,a2,1822 # 1948 <malloc+0x14c>
     232:	bbc40593          	addi	a1,s0,-1092
     236:	bc040513          	addi	a0,s0,-1088
     23a:	dc7ff0ef          	jal	0 <append_str>
    if(e->type == LAYER_BCACHE)
     23e:	0104a903          	lw	s2,16(s1)
     242:	479d                	li	a5,7
     244:	4f27e8e3          	bltu	a5,s2,f34 <print_fs_event+0xdb6>
     248:	00291793          	slli	a5,s2,0x2
     24c:	00002717          	auipc	a4,0x2
     250:	a0470713          	addi	a4,a4,-1532 # 1c50 <malloc+0x454>
     254:	97ba                	add	a5,a5,a4
     256:	439c                	lw	a5,0(a5)
     258:	97ba                	add	a5,a5,a4
     25a:	8782                	jr	a5
     25c:	45313423          	sd	s3,1096(sp)
    append_str(buf, &pos, "BCACHE");
     260:	00001617          	auipc	a2,0x1
     264:	6f860613          	addi	a2,a2,1784 # 1958 <malloc+0x15c>
     268:	bbc40593          	addi	a1,s0,-1092
     26c:	bc040513          	addi	a0,s0,-1088
     270:	d91ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "DIR");
    else if(e->type == LAYER_PATH)
    append_str(buf, &pos, "PATH");
    else if(e->type == LAYER_FILE)
    append_str(buf, &pos, "FILE");
    append_str(buf, &pos, "\"");
     274:	00001617          	auipc	a2,0x1
     278:	68c60613          	addi	a2,a2,1676 # 1900 <malloc+0x104>
     27c:	bbc40593          	addi	a1,s0,-1092
     280:	bc040513          	addi	a0,s0,-1088
     284:	d7dff0ef          	jal	0 <append_str>

    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     288:	00001617          	auipc	a2,0x1
     28c:	6d860613          	addi	a2,a2,1752 # 1960 <malloc+0x164>
     290:	bbc40593          	addi	a1,s0,-1092
     294:	bc040513          	addi	a0,s0,-1088
     298:	d69ff0ef          	jal	0 <append_str>
     29c:	01448613          	addi	a2,s1,20
     2a0:	bbc40593          	addi	a1,s0,-1092
     2a4:	bc040513          	addi	a0,s0,-1088
     2a8:	d59ff0ef          	jal	0 <append_str>
     2ac:	00001617          	auipc	a2,0x1
     2b0:	65460613          	addi	a2,a2,1620 # 1900 <malloc+0x104>
     2b4:	bbc40593          	addi	a1,s0,-1092
     2b8:	bc040513          	addi	a0,s0,-1088
     2bc:	d45ff0ef          	jal	0 <append_str>

    // ===== BCACHE =====
    if(e->type == LAYER_BCACHE){

        append_str(buf, &pos, ",\"buf\":{");
     2c0:	00001617          	auipc	a2,0x1
     2c4:	6d860613          	addi	a2,a2,1752 # 1998 <malloc+0x19c>
     2c8:	bbc40593          	addi	a1,s0,-1092
     2cc:	bc040513          	addi	a0,s0,-1088
     2d0:	d31ff0ef          	jal	0 <append_str>
        append_str(buf, &pos, "\"id\":"); append_int(buf, &pos, e->buf_id);
     2d4:	00001617          	auipc	a2,0x1
     2d8:	6d460613          	addi	a2,a2,1748 # 19a8 <malloc+0x1ac>
     2dc:	bbc40593          	addi	a1,s0,-1092
     2e0:	bc040513          	addi	a0,s0,-1088
     2e4:	d1dff0ef          	jal	0 <append_str>
     2e8:	5490                	lw	a2,40(s1)
     2ea:	bbc40593          	addi	a1,s0,-1092
     2ee:	bc040513          	addi	a0,s0,-1088
     2f2:	dc7ff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, ",\"block\":"); append_int(buf, &pos, e->blockno);
     2f6:	00001617          	auipc	a2,0x1
     2fa:	6ba60613          	addi	a2,a2,1722 # 19b0 <malloc+0x1b4>
     2fe:	bbc40593          	addi	a1,s0,-1092
     302:	bc040513          	addi	a0,s0,-1088
     306:	cfbff0ef          	jal	0 <append_str>
     30a:	50d0                	lw	a2,36(s1)
     30c:	bbc40593          	addi	a1,s0,-1092
     310:	bc040513          	addi	a0,s0,-1088
     314:	da5ff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, "}");
     318:	00001617          	auipc	a2,0x1
     31c:	6a860613          	addi	a2,a2,1704 # 19c0 <malloc+0x1c4>
     320:	bbc40593          	addi	a1,s0,-1092
     324:	bc040513          	addi	a0,s0,-1088
     328:	cd9ff0ef          	jal	0 <append_str>

        append_str(buf, &pos, ",\"state\":{");
     32c:	00001617          	auipc	a2,0x1
     330:	69c60613          	addi	a2,a2,1692 # 19c8 <malloc+0x1cc>
     334:	bbc40593          	addi	a1,s0,-1092
     338:	bc040513          	addi	a0,s0,-1088
     33c:	cc5ff0ef          	jal	0 <append_str>
        append_str(buf, &pos, "\"ref\":"); append_int(buf, &pos, e->refcnt);
     340:	00001617          	auipc	a2,0x1
     344:	69860613          	addi	a2,a2,1688 # 19d8 <malloc+0x1dc>
     348:	bbc40593          	addi	a1,s0,-1092
     34c:	bc040513          	addi	a0,s0,-1088
     350:	cb1ff0ef          	jal	0 <append_str>
     354:	02c4a983          	lw	s3,44(s1)
     358:	864e                	mv	a2,s3
     35a:	bbc40593          	addi	a1,s0,-1092
     35e:	bc040513          	addi	a0,s0,-1088
     362:	d57ff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, ",\"valid\":"); append_int(buf, &pos, e->valid);
     366:	00001617          	auipc	a2,0x1
     36a:	67a60613          	addi	a2,a2,1658 # 19e0 <malloc+0x1e4>
     36e:	bbc40593          	addi	a1,s0,-1092
     372:	bc040513          	addi	a0,s0,-1088
     376:	c8bff0ef          	jal	0 <append_str>
     37a:	0344a903          	lw	s2,52(s1)
     37e:	864a                	mv	a2,s2
     380:	bbc40593          	addi	a1,s0,-1092
     384:	bc040513          	addi	a0,s0,-1088
     388:	d31ff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, "}");
     38c:	00001617          	auipc	a2,0x1
     390:	63460613          	addi	a2,a2,1588 # 19c0 <malloc+0x1c4>
     394:	bbc40593          	addi	a1,s0,-1092
     398:	bc040513          	addi	a0,s0,-1088
     39c:	c65ff0ef          	jal	0 <append_str>

        append_str(buf, &pos, ",\"changes\":{");
     3a0:	00001617          	auipc	a2,0x1
     3a4:	65060613          	addi	a2,a2,1616 # 19f0 <malloc+0x1f4>
     3a8:	bbc40593          	addi	a1,s0,-1092
     3ac:	bc040513          	addi	a0,s0,-1088
     3b0:	c51ff0ef          	jal	0 <append_str>
        print_change(buf, &pos, "ref", e->old_refcnt, e->refcnt);
     3b4:	874e                	mv	a4,s3
     3b6:	5894                	lw	a3,48(s1)
     3b8:	00001617          	auipc	a2,0x1
     3bc:	64860613          	addi	a2,a2,1608 # 1a00 <malloc+0x204>
     3c0:	bbc40593          	addi	a1,s0,-1092
     3c4:	bc040513          	addi	a0,s0,-1088
     3c8:	d29ff0ef          	jal	f0 <print_change>
        print_change(buf, &pos, "valid", e->old_valid, e->valid);
     3cc:	874a                	mv	a4,s2
     3ce:	5c94                	lw	a3,56(s1)
     3d0:	00001617          	auipc	a2,0x1
     3d4:	63860613          	addi	a2,a2,1592 # 1a08 <malloc+0x20c>
     3d8:	bbc40593          	addi	a1,s0,-1092
     3dc:	bc040513          	addi	a0,s0,-1088
     3e0:	d11ff0ef          	jal	f0 <print_change>

        if(buf[pos-1] == ',') pos--; // remove last comma
     3e4:	bbc42783          	lw	a5,-1092(s0)
     3e8:	37fd                	addiw	a5,a5,-1
     3ea:	0007871b          	sext.w	a4,a5
     3ee:	fc070713          	addi	a4,a4,-64
     3f2:	9722                	add	a4,a4,s0
     3f4:	c0074683          	lbu	a3,-1024(a4)
     3f8:	02c00713          	li	a4,44
     3fc:	3ae683e3          	beq	a3,a4,fa2 <print_fs_event+0xe24>
        append_str(buf, &pos, "}");
     400:	00001617          	auipc	a2,0x1
     404:	5c060613          	addi	a2,a2,1472 # 19c0 <malloc+0x1c4>
     408:	bbc40593          	addi	a1,s0,-1092
     40c:	bc040513          	addi	a0,s0,-1088
     410:	bf1ff0ef          	jal	0 <append_str>
     414:	44813983          	ld	s3,1096(sp)
    if(buf[pos-1] == ',')
        pos--;

    append_str(buf, &pos, "}");
}
    append_str(buf, &pos, ",\"desc\":\"");
     418:	00001617          	auipc	a2,0x1
     41c:	7d060613          	addi	a2,a2,2000 # 1be8 <malloc+0x3ec>
     420:	bbc40593          	addi	a1,s0,-1092
     424:	bc040513          	addi	a0,s0,-1088
     428:	bd9ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->details);
     42c:	28c48613          	addi	a2,s1,652
     430:	bbc40593          	addi	a1,s0,-1092
     434:	bc040513          	addi	a0,s0,-1088
     438:	bc9ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     43c:	00001617          	auipc	a2,0x1
     440:	4c460613          	addi	a2,a2,1220 # 1900 <malloc+0x104>
     444:	bbc40593          	addi	a1,s0,-1092
     448:	bc040513          	addi	a0,s0,-1088
     44c:	bb5ff0ef          	jal	0 <append_str>

    append_str(buf, &pos, "}\n");
     450:	00001617          	auipc	a2,0x1
     454:	7a860613          	addi	a2,a2,1960 # 1bf8 <malloc+0x3fc>
     458:	bbc40593          	addi	a1,s0,-1092
     45c:	bc040513          	addi	a0,s0,-1088
     460:	ba1ff0ef          	jal	0 <append_str>

    write(1, buf, pos);
     464:	bbc42603          	lw	a2,-1092(s0)
     468:	bc040593          	addi	a1,s0,-1088
     46c:	4505                	li	a0,1
     46e:	6c3000ef          	jal	1330 <write>
}
     472:	46813083          	ld	ra,1128(sp)
     476:	46013403          	ld	s0,1120(sp)
     47a:	45813483          	ld	s1,1112(sp)
     47e:	45013903          	ld	s2,1104(sp)
     482:	47010113          	addi	sp,sp,1136
     486:	8082                	ret
     488:	45313423          	sd	s3,1096(sp)
     48c:	45413023          	sd	s4,1088(sp)
    append_str(buf, &pos, "LOG");
     490:	00001617          	auipc	a2,0x1
     494:	4d860613          	addi	a2,a2,1240 # 1968 <malloc+0x16c>
     498:	bbc40593          	addi	a1,s0,-1092
     49c:	bc040513          	addi	a0,s0,-1088
     4a0:	b61ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     4a4:	00001617          	auipc	a2,0x1
     4a8:	45c60613          	addi	a2,a2,1116 # 1900 <malloc+0x104>
     4ac:	bbc40593          	addi	a1,s0,-1092
     4b0:	bc040513          	addi	a0,s0,-1088
     4b4:	b4dff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     4b8:	00001617          	auipc	a2,0x1
     4bc:	4a860613          	addi	a2,a2,1192 # 1960 <malloc+0x164>
     4c0:	bbc40593          	addi	a1,s0,-1092
     4c4:	bc040513          	addi	a0,s0,-1088
     4c8:	b39ff0ef          	jal	0 <append_str>
     4cc:	01448613          	addi	a2,s1,20
     4d0:	bbc40593          	addi	a1,s0,-1092
     4d4:	bc040513          	addi	a0,s0,-1088
     4d8:	b29ff0ef          	jal	0 <append_str>
     4dc:	00001617          	auipc	a2,0x1
     4e0:	42460613          	addi	a2,a2,1060 # 1900 <malloc+0x104>
     4e4:	bbc40593          	addi	a1,s0,-1092
     4e8:	bc040513          	addi	a0,s0,-1088
     4ec:	b15ff0ef          	jal	0 <append_str>
        append_str(buf, &pos, ",\"state\":{");
     4f0:	00001617          	auipc	a2,0x1
     4f4:	4d860613          	addi	a2,a2,1240 # 19c8 <malloc+0x1cc>
     4f8:	bbc40593          	addi	a1,s0,-1092
     4fc:	bc040513          	addi	a0,s0,-1088
     500:	b01ff0ef          	jal	0 <append_str>
        append_str(buf, &pos, "\"log_n\":"); append_int(buf, &pos, e->log_n);
     504:	00001617          	auipc	a2,0x1
     508:	50c60613          	addi	a2,a2,1292 # 1a10 <malloc+0x214>
     50c:	bbc40593          	addi	a1,s0,-1092
     510:	bc040513          	addi	a0,s0,-1088
     514:	aedff0ef          	jal	0 <append_str>
     518:	03c4aa03          	lw	s4,60(s1)
     51c:	8652                	mv	a2,s4
     51e:	bbc40593          	addi	a1,s0,-1092
     522:	bc040513          	addi	a0,s0,-1088
     526:	b93ff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, ",\"outstanding\":"); append_int(buf, &pos, e->outstanding);
     52a:	00001617          	auipc	a2,0x1
     52e:	4f660613          	addi	a2,a2,1270 # 1a20 <malloc+0x224>
     532:	bbc40593          	addi	a1,s0,-1092
     536:	bc040513          	addi	a0,s0,-1088
     53a:	ac7ff0ef          	jal	0 <append_str>
     53e:	0444a983          	lw	s3,68(s1)
     542:	864e                	mv	a2,s3
     544:	bbc40593          	addi	a1,s0,-1092
     548:	bc040513          	addi	a0,s0,-1088
     54c:	b6dff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, ",\"committing\":"); append_int(buf, &pos, e->committing);
     550:	00001617          	auipc	a2,0x1
     554:	4e060613          	addi	a2,a2,1248 # 1a30 <malloc+0x234>
     558:	bbc40593          	addi	a1,s0,-1092
     55c:	bc040513          	addi	a0,s0,-1088
     560:	aa1ff0ef          	jal	0 <append_str>
     564:	04c4a903          	lw	s2,76(s1)
     568:	864a                	mv	a2,s2
     56a:	bbc40593          	addi	a1,s0,-1092
     56e:	bc040513          	addi	a0,s0,-1088
     572:	b47ff0ef          	jal	b8 <append_int>
        append_str(buf, &pos, "}");
     576:	00001617          	auipc	a2,0x1
     57a:	44a60613          	addi	a2,a2,1098 # 19c0 <malloc+0x1c4>
     57e:	bbc40593          	addi	a1,s0,-1092
     582:	bc040513          	addi	a0,s0,-1088
     586:	a7bff0ef          	jal	0 <append_str>
        append_str(buf, &pos, ",\"changes\":{");
     58a:	00001617          	auipc	a2,0x1
     58e:	46660613          	addi	a2,a2,1126 # 19f0 <malloc+0x1f4>
     592:	bbc40593          	addi	a1,s0,-1092
     596:	bc040513          	addi	a0,s0,-1088
     59a:	a67ff0ef          	jal	0 <append_str>
        print_change(buf, &pos, "log_n", e->old_log_n, e->log_n);
     59e:	8752                	mv	a4,s4
     5a0:	40b4                	lw	a3,64(s1)
     5a2:	00001617          	auipc	a2,0x1
     5a6:	49e60613          	addi	a2,a2,1182 # 1a40 <malloc+0x244>
     5aa:	bbc40593          	addi	a1,s0,-1092
     5ae:	bc040513          	addi	a0,s0,-1088
     5b2:	b3fff0ef          	jal	f0 <print_change>
        print_change(buf, &pos, "outstanding", e->old_outstanding, e->outstanding);
     5b6:	874e                	mv	a4,s3
     5b8:	44b4                	lw	a3,72(s1)
     5ba:	00001617          	auipc	a2,0x1
     5be:	48e60613          	addi	a2,a2,1166 # 1a48 <malloc+0x24c>
     5c2:	bbc40593          	addi	a1,s0,-1092
     5c6:	bc040513          	addi	a0,s0,-1088
     5ca:	b27ff0ef          	jal	f0 <print_change>
        print_change(buf, &pos, "committing", e->old_committing, e->committing);
     5ce:	874a                	mv	a4,s2
     5d0:	48b4                	lw	a3,80(s1)
     5d2:	00001617          	auipc	a2,0x1
     5d6:	48660613          	addi	a2,a2,1158 # 1a58 <malloc+0x25c>
     5da:	bbc40593          	addi	a1,s0,-1092
     5de:	bc040513          	addi	a0,s0,-1088
     5e2:	b0fff0ef          	jal	f0 <print_change>
        if(buf[pos-1] == ',') pos--;
     5e6:	bbc42783          	lw	a5,-1092(s0)
     5ea:	37fd                	addiw	a5,a5,-1
     5ec:	0007871b          	sext.w	a4,a5
     5f0:	fc070713          	addi	a4,a4,-64
     5f4:	9722                	add	a4,a4,s0
     5f6:	c0074683          	lbu	a3,-1024(a4)
     5fa:	02c00713          	li	a4,44
     5fe:	1ae68ce3          	beq	a3,a4,fb6 <print_fs_event+0xe38>
        append_str(buf, &pos, "}");
     602:	00001617          	auipc	a2,0x1
     606:	3be60613          	addi	a2,a2,958 # 19c0 <malloc+0x1c4>
     60a:	bbc40593          	addi	a1,s0,-1092
     60e:	bc040513          	addi	a0,s0,-1088
     612:	9efff0ef          	jal	0 <append_str>
     616:	44813983          	ld	s3,1096(sp)
     61a:	44013a03          	ld	s4,1088(sp)
     61e:	bbed                	j	418 <print_fs_event+0x29a>
    append_str(buf, &pos, "BALLOC");
     620:	00001617          	auipc	a2,0x1
     624:	35060613          	addi	a2,a2,848 # 1970 <malloc+0x174>
     628:	bbc40593          	addi	a1,s0,-1092
     62c:	bc040513          	addi	a0,s0,-1088
     630:	9d1ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     634:	00001617          	auipc	a2,0x1
     638:	2cc60613          	addi	a2,a2,716 # 1900 <malloc+0x104>
     63c:	bbc40593          	addi	a1,s0,-1092
     640:	bc040513          	addi	a0,s0,-1088
     644:	9bdff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     648:	00001617          	auipc	a2,0x1
     64c:	31860613          	addi	a2,a2,792 # 1960 <malloc+0x164>
     650:	bbc40593          	addi	a1,s0,-1092
     654:	bc040513          	addi	a0,s0,-1088
     658:	9a9ff0ef          	jal	0 <append_str>
     65c:	01448613          	addi	a2,s1,20
     660:	bbc40593          	addi	a1,s0,-1092
     664:	bc040513          	addi	a0,s0,-1088
     668:	999ff0ef          	jal	0 <append_str>
     66c:	00001617          	auipc	a2,0x1
     670:	29460613          	addi	a2,a2,660 # 1900 <malloc+0x104>
     674:	bbc40593          	addi	a1,s0,-1092
     678:	bc040513          	addi	a0,s0,-1088
     67c:	985ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"block\":");
     680:	00001617          	auipc	a2,0x1
     684:	33060613          	addi	a2,a2,816 # 19b0 <malloc+0x1b4>
     688:	bbc40593          	addi	a1,s0,-1092
     68c:	bc040513          	addi	a0,s0,-1088
     690:	971ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->blockno);
     694:	50d0                	lw	a2,36(s1)
     696:	bbc40593          	addi	a1,s0,-1092
     69a:	bc040513          	addi	a0,s0,-1088
     69e:	a1bff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"state\":{");
     6a2:	00001617          	auipc	a2,0x1
     6a6:	32660613          	addi	a2,a2,806 # 19c8 <malloc+0x1cc>
     6aa:	bbc40593          	addi	a1,s0,-1092
     6ae:	bc040513          	addi	a0,s0,-1088
     6b2:	94fff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"bit\":");
     6b6:	00001617          	auipc	a2,0x1
     6ba:	3b260613          	addi	a2,a2,946 # 1a68 <malloc+0x26c>
     6be:	bbc40593          	addi	a1,s0,-1092
     6c2:	bc040513          	addi	a0,s0,-1088
     6c6:	93bff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->bit);
     6ca:	0544a903          	lw	s2,84(s1)
     6ce:	864a                	mv	a2,s2
     6d0:	bbc40593          	addi	a1,s0,-1092
     6d4:	bc040513          	addi	a0,s0,-1088
     6d8:	9e1ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, "}");
     6dc:	00001617          	auipc	a2,0x1
     6e0:	2e460613          	addi	a2,a2,740 # 19c0 <malloc+0x1c4>
     6e4:	bbc40593          	addi	a1,s0,-1092
     6e8:	bc040513          	addi	a0,s0,-1088
     6ec:	915ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"changes\":{");
     6f0:	00001617          	auipc	a2,0x1
     6f4:	30060613          	addi	a2,a2,768 # 19f0 <malloc+0x1f4>
     6f8:	bbc40593          	addi	a1,s0,-1092
     6fc:	bc040513          	addi	a0,s0,-1088
     700:	901ff0ef          	jal	0 <append_str>
    print_change(buf, &pos, "bit", e->old_bit, e->bit);
     704:	874a                	mv	a4,s2
     706:	4cb4                	lw	a3,88(s1)
     708:	00001617          	auipc	a2,0x1
     70c:	36860613          	addi	a2,a2,872 # 1a70 <malloc+0x274>
     710:	bbc40593          	addi	a1,s0,-1092
     714:	bc040513          	addi	a0,s0,-1088
     718:	9d9ff0ef          	jal	f0 <print_change>
    if(buf[pos-1] == ',') pos--;
     71c:	bbc42783          	lw	a5,-1092(s0)
     720:	37fd                	addiw	a5,a5,-1
     722:	0007871b          	sext.w	a4,a5
     726:	fc070713          	addi	a4,a4,-64
     72a:	9722                	add	a4,a4,s0
     72c:	c0074683          	lbu	a3,-1024(a4)
     730:	02c00713          	li	a4,44
     734:	08e685e3          	beq	a3,a4,fbe <print_fs_event+0xe40>
    append_str(buf, &pos, "}");
     738:	00001617          	auipc	a2,0x1
     73c:	28860613          	addi	a2,a2,648 # 19c0 <malloc+0x1c4>
     740:	bbc40593          	addi	a1,s0,-1092
     744:	bc040513          	addi	a0,s0,-1088
     748:	8b9ff0ef          	jal	0 <append_str>
     74c:	b1f1                	j	418 <print_fs_event+0x29a>
     74e:	45313423          	sd	s3,1096(sp)
     752:	45413023          	sd	s4,1088(sp)
     756:	43513c23          	sd	s5,1080(sp)
     75a:	43613823          	sd	s6,1072(sp)
    append_str(buf, &pos, "INODE");
     75e:	00001617          	auipc	a2,0x1
     762:	21a60613          	addi	a2,a2,538 # 1978 <malloc+0x17c>
     766:	bbc40593          	addi	a1,s0,-1092
     76a:	bc040513          	addi	a0,s0,-1088
     76e:	893ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     772:	00001617          	auipc	a2,0x1
     776:	18e60613          	addi	a2,a2,398 # 1900 <malloc+0x104>
     77a:	bbc40593          	addi	a1,s0,-1092
     77e:	bc040513          	addi	a0,s0,-1088
     782:	87fff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     786:	00001617          	auipc	a2,0x1
     78a:	1da60613          	addi	a2,a2,474 # 1960 <malloc+0x164>
     78e:	bbc40593          	addi	a1,s0,-1092
     792:	bc040513          	addi	a0,s0,-1088
     796:	86bff0ef          	jal	0 <append_str>
     79a:	01448613          	addi	a2,s1,20
     79e:	bbc40593          	addi	a1,s0,-1092
     7a2:	bc040513          	addi	a0,s0,-1088
     7a6:	85bff0ef          	jal	0 <append_str>
     7aa:	00001617          	auipc	a2,0x1
     7ae:	15660613          	addi	a2,a2,342 # 1900 <malloc+0x104>
     7b2:	bbc40593          	addi	a1,s0,-1092
     7b6:	bc040513          	addi	a0,s0,-1088
     7ba:	847ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"inode\":{");
     7be:	00001617          	auipc	a2,0x1
     7c2:	2ba60613          	addi	a2,a2,698 # 1a78 <malloc+0x27c>
     7c6:	bbc40593          	addi	a1,s0,-1092
     7ca:	bc040513          	addi	a0,s0,-1088
     7ce:	833ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"inum\":"); append_int(buf, &pos, e->inum);
     7d2:	00001617          	auipc	a2,0x1
     7d6:	2b660613          	addi	a2,a2,694 # 1a88 <malloc+0x28c>
     7da:	bbc40593          	addi	a1,s0,-1092
     7de:	bc040513          	addi	a0,s0,-1088
     7e2:	81fff0ef          	jal	0 <append_str>
     7e6:	4cf0                	lw	a2,92(s1)
     7e8:	bbc40593          	addi	a1,s0,-1092
     7ec:	bc040513          	addi	a0,s0,-1088
     7f0:	8c9ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, "}");
     7f4:	00001617          	auipc	a2,0x1
     7f8:	1cc60613          	addi	a2,a2,460 # 19c0 <malloc+0x1c4>
     7fc:	bbc40593          	addi	a1,s0,-1092
     800:	bc040513          	addi	a0,s0,-1088
     804:	ffcff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"state\":{");
     808:	00001617          	auipc	a2,0x1
     80c:	1c060613          	addi	a2,a2,448 # 19c8 <malloc+0x1cc>
     810:	bbc40593          	addi	a1,s0,-1092
     814:	bc040513          	addi	a0,s0,-1088
     818:	fe8ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"ref\":"); append_int(buf, &pos, e->ref);
     81c:	00001617          	auipc	a2,0x1
     820:	1bc60613          	addi	a2,a2,444 # 19d8 <malloc+0x1dc>
     824:	bbc40593          	addi	a1,s0,-1092
     828:	bc040513          	addi	a0,s0,-1088
     82c:	fd4ff0ef          	jal	0 <append_str>
     830:	0604ab03          	lw	s6,96(s1)
     834:	865a                	mv	a2,s6
     836:	bbc40593          	addi	a1,s0,-1092
     83a:	bc040513          	addi	a0,s0,-1088
     83e:	87bff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"valid\":"); append_int(buf, &pos, e->valid_inode);
     842:	00001617          	auipc	a2,0x1
     846:	19e60613          	addi	a2,a2,414 # 19e0 <malloc+0x1e4>
     84a:	bbc40593          	addi	a1,s0,-1092
     84e:	bc040513          	addi	a0,s0,-1088
     852:	faeff0ef          	jal	0 <append_str>
     856:	0684aa83          	lw	s5,104(s1)
     85a:	8656                	mv	a2,s5
     85c:	bbc40593          	addi	a1,s0,-1092
     860:	bc040513          	addi	a0,s0,-1088
     864:	855ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"type\":"); append_int(buf, &pos, e->inode_type);
     868:	00001617          	auipc	a2,0x1
     86c:	22860613          	addi	a2,a2,552 # 1a90 <malloc+0x294>
     870:	bbc40593          	addi	a1,s0,-1092
     874:	bc040513          	addi	a0,s0,-1088
     878:	f88ff0ef          	jal	0 <append_str>
     87c:	0704aa03          	lw	s4,112(s1)
     880:	8652                	mv	a2,s4
     882:	bbc40593          	addi	a1,s0,-1092
     886:	bc040513          	addi	a0,s0,-1088
     88a:	82fff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"size\":"); append_int(buf, &pos, e->size);
     88e:	00001617          	auipc	a2,0x1
     892:	21260613          	addi	a2,a2,530 # 1aa0 <malloc+0x2a4>
     896:	bbc40593          	addi	a1,s0,-1092
     89a:	bc040513          	addi	a0,s0,-1088
     89e:	f62ff0ef          	jal	0 <append_str>
     8a2:	0784a983          	lw	s3,120(s1)
     8a6:	864e                	mv	a2,s3
     8a8:	bbc40593          	addi	a1,s0,-1092
     8ac:	bc040513          	addi	a0,s0,-1088
     8b0:	809ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"locked\":"); append_int(buf, &pos, e->locked);
     8b4:	00001617          	auipc	a2,0x1
     8b8:	1fc60613          	addi	a2,a2,508 # 1ab0 <malloc+0x2b4>
     8bc:	bbc40593          	addi	a1,s0,-1092
     8c0:	bc040513          	addi	a0,s0,-1088
     8c4:	f3cff0ef          	jal	0 <append_str>
     8c8:	0804a903          	lw	s2,128(s1)
     8cc:	864a                	mv	a2,s2
     8ce:	bbc40593          	addi	a1,s0,-1092
     8d2:	bc040513          	addi	a0,s0,-1088
     8d6:	fe2ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, "}");
     8da:	00001617          	auipc	a2,0x1
     8de:	0e660613          	addi	a2,a2,230 # 19c0 <malloc+0x1c4>
     8e2:	bbc40593          	addi	a1,s0,-1092
     8e6:	bc040513          	addi	a0,s0,-1088
     8ea:	f16ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"changes\":{");
     8ee:	00001617          	auipc	a2,0x1
     8f2:	10260613          	addi	a2,a2,258 # 19f0 <malloc+0x1f4>
     8f6:	bbc40593          	addi	a1,s0,-1092
     8fa:	bc040513          	addi	a0,s0,-1088
     8fe:	f02ff0ef          	jal	0 <append_str>
    print_change(buf, &pos, "ref", e->old_ref, e->ref);
     902:	875a                	mv	a4,s6
     904:	50f4                	lw	a3,100(s1)
     906:	00001617          	auipc	a2,0x1
     90a:	0fa60613          	addi	a2,a2,250 # 1a00 <malloc+0x204>
     90e:	bbc40593          	addi	a1,s0,-1092
     912:	bc040513          	addi	a0,s0,-1088
     916:	fdaff0ef          	jal	f0 <print_change>
    print_change(buf, &pos, "valid", e->old_valid_inode, e->valid_inode);
     91a:	8756                	mv	a4,s5
     91c:	54f4                	lw	a3,108(s1)
     91e:	00001617          	auipc	a2,0x1
     922:	0ea60613          	addi	a2,a2,234 # 1a08 <malloc+0x20c>
     926:	bbc40593          	addi	a1,s0,-1092
     92a:	bc040513          	addi	a0,s0,-1088
     92e:	fc2ff0ef          	jal	f0 <print_change>
    print_change(buf, &pos, "type", e->old_type_inode, e->inode_type);
     932:	8752                	mv	a4,s4
     934:	58f4                	lw	a3,116(s1)
     936:	00001617          	auipc	a2,0x1
     93a:	18a60613          	addi	a2,a2,394 # 1ac0 <malloc+0x2c4>
     93e:	bbc40593          	addi	a1,s0,-1092
     942:	bc040513          	addi	a0,s0,-1088
     946:	faaff0ef          	jal	f0 <print_change>
    print_change(buf, &pos, "size", e->old_size, e->size);
     94a:	874e                	mv	a4,s3
     94c:	5cf4                	lw	a3,124(s1)
     94e:	00001617          	auipc	a2,0x1
     952:	17a60613          	addi	a2,a2,378 # 1ac8 <malloc+0x2cc>
     956:	bbc40593          	addi	a1,s0,-1092
     95a:	bc040513          	addi	a0,s0,-1088
     95e:	f92ff0ef          	jal	f0 <print_change>
    print_change(buf, &pos, "locked", e->old_locked, e->locked);
     962:	874a                	mv	a4,s2
     964:	0844a683          	lw	a3,132(s1)
     968:	00001617          	auipc	a2,0x1
     96c:	16860613          	addi	a2,a2,360 # 1ad0 <malloc+0x2d4>
     970:	bbc40593          	addi	a1,s0,-1092
     974:	bc040513          	addi	a0,s0,-1088
     978:	f78ff0ef          	jal	f0 <print_change>
    if(buf[pos-1] == ',') pos--;
     97c:	bbc42783          	lw	a5,-1092(s0)
     980:	37fd                	addiw	a5,a5,-1
     982:	0007871b          	sext.w	a4,a5
     986:	fc070713          	addi	a4,a4,-64
     98a:	9722                	add	a4,a4,s0
     98c:	c0074683          	lbu	a3,-1024(a4)
     990:	02c00713          	li	a4,44
     994:	64e68363          	beq	a3,a4,fda <print_fs_event+0xe5c>
    append_str(buf, &pos, "}");
     998:	00001617          	auipc	a2,0x1
     99c:	02860613          	addi	a2,a2,40 # 19c0 <malloc+0x1c4>
     9a0:	bbc40593          	addi	a1,s0,-1092
     9a4:	bc040513          	addi	a0,s0,-1088
     9a8:	e58ff0ef          	jal	0 <append_str>
     9ac:	44813983          	ld	s3,1096(sp)
     9b0:	44013a03          	ld	s4,1088(sp)
     9b4:	43813a83          	ld	s5,1080(sp)
     9b8:	43013b03          	ld	s6,1072(sp)
     9bc:	bcb1                	j	418 <print_fs_event+0x29a>
    append_str(buf, &pos, "DIR");
     9be:	00001617          	auipc	a2,0x1
     9c2:	fc260613          	addi	a2,a2,-62 # 1980 <malloc+0x184>
     9c6:	bbc40593          	addi	a1,s0,-1092
     9ca:	bc040513          	addi	a0,s0,-1088
     9ce:	e32ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     9d2:	00001617          	auipc	a2,0x1
     9d6:	f2e60613          	addi	a2,a2,-210 # 1900 <malloc+0x104>
     9da:	bbc40593          	addi	a1,s0,-1092
     9de:	bc040513          	addi	a0,s0,-1088
     9e2:	e1eff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     9e6:	00001617          	auipc	a2,0x1
     9ea:	f7a60613          	addi	a2,a2,-134 # 1960 <malloc+0x164>
     9ee:	bbc40593          	addi	a1,s0,-1092
     9f2:	bc040513          	addi	a0,s0,-1088
     9f6:	e0aff0ef          	jal	0 <append_str>
     9fa:	01448613          	addi	a2,s1,20
     9fe:	bbc40593          	addi	a1,s0,-1092
     a02:	bc040513          	addi	a0,s0,-1088
     a06:	dfaff0ef          	jal	0 <append_str>
     a0a:	00001617          	auipc	a2,0x1
     a0e:	ef660613          	addi	a2,a2,-266 # 1900 <malloc+0x104>
     a12:	bbc40593          	addi	a1,s0,-1092
     a16:	bc040513          	addi	a0,s0,-1088
     a1a:	de6ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"dir\":{");
     a1e:	00001617          	auipc	a2,0x1
     a22:	0ba60613          	addi	a2,a2,186 # 1ad8 <malloc+0x2dc>
     a26:	bbc40593          	addi	a1,s0,-1092
     a2a:	bc040513          	addi	a0,s0,-1088
     a2e:	dd2ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"parent\":");
     a32:	00001617          	auipc	a2,0x1
     a36:	0b660613          	addi	a2,a2,182 # 1ae8 <malloc+0x2ec>
     a3a:	bbc40593          	addi	a1,s0,-1092
     a3e:	bc040513          	addi	a0,s0,-1088
     a42:	dbeff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->parent_inum);
     a46:	1bc4a603          	lw	a2,444(s1)
     a4a:	bbc40593          	addi	a1,s0,-1092
     a4e:	bc040513          	addi	a0,s0,-1088
     a52:	e66ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"target\":");
     a56:	00001617          	auipc	a2,0x1
     a5a:	0a260613          	addi	a2,a2,162 # 1af8 <malloc+0x2fc>
     a5e:	bbc40593          	addi	a1,s0,-1092
     a62:	bc040513          	addi	a0,s0,-1088
     a66:	d9aff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->target_inum);
     a6a:	1c04a603          	lw	a2,448(s1)
     a6e:	bbc40593          	addi	a1,s0,-1092
     a72:	bc040513          	addi	a0,s0,-1088
     a76:	e42ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"offset\":");
     a7a:	00001617          	auipc	a2,0x1
     a7e:	08e60613          	addi	a2,a2,142 # 1b08 <malloc+0x30c>
     a82:	bbc40593          	addi	a1,s0,-1092
     a86:	bc040513          	addi	a0,s0,-1088
     a8a:	d76ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->offset);
     a8e:	1c44a603          	lw	a2,452(s1)
     a92:	bbc40593          	addi	a1,s0,-1092
     a96:	bc040513          	addi	a0,s0,-1088
     a9a:	e1eff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"type\":");
     a9e:	00001617          	auipc	a2,0x1
     aa2:	ff260613          	addi	a2,a2,-14 # 1a90 <malloc+0x294>
     aa6:	bbc40593          	addi	a1,s0,-1092
     aaa:	bc040513          	addi	a0,s0,-1088
     aae:	d52ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->inode_type);
     ab2:	58b0                	lw	a2,112(s1)
     ab4:	bbc40593          	addi	a1,s0,-1092
     ab8:	bc040513          	addi	a0,s0,-1088
     abc:	dfcff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"name\":\"");
     ac0:	00001617          	auipc	a2,0x1
     ac4:	05860613          	addi	a2,a2,88 # 1b18 <malloc+0x31c>
     ac8:	bbc40593          	addi	a1,s0,-1092
     acc:	bc040513          	addi	a0,s0,-1088
     ad0:	d30ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->name);
     ad4:	1a848613          	addi	a2,s1,424
     ad8:	bbc40593          	addi	a1,s0,-1092
     adc:	bc040513          	addi	a0,s0,-1088
     ae0:	d20ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"}");
     ae4:	00001617          	auipc	a2,0x1
     ae8:	04460613          	addi	a2,a2,68 # 1b28 <malloc+0x32c>
     aec:	bbc40593          	addi	a1,s0,-1092
     af0:	bc040513          	addi	a0,s0,-1088
     af4:	d0cff0ef          	jal	0 <append_str>
     af8:	921ff06f          	j	418 <print_fs_event+0x29a>
    append_str(buf, &pos, "PATH");
     afc:	00001617          	auipc	a2,0x1
     b00:	e8c60613          	addi	a2,a2,-372 # 1988 <malloc+0x18c>
     b04:	bbc40593          	addi	a1,s0,-1092
     b08:	bc040513          	addi	a0,s0,-1088
     b0c:	cf4ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     b10:	00001617          	auipc	a2,0x1
     b14:	df060613          	addi	a2,a2,-528 # 1900 <malloc+0x104>
     b18:	bbc40593          	addi	a1,s0,-1092
     b1c:	bc040513          	addi	a0,s0,-1088
     b20:	ce0ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     b24:	00001617          	auipc	a2,0x1
     b28:	e3c60613          	addi	a2,a2,-452 # 1960 <malloc+0x164>
     b2c:	bbc40593          	addi	a1,s0,-1092
     b30:	bc040513          	addi	a0,s0,-1088
     b34:	cccff0ef          	jal	0 <append_str>
     b38:	01448613          	addi	a2,s1,20
     b3c:	bbc40593          	addi	a1,s0,-1092
     b40:	bc040513          	addi	a0,s0,-1088
     b44:	cbcff0ef          	jal	0 <append_str>
     b48:	00001617          	auipc	a2,0x1
     b4c:	db860613          	addi	a2,a2,-584 # 1900 <malloc+0x104>
     b50:	bbc40593          	addi	a1,s0,-1092
     b54:	bc040513          	addi	a0,s0,-1088
     b58:	ca8ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"syscall\":\"");
     b5c:	00001617          	auipc	a2,0x1
     b60:	fd460613          	addi	a2,a2,-44 # 1b30 <malloc+0x334>
     b64:	bbc40593          	addi	a1,s0,-1092
     b68:	bc040513          	addi	a0,s0,-1088
     b6c:	c94ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->syscall);
     b70:	10848613          	addi	a2,s1,264
     b74:	bbc40593          	addi	a1,s0,-1092
     b78:	bc040513          	addi	a0,s0,-1088
     b7c:	c84ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     b80:	00001617          	auipc	a2,0x1
     b84:	d8060613          	addi	a2,a2,-640 # 1900 <malloc+0x104>
     b88:	bbc40593          	addi	a1,s0,-1092
     b8c:	bc040513          	addi	a0,s0,-1088
     b90:	c70ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"cwd\":\"");
     b94:	00001617          	auipc	a2,0x1
     b98:	fac60613          	addi	a2,a2,-84 # 1b40 <malloc+0x344>
     b9c:	bbc40593          	addi	a1,s0,-1092
     ba0:	bc040513          	addi	a0,s0,-1088
     ba4:	c5cff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->cwd);
     ba8:	08848613          	addi	a2,s1,136
     bac:	bbc40593          	addi	a1,s0,-1092
     bb0:	bc040513          	addi	a0,s0,-1088
     bb4:	c4cff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     bb8:	00001617          	auipc	a2,0x1
     bbc:	d4860613          	addi	a2,a2,-696 # 1900 <malloc+0x104>
     bc0:	bbc40593          	addi	a1,s0,-1092
     bc4:	bc040513          	addi	a0,s0,-1088
     bc8:	c38ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"path\":\"");
     bcc:	00001617          	auipc	a2,0x1
     bd0:	f8460613          	addi	a2,a2,-124 # 1b50 <malloc+0x354>
     bd4:	bbc40593          	addi	a1,s0,-1092
     bd8:	bc040513          	addi	a0,s0,-1088
     bdc:	c24ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->path);
     be0:	12848613          	addi	a2,s1,296
     be4:	bbc40593          	addi	a1,s0,-1092
     be8:	bc040513          	addi	a0,s0,-1088
     bec:	c14ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     bf0:	00001617          	auipc	a2,0x1
     bf4:	d1060613          	addi	a2,a2,-752 # 1900 <malloc+0x104>
     bf8:	bbc40593          	addi	a1,s0,-1092
     bfc:	bc040513          	addi	a0,s0,-1088
     c00:	c00ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"elem\":\"");
     c04:	00001617          	auipc	a2,0x1
     c08:	f5c60613          	addi	a2,a2,-164 # 1b60 <malloc+0x364>
     c0c:	bbc40593          	addi	a1,s0,-1092
     c10:	bc040513          	addi	a0,s0,-1088
     c14:	becff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->name);
     c18:	1a848613          	addi	a2,s1,424
     c1c:	bbc40593          	addi	a1,s0,-1092
     c20:	bc040513          	addi	a0,s0,-1088
     c24:	bdcff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     c28:	00001617          	auipc	a2,0x1
     c2c:	cd860613          	addi	a2,a2,-808 # 1900 <malloc+0x104>
     c30:	bbc40593          	addi	a1,s0,-1092
     c34:	bc040513          	addi	a0,s0,-1088
     c38:	bc8ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"inode\":");
     c3c:	00001617          	auipc	a2,0x1
     c40:	f3460613          	addi	a2,a2,-204 # 1b70 <malloc+0x374>
     c44:	bbc40593          	addi	a1,s0,-1092
     c48:	bc040513          	addi	a0,s0,-1088
     c4c:	bb4ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->parent_inum);
     c50:	1bc4a603          	lw	a2,444(s1)
     c54:	bbc40593          	addi	a1,s0,-1092
     c58:	bc040513          	addi	a0,s0,-1088
     c5c:	c5cff0ef          	jal	b8 <append_int>
     c60:	fb8ff06f          	j	418 <print_fs_event+0x29a>
     c64:	45313423          	sd	s3,1096(sp)
    append_str(buf, &pos, "FILE");
     c68:	00001617          	auipc	a2,0x1
     c6c:	d2860613          	addi	a2,a2,-728 # 1990 <malloc+0x194>
     c70:	bbc40593          	addi	a1,s0,-1092
     c74:	bc040513          	addi	a0,s0,-1088
     c78:	b88ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     c7c:	00001617          	auipc	a2,0x1
     c80:	c8460613          	addi	a2,a2,-892 # 1900 <malloc+0x104>
     c84:	bbc40593          	addi	a1,s0,-1092
     c88:	bc040513          	addi	a0,s0,-1088
     c8c:	b74ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     c90:	00001617          	auipc	a2,0x1
     c94:	cd060613          	addi	a2,a2,-816 # 1960 <malloc+0x164>
     c98:	bbc40593          	addi	a1,s0,-1092
     c9c:	bc040513          	addi	a0,s0,-1088
     ca0:	b60ff0ef          	jal	0 <append_str>
     ca4:	01448613          	addi	a2,s1,20
     ca8:	bbc40593          	addi	a1,s0,-1092
     cac:	bc040513          	addi	a0,s0,-1088
     cb0:	b50ff0ef          	jal	0 <append_str>
     cb4:	00001617          	auipc	a2,0x1
     cb8:	c4c60613          	addi	a2,a2,-948 # 1900 <malloc+0x104>
     cbc:	bbc40593          	addi	a1,s0,-1092
     cc0:	bc040513          	addi	a0,s0,-1088
     cc4:	b3cff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"fd\":");
     cc8:	00001617          	auipc	a2,0x1
     ccc:	eb860613          	addi	a2,a2,-328 # 1b80 <malloc+0x384>
     cd0:	bbc40593          	addi	a1,s0,-1092
     cd4:	bc040513          	addi	a0,s0,-1088
     cd8:	b28ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->fd);
     cdc:	1c84a603          	lw	a2,456(s1)
     ce0:	bbc40593          	addi	a1,s0,-1092
     ce4:	bc040513          	addi	a0,s0,-1088
     ce8:	bd0ff0ef          	jal	b8 <append_int>
    append_str(buf,&pos,",\"file_object_id\":");
     cec:	00001617          	auipc	a2,0x1
     cf0:	e9c60613          	addi	a2,a2,-356 # 1b88 <malloc+0x38c>
     cf4:	bbc40593          	addi	a1,s0,-1092
     cf8:	bc040513          	addi	a0,s0,-1088
     cfc:	b04ff0ef          	jal	0 <append_str>
    append_uint64(buf,&pos,e->file_object_id);
     d00:	2804b783          	ld	a5,640(s1)
    if(x==0){
     d04:	b9840813          	addi	a6,s0,-1128
     d08:	8742                	mv	a4,a6
        tmp[n++]='0'+(x%10);
     d0a:	4629                	li	a2,10
    while(x){
     d0c:	4525                	li	a0,9
    if(x==0){
     d0e:	2c078c63          	beqz	a5,fe6 <print_fs_event+0xe68>
        tmp[n++]='0'+(x%10);
     d12:	02c7f6b3          	remu	a3,a5,a2
     d16:	0306869b          	addiw	a3,a3,48
     d1a:	00d70023          	sb	a3,0(a4)
        x/=10;
     d1e:	85be                	mv	a1,a5
     d20:	02c7d7b3          	divu	a5,a5,a2
    while(x){
     d24:	86ba                	mv	a3,a4
     d26:	0705                	addi	a4,a4,1
     d28:	feb565e3          	bltu	a0,a1,d12 <print_fs_event+0xb94>
     d2c:	4106863b          	subw	a2,a3,a6
     d30:	2605                	addiw	a2,a2,1
        tmp[n++]='0'+(x%10);
     d32:	0006069b          	sext.w	a3,a2
    while(n)
     d36:	ca85                	beqz	a3,d66 <print_fs_event+0xbe8>
     d38:	bbc42703          	lw	a4,-1092(s0)
     d3c:	bc040793          	addi	a5,s0,-1088
     d40:	97ba                	add	a5,a5,a4
     d42:	b9840593          	addi	a1,s0,-1128
     d46:	96ae                	add	a3,a3,a1
     d48:	9e39                	addw	a2,a2,a4
        buf[(*pos)++]=tmp[--n];
     d4a:	0017051b          	addiw	a0,a4,1
     d4e:	0005071b          	sext.w	a4,a0
     d52:	fff6c583          	lbu	a1,-1(a3)
     d56:	00b78023          	sb	a1,0(a5)
    while(n)
     d5a:	0785                	addi	a5,a5,1
     d5c:	16fd                	addi	a3,a3,-1
     d5e:	fec716e3          	bne	a4,a2,d4a <print_fs_event+0xbcc>
     d62:	baa42e23          	sw	a0,-1092(s0)
    append_str(buf, &pos, ",\"file_type\":\"");
     d66:	00001617          	auipc	a2,0x1
     d6a:	e3a60613          	addi	a2,a2,-454 # 1ba0 <malloc+0x3a4>
     d6e:	bbc40593          	addi	a1,s0,-1092
     d72:	bc040513          	addi	a0,s0,-1088
     d76:	a8aff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->file_type_str);
     d7a:	1d048613          	addi	a2,s1,464
     d7e:	bbc40593          	addi	a1,s0,-1092
     d82:	bc040513          	addi	a0,s0,-1088
     d86:	a7aff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     d8a:	00001617          	auipc	a2,0x1
     d8e:	b7660613          	addi	a2,a2,-1162 # 1900 <malloc+0x104>
     d92:	bbc40593          	addi	a1,s0,-1092
     d96:	bc040513          	addi	a0,s0,-1088
     d9a:	a66ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"path\":\"");
     d9e:	00001617          	auipc	a2,0x1
     da2:	db260613          	addi	a2,a2,-590 # 1b50 <malloc+0x354>
     da6:	bbc40593          	addi	a1,s0,-1092
     daa:	bc040513          	addi	a0,s0,-1088
     dae:	a52ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, e->path);
     db2:	12848613          	addi	a2,s1,296
     db6:	bbc40593          	addi	a1,s0,-1092
     dba:	bc040513          	addi	a0,s0,-1088
     dbe:	a42ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"");
     dc2:	00001617          	auipc	a2,0x1
     dc6:	b3e60613          	addi	a2,a2,-1218 # 1900 <malloc+0x104>
     dca:	bbc40593          	addi	a1,s0,-1092
     dce:	bc040513          	addi	a0,s0,-1088
     dd2:	a2eff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"inum\":");
     dd6:	00001617          	auipc	a2,0x1
     dda:	dda60613          	addi	a2,a2,-550 # 1bb0 <malloc+0x3b4>
     dde:	bbc40593          	addi	a1,s0,-1092
     de2:	bc040513          	addi	a0,s0,-1088
     de6:	a1aff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->inum);
     dea:	4cf0                	lw	a2,92(s1)
     dec:	bbc40593          	addi	a1,s0,-1092
     df0:	bc040513          	addi	a0,s0,-1088
     df4:	ac4ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"state\":{");
     df8:	00001617          	auipc	a2,0x1
     dfc:	bd060613          	addi	a2,a2,-1072 # 19c8 <malloc+0x1cc>
     e00:	bbc40593          	addi	a1,s0,-1092
     e04:	bc040513          	addi	a0,s0,-1088
     e08:	9f8ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, "\"ref\":");
     e0c:	00001617          	auipc	a2,0x1
     e10:	bcc60613          	addi	a2,a2,-1076 # 19d8 <malloc+0x1dc>
     e14:	bbc40593          	addi	a1,s0,-1092
     e18:	bc040513          	addi	a0,s0,-1088
     e1c:	9e4ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->file_ref);
     e20:	1e84a983          	lw	s3,488(s1)
     e24:	864e                	mv	a2,s3
     e26:	bbc40593          	addi	a1,s0,-1092
     e2a:	bc040513          	addi	a0,s0,-1088
     e2e:	a8aff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"offset\":");
     e32:	00001617          	auipc	a2,0x1
     e36:	cd660613          	addi	a2,a2,-810 # 1b08 <malloc+0x30c>
     e3a:	bbc40593          	addi	a1,s0,-1092
     e3e:	bc040513          	addi	a0,s0,-1088
     e42:	9beff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->file_off);
     e46:	1f04a903          	lw	s2,496(s1)
     e4a:	864a                	mv	a2,s2
     e4c:	bbc40593          	addi	a1,s0,-1092
     e50:	bc040513          	addi	a0,s0,-1088
     e54:	a64ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"readable\":");
     e58:	00001617          	auipc	a2,0x1
     e5c:	d6860613          	addi	a2,a2,-664 # 1bc0 <malloc+0x3c4>
     e60:	bbc40593          	addi	a1,s0,-1092
     e64:	bc040513          	addi	a0,s0,-1088
     e68:	998ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->readable);
     e6c:	1e04a603          	lw	a2,480(s1)
     e70:	bbc40593          	addi	a1,s0,-1092
     e74:	bc040513          	addi	a0,s0,-1088
     e78:	a40ff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, ",\"writable\":");
     e7c:	00001617          	auipc	a2,0x1
     e80:	d5460613          	addi	a2,a2,-684 # 1bd0 <malloc+0x3d4>
     e84:	bbc40593          	addi	a1,s0,-1092
     e88:	bc040513          	addi	a0,s0,-1088
     e8c:	974ff0ef          	jal	0 <append_str>
    append_int(buf, &pos, e->writable);
     e90:	1e44a603          	lw	a2,484(s1)
     e94:	bbc40593          	addi	a1,s0,-1092
     e98:	bc040513          	addi	a0,s0,-1088
     e9c:	a1cff0ef          	jal	b8 <append_int>
    append_str(buf, &pos, "}");
     ea0:	00001617          	auipc	a2,0x1
     ea4:	b2060613          	addi	a2,a2,-1248 # 19c0 <malloc+0x1c4>
     ea8:	bbc40593          	addi	a1,s0,-1092
     eac:	bc040513          	addi	a0,s0,-1088
     eb0:	950ff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"changes\":{");
     eb4:	00001617          	auipc	a2,0x1
     eb8:	b3c60613          	addi	a2,a2,-1220 # 19f0 <malloc+0x1f4>
     ebc:	bbc40593          	addi	a1,s0,-1092
     ec0:	bc040513          	addi	a0,s0,-1088
     ec4:	93cff0ef          	jal	0 <append_str>
    print_change(buf, &pos,
     ec8:	874e                	mv	a4,s3
     eca:	1ec4a683          	lw	a3,492(s1)
     ece:	00001617          	auipc	a2,0x1
     ed2:	b3260613          	addi	a2,a2,-1230 # 1a00 <malloc+0x204>
     ed6:	bbc40593          	addi	a1,s0,-1092
     eda:	bc040513          	addi	a0,s0,-1088
     ede:	a12ff0ef          	jal	f0 <print_change>
    print_change(buf, &pos,
     ee2:	874a                	mv	a4,s2
     ee4:	1f44a683          	lw	a3,500(s1)
     ee8:	00001617          	auipc	a2,0x1
     eec:	cf860613          	addi	a2,a2,-776 # 1be0 <malloc+0x3e4>
     ef0:	bbc40593          	addi	a1,s0,-1092
     ef4:	bc040513          	addi	a0,s0,-1088
     ef8:	9f8ff0ef          	jal	f0 <print_change>
    if(buf[pos-1] == ',')
     efc:	bbc42783          	lw	a5,-1092(s0)
     f00:	37fd                	addiw	a5,a5,-1
     f02:	0007871b          	sext.w	a4,a5
     f06:	fc070713          	addi	a4,a4,-64
     f0a:	9722                	add	a4,a4,s0
     f0c:	c0074683          	lbu	a3,-1024(a4)
     f10:	02c00713          	li	a4,44
     f14:	0ee68763          	beq	a3,a4,1002 <print_fs_event+0xe84>
    append_str(buf, &pos, "}");
     f18:	00001617          	auipc	a2,0x1
     f1c:	aa860613          	addi	a2,a2,-1368 # 19c0 <malloc+0x1c4>
     f20:	bbc40593          	addi	a1,s0,-1092
     f24:	bc040513          	addi	a0,s0,-1088
     f28:	8d8ff0ef          	jal	0 <append_str>
     f2c:	44813983          	ld	s3,1096(sp)
     f30:	ce8ff06f          	j	418 <print_fs_event+0x29a>
    append_str(buf, &pos, "\"");
     f34:	00001617          	auipc	a2,0x1
     f38:	9cc60613          	addi	a2,a2,-1588 # 1900 <malloc+0x104>
     f3c:	bbc40593          	addi	a1,s0,-1092
     f40:	bc040513          	addi	a0,s0,-1088
     f44:	8bcff0ef          	jal	0 <append_str>
    append_str(buf, &pos, ",\"op\":\""); append_str(buf, &pos, e->op_name); append_str(buf, &pos, "\"");
     f48:	00001617          	auipc	a2,0x1
     f4c:	a1860613          	addi	a2,a2,-1512 # 1960 <malloc+0x164>
     f50:	bbc40593          	addi	a1,s0,-1092
     f54:	bc040513          	addi	a0,s0,-1088
     f58:	8a8ff0ef          	jal	0 <append_str>
     f5c:	01448613          	addi	a2,s1,20
     f60:	bbc40593          	addi	a1,s0,-1092
     f64:	bc040513          	addi	a0,s0,-1088
     f68:	898ff0ef          	jal	0 <append_str>
     f6c:	00001617          	auipc	a2,0x1
     f70:	99460613          	addi	a2,a2,-1644 # 1900 <malloc+0x104>
     f74:	bbc40593          	addi	a1,s0,-1092
     f78:	bc040513          	addi	a0,s0,-1088
     f7c:	884ff0ef          	jal	0 <append_str>
    if(e->type == LAYER_BCACHE){
     f80:	479d                	li	a5,7
     f82:	c927eb63          	bltu	a5,s2,418 <print_fs_event+0x29a>
     f86:	090a                	slli	s2,s2,0x2
     f88:	00001717          	auipc	a4,0x1
     f8c:	ce870713          	addi	a4,a4,-792 # 1c70 <malloc+0x474>
     f90:	993a                	add	s2,s2,a4
     f92:	00092783          	lw	a5,0(s2)
     f96:	97ba                	add	a5,a5,a4
     f98:	8782                	jr	a5
     f9a:	45313423          	sd	s3,1096(sp)
     f9e:	b22ff06f          	j	2c0 <print_fs_event+0x142>
        if(buf[pos-1] == ',') pos--; // remove last comma
     fa2:	baf42e23          	sw	a5,-1092(s0)
     fa6:	c5aff06f          	j	400 <print_fs_event+0x282>
     faa:	45313423          	sd	s3,1096(sp)
     fae:	45413023          	sd	s4,1088(sp)
     fb2:	d3eff06f          	j	4f0 <print_fs_event+0x372>
        if(buf[pos-1] == ',') pos--;
     fb6:	baf42e23          	sw	a5,-1092(s0)
     fba:	e48ff06f          	j	602 <print_fs_event+0x484>
    if(buf[pos-1] == ',') pos--;
     fbe:	baf42e23          	sw	a5,-1092(s0)
     fc2:	f76ff06f          	j	738 <print_fs_event+0x5ba>
     fc6:	45313423          	sd	s3,1096(sp)
     fca:	45413023          	sd	s4,1088(sp)
     fce:	43513c23          	sd	s5,1080(sp)
     fd2:	43613823          	sd	s6,1072(sp)
     fd6:	fe8ff06f          	j	7be <print_fs_event+0x640>
    if(buf[pos-1] == ',') pos--;
     fda:	baf42e23          	sw	a5,-1092(s0)
     fde:	ba6d                	j	998 <print_fs_event+0x81a>
     fe0:	45313423          	sd	s3,1096(sp)
     fe4:	b1d5                	j	cc8 <print_fs_event+0xb4a>
        buf[(*pos)++]='0';
     fe6:	bbc42783          	lw	a5,-1092(s0)
     fea:	0017871b          	addiw	a4,a5,1
     fee:	bae42e23          	sw	a4,-1092(s0)
     ff2:	fc078793          	addi	a5,a5,-64
     ff6:	97a2                	add	a5,a5,s0
     ff8:	03000713          	li	a4,48
     ffc:	c0e78023          	sb	a4,-1024(a5)
        return;
    1000:	b39d                	j	d66 <print_fs_event+0xbe8>
        pos--;
    1002:	baf42e23          	sw	a5,-1092(s0)
    1006:	bf09                	j	f18 <print_fs_event+0xd9a>

0000000000001008 <main>:

int main(void) {
    1008:	7179                	addi	sp,sp,-48
    100a:	f406                	sd	ra,40(sp)
    100c:	f022                	sd	s0,32(sp)
    100e:	ec26                	sd	s1,24(sp)
    1010:	e84a                	sd	s2,16(sp)
    1012:	e44e                	sd	s3,8(sp)
    1014:	e052                	sd	s4,0(sp)
    1016:	1800                	addi	s0,sp,48
    printf("FS Buffer Cache Export starting...\n");
    1018:	00001517          	auipc	a0,0x1
    101c:	be850513          	addi	a0,a0,-1048 # 1c00 <malloc+0x404>
    1020:	728000ef          	jal	1748 <printf>
    
    while (1) {
        int n_fs = fsread(fs_ev, 16);
    1024:	00001997          	auipc	s3,0x1
    1028:	fec98993          	addi	s3,s3,-20 # 2010 <fs_ev>
    102c:	31000a13          	li	s4,784
    1030:	a831                	j	104c <main+0x44>
        if (n_fs < 0) {
            fprintf(2, "fsexport: error reading fslog\n");
    1032:	00001597          	auipc	a1,0x1
    1036:	bf658593          	addi	a1,a1,-1034 # 1c28 <malloc+0x42c>
    103a:	4509                	li	a0,2
    103c:	6e2000ef          	jal	171e <fprintf>
            exit(1);
    1040:	4505                	li	a0,1
    1042:	2ce000ef          	jal	1310 <exit>
        for (int i = 0; i < n_fs; i++) {
            print_fs_event(&fs_ev[i]);
        }

        // استخدام sleep(2) بدلاً من pause في xv6 لضمان استمرار الحلقة
        pause(2); 
    1046:	4509                	li	a0,2
    1048:	358000ef          	jal	13a0 <pause>
        int n_fs = fsread(fs_ev, 16);
    104c:	45c1                	li	a1,16
    104e:	854e                	mv	a0,s3
    1050:	368000ef          	jal	13b8 <fsread>
        if (n_fs < 0) {
    1054:	fc054fe3          	bltz	a0,1032 <main+0x2a>
        for (int i = 0; i < n_fs; i++) {
    1058:	fea057e3          	blez	a0,1046 <main+0x3e>
    105c:	00001497          	auipc	s1,0x1
    1060:	fb448493          	addi	s1,s1,-76 # 2010 <fs_ev>
    1064:	03450533          	mul	a0,a0,s4
    1068:	00950933          	add	s2,a0,s1
            print_fs_event(&fs_ev[i]);
    106c:	8526                	mv	a0,s1
    106e:	910ff0ef          	jal	17e <print_fs_event>
        for (int i = 0; i < n_fs; i++) {
    1072:	31048493          	addi	s1,s1,784
    1076:	ff249be3          	bne	s1,s2,106c <main+0x64>
    107a:	b7f1                	j	1046 <main+0x3e>

000000000000107c <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
    107c:	1141                	addi	sp,sp,-16
    107e:	e406                	sd	ra,8(sp)
    1080:	e022                	sd	s0,0(sp)
    1082:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
    1084:	f85ff0ef          	jal	1008 <main>
  exit(r);
    1088:	288000ef          	jal	1310 <exit>

000000000000108c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
    108c:	1141                	addi	sp,sp,-16
    108e:	e422                	sd	s0,8(sp)
    1090:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
    1092:	87aa                	mv	a5,a0
    1094:	0585                	addi	a1,a1,1
    1096:	0785                	addi	a5,a5,1
    1098:	fff5c703          	lbu	a4,-1(a1)
    109c:	fee78fa3          	sb	a4,-1(a5)
    10a0:	fb75                	bnez	a4,1094 <strcpy+0x8>
    ;
  return os;
}
    10a2:	6422                	ld	s0,8(sp)
    10a4:	0141                	addi	sp,sp,16
    10a6:	8082                	ret

00000000000010a8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
    10a8:	1141                	addi	sp,sp,-16
    10aa:	e422                	sd	s0,8(sp)
    10ac:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
    10ae:	00054783          	lbu	a5,0(a0)
    10b2:	cb91                	beqz	a5,10c6 <strcmp+0x1e>
    10b4:	0005c703          	lbu	a4,0(a1)
    10b8:	00f71763          	bne	a4,a5,10c6 <strcmp+0x1e>
    p++, q++;
    10bc:	0505                	addi	a0,a0,1
    10be:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
    10c0:	00054783          	lbu	a5,0(a0)
    10c4:	fbe5                	bnez	a5,10b4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
    10c6:	0005c503          	lbu	a0,0(a1)
}
    10ca:	40a7853b          	subw	a0,a5,a0
    10ce:	6422                	ld	s0,8(sp)
    10d0:	0141                	addi	sp,sp,16
    10d2:	8082                	ret

00000000000010d4 <strlen>:

uint
strlen(const char *s)
{
    10d4:	1141                	addi	sp,sp,-16
    10d6:	e422                	sd	s0,8(sp)
    10d8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    10da:	00054783          	lbu	a5,0(a0)
    10de:	cf91                	beqz	a5,10fa <strlen+0x26>
    10e0:	0505                	addi	a0,a0,1
    10e2:	87aa                	mv	a5,a0
    10e4:	86be                	mv	a3,a5
    10e6:	0785                	addi	a5,a5,1
    10e8:	fff7c703          	lbu	a4,-1(a5)
    10ec:	ff65                	bnez	a4,10e4 <strlen+0x10>
    10ee:	40a6853b          	subw	a0,a3,a0
    10f2:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    10f4:	6422                	ld	s0,8(sp)
    10f6:	0141                	addi	sp,sp,16
    10f8:	8082                	ret
  for(n = 0; s[n]; n++)
    10fa:	4501                	li	a0,0
    10fc:	bfe5                	j	10f4 <strlen+0x20>

00000000000010fe <memset>:

void*
memset(void *dst, int c, uint n)
{
    10fe:	1141                	addi	sp,sp,-16
    1100:	e422                	sd	s0,8(sp)
    1102:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    1104:	ca19                	beqz	a2,111a <memset+0x1c>
    1106:	87aa                	mv	a5,a0
    1108:	1602                	slli	a2,a2,0x20
    110a:	9201                	srli	a2,a2,0x20
    110c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    1110:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    1114:	0785                	addi	a5,a5,1
    1116:	fee79de3          	bne	a5,a4,1110 <memset+0x12>
  }
  return dst;
}
    111a:	6422                	ld	s0,8(sp)
    111c:	0141                	addi	sp,sp,16
    111e:	8082                	ret

0000000000001120 <strchr>:

char*
strchr(const char *s, char c)
{
    1120:	1141                	addi	sp,sp,-16
    1122:	e422                	sd	s0,8(sp)
    1124:	0800                	addi	s0,sp,16
  for(; *s; s++)
    1126:	00054783          	lbu	a5,0(a0)
    112a:	cb99                	beqz	a5,1140 <strchr+0x20>
    if(*s == c)
    112c:	00f58763          	beq	a1,a5,113a <strchr+0x1a>
  for(; *s; s++)
    1130:	0505                	addi	a0,a0,1
    1132:	00054783          	lbu	a5,0(a0)
    1136:	fbfd                	bnez	a5,112c <strchr+0xc>
      return (char*)s;
  return 0;
    1138:	4501                	li	a0,0
}
    113a:	6422                	ld	s0,8(sp)
    113c:	0141                	addi	sp,sp,16
    113e:	8082                	ret
  return 0;
    1140:	4501                	li	a0,0
    1142:	bfe5                	j	113a <strchr+0x1a>

0000000000001144 <gets>:

char*
gets(char *buf, int max)
{
    1144:	711d                	addi	sp,sp,-96
    1146:	ec86                	sd	ra,88(sp)
    1148:	e8a2                	sd	s0,80(sp)
    114a:	e4a6                	sd	s1,72(sp)
    114c:	e0ca                	sd	s2,64(sp)
    114e:	fc4e                	sd	s3,56(sp)
    1150:	f852                	sd	s4,48(sp)
    1152:	f456                	sd	s5,40(sp)
    1154:	f05a                	sd	s6,32(sp)
    1156:	ec5e                	sd	s7,24(sp)
    1158:	1080                	addi	s0,sp,96
    115a:	8baa                	mv	s7,a0
    115c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
    115e:	892a                	mv	s2,a0
    1160:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
    1162:	4aa9                	li	s5,10
    1164:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
    1166:	89a6                	mv	s3,s1
    1168:	2485                	addiw	s1,s1,1
    116a:	0344d663          	bge	s1,s4,1196 <gets+0x52>
    cc = read(0, &c, 1);
    116e:	4605                	li	a2,1
    1170:	faf40593          	addi	a1,s0,-81
    1174:	4501                	li	a0,0
    1176:	1b2000ef          	jal	1328 <read>
    if(cc < 1)
    117a:	00a05e63          	blez	a0,1196 <gets+0x52>
    buf[i++] = c;
    117e:	faf44783          	lbu	a5,-81(s0)
    1182:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
    1186:	01578763          	beq	a5,s5,1194 <gets+0x50>
    118a:	0905                	addi	s2,s2,1
    118c:	fd679de3          	bne	a5,s6,1166 <gets+0x22>
    buf[i++] = c;
    1190:	89a6                	mv	s3,s1
    1192:	a011                	j	1196 <gets+0x52>
    1194:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
    1196:	99de                	add	s3,s3,s7
    1198:	00098023          	sb	zero,0(s3)
  return buf;
}
    119c:	855e                	mv	a0,s7
    119e:	60e6                	ld	ra,88(sp)
    11a0:	6446                	ld	s0,80(sp)
    11a2:	64a6                	ld	s1,72(sp)
    11a4:	6906                	ld	s2,64(sp)
    11a6:	79e2                	ld	s3,56(sp)
    11a8:	7a42                	ld	s4,48(sp)
    11aa:	7aa2                	ld	s5,40(sp)
    11ac:	7b02                	ld	s6,32(sp)
    11ae:	6be2                	ld	s7,24(sp)
    11b0:	6125                	addi	sp,sp,96
    11b2:	8082                	ret

00000000000011b4 <stat>:

int
stat(const char *n, struct stat *st)
{
    11b4:	1101                	addi	sp,sp,-32
    11b6:	ec06                	sd	ra,24(sp)
    11b8:	e822                	sd	s0,16(sp)
    11ba:	e04a                	sd	s2,0(sp)
    11bc:	1000                	addi	s0,sp,32
    11be:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
    11c0:	4581                	li	a1,0
    11c2:	18e000ef          	jal	1350 <open>
  if(fd < 0)
    11c6:	02054263          	bltz	a0,11ea <stat+0x36>
    11ca:	e426                	sd	s1,8(sp)
    11cc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
    11ce:	85ca                	mv	a1,s2
    11d0:	198000ef          	jal	1368 <fstat>
    11d4:	892a                	mv	s2,a0
  close(fd);
    11d6:	8526                	mv	a0,s1
    11d8:	160000ef          	jal	1338 <close>
  return r;
    11dc:	64a2                	ld	s1,8(sp)
}
    11de:	854a                	mv	a0,s2
    11e0:	60e2                	ld	ra,24(sp)
    11e2:	6442                	ld	s0,16(sp)
    11e4:	6902                	ld	s2,0(sp)
    11e6:	6105                	addi	sp,sp,32
    11e8:	8082                	ret
    return -1;
    11ea:	597d                	li	s2,-1
    11ec:	bfcd                	j	11de <stat+0x2a>

00000000000011ee <atoi>:

int
atoi(const char *s)
{
    11ee:	1141                	addi	sp,sp,-16
    11f0:	e422                	sd	s0,8(sp)
    11f2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
    11f4:	00054683          	lbu	a3,0(a0)
    11f8:	fd06879b          	addiw	a5,a3,-48
    11fc:	0ff7f793          	zext.b	a5,a5
    1200:	4625                	li	a2,9
    1202:	02f66863          	bltu	a2,a5,1232 <atoi+0x44>
    1206:	872a                	mv	a4,a0
  n = 0;
    1208:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
    120a:	0705                	addi	a4,a4,1
    120c:	0025179b          	slliw	a5,a0,0x2
    1210:	9fa9                	addw	a5,a5,a0
    1212:	0017979b          	slliw	a5,a5,0x1
    1216:	9fb5                	addw	a5,a5,a3
    1218:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
    121c:	00074683          	lbu	a3,0(a4)
    1220:	fd06879b          	addiw	a5,a3,-48
    1224:	0ff7f793          	zext.b	a5,a5
    1228:	fef671e3          	bgeu	a2,a5,120a <atoi+0x1c>
  return n;
}
    122c:	6422                	ld	s0,8(sp)
    122e:	0141                	addi	sp,sp,16
    1230:	8082                	ret
  n = 0;
    1232:	4501                	li	a0,0
    1234:	bfe5                	j	122c <atoi+0x3e>

0000000000001236 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
    1236:	1141                	addi	sp,sp,-16
    1238:	e422                	sd	s0,8(sp)
    123a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
    123c:	02b57463          	bgeu	a0,a1,1264 <memmove+0x2e>
    while(n-- > 0)
    1240:	00c05f63          	blez	a2,125e <memmove+0x28>
    1244:	1602                	slli	a2,a2,0x20
    1246:	9201                	srli	a2,a2,0x20
    1248:	00c507b3          	add	a5,a0,a2
  dst = vdst;
    124c:	872a                	mv	a4,a0
      *dst++ = *src++;
    124e:	0585                	addi	a1,a1,1
    1250:	0705                	addi	a4,a4,1
    1252:	fff5c683          	lbu	a3,-1(a1)
    1256:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    125a:	fef71ae3          	bne	a4,a5,124e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
    125e:	6422                	ld	s0,8(sp)
    1260:	0141                	addi	sp,sp,16
    1262:	8082                	ret
    dst += n;
    1264:	00c50733          	add	a4,a0,a2
    src += n;
    1268:	95b2                	add	a1,a1,a2
    while(n-- > 0)
    126a:	fec05ae3          	blez	a2,125e <memmove+0x28>
    126e:	fff6079b          	addiw	a5,a2,-1
    1272:	1782                	slli	a5,a5,0x20
    1274:	9381                	srli	a5,a5,0x20
    1276:	fff7c793          	not	a5,a5
    127a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
    127c:	15fd                	addi	a1,a1,-1
    127e:	177d                	addi	a4,a4,-1
    1280:	0005c683          	lbu	a3,0(a1)
    1284:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    1288:	fee79ae3          	bne	a5,a4,127c <memmove+0x46>
    128c:	bfc9                	j	125e <memmove+0x28>

000000000000128e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
    128e:	1141                	addi	sp,sp,-16
    1290:	e422                	sd	s0,8(sp)
    1292:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
    1294:	ca05                	beqz	a2,12c4 <memcmp+0x36>
    1296:	fff6069b          	addiw	a3,a2,-1
    129a:	1682                	slli	a3,a3,0x20
    129c:	9281                	srli	a3,a3,0x20
    129e:	0685                	addi	a3,a3,1
    12a0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
    12a2:	00054783          	lbu	a5,0(a0)
    12a6:	0005c703          	lbu	a4,0(a1)
    12aa:	00e79863          	bne	a5,a4,12ba <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
    12ae:	0505                	addi	a0,a0,1
    p2++;
    12b0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
    12b2:	fed518e3          	bne	a0,a3,12a2 <memcmp+0x14>
  }
  return 0;
    12b6:	4501                	li	a0,0
    12b8:	a019                	j	12be <memcmp+0x30>
      return *p1 - *p2;
    12ba:	40e7853b          	subw	a0,a5,a4
}
    12be:	6422                	ld	s0,8(sp)
    12c0:	0141                	addi	sp,sp,16
    12c2:	8082                	ret
  return 0;
    12c4:	4501                	li	a0,0
    12c6:	bfe5                	j	12be <memcmp+0x30>

00000000000012c8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
    12c8:	1141                	addi	sp,sp,-16
    12ca:	e406                	sd	ra,8(sp)
    12cc:	e022                	sd	s0,0(sp)
    12ce:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    12d0:	f67ff0ef          	jal	1236 <memmove>
}
    12d4:	60a2                	ld	ra,8(sp)
    12d6:	6402                	ld	s0,0(sp)
    12d8:	0141                	addi	sp,sp,16
    12da:	8082                	ret

00000000000012dc <sbrk>:

char *
sbrk(int n) {
    12dc:	1141                	addi	sp,sp,-16
    12de:	e406                	sd	ra,8(sp)
    12e0:	e022                	sd	s0,0(sp)
    12e2:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
    12e4:	4585                	li	a1,1
    12e6:	0b2000ef          	jal	1398 <sys_sbrk>
}
    12ea:	60a2                	ld	ra,8(sp)
    12ec:	6402                	ld	s0,0(sp)
    12ee:	0141                	addi	sp,sp,16
    12f0:	8082                	ret

00000000000012f2 <sbrklazy>:

char *
sbrklazy(int n) {
    12f2:	1141                	addi	sp,sp,-16
    12f4:	e406                	sd	ra,8(sp)
    12f6:	e022                	sd	s0,0(sp)
    12f8:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
    12fa:	4589                	li	a1,2
    12fc:	09c000ef          	jal	1398 <sys_sbrk>
}
    1300:	60a2                	ld	ra,8(sp)
    1302:	6402                	ld	s0,0(sp)
    1304:	0141                	addi	sp,sp,16
    1306:	8082                	ret

0000000000001308 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
    1308:	4885                	li	a7,1
 ecall
    130a:	00000073          	ecall
 ret
    130e:	8082                	ret

0000000000001310 <exit>:
.global exit
exit:
 li a7, SYS_exit
    1310:	4889                	li	a7,2
 ecall
    1312:	00000073          	ecall
 ret
    1316:	8082                	ret

0000000000001318 <wait>:
.global wait
wait:
 li a7, SYS_wait
    1318:	488d                	li	a7,3
 ecall
    131a:	00000073          	ecall
 ret
    131e:	8082                	ret

0000000000001320 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
    1320:	4891                	li	a7,4
 ecall
    1322:	00000073          	ecall
 ret
    1326:	8082                	ret

0000000000001328 <read>:
.global read
read:
 li a7, SYS_read
    1328:	4895                	li	a7,5
 ecall
    132a:	00000073          	ecall
 ret
    132e:	8082                	ret

0000000000001330 <write>:
.global write
write:
 li a7, SYS_write
    1330:	48c1                	li	a7,16
 ecall
    1332:	00000073          	ecall
 ret
    1336:	8082                	ret

0000000000001338 <close>:
.global close
close:
 li a7, SYS_close
    1338:	48d5                	li	a7,21
 ecall
    133a:	00000073          	ecall
 ret
    133e:	8082                	ret

0000000000001340 <kill>:
.global kill
kill:
 li a7, SYS_kill
    1340:	4899                	li	a7,6
 ecall
    1342:	00000073          	ecall
 ret
    1346:	8082                	ret

0000000000001348 <exec>:
.global exec
exec:
 li a7, SYS_exec
    1348:	489d                	li	a7,7
 ecall
    134a:	00000073          	ecall
 ret
    134e:	8082                	ret

0000000000001350 <open>:
.global open
open:
 li a7, SYS_open
    1350:	48bd                	li	a7,15
 ecall
    1352:	00000073          	ecall
 ret
    1356:	8082                	ret

0000000000001358 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
    1358:	48c5                	li	a7,17
 ecall
    135a:	00000073          	ecall
 ret
    135e:	8082                	ret

0000000000001360 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
    1360:	48c9                	li	a7,18
 ecall
    1362:	00000073          	ecall
 ret
    1366:	8082                	ret

0000000000001368 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
    1368:	48a1                	li	a7,8
 ecall
    136a:	00000073          	ecall
 ret
    136e:	8082                	ret

0000000000001370 <link>:
.global link
link:
 li a7, SYS_link
    1370:	48cd                	li	a7,19
 ecall
    1372:	00000073          	ecall
 ret
    1376:	8082                	ret

0000000000001378 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
    1378:	48d1                	li	a7,20
 ecall
    137a:	00000073          	ecall
 ret
    137e:	8082                	ret

0000000000001380 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
    1380:	48a5                	li	a7,9
 ecall
    1382:	00000073          	ecall
 ret
    1386:	8082                	ret

0000000000001388 <dup>:
.global dup
dup:
 li a7, SYS_dup
    1388:	48a9                	li	a7,10
 ecall
    138a:	00000073          	ecall
 ret
    138e:	8082                	ret

0000000000001390 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
    1390:	48ad                	li	a7,11
 ecall
    1392:	00000073          	ecall
 ret
    1396:	8082                	ret

0000000000001398 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
    1398:	48b1                	li	a7,12
 ecall
    139a:	00000073          	ecall
 ret
    139e:	8082                	ret

00000000000013a0 <pause>:
.global pause
pause:
 li a7, SYS_pause
    13a0:	48b5                	li	a7,13
 ecall
    13a2:	00000073          	ecall
 ret
    13a6:	8082                	ret

00000000000013a8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
    13a8:	48b9                	li	a7,14
 ecall
    13aa:	00000073          	ecall
 ret
    13ae:	8082                	ret

00000000000013b0 <csread>:
.global csread
csread:
 li a7, SYS_csread
    13b0:	48d9                	li	a7,22
 ecall
    13b2:	00000073          	ecall
 ret
    13b6:	8082                	ret

00000000000013b8 <fsread>:
.global fsread
fsread:
 li a7, SYS_fsread
    13b8:	48dd                	li	a7,23
 ecall
    13ba:	00000073          	ecall
 ret
    13be:	8082                	ret

00000000000013c0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
    13c0:	1101                	addi	sp,sp,-32
    13c2:	ec06                	sd	ra,24(sp)
    13c4:	e822                	sd	s0,16(sp)
    13c6:	1000                	addi	s0,sp,32
    13c8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
    13cc:	4605                	li	a2,1
    13ce:	fef40593          	addi	a1,s0,-17
    13d2:	f5fff0ef          	jal	1330 <write>
}
    13d6:	60e2                	ld	ra,24(sp)
    13d8:	6442                	ld	s0,16(sp)
    13da:	6105                	addi	sp,sp,32
    13dc:	8082                	ret

00000000000013de <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
    13de:	715d                	addi	sp,sp,-80
    13e0:	e486                	sd	ra,72(sp)
    13e2:	e0a2                	sd	s0,64(sp)
    13e4:	f84a                	sd	s2,48(sp)
    13e6:	0880                	addi	s0,sp,80
    13e8:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
    13ea:	c299                	beqz	a3,13f0 <printint+0x12>
    13ec:	0805c363          	bltz	a1,1472 <printint+0x94>
  neg = 0;
    13f0:	4881                	li	a7,0
    13f2:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
    13f6:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
    13f8:	00001517          	auipc	a0,0x1
    13fc:	89850513          	addi	a0,a0,-1896 # 1c90 <digits>
    1400:	883e                	mv	a6,a5
    1402:	2785                	addiw	a5,a5,1
    1404:	02c5f733          	remu	a4,a1,a2
    1408:	972a                	add	a4,a4,a0
    140a:	00074703          	lbu	a4,0(a4)
    140e:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
    1412:	872e                	mv	a4,a1
    1414:	02c5d5b3          	divu	a1,a1,a2
    1418:	0685                	addi	a3,a3,1
    141a:	fec773e3          	bgeu	a4,a2,1400 <printint+0x22>
  if(neg)
    141e:	00088b63          	beqz	a7,1434 <printint+0x56>
    buf[i++] = '-';
    1422:	fd078793          	addi	a5,a5,-48
    1426:	97a2                	add	a5,a5,s0
    1428:	02d00713          	li	a4,45
    142c:	fee78423          	sb	a4,-24(a5)
    1430:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    1434:	02f05a63          	blez	a5,1468 <printint+0x8a>
    1438:	fc26                	sd	s1,56(sp)
    143a:	f44e                	sd	s3,40(sp)
    143c:	fb840713          	addi	a4,s0,-72
    1440:	00f704b3          	add	s1,a4,a5
    1444:	fff70993          	addi	s3,a4,-1
    1448:	99be                	add	s3,s3,a5
    144a:	37fd                	addiw	a5,a5,-1
    144c:	1782                	slli	a5,a5,0x20
    144e:	9381                	srli	a5,a5,0x20
    1450:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
    1454:	fff4c583          	lbu	a1,-1(s1)
    1458:	854a                	mv	a0,s2
    145a:	f67ff0ef          	jal	13c0 <putc>
  while(--i >= 0)
    145e:	14fd                	addi	s1,s1,-1
    1460:	ff349ae3          	bne	s1,s3,1454 <printint+0x76>
    1464:	74e2                	ld	s1,56(sp)
    1466:	79a2                	ld	s3,40(sp)
}
    1468:	60a6                	ld	ra,72(sp)
    146a:	6406                	ld	s0,64(sp)
    146c:	7942                	ld	s2,48(sp)
    146e:	6161                	addi	sp,sp,80
    1470:	8082                	ret
    x = -xx;
    1472:	40b005b3          	neg	a1,a1
    neg = 1;
    1476:	4885                	li	a7,1
    x = -xx;
    1478:	bfad                	j	13f2 <printint+0x14>

000000000000147a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    147a:	711d                	addi	sp,sp,-96
    147c:	ec86                	sd	ra,88(sp)
    147e:	e8a2                	sd	s0,80(sp)
    1480:	e0ca                	sd	s2,64(sp)
    1482:	1080                	addi	s0,sp,96
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    1484:	0005c903          	lbu	s2,0(a1)
    1488:	28090663          	beqz	s2,1714 <vprintf+0x29a>
    148c:	e4a6                	sd	s1,72(sp)
    148e:	fc4e                	sd	s3,56(sp)
    1490:	f852                	sd	s4,48(sp)
    1492:	f456                	sd	s5,40(sp)
    1494:	f05a                	sd	s6,32(sp)
    1496:	ec5e                	sd	s7,24(sp)
    1498:	e862                	sd	s8,16(sp)
    149a:	e466                	sd	s9,8(sp)
    149c:	8b2a                	mv	s6,a0
    149e:	8a2e                	mv	s4,a1
    14a0:	8bb2                	mv	s7,a2
  state = 0;
    14a2:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
    14a4:	4481                	li	s1,0
    14a6:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
    14a8:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
    14ac:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
    14b0:	06c00c93          	li	s9,108
    14b4:	a005                	j	14d4 <vprintf+0x5a>
        putc(fd, c0);
    14b6:	85ca                	mv	a1,s2
    14b8:	855a                	mv	a0,s6
    14ba:	f07ff0ef          	jal	13c0 <putc>
    14be:	a019                	j	14c4 <vprintf+0x4a>
    } else if(state == '%'){
    14c0:	03598263          	beq	s3,s5,14e4 <vprintf+0x6a>
  for(i = 0; fmt[i]; i++){
    14c4:	2485                	addiw	s1,s1,1
    14c6:	8726                	mv	a4,s1
    14c8:	009a07b3          	add	a5,s4,s1
    14cc:	0007c903          	lbu	s2,0(a5)
    14d0:	22090a63          	beqz	s2,1704 <vprintf+0x28a>
    c0 = fmt[i] & 0xff;
    14d4:	0009079b          	sext.w	a5,s2
    if(state == 0){
    14d8:	fe0994e3          	bnez	s3,14c0 <vprintf+0x46>
      if(c0 == '%'){
    14dc:	fd579de3          	bne	a5,s5,14b6 <vprintf+0x3c>
        state = '%';
    14e0:	89be                	mv	s3,a5
    14e2:	b7cd                	j	14c4 <vprintf+0x4a>
      if(c0) c1 = fmt[i+1] & 0xff;
    14e4:	00ea06b3          	add	a3,s4,a4
    14e8:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
    14ec:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
    14ee:	c681                	beqz	a3,14f6 <vprintf+0x7c>
    14f0:	9752                	add	a4,a4,s4
    14f2:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
    14f6:	05878363          	beq	a5,s8,153c <vprintf+0xc2>
      } else if(c0 == 'l' && c1 == 'd'){
    14fa:	05978d63          	beq	a5,s9,1554 <vprintf+0xda>
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
    14fe:	07500713          	li	a4,117
    1502:	0ee78763          	beq	a5,a4,15f0 <vprintf+0x176>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
    1506:	07800713          	li	a4,120
    150a:	12e78963          	beq	a5,a4,163c <vprintf+0x1c2>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
    150e:	07000713          	li	a4,112
    1512:	14e78e63          	beq	a5,a4,166e <vprintf+0x1f4>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
    1516:	06300713          	li	a4,99
    151a:	18e78e63          	beq	a5,a4,16b6 <vprintf+0x23c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
    151e:	07300713          	li	a4,115
    1522:	1ae78463          	beq	a5,a4,16ca <vprintf+0x250>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
    1526:	02500713          	li	a4,37
    152a:	04e79563          	bne	a5,a4,1574 <vprintf+0xfa>
        putc(fd, '%');
    152e:	02500593          	li	a1,37
    1532:	855a                	mv	a0,s6
    1534:	e8dff0ef          	jal	13c0 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
    1538:	4981                	li	s3,0
    153a:	b769                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, int), 10, 1);
    153c:	008b8913          	addi	s2,s7,8
    1540:	4685                	li	a3,1
    1542:	4629                	li	a2,10
    1544:	000ba583          	lw	a1,0(s7)
    1548:	855a                	mv	a0,s6
    154a:	e95ff0ef          	jal	13de <printint>
    154e:	8bca                	mv	s7,s2
      state = 0;
    1550:	4981                	li	s3,0
    1552:	bf8d                	j	14c4 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'd'){
    1554:	06400793          	li	a5,100
    1558:	02f68963          	beq	a3,a5,158a <vprintf+0x110>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    155c:	06c00793          	li	a5,108
    1560:	04f68263          	beq	a3,a5,15a4 <vprintf+0x12a>
      } else if(c0 == 'l' && c1 == 'u'){
    1564:	07500793          	li	a5,117
    1568:	0af68063          	beq	a3,a5,1608 <vprintf+0x18e>
      } else if(c0 == 'l' && c1 == 'x'){
    156c:	07800793          	li	a5,120
    1570:	0ef68263          	beq	a3,a5,1654 <vprintf+0x1da>
        putc(fd, '%');
    1574:	02500593          	li	a1,37
    1578:	855a                	mv	a0,s6
    157a:	e47ff0ef          	jal	13c0 <putc>
        putc(fd, c0);
    157e:	85ca                	mv	a1,s2
    1580:	855a                	mv	a0,s6
    1582:	e3fff0ef          	jal	13c0 <putc>
      state = 0;
    1586:	4981                	li	s3,0
    1588:	bf35                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
    158a:	008b8913          	addi	s2,s7,8
    158e:	4685                	li	a3,1
    1590:	4629                	li	a2,10
    1592:	000bb583          	ld	a1,0(s7)
    1596:	855a                	mv	a0,s6
    1598:	e47ff0ef          	jal	13de <printint>
        i += 1;
    159c:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
    159e:	8bca                	mv	s7,s2
      state = 0;
    15a0:	4981                	li	s3,0
        i += 1;
    15a2:	b70d                	j	14c4 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    15a4:	06400793          	li	a5,100
    15a8:	02f60763          	beq	a2,a5,15d6 <vprintf+0x15c>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    15ac:	07500793          	li	a5,117
    15b0:	06f60963          	beq	a2,a5,1622 <vprintf+0x1a8>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    15b4:	07800793          	li	a5,120
    15b8:	faf61ee3          	bne	a2,a5,1574 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
    15bc:	008b8913          	addi	s2,s7,8
    15c0:	4681                	li	a3,0
    15c2:	4641                	li	a2,16
    15c4:	000bb583          	ld	a1,0(s7)
    15c8:	855a                	mv	a0,s6
    15ca:	e15ff0ef          	jal	13de <printint>
        i += 2;
    15ce:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
    15d0:	8bca                	mv	s7,s2
      state = 0;
    15d2:	4981                	li	s3,0
        i += 2;
    15d4:	bdc5                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
    15d6:	008b8913          	addi	s2,s7,8
    15da:	4685                	li	a3,1
    15dc:	4629                	li	a2,10
    15de:	000bb583          	ld	a1,0(s7)
    15e2:	855a                	mv	a0,s6
    15e4:	dfbff0ef          	jal	13de <printint>
        i += 2;
    15e8:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
    15ea:	8bca                	mv	s7,s2
      state = 0;
    15ec:	4981                	li	s3,0
        i += 2;
    15ee:	bdd9                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 10, 0);
    15f0:	008b8913          	addi	s2,s7,8
    15f4:	4681                	li	a3,0
    15f6:	4629                	li	a2,10
    15f8:	000be583          	lwu	a1,0(s7)
    15fc:	855a                	mv	a0,s6
    15fe:	de1ff0ef          	jal	13de <printint>
    1602:	8bca                	mv	s7,s2
      state = 0;
    1604:	4981                	li	s3,0
    1606:	bd7d                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
    1608:	008b8913          	addi	s2,s7,8
    160c:	4681                	li	a3,0
    160e:	4629                	li	a2,10
    1610:	000bb583          	ld	a1,0(s7)
    1614:	855a                	mv	a0,s6
    1616:	dc9ff0ef          	jal	13de <printint>
        i += 1;
    161a:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
    161c:	8bca                	mv	s7,s2
      state = 0;
    161e:	4981                	li	s3,0
        i += 1;
    1620:	b555                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
    1622:	008b8913          	addi	s2,s7,8
    1626:	4681                	li	a3,0
    1628:	4629                	li	a2,10
    162a:	000bb583          	ld	a1,0(s7)
    162e:	855a                	mv	a0,s6
    1630:	dafff0ef          	jal	13de <printint>
        i += 2;
    1634:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
    1636:	8bca                	mv	s7,s2
      state = 0;
    1638:	4981                	li	s3,0
        i += 2;
    163a:	b569                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 16, 0);
    163c:	008b8913          	addi	s2,s7,8
    1640:	4681                	li	a3,0
    1642:	4641                	li	a2,16
    1644:	000be583          	lwu	a1,0(s7)
    1648:	855a                	mv	a0,s6
    164a:	d95ff0ef          	jal	13de <printint>
    164e:	8bca                	mv	s7,s2
      state = 0;
    1650:	4981                	li	s3,0
    1652:	bd8d                	j	14c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 16, 0);
    1654:	008b8913          	addi	s2,s7,8
    1658:	4681                	li	a3,0
    165a:	4641                	li	a2,16
    165c:	000bb583          	ld	a1,0(s7)
    1660:	855a                	mv	a0,s6
    1662:	d7dff0ef          	jal	13de <printint>
        i += 1;
    1666:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
    1668:	8bca                	mv	s7,s2
      state = 0;
    166a:	4981                	li	s3,0
        i += 1;
    166c:	bda1                	j	14c4 <vprintf+0x4a>
    166e:	e06a                	sd	s10,0(sp)
        printptr(fd, va_arg(ap, uint64));
    1670:	008b8d13          	addi	s10,s7,8
    1674:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
    1678:	03000593          	li	a1,48
    167c:	855a                	mv	a0,s6
    167e:	d43ff0ef          	jal	13c0 <putc>
  putc(fd, 'x');
    1682:	07800593          	li	a1,120
    1686:	855a                	mv	a0,s6
    1688:	d39ff0ef          	jal	13c0 <putc>
    168c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    168e:	00000b97          	auipc	s7,0x0
    1692:	602b8b93          	addi	s7,s7,1538 # 1c90 <digits>
    1696:	03c9d793          	srli	a5,s3,0x3c
    169a:	97de                	add	a5,a5,s7
    169c:	0007c583          	lbu	a1,0(a5)
    16a0:	855a                	mv	a0,s6
    16a2:	d1fff0ef          	jal	13c0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    16a6:	0992                	slli	s3,s3,0x4
    16a8:	397d                	addiw	s2,s2,-1
    16aa:	fe0916e3          	bnez	s2,1696 <vprintf+0x21c>
        printptr(fd, va_arg(ap, uint64));
    16ae:	8bea                	mv	s7,s10
      state = 0;
    16b0:	4981                	li	s3,0
    16b2:	6d02                	ld	s10,0(sp)
    16b4:	bd01                	j	14c4 <vprintf+0x4a>
        putc(fd, va_arg(ap, uint32));
    16b6:	008b8913          	addi	s2,s7,8
    16ba:	000bc583          	lbu	a1,0(s7)
    16be:	855a                	mv	a0,s6
    16c0:	d01ff0ef          	jal	13c0 <putc>
    16c4:	8bca                	mv	s7,s2
      state = 0;
    16c6:	4981                	li	s3,0
    16c8:	bbf5                	j	14c4 <vprintf+0x4a>
        if((s = va_arg(ap, char*)) == 0)
    16ca:	008b8993          	addi	s3,s7,8
    16ce:	000bb903          	ld	s2,0(s7)
    16d2:	00090f63          	beqz	s2,16f0 <vprintf+0x276>
        for(; *s; s++)
    16d6:	00094583          	lbu	a1,0(s2)
    16da:	c195                	beqz	a1,16fe <vprintf+0x284>
          putc(fd, *s);
    16dc:	855a                	mv	a0,s6
    16de:	ce3ff0ef          	jal	13c0 <putc>
        for(; *s; s++)
    16e2:	0905                	addi	s2,s2,1
    16e4:	00094583          	lbu	a1,0(s2)
    16e8:	f9f5                	bnez	a1,16dc <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
    16ea:	8bce                	mv	s7,s3
      state = 0;
    16ec:	4981                	li	s3,0
    16ee:	bbd9                	j	14c4 <vprintf+0x4a>
          s = "(null)";
    16f0:	00000917          	auipc	s2,0x0
    16f4:	55890913          	addi	s2,s2,1368 # 1c48 <malloc+0x44c>
        for(; *s; s++)
    16f8:	02800593          	li	a1,40
    16fc:	b7c5                	j	16dc <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
    16fe:	8bce                	mv	s7,s3
      state = 0;
    1700:	4981                	li	s3,0
    1702:	b3c9                	j	14c4 <vprintf+0x4a>
    1704:	64a6                	ld	s1,72(sp)
    1706:	79e2                	ld	s3,56(sp)
    1708:	7a42                	ld	s4,48(sp)
    170a:	7aa2                	ld	s5,40(sp)
    170c:	7b02                	ld	s6,32(sp)
    170e:	6be2                	ld	s7,24(sp)
    1710:	6c42                	ld	s8,16(sp)
    1712:	6ca2                	ld	s9,8(sp)
    }
  }
}
    1714:	60e6                	ld	ra,88(sp)
    1716:	6446                	ld	s0,80(sp)
    1718:	6906                	ld	s2,64(sp)
    171a:	6125                	addi	sp,sp,96
    171c:	8082                	ret

000000000000171e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    171e:	715d                	addi	sp,sp,-80
    1720:	ec06                	sd	ra,24(sp)
    1722:	e822                	sd	s0,16(sp)
    1724:	1000                	addi	s0,sp,32
    1726:	e010                	sd	a2,0(s0)
    1728:	e414                	sd	a3,8(s0)
    172a:	e818                	sd	a4,16(s0)
    172c:	ec1c                	sd	a5,24(s0)
    172e:	03043023          	sd	a6,32(s0)
    1732:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    1736:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    173a:	8622                	mv	a2,s0
    173c:	d3fff0ef          	jal	147a <vprintf>
}
    1740:	60e2                	ld	ra,24(sp)
    1742:	6442                	ld	s0,16(sp)
    1744:	6161                	addi	sp,sp,80
    1746:	8082                	ret

0000000000001748 <printf>:

void
printf(const char *fmt, ...)
{
    1748:	711d                	addi	sp,sp,-96
    174a:	ec06                	sd	ra,24(sp)
    174c:	e822                	sd	s0,16(sp)
    174e:	1000                	addi	s0,sp,32
    1750:	e40c                	sd	a1,8(s0)
    1752:	e810                	sd	a2,16(s0)
    1754:	ec14                	sd	a3,24(s0)
    1756:	f018                	sd	a4,32(s0)
    1758:	f41c                	sd	a5,40(s0)
    175a:	03043823          	sd	a6,48(s0)
    175e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    1762:	00840613          	addi	a2,s0,8
    1766:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    176a:	85aa                	mv	a1,a0
    176c:	4505                	li	a0,1
    176e:	d0dff0ef          	jal	147a <vprintf>
}
    1772:	60e2                	ld	ra,24(sp)
    1774:	6442                	ld	s0,16(sp)
    1776:	6125                	addi	sp,sp,96
    1778:	8082                	ret

000000000000177a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    177a:	1141                	addi	sp,sp,-16
    177c:	e422                	sd	s0,8(sp)
    177e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1780:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1784:	00001797          	auipc	a5,0x1
    1788:	87c7b783          	ld	a5,-1924(a5) # 2000 <freep>
    178c:	a02d                	j	17b6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    178e:	4618                	lw	a4,8(a2)
    1790:	9f2d                	addw	a4,a4,a1
    1792:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1796:	6398                	ld	a4,0(a5)
    1798:	6310                	ld	a2,0(a4)
    179a:	a83d                	j	17d8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    179c:	ff852703          	lw	a4,-8(a0)
    17a0:	9f31                	addw	a4,a4,a2
    17a2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
    17a4:	ff053683          	ld	a3,-16(a0)
    17a8:	a091                	j	17ec <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    17aa:	6398                	ld	a4,0(a5)
    17ac:	00e7e463          	bltu	a5,a4,17b4 <free+0x3a>
    17b0:	00e6ea63          	bltu	a3,a4,17c4 <free+0x4a>
{
    17b4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    17b6:	fed7fae3          	bgeu	a5,a3,17aa <free+0x30>
    17ba:	6398                	ld	a4,0(a5)
    17bc:	00e6e463          	bltu	a3,a4,17c4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    17c0:	fee7eae3          	bltu	a5,a4,17b4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
    17c4:	ff852583          	lw	a1,-8(a0)
    17c8:	6390                	ld	a2,0(a5)
    17ca:	02059813          	slli	a6,a1,0x20
    17ce:	01c85713          	srli	a4,a6,0x1c
    17d2:	9736                	add	a4,a4,a3
    17d4:	fae60de3          	beq	a2,a4,178e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
    17d8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    17dc:	4790                	lw	a2,8(a5)
    17de:	02061593          	slli	a1,a2,0x20
    17e2:	01c5d713          	srli	a4,a1,0x1c
    17e6:	973e                	add	a4,a4,a5
    17e8:	fae68ae3          	beq	a3,a4,179c <free+0x22>
    p->s.ptr = bp->s.ptr;
    17ec:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
    17ee:	00001717          	auipc	a4,0x1
    17f2:	80f73923          	sd	a5,-2030(a4) # 2000 <freep>
}
    17f6:	6422                	ld	s0,8(sp)
    17f8:	0141                	addi	sp,sp,16
    17fa:	8082                	ret

00000000000017fc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    17fc:	7139                	addi	sp,sp,-64
    17fe:	fc06                	sd	ra,56(sp)
    1800:	f822                	sd	s0,48(sp)
    1802:	f426                	sd	s1,40(sp)
    1804:	ec4e                	sd	s3,24(sp)
    1806:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    1808:	02051493          	slli	s1,a0,0x20
    180c:	9081                	srli	s1,s1,0x20
    180e:	04bd                	addi	s1,s1,15
    1810:	8091                	srli	s1,s1,0x4
    1812:	0014899b          	addiw	s3,s1,1
    1816:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    1818:	00000517          	auipc	a0,0x0
    181c:	7e853503          	ld	a0,2024(a0) # 2000 <freep>
    1820:	c915                	beqz	a0,1854 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1822:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1824:	4798                	lw	a4,8(a5)
    1826:	08977a63          	bgeu	a4,s1,18ba <malloc+0xbe>
    182a:	f04a                	sd	s2,32(sp)
    182c:	e852                	sd	s4,16(sp)
    182e:	e456                	sd	s5,8(sp)
    1830:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
    1832:	8a4e                	mv	s4,s3
    1834:	0009871b          	sext.w	a4,s3
    1838:	6685                	lui	a3,0x1
    183a:	00d77363          	bgeu	a4,a3,1840 <malloc+0x44>
    183e:	6a05                	lui	s4,0x1
    1840:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    1844:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    1848:	00000917          	auipc	s2,0x0
    184c:	7b890913          	addi	s2,s2,1976 # 2000 <freep>
  if(p == SBRK_ERROR)
    1850:	5afd                	li	s5,-1
    1852:	a081                	j	1892 <malloc+0x96>
    1854:	f04a                	sd	s2,32(sp)
    1856:	e852                	sd	s4,16(sp)
    1858:	e456                	sd	s5,8(sp)
    185a:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
    185c:	00004797          	auipc	a5,0x4
    1860:	8b478793          	addi	a5,a5,-1868 # 5110 <base>
    1864:	00000717          	auipc	a4,0x0
    1868:	78f73e23          	sd	a5,1948(a4) # 2000 <freep>
    186c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    186e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    1872:	b7c1                	j	1832 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
    1874:	6398                	ld	a4,0(a5)
    1876:	e118                	sd	a4,0(a0)
    1878:	a8a9                	j	18d2 <malloc+0xd6>
  hp->s.size = nu;
    187a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    187e:	0541                	addi	a0,a0,16
    1880:	efbff0ef          	jal	177a <free>
  return freep;
    1884:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1888:	c12d                	beqz	a0,18ea <malloc+0xee>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    188a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    188c:	4798                	lw	a4,8(a5)
    188e:	02977263          	bgeu	a4,s1,18b2 <malloc+0xb6>
    if(p == freep)
    1892:	00093703          	ld	a4,0(s2)
    1896:	853e                	mv	a0,a5
    1898:	fef719e3          	bne	a4,a5,188a <malloc+0x8e>
  p = sbrk(nu * sizeof(Header));
    189c:	8552                	mv	a0,s4
    189e:	a3fff0ef          	jal	12dc <sbrk>
  if(p == SBRK_ERROR)
    18a2:	fd551ce3          	bne	a0,s5,187a <malloc+0x7e>
        return 0;
    18a6:	4501                	li	a0,0
    18a8:	7902                	ld	s2,32(sp)
    18aa:	6a42                	ld	s4,16(sp)
    18ac:	6aa2                	ld	s5,8(sp)
    18ae:	6b02                	ld	s6,0(sp)
    18b0:	a03d                	j	18de <malloc+0xe2>
    18b2:	7902                	ld	s2,32(sp)
    18b4:	6a42                	ld	s4,16(sp)
    18b6:	6aa2                	ld	s5,8(sp)
    18b8:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
    18ba:	fae48de3          	beq	s1,a4,1874 <malloc+0x78>
        p->s.size -= nunits;
    18be:	4137073b          	subw	a4,a4,s3
    18c2:	c798                	sw	a4,8(a5)
        p += p->s.size;
    18c4:	02071693          	slli	a3,a4,0x20
    18c8:	01c6d713          	srli	a4,a3,0x1c
    18cc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    18ce:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    18d2:	00000717          	auipc	a4,0x0
    18d6:	72a73723          	sd	a0,1838(a4) # 2000 <freep>
      return (void*)(p + 1);
    18da:	01078513          	addi	a0,a5,16
  }
}
    18de:	70e2                	ld	ra,56(sp)
    18e0:	7442                	ld	s0,48(sp)
    18e2:	74a2                	ld	s1,40(sp)
    18e4:	69e2                	ld	s3,24(sp)
    18e6:	6121                	addi	sp,sp,64
    18e8:	8082                	ret
    18ea:	7902                	ld	s2,32(sp)
    18ec:	6a42                	ld	s4,16(sp)
    18ee:	6aa2                	ld	s5,8(sp)
    18f0:	6b02                	ld	s6,0(sp)
    18f2:	b7f5                	j	18de <malloc+0xe2>

======== THEIR VERSION
>>>>>>>> END
