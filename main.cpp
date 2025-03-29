#include <stdio.h>

extern "C" void MyPrintf(const char*, ...);
int main()
{
    const char* format = "str - %s\nchar - %c\nbin(100) - %b\noct(100) - %o\ndec - %d\nhex(100) - %x\n%s\nsigned (%d)\n$";
    const char* s1 = "_Hllw_wrld";
    const char* s2 = "Good day!";

    MyPrintf(format, s1, 'w', 100, 100, 100, 100, s2, -10);
    return 0;
}

