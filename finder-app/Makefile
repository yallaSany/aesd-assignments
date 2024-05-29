#if the cross_compile environment variable is not set in the system, native will be used instead
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld

CFLAGS = -Wall -g

writer: writer.o
	$(CC) -o $@ $^

%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

clean:
	rm -f writer $(wildcard *.o)
