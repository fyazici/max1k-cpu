ENTRY(start);
 
. = 0x00000000;
 
SECTIONS {
	/* Include entry point at start of binary */
	.text : ALIGN(4) {
		*(.init);
		*(.text*);
	}
	.bss : ALIGN(4) {
		PROVIDE(bss_start = .);
		*(.bss*);
		. += 1024;
		PROVIDE(stack_top = .);
		. += 1024;
		PROVIDE(__global_pointer$ = .);
		PROVIDE(bss_end = .);
	}
	.rodata : ALIGN(4) {
		*(.rodata*);
	}
	.data : ALIGN(4) {
		*(.data*);
	}
}

/* for sbrk */
PROVIDE(_end = .);