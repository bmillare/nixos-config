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

Omitted: Helm, the old CIDER setup, vterm and terminal macros,
custom process-send and temporary-file plumbing, Mac modifiers/renderer,
WSL browser detection, UUID/XML helpers, and the custom kill-buffer command.
The standard buffer-killing commands remain available. These optional
workflows can be reintroduced selectively later.

## Clojure over prepl

Nix installs `clojure-mode`, Port v0.3.0 (source pinned by the `port` input
in `flake.lock`), and the Clojure CLI with its Java runtime. Port mode is
enabled in Clojure buffers; opening a file does not start a process.
Port supplies runtime completion, Eldoc, and definition lookup. There is
no Eglot, language server, nREPL, or injected Orchard dependency.

Paredit is installed through Nix and enabled in Clojure, Emacs Lisp
(including `*scratch*`), Common Lisp, and Scheme buffers.
It keeps delimiters balanced and supplies structural editing commands:
`C-M-f` / `C-M-b` move across forms, `C-)` slurps forward, `C-}` barfs
forward, and `M-s` splices. Paredit is not enabled in Port REPL buffers;
Port uses its standard editing and input-submission bindings.

Visit a Clojure file in your project and use `M-x port` to start a prepl.
`C-u M-x port` lets you edit the launch command, for example to add a
project's development/test aliases. Dependencies are resolved by the
project's Clojure tooling and may download on first launch. If the project
needs its own JDK or CLI, launch Emacs from its development shell or start
the prepl there and attach from Emacs.

For a runtime that lives independently of the editor, run this from the
project directory, then use `M-x port-connect` with `localhost` and `5555`:

```sh
clojure -M -e '(do
  (clojure.core.server/start-server
    {:name "port" :address "127.0.0.1" :port 5555
     :accept (quote clojure.core.server/io-prepl)})
  @(promise))'
```

The endpoint must use `io-prepl`, not the plain socket `repl` accept
function. Port opens a user connection for streaming evaluation and a
separate connection for editor queries. The runtime and its state can
remain alive across editor reconnects. `M-x port-disconnect` disconnects
the client; stop an externally launched JVM in its terminal when done.
For a JVM started by `M-x port`, disconnect also stops that JVM.

| In a Clojure source buffer | Action |
| --- | --- |
| `C-c C-e` | Evaluate preceding form |
| `C-c C-c` | Evaluate enclosing definition |
| `C-c C-r` | Evaluate region |
| `C-c C-k` | Evaluate buffer |
| `C-c C-l` | Load file |
| `C-c C-z` | Switch to REPL |
| `C-c C-d` / `C-c C-s` | Documentation / source |
| `M-.` / `M-,` | Definition / return |
| `C-M-i` | Complete at point |
| `C-c C-t v` | View `tap>` values |
| `C-c C-t n` | Run namespace tests |

In the REPL, `RET` submits complete input (or adds a newline within an
unfinished form); `M-p` / `M-n` browse history. Port persists history in
the project's `.port-history`; keep that file out of version control.
Evaluation results and streamed output remain in the REPL buffer. Jack-in
uses bounded pretty printing by default; customize `port-print-length`
and `port-print-level` for larger values. `M-x port-toggle-message-log`
helps inspect the protocol when troubleshooting.

Port is still young: its REPL `C-c C-c` interrupt command is a stub, and
source commands use a default session rather than a full multiple-listener
workspace. Form-oriented nested `read` can use the user stream; arbitrary
character-at-a-time terminal interaction is not provided by this UI.

The design follows the separate user/tool connections discussed in
[Rich Hickey on REPLs](https://nextjournal.com/mk/rich-hickey-on-repls).
See [Port](https://github.com/clojure-emacs/port) for upstream details.
To upgrade, change the `port` input tag in `flake.nix` and package version
in `emacs.nix`, then run `nix flake update port` and rebuild.
