# imi.vim

Imi is a project-aware navigation plugin for Vim. User documentation will be expanded as the plugin develops; see [vision.md](vision.md) for its goals.

## Development

The test suite requires Vim with assertion support, Git, and a POSIX shell. Other external search tools and fzf integrations are stubbed by the tests.

Run all tests from the repository root:

```sh
test/run-tests.sh
```

Set `VIM_BIN` to test with another compatible Vim executable:

```sh
VIM_BIN=/path/to/vim test/run-tests.sh
```
