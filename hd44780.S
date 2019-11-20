; display library for HD44780 compatible LCD's
; copyright (c) Roland Ludwig 2012
;
; The library is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; Lesser General Public License for more details.
;
; You should have received a copy of the GNU Lesser General Public
; License along with this library; if not, write to the Free Software
; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;
; 2012-04-05 initial version
; 2019-09-10 redesign
; 2019-10-31 stable 4-bit version
; 2019-11-01 version 1.00 released
; 2019-11-15 possible usage of the upper 4 bits in 4 bit mode

; example LCD pin assignment Philips LTN211 (8bit/4bit)
; LCD pin     : 1   2   3   4   5   6   7   8   9   10  11  12  13  14
; Description : Vss Vdd Vo  RS  R/W E   D0  D1  D2  D3  D4  D5  D6  D7
; connected to: Gnd +5V Vco PC0 PC1 PC2 PD0 PD1 PD2 PD3 PD4 PD5 PD6 PD7
; connected to: Gnd +5V Vco PC0 PC1 PC2 Gnd Gnd Gnd Gnd PD0 PD1 PD2 PD3

.version "1.07 2019-11-20"

.set __4BIT__, true             ; if set the 4-bit interface of the display will be used
.set __USE_4TO7__, true         ; if set the upper 4 bits (4-7) of the specified port will be used
;.set __3WIRE__                 ; if set the 3-wire interface (74HCT164) will be used

.ifdef __4BIT__
    .warning "4-bit version: pins D0-D3 need pulldown to ground"
.endif
.ifdef __3WIRE__
	.warning "3-wire version: no display reading possible"
.endif

;.set __ATMEGA8__, true
.equ __F_CPU, 16000000
.equ _CTRL, 0
.equ _DATA, 1

; define control bits
.equ _RS, 0     ; register select: data=0, control=1
.equ _RW, 1     ; read/write: read=0, write=1
.equ _EN, 2     ; enable: active high

; pattern for DDR control port
.equ CtrlOut, (1<<_RS | 1<<_RW | 1<<_EN)

; for 3-wire interface (actually unused)
.equ _SD, _RS     ; serial data
.equ _SC, 1     ; shift register clock

; displays busy flag
.equ _BUSY, 7

; ATMEGA8 I/O register
.ifdef __ATMEGA8__
    .equ _PORTB, 0x18
    .equ _PINB, 0x16
    .equ _DDRB, 0x17
    .equ _PORTC, 0x15
    .equ _PINC, 0x13
    .equ _DDRC, 0x14
    .equ _PORTD, 0x12
    .equ _PIND, 0x10
    .equ _DDRD, 0x11
    .equ _SFIOR, 0x30   ; special function I/O register
    .equ _PUD, 0x02     ; pull up disable
.else                   ; ATMega 328, ATMega32u4
    .equ _PORTB, 0x05
    .equ _PINB, 0x03
    .equ _DDRB, 0x04
    .equ _PORTC, 0x08
    .equ _PINC, 0x06
    .equ _DDRC, 0x07
    .equ _PORTD, 0x0b
    .equ _PIND, 0x09
    .equ _DDRD, 0x0a
    .equ _PORTE, 0x0e
    .equ _PINE, 0x0c
    .equ _DDRE, 0x0d
    .equ _PORTF, 0x11
    .equ _PINF, 0x0f
    .equ _DDRF, 0x10
.endif

; for better readability
.equ DataDDR, _DDRD
.equ DataWrite, _PORTD
.equ DataRead, _PIND
.equ CtrlDDR, _DDRB
.equ CtrlWrite, _PORTB
.equ CtrlRead, _PINB

; pattern for DDR data port
.ifdef __4BIT__
    .ifndef __USE_4TO7__
        .equ DataOut, 0x0f
        .equ DataIn,  0xf0
    .else
        .equ DataOut, 0xf0
        .equ DataIn,  0x0f
    .endif
.else
    .equ DataOut, 0xff
    .equ DataIn,  0x00
