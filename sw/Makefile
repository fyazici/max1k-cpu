# --- Compiler and Flags ---
PREFIX  ?= riscv32-unknown-elf
CC      := $(PREFIX)-gcc
LD      := $(PREFIX)-gcc
AR      := $(PREFIX)-ar
AS      := $(PREFIX)-as
SIZE    := $(PREFIX)-size
OBJCOPY := $(PREFIX)-objcopy
OBJDUMP := $(PREFIX)-objdump

CFLAGS  += -std=c99
CFLAGS  += -march=rv32im_zicsr -mabi=ilp32
CFLAGS  += -fno-common -ffunction-sections -fdata-sections 
CFLAGS  += -I./platform -I./doom
CFLAGS  += -O3
CFLAGS  += -DNORMALUNIX -DXTERM_VIDEO

LDFLAGS += --static -nostartfiles 
LDFLAGS += -Tplatform/lscript.ld
LDFLAGS += -march=rv32im_zicsr -mabi=ilp32
LDFLAGS += -Wl,-Map=$(TARGET).map -Wl,--cref
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group

LIBS    += -lm

# --- Target and Output Directories ---
TARGET    := bin/riscv_doom
OBJDIR    := obj

# --- Define Your Two Source Directories ---
SRCDIRS   := platform doom

# --- File Discovery and Mapping ---
# 1. Use wildcard to find all .c files inside both specified directories
SRCS      += platform/startup.S
SRCS      += $(foreach dir, $(SRCDIRS), $(wildcard $(dir)/*.c))

# 2. Map 'src/file.c' to 'obj/src/file.o' and 'lib/file.c' to 'obj/lib/file.o'
OBJS      += $(patsubst %.c, $(OBJDIR)/%.o, $(SRCS))

# --- Build Rules ---
.PHONY: all clean

all: size
	$(OBJDUMP) -ds $(TARGET).elf >$(TARGET)_dump.S

size: $(TARGET).size
elf: $(TARGET).elf
bin: $(TARGET).bin

%.size: %.elf %.bin
	@$(SIZE) -d $(*).elf | tee $(*).size

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

# Link the executable
$(TARGET).elf: $(OBJS)
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) $(OBJS) $(LIBS) -o $@

# Compile rule handles files from any source directory smoothly
# $(dir $@) ensures obj/src/ or obj/lib/ is created dynamically
$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up build artifacts
clean:
	rm -rf $(OBJDIR) bin/
