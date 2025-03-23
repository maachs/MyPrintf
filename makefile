all: my_printf

my_printf: MyPrintf.o
	ld -s -o MyPrintf MyPrintf.o

MyPrintf.o: MyPrintf.s
	nasm -f elf64 -l MyPrintf.lst MyPrintf.s
