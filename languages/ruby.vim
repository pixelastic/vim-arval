" Arval Ruby configuration file.

" Load config only once
if exists('g:arval_ruby_loaded')
	finish
endif
let g:arval_ruby_loaded = 1

" Do not overwrite possible user-defined method
if !exists('Arval_GetTestFile_ruby')
	" This is where you should define a custom method to get the file test for
	" a given filepath. I do not add one here because Arval will default to its
	" own search function if no filetype-specific function is defined.
	"
	" function! Arval_GetTestFile_ruby(filepath)
	"
	" endfunction
endif

function! Arval_GetTestCommand_ruby(filepath)
	return 'ruby ' . a:filepath
endfunction

function! Arval_ParseRawOutput_ruby(output)
	echo "--------------"
	echo a:output
	echo "--------------"

	return "ok"
endfunction
