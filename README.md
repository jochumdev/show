# show

A pragmatic terminal file viewer and search helper.

`show` is implemented in Nushell and designed to be used from a modern shell environment.

It renders files intelligently in your terminal and acts as a reliable
preview command for `fzf`. It selects the best available renderer based on
mime detection, terminal capabilities, and installed tools — with safe fallbacks.

This is not a pager replacement and not a file manager.  
It is glue that makes existing CLI tools work together predictably.


[![asciicast](https://asciinema.org/a/762163.svg)](https://asciinema.org/a/762163)

---

## How it works

`show` uses a simple renderer pipeline:

```

File
↓
MIME detection
↓
renderer list
↓
first compatible renderer
↓
output

```

For each file:

1. The MIME type is detected (using `file` if available)
2. Matching renderer groups are looked up
3. Renderers are tried in order
4. The first renderer that:
   - is available
   - supports the current terminal
   - has all required commands installed  
   is used

If no renderer matches, `show` falls back safely.
This usually means printing the filepath or listing directory contents,
depending on the input type.

### Example

A `text/plain` file may be rendered by:

- `bat`
- `sed`
- `cat`

If `bat` is installed, it is used.  
If not, `sed` is tried.  
If that fails, `cat` is used.

---

### fzf integration (POSIX shells)


For `/bin/sh`, `bash`, `zsh`:

```sh
export FZF_DEFAULT_OPTS='--preview="show --glob --jump-to-line '\'' {2} '\'' {1}" --delimiter=":"'
```

Same with nu

```nu
$env.FZF_DEFAULT_OPTS = r#'--preview="show --glob --jump-to-line ' {2} ' {1}" --delimiter=":"'#
```

The spaces around `{2}` are intentional.
They avoid a known fzf issue where empty fields are replaced with nothing,
which can break argument boundaries.

## Usage

Preview a file:

```sh
show file.txt
```

Preview a directory (searches for common files like `README`, configurable):

```sh
show -g .
```

Use as an `fzf` preview command:

```sh
fzf --preview 'show {}'
```

Jump to a specific line (used automatically by `show search`):

```sh
show -j 120 file.txt
```

Enable debug logging:

```sh
show --debug file.txt
```

---

## Search

`show search` combines `ripgrep` and `fzf` and reuses the same preview logic.

```sh
show search -F 'open --raw'
```

Search only certain files:

```sh
show search -g '**/*.nu'
```

Search in another directory without having to cd to it:

```sh
show search -d ~/projects/show/testbed 'success'
```

Enable auto-reload (rerun ripgrep on each query change):

```sh
show search -g '**/*.nu' -a
```

Previews shown during search are rendered exactly like `show file`, including
syntax highlighting and image support.

Selecting files in fzf results in an opened Editor at the given line if your Editor supports that.

---

## Configuration

Configuration is optional.

By default, `show` works out of the box.
It can be customized via:

```
$XDG_CONFIG_HOME/show/config.toml
```

You can configure:

* Which files are searched when previewing directories
* MIME type → renderer mappings
* terminal-specific renderer restrictions
* editor integration for `show search`

The configuration is merged on top of sane defaults.

See `config.toml` and `config.example.toml` in the repository for all available options.

---

## Image rendering

Image previews are supported when the terminal allows it.

Supported renderers (used if available):

* `kitten icat` (kitty, ghostty)
* `imgcat` (iTerm2)
* `chafa` (sixel / ASCII fallback)

If image rendering is not supported, `show` falls back to print the path.

---

## Dependencies

Required:

* Nushell

Optional (used if available):

* bat
* ripgrep
* fzf
* chafa
* kitty (`kitten icat`)
* imgcat
* sed
* less

Missing tools are handled gracefully.

---

## Credits

This is based on [fzf-preview.sh](https://github.com/junegunn/fzf/blob/33d8d51c8a6c6e9321b5295b3a63f548b5f18a1f/bin/fzf-preview.sh) as well as a [blog post](https://junegunn.github.io/fzf/tips/ripgrep-integration/) by junegunn the author of fzf.

## License

MIT OR Apache-2.0
