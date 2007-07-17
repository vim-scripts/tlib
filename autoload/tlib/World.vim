" World.vim -- The World prototype for tlib#input#List()
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-05-01.
" @Last Change: 2007-07-10.
" @Revision:    0.1.80

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
    " if self.RespondTo('MaySelectItem')
    "     if !self.MaySelectItem(bi)
    "         return 0
    "     endif
    " endif
    " TLogVAR bi
    let si = index(self.sel_idx, bi)
    " TLogVAR self.sel_idx
    " TLogVAR si
    if si == -1
        call add(self.sel_idx, bi)
    elseif a:mode == 'toggle'
        call remove(self.sel_idx, si)
    endif
    return 1
endf

function! s:prototype.FormatArgs(format_string, arg) dict "{{{3
    let nargs = len(substitute(a:format_string, '%%\|[^%]', '', 'g'))
    return [a:format_string] + repeat([string(a:arg)], nargs)
endf

function! s:prototype.GetRx(filter) "{{{3
    return '\('. join(filter(copy(a:filter), 'v:val[0] != "!"'), '\|') .'\)' 
endf

function! s:prototype.GetItem(idx) dict "{{{3
    return self.list[a:idx - 1]
endf

function! s:prototype.GetListIdx(baseidx) dict "{{{3
    return index(self.table, a:baseidx)
endf

function! s:prototype.GetBaseIdx(idx) dict "{{{3
    if !empty(self.table) && a:idx > 0
        return self.table[a:idx - 1]
    else
        return ''
    endif
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
    for filter in self.filter
        " TLogVAR filter
        let rx = join(reverse(filter(copy(filter), '!empty(v:val)')), '\|')
        " TLogVAR rx
        if rx[0] == '!'
            if len(rx) > 1 && a:text =~ mrx .'\('. rx[1:-1] .'\)'
                return 0
            endif
        elseif a:text !~ mrx .'\('. rx .'\)'
            return 0
        endif
        " if a:text !~ mrx. self.GetRx(filter)
        "     return 0
        " endif
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
    if len(self.filter[0]) > 1
        call remove(self.filter[0], 0)
    elseif len(self.filter) > 1
        call remove(self.filter, 0)
    else
        let self.filter[0] = ['']
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

function! s:prototype.UseScratch() "{{{3
    let id = get(self, 'scratch', '__InputList__')
    if id =~ '^\d\+$'
        if bufnr('%') != id
            exec 'buffer! '. id
        endif
    else
        let bn = bufnr(id)
        if bn != -1
            " TLogVAR bn
            let wn = bufwinnr(bn)
            if wn != -1
                " TLogVAR wn
                exec wn .'wincmd w'
            else
                let cmd = get(self, 'scratch_split', 1) ? 'botright sbuffer! ' : 'buffer! '
                silent exec cmd . bn
            endif
        else
            " TLogVAR id
            let cmd = get(self, 'scratch_split', 1) ? 'botright split ' : 'edit '
            silent exec cmd . escape(id, '%#\ ')
            " silent exec 'split '. id
        endif
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        setlocal modifiable
        setlocal foldmethod=manual
        set ft=tlibInputList
    endif
    let self.scratch = bufnr('%')
    return self.scratch
endf

function! s:prototype.CloseScratch() "{{{3
    let scratch = get(self, 'scratch', '')
    " TLogVAR scratch
    if !empty(scratch)
        let wn = bufwinnr(scratch)
        if wn != -1
            " TLogVAR wn
            exec wn .'wincmd w'
            wincmd c
            " redraw
        endif
        unlet self.scratch
    endif
endf

function! s:prototype.UseInputListScratch() "{{{3
    let scratch = self.UseScratch()
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
    call self.UseInputListScratch()
    call self.ResetSelected()
endf

function! s:prototype.ResetSelected() dict "{{{3
    let self.sel_idx   = []
endf



