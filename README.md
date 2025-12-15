# show — a terminal viewer and search wrapper

**show** is a [Nushell](https://www.nushell.sh/) script that wraps several excellent tools-

- [bat](https://github.com/sharkdp/bat)
- [kitten icat](https://sw.kovidgoyal.net/kitty/kittens/icat/)
- [chafa](https://github.com/hpjansson/chafa/)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fzf](https://github.com/junegunn/fzf)

-to make working with text, images, and search results in the terminal more pleasant and powerful.

It can:

- Render **text and images** directly in your terminal
- Act as a **drop-in preview command for fzf**
- Combine **ripgrep + fzf + show** into a fast interactive search UI

---

## Terminal support

`show` is well tested with:

- **kitty**
- **alacritty**
- **ghostty**

Nushell does **not** need to be your active shell for `show` to work — though I highly recommend trying it.

---

## Demos

- [show as a fzf previewer](demos/2025-12-14-show.mp4)
- [show search in action](demos/2025-12-14-search.mp4)

---

## Installation

### Install `show`

Using Nushell:

```nushell
http get --raw https://git.sr.ht/~jochumdev/show/blob/main/show | save --raw ~/.local/bin/show
^chmod +x ~/.local/bin/show
````

Ensure `~/.local/bin` is in your `$PATH`.

---

### (Optional) Add extra syntax highlighting for `bat`

From the `bat` man page:

```nushell
mkdir -p (^bat --config-dir)/syntaxes
cd (^bat --config-dir)/syntaxes

# Add new .sublime-syntax files, for example:
^git clone https://github.com/tellnobody1/sublime-purescript-syntax

# Rebuild bat's cache
^bat cache --build
```

#### Nushell syntax for `bat`

```nushell
http get --raw https://raw.githubusercontent.com/kurokirasama/nushell_sublime_syntax/refs/heads/main/nushell.sublime-syntax \
  | save --raw -f f"(^bat --config-dir)/syntaxes/nushell.sublime-syntax"

^bat cache --build
```

---

## Using `show` with fzf

You can configure `show` as the preview command for fzf:

```nushell
$env.FZF_DEFAULT_OPTS = '--preview="show --jump-to-line {2} {1}"'
$env.FZF_CTRL_T_OPTS = '--preview="show --jump-to-line {2} {1}"'
```

I’m also using this fzf PR for better completions:
[https://github.com/junegunn/fzf/pull/4630](https://github.com/junegunn/fzf/pull/4630)

---

## `show` — terminal viewer for text and images

```
Renders files or directories in the terminal.

- Text files are highlighted using bat (or cat as fallback)
- Images are rendered inline when supported
- Binary files are shown as their path
- Directories are searched for "known" files
```

### Behavior

* **Directory input**

  * Searches for known files (configurable via env vars or flags)
* **File input**

  * **Images**

    * Rendered inline in kitty and ghostty
    * SIXEL used when supported
  * **Binary files**

    * Path is displayed
  * **Other files**

    * Rendered using bat or cat

For environment variables, see the first lines of the script.

### Usage

```
show {flags} <path>
```

### Subcommands

* `show search` — interactive ripgrep + fzf search with preview

### Flags

* `-h, --help` — Show help
* `-f, --no-find` — Disable directory globbing
* `--patterns <list>` — Find patterns for directories
  (env: `SHOW_FIND_PATTERNS`)
* `--excludes <list>` — Find excludes for directories
  (env: `SHOW_FIND_EXCLUDES`)
* `-j, --jump-to-line <string>` — Jump to line (default: `0`)
* `-d, --debug` — Enable debug logging

### Parameters

* `path <path>` — A file or directory to render

---

### Dependencies

* [Nushell](https://www.nushell.sh/book/installation.html)
  (does not need to be your login shell)

#### Image rendering (optional, resolved in order)

* kitty / ghostty: `kitten` + `sed`
* otherwise: `imgcat`
* fallback: `chafa`

#### Text rendering (optional)

* `bat`
* `sed`
* `cat`

If nothing is available, `ls` is used as a last resort.

---

## `show search` — ripgrep + fzf integration

```
Search with rg <> fzf | open
```

### Examples

Walk files and let fzf handle fuzzy matching:

```
show search -g '**/*.nu'
```

Search in a different directory:

```
show search -d ~/vendor/nushell/nu_scripts -g '**/*.nu'
```

Search for a string in all `.nu` files:

```
show search -g '**/*.nu' 'run-external'
```

Multi-line search:

```
show search -g '**/*.nu' -m '# Update.*\n.*def --env'
```

Use fixed strings (useful for regex-like text):

```
show search -F 'hello.*'
```

Enable auto-reload (rg runs on each query change):

```
show search -F -a initial
```

**Tip**: If something behaves unexpectedly, re-run with `--debug` and close fzf to inspect the output.

---

### Usage

```
show search {flags} (query)
```

### Flags

* `-h, --help` — Show help
* `-d, --working-directory <path>` — Directory to search in
* `-o, --opener <string>` — Editor/opener
  (default: `$env.SHOW_SEARCH_OPENER`, then `nvim`)
* `-d, --debug` — Enable debug logging
* `-a, --auto-reload` — Re-run rg on every query change
* `-F, --fixed-strings` — Use fixed strings with ripgrep
* `-g, --glob <string>` — File glob
* `-m, --multi-line` — Enable multi-line search

### Parameters

* `query <string>` — Initial search query (optional)

---

### Dependencies

* All dependencies of `show`
* `rg`
* `fzf`

---

### Convenience alias

```nushell
alias search = show search
```

---

## `show update`

Updates `show` from the latest `main` branch.

---

## History

`show` started as a port of
[fzf-preview.sh](https://github.com/junegunn/fzf/blob/33d8d51c8a6c6e9321b5295b3a63f548b5f18a1f/bin/fzf-preview.sh)
to [show.sh](show.sh).

After discovering Nushell, I rewrote it in Nu and later deeply integrated
`rg` and `fzf`, resulting in `show search`.

`show search` is inspired by:
[https://junegunn.github.io/fzf/tips/ripgrep-integration/#wrap-up](https://junegunn.github.io/fzf/tips/ripgrep-integration/#wrap-up)

---

## Author

* René Jochum
* Based on work by [@junegunn](https://github.com/junegunn), author of fzf
* This README has been optimized by ChatGPT, all code is hand written.
---

## License

MIT OR Apache-2.0
