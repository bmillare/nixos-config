{ ... }:

{
  imports = [
    ./bmillare-git.nix
    ./common-development.nix
    ./common-ssh.nix
  ];

  home = {
    username = "bmillare";
    homeDirectory = "/home/bmillare";
    stateVersion = "26.05";
  };

  programs.ssh = {
    settings."crayfish" = {
      HostName = "crayfish.local";
      User = "brent";
      IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
      IdentitiesOnly = true;
    };
    settings."blacksheep" = {
      HostName = "blacksheep.local";
      User = "bmillare";
      IdentityFile = "~/.ssh/test_keypari1.pem";
      IdentitiesOnly = true;
    };
  };
}
