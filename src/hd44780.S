; display library for HD44780 compatible LCD's
; copyright (c) 2012 Roland Ludwig
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

; v1.2.6 2020-01-14
; for complete history see HISTORY.md

;---------------------------- user parameter area -------------------------------
; include appropriate file
; you can convert the files from https://github.com/DarkSector/AVR/tree/master/asm/include using atmel2gnu.py

.include "../inc/tn13def.inc"
;.set __F_CPU, 12000000

#include "delay.asm"

;.include "/Users/roland/Projects/inc/m8def.inc"
;.include "/Users/roland/Projects/inc/m328def.inc"

;.set __INFO__, true             ; include "libinfo" function
;.set __4BIT__, true             ; if set the 4-bit interface of the display will be used
;.set __USE_4TO7__, true         ; if set the upper 4 bits (4-7) of the specified port will be used
.set __3WIRE__, true            ; if set the 3-wire interface (74xx164) will be used
.set __USE_FLASH__, true        ; use flash memory as source for "newCHR" (this will save your RAM)
.set __1LINE_LCD__, true        ; set this for lcd's with only one line

; port definition
.equ DataDDR, DDRB
.equ DataWrite, PORTB
.equ DataRead, PINB
.equ CtrlDDR, DDRB
.equ CtrlWrite, PORTB
.equ CtrlRead, PINB

; define control bits
.equ _RS, 1     ; register select: data=1, control=0
.equ _RW, 7     ; read/write: read=1, write=0
.equ _EN, 2     ; enable: falling edge
; only for 3-wire interface
.equ _SD, _RS   ; serial data (shared with lcd register select)
.equ _SC, 4     ; serial clock, RW bit can be used
;--------------------------------------------------------------------------------

; for 3-wire interface (using 8-bit shift register 74xx164)
.ifdef __3WIRE__
    .warning "3-wire version: no display reading possible"
    .equ CtrlOut, (1<<_RS | 1<<_EN | 1<<_SC)   ; pattern for DDR control port
.else
    .equ CtrlOut, (1<<_RS | 1<<_RW | 1<<_EN)   ; pattern for DDR control port
    .equ _BUSY, 7                              ; displays busy flag
.endif

.ifdef __4BIT__                 ; pattern for DDR data port
    .warning "4-bit version: pins D0-D3 need pulldown to ground"
    .ifdef __USE_4TO7__
        .equ DataOut, 0xf0
        .equ DataIn,  0x0f
    .else
        .equ DataOut, 0x0f
        .equ DataIn,  0xf0
    .endif
    .ifdef __3WIRE__
        .error "you can't use 3-wire in combination with 4-bit interface"
    .endif
.else
    .equ DataOut, 0xff
    .equ DataIn,  0x00
.endif

.equ _CTRL, 0
.equ _DATA, 1


;calculate counter for delay loop
;.ifndef __F_CPU                             ; if not set
;    .equ __F_CPU, 12000000                  ; set to 12MHz systemclock
;.endif

;.equ Cfactor, 2                             ; correction factor
;.equ Dloop, (__F_CPU / 4 / 1000) - Cfactor  ; loop counter

; init parameters
.ifdef __1LINE_LCD__
    .equ _4bit,  0b00100000 ; 4 bit, one line, 5x7
    .equ _8bit,  0b00110000 ; 8 bit, one line, 5x7
.else
    .equ _4bit,  0b00101000 ; 4 bit, multiple lines, 5x7
    .equ _8bit,  0b00111000 ; 8 bit, multiple lines, 5x7
.endif
.equ clear,  0b00000001 ; clear display
.equ dpctrl, 0b00001100 ; display on, cursor off, blink off

; macro section

.macro _DP_CTRL cmd
    ldi r22, \cmd
    clr r24
    rcall writeLCD
.endm

.macro _PRINT text
    ldi r24, lo8(\text)
    ldi r25, hi8(\text)
    rcall printLCD
.endm

.macro _CLEAR_LCD
    clr r24
    ldi r22, 0x01
    rcall writeLCD
.endm

.data
.ifdef __INFO__
Version:
    .asciz "1.2.6 2020-01-14"
