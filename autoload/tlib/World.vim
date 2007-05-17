" World.vim -- The World prototype for tlib#InputList()
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-05-01.
" @Last Change: 2007-05-17.
" @Revision:    0.1.25

if &cp || exists("loaded_tlib_world_autoload")
    finish
endif
let loaded_tlib_world_autoload = 1

let s:prototype = tlib#Object#New({'state': 'reset', 'type': '', 'base': [], 'list': [], 'sel_idx': []})
function! tlib#World#New(...)
    let object = s:prototype.New(a:0 >= 1 ? a:1 : {})
    return object
endf

function! s:prototype.GetSelectedItems(current) dict "{{{3
    if stridx(self.type, 'i') != -1
        let rv = copy(self.sel_idx)
    else
        let rv = map(copy(self.sel_idx), 'self.GetBaseItem(v:val)')
    endif
    if a:current != ''
        let ci = index(rv, a:current)
        if ci != -1
            call remove(rv, ci)
        endif
        call insert(rv, a:current)
    endif
    return rv
endf

function! s:prototype.SelectItem(mode, index) dict "{{{3
    let bi = self.GetBaseIdx(a:index)
    " TLogVAR bi
    let si = index(self.sel_idx, bi)
    " TLogVAR self.sel_idx
    " TLogVAR si
    if si == -1
        call add(self.sel_idx, bi)
    elseif a:mode == 'toggle'
        call remove(self.sel_idx, si)
    endif
endf

function! s:prototype.FormatArgs(format_string, arg) dict "{{{3
    let nargs = len(substitute(a:format_string, '%%\|[^%]', '', 'g'))
    return [a:format_string] + repeat([string(a:arg)], nargs)
endf

function! s:prototype.GetRx(filter) "{{{3
    return '\('. join(a:filter, '\|') .'\)' 
endf

function! s:prototype.GetItem(idx) dict "{{{3
    return self.list[a:idx - 1]
endf

function! s:prototype.GetListIdx(baseidx) dict "{{{3
    return index(self.table, a:baseidx)
endf

function! s:prototype.GetBaseIdx(idx) dict "{{{3
    return self.table[a:idx - 1]
endf

function! s:prototype.GetBaseItem(idx) dict "{{{3
    return self.base[a:idx - 1]
endf

function! s:prototype.SetBaseItem(idx, item) dict "{{{3
    let self.base[a:idx - 1] = a:item
endf

function! s:prototype.GetCurrentItem() dict "{{{3
    let idx = self.prefidx
    if stridx(self.type, 'i') != -1
        return idx
    elseif !empty(self.list)
        if len(self.list) >= idx
            return self.list[idx - 1]
        endif
    else
        return ''
    endif
endf

function! s:prototype.Match(text, ...) dict "{{{3
    let mrx = '\V'. (a:0 >= 1 && a:1 ? '\C' : '')
    for rx in self.filter
        if a:text !~ mrx. self.GetRx(rx)
            return 0
        endif
    endfor
    return 1
endf

function! s:prototype.MatchBaseIdx(filter_format, idx, ...) dict "{{{3
    let mrx  = '\V'. (a:0 >= 1 && a:1 ? '\C' : '')
    let text = self.GetBaseItem(a:idx)
    if !empty(a:filter_format)
        let text = eval(call(function("printf"), self.FormatArgs(a:filter_format, text)))
    endif
    return self.Match(text, mrx)
endf

function! s:prototype.ReduceFilter() dict "{{{3
    " TLogVAR self.filter
    if self.filter[0] == [''] && len(self.filter) > 1
        call remove(self.filter, 0)
    elseif empty(self.filter[0][0]) && len(self.filter[0]) > 1
        call remove(self.filter[0], 0)
    else
        let self.filter[0][0] = self.filter[0][0][0:-2]
    endif
endf

function! s:prototype.PopFilter() dict "{{{3
    " TLogVAR self.filter
    if len(self.filter) == 1
        let self.filter[0] = ['']
    else
        call remove(self.filter, 0)
    endif
endf

function! s:prototype.FilterIsEmpty() dict "{{{3
    " TLogVAR self.filter
    return self.filter == [['']]
endf

function! s:prototype.DisplayFilter() dict "{{{3
    " TLogVAR self.filter
    let filter1 = map(deepcopy(self.filter), '"(". join(reverse(v:val), " OR ") .")"')
    " TLogVAR filter1
    return join(reverse(filter1), ' AND ')
endf

function! s:UseInputListScratch(world) "{{{3
    let scratch = tlib#UseScratch(a:world)
    syntax match InputlListCursor /^\d\+\* .*$/
    syntax match InputlListSelected /^\d\+# .*$/
    hi def link InputlListCursor Search
    hi def link InputlListSelected IncSearch
    " hi def link InputlListIndex Special
    " let b:tlibDisplayListMarks = {}
    let b:tlibDisplayListMarks = []
    return scratch
endf

function! s:prototype.Reset() dict "{{{3
    let self.state     = 'display'
    let self.offset    = 1
    let self.filter    = [['']]
    let self.idx       = ''
    let self.prefidx   = 0
    let self.scratch   = s:UseInputListScratch(self)
    call self.ResetSelected()
endf

function! s:prototype.ResetSelected() dict "{{{3
    let self.sel_idx   = []
endf

