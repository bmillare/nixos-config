# Shared Emacs configuration

`../emacs.nix` is imported by `common-development.nix`, so crayfish,
dykestraw, blacksheep, and macbook share the same portable settings. macOS
preserves Command as Meta with a guarded platform setting. Hosts can override
`programs.emacs.package`
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
date insertion, symbol copying, XML tag insertion, and the Emacs server for emacsclient.
Obsolete face/variable names were updated to their current equivalents.

Kept packages: Magit, Markdown mode (with Pandoc), Nix mode, and unfill.
Added: Vertico, Orderless, Marginalia, and Consult, plus built-in project,
history, and recent-file support.

Retired from startup: Helm, CIDER/nREPL setup, vterm, the custom mdr renderer,
terminal macros, custom process-send and temporary-file plumbing, WSL browser
detection, UUID insertion, the backslash helper, and the custom kill-buffer
command. Built-in terminal and buffer-killing commands remain available.

`archived.el` preserves the complete pre-migration Mac init as reference,
including the legacy helpers and their former keybindings. It is neither
installed nor loaded. Do not load it wholesale: extract individual definitions
when needed, review their dependencies, and deliberately choose new bindings.
Some helpers assume `~/clj/src`, named terminal buffers, files under `/tmp`,
or CIDER. The old backslash helper also needs its region/narrowing behavior
reviewed before reuse.

The shared configuration uses inf-clojure rather than CIDER and does not
activate the old `~/.emacs.d/elpa` tree. Existing ELPA files are retained.
The Mac keeps its native Emacs build; Dykestraw keeps PGTK for Wayland.
Command maps to Meta on macOS when the build exposes a corresponding modifier
variable; Option is left at its default. No desktop-wide key remapping is
introduced. `custom.el` and `local.el` remain opt-in local overrides.

## Clojure over a plain REPL

Nix installs `clojure-mode`, `inf-clojure`, and the Clojure CLI with its
Java runtime. `inf-clojure-minor-mode` is enabled in Clojure buffers;
opening a file does not start a process. inf-clojure talks to an ordinary
`clojure.main` REPL, either as a subprocess or over a socket REPL. There
is no Eglot, language server, nREPL, prepl, or injected middleware.

Paredit is installed through Nix and enabled in Clojure, Emacs Lisp
(including `*scratch*`), Common Lisp, and Scheme buffers.
It keeps delimiters balanced and supplies structural editing commands:
`C-M-f` / `C-M-b` move across forms, `C-)` slurps forward, `C-}` barfs
forward, and `M-s` splices. Paredit is not enabled in inf-clojure REPL
buffers.

Visit a Clojure file in your project and use `M-x inf-clojure` to start a
REPL. It detects the project type and prompts with the launch command, so
you can add a project's development/test aliases. Dependencies are
resolved by the project's Clojure tooling and may download on first
launch. If the project needs its own JDK or CLI, launch Emacs from its
development shell or start the REPL there and attach from Emacs.

For a runtime that lives independently of the editor, start a socket REPL
from the project directory, then use `M-x inf-clojure-connect` (`C-c M-c`)
with `localhost` and `5555`:

```sh
clojure -J-Dclojure.server.repl='{:port 5555 :accept clojure.core.server/repl}' -M -r
```

The runtime and its state survive editor reconnects; stop the JVM in its
terminal when done. `C-c C-q` quits the REPL buffer.

| In a Clojure source buffer | Action |
| --- | --- |
| `C-x C-e` / `C-c C-e` | Evaluate preceding form |
| `C-M-x` / `C-c C-c` | Evaluate enclosing definition |
| `C-c C-r` | Evaluate region |
| `C-c C-b` | Evaluate buffer |
| `C-c C-l` | Load file |
| `C-c M-r` | Reload namespace |
| `C-c M-n` | Set REPL namespace |
| `C-c C-z` | Switch to REPL |
| `C-c C-v` / `C-c C-s` | Documentation / source |
| `C-c C-a` | Arglists |
| `C-c C-m` | Macroexpand |
| `C-c M-c` | Connect to socket REPL |

In the REPL, `RET` submits input; `M-p` / `M-n` browse history.
See [inf-clojure](https://github.com/clojure-emacs/inf-clojure) for
upstream details. It comes from nixpkgs' MELPA set, so it updates with
the `nixpkgs` input.
