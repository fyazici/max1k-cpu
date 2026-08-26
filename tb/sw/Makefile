OBJS = startup.o  platform.o coremark/ee_printf.o coremark/core_portme.o coremark/cvt.o coremark/core_util.o coremark/core_list_join.o coremark/core_state.o coremark/core_matrix.o coremark/core_main.o

# Our output name
BINARY = core_main

LDSCRIPT = lscript.ld

# Target-specific flags
FP_FLAGS    ?= 
ARCH_FLAGS   = -march=rv32i_zicsr -mabi=ilp32 $(FP_FLAGS)

# Compiler configuration
PREFIX      ?= riscv32-unknown-elf
CC          := $(PREFIX)-gcc
LD          := $(PREFIX)-gcc
AR          := $(PREFIX)-ar
AS          := $(PREFIX)-as
SIZE        := $(PREFIX)-size
OBJCOPY     := $(PREFIX)-objcopy
OBJDUMP     := $(PREFIX)-objdump
GDB         := $(PREFIX)-gdb
OPT         := -O2
DEBUG       := 
CSTD        ?= -std=c99

# C flags
TGT_CFLAGS  += $(OPT) $(CSTD) $(DEBUG)
TGT_CFLAGS  += $(ARCH_FLAGS)
TGT_CFLAGS  += -Wall -Wextra -Wshadow -Wimplicit-function-declaration
TGT_CFLAGS  += -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
TGT_CFLAGS  += -fno-common -ffunction-sections -fdata-sections
TGT_CFLAGS  += -I./ -Icoremark/
TGT_CFLAGS  += -Wno-unused-parameter

# C preprocessor common flags
TGT_CFLAGS    += -MD
TGT_CFLAGS    += -Wall -Wundef
TGT_CFLAGS    += $(DEFS)

# Linker flags
TGT_LDFLAGS     += --static -nostartfiles
TGT_LDFLAGS     += -T$(LDSCRIPT)
TGT_LDFLAGS     += $(ARCH_FLAGS) $(DEBUG)
TGT_LDFLAGS     += -Wl,-Map=$(*).map -Wl,--cref
TGT_LDFLAGS     += -Wl,--gc-sections

# Used libraries
# DEFS        += -DPRINTF_INCLUDE_CONFIG_H=0 
# DEFS        += -DPRINTF_ALIAS_STANDARD_FUNCTION_NAMES_SOFT=0 
# DEFS        += -DPRINTF_ALIAS_STANDARD_FUNCTION_NAMES_HARD=0
# DEFS        += -DPRINTF_SUPPORT_MSVC_STYLE_INTEGER_SPECIFIERS=0
# DEFS        += -DPRINTF_SUPPORT_DECIMAL_SPECIFIERS=0
# DEFS        += -DPRINTF_SUPPORT_EXPONENTIAL_SPECIFIERS=0
# DEFS        += -DPRINTF_SUPPORT_WRITEBACK_SPECIFIER=0
DEFS        += -DCORE_DEBUG=0 -DPERFORMANCE_RUN=1 -DITERATIONS=200
LDFLAGS     +=
LDLIBS      += 
LDLIBS      += -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

all: size
	$(OBJDUMP) -ds $(BINARY).elf >$(BINARY)_dump.S

size: $(BINARY).size
elf: $(BINARY).elf
bin: $(BINARY).bin
map: $(BINARY).map

GENERATED_BINARIES=$(BINARY).elf $(BINARY).bin $(BINARY).map $(BINARY).size $(BINARY).mif $(BINARY)_dump.S

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin
	./bin2mif $(*).bin


%.elf %.map: $(OBJS) $(LDSCRIPT)
	$(LD) $(TGT_LDFLAGS) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $(*).elf

%.o: %.c
	$(CC) $(TGT_CFLAGS) $(CFLAGS)  -o $(*).o -c $(*).c

%.size: %.elf %.bin
	@$(SIZE) -d $(*).elf | tee $(*).size

clean:
	$(RM) $(GENERATED_BINARIES) generated.* $(OBJS) $(OBJS:%.o=%.d)

.PHONY: clean flash
