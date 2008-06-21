" rx.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-07-20.
" @Last Change: 2007-11-23.
" @Revision:    0.0.15

if &cp || exists("loaded_tlib_rx_autoload")
    finish
endif
let loaded_tlib_rx_autoload = 1


" :def: function! tlib#rx#Escape(text, ?magic='m')
" magic can be one of: m, M, v, V
" See :help 'magic'
function! tlib#rx#Escape(text, ...) "{{{3
    TVarArg 'magic'
    if empty(magic)
        let magic = 'm'
    endif
    if magic ==# 'm'
        return escape(a:text, '^$.*\[]~')
    elseif magic ==# 'M'
        " echoerr 'tlib: Unsupported magic type'
        return escape(a:text, '^$\')
    elseif magic ==# 'V'
        return escape(a:text, '\')
    elseif magic ==# 'v'
        " let chars = '^$.*+\()|{}[]~'
        return substitute(a:text, '[^0-9a-zA-Z_]', '\\&', 'g')
    else
        echoerr 'tlib: Unsupported magic type'
        return a:text
    endif
endf

