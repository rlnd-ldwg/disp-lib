
#ifdef __cplusplus
extern "C" {
#endif

// register select value
#define _CTRL 0
#define _DATA 1

// LCD control values
#define _CLEAR  0b00000001
#define _HOME   0b00000010
#define _DPCTRL 0b00001000      // display control
#define _DPON   0b00000100      // display on/off
#define _CUON   0b00000010      // cursor on/off
#define _BLON   0b00000001      // cursor blink
#define _CGRAM  0b01000000
#define _DDRAM  0b10000000

    extern void initLCD(void);
    extern void libversion(void);
    extern void writeLCD(const char rs, char data);
    extern void printLCD(const char *text);
    extern char readLCD(char rs);

    extern void LCD_CursorOn(void);
    extern void LCD_CursorOff(void);
    extern void LCD_SetCursor(char, char);
    extern void LCD_Off(void);
    extern void LCD_On(void);
    extern void mswait(int);
/* old deprecated functions
    extern void InitLCD(void);
    extern void LCD_SendData(char, char);
    extern char LCD_ReadData(char);
    extern void LCD_PrintStr(char *buffer);
*/

#ifdef __cplusplus
}
#endif

class HD44870 {
    void initLCD(void);
};
