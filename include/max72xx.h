/*  display library for HD44780 compatible LCD's
    copyright (c) 2012 Roland Ludwig

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

// version "0.1.0 2020-11-11"
//#define __INFO__

#ifndef MAX72xx_h
  #define MAX72xx_h
#ifdef __cplusplus
  extern "C" {
#endif

// hexadecimal values
    #define HEX0 0x7e
    #define HEX1 0x30
    #define HEX2 0x6d
    #define HEX3 0x79
    #define HEX4 0x33
    #define HEX5 0x5b
    #define HEX6 0x5f
    #define HEX7 0x70
    #define HEX8 0x7f
    #define HEX9 0x7b
    #define HEXA 0x77
    #define HEXB 0x1f
    #define HEXC 0x4e
    #define HEXD 0x3d
    #define HEXE 0x4f
    #define HEXF 0x47
    #define DASH 0x01

// LCD control values
    #define _NULL	0b00000000		// dummy
    #define _CLEAR  0b00000001      // clear display
    #define _HOME   0b00000010      // cursor home
    #define _DPCTRL 0b00001000      // display control
    #define _DPON   0b00000100      // display on/off
    #define _CUON   0b00000010      // cursor on/off
    #define _BLON   0b00000001      // cursor blink
    #define _CGRAM  0b01000000      // character RAM address
    #define _DDRAM  0b10000000      // display RAM address

//     #define _LCDHOME writeLCD(_CTRL, _HOME)
//     #define _LCDCLEAR writeLCD(_CTRL, _CLEAR)
//     #define _LCDCTRL (cmd) writeLCD(_CTRL, cmd | _DPCTRL)	// cmd = _DPON | _CUON | _BLON
//
     extern void initLED(void);
// #ifdef __INFO__
//     extern void libinfo(void);
// #endif
    extern void writeLED(char reg, char data);
    // extern void printxyLCD(char x, char y, const char *text);
    // extern void printLCD(const char *text);
    // extern char readLCD(char rs);
    // extern void newCHR(char addr, const char *character);

#ifdef __cplusplus
  }
#endif

#endif
