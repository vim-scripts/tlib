" tag.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-11-01.
" @Last Change: 2007-11-04.
" @Revision:    0.0.28

if &cp || exists("loaded_tlib_tag_autoload")
    finish
endif
let loaded_tlib_tag_autoload = 1


" :def: function! tlib#tag#Retrieve(rx, ?extra_tags=0)
" Get all tags matching rx. Basically, this function simply calls 
" |taglist()|, but when extra_tags is true, the list of the tag files 
" (see 'tags') is temporarily expanded with |g:tlib_tags_extra|.
function! tlib#tag#Retrieve(rx, ...) "{{{3
    TVarArg ['extra_tags', 0]
    if extra_tags
        let tags_orig = &l:tags
        if empty(tags_orig)
            setlocal tags<
        endif
        try
            let more_tags = tlib#var#Get('tlib_tags_extra', 'bg')
            if !empty(more_tags)
                let &l:tags .= ','. more_tags
            endif
            let taglist = taglist(a:rx)
        finally
            let &l:tags = tags_orig
        endtry
    else
        let taglist = taglist(a:rx)
    endif
    return taglist
endf


" Retrieve tags that meet the the constraints (a dictionnary of fields and 
" regexp, with the exception of the kind field that is a list of chars). 
" For the use of the optional use_extra argument see 
" |tlib#tag#Retrieve()|.
" :def: function! tlib#tag#Collect(constraints, ?use_extra=0, ?match_front=0)
function! tlib#tag#Collect(constraints, ...) "{{{3
    TVarArg ['use_extra', 0], ['match_front', 0]
    " TLogVAR a:constraints, use_extra
    let rx = get(a:constraints, 'name', '')
    if empty(rx) || rx == '*'
        let rx = '.'
    else
        let rx = '\C^'. tlib#rx#Escape(rx)
        if !match_front
            let rx .= '$'
        endif
    endif
    " TLogVAR rx, use_extra
    let tags = tlib#tag#Retrieve(rx, use_extra)
    " TLogDBG len(tags)
    for [field, rx] in items(a:constraints)
        if !empty(rx) && rx != '*'
            " TLogVAR field, rx
            if field == 'kind'
                call filter(tags, 'v:val.kind =~ "['. rx .']"')
            elseif field != 'name'
                call filter(tags, '!empty(get(v:val, field)) && get(v:val, field) =~ rx')
            endif
        endif
    endfor
    return tags
endf


function! tlib#tag#Format(tag) "{{{3
    if has_key(a:tag, 'signature')
        let name = a:tag.name . a:tag.signature
    elseif a:tag.cmd[0] == '/'
        let name = a:tag.cmd
        let name = substitute(name, '^/\^\?\s*', '', '')
        let name = substitute(name, '\s*\$\?/$', '', '')
        let name = substitute(name, '\s\{2,}', ' ', 'g')
    else
        let name = a:tag.name
    endif
    return name
endf

