" cmd.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-08-23.
" @Last Change: 2007-08-23.
" @Revision:    0.0.3

if &cp || exists("loaded_tlib_cmd_autoload")
    finish
endif
let loaded_tlib_cmd_autoload = 1

function! tlib#cmd#OutputAsList(command) "{{{3
    redir => lines
    silent! exec a:command
    redir END
    return split(lines, '\n')
endf

