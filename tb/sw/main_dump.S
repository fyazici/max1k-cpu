
main.elf:     file format elf32-littleriscv

Contents of section .text:
 0000 97110000 93814187 13014047 130f4007  ......A...@G..@.
 0010 971f0000 938f4f86 23200f00 130f4f00  ......O.# ....O.
 0020 e36cffff 97020000 93828202 6f000002  .l..........o...
Contents of section .text.kprint:
 0030 83470500 63940700 67800000 83a64101  .G..c...g.....A.
 0040 13051500 2380f600 6ff09ffe           ....#...o...    
Contents of section .text.startup.main:
 004c 130101ff 13854100 23261100 eff09ffd  ......A.#&......
 005c 83a70100 93861700 23a0d100 83a64101  ........#.....A.
 006c 2380f600 6ff0dffe                    #...o...        
Contents of section .rodata.main.str1.4:
 0878 48656c6c 6f20776f 726c6421 0d0a00    Hello world!... 
Contents of section .sdata.uart:
 0888 78563412                             xV4.            
Contents of section .comment:
 0000 4743433a 20286736 61666363 34663664  GCC: (g6afcc4f6d
 0010 29203136 2e312e30 00                 ) 16.1.0.       
Contents of section .riscv.attributes:
 0000 411b0000 00726973 63760001 11000000  A....riscv......
 0010 04100572 76333269 32703100           ...rv32i2p1.    

Disassembly of section .text:

00000000 <start>:
   0:	00001197          	auipc	gp,0x1
   4:	87418193          	addi	gp,gp,-1932 # 874 <giValue>
   8:	47400113          	li	sp,1140
   c:	07400f13          	li	t5,116
  10:	00001f97          	auipc	t6,0x1
  14:	864f8f93          	addi	t6,t6,-1948 # 874 <giValue>

00000018 <bss_clear>:
  18:	000f2023          	sw	zero,0(t5)
  1c:	004f0f13          	addi	t5,t5,4
  20:	ffff6ce3          	bltu	t5,t6,18 <bss_clear>
  24:	00000297          	auipc	t0,0x0
  28:	02828293          	addi	t0,t0,40 # 4c <main>
  2c:	0200006f          	j	4c <main>

Disassembly of section .text.kprint:

00000030 <kprint>:
  30:	00054783          	lbu	a5,0(a0)
  34:	00079463          	bnez	a5,3c <kprint+0xc>
  38:	00008067          	ret
  3c:	0141a683          	lw	a3,20(gp) # 888 <uart>
  40:	00150513          	addi	a0,a0,1
  44:	00f68023          	sb	a5,0(a3)
  48:	fe9ff06f          	j	30 <kprint>

Disassembly of section .text.startup.main:

0000004c <main>:
  4c:	ff010113          	addi	sp,sp,-16
  50:	00418513          	addi	a0,gp,4 # 878 <giValue+0x4>
  54:	00112623          	sw	ra,12(sp)
  58:	fd9ff0ef          	jal	30 <kprint>
  5c:	0001a783          	lw	a5,0(gp) # 874 <giValue>
  60:	00178693          	addi	a3,a5,1
  64:	00d1a023          	sw	a3,0(gp) # 874 <giValue>
  68:	0141a683          	lw	a3,20(gp) # 888 <uart>
  6c:	00f68023          	sb	a5,0(a3)
  70:	fedff06f          	j	5c <main+0x10>
