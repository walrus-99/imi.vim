function! fzf#vim#with_preview(spec) abort
  let g:imi_test_preview_spec = deepcopy(a:spec)
  return deepcopy(a:spec)
endfunction

function! fzf#vim#grep(command, with_column, spec, fullscreen) abort
  let g:imi_test_grep_args = [a:command, a:with_column, deepcopy(a:spec), a:fullscreen]
endfunction
