" Arval Ruby configuration file.

" Load config only once
if exists('g:arval_ruby_loaded')
	finish
endif
let g:arval_ruby_loaded = 1

" Do not overwrite possible user-defined method
if !exists('Arval_GetTestFile_ruby') " {{{
	" This is where you should define a custom method to get the file test for
	" a given filepath. I do not add one here because Arval will default to its
	" own search function if no filetype-specific function is defined.
	"
	" function! Arval_GetTestFile_ruby(filepath)
	"
	" endfunction
endif
" }}}

" Return command to test the file
function! Arval_GetTestCommand_ruby(filepath) " {{{
	return 'ruby ' . a:filepath
endfunction
" }}}

" Parses raw test output and return a dictionary
function! Arval_ParseRawOutput_ruby(output) " {{{
	" Find the overview line
	let lines = split(a:output, '\n')
	for line in lines
		if line =~# '\v^\d+ tests'
			let overview = line
			break
		endif
	endfor

	" No overview found
	if !exists('overview')
		return ''
	endif

	" Default results
	let results = {}
	let results['pass'] = -1
	let results['countTotal'] = 0
	let results['countSuccess'] = 0
	let results['countFailure'] = 0
	let results['countError'] = 0
	let results['countTest'] = 0

	" Parsing the line
	let i = 0
	for a in split(overview, ',')
		" Get count
		let x = str2nr(substitute(a, '\v ?(\d+).*', '\1', ''))

		" Attribute value to correct count
		if i == 0
			let results['countTest'] = x
		elseif i == 1
			let results['countSuccess'] = x
		elseif i == 2
			let results['countFailure'] = x
		elseif i == 3
			let results['countError'] = x
		endif

		let i = i+1
	endfor

	" Implying other values
	let results['countTotal'] = results['countSuccess'] + results['countFailure'] + results['countError']
	if (results['countTotal'] != 0 && results['countTotal'] == results['countSuccess'])
		let results['pass'] = 1
	else
		let results['pass'] = 0
	endif

	return results
endfunction
" }}}
