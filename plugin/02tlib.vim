" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-07-09.
" @Revision:    0.9.129
" GetLatestVimScripts: 1863 1 tlib.vim
"
" Please see also ../test/tlib.vim for usage examples.
"
" TODO:
" - tlib#input#List() shouldn't take a list of handlers but an instance 
"   of tlib#World as argument.

if &cp || exists("loaded_tlib")
    finish
endif
if v:version < 700 "{{{2
    echoerr "tlib requires Vim >= 7"
    finish
endif
let loaded_tlib = 9

" When 1, automatically select a single item (after applying the filter).
if !exists('g:tlib_pick_last_item')      | let g:tlib_pick_last_item = 1        | endif

" If a list is bigger than this value, don't try to be smart when 
" selecting an item. Be slightly faster instead.
if !exists('g:tlib_sortprefs_threshold') | let g:tlib_sortprefs_threshold = 200 | endif

" When editing a list typing these numeric chars (as returned by 
" getchar()) will select an item based on its index, not based on its 
" name. I.e. in the default setting, typing a "4" will select the fourth 
" item, not the item called "4".
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

if !exists('g:tlib_handlers_EditList') "{{{2
    let g:tlib_handlers_EditList = [
                \ {'key': 5,  'agent': 'tlib#agent#EditItem',    'key_name': '<c-e>', 'help': 'Edit item'},
                \ {'key': 4,  'agent': 'tlib#agent#DeleteItems', 'key_name': '<c-d>', 'help': 'Delete item(s)'},
                \ {'key': 14, 'agent': 'tlib#agent#NewItem',     'key_name': '<c-n>', 'help': 'New item'},
                \ {'key': 24, 'agent': 'tlib#agent#Cut',         'key_name': '<c-x>', 'help': 'Cut item(s)'},
                \ {'key':  3, 'agent': 'tlib#agent#Copy',        'key_name': '<c-c>', 'help': 'Copy item(s)'},
                \ {'key': 22, 'agent': 'tlib#agent#Paste',       'key_name': '<c-v>', 'help': 'Paste item(s)'},
                \ {'pick_last_item': 0},
                \ {'return_agent': 'tlib#agent#EditReturnValue'},
                \ ]
endif

if !exists('g:tlib_keyagents_InputList_s') "{{{2
    let g:tlib_keyagents_InputList_s = {
                \ "\<PageUp>":   'tlib#agent#PageUp',
                \ "\<PageDown>": 'tlib#agent#PageDown',
                \ "\<Up>":       'tlib#agent#Up',
                \ "\<Down>":     'tlib#agent#Down',
                \ 18:            'tlib#agent#Reset',
                \ 242:           'tlib#agent#Reset',
                \ 17:            'tlib#agent#Input',
                \ 241:           'tlib#agent#Input',
                \ 27:            'tlib#agent#Exit',
                \ 26:            'tlib#agent#Suspend',
                \ 250:           'tlib#agent#Suspend',
                \ 63:            'tlib#agent#Help',
                \ "\<F1>":       'tlib#agent#Help',
                \ 124:           'tlib#agent#OR',
                \ 43:            'tlib#agent#AND',
                \ "\<bs>":       'tlib#agent#ReduceFilter',
                \ "\<del>":      'tlib#agent#ReduceFilter',
                \ "\<c-bs>":     'tlib#agent#PopFilter',
                \ "\<m-bs>":     'tlib#agent#PopFilter',
                \ "\<c-del>":    'tlib#agent#PopFilter',
                \ "\<m-del>":    'tlib#agent#PopFilter',
                \ 191:           'tlib#agent#Debug',
                \ }
endif

if !exists('g:tlib_keyagents_InputList_m') "{{{2
    " "\<c-space>": 'tlib#agent#Select'
    let g:tlib_keyagents_InputList_m = {
                \ 35:          'tlib#agent#Select',
                \ "\<s-up>":   'tlib#agent#SelectUp',
                \ "\<s-down>": 'tlib#agent#SelectDown',
                \ 1:           'tlib#agent#SelectAll',
                \ 225:         'tlib#agent#SelectAll',
                \ }
endif

if !exists('g:tlib_filename_sep') "{{{2
    let g:tlib_filename_sep = '/'
    " let g:tlib_filename_sep = exists('+shellslash') && !&shellslash ? '\' : '/'
endif


" See tlib#var#Let() for an example.
command! -nargs=+ TLLet exec tlib#var#Let(<args>)


" runtime autoload/tlib/agent.vim


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

0.5
- tlib#InputList(): FIX: Selecting items in filtered view
- tlib#InputList(): <c-bs>: Remove last AND pattern from filter

0.6
- tlib#InputList(): Disabled <c-space> map
- tlib#InputList(): try to be smart about user itentions only if a 
list's length is < g:tlib_sortprefs_threshold (default: 200)
- tlib#Object: Super() method
- tlib#MyRuntimeDir()
- tlib#GetCacheName(), tlib#CacheSave(), tlib#CacheGet()
- tlib#Args(), tlib#GetArg()
- FIX: tlib#InputList(): Display problem with first item

0.7
- tlib#InputList(): <c-z> ... Suspend/Resume input
- tlib#InputList(): <c-q> ... Input text on the command line (useful on 
slow systems when working with very large lists)
- tlib#InputList(): AND-pattern starting with '!' will work as 'exclude 
matches'
- tlib#InputList(): FIX <c-bs> pop OR-patterns properly
- tlib#InputList(): display_format == filename: don't add '/' to 
directory names (avoid filesystem access)

0.8
- FIX: Return empty cache name for buffers that have no files attached to it
- Some re-arranging

0.9
- Re-arrangements & modularization (this means many function names have 
changed, on the other hand only those functions are loaded that are 
actually needed)
- tlib#input#List(): Added maps with m-modifiers for <c-q>, <c-z>, <c-a>
- tlib#input#List(): Make sure &fdm is manual
- tlib#input#List(): When exiting the list view, consume the next 5 
characters in the queue (if any)
- tlib#input#EditList(): Now has cut, copy, paste functionality.
- Added documentation and examples


" - tlib#input#List(): Numbers without modifiers are now consideres part of 
" the filename by default (check out g:tlib_numeric_chars for how to 
" change this).

