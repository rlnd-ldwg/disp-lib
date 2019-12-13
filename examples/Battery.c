#include <avr/io.h>
#include <hd44780.h>
#include <stdio.h>

char bat000 [] = {0x0e, 0x1f, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1f};
char bat020 [] = {0x0e, 0x1f, 0x11, 0x11, 0x11, 0x11, 0x1f, 0x1f};
char bat040 [] = {0x0e, 0x1f, 0x11, 0x11, 0x11, 0x1f, 0x1f, 0x1f};
char bat060 [] = {0x0e, 0x1f, 0x11, 0x11, 0x1f, 0x1f, 0x1f, 0x1f};
char bat080 [] = {0x0e, 0x1f, 0x11, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f};
char bat100 [] = {0x0e, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f, 0x1f};

int main(void) {
    initLCD();
    libinfo();

    newCHR(0, bat000);
    newCHR(1, bat020);
    newCHR(2, bat040);
    newCHR(3, bat060);
    newCHR(4, bat080);
    newCHR(5, bat100);

    _LCDCLEAR;
    for (;;) {
        printxyLCD(2, 1, "\0");
        mswait(500);
        printxyLCD(2, 1, "\1");
        mswait(500);
        printxyLCD(2, 1, "\2");
        mswait(500);
        printxyLCD(2, 1, "\3");
        mswait(500);
        printxyLCD(2, 1, "\4");
        mswait(500);
        printxyLCD(2, 1, "\5");
        mswait(500);
    }
}
