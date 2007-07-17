" string.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-06-30.
" @Revision:    0.0.3

if &cp || exists("loaded_tlib_string_autoload")
    finish
endif
let loaded_tlib_string_autoload = 1

function! tlib#string#RemoveBackslashes(text, ...) "{{{3
    exec tlib#arg#Get(1, 'chars', ' ')
    " TLogVAR chars
    let rv = substitute(a:text, '\\\(['. chars .']\)', '\1', 'g')
    return rv
endf

