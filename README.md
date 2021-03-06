# display-library
Small, fast library written in AVR assembler.

Can be used with standard C/C++ compilers, ARDUINO or pure assembler programming

* for HD44780 compatible LCD's, support for
  * 8/4 bit interface
  * 3 wire serial interface based on 74HCT164
  ![Circuit](https://github.com/rlnd-ldwg/disp-lib/blob/master/circuit.png)
* for LED MAX7221 driver (not yet implemented)

### Mandatory settings
The following bit constants must be set in the source-file:

#### 4 / 8 bit mode
* *_RS* Register Select (shared with serial data in 3 wire mode)
* *_RW* Read-write (not needed in 3 wire mode)
* *_EN* Enable

#### 3 wire interface
* *_SD* Serial data (shared with register select)
* *_SC* Serial clock

 Example:
 ```asm
 ; define control bits
.equ _RS, 3     ; register select: data=1, control=0
.equ _RW, 5     ; read/write: read=1, write=0
.equ _EN, 4     ; enable: active high

; for 3-wire interface (using 8-bit shift register 74xx164)
.equ _SD, _RS   ; serial data (shared with lcd register select)
.equ _SC, _RW   ; serial clock (RW not needed in serial mode)
```
### Functions HD44780

#### initLCD(void)
This function initializes the display. You can choose the mode in the source-file (hd44780.S) by commenting out the required assembler definitions:
```asm
;.set __4BIT__, true             ; if set the 4-bit interface of the display will be used
;.set __USE_4TO7__, true         ; if set the upper 4 bits (4-7) of the specified port will be used
;.set __3WIRE__, true            ; if set the 3-wire interface (74xx164) will be used
```
#### libinfo(void)
An info about the library version and mode will be displayed.

#### writeLCD(char rs, char data)
The writeLCD function send the **data** to the selected register **rs**=0 => control or **rs**=1 => data

#### char readLCD(char rs)
Reads the data from selected register **rs**=0 => control or **rs**=1 => data

#### printxyLCD(char x, char y, const char *text)
The given **text** is display at column **x** and row **y**. The numbering starts at '1'.

#### printLCD(const char *text)
Same as above, but prints at current cursor position.

#### newCHR(char addr, const char *character)
Creates an new character in CGRAM. You can define 8 independent characters, the numbering starts at **addr** '0'.
The function expects an array for **\*character** in the following format:
```C
.byte 0x0e, 0x1f, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1f
```
```C
char data[] = {0x0e, 0x1f, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1f};
```
The example shows a battery :wink:.

#### mswait(int ms)
This functions waits for **ms** milliseconds.  

You can adapt the settings in include/delay.asm, to find the best values DelayCalc.ods can help you.
Simply enter the CPU frequency and the desired delay,
the best correction factor can then be found out by trial and error.
Hint: Look at the field with the deviation.

Note: The sheet is locked, values can only be entered in the green fields.

#### uswait(int us)
Same as above but waits for **us** microseconds.  

This function works only with 6, 12, 16 and 20 MHz correct.

#### wait (local hd44780.S)
Internal wait for some display functions.
