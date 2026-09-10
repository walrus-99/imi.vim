function! imi#preview_cmd() abort
  if executable('bat')
    return 'bat --style=numbers --color=always --line-range :500 {}'
  endif
  return 'cat {}'
endfunction

function! imi#grep_preview_cmd() abort
  if executable('bat')
    return 'bat --style=numbers --color=always --highlight-line {2} --line-range {2}: {1}'
  endif
  return 'cat {1}'
endfunction

function! imi#git_root() abort
  let root = systemlist('git rev-parse --show-toplevel')
  return v:shell_error == 0 && len(root) ? root[0] : getcwd()
endfunction

function! imi#is_git_work_tree() abort
  if !executable('git')
    return 0
  endif

  let result = systemlist('git rev-parse --is-inside-work-tree')
  return v:shell_error == 0 && get(result, 0, '') ==# 'true'
endfunction

function! imi#files_smart() abort
  let cwd = getcwd()

  if imi#is_git_work_tree()
    call fzf#run({
          \ 'source': 'git ls-files',
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  elseif executable('fd')
    call fzf#run({
          \ 'source': 'fd . ' . shellescape(cwd) . ' --type f --hidden --follow --exclude .git',
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  elseif executable('locate')
    call fzf#run({
          \ 'source': printf("sh -c 'locate %s | grep -F %s | grep -v \"/.git/\"'",
          \             shellescape(cwd), shellescape(cwd . '/')),
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  elseif executable('rg')
    call fzf#run({
          \ 'source': 'rg --files --hidden --follow --glob "!.git/*" ' . shellescape(cwd),
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  else
    echo 'No suitable file search tool found: fd, locate, or rg'
  endif
endfunction

function! imi#files_home() abort
  let home = expand('$HOME')

  if executable('fd')
    call fzf#run({
          \ 'source': 'fd . ' . shellescape(home) . ' --type f --hidden --follow --exclude .git',
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  elseif executable('locate')
    call fzf#run({
          \ 'source': printf("sh -c 'locate %s | grep -F %s | grep -v \"/.git/\"'",
          \             shellescape(home), shellescape(home . '/')),
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  elseif executable('rg')
    call fzf#run({
          \ 'source': 'rg --files --hidden --follow --glob "!.git/*" ' . shellescape(home),
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  else
    echo 'No suitable file search tool found: fd, locate, or rg'
  endif
endfunction

function! imi#grep(query) abort
  call fzf#vim#grep(
        \ 'rg --column --line-number --no-heading --color=always --smart-case --hidden --glob "!.git/*" ' . shellescape(a:query),
        \ 1,
        \ fzf#vim#with_preview({
        \   'dir': imi#git_root(),
        \   'options': ['--preview', imi#grep_preview_cmd()]
        \ }),
        \ 0)
endfunction
