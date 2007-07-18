" input.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2007-07-18.
" @Revision:    0.0.11

if &cp || exists("loaded_tlib_input_autoload")
    finish
endif
let loaded_tlib_input_autoload = 1


""" Input-related, select from a list etc. {{{1

" Functions related to tlib#input#List(type, ...) "{{{2

" tlib#input#List(type. ?query='', ?list=[], ?handlers=[], ?default="", ?timeout=0)
"
" Select a single or multiple items from a list. Return either the list 
" of selected elements or its indexes.
"
" type can be:
"     s  ... Return one selected element
"     si ... Return the index of the selected element
"     m  ... Return a list of selcted elements
"     mi ... Return a list of indexes
"
" EXAMPLES:
" echo tlib#input#List('s', 'Select one item', [100,200,300])
" echo tlib#input#List('si', 'Select one item', [100,200,300])
" echo tlib#input#List('m', 'Select one or more item(s)', [100,200,300])
" echo tlib#input#List('mi', 'Select one or more item(s)', [100,200,300])
function! tlib#input#List(type, ...) "{{{3
    exec tlib#arg#Let([
        \ ['query', ''],
        \ ['list', []],
        \ ['handlers', []],
        \ ['rv', ''],
        \ ['timeout', 0],
        \ ])
    " let handlers = a:0 >= 1 ? a:1 : []
    " let rv       = a:0 >= 2 ? a:2 : ''
    " let timeout  = a:0 >= 3 ? a:3 : 0
    let backchar = ["\<bs>", "\<del>"]

    if a:type =~ '^resume'
        let world = b:tlib_{matchstr(a:type, ' \zs.\+')}
        " unlet b:tlib_{matchstr(a:type, ' \zs.\+')}
        let [_, query, list, handlers, rv, timeout] = world.arguments
    else
        let world = tlib#World#New({
                    \ 'type': a:type,
                    \ 'base': list,
                    \ 'win_wnr': winnr(),
                    \ 'query': query,
                    \ 'arguments': [a:type, query, list, handlers, rv, timeout],
                    \ })
    endif

    let state_handlers   = filter(copy(handlers), 'has_key(v:val, "state")')
    let post_handlers    = filter(copy(handlers), 'has_key(v:val, "postprocess")')
    let display_format   = tlib#list#Find(handlers, 'has_key(v:val, "display_format")', '', 'v:val.display_format')
    if display_format == 'filename'
        " let display_format = 'printf("%%-20s  %%s", fnamemodify(%s, ":t"), fnamemodify(%s, ":h"))'
        let display_format = 's:DisplayFormat(%s)'
    endif
    let filter_format    = tlib#list#Find(handlers, 'has_key(v:val, "filter_format")', '', 'v:val.filter_format')
    let return_agent     = tlib#list#Find(handlers, 'has_key(v:val, "return_agent")')
    let resize_value     = tlib#list#Find(handlers, 'has_key(v:val, "resize")')
    if !empty(resize_value) && a:type !~ '^resume'
        let world.resize = resize_value.resize
    endif
    let show_empty       = tlib#list#Find(handlers, 'has_key(v:val, "show_empty")', 0, 'v:val.show_empty')
    let pick_last_item   = tlib#list#Find(handlers, 'has_key(v:val, "pick_last_item")', 
                \ tlib#var#Get('tlib_pick_last_item', 'bg'), 'v:val.pick_last_item')
    let numeric_chars    = tlib#list#Find(handlers, 'has_key(v:val, "numeric_chars")', 
                \ tlib#var#Get('tlib_numeric_chars', 'bg'), 'v:val.numeric_chars')
    let key_handlers = filter(copy(handlers), 'has_key(v:val, "key")')
    let key_agents = copy(g:tlib_keyagents_InputList_s)
    if stridx(world.type, 'm') != -1
        call extend(key_agents, g:tlib_keyagents_InputList_m, 'force')
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
        while !empty(world.state) && world.state !~ '^exit' && (show_empty || !empty(world.base))
            " TLogDBG 'while'
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
                    " TLogDBG 'reset'
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
                    call world.DisplayList(world.type, handlers, world.query .' (filter: '. world.DisplayFilter() .'; press "?" for help)', dlist)
                    " TLogDBG 9
                    let world.state = ''

                else
                    if world.state == 'scroll'
                        let world.prefidx = world.offset
                    endif
                    call world.DisplayList(world.type, handlers, '')
                    if world.state == 'help'
                        let world.state = 'display'
                    else
                        let world.state = ''
                    endif
                endif
                let world.list_wnr = winnr()

                " TLogVAR timeout
                let c = tlib#char#Get(timeout)
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
                        let c = tlib#char#Get(timeout)
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
                " TLogDBG 'finally 1'
                if world.state =~ '\<suspend\>'
                elseif !empty(world.list) && !empty(world.base)
                    " TLogVAR world.list
                    if empty(world.state)
                        " TLogVAR world.state
                        if stridx(world.type, 'i') != -1
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

        " TLogDBG 'exit while loop'
        " TLogVAR world.list
        " TLogVAR world.sel_idx
        " TLogVAR world.idx
        " TLogVAR world.prefidx
        " TLogVAR rv
        if world.state =~ '\<suspend\>'
        elseif !empty(return_agent)
            return call(return_agent.return_agent, [world, rv])
        elseif stridx(world.type, 'm') != -1
            return world.GetSelectedItems(rv)
        else
            return rv
        endif

    finally
        let &statusline = statusline
        let &laststatus = laststatus
        " TLogDBG 'finally 2'
        if world.state !~ '\<suspend\>'
            call world.CloseScratch()
            exec world.win_wnr .'wincmd w'
        endif
        for i in range(0,5)
            call getchar(0)
        endfor
        echo
        redraw
    endtry
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

function! s:DisplayFormat(file) "{{{3
    let fname = fnamemodify(a:file, ":p:t")
    " let fname = fnamemodify(a:file, ":t")
    " if isdirectory(a:file)
    "     let fname .='/'
    " endif
    let dname = fnamemodify(a:file, ":h")
    let dnmax = &co - max([20, len(fname)]) - 12 - &fdc
    if len(dname) > dnmax
        let dname = '...'. strpart(fnamemodify(a:file, ":h"), len(dname) - dnmax)
    endif
    return printf("%-20s   %s", fname, dname)
endf


" Functions related to tlib#input#EditList(type, ...) "{{{2

" function! tlib#input#EditList(query, list, ?timeout=0)
" Edit a list.
"
" EXAMPLES:
" echo tlib#input#EditList('Edit:', [100,200,300])
function! tlib#input#EditList(query, list, ...) "{{{3
    let handlers = a:0 >= 1 ? a:1 : g:tlib_handlers_EditList
    let rv       = a:0 >= 2 ? a:2 : ''
    let timeout  = a:0 >= 3 ? a:3 : 0
    " TLogVAR handlers
    let [success, list] = tlib#input#List('m', a:query, copy(a:list), handlers, rv, timeout)
    return success ? list : a:list
endf


