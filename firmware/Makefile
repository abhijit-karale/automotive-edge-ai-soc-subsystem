# Makefile for RV32I RISC-V Cross-Compilation

CROSS_COMPILE ?= riscv32-unknown-elf-
CC = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -I./driver
LDFLAGS = -nostdlib -Ttext 0x00000000

SRCS = apps/main.c driver/accel_driver.c
OBJS = $(SRCS:.c=.o)
TARGET = firmware.elf

all: $(TARGET) firmware.bin firmware.hex

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

firmware.bin: $(TARGET)
	$(OBJCOPY) -O binary $< $@

firmware.hex: $(TARGET)
	$(OBJCOPY) -O ihex $< $@

clean:
	rm -f $(OBJS) $(TARGET) firmware.bin firmware.hex

.PHONY: all clean
