;
; 2012-04-05 initial version
; 2019-09-10 redesign
; 2019-10-31 stable 4-bit version
; 2019-11-01 v1.0.0 released
; 2019-11-15 possible usage of the upper 4 bits in 4 bit mode
; 2019-11-29 v1.1.1 released (3-wire interface)
; 2019-12-08 v1.1.3 error correction serial interface
; 2019-12-11 v1.2.0 error correction 4 bit mode, new function printxyLCD
; 2019-12-12 v1.2.1 new functions uswait, newCHR
;
; example LCD pin assignment Philips LTN211 (8bit/4bit)
; LCD pin     : 1   2   3   4   5   6   7   8   9   10  11  12  13  14
; Description : Vss Vdd Vo  RS  R/W E   D0  D1  D2  D3  D4  D5  D6  D7
; connected to: Gnd +5V Vco PC0 PC1 PC2 PD0 PD1 PD2 PD3 PD4 PD5 PD6 PD7
; connected to: Gnd +5V Vco PC0 PC1 PC2 Gnd Gnd Gnd Gnd PD0 PD1 PD2 PD3