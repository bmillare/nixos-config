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

  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.brent = {
    imports = [
      ../../modules/home/common-development.nix
      ../../modules/home/common-ssh.nix
    ];

    home.username = "brent";
    home.homeDirectory = "/home/brent";
    home.stateVersion = "26.05";

    home.packages = [
      pkgs.azure-cli
      pkgs.docker-compose
      pkgs.llama-cpp
    ];

  };
}
