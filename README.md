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
- **alacrity**
- **ghostty**

Nushell does **not** need to be your active shell for `show` to work — though I highly recommend trying it.

---

## Demos

[![2025-12-15-show-search](https://asciinema.org/a/762163.svg)](https://asciinema.org/a/762163)

[2025-12-15-show-as-fzf-preview.webm](https://github.com/user-attachments/assets/5bc0018d-03d8-4532-9281-0ec335381ee2)

---

## Installation

### Install `show`

Using Nushell:

```nu
http get --raw https://git.sr.ht/~jochumdev/show/blob/main/show | save --raw ~/.local/bin/show
chmod +x ~/.local/bin/show
````

Ensure `~/.local/bin` is in your `$PATH`.

---

### (Optional) Add extra syntax highlighting for `bat`

From the `bat` man page:

```nu
mkdir -p (bat --config-dir)/syntaxes
cd (bat --config-dir)/syntaxes

# Add new .sublime-syntax files, for example:
git clone https://github.com/tellnobody1/sublime-purescript-syntax

# Rebuild bat's cache
bat cache --build
```

#### Nushell syntax for `bat`

```nu
http get --raw https://raw.githubusercontent.com/kurokirasama/nushell_sublime_syntax/refs/heads/main/nushell.sublime-syntax \
  | save --raw -f f"(bat --config-dir)/syntaxes/nushell.sublime-syntax"

bat cache --build
```

---

## Using `show` with fzf

You can configure `show` as the preview command for fzf:

```nu
$env.FZF_DEFAULT_OPTS = r#'--preview="show -j ' {2} ' {1}" --delimiter=":"'#
$env.FZF_CTRL_T_OPTS = r#'--preview="show -j ' {2} ' {1}"'#
```

I’m also using this fzf PR for better completions:
[https://github.com/junegunn/fzf/pull/4630](https://github.com/junegunn/fzf/pull/4630)

---

## `show` — terminal viewer for text and images

Renders files or directories in the terminal.

- Text files are highlighted using bat (or cat as fallback)
- Images are rendered inline when supported
- Binary files are shown as their path
- Directories are searched for "known" files

### Behavior

* **Directory input**

  * with `--glob`
    Searches for known files (configurable via env vars or flags)

  * else
    Runs ls on the directory

* **File input**

  * **Images**

    * Rendered inline in kitty and ghostty
    * SIXEL used when supported
  * **Binary files**

    * Path is displayed
  * **Other files**

    * Rendered using bat or cat

### Configuration

show is highly configurable, it allows you to route different mime types to different "renderers".

You can group mime types by `mimegroups`, the order matters, first-in-first-out applies here.

The config can be loaded from either:

- `$env.XDG_CONFIG_HOME/show/config.toml`
- `$env.XDG_CONFIG_HOME/show/config.json`

Your config will be merged with the default config when it exists
using `merge deep --strategy=prepend` means your mimegroups come first.

For now you can't add additional renderers without changing show itself.

This is the default config:

```toml
[[mimegroups]]
# Render this mimes with the renderers below.
mimes = [
    "application/x-nuscript",
    "application/x-nuon",
    "text/x-nushell",
    "application/json",
]
renderers = [
    "nu-highlight",
    "bat",
    "cat",
]

[[mimegroups]]
mimes = [
    "application",
    "text",
]
renderers = [
    "bat",
    "sed",
    "cat",
]

[[mimegroups]]
mimes = ["image"]
renderers = [
    "kitten_icat",
    "imgcat",
    "chafa",
    "sed",
]

[commands.main]
# Glob patterns for directories.
patterns = [
    "(?i)readme*",
    "(?i)*.md",
    "(?i)*.rst",
    "(?i)*.toml",
]
# Exclude this patterns when globbing for the above files.
excludes = [
    "**/target/**",
    "**/.git/**",
]

[commands.search]
# Open found files with
opener = "nvim"

# Openers which suppport the "<file>:<line>" syntax
line_openers = ["helix"]

[renderers.kitten_icat]
# Terminals taht work with `kitten icat`
terms = [
    "kitty",
    "ghostty",
]

[renderers.bat]
# Bat style/color used within fzf.
fzf_style = "full"
fzf_color = "always"
```

This is my config:

```toml
[[mimegroups]]
mimes = ["text/x-script.python"]
renderers = [
    "nu-highlight",
    "bat",
    "cat",
]
```

### Usage

```
show {flags} <path>
```

### Subcommands

* `show search` — interactive ripgrep + fzf search with preview

### Flags

* `-h, --help` — Show help
* `-g, --glob` — Enable globbing for directories
* `--patterns <list>` — Find patterns for directory globbing
  (env: `SHOW_FIND_PATTERNS`)
* `--excludes <list>` — Find excludes for directory globbing
  (env: `SHOW_FIND_EXCLUDES`)
* `-j, --jump-to-line <string>` — Jump to line (default: `0`)
* `-d, --debug` — Enable debug logging

### Parameters

* `path <path>` — A file or directory to render

---

# Dependencies

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

Search with rg <> fzf then open the found files in your editor.

### Examples

Walk files and let fzf handle fuzzy matching:

```nu
show search -g '**/*.nu'
```

Search in a different directory:

```nu
show search -d ~/vendor/nushell/nu_scripts -g '**/*.nu'
```

Search for a string in all `.nu` files:

```nu
show search -g '**/*.nu' 'run-external'
```

Multi-line search:

```
show search -g '**/*.nu' -m '# Update.*\n.*def --env'
```

Use fixed strings (useful for regex-like text):

```nu
show search -F 'hello.*'
```

Enable auto-reload (rg runs on each query change):

```nu
show search -F -a initial
```

**Tip**: If something behaves unexpectedly, re-run with `--debug` and close fzf to inspect the output.

---

### Usage

```nu
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

```nu
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
