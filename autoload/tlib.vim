" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=vim-tlib)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-04-26.
" @Revision:    1058
" vimscript:    1863
"
" TODO:


if &cp || exists("loaded_tlib_autoload") "{{{2
    finish
endif
let loaded_tlib_autoload = loaded_tlib


""" Scratch buffer {{{1

fun! tlib#UseScratch(world) "{{{3
    let id = get(a:world, 'scratch', '__InputList__')
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
                let cmd = get(a:world, 'scratch_split', 1) ? 'botright sbuffer! ' : 'buffer! '
                silent exec cmd . bn
            endif
        else
            " TLogVAR id
            let cmd = get(a:world, 'scratch_split', 1) ? 'botright split ' : 'edit '
            silent exec cmd . escape(id, '%#\ ')
            " silent exec 'split '. id
        endif
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        setlocal modifiable
        set ft=tlibInputList
    endif
    return bufnr('%')
endf

fun! tlib#CloseScratch(world) "{{{3
    let scratch = get(a:world, 'scratch', '')
    " TLogVAR scratch
    if !empty(scratch)
        let wn = bufwinnr(scratch)
        if wn != -1
            " TLogVAR wn
            exec wn .'wincmd w'
            " call tlib#UseScratch(a:world)
            wincmd c
            " redraw
        endif
        unlet a:world.scratch
    endif
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
                \ 'Enter        ... Pick the current item     <c-r>        ... Reset the display',
                \ 'Letter       ... Filter the list           Esc          ... Abort',
                \ '',
                \ ]
    if stridx(a:type, 'm') != -1
        let help += [
                    \ '#, <c-space> ... (Un)Select the current item',
                    \ '<c-a>        ... (Un)Select all currently visible items',
                    \ '<s-up/down>  ... (Un)Select items',
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
                \ 'The filter is prepended with "\V". Within some limits, you can use "+"',
                \ 'to combine two patters with AND and "|" with OR.',
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
        let ll = len(list)
        if a:world.state != '\<display\>'
            norm! ggdG
            let w = &co - &fdc - 1
            call append(0, map(copy(list), 'printf("%-'. w .'.'. w .'s", substitute(v:val, ''[[:cntrl:][:space:]]'', " ", "g"))'))
            " call append(0, a:query)
            norm! Gddgg
            let resize  = get(a:world, 'resize', 0)
            " TLogVAR resize
            exec 'resize '. (resize == 0 ? ll : min([ll, resize]))
        endif
        let x = len(ll) + 1
        " for idx in keys(b:tlibDisplayListMarks)
        "     if index(a:world.sel_idx, idx) == -1
        "         unlet b:tlibDisplayListMarks[idx]
        "         call s:DisplayListMark(x, idx, ":")
        "     endif
        " endfor
        " for idx in a:world.sel_idx
        "     if !has_key(b:tlibDisplayListMarks, idx) || b:tlibDisplayListMarks[idx] != '#'
        "         call s:DisplayListMark(x, idx, "#")
        "         let b:tlibDisplayListMarks[idx] = '#'
        "     endif
        " endfor
        " let b:tlibDisplayListMarks[a:world.prefidx] = '*'
        " call s:DisplayListMark(x, a:world.prefidx, "*")
        call filter(b:tlibDisplayListMarks, 'index(a:world.sel_idx, v:val) == -1')
        call map(b:tlibDisplayListMarks, 's:DisplayListMark(x, v:val[0], ":")')
        let b:tlibDisplayListMarks = map(copy(a:world.sel_idx), 's:DisplayListMark(x, v:val, "#")')
        call add(b:tlibDisplayListMarks, a:world.prefidx)
        call s:DisplayListMark(x, a:world.prefidx, '*')
        exec 'norm! '. a:world.offset .'zt'
        let &statusline = a:query
    endif
    redraw
endf

fun! s:DisplayListMark(x, y, mark)
    if a:x > 0 && a:y > 0
        " TLogDBG a:x .'x'. a:y .' '. a:mark
        call setpos('.', [0, a:y, a:x, 0])
        exec 'norm! r'. a:mark
        " exec 'norm! '. a:y .'gg'. a:x .'|r'. a:mark
    endif
    return a:y
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
    for fltl in s:world.filter
        let flt = s:GetRx(fltl)
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
    endfor
    return xa
endf

fun! s:SortPrefs(a, b) "{{{3
    let a = s:world.GetItem(a:a)
    let b = s:world.GetItem(a:b)
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
    " hi def link InputlListIndex Special
    " let b:tlibDisplayListMarks = {}
    let b:tlibDisplayListMarks = []
    return scratch
endf

fun! s:WorldGetSelectedItems(current) dict
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

fun! s:WorldSelectItem(mode, index) dict
    let bi = self.GetBaseIdx(a:index)
    let si = index(self.sel_idx, bi)
    if si == -1
        call add(self.sel_idx, bi)
    elseif a:mode == 'toggle'
        call remove(self.sel_idx, si)
    endif
endf

fun! s:GetRx(filter)
    return '\('. join(a:filter, '\|') .'\)' 
endf

fun! s:WorldGetItem(idx) dict
    return self.list[a:idx - 1]
endf

fun! s:WorldGetBaseIdx(idx) dict
    return self.table[a:idx - 1]
endf

fun! s:WorldGetBaseItem(idx) dict
    return self.base[a:idx - 1]
endf

fun! s:WorldSetBaseItem(idx, item) dict
    let self.base[a:idx - 1] = a:item
endf

fun! s:WorldGetCurrentItem() dict
    let idx = self.prefidx
    if stridx(self.type, 'i') != -1
        return idx
    else
        if len(self.list) >= idx
            return self.list[idx - 1]
        endif
    endif
endf

fun! s:WorldMatch(text, ...) dict
    let mrx = '\V'. (a:0 >= 1 && a:1 ? '\C' : '')
    for rx in self.filter
        if a:text !~ mrx. s:GetRx(rx)
            return 0
        endif
    endfor
    return 1
endf

fun! s:WorldMatchBaseIdx(idx, ...) dict
    let mrx  = '\V'. (a:0 >= 1 && a:1 ? '\C' : '')
    let text = self.GetBaseItem(a:idx)
    return self.Match(text, mrx)
endf

fun! s:WorldReduceFilter() dict
    if empty(self.filter[0]) && len(self.filter) > 1
        call remove(self.filter, 0)
    elseif empty(self.filter[0][0] )&& len(self.filter[0]) > 1
        call remove(self.filter[0], 0)
    else
        let self.filter[0][0] = self.filter[0][0][0:-2]
    endif
    " TLogVAR self.filter
    " let self.filter[0] = self.filter[0][0:-2]
endf

fun! s:WorldFilterIsEmpty() dict
    " TLogVAR self.filter
    return self.filter == [['']]
endf

fun! s:WorldDisplayFilter() dict
    " TLogVAR self.filter
    let filter1 = map(deepcopy(self.filter), '"(". join(reverse(v:val), " OR ") .")"')
    " TLogVAR filter1
    return join(reverse(filter1), ' AND ')
endf

fun! s:WorldReset() dict
    let self.state     = 'display'
    let self.offset    = 1
    let self.filter    = [['']]
    let self.idx       = ''
    let self.prefidx   = 0
    let self.scratch   = s:UseInputListScratch(self)
    call self.ResetSelected()
endf

fun! s:WorldResetSelected() dict
    let self.sel_idx   = []
endf

fun! s:CheckAgentReturnValue(name, value)
    if type(a:value) != 4 && !has_key(a:value, 'state')
        echoerr 'Malformed agent: '. a:name
    endif
    return a:value
endf

fun! s:AgentPageUp(world, selected)
    let a:world.offset -= (winheight(0) / 2)
    let a:world.state = 'scroll'
    return a:world
endf

fun! s:AgentPageDown(world, selected)
    let a:world.offset += (winheight(0) / 2)
    let a:world.state = 'scroll'
    return a:world
endf

fun! s:AgentUp(world, selected)
    let a:world.idx = ''
    if a:world.prefidx > 1
        let a:world.prefidx -= 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

fun! s:AgentDown(world, selected)
    let a:world.idx = ''
    if a:world.prefidx < len(a:world.list)
        let a:world.prefidx += 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

fun! s:AgentReset(world, selected)
    let a:world.state = 'reset'
    return a:world
endf

fun! s:AgentExit(world, selected)
    let a:world.state = 'exit escape'
    let a:world.list = []
    " let a:world.base = []
    call a:world.ResetSelected()
    return a:world
endf

fun! s:AgentHelp(world, selected)
    let a:world.state = 'help'
    return a:world
endf

fun! s:AgentOR(world, selected)
    if !empty(a:world.filter[0])
        call insert(a:world.filter[0], '')
    endif
    let a:world.state = 'display'
    return a:world
endf

fun! s:AgentAND(world, selected)
    if !empty(a:world.filter[0])
        call insert(a:world.filter, [''])
    endif
    let a:world.state = 'display'
    return a:world
endf

fun! s:AgentReduceFilter(world, selected)
    call a:world.ReduceFilter()
    let a:world.offset = 1
    let a:world.state = 'display'
    return a:world
endf

fun! s:AgentDebug(world, selected)
    " echo string(world.state)
    echo string(a:world.filter)
    echo string(a:world.idx)
    echo string(a:world.prefidx)
    echo string(a:world.sel_idx)
    call getchar()
    let a:world.state = 'display'
    return a:world
endf

fun! s:AgentSelect(world, selected)
    call a:world.SelectItem('toggle', a:world.prefidx)
    " let a:world.state = 'display keep-cursor'
    let a:world.state = 'redisplay'
    return a:world
endf

fun! s:AgentSelectUp(world, selected)
    call a:world.SelectItem('toggle', a:world.prefidx)
    if a:world.prefidx > 1
        let a:world.prefidx -= 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

fun! s:AgentSelectDown(world, selected)
    call a:world.SelectItem('toggle', a:world.prefidx)
    if a:world.prefidx < len(a:world.list)
        let a:world.prefidx += 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

fun! s:AgentSelectAll(world, selected)
    let unselected = filter(range(1, len(a:world.list)),
                \ 'index(a:world.sel_idx, a:world.GetBaseIdx(v:val)) == -1')
    let mode = len(unselected) == 0 ? 'toggle' : 'set'
    for i in range(1, len(a:world.list))
        call a:world.SelectItem(mode, i)
    endfor
    let a:world.state = 'display keep-cursor'
    return a:world
endf

" fun! s:Agent<+TBD+>(world, selected)
"     <+TBD+>
" endf



" Type
"     Mouse  ... Immediatly select an item
"     Number ... (Immediatly) select an item
"     Letter ... Filter the list (if only one item is left, take it)
"     Esc    ... Abort
"     Enter  ... Select preferred item
" tlib#InputList(type. query, list, ?handlers=[], ?default="", ?timeout=0)
fun! tlib#InputList(type, query, list, ...) "{{{3
    let handlers = a:0 >= 1 ? a:1 : []
    let rv       = a:0 >= 2 ? a:2 : ''
    let timeout  = a:0 >= 3 ? a:3 : 0
    let backchar = ["\<bs>", "\<del>"]
    let wnr      = winnr()

    let state_handlers   = filter(copy(handlers), 'has_key(v:val, "state")')
    let display_handlers = filter(copy(handlers), 'has_key(v:val, "display_format")')
    let post_handlers    = filter(copy(handlers), 'has_key(v:val, "postprocess")')
    let pli_handler      = filter(copy(handlers), 'has_key(v:val, "pick_last_item")')
    let return_agent     = tlib#Find(handlers, 'has_key(v:val, "return_agent")')
    let resize_value     = tlib#Find(handlers, 'has_key(v:val, "resize")')
    if len(pli_handler) > 0
        let pick_last_item = pli_handler[0].pick_last_item
    else
        let pick_last_item = g:tlib_pick_last_item
    endif
    let key_handlers = filter(copy(handlers), 'has_key(v:val, "key")')
    let key_agents = {
                \ "\<PageUp>":   function('s:AgentPageUp'),
                \ "\<PageDown>": function('s:AgentPageDown'),
                \ "\<Up>":       function('s:AgentUp'),
                \ "\<Down>":     function('s:AgentDown'),
                \ 18:            function('s:AgentReset'),
                \ 27:            function('s:AgentExit'),
                \ 63:            function('s:AgentHelp'),
                \ "\<F1>":       function('s:AgentHelp'),
                \ 124:           function('s:AgentOR'),
                \ 43:            function('s:AgentAND'),
                \ "\<bs>":       function('s:AgentReduceFilter'),
                \ "\<del>":      function('s:AgentReduceFilter'),
                \ 191:           function('s:AgentDebug'),
                \ }
    if stridx(a:type, 'm') != -1
        let key_agents["\<c-space>"] = function('s:AgentSelect')
        let key_agents[35] =           function('s:AgentSelect')
        let key_agents["\<s-up>"] =    function('s:AgentSelectUp')
        let key_agents["\<s-down>"] =  function('s:AgentSelectDown')
        let key_agents[1] =            function('s:AgentSelectAll')
    endif
    for handler in key_handlers
        let k = get(handler, 'key', '')
        if !empty(k)
            let key_agents[k] = handler.agent
        endif
    endfor
    let statusline  = &statusline
    let laststatus  = &laststatus
    let &laststatus = 2

    try
        let world = {'state': 'reset', 'type': a:type, 'base': a:list, 'list': [], 'sel_idx': [],
                    \ 'DisplayFilter':    function(s:SNR(). 'WorldDisplayFilter'),
                    \ 'FilterIsEmpty':    function(s:SNR(). 'WorldFilterIsEmpty'),
                    \ 'GetBaseItem':      function(s:SNR(). 'WorldGetBaseItem'),
                    \ 'GetBaseIdx':       function(s:SNR(). 'WorldGetBaseIdx'),
                    \ 'GetCurrentItem':   function(s:SNR(). 'WorldGetCurrentItem'), 
                    \ 'GetItem':          function(s:SNR(). 'WorldGetItem'),
                    \ 'GetSelectedItems': function(s:SNR(). 'WorldGetSelectedItems'),
                    \ 'Match':            function(s:SNR(). 'WorldMatch'),
                    \ 'MatchBaseIdx':     function(s:SNR(). 'WorldMatchBaseIdx'),
                    \ 'ReduceFilter':     function(s:SNR(). 'WorldReduceFilter'),
                    \ 'Reset':            function(s:SNR(). 'WorldReset'),
                    \ 'ResetSelected':    function(s:SNR(). 'WorldResetSelected'),
                    \ 'SetBaseItem':      function(s:SNR(). 'WorldSetBaseItem'),
                    \ 'SelectItem':       function(s:SNR(). 'WorldSelectItem'),
                    \ }
        if !empty(resize_value)
            let world.resize = resize_value.resize
        endif

        while !empty(world.state) && world.state !~ '^exit' && !empty(world.base)
            " TLogVAR world.state
            try
                for handler in state_handlers
                    let eh = get(handler, 'state', '')
                    if !empty(eh) && eh == world.state
                        let ea = get(handler, 'exec', '')
                        if !empty(ea)
                            exec ea
                        else
                            let agent = get(handler, 'agent', '')
                            let world = call(agent, [world])
                            call s:CheckAgentReturnValue(agent, world)
                        endif
                    endif
                endfor

                if world.state == 'reset'
                    call world.Reset()
                    continue
                endif

                let llenw = len(world.base) - winheight(0) + 1
                if world.offset > llenw
                    let world.offset = llenw
                endif
                if world.offset < 1
                    let world.offset = 1
                endif

                if world.state =~ 'display'
                    if world.state =~ '^display'
                        let world.table = filter(range(1, len(world.base)), 'world.MatchBaseIdx(v:val)')
                        " TLogVAR world.table
                        let world.list  = map(copy(world.table), 'world.GetBaseItem(v:val)')
                        let llen = len(world.list)
                        if llen == 0
                            call world.ReduceFilter()
                            let world.offset = 1
                            continue
                        else
                            if llen == 1
                                let world.last_item = world.list[0]
                                if pick_last_item
                                    echom 'Pick last item: '. world.list[0]
                                    let world.prefidx = '1'
                                    throw 'pick'
                                endif
                            else
                                let world.last_item = ''
                            endif
                        endif
                        if world.state == 'display'
                            if world.idx == '' && !world.FilterIsEmpty()
                                let s:world = world
                                let pref    = sort(range(1, llen), 's:SortPrefs')
                                let world.prefidx = get(pref, 0, 1)
                            else
                                let world.prefidx = world.idx == '' ? 1 : world.idx
                            endif
                        endif
                        let dlist = copy(world.list)
                        for handler in display_handlers
                            let nargs = len(substitute(handler.display_format, '%%\|[^%]', '', 'g'))
                            call map(dlist, 'eval(call(function("printf"), ([handler.display_format] + repeat([string(v:val)], nargs))))')
                        endfor
                        " TLogDBG "world.prefidx=". world.prefidx
                        let dlist = map(range(1, llen), 'printf("%0'. len(llen) .'d", v:val) .": ". dlist[v:val - 1]')
                    endif
                    if world.prefidx > world.offset + winheight(0) - 1
                        let world.offset = world.prefidx - winheight(0) + 1
                    elseif world.prefidx < world.offset
                        let world.offset = world.prefidx
                    endif
                    call s:DisplayList(world, a:type, handlers, a:query .' (filter: '. world.DisplayFilter() .'; press "?" for help)', dlist)
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
                    " continue
                elseif has_key(key_agents, c)
                    let world = call(key_agents[c], [world, world.GetSelectedItems(world.GetCurrentItem())])
                    call s:CheckAgentReturnValue(c, world)
                    " continue
                elseif c == 13
                    throw 'pick'
                elseif c == "\<LeftMouse>"
                    let world.prefidx = matchstr(getline(v:mouse_lnum), '^\d\+\ze:')
                    if empty(world.prefidx)
                        " call feedkeys(c, 't')
                        let c = tlib#GetChar(timeout)
                        let world.state = 'help'
                        continue
                    endif
                    throw 'pick'
                elseif c >= 32
                    let world.state = 'display'
                    let ch = nr2char(c)
                    if stridx('1234567890', ch) != -1
                        let world.idx .= ch
                        if len(world.idx) == len(llen)
                            let world.prefidx = world.idx
                            throw 'pick'
                        endif
                    else
                        let world.idx = ''
                        " TLogVAR world.filter
                        let world.filter[0][0] .= ch
                        " continue
                    endif
                else
                    let world.state = 'redisplay'
                endif

            catch /^pick$/
                let world.state = ''
                " echom 'Pick item #'. world.prefidx

            finally
                if !empty(world.list) && !empty(world.base)
                    " TLogVAR world.list
                    if empty(world.state)
                        " TLogVAR world.state
                        if stridx(a:type, 'i') != -1
                            let rv = llen == 1 ? 1 : world.prefidx
                        else
                            if llen == 1
                                " TLogVAR llen
                                let rv = world.list[0]
                            elseif world.prefidx > 0
                                " TLogVAR world.prefidx
                                let rv = world.GetCurrentItem()
                            endif
                        endif
                    endif
                    for handler in post_handlers
                        let state = get(handler, 'postprocess', '')
                        " TLogVAR handler
                        " TLogVAR state
                        " TLogVAR world.state
                        if state == world.state
                            let agent = handler.agent
                            let [world, rv] = call(agent, [world, rv])
                            call s:CheckAgentReturnValue(agent, world)
                        endif
                    endfor
                endif
                " TLogDBG 'state0='. world.state
            endtry
            " TLogDBG 'state1='. world.state
        endwh

        " TLogVAR world.list
        " TLogVAR world.sel_idx
        " TLogVAR world.idx
        " TLogVAR world.prefidx
        " TLogVAR rv
        if !empty(return_agent)
            return call(return_agent.return_agent, [world, rv])
        elseif stridx(a:type, 'm') != -1
            return world.GetSelectedItems(rv)
        else
            return rv
        endif

    finally
        let &statusline = statusline
        let &laststatus = laststatus
        call tlib#CloseScratch(world)
        echo
        redraw
        exec wnr .'wincmd w'
    endtry
endf

fun! s:AgentEditItem(world, selected)
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

fun! s:AgentNewItem(world, selected)
    let basepi = a:world.GetBaseIdx(a:world.prefidx)
    let item = input('New item: ')
    call insert(a:world.base, item, basepi)
    let a:world.state = 'reset'
    return a:world
endf

fun! s:AgentDeleteItems(world, selected)
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

fun! s:AgentEditReturnValue(world, rv)
    return [a:world.state !~ '\<exit\>', a:world.base]
endf

fun! tlib#EditListHandlers()
    return [
                \ {'key': 5, 'agent': s:SNR() .'AgentEditItem',    'key_name': '<c-e>', 'help': 'Edit item'},
                \ {'key': 4, 'agent': s:SNR() .'AgentDeleteItems', 'key_name': '<c-d>', 'help': 'Delete item(s)'},
                \ {'key': 14, 'agent': s:SNR() .'AgentNewItem', 'key_name': '<c-n>', 'help': 'New item'},
                \ {'pick_last_item': 0},
                \ {'return_agent': s:SNR() .'AgentEditReturnValue'},
                \ ]
endf

fun! tlib#EditList(query, list, ...) "{{{3
    let handlers = a:0 >= 1 ? a:1 : tlib#EditListHandlers()
    let rv       = a:0 >= 2 ? a:2 : ''
    let timeout  = a:0 >= 3 ? a:3 : 0
    " TLogVAR handlers
    let [success, list] = tlib#InputList('m', a:query, copy(a:list), handlers, rv, timeout)
    return success ? list : a:list
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
    return filter(copy(a:list), a:expr)
endf

fun! tlib#Find(list, expr, ...)
    let default = a:0 >= 1 ? a:1 : ''
    return get(tlib#FindAll(a:list, a:expr), 0, default)
endf

fun! tlib#Any(list, expr)
    return !empty(tlib#FindAll(a:list, a:expr))
endf

fun! tlib#All(list, expr)
    return len(tlib#FindAll(a:list, a:expr)) == len(a:list)
endf

function! tlib#Remove(list, element)
    let idx = index(a:list, a:element)
    if idx == -1
        call remove(a:list, idx)
    endif
    return a:list
endf

function! tlib#RemoveAll(list, element)
    call filter(a:list, 'v:val != a:element')
    return a:list
endf


""" Variables {{{1

fun! tlib#GetValue(var, scope, ...)
    for scope in split(a:scope, '\zs')
        let var = scope .':'. a:var
        if exists(var)
            return eval(var)
        endif
    endfor
    return a:0 >= 1 ? a:1 : ''
endf

fun! tlib#GetVar(var, scope, ...)
    let pre  = []
    let post = []
    for scope in split(a:scope, '\zs')
        let var = scope .':'. a:var
        call add(pre,  printf('exists("%s") ? %s : (', var, var))
        call add(post, ')')
    endfor
    let default = a:0 >= 1 ? a:1 : ''
    return join(pre) . string(default) . join(post)
endf


" vi: fdm=marker
