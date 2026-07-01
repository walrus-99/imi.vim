# Vision

## Overview

**imi.vim** is a navigation plugin for Vim.

While it provides powerful file and text search, its real purpose is to minimize the time and effort required to move through a project. Searching is only one aspect of navigation. The plugin should make it effortless to find the file, symbol, buffer, or line the user is looking for with as few keystrokes as possible.

The user should spend their time thinking about **what** they want, not **how** to find it.

---

## Philosophy

A user should never have to ask themselves:

* Should I use `git ls-files`?
* Should I use `fd`?
* Should I use `locate`?
* Should I use `find`?
* Should I use `ripgrep`?

They should simply invoke **Imi**, describe what they are looking for, and let the plugin determine the best way to satisfy the request.

The plugin should prefer intelligent defaults over excessive configuration while still remaining highly customizable.

---

## Core Principles

### Intelligent

Imi should automatically choose the best backend available.

Examples include:

* Git
* fd
* ripgrep
* locate / plocate
* find
* Platform-specific search tools

Users should not need to know which backend is being used.

---

### Fast

Navigation should feel instantaneous.

Whenever possible:

* Search only where necessary.
* Use indexed searches when available.
* Avoid unnecessary filesystem traversal.
* Prefer project-local searches over global searches.

---

### Project Aware

Projects are more than Git repositories.

Imi should recognize common project roots such as:

* `.git`
* `go.mod`
* `Cargo.toml`
* `pyproject.toml`
* `package.json`
* `Makefile`
* Additional configurable markers

Searching should automatically use the appropriate project root.

---

### Preview Everything

Every search result should provide useful context before opening.

Examples include:

* File previews
* Syntax highlighting
* Matching line previews
* Symbol context
* Configurable preview commands

---

### Simple Commands

The interface should remain small and memorable.

Examples:

* `:Imi`
* `:ImiHome`
* `:ImiGrep`

Users should not need to memorize dozens of commands.

---

## Long-Term Vision

Over time, Imi should evolve from a collection of search commands into a unified navigation system.

Rather than choosing between:

* file search
* grep
* buffers
* tags
* marks
* recent files

the user should simply ask Imi to find what they need.

Eventually, a command such as:

```
:Imi docker
```

could intelligently determine whether the user intended:

* a file named "docker"
* a `Dockerfile`
* a matching symbol
* matching text
* a recently opened file

The plugin should make the correct choice whenever possible while still allowing users to override its behavior.

---

## Extensible Architecture

Imi should be built as a collection of independent search backends rather than a single monolithic implementation.

Examples include:

* Git backend
* fd backend
* ripgrep backend
* locate backend
* find backend

Each backend should expose a consistent interface so new search providers can be added without changing the rest of the system.

Likewise, the plugin should expose a stable API that other Vim plugins can use for navigation.

---

## Non-Goals

Imi is not intended to replace:

* Language Server Protocol (LSP)
* Tree-sitter
* Git integration
* Vim's built-in editing capabilities

Instead, it should complement these tools by providing a fast, intuitive way to navigate projects regardless of language or tooling.

---

## Guiding Principle

Every feature should answer one question:

> **Does this help the user get where they want to go with fewer keystrokes and less thinking?**

If the answer is yes, it belongs in Imi.

