set nomore

let s:repo_root = fnamemodify(expand('<sfile>'), ':p:h:h')
execute 'set runtimepath^=' . fnameescape(s:repo_root)
execute 'set runtimepath^=' . fnameescape(s:repo_root . '/test/fixtures')

function! s:add_executable(directory, name, lines) abort
  let path = a:directory . '/' . a:name
  call writefile(['#!/bin/sh'] + a:lines, path)
  call setfperm(path, 'rwxr-xr-x')
endfunction

function! s:select_backend(bin_dir) abort
  let $PATH = a:bin_dir
  unlet! g:imi_test_fzf_spec
  call imi#files_smart()
  return get(g:, 'imi_test_fzf_spec', {})
endfunction

function! s:assert_preview(spec, context) abort
  call assert_equal('--multi --preview "cat {}"', get(a:spec, 'options', ''),
        \ a:context . ' must pass the fallback preview to fzf')
endfunction

let s:original_cwd = getcwd()
let s:original_home = $HOME
let s:original_path = $PATH
let s:work_dir = tempname() . " space'quote"
call mkdir(s:work_dir, 'p')

try
  execute 'lcd ' . fnameescape(s:work_dir)
  let $HOME = s:work_dir

  let s:git_bin = s:work_dir . '/git-bin'
  call mkdir(s:git_bin)
  call s:add_executable(s:git_bin, 'git', ['echo true'])
  call s:add_executable(s:git_bin, 'fzf', ['exit 0'])
  let s:spec = s:select_backend(s:git_bin)
  call assert_equal('git ls-files', get(s:spec, 'source', ''), 'Git must be the preferred backend')
  call s:assert_preview(s:spec, 'Git search')

  let s:fd_bin = s:work_dir . '/fd-bin'
  call mkdir(s:fd_bin)
  call s:add_executable(s:fd_bin, 'fd', ['exit 0'])
  call s:add_executable(s:fd_bin, 'fzf', ['exit 0'])
  let s:spec = s:select_backend(s:fd_bin)
  call assert_equal('fd . ' . shellescape(s:work_dir) . ' --type f --hidden --follow --exclude .git',
        \ get(s:spec, 'source', ''), 'fd must receive a shell-escaped working directory')
  call s:assert_preview(s:spec, 'fd search')
  unlet! g:imi_test_fzf_spec
  call imi#files_home()
  call assert_equal('fd . ' . shellescape(s:work_dir) . ' --type f --hidden --follow --exclude .git',
        \ get(g:imi_test_fzf_spec, 'source', ''), 'Home search must select fd')
  call s:assert_preview(g:imi_test_fzf_spec, 'fd home search')

  let s:locate_bin = s:work_dir . '/locate-bin'
  call mkdir(s:locate_bin)
  call s:add_executable(s:locate_bin, 'locate', ['exit 0'])
  call s:add_executable(s:locate_bin, 'fzf', ['exit 0'])
  let s:spec = s:select_backend(s:locate_bin)
  let s:locate_source = printf("sh -c 'locate %s | grep -F %s | grep -v \"/.git/\"'",
        \ shellescape(s:work_dir), shellescape(s:work_dir . '/'))
  call assert_equal(s:locate_source, get(s:spec, 'source', ''),
        \ 'The locate backend command must remain covered pending issue #1')
  call s:assert_preview(s:spec, 'locate search')
  unlet! g:imi_test_fzf_spec
  call imi#files_home()
  call assert_equal(s:locate_source, get(g:imi_test_fzf_spec, 'source', ''),
        \ 'Home search must select locate')
  call s:assert_preview(g:imi_test_fzf_spec, 'locate home search')

  let s:rg_bin = s:work_dir . '/rg-bin'
  call mkdir(s:rg_bin)
  call s:add_executable(s:rg_bin, 'rg', ['exit 0'])
  call s:add_executable(s:rg_bin, 'fzf', ['exit 0'])
  let s:spec = s:select_backend(s:rg_bin)
  let s:rg_source = 'rg --files --hidden --follow --glob "!.git/*" ' . shellescape(s:work_dir)
  call assert_equal(s:rg_source, get(s:spec, 'source', ''),
        \ 'rg must receive a shell-escaped working directory')
  call s:assert_preview(s:spec, 'rg search')
  unlet! g:imi_test_fzf_spec
  call imi#files_home()
  call assert_equal(s:rg_source, get(g:imi_test_fzf_spec, 'source', ''),
        \ 'Home search must select rg')
  call s:assert_preview(g:imi_test_fzf_spec, 'rg home search')

  let s:find_bin = s:work_dir . '/find-bin'
  call mkdir(s:find_bin)
  call s:add_executable(s:find_bin, 'find', ['exit 0'])
  call s:add_executable(s:find_bin, 'fzf', ['exit 0'])
  let s:spec = s:select_backend(s:find_bin)
  let s:find_source = 'find ' . shellescape(s:work_dir) . ' -type f ! -path ' . shellescape('*/.git/*')
  call assert_equal(s:find_source, get(s:spec, 'source', ''),
        \ 'find must be the final portable fallback')
  call s:assert_preview(s:spec, 'find search')
  unlet! g:imi_test_fzf_spec
  call imi#files_home()
  call assert_equal(s:find_source, get(g:imi_test_fzf_spec, 'source', ''),
        \ 'Home search must fall back to find')
  call s:assert_preview(g:imi_test_fzf_spec, 'find home search')

  let s:priority_bin = s:work_dir . '/priority-bin'
  call mkdir(s:priority_bin)
  call s:add_executable(s:priority_bin, 'git', ['exit 128'])
  for s:tool in ['fzf', 'fd', 'locate', 'rg', 'find']
    call s:add_executable(s:priority_bin, s:tool, ['exit 0'])
  endfor
  let s:spec = s:select_backend(s:priority_bin)
  call assert_match('^fd ', get(s:spec, 'source', ''), 'fd must win when all fallback backends exist')
  unlet! g:imi_test_fzf_spec
  call imi#files_home()
  call assert_match('^fd ', get(g:imi_test_fzf_spec, 'source', ''),
        \ 'Home search must prefer fd when all backends exist')

  call delete(s:priority_bin . '/fd')
  let s:spec = s:select_backend(s:priority_bin)
  call assert_match("^sh -c 'locate ", get(s:spec, 'source', ''),
        \ 'locate must be preferred over rg and find')

  call delete(s:priority_bin . '/locate')
  let s:spec = s:select_backend(s:priority_bin)
  call assert_match('^rg --files ', get(s:spec, 'source', ''), 'rg must be preferred over find')

  call delete(s:priority_bin . '/rg')
  let s:spec = s:select_backend(s:priority_bin)
  call assert_match('^find ', get(s:spec, 'source', ''), 'find must remain the final fallback')

  let s:empty_bin = s:work_dir . '/empty-bin'
  call mkdir(s:empty_bin)
  call s:add_executable(s:empty_bin, 'fzf', ['exit 0'])
  let $PATH = s:empty_bin
  unlet! g:imi_test_fzf_spec
  redir => s:message
  call imi#files_smart()
  redir END
  call assert_false(exists('g:imi_test_fzf_spec'), 'No backend must not invoke fzf')
  call assert_match('no file search backend found', s:message,
        \ 'No backend must produce an actionable message')
  redir => s:home_message
  call imi#files_home()
  redir END
  call assert_false(exists('g:imi_test_fzf_spec'), 'No home backend must not invoke fzf')
  call assert_match('no file search backend found', s:home_message,
        \ 'No home backend must produce an actionable message')
finally
  let $PATH = s:original_path
  let $HOME = s:original_home
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
