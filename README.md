
Copy/Paste Finder
=================

CPF (Copy/Paste Finder) is a Vim Plugin for finding copy/paste regions in code.

CPF (Copy/Paste Finder) makes PMD/CPD's or Sloppy's output easier to navigate.
CPF shows detected copied/pasted regions in vertical splits and highlights
the found regions.


See [Vim doc](doc/cpf.txt) file for installation instructions and for more info.


PMD/CPD
-------
PMD's Copy/Paste Detector (CPD) finds duplicated code.
PMD is an extensible cross-language static code analyzer.
PMD is an open source project.

see https://pmd.github.io/ to download it and for more info.

Sloppy
------
Sloppy scans all source code in a directory and generates a report on how
'sloppy' the code is... sloppiness being a measurement of a repetitive code
style: under abstraction (copy / pasting) and over abstraction (pointless
complexity).

Sloppy is written by Wouter van Oortmerssen.

see http://strlen.com/sloppy/ to download it and for more info.

Note
-------
Tested with Vim version 8.0 and above; it may work with older vim, but not
verified.  This plugin only works if 'compatible' is not set.
