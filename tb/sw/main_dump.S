
main.elf:     file format elf32-littleriscv

Contents of section .text:
 0000 97110000 93810188 13010048 130f0008  ...........H....
 0010 971f0000 938f0f87 23200f00 130f4f00  ........# ....O.
 0020 e36cffff 97020000 9382c202 6f004002  .l..........o.@.
Contents of section .text.kprint:
 0030 37170000 83470500 63940700 67800000  7....G..c...g...
 0040 83264789 13051500 2380f600 6ff09ffe  .&G.....#...o...
Contents of section .text.startup.main:
 0050 37150000 130101ff 13054588 23261100  7.........E.#&..
 0060 eff01ffd 37160000 b7160000 83274689  ....7........'F.
 0070 03c70700 23a0e688 2380e700 6ff01fff  ....#...#...o...
Contents of section .rodata.main.str1.4:
 0884 48656c6c 6f20776f 726c6421 0d0a00    Hello world!... 
Contents of section .sdata.uart:
 0894 78563412                             xV4.            
Contents of section .comment:
 0000 4743433a 20286736 61666363 34663664  GCC: (g6afcc4f6d
 0010 29203136 2e312e30 00                 ) 16.1.0.       
Contents of section .riscv.attributes:
 0000 411b0000 00726973 63760001 11000000  A....riscv......
 0010 04100572 76333269 32703100           ...rv32i2p1.    

Disassembly of section .text:

00000000 <start>:
   0:	00001197          	auipc	gp,0x1
   4:	88018193          	addi	gp,gp,-1920 # 880 <giValue>
   8:	48000113          	li	sp,1152
   c:	08000f13          	li	t5,128
  10:	00001f97          	auipc	t6,0x1
  14:	870f8f93          	addi	t6,t6,-1936 # 880 <giValue>

00000018 <bss_clear>:
  18:	000f2023          	sw	zero,0(t5)
  1c:	004f0f13          	addi	t5,t5,4
  20:	ffff6ce3          	bltu	t5,t6,18 <bss_clear>
  24:	00000297          	auipc	t0,0x0
  28:	02c28293          	addi	t0,t0,44 # 50 <main>
  2c:	0240006f          	j	50 <main>

Disassembly of section .text.kprint:

00000030 <kprint>:
  30:	00001737          	lui	a4,0x1
  34:	00054783          	lbu	a5,0(a0)
  38:	00079463          	bnez	a5,40 <kprint+0x10>
  3c:	00008067          	ret
  40:	89472683          	lw	a3,-1900(a4) # 894 <uart>
  44:	00150513          	addi	a0,a0,1
  48:	00f68023          	sb	a5,0(a3)
  4c:	fe9ff06f          	j	34 <kprint+0x4>

Disassembly of section .text.startup.main:

00000050 <main>:
  50:	00001537          	lui	a0,0x1
  54:	ff010113          	addi	sp,sp,-16
  58:	88450513          	addi	a0,a0,-1916 # 884 <giValue+0x4>
  5c:	00112623          	sw	ra,12(sp)
  60:	fd1ff0ef          	jal	30 <kprint>
  64:	00001637          	lui	a2,0x1
  68:	000016b7          	lui	a3,0x1
  6c:	89462783          	lw	a5,-1900(a2) # 894 <uart>
  70:	0007c703          	lbu	a4,0(a5)
  74:	88e6a023          	sw	a4,-1920(a3) # 880 <giValue>
  78:	00e78023          	sb	a4,0(a5)
  7c:	ff1ff06f          	j	6c <main+0x1c>
