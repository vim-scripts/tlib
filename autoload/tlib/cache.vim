" cache.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-06-30.
" @Revision:    0.1.6

if &cp || exists("loaded_tlib_cache_autoload")
    finish
endif
let loaded_tlib_cache_autoload = 1

" tlib#cache#Filename(type, ?file=%, ?mkdir=0)
function! tlib#cache#Filename(type, ...) "{{{3
    " TLogDBG 'bufname='. bufname('.')
    if empty(expand('%:t'))
        return ''
    endif
    let file  = a:0 >= 1 && !empty(a:1) ? a:1 : expand('%:p')
    let mkdir = a:0 >= 2 ? a:2 : 0
    let dir   = tlib#dir#MyRuntime()
    let file  = tlib#file#Relative(file, dir)
    let file  = substitute(file, '\.\.\|[:&<>]\|//\+\|\\\\\+', '_', 'g')
    let dir   = tlib#file#Join([dir, 'cache', a:type, fnamemodify(file, ':h')])
    let file  = fnamemodify(file, ':t')
    " TLogVAR dir
    " TLogVAR file
    if mkdir && !isdirectory(dir)
        call mkdir(dir, 'p')
    endif
    retur tlib#file#Join([dir, file])
endf

function! tlib#cache#Save(cfile, dictionary) "{{{3
    if !empty(a:cfile)
        call writefile([string(a:dictionary)], a:cfile, 'b')
    endif
endf

function! tlib#cache#Get(cfile) "{{{3
    if !empty(a:cfile) && filereadable(a:cfile)
        let val = readfile(a:cfile, 'b')
        return eval(join(val, "\n"))
    else
        return {}
    endif
endf