function! s:DisplayHelp(type, handlers) "{{{3
    let help = [
                \ 'Help:',
                \ 'Mouse   ... Pick an item            Letter       ... Filter the list',
                \ 'Number  ... Pick an item            +, |, !      ... AND, OR, (NOT)',
                \ 'Enter   ... Pick the current item   <bs>, <c-bs> ... Reduce filter',
                \ '<c|m-r> ... Reset the display       Up/Down      ... Next/previous item',
                \ '<c|m-q> ... Edit top filter string  Page Up/Down ... Scroll',
                \ '<c|m-z> ... Suspend/Resume          <Esc>        ... Abort',
                \ '',
                \ ]

    if stridx(a:type, 'm') != -1
        let help += [
                    \ '#, <c-space> ... (Un)Select the current item',
                    \ '<c|m-a>      ... (Un)Select all currently visible items',
                    \ '<s-up/down>  ... (Un)Select items',
                    \ ]
                    " \ '<c-\>        ... Show only selected',
    endif
    for handler in a:handlers
        let key = get(handler, 'key_name', '')
        if !empty(key)
            let desc = get(handler, 'help', '')
            call add(help, printf('%-12s ... %s', key, desc))
        endif
    endfor
    let help += [
                \ '',
                \ 'Warning:',
                \ 'Please don''t try to resize the window with the mouse.',
                \ '',
                \ 'Note on filtering:',
                \ 'The filter is prepended with "\V". Basically, filtering is case-insensitive.',
                \ 'Letters at word boundaries or upper-case lettes in camel-case names is given',
                \ 'more weight. If an OR-joined pattern start with "!", matches will be excluded.',
                \ '',
                \ 'Press any key to continue.',
                \ ]
    norm! ggdG
    call append(0, help)
    norm! Gddgg
    exec 'resize '. len(help)
endf

" DisplayList(type, handlers, query, ?list)
function! s:prototype.DisplayList(type, handlers, query, ...) "{{{3
    " TLogVAR a:query
    " TLogVAR self.state
    let list = a:0 >= 1 ? a:1 : []
    call self.UseScratch()
    if self.state == 'scroll'
        exec 'norm! '. self.offset .'zt'
    elseif self.state == 'help'
        call s:DisplayHelp(a:type, a:handlers)
    else
        let ll = len(list)
        let x  = len(ll) + 1
        " TLogVAR ll
        if self.state =~ '\<display\>'
            norm! ggdG
            let w = &co - &fdc - 1
            call append(0, map(copy(list), 'printf("%-'. w .'.'. w .'s", substitute(v:val, ''[[:cntrl:][:space:]]'', " ", "g"))'))
            " call append(0, a:query)
            norm! Gddgg
            " if self.state !~ '\<redisplay\>'
                let resize = get(self, 'resize', 0)
                " TLogVAR resize
                let resize = resize == 0 ? ll : min([ll, resize])
                let resize = min([resize, (&lines * 3 / 4)])
                " TLogVAR resize, ll, &lines
                exec 'resize '. resize
            " endif
        endif
        " TLogVAR self.prefidx
        let base_pref = self.GetBaseIdx(self.prefidx)
        " TLogVAR base_pref
        if self.state =~ '\<redisplay\>'
            call filter(b:tlibDisplayListMarks, 'index(self.sel_idx, v:val) == -1 && v:val != base_pref')
            " TLogVAR b:tlibDisplayListMarks
            call map(b:tlibDisplayListMarks, 'self.DisplayListMark(x, v:val, ":")')
            " let b:tlibDisplayListMarks = map(copy(self.sel_idx), 'self.DisplayListMark(x, v:val, "#")')
            " call add(b:tlibDisplayListMarks, self.prefidx)
            " call self.DisplayListMark(x, self.GetBaseIdx(self.prefidx), '*')
        endif
        let b:tlibDisplayListMarks = map(copy(self.sel_idx), 'self.DisplayListMark(x, v:val, "#")')
        call add(b:tlibDisplayListMarks, base_pref)
        call self.DisplayListMark(x, base_pref, '*')
        exec 'norm! '. self.offset .'zt'
        let &statusline = a:query
    endif
    redraw
endf

function! s:prototype.DisplayListMark(x, y, mark) "{{{3
    " TLogVAR a:y, a:mark
    if a:x > 0 && a:y >= 0
        " TLogDBG a:x .'x'. a:y .' '. a:mark
        let sy = self.GetListIdx(a:y) + 1
        " TLogVAR sy
        if sy >= 1
            call setpos('.', [0, sy, a:x, 0])
            exec 'norm! r'. a:mark
            " exec 'norm! '. a:y .'gg'. a:x .'|r'. a:mark
        endif
    endif
    return a:y
endf

