" tLib.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=vim-tLib)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-17.
" @Last Change: 2007-04-25.
" @Revision:    31

TAssertBegin! "tlib", 'autoload/tlib.vim'

fun! Add(a,b)
    return a:a + a:b
endf
TAssert IsEqual(tlib#Inject([], 0, function('Add')), 0)
TAssert IsEqual(tlib#Inject([1,2,3], 0, function('Add')), 6)
delfunction Add

TAssert IsEqual(tlib#Compact([]), [])
TAssert IsEqual(tlib#Compact([0,1,2,3,[], {}, ""]), [1,2,3])

TAssert IsEqual(tlib#Flatten([]), [])
TAssert IsEqual(tlib#Flatten([1,2,3]), [1,2,3])
TAssert IsEqual(tlib#Flatten([1,2, [1,2,3], 3]), [1,2,1,2,3,3])
TAssert IsEqual(tlib#Flatten([0,[1,2,[3,""]]]), [0,1,2,3,""])

" TAssert IsEqual(TFind([], '%s == 2'), '')
" TAssert IsEqual(TFind([], '%s == 2', 'X'), 'X')
" TAssert IsEqual(TFind([1,2,3], '%s == 2'), 2)
" TAssert IsEqual(TFind([0,[1,2,[3,""]]], '%s == 2'), '')

" TAssert IsEqual(TFindValue([], '%s == 2'), '0')
" TAssert IsEqual(TFindValue([], '%s == 2', 'X'), 'X')
" TAssert IsEqual(TFindValue([1,2,3], '%s == 2'), 1)
" TAssert IsEqual(TFindValue([0,[1,2,[3,""]]], '%s == 2'), '0')

let g:foo = 1
let g:bar = 2
let b:bar = 3
let s:bar = 4

TAssert IsEqual(tlib#GetValue('bar', 'bg'), 3)
TAssert IsEqual(tlib#GetValue('bar', 'g'), 2)
TAssert IsEqual(tlib#GetValue('foo', 'bg'), 1)
TAssert IsEqual(tlib#GetValue('foo', 'g'), 1)
TAssert IsEqual(tlib#GetValue('none', 'l'), '')

TAssert IsEqual(eval(tlib#GetVar('bar', 'bg')), 3)
TAssert IsEqual(eval(tlib#GetVar('bar', 'g')), 2)
" TAssert IsEqual(eval(tlib#GetVar('bar', 'sg')), 4)
TAssert IsEqual(eval(tlib#GetVar('foo', 'bg')), 1)
TAssert IsEqual(eval(tlib#GetVar('foo', 'g')), 1)
TAssert IsEqual(eval(tlib#GetVar('none', 'l')), '')

unlet g:foo
unlet g:bar
unlet b:bar

TAssertEnd


finish

call tlib#InputList('s', 'Test', ['barfoobar', 'barFoobar'])
call tlib#InputList('s', 'Test', ['barfoobar', 'bar foo bar', 'barFoobar'])
call tlib#InputList('s', 'Test', ['barfoobar', 'bar1Foo1bar', 'barFoobar'])


