ENTRY(reset_handler);
 
MEMORY
{
	/* rom (rx) : ORIGIN = 0x08000000, LENGTH = 64K */
	ram (rwx) : ORIGIN = 0x00000000, LENGTH = 32K
}
 
SECTIONS {
	.text : {
		*(.vectors)	/* Vector table */
		*(.text*)	/* Program code */
		. = ALIGN(4);
		*(.rodata*)	/* Read-only data */
		. = ALIGN(4);
	} >ram

	. = ALIGN(4);
	_etext = .;

	.data : {
		_data = .;
		*(.data*)	/* Read-write initialized data */
		*(.sdata*) /* small data opt */
		__global_pointer$ = .;
		. = ALIGN(4);
		_edata = .;
	} >ram
	_data_loadaddr = LOADADDR(.data);

	.bss : {
		*(.bss*)	/* Read-write zero initialized data */
		*(.sbss*)
		*(COMMON)
		. = ALIGN(4);
		_ebss = .;
	} >ram

	. = ALIGN(4);
	end = .;
}

PROVIDE(_stack = ORIGIN(ram) + LENGTH(ram));
