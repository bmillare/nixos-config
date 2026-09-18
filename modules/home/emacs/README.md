# Shared Emacs configuration

`../emacs.nix` is imported by `common-development.nix`, so crayfish,
dykestraw, blacksheep, and macbook share the same portable settings. There
are no Mac-specific settings. Hosts can override `programs.emacs.package`
if they need a different Emacs build.

Nix supplies Emacs and its packages; `init.el` holds the editable source of
the configuration. Home Manager installs it as `~/.emacs`, with an early
init that disables package.el startup activation. Package versions follow
the repository's `flake.lock`; no MELPA downloads are needed at startup.

## First activation

Back up and move an existing `~/.emacs` and `~/.emacs.d/early-init.el` before
activating Home Manager (or use Home Manager's backup option). These files
are not force-overwritten. An older `~/.emacs.d/init.el` or XDG init is
superseded by `~/.emacs`; it is not loaded or deleted. The original
`/home/bmillare/projects/emacs/dotemacs` is not modified.

Use `~/.emacs.d/local.el` for optional personal code. `custom.el` in that
directory receives Customize changes and loads before `local.el`. Both
are outside Nix and can override the shared defaults. Review an existing
`custom.el` if old settings unexpectedly return. Do not load the entire old
dotemacs from `local.el`, since that would re-enable Helm and its old setup.

## Navigation

| Key | Action |
| --- | --- |
| `C-x C-f` | Find file, with Vertico completion |
| `M-x` | Commands, with Vertico and Marginalia annotations |
| `C-x b` | Consult buffers and recent files |
| `C-x C-r` | Recent files (replaces find-file-read-only) |
| `C-x p f` | Find a file in the current project |
| `C-x p p` | Switch project |
| `C-c f` | Find files recursively |
| `C-c g` | Search file contents with ripgrep |
| `C-x g` | Magit status |

In the completion menu, `TAB` inserts the selected candidate and `RET`
accepts it. `M-RET` accepts exactly what you typed, useful for a new file.
Orderless matches space-separated terms in any order; file prompts use
basic/partial completion to retain path and remote-file completion.

## Migration choices

Preserved: black/gray85/red3 appearance, syntax colors, no backups or lock
files, auto-save timeout, automatic reloading, spaces for indentation,
four-column C indentation, truncated lines, hidden menu/tool bars, right
scroll bar, column numbers, window movement keys, browser-at-point,
date insertion, symbol copying, and the Emacs server for emacsclient.
Obsolete face/variable names were updated to their current equivalents.

Kept packages: Magit, Markdown mode (with Pandoc), Nix mode, and unfill.
Added: Vertico, Orderless, Marginalia, and Consult, plus built-in project,
history, and recent-file support.

Omitted: Helm, CIDER/Clojure/Paredit setup, vterm and terminal macros,
custom process-send and temporary-file plumbing, Mac modifiers/renderer,
WSL browser detection, UUID/XML helpers, and the custom kill-buffer command.
The standard buffer-killing commands remain available. These optional
workflows can be reintroduced selectively later.
