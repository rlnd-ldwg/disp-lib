### Conditional assembling
To use the different version (4/8 bit, 3 wire serial) you have to customize the conditional assembling. Therefor exist three parameters:

- \_\_4BIT\_\_

  use the 4 bit interface, please note that the lower 4 bits needs pulldown's
- \_\_USE_4TO7\_\_

  only in 4 bit mode: use the upper 4 bits on the mcu port (bit 4 to 7 instead 0 to 3)
- \_\_3WIRE\_\_

  use the 3 wire serial interface based on a 74164 shift register, please not that you can not use this with the 4 bit mode of the lcd

 Source code block
 ```asm
; please uncomment the required one
;.set __4BIT__, true             ; if set the 4-bit interface of the display will be used
;.set __USE_4TO7__, true         ; if set the upper 4 bits (4-7) of the specified port will be used
;.set __3WIRE__, true            ; if set the 3-wire interface (74xx164) will be used
```
 ---
### Control bits
You must set the port bit for the following pins

#### 4 / 8 bit
* _RS

  Register Select (shared with serial data in 3 wire mode)
* _RW

  Read-write (not needed in 3 wire mode)
* _EN

  Enable
  
#### 3 wire interface
- _SD

  Serial data (shared with register select)
- _SC

  Serial clock
 
 Source code block
 ```asm
 ; define control bits
.equ _RS, 3     ; register select: data=1, control=0
.equ _RW, 5     ; read/write: read=1, write=0
.equ _EN, 4     ; enable: active high

; for 3-wire interface (using 8-bit shift register 74xx164)
.equ _SD, _RS   ; serial data (shared with lcd register select)
.equ _SC, _RW   ; serial clock (RW not needed in serial mode)
```
