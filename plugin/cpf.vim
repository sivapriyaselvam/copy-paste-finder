"
" Copy/Paste Finder
" =================
"
" Vim plugin for viewing copied-pasted code side-by-side
" Maintainer:   Skycolor Radialsum
" Last Change:  2018-03-05
"
" CPF (Copy/Paste Finder) makes PMD/CPD's or Sloppy's output easier to
" navigate.  It depends on PMD/CPD or Sloppy software and also it needs
" Vim's quickfix feature.
"
" CPD:
" PMD's Copy/Paste Detector (CPD) finds duplicated code.
" PMD is an extensible cross-language static code analyzer.
" PMD is an open source project.
"
" see https://pmd.github.io/ to download it and for more info.
"
" Sloppy:
" Sloppy scans all source code in a directory and generates a report on how
" 'sloppy' the code is... sloppiness being a measurement of a repetitive code
" style: under abstraction (copy / pasting) and over abstraction (pointless
" complexity).
"
" Sloppy is written by Wouter van Oortmerssen.
"
" see http://strlen.com/sloppy/ to download it and for more info.
"
" NOTE:
"     * it cannot be used with other plugins that need a window
"       (e.g. taglist, nerdtree...) or in diff-mode.
"     * it was tested only on Microsoft Windows with Gvim and with few C++
"       source files.
"     * larger repositories may hang Vim or make Vim sluggish.
"     * this script can be buggy---I still learn Vim!
"
"
" Installation
" ------------
" * copy pmdcpd.vim to the compiler directory
" * copy sloppy.vim to the compiler directory
" * copy cpf.vim to plugin directory
"     i.e. inside $HOME/vimfiles (or runtime directory):
"       compiler/pmdcpd.vim
"       compiler/sloppy.vim
"       plugin/cpf.vim
" * ensure java environment or sloppy executable in path
" * ensure cpd (e.g. cpd.bat) is found in the path
" * ensure cpd or sloppy runs correctly
"
" The Sloppy release has sloppy.exe which runs on windows.
" However for the original sloppy, a batch file is required.
" For example: sloppy.bat
"     >> @echo off
"     >> echo. | sloppy %*
" Above batch file helps sloppy to exit---otherwise it waits for
" enter key to be pressed.
"
"
" Usage
" -----
" Steps below targets Microsoft Windows. Similar steps can be used with
" Linux or Unix* operating systems.
"
" * Run gvim to open a new gvim window
" * Ensure current working directory is correct in gvim
" * During an editing session:
"     :compiler pmdcpd
"     :set makeprg=cpd.bat\ --minimum-tokens\ 20\ --language\ cpp\ --files\ .
"     :make!
"     :CpfNext
"
" Or
"     :compiler sloppy
"     :makeprg=sloppy.bat
"     :make!
"     :CpfNext
"
" can be used with sloppy
"
" The command CpfNext can be repeated to see more duplicates
"
" This plugin provides Cpf_Close() and Cpf_Reset().
" Cpf_Close() resets the window options used by the plugin.
" Cpf_Reset() removes splits and reverts to original window width.
" Cpf_Previous() also available, but only partially functional.
"
"
" Mapping
" -------
" Following commands can be used to map a key to CpfNext.
" For example to use function key 'F4' use the commands below:
"   :unmap <F4>
"   :nmap <F4> :CpfNext<CR>
" or
"   :nmap <F4> :call Cpf_Next()<CR>
"
"
" Limitations
" -----------
" can only see two windows with a (vertical) split at a time
" - see TODO below
"
" TODO
" ----
"   * work along with other plugins (e.g. taglist, nerdtree...)
"   * support more windows; now only 2 (see wincount)
"   * support showing previous duplicate (opposite of Cpf_Next())
"   * silent, normal or execute may be redundant in some cases
"   * need to skip lines with no code or lines with comment only
"   * deciding whether to save buffers before jumping to next section
"   * if quickfix windows is visible may need to scroll/redraw
"

if exists('g:loaded_copy_paste_finder')
  finish
endif

let g:loaded_copy_paste_finder = 1

" variables to save and restore options
let s:co_save = &columns
let s:wrap_save = &wrap
let s:sbo_save = &scrollopt

" state variables
let s:idx = -2      " -2: not initialized; -1: reached max; >=0: valid
let s:qnum = -1     " quickfix list number; should be 1 or greater
let s:lines = 0     " number of lines in a copy/paste region
let s:pos = []      " list of cursor positions
let s:bnum = []     " list of buffer-numbers - TODO: to check if buf-modified
let s:lnum = []     " list of line numbers
let s:qflist = []   " list with all the current quickfix errors

