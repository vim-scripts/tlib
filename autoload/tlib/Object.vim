" Object.vim -- Prototype objects?
" @Author:      Thomas Link (mailto:samul AT web de?subject=[vim])
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-05-01.
" @Last Change: 2007-05-18.
" @Revision:    0.1.69

if &cp || exists("loaded_tlib_object_autoload")
    finish
endif
let loaded_tlib_object_autoload = 1

let s:id_counter = 0
let s:prototype  = {'_class': ['object'], '_super': [], '_id': 0} "{{{2
function! tlib#Object#New(...) "{{{3
    return s:prototype.New(a:0 >= 1 ? a:1 : {})
endf

function! s:prototype.New(...) dict "{{{3
    let object = deepcopy(self)
    let s:id_counter += 1
    let object._id = s:id_counter
    if a:0 >= 0 && !empty(a:1)
        call object.Extend(a:1)
    endif
    return object
endf

function! s:prototype.Inherit(object) dict "{{{3
    let class = copy(self._class)
    " TLogVAR class
    let objid = self._id
    for c in get(a:object, '_class', [])
        " TLogVAR c
        if index(class, c) == -1
            call add(class, c)
        endif
    endfor
    call extend(self, a:object, 'keep')
    let self._class = class
    " TLogVAR self._class
    let self._id    = objid
    " let self._super = [super] + self._super
    call insert(self._super, a:object)
    return self
endf

function! s:prototype.Extend(dictionary) dict "{{{3
    let super = copy(self)
    let class = copy(self._class)
    " TLogVAR class
    let objid = self._id
    for c in get(a:dictionary, '_class', [])
        " TLogVAR c
        if index(class, c) == -1
            call add(class, c)
        endif
    endfor
    call extend(self, a:dictionary)
    let self._class = class
    " TLogVAR self._class
    let self._id    = objid
    " let self._super = [super] + self._super
    call insert(self._super, super)
    return self
endf

function! s:prototype.IsA(class) dict "{{{3
    return index(self._class, a:class) != -1
endf

function! s:prototype.IsRelated(object) dict "{{{3
    return len(filter(a:object._class, 'self.IsA(v:val)')) > 1
endf

function! s:prototype.RespondTo(name) dict "{{{3
    return has_key(self, a:name)
endf

function! s:prototype.Super(method, arglist) dict "{{{3
    for o in self._super
        " TLogVAR o
        if o.RespondTo(a:method)
            let self._tmp_method = o[a:method]
            " TLogVAR self._tmp_method
            return call(self._tmp_method, a:arglist, self)
        endif
    endfor
    echoerr 'tlib#Object: Does not respond to '. a:method .': '. string(self)
endf

