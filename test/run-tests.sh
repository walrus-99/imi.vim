#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
vim_bin=${VIM_BIN:-vim}
status=0

for test_file in "$repo_root"/test/*.vim; do
  printf 'Running %s\n' "${test_file#"$repo_root"/}"
  if ! "$vim_bin" -Nu NONE -i NONE -n -es -S "$test_file"; then
    printf 'Failed %s\n' "${test_file#"$repo_root"/}" >&2
    "$vim_bin" -Nu NONE -i NONE -n -es -V1 -S "$test_file" || true
    status=1
  fi
done

exit "$status"
