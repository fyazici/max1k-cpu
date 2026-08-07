
main.elf:     file format elf32-littleriscv

Contents of section .text:
 0000 97110000 9381418a 1301404a 130f400a  ......A...@J..@.
 0010 971f0000 938f4f89 23200f00 130f4f00  ......O.# ....O.
 0020 e36cffff 97020000 9382c200 6f004000  .l..........o.@.
 0030 9307101b 370700c0 130101ff 37050080  ....7.......7...
 0040 2320f700 23200500 9307f000 37a80700  # ..# ......7...
 0050 2326f500 93853110 13080812 23260101  #&....1.....#&..
 0060 8327c100 9386f7ff 2326d100 e39a07fe  .'......#&......
 0070 93861100 1306c004 83274700 93f71700  .........'G.....
 0080 e38c07fe 2324c700 93861600 03c6f6ff  ....#$..........
 0090 e394b6fe 8327c500 93c7f70f 2326f500  .....'......#&..
 00a0 6ff0dffb                             o...            
Contents of section .rodata:
 08a4 4c6f7265 6d206970 73756d20 646f6c6f  Lorem ipsum dolo
 08b4 72207369 7420616d 65742c20 636f6e73  r sit amet, cons
 08c4 65637465 74757220 61646970 69736369  ectetur adipisci
 08d4 6e672065 6c69742e 20536564 20656c65  ng elit. Sed ele
 08e4 6d656e74 756d206e 756e6320 656c6974  mentum nunc elit
 08f4 2c206e65 6320656c 65696665 6e64206d  , nec eleifend m
 0904 65747573 20766976 65727261 2065742e  etus viverra et.
 0914 20437261 73207665 68696375 6c612061   Cras vehicula a
 0924 72637520 6469616d 2c207574 2074656d  rcu diam, ut tem
 0934 706f7220 6a757374 6f20626c 616e6469  por justo blandi
 0944 74206964 2e20416c 69717561 6d206865  t id. Aliquam he
 0954 6e647265 72697420 74757270 69732073  ndrerit turpis s
 0964 65642075 726e6120 64696374 756d2072  ed urna dictum r
 0974 686f6e63 75732e20 41656e65 616e2063  honcus. Aenean c
 0984 6f6e7365 63746574 7572206e 756c6c61  onsectetur nulla
 0994 20657520 656c6974 206c6967 756c612e   eu elit ligula.
 09a4 0a0d00                               ...             
Contents of section .comment:
 0000 4743433a 20286736 61666363 34663664  GCC: (g6afcc4f6d
 0010 29203136 2e312e30 00                 ) 16.1.0.       
Contents of section .riscv.attributes:
 0000 411b0000 00726973 63760001 11000000  A....riscv......
 0010 04100572 76333269 32703100           ...rv32i2p1.    

Disassembly of section .text:

00000000 <start>:
   0:	00001197          	auipc	gp,0x1
   4:	8a418193          	addi	gp,gp,-1884 # 8a4 <__global_pointer$>
   8:	4a400113          	li	sp,1188
   c:	0a400f13          	li	t5,164
  10:	00001f97          	auipc	t6,0x1
  14:	894f8f93          	addi	t6,t6,-1900 # 8a4 <__global_pointer$>

00000018 <bss_clear>:
  18:	000f2023          	sw	zero,0(t5)
  1c:	004f0f13          	addi	t5,t5,4
  20:	ffff6ce3          	bltu	t5,t6,18 <bss_clear>
  24:	00000297          	auipc	t0,0x0
  28:	00c28293          	addi	t0,t0,12 # 30 <main>
  2c:	0040006f          	j	30 <main>

00000030 <main>:
  30:	1b100793          	li	a5,433
  34:	c0000737          	lui	a4,0xc0000
  38:	ff010113          	addi	sp,sp,-16
  3c:	80000537          	lui	a0,0x80000
  40:	00f72023          	sw	a5,0(a4) # c0000000 <_end+0xbffff659>
  44:	00052023          	sw	zero,0(a0) # 80000000 <_end+0x7ffff659>
  48:	00f00793          	li	a5,15
  4c:	0007a837          	lui	a6,0x7a
  50:	00f52623          	sw	a5,12(a0)
  54:	10318593          	addi	a1,gp,259 # 9a7 <_end>
  58:	12080813          	addi	a6,a6,288 # 7a120 <_end+0x79779>
  5c:	01012623          	sw	a6,12(sp)
  60:	00c12783          	lw	a5,12(sp)
  64:	fff78693          	addi	a3,a5,-1
  68:	00d12623          	sw	a3,12(sp)
  6c:	fe079ae3          	bnez	a5,60 <main+0x30>
  70:	00118693          	addi	a3,gp,1 # 8a5 <__global_pointer$+0x1>
  74:	04c00613          	li	a2,76
  78:	00472783          	lw	a5,4(a4)
  7c:	0017f793          	andi	a5,a5,1
  80:	fe078ce3          	beqz	a5,78 <main+0x48>
  84:	00c72423          	sw	a2,8(a4)
  88:	00168693          	addi	a3,a3,1
  8c:	fff6c603          	lbu	a2,-1(a3)
  90:	feb694e3          	bne	a3,a1,78 <main+0x48>
  94:	00c52783          	lw	a5,12(a0)
  98:	0ff7c793          	xori	a5,a5,255
  9c:	00f52623          	sw	a5,12(a0)
  a0:	fbdff06f          	j	5c <main+0x2c>
