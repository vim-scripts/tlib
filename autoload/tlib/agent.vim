" agent.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-24.
" @Last Change: 2007-07-18.
" @Revision:    0.1.47

if &cp || exists("loaded_tlib_agent_autoload")
    finish
endif
let loaded_tlib_agent_autoload = 1


" General {{{1
function! tlib#agent#Exit(world, selected) "{{{3
    call a:world.CloseScratch()
    let a:world.state = 'exit escape'
    let a:world.list = []
    " let a:world.base = []
    call a:world.ResetSelected()
    return a:world
endf

function! tlib#agent#CopyItems(world, selected)
    let @* = join(a:selected, "\n")
    let a:world.state = 'redisplay'
    return a:world
endf


" InputList related {{{1
function! tlib#agent#PageUp(world, selected) "{{{3
    let a:world.offset -= (winheight(0) / 2)
    let a:world.state = 'scroll'
    return a:world
endf

function! tlib#agent#PageDown(world, selected) "{{{3
    let a:world.offset += (winheight(0) / 2)
    let a:world.state = 'scroll'
    return a:world
endf

function! tlib#agent#Up(world, selected) "{{{3
    let a:world.idx = ''
    if a:world.prefidx > 1
        let a:world.prefidx -= 1
    else
        let a:world.prefidx = len(a:world.list)
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! tlib#agent#Down(world, selected) "{{{3
    let a:world.idx = ''
    if a:world.prefidx < len(a:world.list)
        let a:world.prefidx += 1
    else
        let a:world.prefidx = 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! tlib#agent#Reset(world, selected) "{{{3
    let a:world.state = 'reset'
    return a:world
endf

function! tlib#agent#Input(world, selected) "{{{3
    let flt0 = a:world.filter[0][0]
    let flt1 = input('Filter: ', flt0)
    echo
    if flt1 != flt0 && !empty(flt1)
        let a:world.filter[0][0] = flt1
    endif
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#Suspend(world, selected) "{{{3
    let bn = bufnr('.')
    let wn = bufwinnr(bn)
    exec 'noremap <buffer> <c-z> :call <SID>Resume("world", '. bn .', '. wn .')<cr>'
    let b:tlib_world = a:world
    let a:world.state = 'exit suspend'
    return a:world
endf

function! s:Resume(name, bn, wn) "{{{3
    echo
    let b:tlib_{a:name}.state = 'display'
    call tlib#input#List('resume '. a:name)
endf

function! tlib#agent#Help(world, selected) "{{{3
    let a:world.state = 'help'
    return a:world
endf

function! tlib#agent#OR(world, selected) "{{{3
    if !empty(a:world.filter[0])
        call insert(a:world.filter[0], '')
    endif
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#AND(world, selected) "{{{3
    if !empty(a:world.filter[0])
        call insert(a:world.filter, [''])
    endif
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#ReduceFilter(world, selected) "{{{3
    call a:world.ReduceFilter()
    let a:world.offset = 1
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#PopFilter(world, selected) "{{{3
    call a:world.PopFilter()
    let a:world.offset = 1
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#Debug(world, selected) "{{{3
    " echo string(world.state)
    echo string(a:world.filter)
    echo string(a:world.idx)
    echo string(a:world.prefidx)
    echo string(a:world.sel_idx)
    call getchar()
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#Select(world, selected) "{{{3
    call a:world.SelectItem('toggle', a:world.prefidx)
    " let a:world.state = 'display keepcursor'
    let a:world.state = 'redisplay'
    return a:world
endf

function! tlib#agent#SelectUp(world, selected) "{{{3
    call a:world.SelectItem('toggle', a:world.prefidx)
    if a:world.prefidx > 1
        let a:world.prefidx -= 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! tlib#agent#SelectDown(world, selected) "{{{3
    call a:world.SelectItem('toggle', a:world.prefidx)
    if a:world.prefidx < len(a:world.list)
        let a:world.prefidx += 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! tlib#agent#SelectAll(world, selected) "{{{3
    let listrange = range(1, len(a:world.list))
    let mode = empty(filter(copy(listrange), 'index(a:world.sel_idx, a:world.GetBaseIdx(v:val)) == -1'))
                \ ? 'toggle' : 'set'
    for i in listrange
        call a:world.SelectItem(mode, i)
    endfor
    let a:world.state = 'display keepcursor'
    return a:world
