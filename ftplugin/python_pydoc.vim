" Vim ftplugin file
" Language: Python
" Authors:  André Kelpe <efeshundertelf at googlemail dot com>
"           Romain Chossart <romainchossat at gmail dot com>
"           Matthias Vogelgesang
"           Ricardo Catalinas Jiménez <jimenezrick at gmail dot com>
"           Patches and suggestions from all sorts of fine people
"
" More info and updates at:
"
" http://www.vim.org/scripts/script.php?script_id=910
"
"
" This plugin integrates the Python documentation view and search tool pydoc
" into Vim. It allows you to view the documentation of a Python module or class
" by typing:
"
" :Pydoc foo.bar.baz (e.g. :Pydoc re.compile)
"
" Or search a word (uses pydoc -k) in the documentation by typing:
"
" :PydocSearch foobar (e.g. :PydocSearch socket)
"
" Vim will split the current window to show the Python documentation found by
" pydoc (the buffer will be called '__doc__', Pythonic, isn't it ;-) ). The
" name may cause problems if you have a file with the same name, but usually
" this should not happen.
"
" pydoc.vim also allows you to view the documentation of the 'word' (see :help
" word) under the cursor by pressing <Leader>pw or the 'WORD' (see :help WORD)
" under the cursor by pressing <Leader>pW. This is very useful if you want to
" jump to the docs of a module or class found by 'PydocSearch' or if you want
" to see the docs of a module/class in your source code. Additionally K is
" mapped to show invoke pydoc as well, when you are editing python files.
"
" The script is developed in GitHub at:
"
" http://github.com/fs111/pydoc.vim
"
"
" If you want to use the script and pydoc is not in your PATH, just put a
" line like this in your .vimrc:
"
" let g:pydoc_cmd = '/usr/bin/pydoc'
"
" or more portable
"
" let g:pydoc_cmd = 'python -m pydoc'
"
" If you want to open pydoc files in vertical splits or tabs, give the
" appropriate command in your .vimrc with:
"
" let g:pydoc_open_cmd = 'vsplit'
"
" or
"
" let g:pydoc_open_cmd = 'tabnew'
"
" The script will highlight the search term by default. To disable this behaviour
" put in your .vimrc:
"
" let g:pydoc_highlight=0
"
" If you want pydoc to switch to an already open tab with pydoc page,
" set this variable in your .vimrc (uses drop - requires vim compiled with
" gui!):
"
" let g:pydoc_use_drop=1
"
" Pydoc files are open with 10 lines height, if you want to change this value
" put this in your .vimrc:
"
" let g:pydoc_window_lines=15
" or
" let g:pydoc_window_lines=0.5
"
" Float values specify a percentage of the current window.
"
"
" In order to install pydoc.vim download it from vim.org or clone the repository
" on githubi and put it in your .vim/ftplugin directory. pydoc.vim is also fully
" compatible with pathogen, so cloning the repository into your bundle directory
" is also a valid way to install it. (I do this myself. see
" https://github.com/fs111/dotvim).
"
" pydoc.vim is free software; you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation; either version 2
" of the License, or (at your option) any later version.
"
" Please feel free to contact me and follow me on twitter (@fs111).

" IMPORTANT: We don't use here the `exists("b:did_ftplugin")' guard becase we
" want to let the Python filetype script that comes with Vim to execute as
" normal.

" Don't redefine the functions if this ftplugin has been executed previously
" and before finish create the local mappings in the current buffer
if exists('*s:ShowPyDoc') && g:pydoc_perform_mappings
    call s:PerformMappings()
    finish
endif

if !exists('g:pydoc_perform_mappings')
    let g:pydoc_perform_mappings = 1
endif

if !exists('g:pydoc_highlight')
    let g:pydoc_highlight = 1
endif

if !exists('g:pydoc_cmd')
    let g:pydoc_cmd = 'pydoc'
endif

if !exists('g:pydoc_open_cmd')
    let g:pydoc_open_cmd = 'split'
endif

setlocal switchbuf=useopen
highlight pydoc cterm=reverse gui=reverse

function! s:GetWindowLine(value)
    if a:value < 1
        return float2nr(winheight(0)*a:value)
    else
        return a:value
    endif
endfunction

