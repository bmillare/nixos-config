{ pkgs, ... }:

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
       pkgs.llama-cpp
       pkgs.docker-compose
    ];

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
}