.endif

;calculate counter for delay loop
    .ifndef __F_CPU                         ; if not set
    .equ __F_CPU, 12000000                  ; set to 12MHz systemclock
.endif
.equ Cfactor, 2                             ; correction factor
.equ Dloop, (__F_CPU / 4 / 1000) - Cfactor  ; loop counter

.data

Version:
    .asciz "1.07(2019-11-20)"
Mode:
.ifdef __4BIT__
    .ifndef __USE_4TO7__
        .asciz "4 bit mode (0-3)"
    .else
        .asciz "4 bit mode (4-7)"
    .endif
.else
    .asciz "8 bit mode"
.endif

InitSequence:
.ifdef __4BIT__
    .byte 0x28, 0x01, 0x0c, 0x80    ; 4-bit mode|clear display|display on, cursor off, cursor doesn't blink|DD-RAM address=0
.else
    .byte 0x38, 0x01, 0x0c, 0x80    ; 8-bit mode|clear display|display on, cursor off, cursor doesn't blink|DD-RAM address=0
.endif

LineAddress:
    .byte 0x00, 0x40, 0x10, 0x50    ; line # 1, 2, 3, 4

.text

.global initLCD
.func initLCD           ; void initLCD(void)

initLCD:
    push r25
    push r24

    in r24, CtrlDDR     ; switch control port to output
    ori r24, CtrlOut
    out CtrlDDR, r24

    ldi r24, 20         ; wait 15ms
    clr r25
    rcall mswait
    ldi r22, 0x30       ; first init sequence
    clr r24
    rcall writeLCD
    ldi r24, 5          ; wait 5ms (min 4.1ms)
    clr r25
    rcall mswait
    ldi r22, 0x30       ; first init sequence
    clr r24
    rcall writeLCD
    ldi r24, 1          ; wait 1ms (min 0.1ms)
    clr r25
    rcall mswait
    clr r24
    ldi r22, 0x30       ; first init sequence
    rcall writeLCD

    lds r22, InitSequence   ; send initialization sequence
    rcall writeLCD
    lds r22, InitSequence+1
    rcall writeLCD
    lds r22, InitSequence+2
    rcall writeLCD
    lds r22, InitSequence+3
    rcall writeLCD

    pop r24
    pop r25
    ret
.endfunc                ; initLCD

.global libinfo
.func libinfo           ; void libinfo(void)

libversion:
    push r25
    push r24
    push r22
    clr r24
    ldi r22, 0x01
    rcall writeLCD
    clr r24
    ldi r22, 0x02
    rcall writeLCD
    ldi r24, lo8(Version)
    ldi r25, hi8(Version)
    rcall printLCD
    ldi r24, 0xd0       ; wait 2000ms
    ldi r25, 0x07
    rcall mswait
    clr r24
    ldi r22, 0x01
    rcall writeLCD
    clr r24
    ldi r22, 0x02
    rcall writeLCD
    ldi r24, lo8(Mode)
    ldi r25, hi8(Mode)
    rcall printLCD
    ldi r24, 0xd0       ; wait 2000ms
    ldi r25, 0x07
    rcall mswait
    clr r24
    ldi r22, 0x01
    rcall writeLCD
    pop r22
    pop r24
    pop r25
    ret
.endfunc                ; libinfo

.global writeLCD
.func writeLCD          ; void writeLCD (char rs -> r24, char data -> r22)

writeLCD:
    push r26            ; save register
    push r25
    push r24

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
    cbi CtrlWrite, _RW

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
    rcall wait
    cbi CtrlWrite, _EN

    rcall wait          ; -> 8 cycles min. 1000ns enable cycle time min
.ifdef __USE_4TO7__
    swap r22            ; lower nibble -> to bit 4-7
.endif
    andi r22, DataOut   ; mask lower nibble
    or r22, r25         ; chain data higher nibble

    out DataWrite, r22  ; write lower nibble
    sbi CtrlWrite, _EN
    rcall wait
    cbi CtrlWrite, _EN
