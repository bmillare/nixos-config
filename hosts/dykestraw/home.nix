{ inputs, pkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.bmillare = {
    home = {
      username = "bmillare";
      homeDirectory = "/home/bmillare";
      stateVersion = "26.05";
      packages = [
        inputs.codex-cli-nix.packages.${pkgs.system}.default
        inputs.claude-code.packages.${pkgs.system}.default
        pkgs.chromium
        pkgs.jq
      ];
    };

    programs = {
      bash.enable = true;
      direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };
      firefox.enable = true;
      git = {
        enable = true;
        settings.init.defaultBranch = "main";
      };
      home-manager.enable = true;
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };
      };
      tmux.enable = true;
    };
  };
}
