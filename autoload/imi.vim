function! s:error(message) abort
  echohl ErrorMsg
  echomsg 'Imi: ' . a:message
  echohl None
endfunction

function! s:fzf_available(require_vim_integration) abort
  if !executable('fzf')
    call s:error('fzf executable not found. Install fzf to use Imi.')
    return 0
  endif

  if !exists('*fzf#run') && empty(globpath(&runtimepath, 'autoload/fzf.vim'))
    call s:error('fzf core Vim plugin not found. Add fzf''s Vim runtime (which provides fzf#run) to runtimepath.')
    return 0
  endif

  if a:require_vim_integration
        \ && !exists('*fzf#vim#grep')
        \ && empty(globpath(&runtimepath, 'autoload/fzf/vim.vim'))
    call s:error('fzf.vim integration not found. Install the complete fzf.vim plugin.')
    return 0
  endif

  return 1
endfunction

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
  if !s:fzf_available(0)
    return
  endif

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
  elseif executable('find')
    call fzf#run({
          \ 'source': 'find ' . shellescape(cwd) . ' -type f ! -path ' . shellescape('*/.git/*'),
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  else
    call s:error('no file search backend found. Install fd, locate, ripgrep, or find.')
  endif
endfunction

function! imi#files_home() abort
  if !s:fzf_available(0)
    return
  endif

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
  elseif executable('find')
    call fzf#run({
          \ 'source': 'find ' . shellescape(home) . ' -type f ! -path ' . shellescape('*/.git/*'),
          \ 'sink': 'e',
          \ 'options': '--multi --preview "' . imi#preview_cmd() . '"'
          \ })
  else
    call s:error('no file search backend found. Install fd, locate, ripgrep, or find.')
  endif
endfunction

function! imi#grep(query) abort
  if !executable('rg')
    call s:error('ripgrep (rg) is required for :ImiGrep.')
    return
  endif

  if !s:fzf_available(1)
    return
  endif

  call fzf#vim#grep(
        \ 'rg --column --line-number --no-heading --color=always --smart-case --hidden --glob "!.git/*" ' . shellescape(a:query),
        \ 1,
        \ fzf#vim#with_preview({
        \   'dir': imi#git_root(),
        \   'options': ['--preview', imi#grep_preview_cmd()]
        \ }),
        \ 0)
endfunction
