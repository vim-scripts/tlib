" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    111


" :def: function! tlib#rx#Escape(text, ?magic='m')
" magic can be one of: m, M, v, V
" See :help 'magic'
function! tlib#rx#Escape(text, ...) "{{{3
    TVarArg 'magic'
    if empty(magic)
        let magic = 'm'
    endif
    if magic =~# '^\\\?m$'
        return escape(a:text, '^$.*\[]~')
    elseif magic =~# '^\\\?M$'
        return escape(a:text, '^$\')
    elseif magic =~# '^\\\?V$'
        return escape(a:text, '\')
    elseif magic =~# '^\\\?v$'
        return substitute(a:text, '[^0-9a-zA-Z_]', '\\&', 'g')
    else
        echoerr 'tlib: Unsupported magic type'
        return a:text
    endif
endf

" :def: function! tlib#rx#EscapeReplace(text, ?magic='m')
" Escape return |sub-replace-special|.
function! tlib#rx#EscapeReplace(text, ...) "{{{3
    TVarArg ['magic', 'm']
    if magic ==# 'm' || magic ==# 'v'
        return escape(a:text, '\&~')
    elseif magic ==# 'M' || magic ==# 'V'
        return escape(a:text, '\')
    else
        echoerr 'magic must be one of: m, v, M, V'
    endif
endf


function! tlib#rx#Suffixes(...) "{{{3
    TVarArg ['magic', 'm']
    let sfx = split(&suffixes, ',')
    call map(sfx, 'tlib#rx#Escape(v:val, magic)')
    if magic ==# 'v'
        return '('. join(sfx, '|') .')$'
    elseif magic ==# 'V'
        return '\('. join(sfx, '\|') .'\)\$'
    else
        return '\('. join(sfx, '\|') .'\)$'
    endif
endf


let s:rxmap_m_to_x = {
            \ 'v': {'^': '^', '$': '$', '.': '\.', '\(': '\(', '\)': '\)', '\|': '\|', '\.': '.', '\{': '{',
            \       '*': '*', '\+': '+', '\?': '?', '\=': '=', '[': '['},
            \ 'M': {'^': '^', '$': '$', '.': '\.', '\(': '\(', '\)': '\)', '\|': '\|', '\.': '.', '\{': '\{',
            \       '*': '\*', '\+': '\+', '\?': '\?', '\=': '\=', '[': '['},
            \ 'V': {'^': '\^', '$': '\$', '.': '\.', '\(': '\(', '\)': '\)', '\|': '\|', '\.': '.', '\{': '\{',
            \       '*': '\*', '\+': '\+', '\?': '\?', '\=': '\=', '[': '\['},
            \ }


" :display: tlib#rx#Convert(rx, to, ?from = 'guess')
" Convert a subset of |regexp| expressions to another form.
" Supported types: m, M, v, V
" Supported expressions: ^, $, ., \(\|), \{}, *, \+, \?, \=, []
function! tlib#rx#Convert(rx, to, ...) abort "{{{3
    TVarArg ['from', 'guess']
    if type(a:rx) == 4
        let rxdef = a:rx
    else
        let rxdef = {'rx': a:rx}
    endif
    if from ==# 'guess'
        if rxdef.rx =~# '\\\@<!\\V'
            let from = 'V'
        elseif rxdef.rx =~# '\\\@<!\\v'
            let from = 'v'
        elseif rxdef.rx =~# '\\\@<!\\M'
            let from = 'M'
        elseif &magic
            let from = 'm'
        else
            let from = 'M'
        endif
    endif
    let rxdef.rx = substitute(rxdef.rx, '\\\@<!\\[vVmM]', '', 'g')
    " TLogVAR rxdef, from, a:to
    if from !=# 'm'
        if a:to ==# 'm'
            let def = s:rxmap_m_to_x[from]
            let rev = tlib#dictionary#Rev(def)
            let rxdef.rx = s:ConvertRx(rxdef.rx, rev, def)
        else
            let rxdef = tlib#rx#Convert(rxdef, 'm', from)
        endif
    endif
    if a:to != 'm'
        let def = s:rxmap_m_to_x[a:to]
        let def1 = filter(copy(def), 'v:key !~ "^option_"')
        let rev = tlib#dictionary#Rev(def1)
        let rxdef = s:CheckCaseSensitive(rxdef, def)
        let rxdef.rx = s:ConvertRx(rxdef.rx, rev, def)
    endif
    return rxdef
endf


function! s:CheckCaseSensitive(rxdef, def) abort "{{{3
    if !get(a:def, 'option_support_c', 1)
        let rx = a:rxdef.rx
        if rx =~? '\\\@<!\\c'
            if rx =~# '\\\@<!\\c'
                let a:rxdef.casesensitive = 0
            else
                let a:rxdef.casesensitive = 1
            endif
            let rx = substitute(rx, '\\\@<!\\[cC]', '', 'g')
            let a:rxdef.rx = rx
        endif
    endif
    return a:rxdef
endf


function! s:ConvertRx(rx, def, rev) abort "{{{3
    " TLogVAR a:rx, a:def, a:rev
    let prx = map(filter(values(a:def), 'v:val !~# ''^\\'''), 'tlib#rx#Escape(v:val)')
    let rrx = printf('\%%(\\.\|%s\)', join(prx, '\|'))
    " TLogVAR rrx
    let rx = substitute(a:rx, rrx, '\=s:ReplaceRx(submatch(0), a:rev)', 'g')
    " TLogVAR rx
    return rx
endf


function! s:ReplaceRx(match, rev) abort "{{{3
    if has_key(a:rev, a:match)
        return a:rev[a:match]
    elseif a:match =~# '^\\'
        return substitute(a:match, '^\\', '', '')
    else
        return a:match
    endif
endf

