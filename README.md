# [Show](show) shows files/images/directories and adds deep integration with `rg` and `fzf`

See show in action:

- [show with fzf](demos/2025-12-14-show.mp4)
- [show's "show search"](demos/2025-12-14-search.mp4)

## The `main` command

```
Renders a file from a directory or directly a file.
It is able to render images and highlights text with bat in your terminal.

Also it works as preview command for fzf with --preview "show {}"

If the argument is a directory it searches for known files (you can
customize that with env vars or parameters).

If path is a file (or a file has been found):

- Image: try to render or Sixl it.

  Rendering is only supported for kitty and ghosty,
  other terminals will Sixl the image.

- Binary: just show the path

- everything else: use bat or cat to render it.

For list of environment vars please take a look at the first lines of
the script.

Usage:
  > show {flags} <path> 

Subcommands:
  show search (custom) - Search with rg <> fzf | open.

Flags:
  -h, --help: Display the help message for this command
  -f, --no-find: Disable globing for directories, usefull if you just wanna list files.
  --patterns <list<oneof<string, glob>>>: Find patterns for directories, (ENV: SHOW_FIND_PATTERNS)
  --excludes <list<string>>: Find excludes for directories (ENV: SHOW_FIND_EXCLUDES)
  -j, --jump-to-line <string>: Jump to line x (default: '0')
  -d, --debug: Enable debug logging

Parameters:
  path <path>: Input either a single directory or file.
```

## Installation

```nushell
http get --raw https://git.sr.ht/~jochumdev/show/blob/main/show | save --raw ~/.local/bin/show
^chmod +x ~/.local/bin/show
```

To install various syntax's in bat (this is from the man page of bat):

```nushell
mkdir -p (^bat --config-dir)/syntaxes
cd (^bat --config-dir)/syntaxes

# Put new '.sublime-syntax' language definition files
# in this folder (or its subdirectories), for example:
^git clone https://github.com/tellnobody1/sublime-purescript-syntax

# And then build the cache.
^bat cache --build
```

To install a [nushell syntax](https://github.com/kurokirasama/nushell_sublime_syntax) for bat:

```nushell
http get --raw https://raw.githubusercontent.com/kurokirasama/nushell_sublime_syntax/refs/heads/main/nushell.sublime-syntax | save --raw -f f"(^bat --config-dir)/syntaxes/nushell.sublime-syntax"
^bat cache --build
```

You can use it as preview command for fzf

```nushell
$env.FZF_DEFAULT_OPTS = '--preview="show --jump-to-line {2} {1}"'
$env.FZF_CTRL_T_OPTS = '--preview="show --jump-to-line {2} {1}"'
```

I'm using <https://github.com/junegunn/fzf/pull/4630> for FZF completions on various stuff.

### Dependencies

- The nu shell (show works without nu being your active shell).

- For images (all optional):
  - if running in kitty or ghosty: `kitten` + `sed`
  - else: `imgcat`
  - else: `chafa`
- text (all optional):
  - `bat`
  - `sed`
  - `cat`

All dependency resolving falls back to `ls`.

## `show search`

```
Search with rg <> fzf | open.

Examples:

Just walk files with rg, let fzf do the fuzzy search work:

   show search -g '**/*.nu'

The above with a different working directory:

   show search -d ~/vendor/nushell/nu_scripts -g '**/*.nu'

Search for "run-external" in all .nu files:

   show search -g '**/*.nu' 'run-external'

Search for .nu files multi-line:

   show search -g '**/*.nu' -m '# Update.*\n.*def --env'

Used fixed strings (search for regex patterns for example):

   show search -F 'hello.*'

Enable auto-reload (fzf will execute rg on each change in the prompt):

   show search -F -a initial

Tip: When it is not working right enable "--debug" after you close the fzf tui
you will see the output.

Usage:
  > show search {flags} (query) 

Flags:
  -h, --help: Display the help message for this command
  -d, --working-directory <path>: Directory to search and open in (default: '')
  -o, --opener <string>: Editor/opener to use (default: $env.SHOW_SEARCH_OPENER then "nvim")
  -d, --debug: Enable debug logging
  -a, --auto-reload: Run ripgrep on each query change
  -F, --fixed-strings: Use fixed strings with ripgrep
  -g, --glob <string>: Glob file names with ripgrep (default: '')
  -m, --multi-line: Enable ripgreps multi-line search

Parameters:
  query <string>:  (optional, default: '')
```

### Dependencies

- All dependencies of `show`
- `rg`
- `fzf`

### Installation

You can have an alias for it:

```nushell
alias search = show search
```

## History

Originally I ported
[fzf-preview.sh](https://github.com/junegunn/fzf/blob/33d8d51c8a6c6e9321b5295b3a63f548b5f18a1f/bin/fzf-preview.sh)
to [show.sh](show.sh), after recently discovering the wonderful nushell I did
another port to it.

After a while I found a way too deep integrate show with `rg` and `fzf`, the result is `show search`.

`show search` is based on work from junegunn: <https://junegunn.github.io/fzf/tips/ripgrep-integration/#wrap-up>

## Author

- René Jochum
- This is based on work from [@junegunn](https://github.com/junegunn/) the Author of fzf.

## License

MIT OR Apache-2.0