" constants
let s:wincount = 2  " number of windows updated by the plugin
let s:firstwin = 1  " TODO - to support taglist/nerdtree etc, if possible
" NOTE: s:wincount is fixed to 2; may be parameterized later

" configuration
let s:wrap = 0            " when false longer lines will nor wrap
let s:topoff = 7          " number of lines to keep above C/P at the window-top
let s:showqfw = 1         " show quickfix window (when have valid errors)
let s:higroup = 'Visual'  " to highlight the copy/paste sections
let s:split = 1           " vertical/horizontal split --- not used - TODO
" NOTE: variables below can be global so that user can set it


" if !hasmapto('<Plug>CpfNext', 'n')
"   nmap <unique> <silent> <F4> <Plug>CpfNext
" endif
"
" nmap <silent> <Plug>CpfNext :call Cpf_Next()<cr>

command! -nargs=0 CpfNext :call Cpf_Next()

function! Cpf_Next()
  if s:idx <= -2  " not yet initialized
    if s:Cpf_Init() != 0
      return 1
    endif
  endif

  if s:Cpf_Load() != 0
    return 1
  endif

  if s:Cpf_Modified() != 0
    call s:Cpf_EchoError('Error: No write since last change. Please save and retry.')
    return 1
  endif

  let l:repeat = 1

  while l:repeat
    let l:item = get(s:qflist, s:idx, 0)

    if !empty(l:item)
      if l:item.lnum > 0
        let s:lnum += [ l:item.lnum ]
        let s:bnum += [ l:item.bufnr ]
        call s:Cpf_GetPos()

        if len(s:pos) == s:wincount
          let l:offset = min([s:lnum[0], s:lnum[1], s:topoff])

          for i in range(1, s:wincount)
            call s:Cpf_SetPos(i, l:offset)
          endfor

          call remove(s:pos, 0)
          call remove(s:bnum, 0)
          call remove(s:lnum, 0)
          let l:repeat = 0
        endif
      else  " search lines for grouping and line-count of copy/paste regions
        let s:lines = s:Cpf_GetDupLineCount(l:item.text)
        if s:lines > 0
          let s:pos = []
          let s:bnum = []
          let s:lnum = []
        endif
      endif

      let s:idx += 1
    else  " no quickfix info, or reached the end of error-list
      if s:idx <= 0
        call s:Cpf_EchoError('Error: no errors or something went wrong')
      else
        silent crewind
        let s:idx = 0
        call s:Cpf_EchoError('Error: no more errors; try again to restart')
      endif

      break

    endif
  endwhile
endfunction

function! Cpf_Previous()
  " FIXME: buggy!
  "        now shows previous match only if same as current C/P set
  if s:idx > 3
    let s:idx -= 2
    call Cpf_Next()
  endif
endfunction

function! s:Cpf_Init()
  windo call clearmatches()

  if s:Cpf_Widen() != 0
    return 1
  endif

  if !s:wrap
    silent windo set nowrap
  endif

  let s:idx = 0

  if s:showqfw
    cwindow
  endif

  silent redraw
  return 0
endfunction