Mode:
    .ifdef __4BIT__
        .ifndef __USE_4TO7__
            .asciz "4 bit mode (0-3)"
        .else
            .asciz "4 bit mode (4-7)"
        .endif
    .else
        .ifdef __3WIRE__
            .asciz "3 wire interface"
        .else
            .asciz "8 bit mode (0-7)"
        .endif
    .endif
.endif

.text

LineAddress:
    .byte 0x00, 0x40, 0x10, 0x50    ; line # 1, 2, 3, 4 (16x?)

.global initLCD
.func initLCD           ; void initLCD(void)

initLCD:
    push r25
    push r24

    in r24, CtrlDDR     ; switch control port to output
    ori r24, CtrlOut
    out CtrlDDR, r24

    _DELAY_US 15000
    _DP_CTRL 0x30
    _DELAY_US 4100
    _DP_CTRL 0x30
    _DELAY_US 100
    _DP_CTRL 0x30
.ifdef __4BIT__
    _DP_CTRL 0x20
    _DP_CTRL _4bit
.else
    _DP_CTRL _8bit
.endif
    _DP_CTRL dpctrl     ; display on, cursor off, blink off
    _DP_CTRL clear

    pop r24
    pop r25
    ret
.endfunc                ; initLCD

.ifdef __INFO__
    .global libinfo
    .func libinfo           ; void libinfo(void)

    libinfo:
        push r25
        push r24
        push r22

        _DP_CTRL clear
        _PRINT Version
        _DELAY_MS 1500
        _DP_CTRL clear
        _PRINT Mode
        _DELAY_MS 1500
        _DP_CTRL clear

        pop r22
        pop r24
        pop r25
        ret
    .endfunc                ; libinfo
.endif

.global writeLCD
.func writeLCD          ; void writeLCD(char rs -> r24, char data -> r22)

writeLCD:
    push r26            ; save register
    push r25
    push r24
.ifndef __3WIRE__
wait4Disp:
    clr r24             ; set r24 to 0 => control for LCD_ReadData
    rcall readLCD
    sbrc r24, _BUSY     ; wait until display is ready
    rjmp wait4Disp

    pop r24
    tst r24             ; control or data register
    brne selectDataW
    cbi CtrlWrite, _RS
    rjmp selectCtrlW
selectDataW:
    sbi CtrlWrite, _RS
selectCtrlW:

    cbi CtrlWrite, _RW  ; set write mode
    in r26, DataDDR     ; switch data port to output
    ori r26, DataOut
    out DataDDR, r26

    .ifdef __4BIT__
        in r25, DataWrite
        andi r25, DataIn    ; mask unused bits
        mov r26, r22        ; data => r26
        .ifndef __USE_4TO7__
            swap r26            ; swap higher nibble to bit 0-3
        .endif
        andi r26, DataOut   ; mask higher nibble
        or r26, r25         ; chain data lower nibble

        out DataWrite, r26  ; write higher nibble
        sbi CtrlWrite, _EN
        nop                 ; Enable puls wide 300ns at 20MHz
        nop
        nop
        nop
        cbi CtrlWrite, _EN

        rcall wait          ; -> 8 cycles min. 1000ns enable cycle time min
        .ifdef __USE_4TO7__
            swap r22        ; lower nibble -> to bit 4-7
        .endif
        andi r22, DataOut   ; mask lower nibble
        or r22, r25         ; chain data higher nibble
    .endif                  ; __4BIT__
    out DataWrite, r22      ; 4/8 bit

.else                   ; __3WIRE__
    ldi r24, 2         ; no busy flag, wait 2ms
    clr r25
    rcall mswait
; ************************* using hardware SPI
    ldi r26, 8          ; shift 8 bit
.shiftloop:
    cbi CtrlWrite, _SC  ; set clock to low
    lsl r22             ; shift bit to carry
    brcc .bitclr        ; carry == 0 => shift '0'
    sbi CtrlWrite, _SD  ; shift '1'
    rjmp .nxtbit
.bitclr:
    cbi CtrlWrite, _SD
    .nxtbit:
    sbi CtrlWrite, _SC  ; rising edge to shift
    dec r26
    brne .shiftloop     ; all bits done ?

    pop r24
    tst r24             ; control or data register
    brne select2DataW
    cbi CtrlWrite, _RS
    rjmp select2CtrlW
select2DataW:
    sbi CtrlWrite, _RS
