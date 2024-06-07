CROSS_COMPILE=

build:
	$(CROSS_COMPILE)gcc -g -Wall -c -o writer.o writer.c
	$(CROSS_COMPILE)gcc -g -Wall -I/ writer.o -o writer
all:
	$(CC) -g -Wall -c -o writer.o writer.c
	$(CC) -g -Wall -I/ writer.o -o writer
clean:
	rm -f *.o writer *.elf *.map
