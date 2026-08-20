
main.elf:     file format elf32-littleriscv

Contents of section .text:
 0000 97110000 9381818b 1301804b 130f800b  ...........K....
 0010 971f0000 938f8f8a 23200f00 130f4f00  ........# ....O.
 0020 e36cffff 97020000 9382c200 6f004000  .l..........o.@.
 0030 93073036 370700c0 130101ff 37050080  ..067.......7...
 0040 2320f700 b7c7e0f0 23200500 93870708  # ......# ......
 0050 37480f00 2326f500 93853110 13080824  7H..#&....1....$
 0060 23260101 8327c100 9386f7ff 2326d100  #&...'......#&..
 0070 e39a07fe 93861100 1306c004 83274700  .............'G.
 0080 93f71700 e38c07fe 2324c700 93861600  ........#$......
 0090 03c6f6ff e394b6fe 8327c500 8326c500  .........'...&..
 00a0 93d71700 93967600 b3e7d700 93f7f70f  ......v.........
 00b0 2326f500 6ff0dffa                    #&..o...        
Contents of section .rodata:
 08b8 4c6f7265 6d206970 73756d20 646f6c6f  Lorem ipsum dolo
 08c8 72207369 7420616d 65742c20 636f6e73  r sit amet, cons
 08d8 65637465 74757220 61646970 69736369  ectetur adipisci
 08e8 6e672065 6c69742e 20536564 20656c65  ng elit. Sed ele
 08f8 6d656e74 756d206e 756e6320 656c6974  mentum nunc elit
 0908 2c206e65 6320656c 65696665 6e64206d  , nec eleifend m
 0918 65747573 20766976 65727261 2065742e  etus viverra et.
 0928 20437261 73207665 68696375 6c612061   Cras vehicula a
 0938 72637520 6469616d 2c207574 2074656d  rcu diam, ut tem
 0948 706f7220 6a757374 6f20626c 616e6469  por justo blandi
 0958 74206964 2e20416c 69717561 6d206865  t id. Aliquam he
 0968 6e647265 72697420 74757270 69732073  ndrerit turpis s
 0978 65642075 726e6120 64696374 756d2072  ed urna dictum r
 0988 686f6e63 75732e20 41656e65 616e2063  honcus. Aenean c
 0998 6f6e7365 63746574 7572206e 756c6c61  onsectetur nulla
 09a8 20657520 656c6974 206c6967 756c612e   eu elit ligula.
 09b8 0a0d00                               ...             
Contents of section .comment:
 0000 4743433a 20286736 61666363 34663664  GCC: (g6afcc4f6d
 0010 29203136 2e312e30 00                 ) 16.1.0.       
Contents of section .riscv.attributes:
 0000 411b0000 00726973 63760001 11000000  A....riscv......
 0010 04100572 76333269 32703100           ...rv32i2p1.    

Disassembly of section .text:

00000000 <start>:
   0:	00001197          	auipc	gp,0x1
   4:	8b818193          	addi	gp,gp,-1864 # 8b8 <__global_pointer$>
   8:	4b800113          	li	sp,1208
   c:	0b800f13          	li	t5,184
  10:	00001f97          	auipc	t6,0x1
  14:	8a8f8f93          	addi	t6,t6,-1880 # 8b8 <__global_pointer$>

00000018 <bss_clear>:
  18:	000f2023          	sw	zero,0(t5)
  1c:	004f0f13          	addi	t5,t5,4
  20:	ffff6ce3          	bltu	t5,t6,18 <bss_clear>
  24:	00000297          	auipc	t0,0x0
  28:	00c28293          	addi	t0,t0,12 # 30 <main>
  2c:	0040006f          	j	30 <main>

00000030 <main>:
  30:	36300793          	li	a5,867
  34:	c0000737          	lui	a4,0xc0000
  38:	ff010113          	addi	sp,sp,-16
  3c:	80000537          	lui	a0,0x80000
  40:	00f72023          	sw	a5,0(a4) # c0000000 <_end+0xbffff645>
  44:	f0e0c7b7          	lui	a5,0xf0e0c
  48:	00052023          	sw	zero,0(a0) # 80000000 <_end+0x7ffff645>
  4c:	08078793          	addi	a5,a5,128 # f0e0c080 <_end+0xf0e0b6c5>
  50:	000f4837          	lui	a6,0xf4
  54:	00f52623          	sw	a5,12(a0)
  58:	10318593          	addi	a1,gp,259 # 9bb <_end>
  5c:	24080813          	addi	a6,a6,576 # f4240 <_end+0xf3885>
  60:	01012623          	sw	a6,12(sp)
  64:	00c12783          	lw	a5,12(sp)
  68:	fff78693          	addi	a3,a5,-1
  6c:	00d12623          	sw	a3,12(sp)
  70:	fe079ae3          	bnez	a5,64 <main+0x34>
  74:	00118693          	addi	a3,gp,1 # 8b9 <__global_pointer$+0x1>
  78:	04c00613          	li	a2,76
  7c:	00472783          	lw	a5,4(a4)
  80:	0017f793          	andi	a5,a5,1
  84:	fe078ce3          	beqz	a5,7c <main+0x4c>
  88:	00c72423          	sw	a2,8(a4)
  8c:	00168693          	addi	a3,a3,1
  90:	fff6c603          	lbu	a2,-1(a3)
  94:	feb694e3          	bne	a3,a1,7c <main+0x4c>
  98:	00c52783          	lw	a5,12(a0)
  9c:	00c52683          	lw	a3,12(a0)
  a0:	0017d793          	srli	a5,a5,0x1
  a4:	00769693          	slli	a3,a3,0x7
  a8:	00d7e7b3          	or	a5,a5,a3
  ac:	0ff7f793          	zext.b	a5,a5
  b0:	00f52623          	sw	a5,12(a0)
  b4:	fadff06f          	j	60 <main+0x30>
