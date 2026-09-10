set nomore

let s:repo_root = fnamemodify(expand('<sfile>'), ':p:h:h')
execute 'set runtimepath^=' . fnameescape(s:repo_root)
execute 'set runtimepath^=' . fnameescape(s:repo_root . '/test/fixtures')

function! s:add_executable(directory, name, lines) abort
  let path = a:directory . '/' . a:name
  call writefile(['#!/bin/sh'] + a:lines, path)
  call setfperm(path, 'rwxr-xr-x')
endfunction

let s:original_cwd = getcwd()
let s:original_path = $PATH
let s:git_path = exepath('git')
let s:work_dir = tempname() . " root space'quote"
let s:project_dir = s:work_dir . '/project'
let s:nested_dir = s:project_dir . '/nested'
let s:plain_dir = s:work_dir . '/plain'
call mkdir(s:nested_dir, 'p')
call mkdir(s:plain_dir, 'p')

try
  call system('git -C ' . shellescape(s:project_dir) . ' init --quiet')
  call assert_equal(0, v:shell_error, 'The test Git repository could not be initialized')

  let s:tools_bin = s:work_dir . '/tools-bin'
  call mkdir(s:tools_bin)
  call s:add_executable(s:tools_bin, 'git', ['exec ' . shellescape(s:git_path) . ' "$@"'])
  call s:add_executable(s:tools_bin, 'fzf', ['exit 0'])
  call s:add_executable(s:tools_bin, 'rg', ['exit 0'])
  let $PATH = s:tools_bin

  execute 'lcd ' . fnameescape(s:nested_dir)
  call assert_equal(s:project_dir, imi#git_root(), 'Git root detection must work from a nested directory')

  let s:query = "needle with spaces and 'quote"
  unlet! g:imi_test_grep_args g:imi_test_preview_spec
  call imi#grep(s:query)
  let s:expected_command = 'rg --column --line-number --no-heading --color=always --smart-case --hidden --glob "!.git/*" '
        \ . shellescape(s:query)
  call assert_equal(s:expected_command, g:imi_test_grep_args[0],
        \ 'Grep queries must be shell escaped')
  call assert_equal(1, g:imi_test_grep_args[1], 'Grep output must include columns')
  call assert_equal(s:project_dir, g:imi_test_grep_args[2].dir,
        \ 'Grep must run from the Git root')
  call assert_equal(['--preview', imi#grep_preview_cmd()], g:imi_test_grep_args[2].options,
        \ 'Grep must pass its preview command to fzf')
  call assert_equal(0, g:imi_test_grep_args[3], 'Grep must not force fullscreen fzf')

  execute 'lcd ' . fnameescape(s:plain_dir)
  call assert_equal(s:plain_dir, imi#git_root(),
        \ 'Root detection must fall back to the working directory outside Git')

  let s:empty_bin = s:work_dir . '/empty-bin'
  call mkdir(s:empty_bin)
  let $PATH = s:empty_bin
  call assert_equal('cat {}', imi#preview_cmd(), 'File previews must fall back to cat')
  call assert_equal('cat {1}', imi#grep_preview_cmd(), 'Grep previews must fall back to cat')

  let s:bat_bin = s:work_dir . '/bat-bin'
  call mkdir(s:bat_bin)
  call s:add_executable(s:bat_bin, 'bat', ['exit 0'])
  let $PATH = s:bat_bin
  call assert_equal('bat --style=numbers --color=always --line-range :500 {}', imi#preview_cmd(),
        \ 'File previews must use bat when available')
  call assert_equal('bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}',
        \ imi#grep_preview_cmd(), 'Grep previews must use bat when available')
finally
  let $PATH = s:original_path
  execute 'lcd ' . fnameescape(s:original_cwd)
  call delete(s:work_dir, 'rf')
  unlet! g:imi_test_grep_args g:imi_test_preview_spec
endtry

if empty(v:errors)
  quit
endif

for error in v:errors
  echomsg error
endfor
cquit
