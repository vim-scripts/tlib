" string.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-09-13.
" @Revision:    0.0.14

if &cp || exists("loaded_tlib_string_autoload")
    finish
endif
let loaded_tlib_string_autoload = 1


" :def: function! tlib#string#RemoveBackslashes(text, ?chars=' ')
" Remove backslashes from text (but only in front of the characters in 
" chars).
function! tlib#string#RemoveBackslashes(text, ...) "{{{3
    exec tlib#arg#Get(1, 'chars', ' ')
    " TLogVAR chars
    let rv = substitute(a:text, '\\\(['. chars .']\)', '\1', 'g')
    return rv
endf

function! tlib#string#Chomp(string) "{{{3
    return substitute(a:string, '[[:cntrl:][:space:]]*$', '', '')
endf

