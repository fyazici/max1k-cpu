
main.elf:     file format elf32-littleriscv

Contents of section .text:
 0000 97110000 93810188 13010048 130f0008  ...........H....
 0010 971f0000 938f0f87 23200f00 130f4f00  ........# ....O.
 0020 e36cffff 97020000 9382c202 6f004002  .l..........o.@.
Contents of section .text.usleep:
 0030 130101ff 2326a100 8327c100 1387f7ff  ....#&...'......
 0040 2326e100 e39a07fe 13010101 67800000  #&..........g...
Contents of section .text.startup.main:
 0050 130101ff 23248100 23229100 23261100  ....#$..#"..#&..
 0060 13040000 b7040080 37a50700 13050512  ........7.......
 0070 eff01ffc 23a08400 13041400 6ff0dffe  ....#.......o...
Contents of section .comment:
 0000 4743433a 20286736 61666363 34663664  GCC: (g6afcc4f6d
 0010 29203136 2e312e30 00                 ) 16.1.0.       
Contents of section .riscv.attributes:
 0000 411b0000 00726973 63760001 11000000  A....riscv......
 0010 04100572 76333269 32703100           ...rv32i2p1.    

Disassembly of section .text:

00000000 <start>:
   0:	00001197          	auipc	gp,0x1
   4:	88018193          	addi	gp,gp,-1920 # 880 <__global_pointer$>
   8:	48000113          	li	sp,1152
   c:	08000f13          	li	t5,128
  10:	00001f97          	auipc	t6,0x1
  14:	870f8f93          	addi	t6,t6,-1936 # 880 <__global_pointer$>

00000018 <bss_clear>:
  18:	000f2023          	sw	zero,0(t5)
  1c:	004f0f13          	addi	t5,t5,4
  20:	ffff6ce3          	bltu	t5,t6,18 <bss_clear>
  24:	00000297          	auipc	t0,0x0
  28:	02c28293          	addi	t0,t0,44 # 50 <main>
  2c:	0240006f          	j	50 <main>

Disassembly of section .text.usleep:

00000030 <usleep>:
  30:	ff010113          	addi	sp,sp,-16
  34:	00a12623          	sw	a0,12(sp)
  38:	00c12783          	lw	a5,12(sp)
  3c:	fff78713          	addi	a4,a5,-1
  40:	00e12623          	sw	a4,12(sp)
  44:	fe079ae3          	bnez	a5,38 <usleep+0x8>
  48:	01010113          	addi	sp,sp,16
  4c:	00008067          	ret

Disassembly of section .text.startup.main:

00000050 <main>:
  50:	ff010113          	addi	sp,sp,-16
  54:	00812423          	sw	s0,8(sp)
  58:	00912223          	sw	s1,4(sp)
  5c:	00112623          	sw	ra,12(sp)
  60:	00000413          	li	s0,0
  64:	800004b7          	lui	s1,0x80000
  68:	0007a537          	lui	a0,0x7a
  6c:	12050513          	addi	a0,a0,288 # 7a120 <__global_pointer$+0x798a0>
  70:	fc1ff0ef          	jal	30 <usleep>
  74:	0084a023          	sw	s0,0(s1) # 80000000 <__global_pointer$+0x7ffff780>
  78:	00140413          	addi	s0,s0,1
  7c:	fedff06f          	j	68 <main+0x18>
