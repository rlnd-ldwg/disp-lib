; delay.asm
; precise delay routines in µs/ms for AVR mcu's
;
; copyright (c) 2019 Roland Ludwig
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

.print "v0.1.1 2020-01-20"

; AVR register
;.include "../inc/m8def.inc"
;.include "../inc/m328def.inc"
.include "../inc/tn13def.inc"

;calculate counter for delay loop
.ifndef __F_CPU                             ; if not set
    .equ __F_CPU, 12000000                  ; set to 12MHz systemclock
.endif

.equ Cfactor, 2                             ; correction factor
.equ Dloop, (__F_CPU / 4 / 1000) - Cfactor  ; loop counter

.if (__F_CPU == 6000000)        ; clock 6MHz
    .warning "6MHz"
    .macro _DELAY_US us
        .if (\us - 1)
            .set cycles, (\us - 1)
            ldi r24, lo8(cycles)
            ldi r25, hi8(cycles)
            rcall uswait
        .else
            nop
            nop
            nop
            nop
            nop
            nop
        .endif
    .endm
.elseif (__F_CPU >= 12000000)   ; clock 12MHz+
    .warning "12MHz+"
    .macro _DELAY_US us
        ldi r24, lo8(\us)
        ldi r25, hi8(\us)
        rcall uswait
    .endm
.endif
; .endif

.macro _DELAY_MS ms
    ldi r24, lo8(\ms)
    ldi r25, hi8(\ms)
    rcall mswait
.endm

.text

.global uswait
.func uswait        ; void uswait(int µs -> r24:r25)

;   ldi r24, 1        1
;   ldi r25, 0        1
;   rcall uswait      3

uswait:
    sbiw r24, 1     ; 2
.if (__F_CPU <= 12000000)
    brne loop       ; 1|2
    ret             ; 4
.else
    breq return     ; 1|2
    rcall loop      ; 3
.endif
.if (__F_CPU == 20000000)
loop:
    nop             ; 1
    nop             ; 1
    nop             ; 1
    nop             ; 1
.else
loop:
.endif
.if (__F_CPU >= 12000000)
    nop             ; 1
    nop             ; 1
    nop             ; 1
    nop             ; 1
    nop             ; 1
    nop             ; 1
.endif
.if (__F_CPU <= 12000000)    ; 6-12 MHz
    rjmp uswait     ; 2
.else
return:
    ret             ; 4
.endif
.endfunc            ; uswait

.global mswait
.func mswait            ; void mswait(const int ms -> r24:r25)

;    ldi r22,0       1
;    ldi r21,1       1
;    rcall mswait    3

mswait:
    push r26        ; 2
    push r27        ; 2
    rjmp l1         ; 2
l3:
    sbiw r24,1      ; 2
    brne l1         ; 1|2
    pop r27         ; 2
    pop r26         ; 2
    ret             ; 4

l1:
    nop             ; 1
    ldi r26, lo8(Dloop) ; 1
    ldi r27, hi8(Dloop) ; 1

l2:
    sbiw r26,1      ; 2
    brne l2         ; 1|2

    rjmp l3         ; 2
.endfunc            ; mswait
