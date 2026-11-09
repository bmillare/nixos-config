{ config, lib, pkgs, ... }:

{
  imports = [ ./common-ssh.nix ];

  # The same union of public keys authorizes both personal clients.
  home.file.".ssh/authorized_keys.source".text =
    builtins.readFile ../ssh-keys/personal-authorized-keys;

  # A regular file works with sshd StrictModes on macOS as well as Linux.
  home.activation.personalAuthorizedKeys = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${pkgs.coreutils}/bin/install -m 600 ${config.home.file.".ssh/authorized_keys.source".source} "$HOME/.ssh/.authorized_keys.hm-new"
    run ${pkgs.coreutils}/bin/mv -f "$HOME/.ssh/.authorized_keys.hm-new" "$HOME/.ssh/authorized_keys"
  '';

  # Personal clients share aliases; private keys stay outside the Nix store.
  programs.ssh.settings = {
    "macbook" = {
      HostName = "Brents-MacBook-Pro.local";
      User = "bmillare";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
    };
    "crayfish" = {
      HostName = "crayfish.local";
      User = "brent";
      IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
      IdentitiesOnly = true;
    };
    "crayfish_tailscale" = {
      HostName = "crayfish.tailb67abf.ts.net";
      User = "brent";
      IdentityFile = "~/.ssh/brent_spynk_ai_ed25519_key";
      IdentitiesOnly = true;
    };
    "blacksheep" = {
      HostName = "blacksheep.local";
      User = "bmillare";
      IdentityFile = "~/.ssh/test_keypari1.pem";
      IdentitiesOnly = true;
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
    };
    "dykestraw" = {
      # Current LAN DHCP address; update if its lease changes.
      HostName = "192.168.1.98";
      User = "bmillare";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
    };
    "ada-pi" = {
      HostName = "ada-pi.local";
      User = "bmillare";
      IdentityFile = "~/.ssh/test_keypari1.pem";
      IdentitiesOnly = true;
    };
    "ec2T4" = {
      HostName = "3.21.55.225";
      User = "ec2-user";
      IdentityFile = "~/.ssh/test_keypari1.pem";
      IdentitiesOnly = true;
    };
  };
}
