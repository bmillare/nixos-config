{ pkgs, emacs }:

let
  waydmenu = import ../waydmenu { inherit pkgs; };
in
pkgs.writeShellScriptBin "personal-tools" ''
  exec ${pkgs.python3}/bin/python3 ${./personal-tools.py} \
    ${waydmenu}/bin/waydmenu ${emacs}/bin/emacsclient ${emacs}/bin/emacs "$@"
''
