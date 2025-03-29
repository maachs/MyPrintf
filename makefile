all: old & c

c: main.o MyPrintf.o
	g++ main.o MyPrintf.o -o MyPrintf -no-pie

MyPrintf.o: Myprintf.s
	nasm -f elf64 -o MyPrintf.o Myprintf.s

main.o: main.cpp
	g++ -c main.cpp -o main.o

old: old.o
	ld -s -o old old.o

old.o: old.s
	nasm -f elf64 -l old.lst old.s
