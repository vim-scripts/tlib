" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=vim-tlib)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-04-18.
" @Revision:    679
"
" TODO:
" - Agents: pass a dictionary {'state', 'list0', 'list', 'selected', 
"   'prefidx, 'idx'} & select these items only in this dictionary.
" - InputList redraws the list too often. The InputlListCursor 
"   highlight group should use a line number instead, which would make 
"   the cursor keys work more efficiently.


if &cp || exists("loaded_tlib_autoload") "{{{2
    finish
endif
let loaded_tlib_autoload = 1


""" Scratch buffer {{{1

fun! tlib#UseScratch(world) "{{{3
    let id = get(a:world, 'scratch', '__InputList__')
    if id =~ '^\d\+$'
        if bufnr('%') != id
            exec 'b '. id
        endif
    else
        let bn = bufnr(id)
        if bn != -1
            silent exec 'botright sbuffer '. bn
        else
            silent exec 'botright split '. escape(id, '%#\ ')
            " silent exec 'split '. id
        endif
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        setlocal modifiable
        setlocal ft=tlibInputList
    endif
    return bufnr('%')
endf

fun! tlib#CloseScratch(world) "{{{3
    call tlib#UseScratch(a:world)
    wincmd c
    redraw
endf


""" Input-related, select from a list etc. {{{1

fun! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

fun! s:DisplayHelp(type, handlers)
    let help = [
                \ 'Help:',
                \ 'Mouse        ... Pick an item              Up/Down      ... Next/previous item',
                \ 'Number       ... Pick an item              Page Up/Down ... Scroll',
                \ 'Enter        ... Pick the current item     CTRL-R       ... Reset the display',
                \ 'Letter       ... Filter the list           Esc          ... Abort',
                \ '',
                \ ]
    if stridx(a:type, 'm') != -1
        let help += [
                    \ 'CTRL-A       ... (Un)Select all filtered items',
                    \ 'CTRL-SPACE   ... (Un)Select the current item',
                    \ ]
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
                \ 'When you type some letters, the input routine tries to guess which',
                \ 'item you want to select. A pattern that starts at word boundaries or',
                \ 'in camel-case names is given more weight. Otherwise, filtering is',
                \ 'case-insensitive.',
                \ '',
                \ 'The filter is prepended with "\V". You can use "<SPACE>" to add "\.\{-}"',
                \ 'to the pattern, and "|" to add "\|".',
                \ '',
                \ 'Press any key to continue.',
                \ ]
    norm! ggdG
    call append(0, help)
    norm! Gddgg
    exec 'resize '. len(help)
endf

" s:DisplayList(world, type, handlers, query, ?list)
fun! s:DisplayList(world, type, handlers, query, ...) "{{{3
    let list = a:0 >= 1 ? a:1 : []
    call tlib#UseScratch(a:world)
    if empty(list)
        if a:query == 'scroll'
            exec 'norm! '. a:world.offset .'zt'
        elseif a:query == 'help'
            call s:DisplayHelp(a:type, a:handlers)
        endif
    else
        norm! ggdG
        let w = &co - &fdc - 1
        call append(0, map(copy(list), 'printf("%-'. w .'.'. w .'s", v:val)'))
        call append(0, a:query)
        norm! Gddgg
        if a:world.state !~ '\<redisplay\>'
            exec 'resize '. (len(list) + 1)
        endif
        exec 'norm! '. a:world.offset .'zt'
    endif
    redraw
endf

" tlib#GetChar(?timeout=0)
fun! tlib#GetChar(...) "{{{3
    let timeout = a:0 >= 1 ? a:1 : 0
    if timeout == 0
        return getchar()
    else
        let start = localtime()
        while 1
            let c = getchar(0)
            if c != 0
                return c
            elseif localtime() - start > timeout
                return -1
            endif
        endwh
    endif
    return -1
endf

fun! s:AssessName(name)
    let xa  = 0
    let flt = s:world.get_rx()
    if a:name =~# '\V'. flt
        let xa += 3
    endif
    if a:name =~ '\V\^'. flt .'\|'. flt .'\$'
        let xa += 3
    elseif a:name =~ '\V\<'. flt .'\|'. flt .'\>'
        let xa += 2
    elseif a:name =~ '\V\A'. flt .'\|'. flt .'\A'
        let xa += 1
    endif
    if flt[0] =~# '\u' && matchstr(a:name, '\V\.\ze'. flt) =~# '\U'
        let xa += 1
    endif
    if flt[0] =~# '\U' && matchstr(a:name, '\V\.\ze'. flt) =~# '\u'
        let xa += 1
    endif
    if flt[-1] =~# '\u' && matchstr(a:name, '\V'. flt .'\zs\.') =~# '\U'
        let xa += 1
    endif
    if flt[-1] =~# '\U' && matchstr(a:name, '\V'. flt .'\zs\.') =~# '\u'
        let xa += 1
    endif
    return xa
endf

fun! s:SortPrefs(a, b) "{{{3
    let a = s:world.get_item(a:a)
    let b = s:world.get_item(a:b)
    let xa = s:AssessName(a)
    let xb = s:AssessName(b)
    if a < b
        let xa += 1
    elseif b < a
        let xb += 1
    endif
    " let la = len(a)
    " let lb = len(b)
    " if la < lb
    "     let xa += 1
    " elseif lb < la
    "     let xb += 1
    " endif
    return xa == xb ? 0 : xa < xb ? 1 : -1
endf

fun! s:UseInputListScratch(world)
    let scratch = tlib#UseScratch(a:world)
    syntax match InputlListCursor /^\d\+\* .*$/
    syntax match InputlListSelected /^\d\+# .*$/
    hi def link InputlListCursor Search
    hi def link InputlListSelected IncSearch
    return scratch
endf

fun! s:GetSelectedItems(world, current)
    let rv = copy(a:world.selected)
    if a:current != ''
        let ci = index(rv, a:current)
        if ci != -1
            call remove(rv, ci)
        endif
        call insert(rv, a:current)
    endif
    return rv
endf

fun! s:SetItem(mode, world, index)
    let it = a:world.get_item(a:index)
    let si = index(a:world.selected, it)
    if si == -1
        call add(a:world.selected, it)
    elseif a:mode == 'toggle'
        call remove(a:world.selected, si)
    endif
endf

fun! s:WorldGetItem(idx) dict
    return self.list[a:idx - 1]
endf

fun! s:WorldGetCurrentItem() dict
    let idx = self.prefidx
    if len(self.list) >= idx
        return self.list[idx - 1]
    endif
endf

fun! s:WorldGetRx() dict
    return substitute(self.filter, ' ', '\\.\\{-}', 'g')
endf


" Type
"     Mouse  ... Immediatly select an item
"     Number ... (Immediatly) select an item
"     Letter ... Filter the list (if only one item is left, take it)
"     Esc    ... Abort
"     Enter  ... Select preferred item
" tlib#InputList(type. query, list, ?handlers=[], ?default="", ?timeout=0)
" Limitations: The function cannot handle redundant entries properly. 
" Maybe it should thus be called InputSet()?
fun! tlib#InputList(type, query, list, ...) "{{{3
    let handlers = a:0 >= 1 ? a:1 : []
    let rv       = a:0 >= 2 ? a:2 : ''
    let timeout  = a:0 >= 3 ? a:3 : 0
    let backchar = ["\<bs>", "\<del>"]
    let wnr      = winnr()
    let key_handlers     = filter(copy(handlers), 'has_key(v:val, "key")')
    let state_handlers   = filter(copy(handlers), 'has_key(v:val, "state")')
    let display_handlers = filter(copy(handlers), 'has_key(v:val, "display_format")')
    let post_handlers    = filter(copy(handlers), 'has_key(v:val, "postprocess")')
    let pli_handler      = filter(copy(handlers), 'has_key(v:val, "pick_last_item")')
    let filter_expr      = tlib#Find(handlers, 'has_key(v:val, "filter_expr")', 'v:val =~? ''\V''. filterrx')
    if len(pli_handler) > 0
        let pick_last_item = pli_handler[0].pick_last_item
    else
        let pick_last_item = 1
    endif
    try
        let world = {'state': 'reset', 'base': a:list, 'list': [], 'selected': [],
                    \ 'get_current_item': function(s:SNR()."WorldGetCurrentItem"), 
                    \ 'get_item': function(s:SNR()."WorldGetItem"),
                    \ 'get_rx': function(s:SNR()."WorldGetRx"),
                    \ }
        while !empty(world.state) && !empty(world.base)
            try
                for handler in state_handlers
                    let eh = get(handler, 'state', '')
                    if !empty(eh) && eh == world.state
                        let ea = get(handler, 'exec', '')
                        if !empty(ea)
                            exec ea
                        else
                            let ea  = get(handler, 'agent', '')
                            let world = call(ea, [world])
                        endif
                    endif
                endfor
                if world.state == 'reset'
                    let world.state    = 'display'
                    let world.offset   = 1
                    let world.filter   = ''
                    let world.idx      = ''
                    let world.selected = []
                    let world.scratch  = s:UseInputListScratch(world)
                    continue
                endif
                let llenw = len(world.base) - winheight(0) + 2
                if world.offset > llenw
                    let world.offset = llenw
                endif
                if world.offset < 1
                    let world.offset = 1
                endif
                if world.state =~ 'display'
                    let filterrx = world.get_rx()
                    if world.state =~ '^display'
                        let world.list = copy(world.base)
                        if !empty(filter_expr)
                            call filter(world.list, filter_expr)
                        endif
                        let llen = len(world.list)
                        if llen == 0
                            let world.filter = world.filter[0:-2]
                            continue
                        else
                            if llen == 1
                                let world.last_item = world.list[0]
                                if pick_last_item
                                    echom 'Pick last item: '. world.list[0]
                                    let world.state = ''
                                    let world.prefidx = '1'
                                    throw 'pick'
                                endif
                            else
                                let world.last_item = ''
                            endif
                        endif
                        if world.state == 'display'
                            if world.idx == '' && world.filter != ''
                                let s:world = world
                                let pref    = sort(range(1, llen), 's:SortPrefs')
                                let world.prefidx = get(pref, 0, 1)
                            else
                                let world.prefidx = world.idx == '' ? 1 : world.idx
                            endif
                        endif
                    endif
                    if world.prefidx > world.offset + winheight(0) - 2
                        let world.offset = world.prefidx - winheight(0) + 2
                    elseif world.prefidx < world.offset
                        let world.offset = world.prefidx
                    endif
                    let dlist = copy(world.list)
                    for handler in display_handlers
                        let nargs = len(substitute(handler.display_format, '%%\|[^%]', '', 'g'))
                        call map(dlist, 'eval(call(function("printf"), ([handler.display_format] + repeat([string(v:val)], nargs))))')
                    endfor
                    " TLogDBG "world.prefidx=". world.prefidx
                    let dlist = map(range(1, llen), 'printf("%0'. len(llen) .'d", v:val) .(v:val == world.prefidx ? "* " : (index(world.selected, world.get_item(v:val)) != -1 ? "# " : ": ")). dlist[v:val - 1]')
                    call s:DisplayList(world, a:type, handlers, a:query .' (filter: "'. world.filter .'"; press "?" for help)', dlist)
                    let world.state = ''
                else
                    if world.state == 'scroll'
                        let world.prefidx = world.offset
                    endif
                    call s:DisplayList(world, a:type, handlers, world.state)
                    if world.state == 'help'
                        let world.state = 'display'
                    else
                        let world.state = ''
                    endif
                endif
                let c = tlib#GetChar(timeout)
                if world.state != ''
                    continue
                elseif c != -1
                    if c == "\<LeftMouse>"
                        let world.idx = matchstr(getline(v:mouse_lnum), '^\d\+\ze:')
                        if empty(world.idx)
                            " call feedkeys(c, 't')
                            let c = tlib#GetChar(timeout)
                            let world.state = 'help'
                        endif 
                    elseif c == "\<PageUp>"
                        let world.offset -= (winheight(0) / 2)
                        let world.state = 'scroll'
                    elseif c == "\<PageDown>"
                        let world.offset += (winheight(0) / 2)
                        let world.state = 'scroll'
                    elseif c == "\<Up>" || c == "\<C-Up>"
                        if world.prefidx > 1
                            let world.prefidx -= 1
                        endif
                        let world.state = 'redisplay'
                    elseif c == "\<Down>" || c == "\<C-Down>"
                        if world.prefidx < llen
                            let world.prefidx += 1
                        endif
                        let world.state = 'redisplay'
                    elseif c == 18
                        let world.state = 'reset'
                    elseif c == 27
                        let world.list = []
                        let world.selected = []
                    elseif c == 63
                        let world.state = 'help'
                    elseif c == 124
                        let world.filter .= '\|'
                        let world.state = 'display'
                    elseif c == 32
                        if !empty(world.filter)
                            let world.filter .= ' '
                        endif
                        let world.state = 'display'
                    elseif index(backchar, c) != -1
                        let world.filter = world.filter[0:-2]
                        let world.state = 'display'
                    else
                        if stridx(a:type, 'm') != -1
                            if c == "\<c-space>"
                                call s:SetItem('toggle', world, world.prefidx)
                                let world.state = 'display keep-cursor'
                                continue
                            elseif c == "\<S-Up>"
                                call s:SetItem('toggle', world, world.prefidx)
                                if world.prefidx > 1
                                    let world.prefidx -= 1
                                endif
                                let world.state = 'redisplay'
                                continue
                            elseif c == "\<S-Down>"
                                call s:SetItem('toggle', world, world.prefidx)
                                if world.prefidx < llen
                                    let world.prefidx += 1
                                endif
                                let world.state = 'redisplay'
                                continue
                            elseif c == 1
                                let unselected = filter(range(1, len(world.list)), 'index(world.selected, world.get_item(v:val)) == -1')
                                let mode = len(unselected) == 0 ? 'toggle' : 'set'
                                for i in range(1, len(world.list))
                                    call s:SetItem(mode, world, i)
                                endfor
                                let world.state = 'display keep-cursor'
                                continue
                            endif
                        endif
                        for handler in key_handlers
                            let k = get(handler, 'key', '')
                            if !empty(k) && c == k
                                let world = call(handler.agent, [world, s:GetSelectedItems(world, world.get_current_item())])
                                continue
                            endif
                        endfor
                        if c >= 32
                            let ch = nr2char(c)
                            let world.state = 'display'
                            if stridx('1234567890', ch) != -1
                                let world.idx .= ch
                                if len(world.idx) == len(llen)
                                    let world.state = ''
                                    throw 'pick'
                                endif
                            else
                                let world.idx = ''
                                let world.filter .= ch
                            endif
                        endif
                    endif
                endif
            catch /^pick$/
            finally
                if !empty(world.list)
                    if empty(world.state)
                        if !empty(world.idx) && world.idx <= llen
                            let rv = world.get_item(world.idx)
                        elseif llen == 1
                            let rv = world.list[0]
                        elseif world.prefidx >= 0
                            let rv = world.get_current_item()
                        endif
                    endif
                    for handler in post_handlers
                        let state = get(handler, 'postprocess', '')
                        " TLogVAR handler
                        " TLogVAR state
                        " TLogVAR world.state
                        if state == world.state
                            let [world, rv] = call(handler.agent, [world, rv])
                        endif
                    endfor
                endif
                " TLogDBG 'state0='. world.state
            endtry
            " TLogDBG 'state1='. world.state
        endwh
        " TLogVAR world.list
        " TLogVAR world.selected
        " TLogVAR world.idx
        " TLogVAR world.prefidx
        " TLogVAR rv
        if stridx(a:type, 'm') != -1
            return s:GetSelectedItems(world, rv)
        else
            return rv
        endif
    finally
        call tlib#CloseScratch(world)
        exec wnr .'wincmd w'
    endtry
endf


""" List related functions {{{1

fun! tlib#Inject(list, value, Function) "{{{3
    if empty(a:list)
        return a:value
    else
        let item  = a:list[0]
        let rest  = a:list[1:-1]
        let value = call(a:Function, [a:value, item])
        return tlib#Inject(rest, value, a:Function)
    endif
endf

fun! tlib#Compact(list) "{{{3
    return filter(copy(a:list), '!empty(v:val)')
endf

fun! tlib#Flatten(list) "{{{3
    let acc = []
    for e in a:list
        if type(e) == 3
            let acc += tlib#Flatten(e)
        else
            call add(acc, e)
        endif
        unlet e
    endfor
    return acc
endf

fun! tlib#FindAll(list, expr)
    let list = filter(copy(a:list), a:expr)
    return list
endf

fun! tlib#Find(list, expr, ...)
    let default = a:0 >= 1 ? a:1 : ''
    return get(tlib#FindAll(a:list, a:expr), 0, default)
endf


" vi: fdm=marker