function! s:Cpf_Load()
  " NOTE: the getqflist({'nr':0, 'title':1}) is used to get the info
  "       on currently active quickfix list --- this idea can be wrong
  let l:curqf = getqflist({'nr':0, 'title':1, 'size':0})

  if l:curqf.nr <= 0  " TODO: if curqf is empty; or if curqf.nr < 0 ?
    call s:Cpf_EchoError('Error: no quickfix list; did you forget something?')
    return 1
  else
    if s:qnum == l:curqf.nr
      " quickfix list has not changed
    else
      if s:qnum > 0
        echo 'Reloading quickfix from ''' . l:curqf.title . ''' ...'
      else
        echo 'Loading quickfix from ''' . l:curqf.title . ''' ...'
      endif

      if l:curqf.size <= 0
        call s:Cpf_EchoWarning('Note: quickfix list is empty')
        call s:Cpf_EchoWarning('Perhaps it is ok, unless you forgot something')
      elseif len(filter(getqflist(), 'v:val.valid')) == 0
        call s:Cpf_EchoWarning('Note: quickfix has no errors')
        call s:Cpf_EchoWarning('Perhaps it is ok, unless you forgot something')
      endif

      let s:qnum = l:curqf.nr
      let s:qflist = getqflist()
      let s:idx = 0
      let s:pos = []
      let s:bnum = []
      let s:lnum = []

      silent! crewind
    endif
  endif
  return 0
endfunction

function! Cpf_Close()
  let s:idx = -2
  let s:qflist = []

  for i in range(1, s:wincount)
    silent! execute ' '.i.'wincmd w'
    let &wrap = s:wrap_save
    let &scrollopt = s:sbo_save
    call clearmatches()
  endfor
endfunction

function! Cpf_Reset()
  call Cpf_Close()
  " FIXME: reverting to old window size --- perhaps weird
  silent cclose
  silent! wincmd o
  let &columns = s:co_save
endfunction

function! s:Cpf_GetPos()
  silent execute 'cc ' . (s:idx + 1)
  let s:pos += [ getcurpos() ]
endfunction

function! s:Cpf_SetPos(winid, offset)
  let l:winid = 0 + a:winid

  if (l:winid > 0) && (l:winid <= winnr('$'))
    execute ' '.l:winid.'wincmd w'
    set noscrollbind
    let l:id = l:winid - 1
    execute ' '.s:bnum[l:id] . 'buffer'
    call setpos('.', s:pos[l:id])
    call s:Cpf_Highlight_Lines(s:higroup, s:lnum[l:id], s:lines)
    let l:line = s:lnum[l:id] - a:offset
    " NOTE: zz is not helpful when quickfix window is open.
    silent execute "normal! ".l:line."z\<CR>"
    silent execute "normal! ".s:lnum[l:id]."gg"
    set scrollbind
  endif
endfunction

function! s:Cpf_GetDupLineCount(text)
  " getting dup-line-count handles both PMD/CPD and Sloppy error formats
  let l:lines = 0
  if !empty(a:text)
    "PMD_CPD: 'Found a 3 line (45 tokens) duplication...'
    "Sloppy: '55 tokens & 4 skips (1004 sloppiness, 2.49% of total)...'
    if match(a:text, '^Found a \d\+ line (\d\+ tokens) duplication') >= 0
      let l:lines = 0 + matchstr(a:text, '^Found a \zs\d\+\ze')
    elseif match(a:text, '^\d\+ tokens . \d\+ skips') >= 0
      let l:lines = 0 + matchstr(a:text, '^\zs\d\+\ze tokens')
      " NOTE: below is a rough estimation of lines; can be wrong
      let l:lines = 1 + (l:lines / 10)
    endif
  endif
  return l:lines
endfunction

function! s:Cpf_Highlight_Lines(group, start, lines)
  " TODO: need to skip lines with no code or lines with only comment
  if a:lines > 0
    call clearmatches()

    for i in range(a:start, a:start+a:lines-1)
      call matchaddpos(a:group, [ i ])
    endfor

    silent! .foldopen!
  else
    " TODO need to verify
  endif
endfunction

function! s:Cpf_Widen()
  cclose

  if winnr('$') > 2
    if s:Cpf_Modified() != 0
      call s:Cpf_EchoError('Error: No write since last change. Please save and retry.')
      return 1
    endif

    call s:Cpf_EchoWarning('Warning: need to change window layout.')

    if input('Close all other windows except current window? (y/n) ', 'y') == 'y'
      silent! wincmd o
      wincmd v
    else
      return 1
    endif
  elseif winnr('$') == 2
    " if the existing split is horizontal, what to do? now it is allowed.
    wincmd =
  else
    wincmd v
  endif

  if &columns >= 200
    " already wide-enough
  elseif &columns < 120
    " TODO: add extra for fold/number/...
    let &columns = (&columns * 2)
    wincmd =
  endif
endfunction

function! s:Cpf_Modified()
  " counts how many windows has been modified.
  " also if less splits then create splits
  " FIXME: this method is very naive, need to be improved.
  let g:Cpf_n = 0
  let l:lastwin=winnr()  " remember to switch to current window

  if winnr('$') < s:wincount
    " FIXME: wrong if quickfix-window is open
    " TODO: if wincount > 2 ?
    wincmd v
  endif

  silent execute '1,'.s:wincount.'windo let g:Cpf_n+=&modified'
  silent execute ' '.l:lastwin.'wincmd w'
  " TODO: or switch to a modified window?
  let l:Cpf_n = g:Cpf_n
  unlet g:Cpf_n
  return l:Cpf_n
endfunction

function! s:Cpf_EchoError(text)
  echohl ErrorMsg
  echo a:text
  echohl None
endfunction

function! s:Cpf_EchoWarning(text)
  echohl WarningMsg
  echo a:text
  echohl None
endfunction

function! s:Cpf_DebugDump(...)
  if a:0 > 0
    echo string(a:000) . "\n"
  endif

  echo 's:idx:    '.s:idx."\n"
  echo 's:lines:  '.s:lines."\n"
  echo 's:lnum:   '.string(s:lnum)."\n"
  echo 's:bnum:   '.string(s:bnum)."\n"
endfunction
