"
" Copy/Paste Finder
" =================
"
" Vim plugin for viewing copied-pasted code
" Maintainer:   Skycolor Radialsum
" Last Change:  2018-02-26
"
" CPF (Copy/Paste Finder) makes PMD/CPD's output easier to navigate.
" CPF depends on PMD software and needs Vim's quickfix feature.
"
" PMD's Copy/Paste Detector (CPD) can find duplicate code.
" PMD is an open source static Java source code analyzer.
"
" see https://pmd.github.io/ to download it and for more info.

" Installation
" ------------
" * copy pmdcpd.vim to the compiler directory
" * copy cpf.vim to plugin directory
"     i.e. inside $HOME/vimfiles (or runtime directory):
"       compiler/pmdcpd.vim
"       plugin/cpf.vim
" * ensure java environment
" * ensure cpd (e.g. cpd.bat) is found in the path
" * ensure cpd runs correctly
"
" Usage
" -----
" * Run gvim to open a new gvim window
" * Ensure current working directory is correct in gvim
" * During an editing session:
"     :call Lib_Widen()
"     :compiler pmdcpd
"     :set makeprg=cpd.bat\ --minimum-tokens\ 20\ --language\ cpp\ --files\ .
"     :make!
"     :call Cpf_Init()
"     :call Cpf_Next()
"
" The call Cpf_Next() can be repeated to see more duplicates
"
" Mapping
" -------
" Following commands can be used to map a key to Cpf_Next.
" For example to use function key 'F4' use the commands below:
"   :unmap <F4>
"   :nmap <F4> :call Cpf_Next()<CR>
"
" Limitations
" -----------
" can only see two windows with a vertical split at a time
" - see TODO

" TODO
" ----
"   * QuickFixCmd* to further simplify
"   * to check http://strlen.com/sloppy/ and to support it
"   * may need to scroll the window --- try 'zz'?
"   * support more windows
"   * support showing previous duplicate (opposite of Cpf_Next())

if exists('g:loaded_copy_paste_finder')
  finish
endif

let g:loaded_copy_paste_finder = 1

let s:idx = -1
let s:qflist = []
let s:lines = 0
let s:pos = []
let s:buf = []
let s:lnum = []
let s:wincount = 2

" if !hasmapto('<Plug>CpfNext', 'n')
"   nmap <unique> <silent> <F4> <Plug>CpfNext
" endif

nmap <silent> <Plug>CpfNext :call Cpf_Next()<cr>

function! Cpf_Setup()
  compiler pmdcpd
endfunction

function! Cpf_Init()
  windo call clearmatches()
  let s:qflist = getqflist()

  if !empty(s:qflist)
    let s:idx = 0
    silent cfirst
  else
    echohl ErrorMsg
    echo 'Error: no errors or something went wrong'
    echohl None
  endif
endfunction

function! Cpf_Next()
  let l:repeat = 1
  while l:repeat
    let l:item = get(s:qflist, s:idx, 0)
    if !empty(l:item)
      if l:item.lnum > 0
        let s:lnum += [ l:item.lnum ]
        let s:buf += [ l:item.bufnr ]
        call Cpf_GetPos()
        if len(s:pos) == s:wincount
          for i in range(1, s:wincount)
            call Cpf_SetPos(i)
          endfor
          call remove(s:pos, 0)
          call remove(s:buf, 0)
          call remove(s:lnum, 0)
          let l:repeat = 0
        endif
      elseif match(l:item.text, '^Found a \d\+ line (\d\+ tokens) duplication') >= 0
        " Found a 3 line (45 tokens) duplication
        let s:lines = 0 + matchstr(l:item.text, '^Found a \zs\d\+\ze line')
        let s:pos = []
        let s:buf = []
        let s:lnum = []
      else
        " skip
      endif
      let s:idx += 1
    else
      if s:idx == 0
        echohl ErrorMsg
        echo 'Error: no errors or something went wrong'
        echohl None
      else
        silent cfirst
        let s:idx = 0
        echohl ErrorMsg
        echo 'Error: no more errors; try again to restart'
        echohl None
      endif
      break
    endif
  endwhile
endfunction

function! Cpf_Close()
  let s:idx = -1
  let s:qflist = []
endfunction

function! Cpf_GetPos()
  silent cnext
  let s:pos += [ getcurpos() ]
endfunction

function! Cpf_SetPos(winid)
  let l:winid = 0 + a:winid
  if (l:winid > 0) && (l:winid <= winnr('$'))
    execute ' '.l:winid.'wincmd w'
    let l:winid -= 1
    execute ' '.s:buf[l:winid] . 'buffer'
    call setpos('.', s:pos[l:winid])
    call Lib_Highlight_Lines('Visual', s:lnum[l:winid], s:lines)
  endif
endfunction

" functions below can be independent of CPF scope
function! Lib_Highlight_Lines(group, start, lines)
  " TODO: need to skip lines with no code but only comment
  if a:lines > 0
     call clearmatches()
    for i in range(a:start, a:start+a:lines-1)
      call matchaddpos(a:group, [ i ])
    endfor
    silent! normal! zO
  else
    " TODO need to verify
  endif
endfunction

function! Lib_Widen()
  cclose
  if winnr('$') == 1
    let l:col = &columns
    if &columns >= 200
      " already wide-enough
    else
      if &columns < 120
        let &columns = (&columns * 2)
      endif
    endif
    wincmd v
    cwindow
  else
    echohl ErrorMsg
    echo 'Error: it is required to keep only one window open'
    echohl None
  endif
endfunction