select2CtrlW:
.endif                  ; __3WIRE__
    sbi CtrlWrite, _EN
    nop                 ; Enable puls wide 300ns at 20MHz
    nop
    nop
    nop
    cbi CtrlWrite, _EN

    pop r25
    pop r26
    ret
.endfunc                ; writeLCD

.global readLCD
.func readLCD           ; char readLCD(char rs -> r24) -> r24

readLCD:
    push r25            ; save register

    tst r24             ; control or data register
    brne selectDataR
    cbi CtrlWrite, _RS
    rjmp selectCtrlR
selectDataR:
    sbi CtrlWrite, _RS
selectCtrlR:
    sbi CtrlWrite, _RW

    in r24, DataDDR     ; switch data port to input
    andi r24, DataIn
    out DataDDR, r24

; read data
    sbi CtrlWrite, _EN
    rcall wait
    in r24, DataRead    ; in 4 bit mode higher nibble -> bit 0-3 !!!
    cbi CtrlWrite, _EN

.ifdef __4BIT__
    sbi CtrlWrite, _EN
    rcall wait
    in r25, DataRead    ; lower nibble
    cbi CtrlWrite, _EN
    rcall wait
    .ifndef __USE_4TO7__
        swap r24            ; bits 0-3 used -> swap r24 to higher nibble
    .else
        swap r25            ; bits 4-7 used -> swap r25 to lower nibble
    .endif
    andi r24, 0xf0
    andi r25, 0x0f
    or r24, r25
.endif

    rcall wait
    pop r25             ; restore register
    ret
.endfunc                ; readLCD

.global printxyLCD
.func printxyLCD        ; void printxyLCD(char x -> r24, y -> r22; const char *text -> r20:r21)

printxyLCD:
    push r31
    push r30

    dec r24             ; pos 1 => 0
    dec r22             ; pos 1 => 0
    ldi r30, lo8(LineAddress)
    ldi r31, hi8(LineAddress)
    add r30, r22        ; calculate lineaddress
    clr r22
    adc r31, r22        ; add carry if neccesarry
;    ld r22, Z           ; lineaddress -> r22
    lpm r22, Z           ; lineaddress -> r22
    add r22, r24        ; lineaddress + column (r24)
    clr r24             ; write control
    ori r22, 0x80       ; set DDRAM address
    rcall writeLCD
    movw r30, r20       ; startadress string => R30:31 (Z)
    push r22            ; needed for correct "pop" in printLCD
    rjmp .printLCD      ; jump to printLCD
.endfunc                ; printxyLCD

.global printLCD
.func printLCD          ; void printLCD(const char *text -> r24:r25)

printLCD:
    push r31            ; save register
    push r30
    push r22

    movw r30, r24       ; startadress string => R30:31 (Z)
.printLCD:
    ldi r24, 0x01       ; select data register
nextChar:
    ld  r22, Z+
    tst r22             ; end of text?
    breq textEnd
    rcall writeLCD
    rjmp nextChar
textEnd:

    pop r22
    pop r30
    pop r31
    ret
.endfunc                ; printLCD

.global newCHR
.func newCHR            ; void newCHR(char addr -> r24, const char *text -> r22:r23)
newCHR:
    push r25

    lsl r24         ; r24 * 8
    lsl r24
    lsl r24
    ori r24, 0x40   ; calculate CGRAM address
    movw r30, r22   ; startaddress character => R30:R31 (Z)
    mov r23, r24    ; r24 -> rs
    ldi r25, 8      ; shift 8 bit
.shift2loop:
    clr r24         ; RS -> ctrl
    mov r22, r23    ; CGRAM address
    rcall writeLCD
    ldi r24, 0x01   ; RS - data
.ifdef __USE_FLASH__
    lpm r22, Z+     ; character[Z] -> r22
.else
    ld r22, Z+      ; character[Z] -> r22
.endif
    rcall writeLCD
    inc r23         ; CGRAM address counter
    dec r25
    brne .shift2loop     ; all bits done ?

    pop r25
    ret
.endfunc                ; newCHR

.local wait
wait:
;   rcall wait          ; 3
    push r22
    pop r22
    ret                 ; 4
; 7 cyles * 50ns (at 20MHz) equates 350ns

.end
