" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-04-26.
" @Revision:    0.3.46
" vimscript:    1863
"
" This is just a stub. See ../autoload/tlib.vim for the actual file.

if &cp || exists("loaded_tlib")
    finish
endif
let loaded_tlib = 3

if !exists('g:tlib_pick_last_item')| let g:tlib_pick_last_item = 1 | endif


finish
-----------------------------------------------------------------------
This library provides some utility functions. There isn't much need to 
install it unless another plugin requires you to do so.

tlib#InputList(type, query, list)
    Select items from a list that can be filtered using a regexp and 
    does some other tricks. The goal of the function is to let you 
    select items from a list with only a few keystrokes. The function 
    can be used to select a single item or multiple items.

tlib#EditList(query, list)
    Edit items in a list. Return the modified list.


CHANGES:
0.1
Initial release

0.2
- More list convenience functions
- tlib#EditList()
- tlib#InputList(): properly handle duplicate items; it type contains 
'i', the list index + 1 is returned, not the element

0.3
- Show feedback in statusline instead of the echo area
- tlib#GetVar(), tlib#GetValue()

