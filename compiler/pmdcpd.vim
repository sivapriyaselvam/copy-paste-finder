"
" PMD/CPD support
"
if exists("current_compiler")
  finish
endif
let current_compiler = "pmdcpd"
let s:keepcpo= &cpo
set cpo&vim

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

"Starting at line 3886 of file.cpp

"set efm=Starting at line %l of %f

CompilerSet errorformat=Starting\ at\ line\ %l\ of\ %f

let &cpo = s:keepcpo
unlet s:keepcpo
