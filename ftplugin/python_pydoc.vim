" Vim ftplugin file
" Language: Python
" Authors:  André Kelpe <efeshundertelf at googlemail dot com>
"           Romain Chossart <romainchossat at gmail dot com>
"           Matthias Vogelgesang
"           Ricardo Catalinas Jiménez <jimenezrick at gmail.com>
"           Patches and suggestions from all sorts of fine people
"
" More info and updates at:
"
" http://www.vim.org/scripts/script.php?script_id=910
"
"
" This plugin integrates the Python documentation view and search tool pydoc
" into Vim. The plugin allows you to view the documentation of a Python
" module or class by typing:
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
" to see the docs of a module/class in your source code.
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
" pydoc.vim is free software; you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation; either version 2
" of the License, or (at your option) any later version.
"
" Please feel free to contact me and follow me on twitter (@fs111).

if exists("b:did_ftplugin")
    finish
else
    let b:did_ftplugin = 1
endif

setlocal switchbuf=useopen
function s:ShowPyDoc(name, type)
    if !exists('g:pydoc_cmd')
        let g:pydoc_cmd = 'pydoc'
    endif

    if !exists('g:pydoc_open_cmd')
        let g:pydoc_open_cmd = 'split'
    endif

    if g:pydoc_open_cmd == 'split'
        let l:pydoc_wh = 10
    endif

    if bufloaded("__doc__") > 0
        let l:buf_is_new = 0
    else
        let l:buf_is_new = 1
    endif

    if bufname("%") == "__doc__"
        " The current buffer is __doc__, so do not
        " recreate nor resize it
        let l:pydoc_wh = -1
    else
        if bufnr("__doc__") > 0
            " If the __doc__ buffer is open in the
            " current window, jump to it
            execute "sbuffer" bufnr("__doc__")
        else
            execute g:pydoc_open_cmd '__doc__'
            setlocal noswapfile
            setlocal buftype=nofile
            setlocal bufhidden=wipe
            setlocal modifiable
            setlocal filetype=man
            call s:PerformMappings()
        endif
    endif

    normal ggdG
    " Remove function/method arguments
    let s:name2 = substitute(a:name, '(.*', '', 'g' )
    " Remove all colons
    let s:name2 = substitute(s:name2, ':', '', 'g' )
    if a:type == 1
        execute  "silent read !" g:pydoc_cmd s:name2
    else
        execute  "silent read !" g:pydoc_cmd "-k" s:name2
    endif
    setlocal nomodified
    normal 1G

    if exists('l:pydoc_wh') && l:pydoc_wh != -1
        execute "silent resize" l:pydoc_wh
    end

    if !exists('g:pydoc_highlight')
        let g:pydoc_highlight = 1
    endif
    if g:pydoc_highlight == 1
        call s:Highlight(s:name2)
    endif

    let l:line = getline(2)
    if l:line =~ "^no Python documentation found for.*$"
        if l:buf_is_new
            execute "bd!"
        else
            normal u
        endif
        redraw
        echohl WarningMsg | echo l:line | echohl None
    endif
endfunction

" Highlighting
function s:Highlight(name)
    execute "sb __doc__"
    setlocal filetype=man
    execute 'syntax keyword pydoc' a:name
    hi pydoc gui=reverse
endfunction

" Mappings
function s:PerformMappings()
    nnoremap <silent> <buffer> <Leader>pw :silent call <SID>ShowPyDoc('<C-R><C-W>', 1)<CR>
    nnoremap <silent> <buffer> <Leader>pW :silent call <SID>ShowPyDoc('<C-R><C-A>', 1)<CR>
    nnoremap <silent> <buffer> <Leader>pk :silent call <SID>ShowPyDoc('<C-R><C-W>', 0)<CR>
    nnoremap <silent> <buffer> <Leader>pK :silent call <SID>ShowPyDoc('<C-R><C-A>', 0)<CR>

    " remap the K (or 'help') key
    nnoremap <silent> <buffer> K :silent call <SID>ShowPyDoc(expand("<cword>"), 1)<CR>
endfunction

if !exists('g:pydoc_perform_mappings')
    let g:pydoc_perform_mappings = 1
endif
if g:pydoc_perform_mappings != 0
    call s:PerformMappings()
endif

" Commands
command -nargs=1 Pydoc       :silent call s:ShowPyDoc('<args>', 1)
command -nargs=* PydocSearch :silent call s:ShowPyDoc('<args>', 0)
