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
	" Find the overview line {{{
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

	" Default results {{{
	let results = {}
	let results['pass'] = -1
	let results['count'] = { 'total':0, 'success':0, 'failure':0, 'error':0, 'test':0 }
	let results['messages'] = []
	" }}}

	" Parsing the line
	let i = 0
	for a in split(overview, ',')
		" Get count
		let x = str2nr(substitute(a, '\v ?(\d+).*', '\1', ''))

		" Attribute value to correct count
		if i == 0
			let results['count']['test'] = x
		elseif i == 1
			let results['count']['success'] = x
		elseif i == 2
			let results['count']['failure'] = x
		elseif i == 3
			let results['count']['error'] = x
		endif

		let i = i+1
	endfor
	" }}}

	" Implying other values {{{
	let results['count']['total'] = results['count']['success'] + results['count']['failure'] + results['count']['error']
	if (results['count']['total'] != 0 && results['count']['total'] == results['count']['success'])
		let results['pass'] = 1
	else
		let results['pass'] = 0
	endif
	" }}}

	" Some errors, we need to parse the messages {{{
	" Note: This is mostly hackish, parsing an expected output, but might
	" easily break for more complicated error output.
	if results['pass'] == 0

		let i = -1
		for line in lines
			let i = i + 1
			
			" Skip lines not messages
			if line !~# '\v^\s+\d+\) \w+:'
				continue
			endif

			let message = {}
			
			" Get the type
			let message['type'] = substitute(line, '\v^\s+\d+\) (\w+):', '\L\1', '')

			" Error {{{
			if message['type'] == "error"
				" Full message is directly available on i+2
				let message['text'] = lines[i+2]
				
				" For line number and function, we need to parse the i+3
				let overview = lines[i+3]
				" Set a comma-separated line and split it
				let commaList = substitute(overview, '\v^\s+(/.[^:]*):(\d+):in `(.*)''', '\1,\2,\3', '')
				let list = split(commaList, ',')
				let message['line'] = list[1]
				let message['function'] = list[2]
			endif
			" }}}
			
			" Failure {{{
			if message['type'] == "failure"
				" Full message starts on i+2 and may continue on i+3
				let message['text'] = lines[i+2]
				if lines[i+3] != ''
					let message['text'] = message['text'] . ' ' . lines[i+3]
				endif

				" For line number and function, we need to parse i+1
				let overview = lines[i+1]
				let commaList = substitute(overview, '\v^(.*)\(.*\[(.[^:]*):(\d+)\]:', '\1,\2,\3', '')
				let list = split(commaList, ',')
				let message['line'] = list[2]
				let message['function'] = list[0]
			endif
			" }}}

			" Add this message to the message list
			call add(results['messages'], message)
		endfor
	endif
	" }}}
	
	return results
endfunction
" }}}
