#!/usr/bin/python
''' converts atmel avr syntax to gnu avr-as format
    copyright (c) september 2019 Roland Ludwig

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
'''

import sys
import re
import string

print '\nConverting Atmel AVR include files to GNU AVR format v.1.0.3 September \'19\n'

if len(sys.argv) < 3:
    print 'Missing parameters\nusage : ' + sys.argv[0] + ' <source> <target>\n'
    quit()
print 'converting ' + sys.argv[1] + ' to ' + sys.argv[2] + '...\n'
infile = open(sys.argv[1], 'rb')
outfile = open(sys.argv[2], 'w')
count = 0
regex = re.compile(r'(\s|\t|=)+')
for line in infile:
    dummy = line.strip()
    commentpos = dummy.find(';')
    if len(dummy) == 0:
        outfile.write('\n')         # empty line
    elif commentpos == 0:           # comment, leave as is
        outfile.write('%s\n' % line[0:len(line)-2])
    elif dummy[0:4] == '.equ':      # assignment
        dumArr = re.split(regex, dummy)
        filtered = [i for i in dumArr if not regex.search(i)]
#        print '%s -> %s' % (dummy, filtered)
        if commentpos > 0:
            comment = '\t' + dummy[commentpos:]
        else:
            comment = ''
        outfile.write('%s %s, %s%s\n' % (filtered[0], filtered[1], filtered[2], comment))
infile.close()
outfile.close()
