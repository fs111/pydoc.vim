"pydoc.vim: pydoc integration for vim performs searches and can display the
"documentation of python modules 
"Author: André Kelpe <efeshundertelf at
"googlemail dot com> 
"Author: Romain Chossart <romainchossat at gmail dot com>
"Author: Matthias Vogelgesang
"Author: patches and suggestions from all sorts of fine people
"http://www.vim.org/scripts/script.php?script_id=910
"
"This plugin integrates the python documentation view- and search-tool 'pydoc'
"into (g)vim. The plugin allows yout to view the documentation of a
"python-module or class by typing
"
":Pydoc foo.bar.baz (e.g. :Pydoc re.compile)
"
"or search a word (uses pydoc -k) in the documentation by typing
"
":PydocSearch foobar
""
"Vim will split a new buffer, which shows the python-documentation found by 
"pydoc.  (The buffer is called '__doc__' (pythonic, isn't it ;-) ). The name
"may cause problems, if you have a file with the same name, but usually this 
"should not happen).

"pydoc.vim also allows you view the documentation of the 'word' (see :help
"word) under the cursor by pressing <leader>pw or the 'WORD' (see :help WORD)
"under the cursor by pressing <leader>pW. This is very useful if you want to
"jump to the docs of a module or class found by 'PydocSearch' or if you want
"to see the docs of a module/class in your source code.

"To have a browser like feeling you can use 'u' and 'CTRL-r' to go back and
"forward, just like editing normal text in a normal buffer.
"
"The script is also hosted on github:
"https://github.com/fs111/pydoc.vim

"If you want to use the script and pydoc is not in your PATH, just put a line
"like  
"
" let g:pydoc_cmd = \"/usr/bin/pydoc" (without the backslash!!)
"
"in your .vimrc
"
"If you want to open pydoc files in vertical splits or tabs, give the
"appropriate command in
" let g:pydoc_open_cmd = \"vsplit"
" 
"or
"
" let g:pydoc_open_cmd = \"tabnew"
"
"The script will highlight the search-term by default. To disable this behaviour
"put
"
" let g:pydoc_highlight=0
"
" in your .vimrc. 
"
"pydoc.vim is free software, you can redistribute or modify
"it under the terms of the GNU General Public License Version 2 or any
"later Version (see http://www.gnu.org/copyleft/gpl.html for details). 

"Please feel free to contact me and follow me on twitter (@fs111)


set switchbuf=useopen
function! ShowPyDoc(name, type)
    if !exists('g:pydoc_cmd')
        let g:pydoc_cmd = 'pydoc'
    endif

    if !exists('g:pydoc_open_cmd')
        let g:pydoc_open_cmd = 'split'
    endif

    if g:pydoc_open_cmd == 'split'
        let l:pydoc_wh = 10
    endif

    if bufloaded("__doc__") >0
        let l:buf_is_new = 0
    else
        let l:buf_is_new = 1
    endif

    if bufnr("__doc__") >0
        execute g:pydoc_open_cmd.' | b __doc__'
    else
        execute g:pydoc_open_cmd.' __doc__'
    endif

    setlocal noswapfile
    set buftype=nofile
    setlocal modifiable
    normal ggdG
    " remove function/method arguments
    let s:name2 = substitute(a:name, '(.*', '', 'g' )
    " remove all colons
    let s:name2 = substitute(s:name2, ':', '', 'g' )
    if a:type==1
        execute  "silent read ! " . g:pydoc_cmd . " " . s:name2 
    else 
        execute  "silent read ! " . g:pydoc_cmd . " -k " . s:name2 
    endif	
    setlocal nomodified
    set filetype=man
    normal 1G

    if exists('l:pydoc_wh')
        execute "silent resize " . l:pydoc_wh 
    end

    if !exists('g:pydoc_highlight')
        let g:pydoc_highlight = 1
    endif
    if g:pydoc_highlight == 1
        call Highlight(s:name2)
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

"highlighting
function! Highlight(name)
    execute "sb __doc__"
    set filetype=man
    "syn on
    execute 'syntax keyword pydoc '.a:name
    hi pydoc gui=reverse
endfunction

"mappings
if !exists('g:pydoc_perform_mappings')
    let g:pydoc_perform_mappings = 1
endif
if g:pydoc_perform_mappings != 0
    au FileType python,man map <buffer> <leader>pw :call ShowPyDoc('<C-R><C-W>', 1)<CR>
    au FileType python,man map <buffer> <leader>pW :call ShowPyDoc('<C-R><C-A>', 1)<CR>
    au FileType python,man map <buffer> <leader>pk :call ShowPyDoc('<C-R><C-W>', 0)<CR>
    au FileType python,man map <buffer> <leader>pK :call ShowPyDoc('<C-R><C-A>', 0)<CR>

    " remap the K (or 'help') key
    nnoremap <silent> <buffer> K :call ShowPyDoc(expand("<cword>"), 1)<CR>
endif

"commands
command! -nargs=1 Pydoc :call ShowPyDoc('<args>', 1)
command! -nargs=*  PydocSearch :call ShowPyDoc('<args>', 0)
