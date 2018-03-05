" Vim compiler file
" Compiler:     Sloppy
" Maintainer:   Skycolor Radialsum
" Last Change:  2018-03-05
"
" This file is used by Copy/Paste Finder plugin (see cpf.vim).
" Copy/Paste Finder is a Vim plugin for viewing copied-pasted code
" side-by-side
"
" Sloppy is written by Wouter van Oortmerssen.
" see http://strlen.com/sloppy/ to download it and for more info.
"

if exists("current_compiler")
  finish
endif

let current_compiler = "sloppy"

let s:cpo_save = &cpo
set cpo&vim

if exists(":CompilerSet") != 2  " older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

" Example of sloppy's output
"   || 82 tokens & 4 skips (2122 sloppiness, 5.26% of total) starting at:
"   || => file.cpp:3919

" FIXME: makeprg is valid only for Microsoft Windows
CompilerSet makeprg=sloppy.bat

CompilerSet errorformat==>\ %f:%l

" NOTE: au command below works with single file/window;
"       but can cause problems with many buffers/files/windows.
" au QuickfixCmdPost make call Cpf_Init()

let &cpo = s:cpo_save
unlet s:cpo_save

