ENTRY(start);
 
MEMORY
{
	ram (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}
 
SECTIONS {
	/* Include entry point at start of binary */
	.text : ALIGN(4) {
		*(.init);
		*(.text);
	} >ram
	
	.bss : ALIGN(4) {
		PROVIDE(bss_start = .);
		*(.bss);
		. += 1024;
		PROVIDE(stack_top = .);
		. += 1024;
		PROVIDE(global_pointer = .);
		PROVIDE(bss_end = .);
	} >ram

	.rodata : ALIGN(4) {
		*(.rodata);
	} >ram

	.data : ALIGN(4) {
		*(.data);
	} >ram
}