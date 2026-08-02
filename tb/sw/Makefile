OBJS = main.o startup.o

# Our output name
BINARY = main

LDSCRIPT = lscript.ld

# Target-specific flags
FP_FLAGS    ?= 
ARCH_FLAGS   = -march=rv32i -mabi=ilp32 $(FP_FLAGS)

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
OPT         := -Os
DEBUG       := 
CSTD        ?= -std=c99

# C flags
TGT_CFLAGS  += $(OPT) $(CSTD) $(DEBUG)
TGT_CFLAGS  += $(ARCH_FLAGS)
TGT_CFLAGS  += -Wextra -Wshadow -Wimplicit-function-declaration
TGT_CFLAGS  += -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
TGT_CFLAGS  += -fno-common -ffunction-sections -fdata-sections

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
DEFS        += 
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
	./bin2mif


%.elf %.map: $(OBJS) $(LDSCRIPT)
	$(LD) $(TGT_LDFLAGS) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $(*).elf

%.o: %.c
	$(CC) $(TGT_CFLAGS) $(CFLAGS)  -o $(*).o -c $(*).c

%.size: %.elf %.bin
	@$(SIZE) -d $(*).elf | tee $(*).size

clean:
	$(RM) $(GENERATED_BINARIES) generated.* $(OBJS) $(OBJS:%.o=%.d)

.PHONY: clean flash
