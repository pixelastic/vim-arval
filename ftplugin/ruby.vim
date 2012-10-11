" SplitestGetTestFile {{{
" Return the matching test file for a given filepath
function! SplitestGetTestFile(filepath) 
	let filepath = expand(a:filepath)

	" This is itself a test
	if filepath =~ '.test.rb$'
		return filepath
	endif

	return ''
endfunction
" }}}
" SplitestRun {{{
function! SplitestRun()
	" Keep track of which files have their tests opened
	if !exists('g:SplitestOpenedTests')
		let g:SplitestOpenedTests = {}
	endif

	" Closing existing window if opened
	let filepath = expand("%:p")
	if get(g:SplitestOpenedTests, filepath, 0) == 1
		wincmd j
		execute 'quit!'
	endif

	" Spliting window
	let g:SplitestOpenedTests[filepath] = 1
	rightbelow new

	" Adding some special config to that window
	execute 'au BufDelete <buffer> let g:SplitestOpenedTests["'.filepath.'"] = 0'
	set readonly
	set wrap
	nnoremap <silent> <buffer> q :quit!<CR>
	nnoremap <silent> <buffer> <C-D> :quit!<CR>
	nnoremap <silent> <buffer> <F5> :quit!<CR>

	" Adding content
	let testFilepath = SplitestGetTestFile(filepath)
	silent execute '.!ruby '.testFilepath

endfunction
" }}}


" Map F5 to run the tests
let b:SplitestTestFile = SplitestGetTestFile(expand("%"))
if b:SplitestTestFile != ''
	nnoremap <silent> <buffer> <F5> :call SplitestRun()<CR>
endif



