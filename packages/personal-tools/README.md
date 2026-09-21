# Personal tools

Dykestraw binds Super+Shift+Space to this launcher. Super+Space remains Fuzzel.
Choose Org or Markdown, then a file to open in an existing Emacs frame. A frame
is created if none exists; Emacs starts if no server is available. Escape cancels
either menu.

Search covers all of `~/projects` recursively, including hidden and ignored
directories, without following directory symlinks. Org matches `.org`; Markdown
matches `.md` and `.markdown`, case-insensitively. Files are sorted by modification
time, newest first. Menu labels are relative paths; menu values are indices, so
spaces, tabs, newlines, and shell characters in filenames remain safe.

`default.nix` supplies the interpreter, menu, and configured Emacs through Nix
store paths. The Python file contains both searches and the menu dispatch.
Other hosts can reuse the package by passing their own `pkgs` and Emacs package.
Only dykestraw currently installs it and defines a keybinding.
