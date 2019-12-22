; delay routines
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

.version "0.1.0 2019-12-21"

; calculate counter for delay loop
.ifndef __F_CPU                             ; if not set
    .equ __F_CPU, 12000000                  ; set to 12MHz systemclock
.endif

.equ Cfactor, 2                             ; correction factor
.equ Dloop, (__F_CPU / 4 / 1000) - Cfactor  ; loop counter

.macro _DELAY_MS ms
    ldi r24, lo8(\ms)
    ldi r25, hi8(\ms)
    rcall mswait
.endm

.macro _DELAY_US us			; only correct for 12 MHz
	ldi r24, lo8(\us)
	ldi r25, hi8(\us)
	rcall uswait
.endm

.text

.global mswait
.func mswait        ; void mswait(const int ms -> r24:r25)

mswait:
    push r26        ; save register
    push r27
l3: sbiw r24, 1     ; decrement double register
    brcc l1         ; wait 1 ms
    pop r27
    pop r26
    ret
l1: nop
    ldi     r26, lo8(Dloop)
    ldi     r27, hi8(Dloop)
l2: sbiw    r26, 1
    brne    l2
    rjmp l3
.endfunc            ; mswait

.global uswait
.func uswait        ; void uswait(int us -> r24:r25)

uswait:
    ;ldi r24, 1     ; 1
    ;ldi r25, 0     ; 1
    ;rcall uswait   ; 3
    sbiw r24, 1     ; 2
    brne l4         ; 1 / 2
    ret             ; 4
l4: nop             ; 1
    nop
    nop
    nop
    nop
    nop
    rjmp uswait     ; 2
.endfunc            ; uswait

.end
