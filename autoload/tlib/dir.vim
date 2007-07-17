" dir.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-06-30.
" @Revision:    0.0.4

if &cp || exists("loaded_tlib_dir_autoload")
    finish
endif
let loaded_tlib_dir_autoload = 1

" EXAMPLES:
" tlib#dir#CanonicName('foo/bar')
" => 'foo/bar/'
function! tlib#dir#CanonicName(dirname) "{{{3
    if a:dirname !~ '[/\\]$'
        return a:dirname . g:tlib_filename_sep
    endif
    return a:dirname
endf

" Create a directory if it doesn't already exist.
function! tlib#dir#Ensure(dir) "{{{3
    if !isdirectory(a:dir)
        return mkdir(a:dir, 'p')
    endif
    return 1
endf

" Return the first directory in &rtp.
function! tlib#dir#MyRuntime() "{{{3
    return get(split(&rtp, ','), 0)
endf

