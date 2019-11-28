#include <stdio.h>
#include <hd44780.h>

int main (void) {

    char line [21];     // max 20 characters + \0
    int x = 12;
    float y = 12.34567;

    initLCD();
    // show library version and mode
    libinfo();

    printLCD("Hello World!");
    mswait(10000);
    writeLCD(_CTRL, _HOME);     // set cursor to home
    writeLCD(_CTRL, _CLEAR);    // clear Display
    sprintf (line, "Int: %d float: %2.2f", x, y);
    printLCD(line);
    mswait(10000);
}
