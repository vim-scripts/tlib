" scratch.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-07-18.
" @Last Change: 2007-07-18.
" @Revision:    0.0.3

if &cp || exists("loaded_tlib_scratch_autoload")
    finish
endif
let loaded_tlib_scratch_autoload = 1

function! tlib#scratch#UseScratch(keyargs) "{{{3
    let id = get(a:keyargs, 'scratch', '__InputList__')
    if id =~ '^\d\+$'
        if bufnr('%') != id
            exec 'buffer! '. id
        endif
    else
        let bn = bufnr(id)
        if bn != -1
            " TLogVAR bn
            let wn = bufwinnr(bn)
            if wn != -1
                " TLogVAR wn
                exec wn .'wincmd w'
            else
                let cmd = get(a:keyargs, 'scratch_split', 1) ? 'botright sbuffer! ' : 'buffer! '
                silent exec cmd . bn
            endif
        else
            " TLogVAR id
            let cmd = get(a:keyargs, 'scratch_split', 1) ? 'botright split ' : 'edit '
            silent exec cmd . escape(id, '%#\ ')
            " silent exec 'split '. id
        endif
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        setlocal modifiable
        setlocal foldmethod=manual
        set ft=tlibInputList
    endif
    let a:keyargs.scratch = bufnr('%')
    return a:keyargs.scratch
endf

function! tlib#scratch#CloseScratch(keyargs) "{{{3
    let scratch = get(a:keyargs, 'scratch', '')
    " TLogVAR scratch
    if !empty(scratch)
        let wn = bufwinnr(scratch)
        if wn != -1
            " TLogVAR wn
            exec wn .'wincmd w'
            wincmd c
            " redraw
        endif
        unlet a:keyargs.scratch
    endif
endf


