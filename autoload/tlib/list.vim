" list.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-06-30.
" @Revision:    0.0.3

if &cp || exists("loaded_tlib_list_autoload")
    finish
endif
let loaded_tlib_list_autoload = 1

""" List related functions {{{1
" For the following functions please see ../../test/tlib.vim for examples.

" EXAMPLES:
" echo tlib#list#Inject([1,2,3], 0, function('Add')
" => 6
function! tlib#list#Inject(list, value, Function) "{{{3
    if empty(a:list)
        return a:value
    else
        let item  = a:list[0]
        let rest  = a:list[1:-1]
        let value = call(a:Function, [a:value, item])
        return tlib#list#Inject(rest, value, a:Function)
    endif
endf

" EXAMPLES:
" tlib#list#Compact([0,1,2,3,[], {}, ""])
" => [1,2,3]
function! tlib#list#Compact(list) "{{{3
    return filter(copy(a:list), '!empty(v:val)')
endf

" EXAMPLES:
" tlib#list#Flatten([0,[1,2,[3,""]]])
" => [0,1,2,3,""]
function! tlib#list#Flatten(list) "{{{3
    let acc = []
    for e in a:list
        if type(e) == 3
            let acc += tlib#list#Flatten(e)
        else
            call add(acc, e)
        endif
        unlet e
    endfor
    return acc
endf

" tlib#list#FindAll(list, filter, ?process_expr="")
" Basically the same as filter()
"
" EXAMPLES:
" tlib#list#FindAll([1,2,3], 'v:val >= 2')
" => [2, 3]
function! tlib#list#FindAll(list, filter, ...) "{{{3
    let rv   = filter(copy(a:list), a:filter)
    if a:0 >= 1 && a:1 != ''
        let rv = map(rv, a:1)
    endif
    return rv
endf

" tlib#list#Find(list, filter, ?default="", ?process_expr="")
"
" EXAMPLES:
" tlib#list#Find([1,2,3], 'v:val >= 2')
" => 2
function! tlib#list#Find(list, filter, ...) "{{{3
    let default = a:0 >= 1 ? a:1 : ''
    let expr    = a:0 >= 2 ? a:2 : ''
    return get(tlib#list#FindAll(a:list, a:filter, expr), 0, default)
endf

" EXAMPLES:
" tlib#list#Any([1,2,3], 'v:val >= 2')
" => 1
function! tlib#list#Any(list, expr) "{{{3
    return !empty(tlib#list#FindAll(a:list, a:expr))
endf

" EXAMPLES:
" tlib#list#All([1,2,3], 'v:val >= 2')
" => 0
function! tlib#list#All(list, expr) "{{{3
    return len(tlib#list#FindAll(a:list, a:expr)) == len(a:list)
endf

" EXAMPLES:
" tlib#list#Remove([1,2,1,2], 2)
" => [1,1,2]
function! tlib#list#Remove(list, element) "{{{3
    let idx = index(a:list, a:element)
    if idx != -1
        call remove(a:list, idx)
    endif
    return a:list
endf

" EXAMPLES:
" tlib#list#RemoveAll([1,2,1,2], 2)
" => [1,1]
function! tlib#list#RemoveAll(list, element) "{{{3
    call filter(a:list, 'v:val != a:element')
    return a:list
endf


