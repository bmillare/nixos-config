{ inputs, pkgs, ... }:

{
  home = {
    username = "bmillare";
    homeDirectory = "/home/bmillare";
    stateVersion = "26.05";
    packages = [
      inputs.codex-cli-nix.packages.${pkgs.system}.default
      inputs.claude-code.packages.${pkgs.system}.default
      pkgs.chromium
      pkgs.curl
      pkgs.emacs
      pkgs.jq
      pkgs.ripgrep
      pkgs.vim
      pkgs.wget
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
    gh = {
      enable = true;
      settings.git_protocol = "ssh";
      gitCredentialHelper.enable = true;
    };
    home-manager.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;

      # Work GitHub is the default, with a separate alias for repositories
      # owned by the personal account.
      settings."github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."github.com_personal" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
      };
      settings."crayfish" = {
        HostName = "crayfish.local";
        User = "brent";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."octavian" = {
        HostName = "www.breakds.org";
        User = "brent";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."lorian" = {
        HostName = "lorian.local";
        User = "brent";
        ProxyJump = "octavian";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."cradle" = {
        HostName = "cradle.local";
        User = "brent";
        ProxyJump = "octavian";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."slot1" = {
        HostName = "10.231.1.2";
        User = "root";
        ProxyJump = "cradle";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."slot2" = {
        HostName = "10.231.1.3";
        User = "root";
        ProxyJump = "cradle";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."slot3" = {
        HostName = "10.231.1.4";
        User = "root";
        ProxyJump = "cradle";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
      settings."*.psynk.ai" = {
        User = "brent";
        IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
        IdentitiesOnly = true;
      };
    };
    tmux.enable = true;
  };
}
