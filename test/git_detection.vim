set nomore

let s:repo_root = fnamemodify(expand('<sfile>'), ':p:h:h')
execute 'set runtimepath^=' . fnameescape(s:repo_root)
execute 'set runtimepath^=' . fnameescape(s:repo_root . '/test/fixtures')

let s:original_cwd = getcwd()
let s:original_path = $PATH
let s:work_dir = tempname()
call mkdir(s:work_dir, 'p')

try
  execute 'lcd ' . fnameescape(s:work_dir)
  call assert_false(imi#is_git_work_tree(), 'A plain directory must not be detected as a Git work tree')

  call system('git init --quiet')
  call assert_equal(0, v:shell_error, 'The test Git repository could not be initialized')
  call assert_true(imi#is_git_work_tree(), 'A Git work tree must be detected')

  call writefile(['tracked'], 'tracked.txt')
  call system('git add -- tracked.txt')
  call assert_equal(0, v:shell_error, 'The test file could not be added to the Git index')

  unlet! g:imi_test_fzf_spec
  call imi#files_smart()
  call assert_true(exists('g:imi_test_fzf_spec'), 'Smart file search must invoke fzf')
  if exists('g:imi_test_fzf_spec')
    call assert_equal('git ls-files', g:imi_test_fzf_spec.source,
          \ 'Smart file search must prefer git ls-files in a Git work tree')
  endif

  let s:bin_dir = s:work_dir . '/bin'
  call mkdir(s:bin_dir)
  call writefile(['#!/bin/sh', 'exit 128'], s:bin_dir . '/git')
  call writefile(['#!/bin/sh', 'exit 0'], s:bin_dir . '/fd')
  call setfperm(s:bin_dir . '/git', 'rwxr-xr-x')
  call setfperm(s:bin_dir . '/fd', 'rwxr-xr-x')
  let $PATH = s:bin_dir

  unlet! g:imi_test_fzf_spec
  call imi#files_smart()
  call assert_match('^fd ', g:imi_test_fzf_spec.source,
        \ 'Smart file search must fall back when Git detection fails')

  call delete(s:bin_dir . '/git')
  call assert_false(imi#is_git_work_tree(), 'A missing Git executable must not report a work tree')
  unlet! g:imi_test_fzf_spec
  call imi#files_smart()
  call assert_match('^fd ', g:imi_test_fzf_spec.source,
        \ 'Smart file search must fall back when Git is unavailable')
finally
  let $PATH = s:original_path
  execute 'lcd ' . fnameescape(s:original_cwd)
  call delete(s:work_dir, 'rf')
  unlet! g:imi_test_fzf_spec
endtry

if empty(v:errors)
  quit
endif

for error in v:errors
  echomsg error
endfor
cquit
