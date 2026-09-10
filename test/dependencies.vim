set nomore

let s:repo_root = fnamemodify(expand('<sfile>'), ':p:h:h')
let s:fixtures = s:repo_root . '/test/fixtures'
let s:original_rtp = &runtimepath
let s:original_path = $PATH
let s:work_dir = tempname()
call mkdir(s:work_dir, 'p')

function! s:add_executable(directory, name) abort
  let path = a:directory . '/' . a:name
  call writefile(['#!/bin/sh', 'exit 0'], path)
  call setfperm(path, 'rwxr-xr-x')
endfunction

try
  let s:no_plugin_bin = s:work_dir . '/no-plugin-bin'
  call mkdir(s:no_plugin_bin)
  call s:add_executable(s:no_plugin_bin, 'fzf')
  call s:add_executable(s:no_plugin_bin, 'fd')
  let &runtimepath = s:repo_root
  let $PATH = s:no_plugin_bin
  redir => s:no_plugin_message
  try
    call imi#files_smart()
  catch
    call assert_report('Missing fzf.vim must not throw: ' . v:exception)
  endtry
  redir END
  call assert_match('fzf core Vim plugin not found', s:no_plugin_message,
        \ 'A missing fzf core Vim plugin must produce an actionable message')

  let s:base_runtime = s:work_dir . '/base-runtime'
  call mkdir(s:base_runtime . '/autoload', 'p')
  call writefile([
        \ 'function! fzf#run(spec) abort',
        \ '  let g:imi_test_fzf_spec = deepcopy(a:spec)',
        \ 'endfunction'], s:base_runtime . '/autoload/fzf.vim')
  let s:no_integration_bin = s:work_dir . '/no-integration-bin'
  call mkdir(s:no_integration_bin)
  call s:add_executable(s:no_integration_bin, 'fzf')
  call s:add_executable(s:no_integration_bin, 'rg')
  let &runtimepath = s:base_runtime . ',' . s:repo_root
  let $PATH = s:no_integration_bin
  redir => s:no_integration_message
  try
    call imi#grep('query')
  catch
    call assert_report('Missing fzf.vim integration must not throw: ' . v:exception)
  endtry
  redir END
  call assert_match('fzf.vim integration not found', s:no_integration_message,
        \ 'A partial fzf.vim installation must produce an actionable message')

  let s:no_fzf_bin = s:work_dir . '/no-fzf-bin'
  call mkdir(s:no_fzf_bin)
  call s:add_executable(s:no_fzf_bin, 'fd')
  let &runtimepath = s:fixtures . ',' . s:repo_root
  let $PATH = s:no_fzf_bin
  redir => s:no_fzf_message
  try
    call imi#files_smart()
  catch
    call assert_report('Missing fzf executable must not throw: ' . v:exception)
  endtry
  redir END
  call assert_match('fzf executable not found', s:no_fzf_message,
        \ 'A missing fzf executable must produce an actionable message')

  let s:grep_no_fzf_bin = s:work_dir . '/grep-no-fzf-bin'
  call mkdir(s:grep_no_fzf_bin)
  call s:add_executable(s:grep_no_fzf_bin, 'rg')
  let $PATH = s:grep_no_fzf_bin
  unlet! g:imi_test_grep_args
  redir => s:grep_no_fzf_message
  try
    call imi#grep('query')
  catch
    call assert_report('Missing fzf during grep must not throw: ' . v:exception)
  endtry
  redir END
  call assert_match('fzf executable not found', s:grep_no_fzf_message,
        \ 'Grep must report a missing fzf executable')
  call assert_false(exists('g:imi_test_grep_args'), 'Missing fzf must not invoke fzf grep')

  let s:no_rg_bin = s:work_dir . '/no-rg-bin'
  call mkdir(s:no_rg_bin)
  call s:add_executable(s:no_rg_bin, 'fzf')
  let $PATH = s:no_rg_bin
  unlet! g:imi_test_grep_args
  redir => s:no_rg_message
  try
    call imi#grep('query')
  catch
    call assert_report('Missing ripgrep must not throw: ' . v:exception)
  endtry
  redir END
  call assert_match('ripgrep (rg) is required', s:no_rg_message,
        \ 'A missing ripgrep executable must produce an actionable message')
  call assert_false(exists('g:imi_test_grep_args'), 'Missing ripgrep must not invoke fzf')
finally
  let &runtimepath = s:original_rtp
  let $PATH = s:original_path
  call delete(s:work_dir, 'rf')
  unlet! g:imi_test_fzf_spec g:imi_test_grep_args
endtry

if empty(v:errors)
  quit
endif

for error in v:errors
  echomsg error
endfor
cquit
