{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  home.packages = [
    inputs.codex-cli-nix.packages.${pkgs.system}.default
    inputs.claude-code.packages.${pkgs.system}.default
    pkgs.curl
    pkgs.emacs
    pkgs.jq
    pkgs.pdftk
    pkgs.ripgrep
    pkgs.silver-searcher
    pkgs.vim
    pkgs.wget
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.chromium ];

  programs = {
    bash.enable = true;
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
    firefox.enable = pkgs.stdenv.isLinux;
    git = {
      enable = true;
      settings.init.defaultBranch = "main";
    };
    gh = {
      enable = true;
      settings.git_protocol = "ssh";
      gitCredentialHelper.enable = true;
    };
    home-manager.enable = true;
    tmux.enable = true;
  };
}
