" Arval
" Vim plugin to know if the file you're editing passes its tests or not.

" 
" Script Initialization
"


"
" Buffer Initialization
" 
function s:LoadFiletypeConfig(ft) " {{{
	echo a:ft
	" Load it only once
	if exists('g:arval_ruby_loaded')
		return 1
	endif
	
	let configFile = "languages/" . a:ft . ".vim"
	execute "runtime " . configFile

	" Error in loading
	if !exists('g:arval_ruby_loaded')
		return 0
	endif
	
	return 1
endfunction
"}}}

augroup arval_bufer
	autocmd BufReadPost * call s:LoadFiletypeConfig(&ft)
augroup END

	


