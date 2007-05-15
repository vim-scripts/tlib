" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-05-12.
" @Revision:    0.4.70
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
let loaded_tlib = 4

if !exists('g:tlib_pick_last_item') | let g:tlib_pick_last_item = 1 | endif

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
- tlib#InputList(): Show feedback in statusline instead of the echo area
- tlib#GetVar(), tlib#GetValue()

0.4
- tlib#InputList(): Up/Down keys wrap around list
- tlib#InputList(): FIX: Problem when reducing the filter & using AND
- tlib#InputList(): Made <a-numeric> work (can be configured via 
- tlib#InputList(): special display_format: "filename"
- tlib#Object: experimental support for some kind of OOP
- tlib#World: Extracted some functions from tlib.vim to tlib/World.vim
- tlib#FileJoin(), tlib#FileSplit(), tlib#RelativeFilename()
- tlib#Let()
- tlib#EnsureDirectoryExists(dir)
- tlib#DirName(dir)
- tlib#DecodeURL(url), tlib#EncodeChar(char), tlib#EncodeURL(url)
- FIX: Problem when using shift-up/down with filtered lists

