" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-04-18.
" @Revision:    0.1.38
"
" This is just a stub. See ../autoload/tlib.vim for the actual file.

if &cp || exists("loaded_tlib")
    finish
endif
let loaded_tlib = 1


finish

This library provides some utility functions. There isn't much need to 
install it unless another plugin requires you to do so.

These commands use the tlib#InputList() function to select items from a 
list that can be filtered using a regexp and does some other tricks. The 
goal of the function is to let you select items from a list with only a 
few keystrokes. The function can be used to select a single item or 
multiple items.


0.1
Initial release

