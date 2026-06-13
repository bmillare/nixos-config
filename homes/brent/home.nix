{ ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.brent = {
    home.username = "brent";
    home.homeDirectory = "/home/brent";
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;

    programs.bash.enable = true;

    programs.git = {
      enable = true;
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
