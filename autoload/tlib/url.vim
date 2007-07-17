" url.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-06-30.
" @Revision:    0.0.2

if &cp || exists("loaded_tlib_url_autoload")
    finish
endif
let loaded_tlib_url_autoload = 1

" These functions could use printf() now.
function! tlib#url#Decode(url) "{{{3
    let rv = ''
    let n  = 0
    let m  = strlen(a:url)
    while n < m
        let c = a:url[n]
        if c == '+'
            let c = ' '
        elseif c == '%'
            if a:url[n + 1] == '%'
                let n = n + 1
            else
                " let c = escape(nr2char('0x'. strpart(a:url, n + 1, 2)), '\')
                let c = nr2char('0x'. strpart(a:url, n + 1, 2))
                let n = n + 2
            endif
        endif
        let rv = rv.c
        let n = n + 1
    endwh
    return rv
endf

function! tlib#url#EncodeChar(char) "{{{3
    if a:char == '%'
        return '%%'
    elseif a:char == ' '
        return '+'
    else
        " Taken from eval.txt
        let n = char2nr(a:char)
        let r = ''
        while n
            let r = '0123456789ABCDEF'[n % 16] . r
            let n = n / 16
        endwhile
        return '%'. r
    endif
endf

function! tlib#url#Encode(url) "{{{3
    return substitute(a:url, '\([^a-zA-Z0-9_.-]\)', '\=tlib#url#EncodeChar(submatch(1))', 'g')
endf


