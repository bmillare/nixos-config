{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  users.users.brent.extraGroups = [ "docker" ];

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

    programs.home-manager.enable = true;
    programs.bash.enable = true;
    programs.firefox.enable = true;

    programs.git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
