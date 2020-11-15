; library for MAX7221/MAX7219 display driver (7-segment)
; copyright (c) 2020 Roland Ludwig
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

; v0.1.0 2020-11-11
; v0.2.0 2020-11-14 SPI transfer
; v0.3.1 2020-11-15 initialize display function, macro for display commands
; for complete history see HISTORY.md

;---------------------------- user parameter area -------------------------------
; include appropriate file
; you can convert the files from https://github.com/DarkSector/AVR/tree/master/asm/include using atmel2gnu.py

;.include "../inc/tn13def.inc"
;.set __F_CPU, 12000000

;#include "delay.asm"

;.include "/Users/roland/Projects/inc/m8def.inc"
.include "/Users/roland/Projects/inc/m328Pdef.inc"

.set __SPI_HWI__, true      ; use SPI hardware interface

; port definition
.equ DataDDR, DDRB
.equ DataWrite, PORTB

; define control bits
.equ MOSI, PB3  ; data
.equ SS_, PB2   ; chip select, data latched at rising edge
.equ SCK, PB5   ; clock, shift on rising edge

; control registers
.equ _mode_reg, 0x09
.equ _intensity_reg, 0x0a
.equ _scanlimit_reg, 0x0b   ; number of segments
.equ _operation_reg, 0x0c
.equ _test_reg, 0x0f

; initial led parameters, you can overwrite them later
.equ _active_segments, 7    ; number of segments decremnet by one
.equ _intensity, 3
.equ _all_as_bcd, 0xff      ; decode all segments as BCD

; Code B: 0..9 -> "0".."9", 10 -> -, 11 -> E, 12 -> H, 13 -> L 14 -> P, 15 -> "blank"

; hex char set
.equ HEX0, 0x7e
.equ HEX1, 0x30
.equ HEX2, 0x6d
.equ HEX3, 0x79
.equ HEX4, 0x33
.equ HEX5, 0x5b
.equ HEX6, 0x5f
.equ HEX7, 0x70
.equ HEX8, 0x7f
.equ HEX9, 0x7b
.equ HEXA, 0x77
.equ HEXB, 0x1f
.equ HEXC, 0x4e
.equ HEXD, 0x3d
.equ HEXE, 0x4f
.equ HEXF, 0x47
.equ DASH, 0x01

; macro section

.macro _WRITE_CMD reg cmd
    ldi r24, \reg
    ldi r22, \cmd
    rcall writeLED
.endm

.data
.ifdef __INFO__
Version:
    .asciz "0.3.1"
.endif

.text

.global initLED
.func initLED           ; void initLCD(void)

initLED:
    push r24
    push r22

    in r24, DataDDR     ; switch SPI ports to output
    ori r24, (1<<MOSI) | (1<<SCK) | (1<<SS_)
    out DataDDR, r24
    sbi DataWrite, SS_  ; disable slave select

    .ifdef __SPI_HWI__  ; initialize SPI interface
        ldi r24, (1<<SPE) | (1<<MSTR)   ; no interrupts, MSB firts, AVR is master, clock resting state is low, rising edge, clock is half xtal
        out SPCR, r24
        ldi r24, 1
        out SPSR, r24   ; set double Speed
        ldi r24, 0x55   ; write dummy data to set SPIF
        out SPDR, r24
    .endif

    _WRITE_CMD _operation_reg 1 ; normal operation
    _WRITE_CMD _test_reg 0      ; test mode off
    _WRITE_CMD _scanlimit_reg _active_segments
    _WRITE_CMD _intensity_reg _intensity
    _WRITE_CMD _mode_reg _all_as_bcd

    _WRITE_CMD 0x01 0x01    ; version
    _WRITE_CMD 0x02 0x83
    _WRITE_CMD 0x03 0x80

    pop r22
    pop r24
.endfunc                ; initLED

.global writeLED
.func writeLED          ; void writeLED(char reg -> r24, char data -> r22)

writeLED:
    cbi DataWrite, SS_  ; set slave select to low
    .ifdef __SPI_HWI__  ; send data to Display
        rcall shiftSPI
    .else
        rcall shift8bit
    .endif
    mov r24, r22        ; send second byte
    .ifdef __SPI_HWI__  ; send register to Display
        rcall shiftSPI
        .wait2:
            in r22, SPSR    ; waiting for transmission bevor
            sbrs r22, SPIF
            rjmp .wait2
    .else
        rcall shift8bit
    .endif

    sbi DataWrite, SS_  ; transfer data
    ret
.endfunc                ; writeLED

.local shiftSPI
.func shiftSPI

shiftSPI:
    push r25
.wait:
;    sbis SPSR, SPIF     ; waiting for old transmission
    in r25, SPSR
    sbrs r25, SPIF
    rjmp .wait

    out SPDR, r24
    pop r25
    ret
.endfunc                ; shiftSPI

.local shift8bit
.func shift8bit

shift8bit:

    push r25
    ldi r25, 8          ; shift 8 bit
.shiftloop:
    cbi DataWrite, SCK ; set clock to low
    lsl r24             ; shift MSB to carry, MAX72xx expects the MSB at first
    brcc .bitclr        ; carry == 0 => shift '0'
    sbi DataWrite, MOSI ; shift '1'
    rjmp .nxtbit
.bitclr:
    cbi DataWrite, MOSI
.nxtbit:
    nop
    sbi DataWrite, SCK ; rising edge to shift
    dec r25
    brne .shiftloop     ; all bits done ?

    pop r25
    ret

.endfunc                ; shift8bit

.end
