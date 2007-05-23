" tlib.vim -- Some utility functions
" @Author:      Thomas Link (mailto:samul AT web de?subject=vim-tlib)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-10.
" @Last Change: 2007-05-23.
" @Revision:    1340
" vimscript:    1863
"
" TODO:
" - tlib#InputList() shouldn't take a list of handlers but an instance 
"   of tlib#World as argument.
" - tlib#InputList(): Speed up with large lists (n > 1000)
" - tlib#Args(dictionary)

if &cp || exists("loaded_tlib_autoload") "{{{2
    finish
endif
let loaded_tlib_autoload = loaded_tlib


""" Scratch buffer {{{1
function! tlib#UseScratch(world) "{{{3
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

function! tlib#CloseScratch(world) "{{{3
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
function! s:SNR() "{{{3
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

function! s:DisplayHelp(type, handlers) "{{{3
    let help = [
                \ 'Help:',
                \ 'Mouse        ... Pick an item            Letter       ... Filter the list',
                \ 'Number       ... Pick an item            +, |         ... AND, OR',
                \ 'Enter        ... Pick the current item   <bs>, <c-bs> ... Reduce filter',
                \ '<c-r>        ... Reset the display       Up/Down      ... Next/previous item',
                \ '<Esc>        ... Abort                   Page Up/Down ... Scroll',
                \ '',
                \ ]

    if stridx(a:type, 'm') != -1
        let help += [
                    \ '#, <c-space> ... (Un)Select the current item',
                    \ '<c-a>        ... (Un)Select all currently visible items',
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
                \ 'more weight.',
                \ '',
                \ 'Press any key to continue.',
                \ ]
    norm! ggdG
    call append(0, help)
    norm! Gddgg
    exec 'resize '. len(help)
endf

" s:DisplayList(world, type, handlers, query, ?list)
function! s:DisplayList(world, type, handlers, query, ...) "{{{3
    " TLogVAR a:query
    " TLogVAR a:world.state
    let list = a:0 >= 1 ? a:1 : []
    call tlib#UseScratch(a:world)
    if a:world.state == 'scroll'
        exec 'norm! '. a:world.offset .'zt'
    elseif a:world.state == 'help'
        call s:DisplayHelp(a:type, a:handlers)
    else
        let ll = len(list)
        let x  = len(ll) + 1
        " TLogVAR ll
        if a:world.state =~ '\<display\>'
            norm! ggdG
            let w = &co - &fdc - 1
            call append(0, map(copy(list), 'printf("%-'. w .'.'. w .'s", substitute(v:val, ''[[:cntrl:][:space:]]'', " ", "g"))'))
            " call append(0, a:query)
            norm! Gddgg
            " if a:world.state !~ '\<redisplay\>'
                let resize  = get(a:world, 'resize', 0)
                " TLogVAR resize
                exec 'resize '. (resize == 0 ? ll : min([ll, resize]))
            " endif
        endif
        " TLogVAR a:world.prefidx
        let base_pref = a:world.GetBaseIdx(a:world.prefidx)
        " TLogVAR base_pref
        if a:world.state =~ '\<redisplay\>'
            call filter(b:tlibDisplayListMarks, 'index(a:world.sel_idx, v:val) == -1 && v:val != base_pref')
            " TLogVAR b:tlibDisplayListMarks
            call map(b:tlibDisplayListMarks, 's:DisplayListMark(a:world, x, v:val, ":")')
            " let b:tlibDisplayListMarks = map(copy(a:world.sel_idx), 's:DisplayListMark(a:world, x, v:val, "#")')
            " call add(b:tlibDisplayListMarks, a:world.prefidx)
            " call s:DisplayListMark(a:world, x, a:world.GetBaseIdx(a:world.prefidx), '*')
        endif
        let b:tlibDisplayListMarks = map(copy(a:world.sel_idx), 's:DisplayListMark(a:world, x, v:val, "#")')
        call add(b:tlibDisplayListMarks, base_pref)
        call s:DisplayListMark(a:world, x, base_pref, '*')
        exec 'norm! '. a:world.offset .'zt'
        let &statusline = a:query
    endif
    redraw
endf

function! s:DisplayListMark(world, x, y, mark) "{{{3
    " TLogVAR a:y, a:mark
    if a:x > 0 && a:y >= 0
        " TLogDBG a:x .'x'. a:y .' '. a:mark
        let sy = a:world.GetListIdx(a:y) + 1
        " TLogVAR sy
        if sy >= 1
            call setpos('.', [0, sy, a:x, 0])
            exec 'norm! r'. a:mark
            " exec 'norm! '. a:y .'gg'. a:x .'|r'. a:mark
        endif
    endif
    return a:y
endf

" tlib#GetChar(?timeout=0)
function! tlib#GetChar(...) "{{{3
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

function! s:AssessName(name) "{{{3
    let xa  = 0
    for fltl in s:world.filter
        let flt = s:world.GetRx(fltl)
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

function! s:SortPrefs(a, b) "{{{3
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

function! s:CheckAgentReturnValue(name, value) "{{{3
    if type(a:value) != 4 && !has_key(a:value, 'state')
        echoerr 'Malformed agent: '. a:name
    endif
    return a:value
endf

function! s:AgentPageUp(world, selected) "{{{3
    let a:world.offset -= (winheight(0) / 2)
    let a:world.state = 'scroll'
    return a:world
endf

function! s:AgentPageDown(world, selected) "{{{3
    let a:world.offset += (winheight(0) / 2)
    let a:world.state = 'scroll'
    return a:world
endf

function! s:AgentUp(world, selected) "{{{3
    let a:world.idx = ''
    if a:world.prefidx > 1
        let a:world.prefidx -= 1
    else
        let a:world.prefidx = len(a:world.list)
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! s:AgentDown(world, selected) "{{{3
    let a:world.idx = ''
    if a:world.prefidx < len(a:world.list)
        let a:world.prefidx += 1
    else
        let a:world.prefidx = 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! s:AgentReset(world, selected) "{{{3
    let a:world.state = 'reset'
    return a:world
endf

function! s:AgentExit(world, selected) "{{{3
    let a:world.state = 'exit escape'
    let a:world.list = []
    " let a:world.base = []
    call a:world.ResetSelected()
    return a:world
endf

function! s:AgentHelp(world, selected) "{{{3
    let a:world.state = 'help'
    return a:world
endf

function! s:AgentOR(world, selected) "{{{3
    if !empty(a:world.filter[0])
        call insert(a:world.filter[0], '')
    endif
    let a:world.state = 'display'
    return a:world
endf

function! s:AgentAND(world, selected) "{{{3
    if !empty(a:world.filter[0])
        call insert(a:world.filter, [''])
    endif
    let a:world.state = 'display'
    return a:world
endf

function! s:AgentReduceFilter(world, selected) "{{{3
    call a:world.ReduceFilter()
    let a:world.offset = 1
    let a:world.state = 'display'
    return a:world
endf

function! s:AgentPopFilter(world, selected) "{{{3
    call a:world.PopFilter()
    let a:world.offset = 1
    let a:world.state = 'display'
    return a:world
endf

function! s:AgentDebug(world, selected) "{{{3
    " echo string(world.state)
    echo string(a:world.filter)
    echo string(a:world.idx)
    echo string(a:world.prefidx)
    echo string(a:world.sel_idx)
    call getchar()
    let a:world.state = 'display'
    return a:world
endf

function! s:AgentSelect(world, selected) "{{{3
    call a:world.SelectItem('toggle', a:world.prefidx)
    " let a:world.state = 'display keepcursor'
    let a:world.state = 'redisplay'
    return a:world
endf

function! s:AgentSelectUp(world, selected) "{{{3
    call a:world.SelectItem('toggle', a:world.prefidx)
    if a:world.prefidx > 1
        let a:world.prefidx -= 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! s:AgentSelectDown(world, selected) "{{{3
    call a:world.SelectItem('toggle', a:world.prefidx)
    if a:world.prefidx < len(a:world.list)
        let a:world.prefidx += 1
    endif
    let a:world.state = 'redisplay'
    return a:world
endf

function! s:AgentSelectAll(world, selected) "{{{3
    let listrange = range(1, len(a:world.list))
    let mode = empty(filter(copy(listrange), 'index(a:world.sel_idx, a:world.GetBaseIdx(v:val)) == -1'))
                \ ? 'toggle' : 'set'
    for i in listrange
        call a:world.SelectItem(mode, i)
    endfor
    let a:world.state = 'display keepcursor'
    return a:world
endf

" function! s:Agent<+TBD+>(world, selected)
"     <+TBD+>
" endf

function! s:DisplayFormat(file)
    let fname = fnamemodify(a:file, ":t")
    if isdirectory(a:file)
        let fname .='/'
    endif
    let dname = fnamemodify(a:file, ":h")
    let dnmax = &co - max([20, len(fname)]) - 12 - &fdc
    if len(dname) > dnmax
        let dname = '...'. strpart(fnamemodify(a:file, ":h"), len(dname) - dnmax)
    endif
    return printf("%-20s   %s", fname, dname)
endf

" Type
"     Mouse  ... Immediatly select an item
"     Number ... (Immediatly) select an item
"     Letter ... Filter the list (if only one item is left, take it)
"     Esc    ... Abort
"     Enter  ... Select preferred item
" tlib#InputList(type. query, list, ?handlers=[], ?default="", ?timeout=0)
function! tlib#InputList(type, query, list, ...) "{{{3
    let handlers = a:0 >= 1 ? a:1 : []
    let rv       = a:0 >= 2 ? a:2 : ''
    let timeout  = a:0 >= 3 ? a:3 : 0
    let backchar = ["\<bs>", "\<del>"]
    let wnr      = winnr()

    let state_handlers   = filter(copy(handlers), 'has_key(v:val, "state")')
    let post_handlers    = filter(copy(handlers), 'has_key(v:val, "postprocess")')
    let display_format   = tlib#Find(handlers, 'has_key(v:val, "display_format")', '', 'v:val.display_format')
    if display_format == 'filename'
        " let display_format = 'printf("%%-20s  %%s", fnamemodify(%s, ":t"), fnamemodify(%s, ":h"))'
        let display_format = 's:DisplayFormat(%s)'
    endif
    let filter_format    = tlib#Find(handlers, 'has_key(v:val, "filter_format")', '', 'v:val.filter_format')
    let return_agent     = tlib#Find(handlers, 'has_key(v:val, "return_agent")')
    let resize_value     = tlib#Find(handlers, 'has_key(v:val, "resize")')
    let show_empty       = tlib#Find(handlers, 'has_key(v:val, "show_empty")', 0, 'v:val.show_empty')
    let pick_last_item   = tlib#Find(handlers, 'has_key(v:val, "pick_last_item")', 
                \ tlib#GetValue('tlib_pick_last_item', 'bg'), 'v:val.pick_last_item')
    let numeric_chars    = tlib#Find(handlers, 'has_key(v:val, "numeric_chars")', 
                \ tlib#GetValue('tlib_numeric_chars', 'bg'), 'v:val.numeric_chars')
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
                \ "\<c-bs>":     function('s:AgentPopFilter'),
                \ "\<m-bs>":     function('s:AgentPopFilter'),
                \ "\<c-del>":    function('s:AgentPopFilter'),
                \ "\<m-del>":    function('s:AgentPopFilter'),
                \ 191:           function('s:AgentDebug'),
                \ }
    if stridx(a:type, 'm') != -1
        " let key_agents["\<c-space>"] = function('s:AgentSelect')
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
        let world = tlib#World#New({'type': a:type, 'base': a:list})
        if !empty(resize_value)
            let world.resize = resize_value.resize
        endif

        while !empty(world.state) && world.state !~ '^exit' && (show_empty || !empty(world.base))
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

                " TLogDBG 1
                " TLogVAR world.state
                if world.state =~ 'display'
                    if world.state =~ '^display'
                        let world.table = filter(range(1, len(world.base)), 'world.MatchBaseIdx(filter_format, v:val)')
                        " TLogDBG 2
                        " TLogVAR world.table
                        let world.list  = map(copy(world.table), 'world.GetBaseItem(v:val)')
                        " TLogDBG 3
                        let llen = len(world.list)
                        if llen == 0 && !show_empty
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
                        " TLogDBG 4
                        if world.state == 'display'
                            if world.idx == '' && llen < g:tlib_sortprefs_threshold && !world.FilterIsEmpty()
                                let s:world = world
                                let pref    = sort(range(1, llen), 's:SortPrefs')
                                let world.prefidx = get(pref, 0, 1)
                            else
                                let world.prefidx = world.idx == '' ? 1 : world.idx
                            endif
                        endif
                        " TLogDBG 5
                        let dlist = copy(world.list)
                        if !empty(display_format)
                            call map(dlist, 'eval(call(function("printf"), world.FormatArgs(display_format, v:val)))')
                        endif
                        " TLogVAR world.prefidx
                        " TLogDBG 6
                        let dlist = map(range(1, llen), 'printf("%0'. len(llen) .'d", v:val) .": ". dlist[v:val - 1]')
                    endif
                    " TLogDBG 7
                    if world.prefidx > world.offset + winheight(0) - 1
                        let world.offset = world.prefidx - winheight(0) + 1
                    elseif world.prefidx < world.offset
                        let world.offset = world.prefidx
                    endif
                    " TLogDBG 8
                    call s:DisplayList(world, a:type, handlers, a:query .' (filter: '. world.DisplayFilter() .'; press "?" for help)', dlist)
                    " TLogDBG 9
                    let world.state = ''

                else
                    if world.state == 'scroll'
                        let world.prefidx = world.offset
                    endif
                    call s:DisplayList(world, a:type, handlers, '')
                    if world.state == 'help'
                        let world.state = 'display'
                    else
                        let world.state = ''
                    endif
                endif

                " TLogVAR timeout
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
                    if has_key(numeric_chars, c)
                        let world.idx .= (c - numeric_chars[c])
                        if len(world.idx) == len(llen)
                            let world.prefidx = world.idx
                            throw 'pick'
                        endif
                    else
                        let world.idx = ''
                        " TLogVAR world.filter
                        let world.filter[0][0] .= nr2char(c)
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

function! s:AgentEditItem(world, selected) "{{{3
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

function! s:AgentNewItem(world, selected) "{{{3
    let basepi = a:world.GetBaseIdx(a:world.prefidx)
    let item = input('New item: ')
    call insert(a:world.base, item, basepi)
    let a:world.state = 'reset'
    return a:world
endf

function! s:AgentDeleteItems(world, selected) "{{{3
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

function! s:AgentEditReturnValue(world, rv) "{{{3
    return [a:world.state !~ '\<exit\>', a:world.base]
endf

function! tlib#EditListHandlers() "{{{3
    return [
                \ {'key': 5, 'agent': s:SNR() .'AgentEditItem',    'key_name': '<c-e>', 'help': 'Edit item'},
                \ {'key': 4, 'agent': s:SNR() .'AgentDeleteItems', 'key_name': '<c-d>', 'help': 'Delete item(s)'},
                \ {'key': 14, 'agent': s:SNR() .'AgentNewItem',    'key_name': '<c-n>', 'help': 'New item'},
                \ {'pick_last_item': 0},
                \ {'return_agent': s:SNR() .'AgentEditReturnValue'},
                \ ]
endf

function! tlib#EditList(query, list, ...) "{{{3
    let handlers = a:0 >= 1 ? a:1 : tlib#EditListHandlers()
    let rv       = a:0 >= 2 ? a:2 : ''
    let timeout  = a:0 >= 3 ? a:3 : 0
    " TLogVAR handlers
    let [success, list] = tlib#InputList('m', a:query, copy(a:list), handlers, rv, timeout)
    return success ? list : a:list
endf


""" List related functions {{{1
function! tlib#Inject(list, value, Function) "{{{3
    if empty(a:list)
        return a:value
    else
        let item  = a:list[0]
        let rest  = a:list[1:-1]
        let value = call(a:Function, [a:value, item])
        return tlib#Inject(rest, value, a:Function)
    endif
endf

function! tlib#Compact(list) "{{{3
    return filter(copy(a:list), '!empty(v:val)')
endf

function! tlib#Flatten(list) "{{{3
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

" tlib#FindAll(list, filter, ?process_expr="")
function! tlib#FindAll(list, filter, ...) "{{{3
    let rv   = filter(copy(a:list), a:filter)
    if a:0 >= 1 && a:1 != ''
        let rv = map(rv, a:1)
    endif
    return rv
endf

" tlib#Find(list, filter, ?default="", ?process_expr="")
function! tlib#Find(list, filter, ...) "{{{3
    let default = a:0 >= 1 ? a:1 : ''
    let expr    = a:0 >= 2 ? a:2 : ''
    return get(tlib#FindAll(a:list, a:filter, expr), 0, default)
endf

function! tlib#Any(list, expr) "{{{3
    return !empty(tlib#FindAll(a:list, a:expr))
endf

function! tlib#All(list, expr) "{{{3
    return len(tlib#FindAll(a:list, a:expr)) == len(a:list)
endf

function! tlib#Remove(list, element) "{{{3
    let idx = index(a:list, a:element)
    if idx == -1
        call remove(a:list, idx)
    endif
    return a:list
endf

function! tlib#RemoveAll(list, element) "{{{3
    call filter(a:list, 'v:val != a:element')
    return a:list
endf


""" Variables {{{1
function! tlib#Let(name, val)
    if !exists(a:name)
        " exec "let ". a:name ."='". a:val ."'"
        " exec 'let '. a:name .'="'. escape(a:val, '"\') .'"'
        let {a:name} = a:val
    endif
endf

" tlib#GetArg(var, n, ?default="", ?test='')
function! tlib#GetArg(n, var, ...) "{{{3
    let default = a:0 >= 1 ? a:1 : ''
    let atest   = a:0 >= 2 ? a:2 : ''
    if !empty(atest)
        let atest = ' && (a:'. a:n .' '. atest .')'
    endif
    let test = printf('a:0 >= %d', a:n) . atest
    return printf('let %s = %s ? a:%d : %s', a:var, test, a:n, string(default))
endf

" tlib#Args(list, ?default='')
function! tlib#Args(list, ...) "{{{3
    let default = a:0 >= 1 ? a:1 : ''
    let list = map(copy(a:list), 'type(v:val) == 3 ? v:val : [v:val, default]')
    let args = map(range(1, len(list)), 'call("tlib#GetArg", [v:val] + list[v:val - 1])')
    return join(args, ' | ')
endf

function! tlib#GetValue(var, namespace, ...) "{{{3
    for namespace in split(a:namespace, '\zs')
        let var = namespace .':'. a:var
        if exists(var)
            return eval(var)
        endif
    endfor
    return a:0 >= 1 ? a:1 : ''
endf

function! tlib#GetVar(var, namespace, ...) "{{{3
    let pre  = []
    let post = []
    for namespace in split(a:namespace, '\zs')
        let var = namespace .':'. a:var
        call add(pre,  printf('exists("%s") ? %s : (', var, var))
        call add(post, ')')
    endfor
    let default = a:0 >= 1 ? a:1 : ''
    return join(pre) . string(default) . join(post)
endf

function! tlib#EvalInBuffer(buffer, code) "{{{3
    let cb = bufnr('%')
    let wb = bufwinnr('%')
    " TLogVAR cb
    let sn = bufnr(a:buffer)
    let sb = sn != cb
    let lazyredraw = &lazyredraw
    set lazyredraw
    if sb
        let ws = bufwinnr(sn)
        if ws != -1
            try
                exec ws.'wincmd w'
                exec a:code
            finally
                exec wb.'wincmd w'
            endtry
        else
            try
                silent exec 'sbuffer! '. sn
                exec a:code
            finally
                wincmd c
            endtry
        endif
    else
        exec a:code
    endif
    let &lazyredraw = lazyredraw
endf



""" Command line {{{1
function! tlib#ExArg(arg, ...) "{{{3
    let chars = '%# \'
    if a:0 >= 1
        let chars .= a:1
    endif
    return escape(a:arg, chars)
endf


""" File names {{{1
let g:tlibFileNameSeparator = '/'
" let g:tlibFileNameSeparator = exists('+shellslash') && !&shellslash ? '\' : '/'

function! tlib#FileSplit(filename) "{{{3
    let prefix = matchstr(a:filename, '^\(\w\+:\)\?/\+')
    " TLogVAR prefix
    if !empty(prefix)
        let filename = a:filename[len(prefix) : -1]
    else
        let filename = a:filename
    endif
    let rv = split(filename, '[\/]')
    " let rv = split(filename, '[\/]', 1)
    if !empty(prefix)
        call insert(rv, prefix[0:-2])
    endif
    return rv
endf

function! tlib#FileJoin(filename_parts) "{{{3
    return join(a:filename_parts, g:tlibFileNameSeparator)
endf

function! tlib#DirName(dirname) "{{{3
    if a:dirname !~ '[/\\]$'
        return a:dirname . g:tlibFileNameSeparator
    endif
    return a:dirname
endf

function! tlib#RelativeFilename(filename, basedir) "{{{3
    let f0 = fnamemodify(a:filename, ':p')
    let fn = fnamemodify(f0, ':t')
    let fd = fnamemodify(f0, ':h')
    let f  = tlib#FileSplit(fd)
    " TLogVAR f
    let b0 = fnamemodify(a:basedir, ':p')
    let b  = tlib#FileSplit(b0)
    " TLogVAR b
    if f[0] != b[0]
        return f0
    else
        while !empty(f) && !empty(b)
            if f[0] != b[0]
                break
            endif
            call remove(f, 0)
            call remove(b, 0)
        endwh
        return tlib#FileJoin(repeat(['..'], len(b)) + f + [fn])
    endif
endf

function! tlib#EnsureDirectoryExists(dir) "{{{3
    if !isdirectory(a:dir)
        return mkdir(a:dir, 'p')
    endif
    return 1
endf

function! tlib#MyRuntimeDir() "{{{3
    return get(split(&rtp, ','), 0)
endf

function! tlib#GetCacheName(type, ...) "{{{3
    let file  = a:0 >= 1 && !empty(a:1) ? a:1 : expand('%:p')
    let mkdir = a:0 >= 2 ? a:2 : 0
    let dir   = tlib#MyRuntimeDir()
    let file  = tlib#RelativeFilename(file, dir)
    let file  = substitute(file, '\.\.\|[:&<>]\|//\+\|\\\\\+', '_', 'g')
    let dir   = tlib#FileJoin([dir, 'cache', a:type, fnamemodify(file, ':h')])
    let file  = fnamemodify(file, ':t')
    " TLogVAR dir
    " TLogVAR file
    if mkdir && !isdirectory(dir)
        call mkdir(dir, 'p')
    endif
    retur tlib#FileJoin([dir, file])
endf

function! tlib#CacheSave(cfile, dictionary) "{{{3
    call writefile([string(a:dictionary)], a:cfile, 'b')
endf

function! tlib#CacheGet(cfile) "{{{3
    if filereadable(a:cfile)
        let val = readfile(a:cfile, 'b')
        return eval(join(val, "\n"))
    else
        return {}
    endif
endf



""" Strings {{{1
function! tlib#RemoveBackslashes(text, ...) "{{{3
    exec tlib#GetArg(1, 'chars', ' ')
    " TLogVAR chars
    let rv = substitute(a:text, '\\\(['. chars .']\)', '\1', 'g')
    return rv
endf



""" URLs {{{1
" These functions could use printf() now.
function! tlib#DecodeURL(url)
    let rv = ''
    let n  = 0
    let m  = strlen(a:url)
    while n < m
        let c = a:url[n]
        if c == '+'
            let c = ' '
        elseif c == '%'
            if a:url[n + 1] == '%'
                let n = n + 1
            else
                " let c = escape(nr2char('0x'. strpart(a:url, n + 1, 2)), '\')
                let c = nr2char('0x'. strpart(a:url, n + 1, 2))
                let n = n + 2
            endif
        endif
        let rv = rv.c
        let n = n + 1
    endwh
    return rv
endf

function! tlib#EncodeChar(char)
    if a:char == '%'
        return '%%'
    elseif a:char == ' '
        return '+'
    else
        " Taken from eval.txt
        let n = char2nr(a:char)
        let r = ''
        while n
            let r = '0123456789ABCDEF'[n % 16] . r
            let n = n / 16
        endwhile
        return '%'. r
    endif
endf

function! tlib#EncodeURL(url)
    return substitute(a:url, '\([^a-zA-Z0-9_.-]\)', '\=EncodeChar(submatch(1))', 'g')
endf



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

" vi: fdm=marker
