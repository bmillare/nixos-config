{ inputs, pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; [
      vertico
      orderless
      marginalia
      consult
      magit
      markdown-mode
      nix-mode
      unfill
      clojure-mode
      paredit
      (epkgs.trivialBuild {
        pname = "port";
        version = "0.3.0";
        src = "${inputs.port}/lisp";
      })
    ];
  };

  # The Clojure CLI includes its Java runtime; projects can override it in
  # their development shell, or run a prepl independently of Emacs.
  home.packages = [ pkgs.ripgrep pkgs.pandoc pkgs.clojure ];

  # Own the user init: HM's extraConfig becomes default.el and would run
  # after an existing init, mixing the old Helm setup with this one.
  home.file.".emacs".source = ./emacs/init.el;
  home.file.".emacs.d/early-init.el".text = ''
    ;; Use Nix's load-path, without activating packages from an old ELPA tree.
    (setq package-enable-at-startup nil)
  '';
}
