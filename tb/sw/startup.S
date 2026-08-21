.section .vectors

.option norvc

.type reset_handler, @function
.global reset_handler
reset_handler:
	.cfi_startproc

.option push
.option norelax
	la gp, __global_pointer$
.option pop
	
	/* Reset satp */
	/* csrw satp, zero */
	
	/* Setup stack */
	la sp, _stack
	
	/* Clear the BSS section */
	la t5, _edata
	la t6, _ebss
_bss_clear_loop:
	sw zero, (t5)
	addi t5, t5, 4
	bltu t5, t6, _bss_clear_loop
	
	la t0, main
	/* csrw mepc, t0 */
	
	/* Jump to kernel! */
	tail main
	
	.cfi_endproc

.end
