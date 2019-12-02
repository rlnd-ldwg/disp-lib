# display-library
Small fast library written in avr assembler
Can be used with standard c/c++ compilers, ARDUINO or pure assembler programming

* for HD44780 compatible LCD's, support for
  * 8/4 bit interface
  * 3 wire serial interface based on 74HCT164
  ![Circuit](https://github.com/rlnd-ldwg/disp-lib/blob/master/circuit.png)
* for LED MAX7221 driver (not yet implemented)

### planned
* better support für AVR port description (maybe include files?)
* more accurate calculation for mswait
