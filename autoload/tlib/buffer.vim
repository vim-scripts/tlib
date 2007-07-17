" buffer.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-06-30.
" @Revision:    0.0.2

if &cp || exists("loaded_tlib_buffer_autoload")
    finish
endif
let loaded_tlib_buffer_autoload = 1

" tlib#buffer#Eval(buffer, code)
" Evaluate CODE in BUFFER.
"
" EXAMPLES:
" call tlib#buffer#Eval('foo.txt', 'echo b:bar')
function! tlib#buffer#Eval(buffer, code) "{{{3
    let cb = bufnr('%')
    let wb = bufwinnr('%')
    " TLogVAR cb
    let sn = bufnr(a:buffer)
    let sb = sn != cb
    let lazyredraw = &lazyredraw
    set lazyredraw
    try
        if sb
            let ws = bufwinnr(sn)
            if ws != -1
                try
                    exec ws.'wincmd w'
                    exec a:code
                finally
                    exec wb.'wincmd w'
                endtry
            else
                try
                    silent exec 'sbuffer! '. sn
                    exec a:code
                finally
                    wincmd c
                endtry
            endif
        else
            exec a:code
        endif
    finally
        let &lazyredraw = lazyredraw
    endtry
endf


