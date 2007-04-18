" tLib.vim
" @Author:      Thomas Link (mailto:samul AT web de?subject=vim-tLib)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-17.
" @Last Change: 2007-04-10.
" @Revision:    12

TAssertBegin! "tlib", 'autoload/tlib.vim'


fun! Add(a,b)
    return a:a + a:b
endf
TAssert IsEqual(tlib#Inject([], 0, function('Add')), 0)
TAssert IsEqual(tlib#Inject([1,2,3], 0, function('Add')), 6)


TAssert IsEqual(tlib#Compact([]), [])
TAssert IsEqual(tlib#Compact([0,1,2,3,""]), [1,2,3])


TAssert IsEqual(tlib#Flatten([]), [])
TAssert IsEqual(tlib#Flatten([1,2,3]), [1,2,3])
TAssert IsEqual(tlib#Flatten([0,[1,2,[3,""]]]), [0,1,2,3,""])


" TAssert IsEqual(TFind([], '%s == 2'), '')
" TAssert IsEqual(TFind([], '%s == 2', 'X'), 'X')
" TAssert IsEqual(TFind([1,2,3], '%s == 2'), 2)
" TAssert IsEqual(TFind([0,[1,2,[3,""]]], '%s == 2'), '')


" TAssert IsEqual(TFindValue([], '%s == 2'), '0')
" TAssert IsEqual(TFindValue([], '%s == 2', 'X'), 'X')
" TAssert IsEqual(TFindValue([1,2,3], '%s == 2'), 1)
" TAssert IsEqual(TFindValue([0,[1,2,[3,""]]], '%s == 2'), '0')


TAssertEnd Add()

