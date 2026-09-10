set nomore

let s:repo_root = fnamemodify(expand('<sfile>'), ':p:h:h')
execute 'set runtimepath^=' . fnameescape(s:repo_root)
execute 'set runtimepath^=' . fnameescape(s:repo_root . '/test/fixtures')

unlet! g:loaded_imi g:imi_default_mappings
runtime plugin/imi.vim

call assert_equal(2, exists(':Imi'), ':Imi must be registered')
call assert_equal(2, exists(':ImiHome'), ':ImiHome must be registered')
call assert_equal(2, exists(':ImiGrep'), ':ImiGrep must be registered')
call assert_equal(':Imi<CR>', maparg('<leader>g', 'n'), 'The default :Imi mapping must be registered')
call assert_equal(':ImiHome<CR>', maparg('<leader>h', 'n'), 'The default :ImiHome mapping must be registered')
call assert_equal(':ImiGrep ', maparg('<leader>f', 'n'), 'The default :ImiGrep mapping must be registered')

let s:query = "command query with 'quote"
unlet! g:imi_test_grep_args
execute 'ImiGrep ' . s:query
let s:expected_grep = 'rg --column --line-number --no-heading --color=always --smart-case --hidden --glob "!.git/*" '
      \ . shellescape(s:query)
call assert_equal(s:expected_grep, g:imi_test_grep_args[0], ':ImiGrep must forward its complete query')

silent! nunmap <leader>g
silent! nunmap <leader>h
silent! nunmap <leader>f
delcommand Imi
delcommand ImiHome
delcommand ImiGrep
unlet! g:loaded_imi
let g:imi_default_mappings = 0
runtime plugin/imi.vim

call assert_equal(2, exists(':Imi'), ':Imi must be registered when mappings are disabled')
call assert_equal('', maparg('<leader>g', 'n'), 'The :Imi mapping must be optional')
call assert_equal('', maparg('<leader>h', 'n'), 'The :ImiHome mapping must be optional')
call assert_equal('', maparg('<leader>f', 'n'), 'The :ImiGrep mapping must be optional')

unlet! g:imi_test_grep_args g:imi_test_preview_spec

if empty(v:errors)
  quit
endif

for error in v:errors
  echomsg error
endfor
cquit
