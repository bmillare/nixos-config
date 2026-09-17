{ lib, modulesPath, pkgs, self, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  networking = {
    hostName = "dykestraw-installer";
    networkmanager.enable = true;
  };

  # Let the personal key log in as nixos over Ethernet/Wi-Fi. The live image
  # has no embedded password or private credentials.
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIc+wMxSoktmSGv9e7yEf0SQ2Qu7A9S9SX2jqh4V0z1a brent.millare@gmail.com"
  ];
  services.openssh.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # The generic minimal ISO enables ZFS and would compile it against the
  # custom Surface kernel. Dykestraw only needs these installation filesystems.
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];

  environment.systemPackages = with pkgs; [
    cryptsetup
    git
    gptfdisk
    lvm2
    networkmanager
    ripgrep
    tmux
    vim
  ];

  # The source and complete target closure make an offline installation
  # possible after the ISO itself has been built on crayfish.
  environment.etc."nixos-config".source = self;
  isoImage.storeContents = [
    self.nixosConfigurations.dykestraw.config.system.build.toplevel
  ];
}
