all: $(BUILD_DIR) old  c

BUILD_DIR = build

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

c: $(BUILD_DIR)/main.o $(BUILD_DIR)/MyPrintf.o
	g++ $(BUILD_DIR)/main.o $(BUILD_DIR)/MyPrintf.o -o MyPrintf -no-pie

$(BUILD_DIR)/MyPrintf.o: Myprintf.s
	nasm -f elf64 -o $(BUILD_DIR)/MyPrintf.o Myprintf.s

$(BUILD_DIR)/main.o: main.cpp
	g++ -c main.cpp -o $(BUILD_DIR)/main.o

old: $(BUILD_DIR)old.o
	ld -s -o old $(BUILD_DIR)old.o

$(BUILD_DIR)/old.o: ./old_version/old.s
	nasm -f elf64 -l $(BUILD_DIR)old.lst ./old_version/old.s