.else ; write 8 bit data
    sbi CtrlWrite, _EN
    out DataWrite, r22
    rcall wait
    cbi CtrlWrite, _EN
.endif

    rcall wait
    pop r25             ; restore register
    pop r26
    ret
.endfunc                ; writeLCD

.global readLCD
.func readLCD           ; char readLCD (char rs -> r24) -> r24

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

.global printLCD
.func printLCD          ; void printLCD (const char *text -> r24:r25)

printLCD:
    push r31            ; save register
    push r30
    push r22

    movw r30, r24       ; startadress string => R30:31 (Z)
    ldi r24, 0x01       ; select data register

nextChar:
    ld  r22, Z+
    tst r22             ; end fo text?
    breq textEnd
    rcall writeLCD
    rjmp nextChar

textEnd:
    pop r22
    pop r30
    pop r31
    ret
.endfunc                ; printLCD

.local wait
wait:
;   rcall wait          ; 3
    ret                 ; 4
; 10 cyles * 50ns (at 20MHz) equates 500ns

.global mswait          ; function mswait(uint16_t ms)
.func mswait            ; void mswait (const int ms -> r24:r25)

mswait:
        push r26        ; save register
        push r27
l3:
        sbiw r24, 1     ; decrement double register
        brcc l1         ; wait 1 ms
        pop r27         ; restore register
        pop r26
        ret
l1:
        nop
        ldi     r26, lo8(Dloop)
        ldi     r27, hi8(Dloop)
l2:
        sbiw    r26, 1
        brne    l2
        rjmp l3
.end                    ; mswait

;
; old stuff, to be reviewed
; ##################################################
; function void LCD_CursorOn(char blink)
; parameters: blink => r24
; ##################################################

.global LCD_CursorOn
.type LCD_CursorOn, @function

LCD_CursorOn:
        push r24            ; save register
        push r22

        ldi r22, 0x0e       ; display on, cursor on
        add r22, r24        ; cursor blink ?
        clr r24
        rcall writeLCD

        pop r22
        pop r24             ; restore register
        ret

; ##################################################
; function void LCD_CursorOff
; parameters: none
; ##################################################

.global LCD_CursorOff
.type LCD_CursorOff, @function

LCD_CursorOff:
        push r24            ; save register
        push r22

        ldi r22, 0x0a       ; display on, cursor off
        clr r24
        rcall writeLCD

        pop r22
        pop r24             ; restore register
        ret

; ##################################################
; function void LCD_SetCursor(char X, char Y)
; parameters: X column => r24, Y line => r22 zeile, spalte
; ##################################################

.global LCD_SetCursor
.type LCD_SetCursor, @function

LCD_SetCursor:
        push r26            ; save register
        push r27
        push r17
        push r16

        dec r24             ; pos 1 => 0
        dec r22             ; pos 1 => 0
        breq .line1         ; 0 => 1st line
        lds r17, LineAddress+1
        add r24, r17        ; calculate RAM adress for 2nd line
.line1:
        mov r22, r24        ; absolute RAM adress => r24
        clr r24        ; write control
        ori r22, 0x80       ; DD RAM adress set
        rcall writeLCD

        pop r16
        pop r17
        pop r27
        pop r26             ; restore register
        ret

; ##################################################
; function void LCD_Off (void)
; parameters: none
; ##################################################

.global LCD_Off
.type LCD_Off, @function

LCD_Off:
        push r22                ; save register
        push r24

        clr r24            ; select control register
        ldi r22, 0x04           ; switch display off
        rcall writeLCD

        pop r24
        pop r22
        ret

; ##################################################
; function void DisplayOon (void)
; parameters: none
; ##################################################

.global LCD_On
.type LCD_On, @function

LCD_On:
        push r22                ; save register
        push r24

        clr r24            ; select control register
        ldi r22, 0x06           ; switch display on
        rcall writeLCD

        pop r24
        pop r22
        ret
