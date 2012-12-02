" Arval
" Vim plugin to know if the file you're editing passes its tests or not.

" Script Initialization {{{
" Stores information about which message windows are currently opened
let g:arval_opened_message_windows = {}
" }}}

" Buffer Initialization {{{
augroup arval_buffer
	" Load filetype-specific functions on each buffer
	autocmd BufReadPost * call s:LoadFiletypeConfig(&ft)
	" Init default values for statusline
	autocmd BufReadPost * let b:arval_test_pass = -1
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

" Exposed commands
command! ArvalTest call s:TestCurrentFile()
command! ArvalDisplayMessageWindow call s:DisplayMessageWindow()

function! ArvalGetTestFile() " {{{
	return s:GetTestFile(expand('%:p'), &ft)
endfunction
" }}}

" }}}


function! s:TestCurrentFile() " {{{
	let filepath = expand('%:p')
	let ft = &ft

	" First, check for a test file
	let testfile = s:GetTestFile(filepath, ft)
	if testfile ==? ''
		echo "No test file found."
		return
	endif

	" Then, how to run it
	let testcommand = s:GetTestCommand(testfile, ft)
	if testcommand ==? ''
		echo "Unable to run tests on file, no command found."
		return
	endif

	" Finally, parse the results in a known format
	let testresults = s:GetTestResults(testcommand, ft)
	if type(testresults) == 1 && testresults ==? ''
		echo "Unable to parse test results, no parser found"
		return
	endif

	" Set a buffer variable indicating if tests passes or not
	let b:arval_test_pass = testresults['pass']
	" Also expose the test results to anyone
	let b:arval_test_results = testresults

	" Display errors to users
	if testresults['pass'] == 0 && len(testresults['messages']) > 0
		call s:DisplayMessageWindow()
	endif

	" Hide errors if tests pass
	if testresults['pass'] == 1 && s:IsMessageWindowOpened() == 1
		call s:CloseMessageWindow()
	endif

endfunction
" }}}

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
function! s:GetTestCommand(file, ft) " {{{
	" Will return the shell command to run the tests and get the output.
	" A Arval_GetTestCommand_{ft}() function must be defined.
	
	let fullpath = fnamemodify(a:file, ':p')
	let ftfunction = 'Arval_GetTestCommand_' . a:ft
	if !exists('*'.ftfunction)
		return ''
	endif

	execute 'let testcommand = ' . ftfunction . "('" . fullpath . "')"
	return testcommand
endfunction
" }}}
function! s:GetTestResults(command, ft) " {{{
	" Will execute the shell command, parse it and return and associative array
	" containing all valuable results
	
	" No need to go further if we do not have the method to parse the raw output
	let ftfunction = "Arval_ParseRawOutput_" . a:ft
	if !exists('*' . ftfunction)
		return ''
	endif

	" Get raw result from the command output
	execute 'let rawresult = system('. shellescape(a:command) . ')'

	" Parse the command
	let rawresult = substitute(rawresult, "'", "''", "g")
	execute 'let testresult = ' . ftfunction . "('" . rawresult . "')" 

	return testresult
endfunction
" }}}

function! s:DisplayMessageWindow() " {{{
	" Nothing to display
	if !exists('b:arval_test_results') || len(b:arval_test_results['messages']) == 0
		return
	endif

	" Closing the window if already opened
	if s:IsMessageWindowOpened()
		call s:CloseMessageWindow()
	endif

	let messages = b:arval_test_results['messages']

	" Open a split window to display a max of 2 messages
	let height = min([4, 2 * len(messages)])
	call s:OpenEmptyMessageWindow(height, expand('%:p'))

	" Append text and go back to main window
	call append(0, s:GetMessageLines(messages))
	normal Gddgg
	wincmd k
endfunction
" }}}
function! s:CloseMessageWindow() " {{{
		wincmd j
		execute 'quit!'	
endfunction
" }}}
function! s:RegisterOpenedMessageWindow(filepath, status) " {{{
	" Save window message status of given filepath
	let g:arval_opened_message_windows[a:filepath] = a:status
endfunction
" }}}
function! s:IsMessageWindowOpened() " {{{
	" Decide if we need to open a new message window or if it is already opened
	let filepath = expand('%:p')
	return get(g:arval_opened_message_windows, filepath, 0)
endfunction
" }}}
function! s:GetMessageLines(messages) " {{{
	" Return a List containing all the lines to display in the split window
	let text = []
	for message in a:messages
		let line1 = toupper(strpart(message['type'], 0, 1)) . ':' . message['line'] . ' ' . message['function']
		let line2 = message['text']
		call add(text, line1)
		call add(text, line2)
	endfor
	return text
endfunction
" }}}
function! s:OpenEmptyMessageWindow(height, filepath) " {{{
	" Open a new split window to display the messages
	rightbelow new
	" Mark it as opened
	call s:RegisterOpenedMessageWindow(a:filepath, 1)
	" Set the height
	execute 'resize ' . a:height
	" Hide statusbar and line number
	setlocal laststatus=0
	setlocal statusline=''
	setlocal noruler
	setlocal nonumber
	" Close it with q
	nnoremap <silent> <buffer> q :quit!<CR>
	nnoremap <silent> <buffer> <C-D> :quit!<CR>
	nnoremap <silent> <buffer> <Esc> :quit!<CR>
	" Mark it as closed when closed
	execute 'au BufDelete <buffer> call s:RegisterOpenedMessageWindow(''' . a:filepath . ''', 0)'
endfunction
" }}}

" }}}