" Args: name: lookup; type: 0: search, 1: lookup
function! s:ShowPyDoc(name, type)
    if a:name == ''
        return
    endif

    if g:pydoc_open_cmd == 'split'
        if exists('g:pydoc_window_lines')
            let l:pydoc_wh = s:GetWindowLine(g:pydoc_window_lines)
        else
            let l:pydoc_wh = 10
        endif
    endif

    if bufloaded("__doc__")
        let l:buf_is_new = 0
        if bufname("%") == "__doc__"
            " The current buffer is __doc__, thus do not
            " recreate nor resize it
            let l:pydoc_wh = -1
        else
            " If the __doc__ buffer is open, jump to it
            if exists("g:pydoc_use_drop")
                execute "drop" "__doc__"
            else
                execute "sbuffer" bufnr("__doc__")
            endif
            let l:pydoc_wh = -1
        endif
    else
        let l:buf_is_new = 1
        execute g:pydoc_open_cmd '__doc__'
        if g:pydoc_perform_mappings
            call s:PerformMappings()
        endif
    endif

    setlocal modifiable
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal syntax=man
    setlocal nolist

    normal ggdG
    " Remove function/method arguments
    let s:name2 = substitute(a:name, '(.*', '', 'g' )
    " Remove all colons
    let s:name2 = substitute(s:name2, ':', '', 'g' )
    if a:type == 1
        let s:cmd = g:pydoc_cmd . ' ' . shellescape(s:name2)
    else
        let s:cmd = g:pydoc_cmd . ' -k ' . shellescape(s:name2)
    endif
    if &verbose
        echomsg "pydoc: calling " s:cmd
    endif
    execute  "silent read !" s:cmd
    normal 1G

    if exists('l:pydoc_wh') && l:pydoc_wh != -1
        execute "resize" l:pydoc_wh
    end

    if g:pydoc_highlight == 1
        execute 'syntax match pydoc' "'" . s:name2 . "'"
    endif

    let l:line = getline(2)
    if l:line =~ "^no Python documentation found for.*$"
        if l:buf_is_new
            execute "bdelete!"
        else
            normal u
            setlocal nomodified
            setlocal nomodifiable
        endif
        redraw
        echohl WarningMsg | echo l:line | echohl None
    else
        setlocal nomodified
        setlocal nomodifiable
    endif
endfunction

function! s:ReplaceModuleAlias()
    " Replace module aliases with their own name.
    "
    " For example:
    "   import foo as bar
    " if `bar` is in the ExpandModulePath's return value, it should be
    " replaced with `foo`.
    let l:cur_col = col(".")
    let l:cur_line = line(".")
    let l:module_path = s:ExpandModulePath()
    let l:module_names = split(l:module_path, '\.')
    let l:module_orig_name = l:module_names[0]
    if search('import \+[0-9a-zA-Z_.]\+ \+as \+' . l:module_orig_name)
        let l:line = getline(".")
        let l:name = matchlist(l:line, 'import \+\([a-zA-Z0-9_.]\+\) \+as')[1]
        if l:name != ''
            let l:module_orig_name = l:name
        endif
    endif
    if l:module_names[0] != l:module_orig_name
        let l:module_names[0] = l:module_orig_name
    endif
    call cursor(l:cur_line, l:cur_col)
    return join(l:module_names, ".")
endfunction

function! s:ExpandModulePath()
    " Extract the 'word' at the cursor, expanding leftwards across identifiers
    " and the . operator, and rightwards across the identifier only.
    "
    " For example:
    "   import xml.dom.minidom
    "           ^   !
    "
    " With the cursor at ^ this returns 'xml'; at ! it returns 'xml.dom'.
    let l:line = getline(".")
    let l:pre = l:line[:col(".") - 1]
    let l:suf = l:line[col("."):]
    return matchstr(pre, "[A-Za-z0-9_.]*$") . matchstr(suf, "^[A-Za-z0-9_]*")
endfunction

" Mappings
function! s:PerformMappings()
    nnoremap <silent> <buffer> <Leader>pw :call <SID>ShowPyDoc('<C-R><C-W>', 1)<CR>
    nnoremap <silent> <buffer> <Leader>pW :call <SID>ShowPyDoc('<C-R><C-A>', 1)<CR>
    nnoremap <silent> <buffer> <Leader>pk :call <SID>ShowPyDoc('<C-R><C-W>', 0)<CR>
    nnoremap <silent> <buffer> <Leader>pK :call <SID>ShowPyDoc('<C-R><C-A>', 0)<CR>

    " remap the K (or 'help') key
    nnoremap <silent> <buffer> K :call <SID>ShowPyDoc(<SID>ReplaceModuleAlias(), 1)<CR>
endfunction

if g:pydoc_perform_mappings
    call s:PerformMappings()
endif

" Commands
command! -nargs=1 Pydoc       :call s:ShowPyDoc('<args>', 1)
command! -nargs=* PydocSearch :call s:ShowPyDoc('<args>', 0)
ca pyd Pydoc
ca pyds PydocSearch
