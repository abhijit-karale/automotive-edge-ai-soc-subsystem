# Makefile for DPI-C Golden Reference Model Shared Library

CC = gcc
CFLAGS = -fPIC -O3 -Wall -I.
LDFLAGS = -shared

TARGET = libaccel_ref.so
SRCS = accel_ref_model.c
OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
