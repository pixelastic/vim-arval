" Arval Ruby configuration file.

" Load config only once
if exists('g:arval_ruby_loaded')
	finish
endif
let g:arval_ruby_loaded = 1

function! Arval_GetTestFile_ruby(filepath)
	return '~/.vimrc'
endfunction
