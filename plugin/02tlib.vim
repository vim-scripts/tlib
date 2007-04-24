" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-04-22.
" @Revision:    0.1.43
" vimscript:    1863
"
" This is just a stub. See ../autoload/tlib.vim for the actual file.

if &cp || exists("loaded_tlib")
    finish
endif
let loaded_tlib = 1

if !exists('g:tlib_pick_last_item')| let g:tlib_pick_last_item = 1 | endif

