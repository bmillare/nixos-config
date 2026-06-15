{ inputs, pkgs, ... }:

{
  #virtualisation.docker.enable = true;
  virtualisation.podman.enable = true;
  environment.systemPackages = [ pkgs.distrobox ];
  #users.users.brent.extraGroups = [ "docker" ];

  # virtualisation.oci-containers = {
  #   backend = "docker";
  #   containers = {
  #     ubuntu-server = {
  #       image = "ubuntu:latest";
  #       cmd = [ "sleep" "infinity" ];
  #     };
  #   };
  # };
  # virtualisation.oci-containers = {
  #   backend = "docker";
  #   containers = {
  #     vanta-ubuntu = {
  #       image = "jrei/systemd-ubuntu:latest";
  #       # Systemd requires privileged access to manage system services
  #       extraOptions = [ "--privileged" ];
  #       volumes = [
  #         "/sys/fs/cgroup:/sys/fs/cgroup:ro"
  #       ];
  #     };
  #   };
  # };
  users.users.brent.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzv9piBq1YBoem21fGSuNUQO9JfbpOusARoSyojJ6wH brent@psynk.ai"
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.brent = {
    home.username = "brent";
    home.homeDirectory = "/home/brent";
    home.stateVersion = "26.05";

    home.packages = [
      inputs.codex-cli-nix.packages.${pkgs.system}.default
      inputs.claude-code.packages.${pkgs.system}.default
      pkgs.azure-cli
      pkgs.docker-compose
      pkgs.llama-cpp
      pkgs.silver-searcher
    ];

    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv = {
        enable = true;
      };
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      # work github is default
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
    };

    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
      };
    };

    programs.home-manager.enable = true;
    programs.bash.enable = true;
    programs.firefox.enable = true;

    programs.tmux = {
      enable = true;
    };
  };

  nix.settings = {
    substituters = [
      "https://codex-cli.cachix.org"
      "https://claude-code.cachix.org"
    ];
    trusted-public-keys = [
      "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    ];
  };

}
