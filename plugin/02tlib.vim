" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-05-18.
" @Revision:    0.6.82
" vimscript:    1863
"
" This is just a stub. See ../autoload/tlib.vim for the actual file.

if &cp || exists("loaded_tlib")
    finish
endif
if v:version < 700 "{{{2
    echoerr "tlib requires Vim >= 7"
    finish
endif
let loaded_tlib = 6

if !exists('g:tlib_pick_last_item')      | let g:tlib_pick_last_item = 1        | endif
if !exists('g:tlib_sortprefs_threshold') | let g:tlib_sortprefs_threshold = 200 | endif

if !exists('g:tlib_numeric_chars')
    let g:tlib_numeric_chars = {
                \ 48: 48,
                \ 49: 48,
                \ 50: 48,
                \ 51: 48,
                \ 52: 48,
                \ 53: 48,
                \ 54: 48,
                \ 55: 48,
                \ 56: 48,
                \ 57: 48,
                \ 176: 176,
                \ 177: 176,
                \ 178: 176,
                \ 179: 176,
                \ 180: 176,
                \ 181: 176,
                \ 182: 176,
                \ 183: 176,
                \ 184: 176,
                \ 185: 176,
                \}
endif

