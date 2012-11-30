" Arval
" Vim plugin to know if the file you're editing passes its tests or not.

" Script Initialization {{{

" The only method you'll ever need to call.
command! ArvalTest call s:GetTestResults()

" }}}

" Buffer Initialization {{{
augroup arval_bufer
	" Load filetype-specific functions on each buffer
	autocmd BufReadPost * call s:LoadFiletypeConfig(&ft)
augroup END

function! s:LoadFiletypeConfig(ft) " {{{
	" Loads functions specific to the current filetype. Fired on every new
	" buffer, but only load files if not already loaded.

	if exists('g:arval_' . a:ft . '_loaded')
		return 1
	endif
	
	let configFile = "languages/" . a:ft . ".vim"
	execute "runtime " . configFile

	" Error in loading
	if !exists('g:arval_' . a:ft .'_loaded')
		return 0
	endif
	
	return 1
endfunction
" }}}

" }}}

" Public Functions {{{

function! s:GetTestResults()
	let testfile = s:GetTestFile(expand('%'), &ft)
	echo testfile
endfunction

" }}}

" Private Functions {{{

function! s:GetTestFile(file, ft) " {{{
	" Returns path to the test file associated to the current file.
	" Will first look for a user-defined b:ArvalGetTestFile function, if not
	" found will try the one defined for this filetype, and if still not found
	" will try the default method. 
	" Will only return a filepath if the file exists, anyway.
	
	let testfile = ''
	let fullpath = fnamemodify(a:file, ':p')
	let ftfunction = 'Arval_GetTestFile_'. a:ft
	
	" Try methods in order
	if exists('*b:ArvalGetTestFile')
		let testfile = b:ArvalGetTestFile(fullpath)
	elseif exists('*' . ftfunction)
		execute 'let testfile = '. ftfunction . "('" . fullpath . "')"
	else
		let testfile = s:GetTestFile_default(fullpath)
	endif

	" Expand testfile one last time to be sure to have a full path
	let testfile = fnamemodify(testfile, ':p')

	" Return only if readable
	if (testfile ==? '' || !filereadable(testfile))
		return 0
	endif

	return testfile
endfunction
" }}}

function! s:GetTestFile_default(file) " {{{
	" First look for a filename.test.ext, then for a tests/filename.test.ext
	
	let fullpath = fnamemodify(a:file, ':p')
	let basepath = fnamemodify(fullpath, ':h')
	let ext = fnamemodify(fullpath, ':e')
	let basename = fnamemodify(fullpath, ':t:r')

	" /fullpath/filename.test.ext
	let testpath = basepath . '/' . basename . '.test.' . ext
	if filereadable(testpath)
		return testpath
	endif

	" /fullpath/tests/filename.test.ext
	let testpath = basepath . '/tests/' . basename . '.test.' . ext
	if filereadable(testpath)
		return testpath
	endif

	" No test file found
	return ''

endfunction
" }}}

" }}}