endf


" EditList related {{{1
function! tlib#agent#EditItem(world, selected) "{{{3
    let lidx = a:world.prefidx
    " TLogVAR lidx
    " TLogVAR a:world.table
    let bidx = a:world.GetBaseIdx(lidx)
    " TLogVAR bidx
    let item = a:world.GetBaseItem(bidx)
    let item = input(lidx .'@'. bidx .': ', item)
    if item != ''
        call a:world.SetBaseItem(bidx, item)
    endif
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#NewItem(world, selected) "{{{3
    let basepi = a:world.GetBaseIdx(a:world.prefidx)
    let item = input('New item: ')
    call insert(a:world.base, item, basepi)
    let a:world.state = 'reset'
    return a:world
endf

function! tlib#agent#DeleteItems(world, selected) "{{{3
    let remove = copy(a:world.sel_idx)
    let basepi = a:world.GetBaseIdx(a:world.prefidx)
    if index(remove, basepi) == -1
        call add(remove, basepi)
    endif
    " call map(remove, 'a:world.GetBaseIdx(v:val)')
    for idx in reverse(sort(remove))
        call remove(a:world.base, idx - 1)
    endfor
    let a:world.state = 'display'
    call a:world.ResetSelected()
    " let a:world.state = 'reset'
    return a:world
endf


function! tlib#agent#Cut(world, selected) "{{{3
    let world = tlib#agent#Copy(a:world, a:selected)
    return tlib#agent#DeleteItems(world, a:selected)
endf

function! tlib#agent#Copy(world, selected) "{{{3
    let a:world.clipboard = []
    let bidxs = copy(a:world.sel_idx)
    call add(bidxs, a:world.GetBaseIdx(a:world.prefidx))
    for bidx in sort(bidxs)
        call add(a:world.clipboard, a:world.GetBaseItem(bidx))
    endfor
    let a:world.state = 'redisplay'
    return a:world
endf

function! tlib#agent#Paste(world, selected) "{{{3
    if has_key(a:world, 'clipboard')
        for e in reverse(copy(a:world.clipboard))
            call insert(a:world.base, e, a:world.prefidx)
        endfor
    endif
    let a:world.state = 'display'
    call a:world.ResetSelected()
    return a:world
endf

function! tlib#agent#EditReturnValue(world, rv) "{{{3
    return [a:world.state !~ '\<exit\>', a:world.base]
endf



" Files related {{{1
function! tlib#agent#ViewFile(world, selected)
    if a:world.SwitchWindow('win')
        call tlib#file#With('edit', 'buffer', a:selected, a:world)
        if !a:world.SwitchWindow('list')
            throw 'tlib: Cannot switch back to list window: '. string(a:world)
        end
    endif
    let a:world.state = 'display'
    return a:world
endf

function! tlib#agent#EditFile(world, selected)
    return tlib#agent#Exit(tlib#agent#ViewFile(world, a:selected), a:selected)
endf

function! tlib#agent#EditFileInSplit(world, selected)
    call a:world.CloseScratch()
    " call tlib#file#With('edit', 'buffer', a:selected[0:0], a:world)
    " call tlib#file#With('split', 'sbuffer', a:selected[1:-1], a:world)
    call tlib#file#With('split', 'sbuffer', a:selected, a:world)
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#EditFileInVSplit(world, selected)
    call a:world.CloseScratch()
    " call tlib#file#With('edit', 'buffer', a:selected[0:0], a:world)
    " call tlib#file#With('vertical split', 'vertical sbuffer', a:selected[1:-1], a:world)
    call tlib#file#With('vertical split', 'vertical sbuffer', a:selected, a:world)
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#EditFileInTab(world, selected)
    call a:world.CloseScratch()
    call tlib#file#With('tabedit', 'tab buffer', a:selected, a:world)
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#ToggleScrollbind(world, selected)
    let a:world.scrollbind = get(a:world, 'scrollbind') ? 0 : 1
    let a:world.state = 'redisplay'
    return a:world
endf

