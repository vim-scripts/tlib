" agent.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-24.
" @Last Change: 2007-06-24.
" @Revision:    0.1.21

if &cp || exists("loaded_tlib_agent_autoload")
    finish
endif
let loaded_tlib_agent_autoload = 1


" General {{{1
function! tlib#agent#Exit(world, selected) "{{{3
    call tlib#CloseScratch(a:world)
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


" Files related {{{1
function! tlib#agent#EditFile(world, selected)
    call tlib#CloseScratch(a:world)
    call tlib#ExWithFiles(a:world, 'edit', 'buffer', a:selected)
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#EditFileInSplit(world, selected)
    call tlib#CloseScratch(a:world)
    call tlib#ExWithFiles(a:world, 'edit', 'buffer', a:selected[0:0])
    call tlib#ExWithFiles(a:world, 'split', 'sbuffer', a:selected[1:-1])
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#EditFileInVSplit(world, selected)
    call tlib#CloseScratch(a:world)
    call tlib#ExWithFiles(a:world, 'edit', 'buffer', a:selected[0:0])
    call tlib#ExWithFiles(a:world, 'vertical split', 'vertical sbuffer', a:selected[1:-1])
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#EditFileInTab(world, selected)
    call tlib#CloseScratch(a:world)
    call tlib#ExWithFiles(a:world, 'tabe', 'tab buffer', a:selected)
    return tlib#agent#Exit(a:world, a:selected)
endf

function! tlib#agent#ToggleScrollbind(world, selected)
    let a:world.scrollbind = get(a:world, 'scrollbind') ? 0 : 1
    let a:world.state = 'redisplay'
    return a:world
endf

