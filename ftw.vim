" diese datei nach ~/.vim/syntax/ftw.vim kopieren und
" folgendes in die ~/.vimrc schmeissen:
" > syntax on
" > filetype on
" > augroup filetypedetect
" > 	au BufNewFile,BufRead *.ftw setf ftw
" > augroup END
"
" have fun :)

if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif

syn case match
syn sync lines=250

syn match Statement "!x"
syn match Statement "!e"
syn match Statement "!c"
syn match Statement "!l"
syn match Statement "!b"

syn match Special "{"
syn match Special "}"
syn match Special " ;"

syn match Identifier "\[\w\+\]"
syn match Constant "\[\[\w\+\]\]"

syn match Comment /#.*/

let b:current_syntax = "ftw"

