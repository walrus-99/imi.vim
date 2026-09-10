if exists('g:loaded_imi')
  finish
endif

let g:loaded_imi = 1

command! Imi call imi#files_smart()
command! ImiHome call imi#files_home()
command! -nargs=* ImiGrep call imi#grep(<q-args>)

if get(g:, 'imi_default_mappings', 1)
  nnoremap <silent> <leader>g :Imi<CR>
  nnoremap <silent> <leader>h :ImiHome<CR>
  nnoremap <leader>f :ImiGrep<Space>
endif
